import { Module } from "@nestjs/common";

import { MobileApiController } from "./mobile-api.controller";
import { MobileApiService } from "./mobile-api.service";

@Module({
  controllers: [MobileApiController],
  providers: [MobileApiService],
})
export class MobileApiModule {}
