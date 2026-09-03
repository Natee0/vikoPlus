import { Module } from "@nestjs/common";

import { VerificationDeliveryService } from "./verification-delivery.service";

@Module({
  providers: [VerificationDeliveryService],
  exports: [VerificationDeliveryService],
})
export class VerificationModule {}
