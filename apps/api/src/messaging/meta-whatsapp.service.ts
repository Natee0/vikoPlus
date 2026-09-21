import {
  BadGatewayException,
  Injectable,
  InternalServerErrorException,
  Logger,
} from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { createHmac } from "crypto";

export type SendWhatsAppInput = {
  to: string;
  content: string;
};

export type SendWhatsAppTemplateInput = {
  to: string;
  templateName: string;
  languageCode?: string;
  bodyParameters: Array<string | { name?: string; text: string }>;
};

@Injectable()
export class MetaWhatsAppService {
  private readonly logger = new Logger(MetaWhatsAppService.name);

  constructor(private readonly config: ConfigService) {}

  async sendText(input: SendWhatsAppInput): Promise<{
    provider: string;
    providerRef: string;
    delivered: boolean;
  }> {
    return this.sendMetaPayload({
      messaging_product: "whatsapp",
      recipient_type: "individual",
      to: this.normalizeMetaPhone(input.to),
      type: "text",
      text: {
        preview_url: true,
        body: input.content,
      },
    });
  }

  async sendTemplate(input: SendWhatsAppTemplateInput): Promise<{
    provider: string;
    providerRef: string;
    delivered: boolean;
  }> {
    return this.sendMetaPayload({
      messaging_product: "whatsapp",
      recipient_type: "individual",
      to: this.normalizeMetaPhone(input.to),
      type: "template",
      template: {
        name: input.templateName,
        language: {
          code: input.languageCode ?? "en",
        },
        components: [
          {
            type: "body",
            parameters: input.bodyParameters.map((parameter) =>
              this.templateTextParameter(parameter),
            ),
          },
        ],
      },
    });
  }

  private async sendMetaPayload(body: Record<string, unknown>): Promise<{
    provider: string;
    providerRef: string;
    delivered: boolean;
  }> {
    const provider = this.config.get<string>("WHATSAPP_PROVIDER", "disabled");
    if (provider !== "meta") {
      throw new InternalServerErrorException(
        'WhatsApp provider is not configured. Set WHATSAPP_PROVIDER="meta".',
      );
    }

    const accessToken = this.config.get<string>("META_WHATSAPP_ACCESS_TOKEN");
    const phoneNumberId = this.config.get<string>("META_WHATSAPP_PHONE_NUMBER_ID");
    if (!accessToken) {
      throw new InternalServerErrorException(
        "META_WHATSAPP_ACCESS_TOKEN is required when WhatsApp provider is Meta.",
      );
    }
    if (!phoneNumberId) {
      throw new InternalServerErrorException(
        "META_WHATSAPP_PHONE_NUMBER_ID is required when WhatsApp provider is Meta.",
      );
    }

    const apiVersion = this.config.get<string>("META_GRAPH_API_VERSION", "v24.0");
    const baseUrl = this.config
      .get<string>("META_GRAPH_BASE_URL", "https://graph.facebook.com")
      .replace(/\/$/, "");
    const requestUrl = this.metaGraphUrl(
      `${baseUrl}/${apiVersion}/${phoneNumberId}/messages`,
      accessToken,
    );
    const response = await fetch(requestUrl, {
      method: "POST",
      signal: AbortSignal.timeout(20000),
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
    });
    const payload = await this.readJson(response);

    if (!response.ok) {
      this.logger.error(
        `Meta WhatsApp send failed with HTTP ${response.status}: ${JSON.stringify(
          payload,
        )}`,
      );
      throw new BadGatewayException({
        message: "Meta WhatsApp send failed.",
        statusCode: response.status,
        providerPayload: payload,
      });
    }

    return {
      provider: "meta-whatsapp",
      providerRef: this.extractMetaMessageId(payload) ?? "meta-whatsapp",
      delivered: true,
    };
  }

  private metaGraphUrl(url: string, accessToken: string): string {
    const appSecret =
      this.config.get<string>("META_WHATSAPP_APP_SECRET") ??
      this.config.get<string>("META_APP_SECRET") ??
      this.config.get<string>("WHATSAPP_APP_SECRET");
    if (!appSecret) return url;
    const proof = createHmac("sha256", appSecret)
      .update(accessToken)
      .digest("hex");
    const separator = url.includes("?") ? "&" : "?";
    return `${url}${separator}appsecret_proof=${encodeURIComponent(proof)}`;
  }

  private normalizeMetaPhone(value: string): string {
    const digits = value.replace(/\D/g, "");
    if (digits.startsWith("255")) return digits;
    if (digits.startsWith("0")) return `255${digits.slice(1)}`;
    if (digits.length === 9) return `255${digits}`;
    return digits;
  }

  private templateTextParameter(
    parameter: string | { name?: string; text: string },
  ): Record<string, string> {
    if (typeof parameter === "string") {
      return {
        type: "text",
        text: parameter,
      };
    }

    return {
      type: "text",
      ...(parameter.name ? { parameter_name: parameter.name } : {}),
      text: parameter.text,
    };
  }

  private extractMetaMessageId(payload: unknown): string | null {
    if (!payload || typeof payload !== "object") return null;
    const record = payload as Record<string, unknown>;
    const messages = Array.isArray(record.messages) ? record.messages : [];
    const first = messages[0] as Record<string, unknown> | undefined;
    return typeof first?.id === "string" ? first.id : null;
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
