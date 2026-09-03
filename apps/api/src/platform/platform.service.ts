import { Injectable } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { PlatformPricingService } from "./platform-pricing.service";

@Injectable()
export class PlatformService {
  constructor(
    private readonly config: ConfigService,
    private readonly pricing: PlatformPricingService,
  ) {}

  async bootstrap() {
    const packages = await this.pricing.publicPackages();

    return {
      defaultLocale: this.config.getOrThrow<string>("DEFAULT_LOCALE"),
      supportedLocales: ["en", "sw"],
      packages,
    };
  }
}
