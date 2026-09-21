import { Injectable, InternalServerErrorException } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import * as nodemailer from "nodemailer";
import { BriqMessagingService } from "../messaging/briq-messaging.service";
import { MetaWhatsAppService } from "../messaging/meta-whatsapp.service";
import { verificationEmailTemplate } from "./verification-email.template";

export type VerificationChannel = "sms" | "email" | "whatsapp";
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
  constructor(
    private readonly config: ConfigService,
    private readonly briq: BriqMessagingService,
    private readonly whatsapp: MetaWhatsAppService,
  ) {}

  async sendCode(input: VerificationInput): Promise<{
    provider: string;
    delivered: boolean;
  }> {
    if (input.channel === "sms") {
      return this.sendSms(input);
    }
    if (input.channel === "whatsapp") {
      return this.sendWhatsApp(input);
    }
    return this.sendEmail(input);
  }

  private async sendSms(input: VerificationInput): Promise<{
    provider: string;
    delivered: boolean;
  }> {
    return this.briq.sendSms({
      to: input.destination,
      content: this.smsMessage(input),
    });
  }

  private async sendWhatsApp(input: VerificationInput): Promise<{
    provider: string;
    delivered: boolean;
  }> {
    const templateName = this.config.get<string>(
      "AUTH_WHATSAPP_TEMPLATE_NAME",
      "auth_template",
    );
    return this.whatsapp.sendTemplate({
      to: input.destination,
      templateName,
      languageCode: this.config.get<string>(
        "AUTH_WHATSAPP_TEMPLATE_LANGUAGE",
        "en",
      ),
      bodyParameters: [
        { name: "code", text: input.code },
        { name: "text", text: this.whatsappActionText(input) },
      ],
      copyCodeButtonText: input.code,
    });
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

  private smsMessage(input: VerificationInput): string {
    const action = this.actionText(input);
    return `Your Vikoplus code is ${input.code}. Use it to ${action}. It expires in 10 minutes. Do not share it.`;
  }

  private actionText(input: VerificationInput): string {
    return input.purpose === "password_reset"
      ? "reset your Vikoplus password"
      : "verify your Vikoplus account";
  }

  private whatsappActionText(input: VerificationInput): string {
    return input.purpose === "password_reset" ? "password reset" : "verification";
  }
}
