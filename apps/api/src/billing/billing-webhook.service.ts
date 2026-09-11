import { Inject, Injectable } from "@nestjs/common";
import {
  BillingEventStatus,
  BillingProvider,
  BillingTransactionStatus,
  Prisma,
  ReminderPackagePurchaseStatus,
  SubscriptionState,
} from "@prisma/client";
import { PrismaService } from "../prisma/prisma.service";
import { SUBSCRIPTION_BILLING_PROVIDER } from "./billing-provider.token";
import { PaymentEventsGateway } from "./payment-events.gateway";
import { SubscriptionBillingProvider } from "./subscription-billing-provider";

@Injectable()
export class BillingWebhookService {
  constructor(
    private readonly prisma: PrismaService,
    @Inject(SUBSCRIPTION_BILLING_PROVIDER)
    private readonly billingProvider: SubscriptionBillingProvider,
    private readonly paymentEvents: PaymentEventsGateway,
  ) {}

  async receive(
    provider: BillingProvider,
    payload: Buffer,
    signature: string,
    timestamp?: string,
  ): Promise<{ received: true; eventId: string }> {
    const verified = await this.billingProvider.verifyWebhookSignature(
      payload,
      signature,
      timestamp,
    );

    const event = await this.prisma.billingEvent.upsert({
      where: {
        provider_providerEventId: {
          provider,
          providerEventId: verified.providerEventId,
        },
      },
      create: {
        provider,
        providerEventId: verified.providerEventId,
        type: verified.type,
        payload: verified.payload as Prisma.InputJsonValue,
        status: BillingEventStatus.RECEIVED,
      },
      update: {},
    });

    if (event.status === BillingEventStatus.PROCESSED) {
      return { received: true, eventId: event.id };
    }

    try {
      await this.processReminderPackagePaymentEvent(verified.payload);
      await this.processSubscriptionPaymentEvent(verified.payload);
      await this.prisma.billingEvent.update({
        where: { id: event.id },
        data: {
          status: BillingEventStatus.PROCESSED,
          processedAt: new Date(),
          failureReason: null,
        },
      });
    } catch (error) {
      await this.prisma.billingEvent.update({
        where: { id: event.id },
        data: {
          status: BillingEventStatus.FAILED,
          failureReason:
            error instanceof Error ? error.message : "Billing event failed.",
        },
      });
      throw error;
    }

    return { received: true, eventId: event.id };
  }

  private async processSubscriptionPaymentEvent(
    payload: Record<string, unknown>,
  ): Promise<void> {
    const orderId = this.firstString(payload, ["orderId", "providerRef"]);
    const externalRef = this.firstString(payload, ["externalRef"]);
    const providerStatus = this.firstString(payload, [
      "paymentStatus",
      "status",
      "result",
    ]);
    const nextState = this.subscriptionStateFromProviderStatus(providerStatus);
    if (!nextState) return;

    const subscription = orderId
      ? await this.prisma.subscription.findFirst({
          where: { providerSubscriptionId: orderId },
          include: { plan: true },
        })
      : await this.subscriptionFromExternalRef(externalRef);
    if (!subscription) return;

    const now = new Date();
    const activePeriodStartsAt = now;
    const activePeriodEndsAt = addBillingPeriod(
      activePeriodStartsAt,
      subscription.plan.interval,
      subscription.plan.intervalCount,
    );
    await this.prisma.subscription.update({
      where: { id: subscription.id },
      data: {
        providerSubscriptionId: orderId ?? subscription.providerSubscriptionId,
        state: nextState,
        ...(nextState === SubscriptionState.ACTIVE
          ? {
              currentPeriodStartsAt: activePeriodStartsAt,
              currentPeriodEndsAt: activePeriodEndsAt,
              cancelledAt: null,
              expiredAt: null,
              suspendedAt: null,
            }
          : {}),
        ...(nextState === SubscriptionState.CANCELLED
          ? { cancelledAt: now }
          : {}),
        ...(nextState === SubscriptionState.SUSPENDED
          ? { suspendedAt: now }
          : {}),
        ...(nextState === SubscriptionState.EXPIRED ? { expiredAt: now } : {}),
      },
    });

    this.paymentEvents.emitPaymentUpdated({
      groupId: subscription.groupId,
      productType: "group-access",
      status: nextState,
      orderId: orderId ?? undefined,
      planCode: subscription.plan.code,
    });

    if (nextState !== SubscriptionState.ACTIVE) return;
    const transactionRef =
      this.firstString(payload, ["transid", "reference", "orderId"]) ??
      orderId;
    if (!transactionRef) return;

    const amountMinor = this.numberValue(payload["amount"]);
    await this.prisma.billingTransaction.upsert({
      where: { providerTransactionId: transactionRef },
      create: {
        subscriptionId: subscription.id,
        providerTransactionId: transactionRef,
        status: BillingTransactionStatus.SUCCEEDED,
        amountMinor: amountMinor ?? subscription.plan.priceMinor,
        currency: this.firstString(payload, ["currency"]) ?? subscription.plan.currency,
        processedAt: now,
      },
      update: {
        status: BillingTransactionStatus.SUCCEEDED,
        processedAt: now,
      },
    });
  }

