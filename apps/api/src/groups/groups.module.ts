import { Module } from "@nestjs/common";
import { BullModule } from "@nestjs/bullmq";

import { BillingModule } from "../billing/billing.module";
import { MessagingModule } from "../messaging/messaging.module";
import { PrismaModule } from "../prisma/prisma.module";
import { GroupsController } from "./groups.controller";
import { GroupsService } from "./groups.service";
import { REMINDER_QUEUE } from "./reminder-queue.constants";
import { ReminderQueueProcessor } from "./reminder-queue.processor";
import { ReminderQueueService } from "./reminder-queue.service";
import { ReminderDispatchService } from "./reminder-dispatch.service";

@Module({
  imports: [
    PrismaModule,
    BillingModule,
    MessagingModule,
    BullModule.registerQueue({ name: REMINDER_QUEUE }),
  ],
  controllers: [GroupsController],
  providers: [
    GroupsService,
    ReminderDispatchService,
    ReminderQueueService,
    ReminderQueueProcessor,
  ],
})
export class GroupsModule {}
