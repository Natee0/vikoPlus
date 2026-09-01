import { Injectable, NotFoundException } from "@nestjs/common";
import { ApiErrorCode } from "../common/errors/api-error-code";
import { PrismaService } from "../prisma/prisma.service";
import {
  calculateContributionReport,
  ContributionReport,
} from "./contribution-report.calculator";

@Injectable()
export class ReportsService {
  constructor(private readonly prisma: PrismaService) {}

  async getContributionReport(
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

    const selectedFinancialYearId =
      financialYearId ?? (await this.findActiveFinancialYearId(groupId));

    if (!selectedFinancialYearId) {
      return calculateContributionReport([]);
    }

    const obligations = await this.prisma.memberContributionObligation.findMany(
      {
        where: {
          member: { groupId },
          period: { financialYearId: selectedFinancialYearId },
        },
        include: {
          member: true,
          plan: true,
          period: true,
        },
      },
    );

    return calculateContributionReport(
      obligations.map((obligation) => ({
        memberId: obligation.member.id,
        memberNumber: obligation.member.memberNumber,
        memberName: obligation.member.fullName,
        planType: obligation.plan.type,
        periodLabel: obligation.period?.label ?? null,
        periodSortOrder: obligation.period?.sortOrder ?? null,
        amountDueMinor: obligation.amountDueMinor,
        amountPaidMinor: obligation.amountPaidMinor,
      })),
    );
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
