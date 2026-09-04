import { ApiPropertyOptional } from "@nestjs/swagger";
import { IsEnum, IsOptional, IsString } from "class-validator";

export enum ContributionReportExportFormat {
  csv = "csv",
}

export enum ContributionReportMemberStatus {
  all = "all",
  outstanding = "outstanding",
  cleared = "cleared",
}

export class ContributionReportQueryDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  financialYearId?: string;

  @ApiPropertyOptional({ enum: ContributionReportMemberStatus })
  @IsOptional()
  @IsEnum(ContributionReportMemberStatus)
  memberStatus?: ContributionReportMemberStatus;

  @ApiPropertyOptional({ enum: ContributionReportExportFormat })
  @IsOptional()
  @IsEnum(ContributionReportExportFormat)
  format?: ContributionReportExportFormat;
}
