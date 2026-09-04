import { Body, Controller, Get, Post } from "@nestjs/common";
import { ApiBearerAuth, ApiTags } from "@nestjs/swagger";
import { Throttle } from "@nestjs/throttler";

import { CurrentUser } from "../common/auth/auth-user.decorator";
import { AuthenticatedUser } from "../common/auth/authenticated-user";
import { Public } from "../common/auth/public.decorator";
import { AuthService } from "./auth.service";
import {
  CompletePasswordResetDto,
  LoginDto,
  RefreshTokenDto,
  RegisterDto,
  RequestPasswordResetDto,
  VerifyPasswordResetCodeDto,
  VerifyOtpDto,
} from "./dto/auth.dto";

@ApiTags("auth")
@Controller({ path: "auth", version: "1" })
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Public()
  @Throttle({ default: { limit: 5, ttl: 60000, blockDuration: 300000 } })
  @Post("register")
  register(@Body() body: RegisterDto) {
    return this.auth.register(body);
  }

  @Public()
  @Throttle({ default: { limit: 5, ttl: 60000, blockDuration: 300000 } })
  @Post("login")
  login(@Body() body: LoginDto) {
    return this.auth.login(body);
  }

  @Public()
  @Throttle({ default: { limit: 8, ttl: 60000, blockDuration: 300000 } })
  @Post("verify-otp")
  verifyOtp(@Body() body: VerifyOtpDto) {
    return this.auth.verifyOtp(body);
  }

  @Public()
  @Throttle({ default: { limit: 5, ttl: 60000, blockDuration: 300000 } })
  @Post("password-reset/request")
  requestPasswordReset(@Body() body: RequestPasswordResetDto) {
    return this.auth.requestPasswordReset(body);
  }

  @Public()
  @Throttle({ default: { limit: 8, ttl: 60000, blockDuration: 300000 } })
  @Post("password-reset/verify")
  verifyPasswordResetCode(@Body() body: VerifyPasswordResetCodeDto) {
    return this.auth.verifyPasswordResetCode(body);
  }

  @Public()
  @Throttle({ default: { limit: 5, ttl: 60000, blockDuration: 300000 } })
  @Post("password-reset/complete")
  completePasswordReset(@Body() body: CompletePasswordResetDto) {
    return this.auth.completePasswordReset(body);
  }

  @Public()
  @Throttle({ default: { limit: 20, ttl: 60000, blockDuration: 120000 } })
  @Post("refresh")
  refresh(@Body() body: RefreshTokenDto) {
    return this.auth.refresh(body);
  }

  @ApiBearerAuth()
  @Post("logout")
  logout(@CurrentUser() user: AuthenticatedUser) {
    return this.auth.logout(user);
  }

  @ApiBearerAuth()
  @Get("me")
  currentUser(@CurrentUser() user: AuthenticatedUser) {
    return this.auth.currentUser(user);
  }
}
