import { Controller, Get } from "@nestjs/common";
import { InjectQueue } from "@nestjs/bullmq";
import { ConfigService } from "@nestjs/config";
import { ApiOkResponse, ApiTags } from "@nestjs/swagger";
import { Job, Queue } from "bullmq";
import { Public } from "../common/auth/public.decorator";
import { REMINDER_QUEUE } from "../groups/reminder-queue.constants";
import { MESSAGING_QUEUE } from "../messaging/messaging-queue.constants";
import { PrismaService } from "../prisma/prisma.service";
import { RedisService } from "../redis/redis.service";

type HealthStatus = {
  status: "ok" | "degraded";
  service: "vikoplus-api";
  checks: {
    database: "ok" | "down";
    redis: "ok" | "down";
  };
};

type QueueHealthStatus = {
  status: "ok" | "degraded";
  service: "vikoplus-api";
  queues: QueueHealth[];
};

type QueueHealth = {
  name: string;
  status: "ok" | "degraded" | "down";
  paused: boolean;
  degradedReasons: string[];
  counts: {
    waiting: number;
    active: number;
    delayed: number;
    completed: number;
    failed: number;
  };
  backlog: {
    threshold: number;
    oldestWaitingAgeSeconds: number | null;
    oldestDelayedAgeSeconds: number | null;
  };
  recentFailures: QueueFailureSample[];
  error?: string;
};

type QueueFailureSample = {
  id: string;
  name: string;
  attemptsMade: number;
  failedReason: string | null;
  createdAt: string | null;
  finishedAt: string | null;
};

@ApiTags("health")
@Public()
@Controller({ path: "health", version: "1" })
export class HealthController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
    private readonly config: ConfigService,
    @InjectQueue(REMINDER_QUEUE) private readonly remindersQueue: Queue,
    @InjectQueue(MESSAGING_QUEUE) private readonly messagingQueue: Queue,
  ) {}

  @Get()
  @ApiOkResponse({ description: "API health status." })
  async getHealth(): Promise<HealthStatus> {
    const [database, redis] = await Promise.all([
      this.databaseStatus(),
      this.redisStatus(),
    ]);
    return {
      status: database === "ok" && redis === "ok" ? "ok" : "degraded",
      service: "vikoplus-api",
      checks: { database, redis },
    };
  }

  @Get("queues")
  @ApiOkResponse({ description: "Queue health and job counts." })
  async getQueuesHealth(): Promise<QueueHealthStatus> {
    const queues = await Promise.all([
      this.queueStatus(REMINDER_QUEUE, this.remindersQueue),
      this.queueStatus(MESSAGING_QUEUE, this.messagingQueue),
    ]);
    return {
      status: queues.every((queue) => queue.status === "ok")
        ? "ok"
        : "degraded",
      service: "vikoplus-api",
      queues,
    };
  }

  private async databaseStatus(): Promise<"ok" | "down"> {
    try {
      await this.prisma.$queryRaw`SELECT 1`;
      return "ok";
    } catch {
      return "down";
    }
  }

  private async redisStatus(): Promise<"ok" | "down"> {
    try {
      return (await this.redis.ping()) === "PONG" ? "ok" : "down";
    } catch {
      return "down";
    }
  }

  private async queueStatus(name: string, queue: Queue): Promise<QueueHealth> {
    try {
      const [counts, paused, waitingJobs, delayedJobs, failedJobs] =
        await Promise.all([
          queue.getJobCounts(
            "waiting",
            "active",
            "delayed",
            "completed",
            "failed",
          ),
          queue.isPaused(),
          queue.getWaiting(0, 0),
          queue.getDelayed(0, 0),
          queue.getFailed(0, 4),
        ]);
      const failed = counts.failed ?? 0;
      const waiting = counts.waiting ?? 0;
      const threshold = this.config.getOrThrow<number>(
        "QUEUE_WAITING_DEGRADED_THRESHOLD",
      );
      const degradedReasons = [
        ...(failed > 0 ? [`${failed} failed job${failed === 1 ? "" : "s"}`] : []),
        ...(waiting >= threshold
          ? [`${waiting} waiting jobs exceeds threshold ${threshold}`]
          : []),
        ...(paused ? ["queue is paused"] : []),
      ];
      return {
        name,
        status: degradedReasons.length > 0 ? "degraded" : "ok",
        paused,
        degradedReasons,
        counts: {
          waiting,
          active: counts.active ?? 0,
          delayed: counts.delayed ?? 0,
          completed: counts.completed ?? 0,
          failed,
        },
        backlog: {
          threshold,
          oldestWaitingAgeSeconds: this.oldestJobAgeSeconds(waitingJobs),
          oldestDelayedAgeSeconds: this.oldestJobAgeSeconds(delayedJobs),
        },
        recentFailures: failedJobs.map((job) => this.failureSample(job)),
      };
    } catch (error) {
      return {
        name,
        status: "down",
        paused: false,
        degradedReasons: ["queue status check failed"],
        counts: {
          waiting: 0,
          active: 0,
          delayed: 0,
          completed: 0,
          failed: 0,
        },
        backlog: {
          threshold:
            this.config.get<number>("QUEUE_WAITING_DEGRADED_THRESHOLD") ?? 100,
          oldestWaitingAgeSeconds: null,
          oldestDelayedAgeSeconds: null,
        },
        recentFailures: [],
        error: error instanceof Error ? error.message : String(error),
      };
    }
  }

  private oldestJobAgeSeconds(jobs: Job[]): number | null {
    const timestamps = jobs
      .map((job) => job.timestamp)
      .filter((value) => Number.isFinite(value));
    if (timestamps.length === 0) return null;
    return Math.max(
      0,
      Math.floor((Date.now() - Math.min(...timestamps)) / 1000),
    );
  }

  private failureSample(job: Job): QueueFailureSample {
    return {
      id: String(job.id ?? ""),
      name: job.name,
      attemptsMade: job.attemptsMade,
      failedReason: job.failedReason ?? null,
      createdAt: job.timestamp ? new Date(job.timestamp).toISOString() : null,
      finishedAt: job.finishedOn
        ? new Date(job.finishedOn).toISOString()
        : null,
    };
  }
}
