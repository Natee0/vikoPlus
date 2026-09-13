import { Controller, Get } from "@nestjs/common";
import { ApiOkResponse, ApiTags } from "@nestjs/swagger";
import { Throttle } from "@nestjs/throttler";
import { Public } from "../common/auth/public.decorator";
import { SubscriptionPlanDto } from "./subscription-plan.dto";
import { SubscriptionPlansService } from "./subscription-plans.service";

@ApiTags("subscription-plans")
@Public()
@Controller({ path: "subscription-plans", version: "1" })
export class SubscriptionPlansController {
  constructor(private readonly plans: SubscriptionPlansService) {}

  @Get()
  @Throttle({ default: { limit: 120, ttl: 60000, blockDuration: 60000 } })
  @ApiOkResponse({ type: SubscriptionPlanDto, isArray: true })
  listPlans(): Promise<SubscriptionPlanDto[]> {
    return this.plans.listActivePlans();
  }
}
