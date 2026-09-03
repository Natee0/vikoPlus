import {
  IsEmail,
  IsIn,
  IsNotEmpty,
  IsOptional,
  IsString,
  Length,
  MaxLength,
  MinLength,
  ValidateIf,
} from "class-validator";

export class RegisterDto {
  @IsString()
  @IsNotEmpty()
  @Length(2, 100)
  fullName!: string;

  @ValidateIf((body: RegisterDto) => !body.email)
  @IsString()
  @IsNotEmpty()
  @MaxLength(30)
  phone?: string;

  @ValidateIf((body: RegisterDto) => !body.phone)
  @IsEmail()
  email?: string;

  @IsString()
  @IsNotEmpty()
  @MinLength(8)
  @MaxLength(128)
  password!: string;

  @IsOptional()
  @IsIn(["en", "sw"])
  preferredLocale?: "en" | "sw";
}

export class LoginDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(254)
  identifier!: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(128)
  password!: string;
}

export class VerifyOtpDto {
  @IsString()
  @IsNotEmpty()
  challengeId!: string;

  @IsString()
  @Length(4, 8)
  code!: string;
}

export class RefreshTokenDto {
  @IsString()
  @IsNotEmpty()
  refreshToken!: string;
}
