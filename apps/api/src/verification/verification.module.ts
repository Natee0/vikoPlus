import { Module } from "@nestjs/common";

import { MessagingModule } from "../messaging/messaging.module";
import { VerificationDeliveryService } from "./verification-delivery.service";

@Module({
  imports: [MessagingModule],
  providers: [VerificationDeliveryService],
  exports: [VerificationDeliveryService],
})
export class VerificationModule {}
