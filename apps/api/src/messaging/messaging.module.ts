import { Module } from "@nestjs/common";

import { BriqMessagingService } from "./briq-messaging.service";
import { SmtpEmailService } from "./smtp-email.service";

@Module({
  providers: [BriqMessagingService, SmtpEmailService],
  exports: [BriqMessagingService, SmtpEmailService],
})
export class MessagingModule {}
