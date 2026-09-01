import { ApiPropertyOptional } from "@nestjs/swagger";
import { IsOptional, IsString } from "class-validator";

export class ContributionReportQueryDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  financialYearId?: string;
}
