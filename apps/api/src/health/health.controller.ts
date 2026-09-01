import { Controller, Get } from "@nestjs/common";
import { ApiOkResponse, ApiTags } from "@nestjs/swagger";

@ApiTags("health")
@Controller({ path: "health", version: "1" })
export class HealthController {
  @Get()
  @ApiOkResponse({ description: "API health status." })
  getHealth(): { status: "ok"; service: "vikoplus-api" } {
    return { status: "ok", service: "vikoplus-api" };
  }
}
