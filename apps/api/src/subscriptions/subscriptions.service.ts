import {
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import {
  GroupMemberStatus,
  GroupRole,
  SubscriptionPlanStatus,
  SubscriptionState,
} from "@prisma/client";
import { ApiErrorCode } from "../common/errors/api-error-code";
import { hasPaidFeatureAccess } from "../common/subscriptions/subscription-access.policy";
import { PrismaService } from "../prisma/prisma.service";
import { SUBSCRIPTION_BILLING_PROVIDER } from "../billing/billing-provider.token";
import { SubscriptionBillingProvider } from "../billing/subscription-billing-provider";
import { CreateCheckoutDto } from "./dto/create-checkout.dto";
import { SubscriptionDto } from "./dto/subscription.dto";
import { AuthenticatedUser } from "../common/auth/authenticated-user";

@Injectable()
export class SubscriptionsService {
  constructor(
    private readonly prisma: PrismaService,
    @Inject(SUBSCRIPTION_BILLING_PROVIDER)
    private readonly billingProvider: SubscriptionBillingProvider,
  ) {}

  async getGroupSubscription(groupId: string): Promise<SubscriptionDto> {
    const subscription = await this.prisma.subscription.findFirst({
      where: { groupId },
      include: { plan: true },
      orderBy: { createdAt: "desc" },
    });

    if (!subscription) {
      throw new NotFoundException({
        code: ApiErrorCode.SubscriptionRequired,
        message: "A Vikoplus subscription is required for this group.",
      });
    }

    return {
      id: subscription.id,
      groupId: subscription.groupId,
      planCode: subscription.plan.code,
      state: subscription.state,
      hasPaidFeatureAccess: hasPaidFeatureAccess({
        state: subscription.state,
        currentPeriodEndsAt: subscription.currentPeriodEndsAt,
      }),
      currentPeriodEndsAt: subscription.currentPeriodEndsAt,
      cancelAtPeriodEnd: subscription.cancelAtPeriodEnd,
    };
  }

  async createCheckout(
    user: AuthenticatedUser,
    groupId: string,
    input: CreateCheckoutDto,
  ): Promise<{ checkoutUrl: string; expiresAt: Date }> {
    await this.requireBillingAuthority(user, groupId);

    const [group, plan] = await Promise.all([
      this.prisma.group.findUnique({ where: { id: groupId } }),
      this.prisma.subscriptionPlan.findUnique({
        where: { code: input.planCode },
      }),
    ]);

    if (!group || !plan) {
      throw new NotFoundException({
        code: ApiErrorCode.ResourceNotFound,
        message: "Group or subscription plan was not found.",
      });
    }
    if (plan.status !== SubscriptionPlanStatus.ACTIVE) {
      throw new NotFoundException({
        code: ApiErrorCode.ResourceNotFound,
        message: "Subscription plan was not found.",
      });
    }

    const providerCustomer = await this.billingProvider.createCustomer({
      groupId,
      name: group.name,
      email: input.buyerEmail,
      phone: input.buyerPhone,
    });
    const billingProvider = this.billingProvider.provider;

    const billingCustomer = await this.prisma.billingCustomer.upsert({
      where: {
        provider_providerCustomerId: {
          provider: billingProvider,
          providerCustomerId: providerCustomer.providerCustomerId,
        },
      },
      create: {
        groupId,
        provider: billingProvider,
        providerCustomerId: providerCustomer.providerCustomerId,
        email: input.buyerEmail,
        phone: input.buyerPhone,
      },
      update: {},
    });

    await this.prisma.subscription.upsert({
      where: { id: `${groupId}:${plan.id}` },
      create: {
        id: `${groupId}:${plan.id}`,
        groupId,
        planId: plan.id,
        billingCustomerId: billingCustomer.id,
        provider: billingProvider,
        state: SubscriptionState.TRIAL,
        trialEndsAt:
          plan.trialDays > 0 ? addDays(new Date(), plan.trialDays) : null,
      },
      update: {
        planId: plan.id,
        billingCustomerId: billingCustomer.id,
      },
    });

    const checkout = await this.billingProvider.createCheckoutSession({
      groupId,
      planCode: plan.code,
      productType: "group-access",
      productName: plan.name,
      providerCustomerId: billingCustomer.providerCustomerId,
      amountMinor: plan.priceMinor,
      currency: plan.currency,
      interval: plan.interval,
      intervalCount: plan.intervalCount,
      trialDays: plan.trialDays,
      successUrl: input.successUrl,
      cancelUrl: input.cancelUrl,
      buyerEmail: input.buyerEmail,
      buyerName: input.buyerName ?? group.name,
      buyerPhone: input.buyerPhone,
    });

    return {
      checkoutUrl: checkout.checkoutUrl,
      expiresAt: checkout.expiresAt,
    };
  }

  async createBillingPortal(
    user: AuthenticatedUser,
    groupId: string,
    returnUrl: string,
  ): Promise<{ portalUrl: string; expiresAt: Date }> {
    await this.requireBillingAuthority(user, groupId);

    const customer = await this.prisma.billingCustomer.findFirst({
      where: { groupId },
    });
    if (!customer) {
      throw new NotFoundException({
        code: ApiErrorCode.ResourceNotFound,
        message: "Billing customer was not found.",
      });
    }

    const session = await this.billingProvider.createBillingPortalSession({
      providerCustomerId: customer.providerCustomerId,
      returnUrl,
    });
    return { portalUrl: session.portalUrl, expiresAt: session.expiresAt };
  }

  async cancel(
    user: AuthenticatedUser,
    groupId: string,
  ): Promise<SubscriptionDto> {
    await this.requireBillingAuthority(user, groupId);
    return this.updateProviderState(groupId, "cancel");
  }

  async resume(
    user: AuthenticatedUser,
    groupId: string,
  ): Promise<SubscriptionDto> {
    await this.requireBillingAuthority(user, groupId);
    return this.updateProviderState(groupId, "resume");
  }

  private async updateProviderState(
    groupId: string,
    action: "cancel" | "resume",
  ): Promise<SubscriptionDto> {
    const subscription = await this.prisma.subscription.findFirst({
      where: { groupId },
      include: { plan: true },
      orderBy: { createdAt: "desc" },
    });

    if (!subscription?.providerSubscriptionId) {
      throw new NotFoundException({
        code: ApiErrorCode.SubscriptionRequired,
        message: "Active provider subscription was not found.",
      });
    }

    const providerSubscription =
      action === "cancel"
        ? await this.billingProvider.cancelSubscription(
            subscription.providerSubscriptionId,
          )
        : await this.billingProvider.resumeSubscription(
            subscription.providerSubscriptionId,
          );

    const updated = await this.prisma.subscription.update({
      where: { id: subscription.id },
      data: {
        state: mapProviderStatus(providerSubscription.status),
        cancelAtPeriodEnd: providerSubscription.cancelAtPeriodEnd,
        currentPeriodStartsAt: providerSubscription.currentPeriodStartsAt,
        currentPeriodEndsAt: providerSubscription.currentPeriodEndsAt,
        cancelledAt: action === "cancel" ? new Date() : null,
      },
      include: { plan: true },
    });

    return {
      id: updated.id,
      groupId: updated.groupId,
      planCode: updated.plan.code,
      state: updated.state,
      hasPaidFeatureAccess: hasPaidFeatureAccess({
        state: updated.state,
        currentPeriodEndsAt: updated.currentPeriodEndsAt,
      }),
      currentPeriodEndsAt: updated.currentPeriodEndsAt,
      cancelAtPeriodEnd: updated.cancelAtPeriodEnd,
    };
  }

  private async requireBillingAuthority(
    user: AuthenticatedUser,
    groupId: string,
  ): Promise<void> {
    const [group, membership] = await Promise.all([
      this.prisma.group.findUnique({
        where: { id: groupId },
        select: { billingOwnerUserId: true },
      }),
      this.prisma.groupMember.findFirst({
        where: {
          groupId,
          userId: user.id,
          status: GroupMemberStatus.ACTIVE,
        },
        select: { role: true },
      }),
    ]);

    if (!group || !membership) {
      throw new ForbiddenException("Group billing access denied.");
    }

    if (
      group.billingOwnerUserId !== user.id &&
      membership.role !== GroupRole.GROUP_ADMIN
    ) {
      throw new ForbiddenException("Group billing access denied.");
    }
  }
}

function mapProviderStatus(status: string): SubscriptionState {
  if (status === "trialing") return SubscriptionState.TRIAL;
  if (status === "active") return SubscriptionState.ACTIVE;
  if (status === "past_due") return SubscriptionState.PAST_DUE;
  if (status === "cancelled") return SubscriptionState.CANCELLED;
  if (status === "suspended") return SubscriptionState.SUSPENDED;
  return SubscriptionState.EXPIRED;
}

function addDays(date: Date, days: number): Date {
  return new Date(date.getTime() + days * 24 * 60 * 60_000);
}
