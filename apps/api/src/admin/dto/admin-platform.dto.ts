import {
  IsBoolean,
  IsIn,
  IsInt,
  IsNotEmpty,
  IsObject,
  IsOptional,
  IsString,
  Length,
  Matches,
  Max,
  MaxLength,
  Min,
} from "class-validator";

const codePattern = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;

export class CreateAccessPlanDto {
  @IsString()
  @Matches(codePattern)
  @Length(3, 80)
  code!: string;

  @IsString()
  @IsNotEmpty()
  @Length(2, 100)
  name!: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  description?: string;

  @IsInt()
  @Min(1)
  priceMinor!: number;

  @IsString()
  @Length(3, 3)
  currency!: string;

  @IsIn(["MONTH", "YEAR"])
  interval!: "MONTH" | "YEAR";

  @IsInt()
  @Min(1)
  @Max(24)
  intervalCount!: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(365)
  trialDays?: number;

  @IsOptional()
  @IsIn(["ACTIVE", "INACTIVE", "ARCHIVED"])
  status?: "ACTIVE" | "INACTIVE" | "ARCHIVED";

  @IsOptional()
  @IsObject()
  featureEntitlements?: Record<string, unknown>;
}

export class UpdateAccessPlanDto {
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @Length(2, 100)
  name?: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  description?: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  priceMinor?: number;

  @IsOptional()
  @IsString()
  @Length(3, 3)
  currency?: string;

  @IsOptional()
  @IsIn(["MONTH", "YEAR"])
  interval?: "MONTH" | "YEAR";

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(24)
  intervalCount?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(365)
  trialDays?: number;

  @IsOptional()
  @IsIn(["ACTIVE", "INACTIVE", "ARCHIVED"])
  status?: "ACTIVE" | "INACTIVE" | "ARCHIVED";

  @IsOptional()
  @IsObject()
  featureEntitlements?: Record<string, unknown>;
}

export class CreateReminderPackageDto {
  @IsString()
  @Matches(codePattern)
  @Length(3, 80)
  code!: string;

  @IsString()
  @IsNotEmpty()
  @Length(2, 100)
  name!: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  description?: string;

  @IsIn(["SMS", "WHATSAPP", "BOTH"])
  channel!: "SMS" | "WHATSAPP" | "BOTH";

  @IsInt()
  @Min(1)
  amountMinor!: number;

  @IsString()
  @Length(3, 3)
  currency!: string;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

export class UpdateReminderPackageDto {
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @Length(2, 100)
  name?: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  description?: string;

  @IsOptional()
  @IsIn(["SMS", "WHATSAPP", "BOTH"])
  channel?: "SMS" | "WHATSAPP" | "BOTH";

  @IsOptional()
  @IsInt()
  @Min(1)
  amountMinor?: number;

  @IsOptional()
  @IsString()
  @Length(3, 3)
  currency?: string;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
