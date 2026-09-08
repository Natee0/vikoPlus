import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import {
  ContributionObligationStatus,
  GroupContributionPaymentStatus,
  GroupExpenseStatus,
  GroupLoanStatus,
  GroupMemberStatus,
  GroupRole,
} from "@prisma/client";
import { ApiErrorCode } from "../common/errors/api-error-code";
import { AuthenticatedUser } from "../common/auth/authenticated-user";
import { PrismaService } from "../prisma/prisma.service";
import {
  calculateContributionReport,
  ContributionReport,
  MemberContributionAnalysis,
} from "./contribution-report.calculator";
import {
  ContributionReportExportFormat,
  ContributionReportMemberStatus,
  ContributionReportQueryDto,
} from "./dto/contribution-report-query.dto";

@Injectable()
export class ReportsService {
  constructor(private readonly prisma: PrismaService) {}

  async getContributionReport(
    user: AuthenticatedUser,
    groupId: string,
    financialYearId?: string,
  ): Promise<ContributionReport> {
    const group = await this.prisma.group.findUnique({
      where: { id: groupId },
      select: { id: true },
    });
    if (!group) {
      throw new NotFoundException({
        code: ApiErrorCode.ResourceNotFound,
        message: "Group was not found.",
      });
    }
    const membership = await this.requireMembership(user, groupId);
    const rolesAllowedToSeeAllMembers: GroupRole[] = [
      GroupRole.GROUP_ADMIN,
      GroupRole.TREASURER,
      GroupRole.SECRETARY,
    ];
    const canSeeAllMembers = rolesAllowedToSeeAllMembers.includes(
      membership.role,
    );

    const selectedFinancialYearId =
      financialYearId ?? (await this.findActiveFinancialYearId(groupId));

    if (!selectedFinancialYearId) {
      return this.withGroupCashTotals(groupId, calculateContributionReport([]));
    }

    const obligations = await this.prisma.memberContributionObligation.findMany(
      {
        where: {
          member: {
            groupId,
            ...(canSeeAllMembers ? {} : { id: membership.id }),
          },
          period: { financialYearId: selectedFinancialYearId },
          dueAt: { lte: new Date() },
          status: {
            in: [
              ContributionObligationStatus.UPCOMING,
              ContributionObligationStatus.DUE,
              ContributionObligationStatus.PARTIALLY_PAID,
              ContributionObligationStatus.OVERDUE,
              ContributionObligationStatus.PAID,
            ],
          },
        },
        include: {
          member: true,
          plan: true,
          period: true,
        },
      },
    );
    const historicalAllocations = await this.prisma.paymentAllocation.findMany({
      where: {
        obligationId: null,
        payment: {
          groupId,
          status: GroupContributionPaymentStatus.APPROVED,
          member: {
            ...(canSeeAllMembers ? {} : { id: membership.id }),
          },
        },
      },
      include: {
        payment: { include: { member: true } },
        plan: true,
      },
    });

    const report = calculateContributionReport(
      [
        ...obligations.map((obligation) => ({
          memberId: obligation.member.id,
          memberNumber: obligation.member.memberNumber,
          memberName: obligation.member.fullName,
          planType: obligation.plan.type,
          periodLabel: obligation.period?.label ?? null,
          periodId: obligation.period?.id ?? null,
          periodSortOrder: obligation.period?.sortOrder ?? null,
          amountDueMinor: obligation.amountDueMinor,
          amountPaidMinor: obligation.amountPaidMinor,
        })),
        ...historicalAllocations.map((allocation) => ({
          memberId: allocation.payment.member.id,
          memberNumber: allocation.payment.member.memberNumber,
          memberName: allocation.payment.member.fullName,
          planType: allocation.plan.type,
          periodLabel: null,
          periodId: null,
          periodSortOrder: null,
          amountDueMinor: allocation.amountMinor,
          amountPaidMinor: allocation.amountMinor,
        })),
      ],
    );
    const plans = await this.prisma.contributionPlan.findMany({
      where: {
        groupId,
        OR: [
          { isActive: true },
          {
            obligations: {
              some: { period: { financialYearId: selectedFinancialYearId } },
            },
          },
        ],
      },
      select: {
        name: true,
        type: true,
        frequency: true,
        amountMinor: true,
        currency: true,
      },
      orderBy: { createdAt: "asc" },
    });
    return this.withGroupCashTotals(groupId, { ...report, rates: plans });
  }

  async exportContributionReport(
    user: AuthenticatedUser,
    groupId: string,
    query: ContributionReportQueryDto,
  ) {
    const format = query.format ?? ContributionReportExportFormat.csv;
    const report = await this.getContributionReport(
      user,
      groupId,
      query.financialYearId,
    );
    const members = this.filterMembersForExport(
      report.memberAnalysis,
      query.memberStatus ?? ContributionReportMemberStatus.all,
    );
    const content = this.contributionReportCsv(report, members);

    return {
      fileName: `vikoplus-contribution-report-${new Date()
        .toISOString()
        .slice(0, 10)}.${format}`,
      mimeType: "text/csv",
      format,
      content,
    };
  }

