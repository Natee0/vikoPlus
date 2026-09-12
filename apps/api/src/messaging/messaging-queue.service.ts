import { Injectable } from "@nestjs/common";
import { InjectQueue } from "@nestjs/bullmq";
import { Queue } from "bullmq";
import {
  MESSAGING_QUEUE,
  SEND_EMAIL_JOB,
  SEND_PUSH_NOTIFICATION_JOB,
  SEND_SMS_JOB,
} from "./messaging-queue.constants";

export type SendSmsJob = {
  to: string;
  content: string;
};

export type SendEmailJob = {
  to: string;
  subject: string;
  text: string;
  html: string;
};

export type SendPushNotificationJob = {
  notificationId: string;
};

@Injectable()
export class MessagingQueueService {
  constructor(@InjectQueue(MESSAGING_QUEUE) private readonly queue: Queue) {}

  async enqueueSms(job: SendSmsJob, jobId?: string): Promise<void> {
    await this.queue.add(SEND_SMS_JOB, job, { jobId });
  }

  async enqueueEmail(job: SendEmailJob, jobId?: string): Promise<void> {
    await this.queue.add(SEND_EMAIL_JOB, job, { jobId });
  }

  async enqueuePush(job: SendPushNotificationJob): Promise<void> {
    await this.queue.add(SEND_PUSH_NOTIFICATION_JOB, job, {
      jobId: job.notificationId,
      delay: 3000,
    });
  }
}
