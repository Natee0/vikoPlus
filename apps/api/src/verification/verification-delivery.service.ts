import { Injectable, InternalServerErrorException } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import * as nodemailer from "nodemailer";
import { BriqMessagingService } from "../messaging/briq-messaging.service";
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
  constructor(
    private readonly config: ConfigService,
    private readonly briq: BriqMessagingService,
  ) {}

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
    return this.briq.sendSms({
      to: input.destination,
      content: this.smsMessage(input),
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
    const action =
      input.purpose === "password_reset"
        ? "reset your Vikoplus password"
        : "verify your Vikoplus account";
    return `Your Vikoplus code is ${input.code}. Use it to ${action}. It expires in 10 minutes. Do not share it.`;
  }
}
