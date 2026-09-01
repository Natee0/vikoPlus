import { ApiProperty } from "@nestjs/swagger";
import { SubscriptionState } from "@prisma/client";

export class SubscriptionDto {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  groupId!: string;

  @ApiProperty()
  planCode!: string;

  @ApiProperty({ enum: SubscriptionState })
  state!: SubscriptionState;

  @ApiProperty()
  hasPaidFeatureAccess!: boolean;

  @ApiProperty({ nullable: true })
  currentPeriodEndsAt!: Date | null;

  @ApiProperty()
  cancelAtPeriodEnd!: boolean;
}
