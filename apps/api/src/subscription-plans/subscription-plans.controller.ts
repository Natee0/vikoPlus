import { Controller, Get } from "@nestjs/common";
import { ApiOkResponse, ApiTags } from "@nestjs/swagger";
import { SubscriptionPlanDto } from "./subscription-plan.dto";
import { SubscriptionPlansService } from "./subscription-plans.service";

@ApiTags("subscription-plans")
@Controller({ path: "subscription-plans", version: "1" })
export class SubscriptionPlansController {
  constructor(private readonly plans: SubscriptionPlansService) {}

  @Get()
  @ApiOkResponse({ type: SubscriptionPlanDto, isArray: true })
  listPlans(): Promise<SubscriptionPlanDto[]> {
    return this.plans.listActivePlans();
  }
}
