import { Logger } from "@nestjs/common";
import { OnWorkerEvent, Processor, WorkerHost } from "@nestjs/bullmq";
import { Job } from "bullmq";
import { ReminderDispatchService } from "./reminder-dispatch.service";
import {
  REMINDER_QUEUE,
  SEND_REMINDER_SMS_JOB,
} from "./reminder-queue.constants";
import { SendReminderSmsJob } from "./reminder-queue.service";

@Processor(REMINDER_QUEUE, { concurrency: 4 })
export class ReminderQueueProcessor extends WorkerHost {
  private readonly logger = new Logger(ReminderQueueProcessor.name);

  constructor(private readonly reminders: ReminderDispatchService) {
    super();
  }

  async process(job: Job<SendReminderSmsJob>): Promise<void> {
    if (job.name !== SEND_REMINDER_SMS_JOB) {
      this.logger.warn(`Unknown reminder queue job ignored: ${job.name}`);
      return;
    }

    await this.reminders.send(
      job.data.groupId,
      job.data.key,
      job.data.phone,
      job.data.content,
    );
  }

  @OnWorkerEvent("failed")
  onFailed(job: Job<SendReminderSmsJob> | undefined, error: Error): void {
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
