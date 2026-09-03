import { Injectable, UnauthorizedException } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { createHmac, randomUUID, timingSafeEqual } from "crypto";
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
export class MockSubscriptionBillingProvider implements SubscriptionBillingProvider {
  constructor(private readonly config: ConfigService) {}

  createCustomer(input: CreateBillingCustomerInput): Promise<BillingCustomer> {
    return Promise.resolve({
      providerCustomerId: `mock_customer_${input.groupId}`,
    });
  }

  createCheckoutSession(
    input: CreateCheckoutSessionInput,
  ): Promise<CheckoutSession> {
    return Promise.resolve({
      providerSessionId: `mock_checkout_${randomUUID()}`,
      checkoutUrl: `vikoplus://billing/mock-checkout?groupId=${input.groupId}&plan=${input.planCode}`,
      expiresAt: addMinutes(new Date(), 30),
    });
  }

  getSubscription(
    providerSubscriptionId: string,
  ): Promise<ProviderSubscription> {
    return Promise.resolve(
      mockSubscription(providerSubscriptionId, "active", false),
    );
  }

  cancelSubscription(
    providerSubscriptionId: string,
  ): Promise<ProviderSubscription> {
    return Promise.resolve(
      mockSubscription(providerSubscriptionId, "cancelled", true),
    );
  }

  resumeSubscription(
    providerSubscriptionId: string,
  ): Promise<ProviderSubscription> {
    return Promise.resolve(
      mockSubscription(providerSubscriptionId, "active", false),
    );
  }

  createBillingPortalSession(
    input: BillingPortalInput,
  ): Promise<BillingPortalSession> {
    return Promise.resolve({
      portalUrl: `vikoplus://billing/mock-portal?customer=${input.providerCustomerId}`,
      expiresAt: addMinutes(new Date(), 30),
    });
  }

  verifyWebhookSignature(
    payload: Buffer,
    signature: string,
  ): Promise<VerifiedBillingEvent> {
    const secret = this.config.getOrThrow<string>(
      "MOCK_BILLING_WEBHOOK_SECRET",
    );
    const expected = createHmac("sha256", secret).update(payload).digest("hex");
    const given = Buffer.from(signature, "hex");
    const expectedBuffer = Buffer.from(expected, "hex");

    if (
      given.length !== expectedBuffer.length ||
      !timingSafeEqual(given, expectedBuffer)
    ) {
      throw new UnauthorizedException("Invalid billing webhook signature");
    }

    const parsed = JSON.parse(payload.toString("utf8")) as VerifiedBillingEvent;
    return Promise.resolve({
      providerEventId: parsed.providerEventId,
      type: parsed.type,
      payload: parsed.payload,
    });
  }
}

function mockSubscription(
  providerSubscriptionId: string,
  status: ProviderSubscription["status"],
  cancelAtPeriodEnd: boolean,
): ProviderSubscription {
  const now = new Date();
  return {
    providerSubscriptionId,
    providerCustomerId: "mock_customer",
    status,
    currentPeriodStartsAt: now,
    currentPeriodEndsAt: addDays(now, 30),
    cancelAtPeriodEnd,
  };
}

function addMinutes(date: Date, minutes: number): Date {
  return new Date(date.getTime() + minutes * 60_000);
}

function addDays(date: Date, days: number): Date {
  return new Date(date.getTime() + days * 24 * 60 * 60_000);
}
