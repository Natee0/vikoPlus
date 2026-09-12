import { Logger } from "@nestjs/common";
import { OnWorkerEvent, Processor, WorkerHost } from "@nestjs/bullmq";
import { Job } from "bullmq";
import { PrismaService } from "../prisma/prisma.service";
import { BriqMessagingService } from "./briq-messaging.service";
import { FirebasePushService } from "./firebase-push.service";
import {
  MESSAGING_QUEUE,
  SEND_EMAIL_JOB,
  SEND_PUSH_NOTIFICATION_JOB,
  SEND_SMS_JOB,
} from "./messaging-queue.constants";
import {
  SendEmailJob,
  SendPushNotificationJob,
  SendSmsJob,
} from "./messaging-queue.service";
import { SmtpEmailService } from "./smtp-email.service";

@Processor(MESSAGING_QUEUE, { concurrency: 6 })
export class MessagingQueueProcessor extends WorkerHost {
  private readonly logger = new Logger(MessagingQueueProcessor.name);

  constructor(
    private readonly briq: BriqMessagingService,
    private readonly email: SmtpEmailService,
    private readonly push: FirebasePushService,
    private readonly prisma: PrismaService,
  ) {
    super();
  }

  async process(
    job: Job<SendSmsJob | SendEmailJob | SendPushNotificationJob>,
  ): Promise<void> {
    if (job.name === SEND_SMS_JOB) {
      const data = job.data as SendSmsJob;
      await this.briq.sendSms(data);
      return;
    }

    if (job.name === SEND_EMAIL_JOB) {
      const data = job.data as SendEmailJob;
      await this.email.sendEmail(data);
      return;
    }

    if (job.name === SEND_PUSH_NOTIFICATION_JOB) {
      await this.sendPush(job.data as SendPushNotificationJob);
      return;
    }

    this.logger.warn(`Unknown messaging queue job ignored: ${job.name}`);
  }

  private async sendPush(job: SendPushNotificationJob): Promise<void> {
    const notification = await this.prisma.notification.findUnique({
      where: { id: job.notificationId },
      include: { user: { include: { pushDeviceTokens: true } } },
    });
    if (!notification) return;

    const pushResult = await this.push.sendToTokens(
      notification.user.pushDeviceTokens.map((item) => item.token),
      {
        title: notification.title,
        body: notification.body,
        data: { notificationId: notification.id },
      },
    );

    if (pushResult.invalidTokens.length > 0) {
      await this.prisma.pushDeviceToken.deleteMany({
        where: { token: { in: pushResult.invalidTokens } },
      });
    }
  }

  @OnWorkerEvent("failed")
  onFailed(
    job: Job<SendSmsJob | SendEmailJob | SendPushNotificationJob> | undefined,
    error: Error,
  ): void {
    if (!job) {
      this.logger.error(`Messaging queue job failed without job context: ${error.message}`);
      return;
    }
    const maxAttempts = job.opts.attempts ?? 1;
    if (job.attemptsMade < maxAttempts) return;
    this.logger.error(
      `Messaging queue job permanently failed: ${job.name} (${job.id ?? "unknown"}) ` +
        `attempts ${job.attemptsMade}/${maxAttempts}. ${error.message}`,
    );
  }
}
