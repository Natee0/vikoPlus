import { Controller, Get } from "@nestjs/common";
import { ApiTags } from "@nestjs/swagger";

import { Public } from "../common/auth/public.decorator";
import { PlatformService } from "./platform.service";

@ApiTags("app")
@Public()
@Controller({ path: "app", version: "1" })
export class PlatformController {
  constructor(private readonly platform: PlatformService) {}

  @Get("bootstrap")
  bootstrap() {
    return this.platform.bootstrap();
  }
}
