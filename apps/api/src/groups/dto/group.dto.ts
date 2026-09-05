import {
  ArrayMinSize,
  ArrayMaxSize,
  IsArray,
  IsDateString,
  IsEmail,
  IsIn,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUrl,
  Length,
  MaxLength,
  Min,
  Max,
  ValidateNested,
} from "class-validator";
import { Type } from "class-transformer";

export class UpdateLanguageDto {
  @IsIn(["en", "sw"])
  locale!: "en" | "sw";
}

export class CreateGroupDto {
  @IsString()
  @IsNotEmpty()
  @Length(2, 100)
  name!: string;

  @IsOptional()
  @IsString()
  @MaxLength(50)
  type?: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  description?: string;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  location?: string;

  @IsOptional()
  @IsString()
  @Length(3, 3)
  currency?: string;

  @IsOptional()
  @IsDateString()
  establishedAt?: string;

  @IsOptional()
  @IsDateString()
  historicalDataStartsAt?: string;
}

export class PreviewJoinCodeDto {
  @IsString()
  @IsNotEmpty()
  @Length(4, 64)
  code!: string;
}

export class JoinGroupDto {
  @IsString()
  @IsNotEmpty()
  @Length(4, 64)
  invitationCode!: string;
}

export class FinancialYearDto {
  @IsString()
  @IsNotEmpty()
  @Length(2, 100)
  name!: string;

  @IsDateString()
  startsAt!: string;

  @IsDateString()
  endsAt!: string;
}

export class ContributionSettingsDto {
  @IsInt()
  @Min(0)
  joiningFeeMinor!: number;

  @IsInt()
  @Min(0)
  membershipFeeMinor!: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  memberContributionMinor?: number;

  @IsOptional()
  @IsIn(["DAILY", "WEEKLY", "MONTHLY", "QUARTERLY", "ANNUAL"])
  membershipFeeFrequency?: "DAILY" | "WEEKLY" | "MONTHLY" | "QUARTERLY" | "ANNUAL";

  @IsOptional()
  @IsIn(["DAILY", "WEEKLY", "MONTHLY", "QUARTERLY", "ANNUAL"])
  memberContributionFrequency?:
    | "DAILY"
    | "WEEKLY"
    | "MONTHLY"
    | "QUARTERLY"
    | "ANNUAL";

  @IsOptional()
  @IsIn(["DAILY", "WEEKLY", "MONTHLY", "QUARTERLY", "ANNUAL"])
  frequency?: "DAILY" | "WEEKLY" | "MONTHLY" | "QUARTERLY" | "ANNUAL";

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(7)
  dueDayOfWeek?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(7)
  membershipDueDayOfWeek?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(7)
  memberContributionDueDayOfWeek?: number;

  @IsOptional()
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(7)
  @Type(() => Number)
  @IsInt({ each: true })
  @Min(1, { each: true })
  @Max(7, { each: true })
  memberContributionDueDaysOfWeek?: number[];

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(31)
  dueDayOfMonth?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(31)
  membershipDueDayOfMonth?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(31)
  memberContributionDueDayOfMonth?: number;

  @IsOptional()
  @IsDateString()
  cycleAnchorDate?: string;
}

export class ReminderSettingsDto {
  @IsOptional()
  @IsString()
  @MaxLength(500)
  dueReminderTemplate?: string;
}

export class AddMemberDto {
  @IsString()
  @IsNotEmpty()
  @Length(2, 100)
  fullName!: string;

  @IsOptional()
  @IsString()
  @MaxLength(30)
  memberNumber?: string;

  @IsOptional()
  @IsString()
  @MaxLength(30)
  phone?: string;

  @IsOptional()
  @IsEmail()
  email?: string;

  @IsOptional()
  @IsIn(["GROUP_ADMIN", "TREASURER", "SECRETARY", "MEMBER"])
  role?: "GROUP_ADMIN" | "TREASURER" | "SECRETARY" | "MEMBER";
}

export class InviteMembersDto {
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(100)
  @IsString({ each: true })
  @MaxLength(100, { each: true })
  recipients!: string[];

  @IsOptional()
  @IsIn(["GROUP_ADMIN", "TREASURER", "SECRETARY", "MEMBER"])
  role?: "GROUP_ADMIN" | "TREASURER" | "SECRETARY" | "MEMBER";
}

