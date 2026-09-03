import {
  BadRequestException,
  Injectable,
  ServiceUnavailableException,
  UnauthorizedException,
} from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { BillingProvider } from "@prisma/client";
import { createHash, createHmac, randomUUID, timingSafeEqual } from "crypto";
import {
  BillingCustomer,
  BillingPortalInput,
  BillingPortalSession,
  CheckoutSession,
  CreateBillingCustomerInput,
  CreateCheckoutSessionInput,
  ProviderSubscription,
  SubscriptionBillingProvider,
  VerifiedBillingEvent,
} from "./subscription-billing-provider";

@Injectable()
export class SayariSubscriptionBillingProvider implements SubscriptionBillingProvider {
  readonly provider = BillingProvider.SAYARI;

  constructor(private readonly config: ConfigService) {}

  createCustomer(input: CreateBillingCustomerInput): Promise<BillingCustomer> {
    return Promise.resolve({
      providerCustomerId: `sayari_customer_${input.groupId}`,
    });
  }

  async createCheckoutSession(
    input: CreateCheckoutSessionInput,
  ): Promise<CheckoutSession> {
    if (!input.buyerEmail) {
      throw new BadRequestException(
        "Buyer email is required for Sayari Payments.",
      );
    }
    if (!input.buyerName) {
      throw new BadRequestException(
        "Buyer name is required for Sayari Payments.",
      );
    }

    const order = await this.sayariRequest<Record<string, unknown>>(
      "/api/v1/checkout/orders",
      {
        method: "POST",
        idempotencyKey: `vikoplus-access-order-${input.groupId}-${input.planCode}`,
        body: {
          externalRef: `${input.groupId}:${input.planCode}`,
          buyerEmail: input.buyerEmail,
          buyerName: input.buyerName,
          buyerPhone: this.normalizeMsisdn(input.buyerPhone),
          amount: input.amountMinor,
          currency: input.currency,
          metadata: {
            product: input.productType,
            productName: input.productName,
            groupId: input.groupId,
            code: input.planCode,
            interval: input.interval,
            intervalCount: input.intervalCount,
            trialDays: input.trialDays,
            ...input.metadata,
          },
          successUrl: input.successUrl,
          cancelUrl: input.cancelUrl,
        },
      },
    );

    const orderId = this.firstString(order, ["orderId", "id"]);
    if (!orderId) {
      throw new ServiceUnavailableException(
        "Sayari Payments did not return an order id.",
      );
    }

    if (input.buyerPhone) {
      await this.sayariRequest<Record<string, unknown>>(
        `/api/v1/checkout/orders/${encodeURIComponent(orderId)}/wallet-payment`,
        {
          method: "POST",
          idempotencyKey: `vikoplus-access-wallet-${input.groupId}-${input.planCode}`,
          body: { msisdn: this.normalizeMsisdn(input.buyerPhone) },
        },
      );
    }

    return {
      providerSessionId: orderId,
      checkoutUrl:
        this.firstString(order, ["paymentGatewayUrl", "paymentUrl"]) ??
        input.successUrl,
      expiresAt: addMinutes(new Date(), 30),
    };
  }

  async getSubscription(
    providerSubscriptionId: string,
  ): Promise<ProviderSubscription> {
    const order = await this.sayariRequest<Record<string, unknown>>(
      `/api/v1/checkout/orders/${encodeURIComponent(providerSubscriptionId)}`,
      { method: "GET", idempotencyKey: randomUUID() },
    );
    return this.providerSubscriptionFromOrder(providerSubscriptionId, order);
  }

  cancelSubscription(
    providerSubscriptionId: string,
  ): Promise<ProviderSubscription> {
    return Promise.resolve(
      mockProviderSubscription(providerSubscriptionId, "cancelled", true),
    );
  }

  resumeSubscription(
    providerSubscriptionId: string,
  ): Promise<ProviderSubscription> {
    return Promise.resolve(
      mockProviderSubscription(providerSubscriptionId, "active", false),
    );
  }

  createBillingPortalSession(
    input: BillingPortalInput,
  ): Promise<BillingPortalSession> {
    return Promise.resolve({
      portalUrl: input.returnUrl,
      expiresAt: addMinutes(new Date(), 30),
    });
  }

