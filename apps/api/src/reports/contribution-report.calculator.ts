import { ContributionPlanType } from "@prisma/client";

export type ContributionReportObligation = {
  memberId: string;
  memberNumber: string | null;
  memberName: string;
  planType: ContributionPlanType;
  periodLabel: string | null;
  periodSortOrder: number | null;
  amountDueMinor: number;
  amountPaidMinor: number;
};

export type ContributionPeriodTotal = {
  label: string;
  sortOrder: number;
  paidMinor: number;
};

export type MemberContributionAnalysis = {
  memberId: string;
  memberNumber: string | null;
  memberName: string;
  joiningFeePaidMinor: number;
  recurringPaidMinor: number;
  totalPaidMinor: number;
  outstandingMinor: number;
  paidRecurringPeriods: number;
  percentageOfGroupTotal: number;
};

export type ContributionReport = {
  membersCount: number;
  totalPaidMinor: number;
  totalOutstandingMinor: number;
  joiningFeesPaidMinor: number;
  recurringPaidMinor: number;
  periodTotals: ContributionPeriodTotal[];
  memberAnalysis: MemberContributionAnalysis[];
};

export function calculateContributionReport(
  obligations: ContributionReportObligation[],
): ContributionReport {
  const members = new Map<string, MemberContributionAnalysis>();
  const periods = new Map<string, ContributionPeriodTotal>();

  let totalPaidMinor = 0;
  let totalOutstandingMinor = 0;
  let joiningFeesPaidMinor = 0;
  let recurringPaidMinor = 0;

  for (const obligation of obligations) {
    totalPaidMinor += obligation.amountPaidMinor;
    totalOutstandingMinor += Math.max(
      obligation.amountDueMinor - obligation.amountPaidMinor,
      0,
    );

    const member = getOrCreateMember(members, obligation);
    member.totalPaidMinor += obligation.amountPaidMinor;
    member.outstandingMinor += Math.max(
      obligation.amountDueMinor - obligation.amountPaidMinor,
      0,
    );

    if (obligation.planType === ContributionPlanType.JOINING_FEE) {
      joiningFeesPaidMinor += obligation.amountPaidMinor;
      member.joiningFeePaidMinor += obligation.amountPaidMinor;
      continue;
    }

    recurringPaidMinor += obligation.amountPaidMinor;
    member.recurringPaidMinor += obligation.amountPaidMinor;

    if (obligation.amountPaidMinor >= obligation.amountDueMinor) {
      member.paidRecurringPeriods += 1;
    }

    if (obligation.periodLabel && obligation.periodSortOrder !== null) {
      const period = periods.get(obligation.periodLabel) ?? {
        label: obligation.periodLabel,
        sortOrder: obligation.periodSortOrder,
        paidMinor: 0,
      };
      period.paidMinor += obligation.amountPaidMinor;
      periods.set(obligation.periodLabel, period);
    }
  }

  const memberAnalysis = Array.from(members.values())
    .map((member) => ({
      ...member,
      percentageOfGroupTotal:
        totalPaidMinor === 0
          ? 0
          : Number(((member.totalPaidMinor / totalPaidMinor) * 100).toFixed(2)),
    }))
    .sort((left, right) => left.memberName.localeCompare(right.memberName));

  return {
    membersCount: members.size,
    totalPaidMinor,
    totalOutstandingMinor,
    joiningFeesPaidMinor,
    recurringPaidMinor,
    periodTotals: Array.from(periods.values()).sort(
      (left, right) => left.sortOrder - right.sortOrder,
    ),
    memberAnalysis,
  };
}

function getOrCreateMember(
  members: Map<string, MemberContributionAnalysis>,
  obligation: ContributionReportObligation,
): MemberContributionAnalysis {
  const existing = members.get(obligation.memberId);
  if (existing) return existing;

  const member = {
    memberId: obligation.memberId,
    memberNumber: obligation.memberNumber,
    memberName: obligation.memberName,
    joiningFeePaidMinor: 0,
    recurringPaidMinor: 0,
    totalPaidMinor: 0,
    outstandingMinor: 0,
    paidRecurringPeriods: 0,
    percentageOfGroupTotal: 0,
  };
  members.set(obligation.memberId, member);
  return member;
}
