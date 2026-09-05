import { BadGatewayException, Injectable } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";

type BriqSendSmsInput = {
  to: string;
  content: string;
};

@Injectable()
export class BriqMessagingService {
  constructor(private readonly config: ConfigService) {}

  async sendSms(input: BriqSendSmsInput): Promise<{
    provider: string;
    delivered: boolean;
  }> {
    const apiKey = this.config.getOrThrow<string>("BRIQ_API_KEY");
    const baseUrl = this.config
      .getOrThrow<string>("BRIQ_BASE_URL")
      .replace(/\/$/, "");
    const senderId = this.config.getOrThrow<string>("BRIQ_SENDER_ID");
    const response = await fetch(`${baseUrl}/v1/message/send-instant`, {
      method: "POST",
      signal: AbortSignal.timeout(20000),
      headers: {
        Accept: "application/json",
        "Content-Type": "application/json",
        "X-API-Key": apiKey,
      },
      body: JSON.stringify({
        content: input.content,
        recipients: [this.normalizeMsisdn(input.to)],
        sender_id: senderId,
      }),
    });

    if (!response.ok) {
      throw new BadGatewayException({
        message: "Briq SMS delivery failed.",
        statusCode: response.status,
        providerPayload: await this.readJson(response),
      });
    }

    return { provider: "briq-sms", delivered: true };
  }

  private normalizeMsisdn(value: string): string {
    const digits = value.replace(/\D/g, "");
    if (digits.startsWith("255")) return digits;
    if (digits.startsWith("0")) return `255${digits.slice(1)}`;
    if (digits.length === 9) return `255${digits}`;
    return digits;
  }

  private async readJson(response: Response): Promise<unknown> {
    const text = await response.text();
    if (!text) return null;
    try {
      return JSON.parse(text) as Record<string, unknown>;
    } catch {
      return { raw: text };
    }
  }
}
