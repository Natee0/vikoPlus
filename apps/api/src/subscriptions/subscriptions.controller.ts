import { Body, Controller, Get, Param, Post, Query } from "@nestjs/common";
import { ApiOkResponse, ApiTags } from "@nestjs/swagger";
import { CurrentUser } from "../common/auth/auth-user.decorator";
import { AuthenticatedUser } from "../common/auth/authenticated-user";
import { BillingPortalQueryDto } from "./dto/billing-portal-query.dto";
import { CreateCheckoutDto } from "./dto/create-checkout.dto";
import { SubscriptionDto } from "./dto/subscription.dto";
import { SubscriptionsService } from "./subscriptions.service";

@ApiTags("subscriptions")
@Controller({ path: "groups/:groupId/subscription", version: "1" })
export class SubscriptionsController {
  constructor(private readonly subscriptions: SubscriptionsService) {}

  @Get()
  @ApiOkResponse({ type: SubscriptionDto })
  getGroupSubscription(
    @Param("groupId") groupId: string,
  ): Promise<SubscriptionDto> {
    return this.subscriptions.getGroupSubscription(groupId);
  }

  @Post("checkout")
  createCheckout(
    @CurrentUser() user: AuthenticatedUser,
    @Param("groupId") groupId: string,
    @Body() body: CreateCheckoutDto,
  ): Promise<{ checkoutUrl: string; expiresAt: Date }> {
    return this.subscriptions.createCheckout(user, groupId, body);
  }

  @Get("billing-portal")
  createBillingPortal(
    @CurrentUser() user: AuthenticatedUser,
    @Param("groupId") groupId: string,
    @Query() query: BillingPortalQueryDto,
  ): Promise<{ portalUrl: string; expiresAt: Date }> {
    return this.subscriptions.createBillingPortal(user, groupId, query.returnUrl);
  }

  @Post("cancel")
  @ApiOkResponse({ type: SubscriptionDto })
  cancel(
    @CurrentUser() user: AuthenticatedUser,
    @Param("groupId") groupId: string,
  ): Promise<SubscriptionDto> {
    return this.subscriptions.cancel(user, groupId);
  }

  @Post("resume")
  @ApiOkResponse({ type: SubscriptionDto })
  resume(
    @CurrentUser() user: AuthenticatedUser,
    @Param("groupId") groupId: string,
  ): Promise<SubscriptionDto> {
    return this.subscriptions.resume(user, groupId);
  }
}
