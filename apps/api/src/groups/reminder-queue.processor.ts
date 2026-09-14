import { Logger } from "@nestjs/common";
import { OnWorkerEvent, Processor, WorkerHost } from "@nestjs/bullmq";
import { Job } from "bullmq";
import { ReminderDispatchService } from "./reminder-dispatch.service";
import {
  REMINDER_QUEUE,
  SEND_REMINDER_SMS_JOB,
  SEND_REMINDER_WHATSAPP_JOB,
} from "./reminder-queue.constants";
import {
  SendReminderSmsJob,
  SendReminderWhatsAppJob,
} from "./reminder-queue.service";

@Processor(REMINDER_QUEUE, { concurrency: 4 })
export class ReminderQueueProcessor extends WorkerHost {
  private readonly logger = new Logger(ReminderQueueProcessor.name);

  constructor(private readonly reminders: ReminderDispatchService) {
    super();
  }

  async process(
    job: Job<SendReminderSmsJob | SendReminderWhatsAppJob>,
  ): Promise<void> {
    if (job.name === SEND_REMINDER_SMS_JOB) {
      await this.reminders.sendSms(
        job.data.groupId,
        job.data.key,
        job.data.phone,
        job.data.content,
      );
      return;
    }

    if (job.name === SEND_REMINDER_WHATSAPP_JOB) {
      await this.reminders.sendWhatsApp(
        job.data.groupId,
        job.data.key,
        job.data.phone,
        job.data.content,
      );
      return;
    }

    this.logger.warn(`Unknown reminder queue job ignored: ${job.name}`);
  }

  @OnWorkerEvent("failed")
  onFailed(
    job: Job<SendReminderSmsJob | SendReminderWhatsAppJob> | undefined,
    error: Error,
  ): void {
    if (!job) {
      this.logger.error(`Reminder queue job failed without job context: ${error.message}`);
      return;
    }
    const maxAttempts = job.opts.attempts ?? 1;
    if (job.attemptsMade < maxAttempts) return;
    this.logger.error(
      `Reminder queue job permanently failed: ${job.name} (${job.id ?? "unknown"}) ` +
        `attempts ${job.attemptsMade}/${maxAttempts}. ${error.message}`,
    );
  }
}
