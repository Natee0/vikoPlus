import { Module } from "@nestjs/common";
import { BullModule } from "@nestjs/bullmq";
import { BillingModule } from "../billing/billing.module";
import { REMINDER_QUEUE } from "../groups/reminder-queue.constants";
import { MESSAGING_QUEUE } from "../messaging/messaging-queue.constants";
import { PlatformModule } from "../platform/platform.module";
import { QueueModule } from "../queue/queue.module";
import { AdminController } from "./admin.controller";
import { AdminQueueService } from "./admin-queue.service";
import { AdminService } from "./admin.service";

@Module({
  imports: [
    BillingModule,
    PlatformModule,
    QueueModule,
    BullModule.registerQueue(
      { name: REMINDER_QUEUE },
      { name: MESSAGING_QUEUE },
    ),
  ],
  controllers: [AdminController],
  providers: [AdminService, AdminQueueService],
})
export class AdminModule {}
