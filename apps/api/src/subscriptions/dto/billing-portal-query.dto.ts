import { ApiProperty } from "@nestjs/swagger";
import { IsUrl } from "class-validator";

export class BillingPortalQueryDto {
  @ApiProperty()
  @IsUrl({ require_tld: false })
  returnUrl!: string;
}
