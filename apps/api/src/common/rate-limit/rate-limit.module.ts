import { Module } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { ThrottlerModule } from "@nestjs/throttler";

import { RedisModule } from "../../redis/redis.module";
import { RedisService } from "../../redis/redis.service";
import { RedisThrottlerStorage } from "./redis-throttler.storage";

@Module({
  imports: [
    RedisModule,
    ThrottlerModule.forRootAsync({
      inject: [ConfigService, RedisService],
      useFactory: (config: ConfigService, redis: RedisService) => ({
        storage: new RedisThrottlerStorage(redis),
        throttlers: [
          {
            name: "default",
            ttl: config.getOrThrow<number>("RATE_LIMIT_TTL_MS"),
            limit: config.getOrThrow<number>("RATE_LIMIT_MAX_REQUESTS"),
            blockDuration: config.getOrThrow<number>(
              "RATE_LIMIT_BLOCK_DURATION_MS",
            ),
          },
        ],
      }),
    }),
  ],
  exports: [ThrottlerModule],
})
export class RateLimitModule {}
