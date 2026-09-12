import { Module } from "@nestjs/common";
import { BullModule } from "@nestjs/bullmq";
import { REMINDER_QUEUE } from "../groups/reminder-queue.constants";
import { MESSAGING_QUEUE } from "../messaging/messaging-queue.constants";
import { PrismaModule } from "../prisma/prisma.module";
import { QueueModule } from "../queue/queue.module";
import { RedisModule } from "../redis/redis.module";
import { HealthController } from "./health.controller";

@Module({
  imports: [
    PrismaModule,
    RedisModule,
    QueueModule,
    BullModule.registerQueue(
      { name: REMINDER_QUEUE },
      { name: MESSAGING_QUEUE },
    ),
  ],
  controllers: [HealthController],
})
export class HealthModule {}
