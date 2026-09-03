import {
  IsArray,
  IsBoolean,
  IsDateString,
  IsEmail,
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  Min,
} from "class-validator";

export class RegisterDto {
  @IsString()
  fullName!: string;

  @IsOptional()
  @IsString()
  phone?: string;

  @IsOptional()
  @IsEmail()
  email?: string;

  @IsString()
  password!: string;

  @IsOptional()
  @IsIn(["en", "sw"])
  preferredLocale?: "en" | "sw";
}

export class LoginDto {
  @IsString()
  identifier!: string;

  @IsString()
  password!: string;

  @IsOptional()
  @IsIn(["NEW_USER", "GROUP_ADMIN", "TREASURER", "SECRETARY", "MEMBER"])
  rolePreview?: string;
}

export class VerifyOtpDto {
  @IsString()
  challengeId!: string;

  @IsString()
  code!: string;
}

export class UpdateLanguageDto {
  @IsIn(["en", "sw"])
  locale!: "en" | "sw";
}

export class CreateGroupDto {
  @IsString()
  name!: string;

  @IsOptional()
  @IsString()
  type?: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsString()
  location?: string;

  @IsOptional()
  @IsString()
  currency?: string;
}

export class JoinGroupDto {
  @IsString()
  invitationCode!: string;
}

export class FinancialYearDto {
  @IsString()
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
  @IsIn(["MONTHLY", "QUARTERLY", "ANNUAL"])
  frequency?: string;
}

export class ReminderSettingsDto {
  @IsBoolean()
  smsEnabled!: boolean;

  @IsBoolean()
  whatsappEnabled!: boolean;

  @IsOptional()
  @IsInt()
  @Min(0)
  smsPriceMinor?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  whatsappPriceMinor?: number;
}

export class AddMemberDto {
  @IsString()
  fullName!: string;

  @IsOptional()
  @IsString()
  phone?: string;

  @IsOptional()
  @IsEmail()
  email?: string;

  @IsOptional()
  @IsIn(["GROUP_ADMIN", "TREASURER", "SECRETARY", "MEMBER"])
  role?: string;
}

export class InviteMembersDto {
  @IsArray()
  @IsString({ each: true })
  recipients!: string[];

  @IsOptional()
  @IsIn(["GROUP_ADMIN", "TREASURER", "SECRETARY", "MEMBER"])
  role?: string;
}

export class AssignRoleDto {
  @IsIn(["GROUP_ADMIN", "TREASURER", "SECRETARY", "MEMBER"])
  role!: string;
}

export class RecordContributionPaymentDto {
  @IsString()
  memberId!: string;

  @IsInt()
  @Min(1)
  amountMinor!: number;

  @IsString()
  method!: string;

  @IsOptional()
  @IsString()
  reference?: string;
}

export class SendReminderDto {
  @IsIn(["SMS", "WHATSAPP", "BOTH"])
  channel!: "SMS" | "WHATSAPP" | "BOTH";

  @IsString()
  message!: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  memberIds?: string[];
}

export class CreateLoanApplicationDto {
  @IsInt()
  @Min(1)
  amountMinor!: number;

  @IsString()
  purpose!: string;

  @IsInt()
  @Min(1)
  termMonths!: number;

  @IsArray()
  @IsString({ each: true })
  guarantorMemberIds!: string[];
}

export class ReviewLoanApplicationDto {
  @IsOptional()
  @IsString()
  notes?: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  approvedAmountMinor?: number;
}

export class RecordLoanRepaymentDto {
  @IsInt()
  @Min(1)
  amountMinor!: number;

  @IsString()
  provider!: string;

  @IsOptional()
  @IsString()
  reference?: string;
}