export class AssignRoleDto {
  @IsIn(["GROUP_ADMIN", "TREASURER", "SECRETARY", "MEMBER"])
  role!: "GROUP_ADMIN" | "TREASURER" | "SECRETARY" | "MEMBER";
}

export class RecordContributionPaymentDto {
  @IsString()
  @IsNotEmpty()
  memberId!: string;

  @IsInt()
  @Min(1)
  amountMinor!: number;

  @IsString()
  @IsNotEmpty()
  @MaxLength(50)
  @IsIn(["CASH", "MOBILE_MONEY", "BANK_TRANSFER", "OTHER"])
  method!: string;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  reference?: string;

  @IsOptional()
  @IsDateString()
  paidAt?: string;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(50)
  @IsString({ each: true })
  obligationIds?: string[];
}

export class SubmitContributionPaymentRequestDto {
  @IsInt()
  @Min(1)
  amountMinor!: number;

  @IsString()
  @IsNotEmpty()
  @MaxLength(50)
  @IsIn(["CASH", "MOBILE_MONEY", "BANK_TRANSFER", "OTHER"])
  method!: string;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  reference?: string;

  @IsOptional()
  @IsDateString()
  paidAt?: string;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(50)
  @IsString({ each: true })
  obligationIds?: string[];
}

export class HistoricalContributionPaymentDto {
  @IsString()
  @IsNotEmpty()
  memberId!: string;

  @IsInt()
  @Min(1)
  amountMinor!: number;

  @IsString()
  @IsNotEmpty()
  @MaxLength(50)
  @IsIn(["CASH", "MOBILE_MONEY", "BANK_TRANSFER", "OTHER"])
  method!: string;

  @IsDateString()
  paidAt!: string;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  reference?: string;
}

export class ImportHistoricalContributionPaymentsDto {
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(500)
  @ValidateNested({ each: true })
  @Type(() => HistoricalContributionPaymentDto)
  payments!: HistoricalContributionPaymentDto[];
}

export class ReviewContributionPaymentDto {
  @IsOptional()
  @IsString()
  @MaxLength(300)
  reason?: string;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(50)
  @IsString({ each: true })
  obligationIds?: string[];
}

export class SendReminderDto {
  @IsIn(["SMS", "WHATSAPP", "BOTH"])
  channel!: "SMS" | "WHATSAPP" | "BOTH";

  @IsString()
  @IsNotEmpty()
  @MaxLength(500)
  message!: string;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(200)
  @IsString({ each: true })
  memberIds?: string[];
}

export class CreateReminderPackageCheckoutDto {
  @IsString()
  @IsNotEmpty()
  @Length(3, 80)
  packageCode!: string;

  @IsInt()
  @Min(1)
  quantity!: number;

  @IsUrl({ require_tld: false })
  successUrl!: string;

  @IsUrl({ require_tld: false })
  cancelUrl!: string;

  @IsOptional()
  @IsEmail()
  buyerEmail?: string;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  buyerName?: string;

  @IsOptional()
  @IsString()
  @MaxLength(30)
  buyerPhone?: string;
}

export class CreateLoanApplicationDto {
  @IsInt()
  @Min(1)
  amountMinor!: number;

  @IsString()
  @IsNotEmpty()
  @MaxLength(120)
  purpose!: string;

  @IsInt()
  @Min(1)
  @Max(60)
  termMonths!: number;

  @IsArray()
  @ArrayMinSize(2)
  @ArrayMaxSize(10)
  @IsString({ each: true })
  guarantorMemberIds!: string[];
}

export class ReviewLoanApplicationDto {
  @IsOptional()
  @IsInt()
  @Min(1)
  approvedAmountMinor?: number;

  @IsOptional()
  @IsString()
  @MaxLength(300)
  notes?: string;

  @IsOptional()
  @IsString()
  @MaxLength(300)
  reason?: string;
}

export class RecordLoanRepaymentDto {
  @IsInt()
  @Min(1)
  amountMinor!: number;

  @IsString()
  @IsNotEmpty()
  @MaxLength(50)
  @IsIn(["CASH", "MOBILE_MONEY", "BANK_TRANSFER", "OTHER"])
  method!: string;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  reference?: string;

  @IsOptional()
  @IsDateString()
  paidAt?: string;
}
