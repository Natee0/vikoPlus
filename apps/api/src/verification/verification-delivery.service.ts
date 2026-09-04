import {
  BadGatewayException,
  Injectable,
  InternalServerErrorException,
} from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import * as nodemailer from "nodemailer";
import { verificationEmailTemplate } from "./verification-email.template";

export type VerificationChannel = "sms" | "email";
export type VerificationPurpose = "account_verification" | "password_reset";

type VerificationInput = {
  channel: VerificationChannel;
  destination: string;
  code: string;
  name?: string | null;
  purpose?: VerificationPurpose;
};

@Injectable()
export class VerificationDeliveryService {
  constructor(private readonly config: ConfigService) {}

  async sendCode(input: VerificationInput): Promise<{
    provider: string;
    delivered: boolean;
  }> {
    if (input.channel === "sms") {
      return this.sendSms(input);
    }
    return this.sendEmail(input);
  }

  private async sendSms(input: VerificationInput): Promise<{
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
      headers: {
        Accept: "application/json",
        "Content-Type": "application/json",
        "X-API-Key": apiKey,
      },
      body: JSON.stringify({
        content: this.smsMessage(input),
        recipients: [this.normalizeMsisdn(input.destination)],
        sender_id: senderId,
      }),
    });

    if (!response.ok) {
      throw new BadGatewayException({
        message: "Briq verification SMS failed.",
        statusCode: response.status,
        providerPayload: await this.readJson(response),
      });
    }

    return { provider: "briq-sms", delivered: true };
  }

  private async sendEmail(input: VerificationInput): Promise<{
    provider: string;
    delivered: boolean;
  }> {
    const transport = nodemailer.createTransport({
      host: this.config.getOrThrow<string>("SMTP_HOST"),
      port: this.config.getOrThrow<number>("SMTP_PORT"),
      secure: this.config.getOrThrow<boolean>("SMTP_SECURE"),
      auth: {
        user: this.config.getOrThrow<string>("SMTP_USER"),
        pass: this.config.getOrThrow<string>("SMTP_PASSWORD"),
      },
    });

    try {
      const message = verificationEmailTemplate(input);
      await transport.sendMail({
        from: this.config.getOrThrow<string>("EMAIL_FROM"),
        to: input.destination,
        subject: message.subject,
        text: message.text,
        html: message.html,
      });
      return { provider: "smtp-email", delivered: true };
    } catch (error) {
      throw new InternalServerErrorException({
        message: "Verification email could not be sent.",
        error: error instanceof Error ? error.message : String(error),
      });
    }
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

  private smsMessage(input: VerificationInput): string {
    const action =
      input.purpose === "password_reset"
        ? "reset your Vikoplus password"
        : "verify your Vikoplus account";
    return `Your Vikoplus code is ${input.code}. Use it to ${action}. It expires in 10 minutes. Do not share it.`;
  }
}
