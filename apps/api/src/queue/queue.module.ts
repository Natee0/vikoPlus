import { Global, Module } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { BullModule } from "@nestjs/bullmq";
import type { ConnectionOptions } from "bullmq";

@Global()
@Module({
  imports: [
    BullModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        connection: redisConnectionFromUrl(
          config.getOrThrow<string>("REDIS_URL"),
        ),
        defaultJobOptions: {
          attempts: config.get<number>("QUEUE_MAX_ATTEMPTS") ?? 3,
          backoff: {
            type: "exponential",
            delay: config.get<number>("QUEUE_BACKOFF_MS") ?? 30000,
          },
          removeOnComplete: {
            age: config.get<number>("QUEUE_REMOVE_COMPLETE_SECONDS") ?? 86400,
            count: config.get<number>("QUEUE_REMOVE_COMPLETE_COUNT") ?? 1000,
          },
          removeOnFail: {
            age: config.get<number>("QUEUE_REMOVE_FAILED_SECONDS") ?? 604800,
            count: config.get<number>("QUEUE_REMOVE_FAILED_COUNT") ?? 5000,
          },
        },
      }),
    }),
  ],
  exports: [BullModule],
})
export class QueueModule {}

function redisConnectionFromUrl(rawUrl: string): ConnectionOptions {
  const url = new URL(rawUrl);
  const dbFromPath = Number(url.pathname.replace("/", ""));
  return {
    host: url.hostname,
    port: url.port ? Number(url.port) : 6379,
    username: url.username ? decodeURIComponent(url.username) : undefined,
    password: url.password ? decodeURIComponent(url.password) : undefined,
    db: Number.isFinite(dbFromPath) ? dbFromPath : undefined,
    tls: url.protocol === "rediss:" ? {} : undefined,
    maxRetriesPerRequest: null,
  };
}
