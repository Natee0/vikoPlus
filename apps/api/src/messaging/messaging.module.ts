import { Module } from "@nestjs/common";

import { BriqMessagingService } from "./briq-messaging.service";
import { FirebasePushService } from "./firebase-push.service";
import { SmtpEmailService } from "./smtp-email.service";

@Module({
  providers: [BriqMessagingService, FirebasePushService, SmtpEmailService],
  exports: [BriqMessagingService, FirebasePushService, SmtpEmailService],
})
export class MessagingModule {}
