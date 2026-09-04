import { Module } from "@nestjs/common";

import { BriqMessagingService } from "./briq-messaging.service";

@Module({
  providers: [BriqMessagingService],
  exports: [BriqMessagingService],
})
export class MessagingModule {}
