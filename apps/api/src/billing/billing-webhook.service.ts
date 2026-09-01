import { Inject, Injectable } from "@nestjs/common";
import { BillingEventStatus, BillingProvider, Prisma } from "@prisma/client";
import { PrismaService } from "../prisma/prisma.service";
import { SUBSCRIPTION_BILLING_PROVIDER } from "./billing-provider.token";
import { SubscriptionBillingProvider } from "./subscription-billing-provider";

@Injectable()
export class BillingWebhookService {
  constructor(
    private readonly prisma: PrismaService,
    @Inject(SUBSCRIPTION_BILLING_PROVIDER)
    private readonly billingProvider: SubscriptionBillingProvider,
  ) {}

  async receive(
    provider: BillingProvider,
    payload: Buffer,
    signature: string,
  ): Promise<{ received: true; eventId: string }> {
    const verified = await this.billingProvider.verifyWebhookSignature(
      payload,
      signature,
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

    return { received: true, eventId: event.id };
  }
}
