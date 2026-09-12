import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import { InjectQueue } from "@nestjs/bullmq";
import { Job, Queue } from "bullmq";
import { REMINDER_QUEUE } from "../groups/reminder-queue.constants";
import { MESSAGING_QUEUE } from "../messaging/messaging-queue.constants";

type QueueName = typeof REMINDER_QUEUE | typeof MESSAGING_QUEUE;

type QueueFailedJob = {
  id: string;
  name: string;
  attemptsMade: number;
  maxAttempts: number;
  failedReason: string | null;
  createdAt: string | null;
  processedAt: string | null;
  finishedAt: string | null;
};

@Injectable()
export class AdminQueueService {
  constructor(
    @InjectQueue(REMINDER_QUEUE) private readonly remindersQueue: Queue,
    @InjectQueue(MESSAGING_QUEUE) private readonly messagingQueue: Queue,
  ) {}

  async list() {
    const queues = await Promise.all([
      this.summary(REMINDER_QUEUE, this.remindersQueue),
      this.summary(MESSAGING_QUEUE, this.messagingQueue),
    ]);
    return { queues };
  }

  async failed(queueName: string, start = 0, end = 49) {
    const queue = this.queue(queueName);
    const safeStart = Math.max(0, start);
    const safeEnd = Math.min(Math.max(safeStart, end), safeStart + 99);
    const [jobs, failedCount] = await Promise.all([
      queue.getFailed(safeStart, safeEnd),
      queue.getJobCountByTypes("failed"),
    ]);
    return {
      queue: queueName,
      start: safeStart,
      end: safeEnd,
      failedCount,
      jobs: jobs.map((job) => this.failedJob(job)),
    };
  }

  async retryFailed(queueName: string, jobId: string) {
    const queue = this.queue(queueName);
    const job = await queue.getJob(jobId);
    if (!job) {
      throw new NotFoundException("Queue job was not found.");
    }
    const state = await job.getState();
    if (state !== "failed") {
      throw new BadRequestException(`Only failed jobs can be retried. Current state: ${state}.`);
    }
    await job.retry();
    return { queue: queueName, jobId, retried: true };
  }

  async cleanFailed(queueName: string, graceSeconds = 604800, limit = 1000) {
    const queue = this.queue(queueName);
    const safeGraceSeconds = Math.max(0, graceSeconds);
    const safeLimit = Math.min(Math.max(1, limit), 5000);
    const removedJobIds = await queue.clean(
      safeGraceSeconds * 1000,
      safeLimit,
      "failed",
    );
    return {
      queue: queueName,
      graceSeconds: safeGraceSeconds,
      removedCount: removedJobIds.length,
      removedJobIds,
    };
  }

  private async summary(name: QueueName, queue: Queue) {
    const [counts, paused, failedJobs] = await Promise.all([
      queue.getJobCounts("waiting", "active", "delayed", "completed", "failed"),
      queue.isPaused(),
      queue.getFailed(0, 4),
    ]);
    return {
      name,
      paused,
      counts: {
        waiting: counts.waiting ?? 0,
        active: counts.active ?? 0,
        delayed: counts.delayed ?? 0,
        completed: counts.completed ?? 0,
        failed: counts.failed ?? 0,
      },
      recentFailures: failedJobs.map((job) => this.failedJob(job)),
    };
  }

  private queue(queueName: string): Queue {
    if (queueName === REMINDER_QUEUE) return this.remindersQueue;
    if (queueName === MESSAGING_QUEUE) return this.messagingQueue;
    throw new BadRequestException(
      `Unknown queue "${queueName}". Use "${REMINDER_QUEUE}" or "${MESSAGING_QUEUE}".`,
    );
  }

  private failedJob(job: Job): QueueFailedJob {
    return {
      id: String(job.id ?? ""),
      name: job.name,
      attemptsMade: job.attemptsMade,
      maxAttempts: job.opts.attempts ?? 1,
      failedReason: job.failedReason ?? null,
      createdAt: job.timestamp ? new Date(job.timestamp).toISOString() : null,
      processedAt: job.processedOn
        ? new Date(job.processedOn).toISOString()
        : null,
      finishedAt: job.finishedOn
        ? new Date(job.finishedOn).toISOString()
        : null,
    };
  }
}
