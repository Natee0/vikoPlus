import { Module } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { ThrottlerModule } from "@nestjs/throttler";

import { RedisThrottlerStorage } from "./redis-throttler.storage";

@Module({
  imports: [
    ThrottlerModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        storage: new RedisThrottlerStorage(config),
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
