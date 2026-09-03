import { Module } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { SUBSCRIPTION_BILLING_PROVIDER } from "./billing-provider.token";
import { BillingWebhookService } from "./billing-webhook.service";
import { BillingWebhooksController } from "./billing-webhooks.controller";
import { MockSubscriptionBillingProvider } from "./mock-subscription-billing.provider";
import { SayariSubscriptionBillingProvider } from "./sayari-subscription-billing.provider";

@Module({
  controllers: [BillingWebhooksController],
  providers: [
    BillingWebhookService,
    MockSubscriptionBillingProvider,
    SayariSubscriptionBillingProvider,
    {
      provide: SUBSCRIPTION_BILLING_PROVIDER,
      inject: [
        ConfigService,
        MockSubscriptionBillingProvider,
        SayariSubscriptionBillingProvider,
      ],
      useFactory: (
        config: ConfigService,
        mock: MockSubscriptionBillingProvider,
        sayari: SayariSubscriptionBillingProvider,
      ) =>
        config.get<string>("BILLING_PROVIDER") === "sayari" ? sayari : mock,
    },
  ],
  exports: [SUBSCRIPTION_BILLING_PROVIDER],
})
export class BillingModule {}
