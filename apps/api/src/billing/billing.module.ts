import { Module } from "@nestjs/common";
import { SUBSCRIPTION_BILLING_PROVIDER } from "./billing-provider.token";
import { BillingWebhookService } from "./billing-webhook.service";
import { BillingWebhooksController } from "./billing-webhooks.controller";
import { MockSubscriptionBillingProvider } from "./mock-subscription-billing.provider";

@Module({
  controllers: [BillingWebhooksController],
  providers: [
    BillingWebhookService,
    MockSubscriptionBillingProvider,
    {
      provide: SUBSCRIPTION_BILLING_PROVIDER,
      useExisting: MockSubscriptionBillingProvider,
    },
  ],
  exports: [SUBSCRIPTION_BILLING_PROVIDER],
})
export class BillingModule {}