  private filterMembersForExport(
    members: MemberContributionAnalysis[],
    status: ContributionReportMemberStatus,
  ): MemberContributionAnalysis[] {
    if (status === ContributionReportMemberStatus.outstanding) {
      return members.filter((member) => member.outstandingMinor > 0);
    }
    if (status === ContributionReportMemberStatus.cleared) {
      return members.filter((member) => member.outstandingMinor <= 0);
    }
    return members;
  }

  private contributionReportCsv(
    report: ContributionReport,
    members: MemberContributionAnalysis[],
  ): string {
    const rows: string[][] = [
      ["Report", "Metric", "Value"],
      ["Summary", "Members", report.membersCount.toString()],
      ["Summary", "Total paid minor", report.totalPaidMinor.toString()],
      [
        "Summary",
        "Total outstanding minor",
        report.totalOutstandingMinor.toString(),
      ],
      [
        "Summary",
        "Joining fees paid minor",
        report.joiningFeesPaidMinor.toString(),
      ],
      ["Summary", "Recurring paid minor", report.recurringPaidMinor.toString()],
      [
        "Summary",
        "Approved expenses minor",
        report.approvedExpensesMinor.toString(),
      ],
      [
        "Summary",
        "Pending expenses minor",
        report.pendingExpensesMinor.toString(),
      ],
      [
        "Summary",
        "Active loan principal minor",
        report.activeLoanPrincipalMinor.toString(),
      ],
      [
        "Summary",
        "Active loan outstanding minor",
        report.activeLoanOutstandingMinor.toString(),
      ],
      [
        "Summary",
        "Net group cash balance minor",
        report.netCashBalanceMinor.toString(),
      ],
      [],
      ["Period totals", "Period", "Paid minor"],
      ...report.periodTotals.map((period) => [
        "Period",
        period.label,
        period.paidMinor.toString(),
      ]),
      [],
      [
        "Member analysis",
        "Member number",
        "Member name",
        "Joining fee paid minor",
        "Recurring paid minor",
        "Total paid minor",
        "Outstanding minor",
        "Paid recurring periods",
        "Percentage of group total",
      ],
      ...members.map((member) => [
        "Member",
        member.memberNumber ?? "",
        member.memberName,
        member.joiningFeePaidMinor.toString(),
        member.recurringPaidMinor.toString(),
        member.totalPaidMinor.toString(),
        member.outstandingMinor.toString(),
        member.paidRecurringPeriods.toString(),
        member.percentageOfGroupTotal.toString(),
      ]),
    ];

    return rows
      .map((row) => row.map((value) => this.csvCell(value)).join(","))
      .join("\n");
  }

  private csvCell(value: string): string {
    if (!/[",\n\r]/.test(value)) return value;
    return `"${value.replaceAll('"', '""')}"`;
  }

  private async withGroupCashTotals(
    groupId: string,
    report: ContributionReport,
  ): Promise<ContributionReport> {
    const [approvedExpenses, pendingExpenses, activeLoans] = await Promise.all([
      this.prisma.groupExpense.aggregate({
        where: { groupId, status: GroupExpenseStatus.APPROVED },
        _sum: { amountMinor: true },
      }),
      this.prisma.groupExpense.aggregate({
        where: { groupId, status: GroupExpenseStatus.SUBMITTED },
        _sum: { amountMinor: true },
      }),
      this.prisma.groupLoan.aggregate({
        where: { groupId, status: GroupLoanStatus.ACTIVE },
        _sum: { amountMinor: true, amountPaidMinor: true },
      }),
    ]);
    const approvedExpensesMinor = approvedExpenses._sum.amountMinor ?? 0;
    const activeLoanPrincipalMinor = activeLoans._sum.amountMinor ?? 0;
    const activeLoanOutstandingMinor = Math.max(
      activeLoanPrincipalMinor - (activeLoans._sum.amountPaidMinor ?? 0),
      0,
    );
    return {
      ...report,
      approvedExpensesMinor,
      pendingExpensesMinor: pendingExpenses._sum.amountMinor ?? 0,
      activeLoanPrincipalMinor,
      activeLoanOutstandingMinor,
      netCashBalanceMinor: Math.max(
        report.totalPaidMinor - approvedExpensesMinor - activeLoanOutstandingMinor,
        0,
      ),
    };
  }

  private async requireMembership(user: AuthenticatedUser, groupId: string) {
    const membership = await this.prisma.groupMember.findFirst({
      where: {
        userId: user.id,
        groupId,
        status: GroupMemberStatus.ACTIVE,
      },
      select: { id: true, role: true },
    });
    if (!membership) throw new ForbiddenException("Group access denied.");
    return membership;
  }

  private async findActiveFinancialYearId(
    groupId: string,
  ): Promise<string | undefined> {
    const activeFinancialYear = await this.prisma.financialYear.findFirst({
      where: { groupId, isActive: true },
      select: { id: true },
      orderBy: { startsAt: "desc" },
    });

    return activeFinancialYear?.id;
  }
}
