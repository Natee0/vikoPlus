import { ApiProperty } from "@nestjs/swagger";

export class ContributionPeriodTotalDto {
  @ApiProperty()
  label!: string;

  @ApiProperty()
  sortOrder!: number;

  @ApiProperty()
  paidMinor!: number;
}

export class MemberContributionAnalysisDto {
  @ApiProperty()
  memberId!: string;

  @ApiProperty({ nullable: true })
  memberNumber!: string | null;

  @ApiProperty()
  memberName!: string;

  @ApiProperty()
  joiningFeePaidMinor!: number;

  @ApiProperty()
  recurringPaidMinor!: number;

  @ApiProperty()
  totalPaidMinor!: number;

  @ApiProperty()
  outstandingMinor!: number;

  @ApiProperty()
  paidRecurringPeriods!: number;

  @ApiProperty()
  percentageOfGroupTotal!: number;
}

export class ContributionReportDto {
  @ApiProperty()
  membersCount!: number;

  @ApiProperty()
  totalPaidMinor!: number;

  @ApiProperty()
  totalOutstandingMinor!: number;

  @ApiProperty()
  joiningFeesPaidMinor!: number;

  @ApiProperty()
  recurringPaidMinor!: number;

  @ApiProperty({ type: [ContributionPeriodTotalDto] })
  periodTotals!: ContributionPeriodTotalDto[];

  @ApiProperty({ type: [MemberContributionAnalysisDto] })
  memberAnalysis!: MemberContributionAnalysisDto[];
}
