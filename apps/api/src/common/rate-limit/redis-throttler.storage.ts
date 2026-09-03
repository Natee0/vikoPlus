import { Injectable, OnModuleDestroy } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { ThrottlerStorage } from "@nestjs/throttler";
import { ThrottlerStorageRecord } from "@nestjs/throttler/dist/throttler-storage-record.interface";
import { createClient, RedisClientType } from "redis";

@Injectable()
export class RedisThrottlerStorage
  implements ThrottlerStorage, OnModuleDestroy
{
  private client?: RedisClientType;

  constructor(private readonly config: ConfigService) {}

  async increment(
    key: string,
    ttl: number,
    limit: number,
    blockDuration: number,
    throttlerName: string,
  ): Promise<ThrottlerStorageRecord> {
    const client = await this.redis();
    const namespacedKey = `vikoplus:rate-limit:${throttlerName}:${key}`;
    const blockKey = `${namespacedKey}:blocked`;
    const blockedTtl = await client.pTTL(blockKey);
    if (blockedTtl > 0) {
      return {
        totalHits: limit + 1,
        timeToExpire: Math.ceil(ttl / 1000),
        isBlocked: true,
        timeToBlockExpire: Math.ceil(blockedTtl / 1000),
      };
    }

    const totalHits = await client.incr(namespacedKey);
    if (totalHits === 1) {
      await client.pExpire(namespacedKey, ttl);
    }

    const keyTtl = await client.pTTL(namespacedKey);
    const isBlocked = totalHits > limit;
    if (isBlocked) {
      await client.set(blockKey, "1", { PX: blockDuration });
    }

    return {
      totalHits,
      timeToExpire: Math.ceil(Math.max(keyTtl, 0) / 1000),
      isBlocked,
      timeToBlockExpire: isBlocked ? Math.ceil(blockDuration / 1000) : 0,
    };
  }

  async onModuleDestroy(): Promise<void> {
    if (this.client?.isOpen) {
      await this.client.quit();
    }
  }

  private async redis(): Promise<RedisClientType> {
    if (this.client?.isOpen) return this.client;
    this.client = createClient({
      url: this.config.getOrThrow<string>("REDIS_URL"),
    });
    await this.client.connect();
    return this.client;
  }
}
