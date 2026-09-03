import { BillingInterval, BillingProvider } from "@prisma/client";

export type CreateBillingCustomerInput = {
  groupId: string;
  email?: string;
  phone?: string;
  name: string;
};

export type BillingCustomer = {
  providerCustomerId: string;
};

export type CreateCheckoutSessionInput = {
  groupId: string;
  planCode: string;
  productType: "group-access" | "reminder-package";
  productName: string;
  providerCustomerId: string;
  amountMinor: number;
  currency: string;
  interval: BillingInterval;
  intervalCount: number;
  trialDays: number;
  metadata?: Record<string, unknown>;
  successUrl: string;
  cancelUrl: string;
  buyerEmail?: string;
  buyerName?: string;
  buyerPhone?: string;
};

export type CheckoutSession = {
  providerSessionId: string;
  checkoutUrl: string;
  expiresAt: Date;
};

export type ProviderSubscription = {
  providerSubscriptionId: string;
  providerCustomerId: string;
  status:
    "trialing" | "active" | "past_due" | "cancelled" | "suspended" | "expired";
  currentPeriodStartsAt: Date;
  currentPeriodEndsAt: Date;
  cancelAtPeriodEnd: boolean;
};

export type BillingPortalInput = {
  providerCustomerId: string;
  returnUrl: string;
};

export type BillingPortalSession = {
  portalUrl: string;
  expiresAt: Date;
};

export type VerifiedBillingEvent = {
  providerEventId: string;
  type: string;
  payload: Record<string, unknown>;
};

export interface SubscriptionBillingProvider {
  readonly provider: BillingProvider;
  createCustomer(input: CreateBillingCustomerInput): Promise<BillingCustomer>;
  createCheckoutSession(
    input: CreateCheckoutSessionInput,
  ): Promise<CheckoutSession>;
  getSubscription(
    providerSubscriptionId: string,
  ): Promise<ProviderSubscription>;
  cancelSubscription(
    providerSubscriptionId: string,
  ): Promise<ProviderSubscription>;
  resumeSubscription(
    providerSubscriptionId: string,
  ): Promise<ProviderSubscription>;
  createBillingPortalSession(
    input: BillingPortalInput,
  ): Promise<BillingPortalSession>;
  verifyWebhookSignature(
    payload: Buffer,
    signature: string,
  ): Promise<VerifiedBillingEvent>;
}
