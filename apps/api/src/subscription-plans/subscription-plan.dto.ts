import { ApiProperty } from "@nestjs/swagger";
import { BillingInterval, SubscriptionPlanStatus } from "@prisma/client";

export class SubscriptionPlanDto {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  code!: string;

  @ApiProperty()
  name!: string;

  @ApiProperty({ nullable: true })
  description!: string | null;

  @ApiProperty()
  priceMinor!: number;

  @ApiProperty()
  currency!: string;

  @ApiProperty({ enum: BillingInterval })
  interval!: BillingInterval;

  @ApiProperty()
  trialDays!: number;

  @ApiProperty({ enum: SubscriptionPlanStatus })
  status!: SubscriptionPlanStatus;

  @ApiProperty()
  featureEntitlements!: unknown;
}
