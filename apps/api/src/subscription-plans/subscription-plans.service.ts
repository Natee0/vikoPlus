import { Injectable } from "@nestjs/common";
import { SubscriptionPlanStatus } from "@prisma/client";
import { PrismaService } from "../prisma/prisma.service";
import { SubscriptionPlanDto } from "./subscription-plan.dto";

@Injectable()
export class SubscriptionPlansService {
  constructor(private readonly prisma: PrismaService) {}

  async listActivePlans(): Promise<SubscriptionPlanDto[]> {
    return this.prisma.subscriptionPlan.findMany({
      where: { status: SubscriptionPlanStatus.ACTIVE },
      orderBy: [{ priceMinor: "asc" }, { code: "asc" }],
    });
  }
}
