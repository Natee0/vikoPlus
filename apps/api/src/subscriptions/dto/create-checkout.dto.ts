import { ApiProperty } from "@nestjs/swagger";
import { IsEmail, IsOptional, IsString, IsUrl } from "class-validator";

export class CreateCheckoutDto {
  @ApiProperty()
  @IsString()
  planCode!: string;

  @ApiProperty()
  @IsUrl({ require_tld: false })
  successUrl!: string;

  @ApiProperty()
  @IsUrl({ require_tld: false })
  cancelUrl!: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsEmail()
  buyerEmail?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  buyerName?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  buyerPhone?: string;
}
