import { Controller, Get } from "@nestjs/common";
import { ApiOkResponse, ApiTags } from "@nestjs/swagger";
import { Public } from "../common/auth/public.decorator";
import { PrismaService } from "../prisma/prisma.service";
import { RedisService } from "../redis/redis.service";

type HealthStatus = {
  status: "ok" | "degraded";
  service: "vikoplus-api";
  checks: {
    database: "ok" | "down";
    redis: "ok" | "down";
  };
};

@ApiTags("health")
@Public()
@Controller({ path: "health", version: "1" })
export class HealthController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
  ) {}

  @Get()
  @ApiOkResponse({ description: "API health status." })
  async getHealth(): Promise<HealthStatus> {
    const [database, redis] = await Promise.all([
      this.databaseStatus(),
      this.redisStatus(),
    ]);
    return {
      status: database === "ok" && redis === "ok" ? "ok" : "degraded",
      service: "vikoplus-api",
      checks: { database, redis },
    };
  }

  private async databaseStatus(): Promise<"ok" | "down"> {
    try {
      await this.prisma.$queryRaw`SELECT 1`;
      return "ok";
    } catch {
      return "down";
    }
  }

  private async redisStatus(): Promise<"ok" | "down"> {
    try {
      return (await this.redis.ping()) === "PONG" ? "ok" : "down";
    } catch {
      return "down";
    }
  }
}
