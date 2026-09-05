import { Injectable, InternalServerErrorException } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import * as nodemailer from "nodemailer";

type SendEmailInput = {
  to: string;
  subject: string;
  text: string;
  html: string;
};

@Injectable()
export class SmtpEmailService {
  constructor(private readonly config: ConfigService) {}

  async sendEmail(input: SendEmailInput): Promise<{
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
      await transport.sendMail({
        from: this.config.getOrThrow<string>("EMAIL_FROM"),
        to: input.to,
        subject: input.subject,
        text: input.text,
        html: input.html,
      });
      return { provider: "smtp-email", delivered: true };
    } catch (error) {
      throw new InternalServerErrorException({
        message: "Email delivery failed.",
        error: error instanceof Error ? error.message : String(error),
      });
    }
  }
}
