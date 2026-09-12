import { Injectable } from "@nestjs/common";
import { InjectQueue } from "@nestjs/bullmq";
import { Queue } from "bullmq";
import { REMINDER_QUEUE, SEND_REMINDER_SMS_JOB } from "./reminder-queue.constants";

export type SendReminderSmsJob = {
  groupId: string;
  key: string;
  phone: string;
  content: string;
};

@Injectable()
export class ReminderQueueService {
  constructor(@InjectQueue(REMINDER_QUEUE) private readonly queue: Queue) {}

  async enqueueSms(job: SendReminderSmsJob): Promise<boolean> {
    const result = await this.queue.add(SEND_REMINDER_SMS_JOB, job, {
      jobId: job.key,
    });
    return Boolean(result);
  }
}
