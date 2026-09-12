import { Module } from "@nestjs/common";
import { BullModule } from "@nestjs/bullmq";
import { PrismaModule } from "../prisma/prisma.module";

import { BriqMessagingService } from "./briq-messaging.service";
import { FirebasePushService } from "./firebase-push.service";
import { MESSAGING_QUEUE } from "./messaging-queue.constants";
import { MessagingQueueProcessor } from "./messaging-queue.processor";
import { MessagingQueueService } from "./messaging-queue.service";
import { SmtpEmailService } from "./smtp-email.service";

@Module({
  imports: [
    PrismaModule,
    BullModule.registerQueue({ name: MESSAGING_QUEUE }),
  ],
  providers: [
    BriqMessagingService,
    FirebasePushService,
    SmtpEmailService,
    MessagingQueueService,
    MessagingQueueProcessor,
  ],
  exports: [
    BriqMessagingService,
    FirebasePushService,
    SmtpEmailService,
    MessagingQueueService,
  ],
})
export class MessagingModule {}
