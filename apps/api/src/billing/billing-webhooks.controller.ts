import { Body, Controller, Headers, Param, Post, Req } from "@nestjs/common";
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
    @Headers("x-sayari-signature") sayariSignature: string,
    @Headers("x-vikoplus-signature") legacySignature: string,
    @Body() body: Record<string, unknown>,
    @Req() req: { rawBody?: Buffer },
  ): Promise<{ received: true; eventId: string }> {
    const payload = req.rawBody ?? Buffer.from(JSON.stringify(body), "utf8");
    return this.webhooks.receive(
      provider.toUpperCase() as BillingProvider,
      payload,
      sayariSignature ?? legacySignature,
    );
  }
}