  private async subscriptionFromExternalRef(externalRef?: string) {
    if (!externalRef) return null;
    const [groupId, planCode] = externalRef.split(":");
    if (!groupId || !planCode) return null;
    return this.prisma.subscription.findFirst({
      where: {
        groupId,
        plan: { code: planCode },
      },
      include: { plan: true },
      orderBy: { updatedAt: "desc" },
    });
  }

  private subscriptionStateFromProviderStatus(
    status?: string,
  ): SubscriptionState | null {
    switch (String(status ?? "").toUpperCase()) {
      case "COMPLETED":
        return SubscriptionState.ACTIVE;
      case "FAILED":
        return SubscriptionState.PAST_DUE;
      case "CANCELLED":
        return SubscriptionState.CANCELLED;
      case "EXPIRED":
        return SubscriptionState.EXPIRED;
      default:
        return null;
    }
  }

  private async processReminderPackagePaymentEvent(
    payload: Record<string, unknown>,
  ): Promise<void> {
    const orderId = this.firstString(payload, ["orderId", "providerRef"]);
    if (!orderId) return;

    const providerStatus = this.firstString(payload, [
      "paymentStatus",
      "status",
      "result",
    ]);
    const nextStatus =
      this.reminderPurchaseStatusFromProviderStatus(providerStatus);
    if (!nextStatus) return;

    const purchase =
      (await this.prisma.reminderPackagePurchase.findFirst({
        where: { providerCheckoutId: orderId },
      })) ??
      (await this.reminderPurchaseFromExternalRef(
        this.firstString(payload, ["externalRef"]),
      ));
    if (!purchase) return;

    await this.prisma.reminderPackagePurchase.update({
      where: { id: purchase.id },
      data: {
        providerCheckoutId: orderId,
        status: nextStatus,
        ...(nextStatus === ReminderPackagePurchaseStatus.PAID
          ? { paidAt: new Date() }
          : {}),
      },
    });

    const remainingCredits = await this.reminderCreditsRemaining(
      purchase.groupId,
    );
    this.paymentEvents.emitPaymentUpdated({
      groupId: purchase.groupId,
      productType: "reminder-package",
      status: nextStatus,
      orderId,
      remainingCredits,
    });
  }

  private reminderPurchaseStatusFromProviderStatus(
    status?: string,
  ): ReminderPackagePurchaseStatus | null {
    switch (String(status ?? "").toUpperCase()) {
      case "COMPLETED":
        return ReminderPackagePurchaseStatus.PAID;
      case "FAILED":
        return ReminderPackagePurchaseStatus.FAILED;
      case "CANCELLED":
      case "CANCELED":
        return ReminderPackagePurchaseStatus.CANCELLED;
      case "EXPIRED":
        return ReminderPackagePurchaseStatus.FAILED;
      default:
        return null;
    }
  }

  private async reminderPurchaseFromExternalRef(externalRef?: string) {
    if (!externalRef) return null;
    const [groupId, packageCode] = externalRef.split(":");
    if (!groupId || !packageCode) return null;
    return this.prisma.reminderPackagePurchase.findFirst({
      where: {
        groupId,
        platformPrice: { code: packageCode },
        status: ReminderPackagePurchaseStatus.PENDING,
      },
      orderBy: { createdAt: "desc" },
    });
  }

  private firstString(
    payload: Record<string, unknown>,
    keys: string[],
  ): string | undefined {
    for (const key of keys) {
      const value = payload[key];
      if (typeof value === "string" && value.trim()) return value.trim();
      if (typeof value === "number") return String(value);
    }
    return undefined;
  }

  private numberValue(value: unknown): number | undefined {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? Math.round(parsed) : undefined;
  }

  private async reminderCreditsRemaining(groupId: string): Promise<number> {
    const totals = await this.prisma.reminderPackagePurchase.aggregate({
      where: {
        groupId,
        status: ReminderPackagePurchaseStatus.PAID,
      },
      _sum: {
        quantity: true,
        usedQuantity: true,
      },
    });
    return Math.max(
      (totals._sum.quantity ?? 0) - (totals._sum.usedQuantity ?? 0),
      0,
    );
  }
}

function addBillingPeriod(
  date: Date,
  interval: "MONTH" | "YEAR",
  intervalCount: number,
): Date {
  const next = new Date(date);
  if (interval === "YEAR") {
    next.setFullYear(next.getFullYear() + intervalCount);
  } else {
    next.setMonth(next.getMonth() + intervalCount);
  }
  return next;
}
