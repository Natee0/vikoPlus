import { Module } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { CommonAuthModule } from "../common/auth/common-auth.module";
import { SUBSCRIPTION_BILLING_PROVIDER } from "./billing-provider.token";
import { BillingWebhookService } from "./billing-webhook.service";
import { BillingWebhooksController } from "./billing-webhooks.controller";
import { MockSubscriptionBillingProvider } from "./mock-subscription-billing.provider";
import { PaymentEventsGateway } from "./payment-events.gateway";
import { SayariSubscriptionBillingProvider } from "./sayari-subscription-billing.provider";

@Module({
  imports: [CommonAuthModule],
  controllers: [BillingWebhooksController],
  providers: [
    BillingWebhookService,
    PaymentEventsGateway,
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
  exports: [SUBSCRIPTION_BILLING_PROVIDER, PaymentEventsGateway],
})
export class BillingModule {}