  verifyWebhookSignature(
    payload: Buffer,
    signature: string,
  ): Promise<VerifiedBillingEvent> {
    const secret = this.config.getOrThrow<string>(
      "SAYARI_PAYMENT_CALLBACK_SECRET",
    );
    const expected = createHmac("sha256", secret).update(payload).digest("hex");
    if (!this.safeCompare(signature, expected)) {
      throw new UnauthorizedException(
        "Invalid Sayari payment webhook signature.",
      );
    }

    const parsed = JSON.parse(payload.toString("utf8")) as Record<
      string,
      unknown
    >;
    const normalized = this.normalizedPayload(parsed);
    const providerEventId =
      this.firstString(normalized, ["eventId", "id", "orderId"]) ??
      createHash("sha256").update(payload).digest("hex");

    return Promise.resolve({
      providerEventId,
      type: this.firstString(normalized, ["type", "eventType"]) ?? "payment",
      payload: normalized,
    });
  }

  private async sayariRequest<T>(
    path: string,
    options: {
      method: "GET" | "POST" | "DELETE";
      idempotencyKey: string;
      body?: Record<string, unknown>;
    },
  ): Promise<T> {
    const apiKey = this.config.getOrThrow<string>("SAYARI_PAYMENT_API_KEY");
    const baseUrl = this.config
      .getOrThrow<string>("SAYARI_PAYMENT_BASE_URL")
      .replace(/\/$/, "");
    const response = await fetch(`${baseUrl}${path}`, {
      method: options.method,
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
        "Idempotency-Key": options.idempotencyKey,
        "X-Request-Id": randomUUID(),
      },
      body: options.body ? JSON.stringify(options.body) : undefined,
    });
    const payload = await this.readJson(response);
    if (!response.ok) {
      throw new ServiceUnavailableException({
        message: "Sayari Payments request failed.",
        statusCode: response.status,
        providerPayload: payload,
      });
    }
    return payload as T;
  }

  private async readJson(response: Response): Promise<Record<string, unknown>> {
    const text = await response.text();
    if (!text) return {};
    try {
      return JSON.parse(text) as Record<string, unknown>;
    } catch {
      return { raw: text };
    }
  }

  private providerSubscriptionFromOrder(
    orderId: string,
    order: Record<string, unknown>,
  ): ProviderSubscription {
    const status = this.firstString(order, ["status", "paymentStatus"]);
    return mockProviderSubscription(
      orderId,
      status === "PAID" ? "active" : "trialing",
      false,
    );
  }

  private normalizedPayload(
    body: Record<string, unknown>,
  ): Record<string, unknown> {
    const data =
      typeof body.data === "object" && body.data
        ? (body.data as Record<string, unknown>)
        : {};
    const metadata =
      typeof body.metadata === "object" && body.metadata
        ? (body.metadata as Record<string, unknown>)
        : {};
    return { ...body, ...data, ...metadata };
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

  private normalizeMsisdn(value?: string): string | undefined {
    const digits = String(value ?? "").replace(/\D/g, "");
    if (!digits) return undefined;
    if (digits.startsWith("255")) return digits;
    if (digits.startsWith("0")) return `255${digits.slice(1)}`;
    if (digits.length === 9) return `255${digits}`;
    return digits;
  }

  private safeCompare(actual: string, expected: string): boolean {
    const actualHash = createHash("sha256").update(actual).digest();
    const expectedHash = createHash("sha256").update(expected).digest();
    return timingSafeEqual(actualHash, expectedHash);
  }
}

function mockProviderSubscription(
  providerSubscriptionId: string,
  status: ProviderSubscription["status"],
  cancelAtPeriodEnd: boolean,
): ProviderSubscription {
  const now = new Date();
  return {
    providerSubscriptionId,
    providerCustomerId: "sayari_customer",
    status,
    currentPeriodStartsAt: now,
    currentPeriodEndsAt: addDays(now, 365),
    cancelAtPeriodEnd,
  };
}

function addMinutes(date: Date, minutes: number): Date {
  return new Date(date.getTime() + minutes * 60_000);
}

function addDays(date: Date, days: number): Date {
  return new Date(date.getTime() + days * 24 * 60 * 60_000);
}
