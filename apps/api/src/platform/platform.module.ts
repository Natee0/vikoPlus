import { Module } from "@nestjs/common";

import { PlatformController } from "./platform.controller";
import { PlatformPricingService } from "./platform-pricing.service";
import { PlatformService } from "./platform.service";

@Module({
  controllers: [PlatformController],
  providers: [PlatformPricingService, PlatformService],
  exports: [PlatformPricingService],
})
export class PlatformModule {}
