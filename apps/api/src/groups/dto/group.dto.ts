import {
  ArrayMinSize,
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  ArrayUnique,
  IsDateString,
  IsEmail,
  IsIn,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUrl,
  Length,
  Matches,
  MaxLength,
  Min,
  Max,
  ValidateNested,
} from "class-validator";
import { Transform, Type } from "class-transformer";

export class UpdateLanguageDto {
  @IsIn(["en", "sw"])
  locale!: "en" | "sw";
}

export class RegisterPushTokenDto {
  @IsString()
  @IsNotEmpty()
  token!: string;

  @IsIn(["android", "ios", "web"])
  platform!: "android" | "ios" | "web";

  @IsOptional()
  @IsString()
  @MaxLength(128)
  deviceId?: string;

  @IsOptional()
  @IsString()
  @MaxLength(32)
  appVersion?: string;
}

export class UpdateMemberStatusDto {
  @IsIn(["ACTIVE", "SUSPENDED", "REMOVED"])
  status!: "ACTIVE" | "SUSPENDED" | "REMOVED";
}

export class UpdateProfileDto {
  @IsString()
  @Length(2, 100)
  displayName!: string;
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
  @Transform(({ value }) =>
    typeof value === "string" ? value.replace(/\s+/g, "").toUpperCase() : value,
  )
  @IsString()
  @IsNotEmpty()
  @Length(6, 6)
  @Matches(/^[A-Z0-9]{6}$/)
  code!: string;
}

export class JoinGroupDto {
  @Transform(({ value }) =>
    typeof value === "string" ? value.replace(/\s+/g, "").toUpperCase() : value,
  )
  @IsString()
  @IsNotEmpty()
  @Length(6, 6)
  @Matches(/^[A-Z0-9]{6}$/)
  invitationCode!: string;
}

export class FinancialYearDto {
  @IsOptional()
  @IsBoolean()
  automaticRollover?: boolean;
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
  membershipFeeFrequency?:
    "DAILY" | "WEEKLY" | "MONTHLY" | "QUARTERLY" | "ANNUAL";

  @IsOptional()
  @IsIn(["DAILY", "WEEKLY", "MONTHLY", "QUARTERLY", "ANNUAL"])
  memberContributionFrequency?:
    "DAILY" | "WEEKLY" | "MONTHLY" | "QUARTERLY" | "ANNUAL";

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
  @IsBoolean()
  enabled?: boolean;

  @IsOptional()
  @IsArray()
  @ArrayUnique()
  @ArrayMaxSize(3)
  @IsIn([-3, 0, 3], { each: true })
  offsets?: number[];

  @IsOptional()
  @IsIn(["en", "sw"])
  locale?: "en" | "sw";
  @IsOptional()
  @IsString()
  @MaxLength(500)
  dueReminderTemplate?: string;
}

export class PaymentRulesDto {
  @IsBoolean()
  allowsPartial!: boolean;
  @IsBoolean()
  penaltiesEnabled!: boolean;
  @IsInt()
  @Min(0)
  @Max(2147483647)
  penaltyAmountMinor!: number;
  @IsInt()
  @Min(0)
  @Max(365)
  graceDays!: number;
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
  @IsIn(["JOINING_FEE", "MEMBERSHIP_FEE", "RECURRING"])
  contributionType?: "JOINING_FEE" | "MEMBERSHIP_FEE" | "RECURRING";

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

  @IsOptional()
  @IsInt()
  @Min(1)
  quantity?: number;

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
  @ArrayUnique()
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

export class LoanDecisionDto {
  @IsBoolean()
  approve!: boolean;
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

export class CreateGroupExpenseDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(80)
  category!: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(500)
  purpose!: string;

  @IsInt()
  @Min(1)
  amountMinor!: number;

  @IsOptional()
  @IsString()
  @Length(3, 3)
  currency?: string;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  beneficiary?: string;

  @IsOptional()
  @IsString()
  @MaxLength(80)
  paymentRail?: string;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  reference?: string;

  @IsOptional()
  @IsDateString()
  spentAt?: string;
}

export class ReviewGroupExpenseDto {
  @IsBoolean()
  approve!: boolean;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  notes?: string;
}
