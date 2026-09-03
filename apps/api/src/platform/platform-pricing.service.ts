import { Injectable, ServiceUnavailableException } from "@nestjs/common";
import { SubscriptionPlanStatus } from "@prisma/client";
import { PrismaService } from "../prisma/prisma.service";

@Injectable()
export class PlatformPricingService {
  constructor(private readonly prisma: PrismaService) {}

  async publicPackages() {
    const [accessPlans, reminderPackages] = await Promise.all([
      this.prisma.subscriptionPlan.findMany({
        where: { status: SubscriptionPlanStatus.ACTIVE },
        orderBy: [
          { interval: "asc" },
          { intervalCount: "asc" },
          { priceMinor: "asc" },
        ],
      }),
      this.prisma.platformPrice.findMany({
        where: { isActive: true },
        orderBy: [{ channel: "asc" }, { amountMinor: "asc" }],
      }),
    ]);

    if (accessPlans.length === 0 || reminderPackages.length === 0) {
      throw new ServiceUnavailableException(
        "Platform packages are not configured.",
      );
    }

    return { accessPlans, reminderPackages };
  }

  async adminPackages() {
    const [accessPlans, reminderPackages] = await Promise.all([
      this.prisma.subscriptionPlan.findMany({
        orderBy: [
          { status: "asc" },
          { interval: "asc" },
          { intervalCount: "asc" },
          { priceMinor: "asc" },
        ],
      }),
      this.prisma.platformPrice.findMany({
        orderBy: [{ isActive: "desc" }, { channel: "asc" }, { code: "asc" }],
      }),
    ]);

    return {
      accessPlans,
      reminderPackages,
      isConfigured:
        accessPlans.some(
          (plan) => plan.status === SubscriptionPlanStatus.ACTIVE,
        ) && reminderPackages.some((item) => item.isActive),
    };
  }
}
