import { Body, Controller, Headers, Param, Post } from "@nestjs/common";
import { ApiTags } from "@nestjs/swagger";
import { BillingProvider } from "@prisma/client";
import { Public } from "../common/auth/public.decorator";
import { BillingWebhookService } from "./billing-webhook.service";

@ApiTags("billing-webhooks")
@Public()
@Controller({ path: "billing/webhooks", version: "1" })
export class BillingWebhooksController {
  constructor(private readonly webhooks: BillingWebhookService) {}

  @Post(":provider")
  async receiveWebhook(
    @Param("provider") provider: string,
    @Headers("x-vikoplus-signature") signature: string,
    @Body() body: Record<string, unknown>,
  ): Promise<{ received: true; eventId: string }> {
    const payload = Buffer.from(JSON.stringify(body), "utf8");
    return this.webhooks.receive(
      provider.toUpperCase() as BillingProvider,
      payload,
      signature,
    );
  }
}
