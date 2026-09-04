import { Controller, Get, Param, Query } from "@nestjs/common";
import { ApiOkResponse, ApiTags } from "@nestjs/swagger";
import { CurrentUser } from "../common/auth/auth-user.decorator";
import { AuthenticatedUser } from "../common/auth/authenticated-user";
import {
  ContributionReportDto,
  MemberContributionAnalysisDto,
} from "./dto/contribution-report.dto";
import { ContributionReportQueryDto } from "./dto/contribution-report-query.dto";
import { ReportsService } from "./reports.service";

@ApiTags("reports")
@Controller({ path: "groups/:groupId/reports/contributions", version: "1" })
export class ReportsController {
  constructor(private readonly reports: ReportsService) {}

  @Get("summary")
  @ApiOkResponse({ type: ContributionReportDto })
  getContributionReport(
    @CurrentUser() user: AuthenticatedUser,
    @Param("groupId") groupId: string,
    @Query() query: ContributionReportQueryDto,
  ): Promise<ContributionReportDto> {
    return this.reports.getContributionReport(
      user,
      groupId,
      query.financialYearId,
    );
  }

  @Get("members")
  @ApiOkResponse({ type: [MemberContributionAnalysisDto] })
  async getMemberAnalysis(
    @CurrentUser() user: AuthenticatedUser,
    @Param("groupId") groupId: string,
    @Query() query: ContributionReportQueryDto,
  ): Promise<ContributionReportDto["memberAnalysis"]> {
    const report = await this.reports.getContributionReport(
      user,
      groupId,
      query.financialYearId,
    );
    return report.memberAnalysis;
  }

  @Get("export")
  exportContributionReport(
    @CurrentUser() user: AuthenticatedUser,
    @Param("groupId") groupId: string,
    @Query() query: ContributionReportQueryDto,
  ) {
    return this.reports.exportContributionReport(user, groupId, query);
  }
}
