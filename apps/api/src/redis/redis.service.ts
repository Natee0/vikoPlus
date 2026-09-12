import { Injectable, OnModuleDestroy } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { createClient, RedisClientType } from "redis";

@Injectable()
export class RedisService implements OnModuleDestroy {
  private client?: RedisClientType;

  constructor(private readonly config: ConfigService) {}

  async getClient(): Promise<RedisClientType> {
    if (this.client?.isOpen) return this.client;

    this.client = createClient({
      url: this.config.getOrThrow<string>("REDIS_URL"),
      socket: {
        reconnectStrategy: (retries) => Math.min(retries * 50, 1000),
      },
    });
    await this.client.connect();
    return this.client;
  }

  async ping(): Promise<string> {
    return (await this.getClient()).ping();
  }

  async onModuleDestroy(): Promise<void> {
    if (this.client?.isOpen) {
      await this.client.quit();
    }
  }
}
