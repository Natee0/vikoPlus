import {
  BadRequestException,
  ConflictException,
  Injectable,
  UnauthorizedException,
} from "@nestjs/common";
import {
  GroupMemberStatus,
  Locale,
  OtpPurpose,
  UserIdentityType,
} from "@prisma/client";
import * as argon2 from "argon2";
import { createHash, randomBytes, randomInt } from "crypto";

import { AuthenticatedUser } from "../common/auth/authenticated-user";
import { TokenService } from "../common/auth/token.service";
import { PrismaService } from "../prisma/prisma.service";
import { VerificationDeliveryService } from "../verification/verification-delivery.service";
import {
  CompletePasswordResetDto,
  LoginDto,
  RefreshTokenDto,
  RegisterDto,
  RequestPasswordResetDto,
  VerifyPasswordResetCodeDto,
  VerifyOtpDto,
} from "./dto/auth.dto";

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly tokens: TokenService,
    private readonly verificationDelivery: VerificationDeliveryService,
  ) {}

  async register(input: RegisterDto) {
    const identity = this.identityInput(input);
    const existingIdentity = await this.prisma.userIdentity.findUnique({
      where: { type_value: identity },
    });
    if (existingIdentity) {
      throw new ConflictException(
        "Account identity is already registered or pending verification.",
      );
    }

    const code = this.otpCode();
    const passwordHash = await argon2.hash(input.password);
    const otpHash = await argon2.hash(code);
    const user = await this.prisma.user.create({
      data: {
        displayName: input.fullName.trim(),
        passwordHash,
        preferredLocale: this.locale(input.preferredLocale),
        identities: {
          create: {
            type: identity.type,
            value: identity.value,
            isVerified: false,
          },
        },
        otpChallenges: {
          create: {
            identityType: identity.type,
            purpose: OtpPurpose.ACCOUNT_VERIFICATION,
            identifier: identity.value,
            otpHash,
            expiresAt: this.minutesFromNow(10),
          },
        },
      },
      include: { otpChallenges: { orderBy: { createdAt: "desc" }, take: 1 } },
    });

    const challenge = user.otpChallenges[0];
    if (!challenge) {
      throw new BadRequestException("OTP challenge could not be created.");
    }

    const delivery = await this.verificationDelivery.sendCode({
      channel: identity.type === UserIdentityType.PHONE ? "sms" : "email",
      destination: identity.value,
      code,
      name: user.displayName,
      purpose: "account_verification",
    });

    return {
      user: this.userPayload(user),
      otpChallenge: {
        id: challenge.id,
        destination: identity.value,
        channel: identity.type === UserIdentityType.PHONE ? "sms" : "email",
        expiresAt: challenge.expiresAt,
        delivery,
      },
    };
  }

  async login(input: LoginDto) {
    const identity = await this.findIdentity(input.identifier);
    if (
      !identity ||
      !(await argon2.verify(identity.user.passwordHash, input.password))
    ) {
      throw new UnauthorizedException("Invalid credentials.");
    }
    if (!identity.isVerified) {
      throw new UnauthorizedException("Account verification is required.");
    }

    return this.authResponse(identity.user.id);
  }

  async verifyOtp(input: VerifyOtpDto) {
    const challenge = await this.prisma.otpChallenge.findUnique({
      where: { id: input.challengeId },
    });
    if (
      !challenge ||
      challenge.purpose !== OtpPurpose.ACCOUNT_VERIFICATION ||
      challenge.consumedAt ||
      challenge.expiresAt <= new Date()
    ) {
      throw new UnauthorizedException("Verification code expired or invalid.");
    }
    if (challenge.attempts >= 5) {
      throw new UnauthorizedException("Too many verification attempts.");
    }

    const verified = await argon2.verify(challenge.otpHash, input.code);
    if (!verified) {
      await this.prisma.otpChallenge.update({
        where: { id: challenge.id },
        data: { attempts: { increment: 1 } },
      });
      throw new UnauthorizedException("Invalid verification code.");
    }

    await this.prisma.$transaction([
      this.prisma.otpChallenge.update({
        where: { id: challenge.id },
        data: { consumedAt: new Date() },
      }),
      this.prisma.userIdentity.update({
        where: {
          type_value: {
            type: challenge.identityType,
            value: challenge.identifier,
          },
        },
        data: { isVerified: true, verifiedAt: new Date() },
      }),
      this.prisma.auditLog.create({
        data: {
          actorUserId: challenge.userId,
          action: "ACCOUNT_VERIFIED",
          entityType: "User",
          entityId: challenge.userId,
        },
      }),
    ]);

    return { verified: true, nextRoute: "/groups" };
  }

  async requestPasswordReset(input: RequestPasswordResetDto) {
    const identity = await this.findIdentity(input.identifier);
    if (!identity || !identity.isVerified) {
      return this.passwordResetRequestedResponse(input.identifier);
    }

    await this.prisma.otpChallenge.updateMany({
      where: {
        userId: identity.userId,
        identifier: identity.value,
        purpose: OtpPurpose.PASSWORD_RESET,
        consumedAt: null,
      },
      data: { consumedAt: new Date() },
    });

    const code = this.otpCode();
    const otpHash = await argon2.hash(code);
    await this.prisma.otpChallenge.create({
      data: {
        userId: identity.userId,
        identityType: identity.type,
        purpose: OtpPurpose.PASSWORD_RESET,
        identifier: identity.value,
        otpHash,
        expiresAt: this.minutesFromNow(10),
      },
    });

    const delivery = await this.verificationDelivery.sendCode({
      channel: identity.type === UserIdentityType.PHONE ? "sms" : "email",
      destination: identity.value,
      code,
      name: identity.user.displayName,
      purpose: "password_reset",
    });

    await this.prisma.auditLog.create({
      data: {
        actorUserId: identity.userId,
        action: "PASSWORD_RESET_REQUESTED",
        entityType: "User",
        entityId: identity.userId,
      },
    });

    return this.passwordResetRequestedResponse(identity.value, delivery);
  }

  async verifyPasswordResetCode(input: VerifyPasswordResetCodeDto) {
    const identity = await this.findIdentity(input.identifier);
    const challenge = identity
      ? await this.prisma.otpChallenge.findFirst({
          where: {
            userId: identity.userId,
            identifier: identity.value,
            purpose: OtpPurpose.PASSWORD_RESET,
            consumedAt: null,
            expiresAt: { gt: new Date() },
          },
          orderBy: { createdAt: "desc" },
        })
      : null;

    if (!challenge) {
      throw new UnauthorizedException("Verification code expired or invalid.");
    }
    if (challenge.attempts >= 5) {
      throw new UnauthorizedException("Too many verification attempts.");
    }

    const verified = await argon2.verify(challenge.otpHash, input.code);
    if (!verified) {
      await this.prisma.otpChallenge.update({
        where: { id: challenge.id },
        data: { attempts: { increment: 1 } },
      });
      throw new UnauthorizedException("Invalid verification code.");
    }

    const resetToken = this.resetToken();
    const resetTokenRecord = await this.prisma.$transaction(async (tx) => {
      await tx.otpChallenge.update({
        where: { id: challenge.id },
        data: { consumedAt: new Date() },
      });
      return tx.passwordResetToken.create({
        data: {
          userId: challenge.userId,
          tokenHash: this.hashToken(resetToken),
          expiresAt: this.minutesFromNow(10),
        },
      });
    });

    return {
      resetToken,
      expiresAt: resetTokenRecord.expiresAt,
    };
  }

  async completePasswordReset(input: CompletePasswordResetDto) {
    const tokenHash = this.hashToken(input.resetToken);
    const resetToken = await this.prisma.passwordResetToken.findUnique({
      where: { tokenHash },
      include: { user: true },
    });

    if (
      !resetToken ||
      resetToken.usedAt ||
      resetToken.expiresAt <= new Date()
    ) {
      throw new UnauthorizedException("Password reset session expired.");
    }

    if (await argon2.verify(resetToken.user.passwordHash, input.password)) {
      throw new BadRequestException(
        "New password must be different from the current password.",
      );
    }

    const passwordHash = await argon2.hash(input.password);
    await this.prisma.$transaction([
      this.prisma.user.update({
        where: { id: resetToken.userId },
        data: { passwordHash },
      }),
      this.prisma.passwordResetToken.update({
        where: { id: resetToken.id },
        data: { usedAt: new Date() },
      }),
      this.prisma.refreshToken.updateMany({
        where: { userId: resetToken.userId, revokedAt: null },
        data: { revokedAt: new Date() },
      }),
      this.prisma.auditLog.create({
        data: {
          actorUserId: resetToken.userId,
          action: "PASSWORD_RESET_COMPLETED",
          entityType: "User",
          entityId: resetToken.userId,
          newValue: {
            logoutOtherSessions: input.logoutOtherSessions ?? true,
          },
        },
      }),
    ]);

    return { status: "PASSWORD_RESET" };
  }

  async refresh(input: RefreshTokenDto) {
    const payload = this.tokens.verifyRefreshToken(input.refreshToken);
    const tokenHash = this.hashToken(input.refreshToken);
    const stored = await this.prisma.refreshToken.findUnique({
      where: { id: payload.jti },
    });
    if (
      !stored ||
      stored.userId !== payload.sub ||
      stored.tokenHash !== tokenHash ||
      stored.revokedAt ||
      stored.expiresAt <= new Date()
    ) {
      throw new UnauthorizedException("Refresh token expired or invalid.");
    }

    await this.prisma.refreshToken.update({
      where: { id: stored.id },
      data: { revokedAt: new Date() },
    });
    return this.authResponse(payload.sub);
  }

  async logout(user: AuthenticatedUser) {
    await this.prisma.refreshToken.updateMany({
      where: { userId: user.id, revokedAt: null },
      data: { revokedAt: new Date() },
    });
    return { status: "LOGGED_OUT" };
  }

  async currentUser(user: AuthenticatedUser) {
    const account = await this.prisma.user.findUniqueOrThrow({
      where: { id: user.id },
      include: {
        identities: true,
        memberships: {
          where: { status: GroupMemberStatus.ACTIVE },
          include: { group: true },
        },
      },
    });
    return {
      ...this.userPayload(account),
      selectedRole: this.selectedRole(
        account.memberships.map((item) => item.role),
      ),
      identities: account.identities.map((identity) => ({
        type: identity.type,
        value: identity.value,
        isVerified: identity.isVerified,
      })),
    };
  }

  private async authResponse(userId: string) {
    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
      include: { memberships: { where: { status: GroupMemberStatus.ACTIVE } } },
    });
    const access = this.tokens.signAccessToken(user.id);
    const refresh = this.tokens.signRefreshToken(user.id);
    await this.prisma.refreshToken.create({
      data: {
        id: refresh.tokenId,
        userId: user.id,
        tokenHash: this.hashToken(refresh.token),
        expiresAt: refresh.expiresAt,
      },
    });
    return {
      accessToken: access.token,
      refreshToken: refresh.token,
      user: {
        ...this.userPayload(user),
        selectedRole: this.selectedRole(
          user.memberships.map((item) => item.role),
        ),
      },
    };
  }

  private async findIdentity(identifier: string) {
    const value = identifier.includes("@")
      ? identifier.trim().toLowerCase()
      : this.normalizePhone(identifier);
    const type = identifier.includes("@")
      ? UserIdentityType.EMAIL
      : UserIdentityType.PHONE;
    return this.prisma.userIdentity.findUnique({
      where: { type_value: { type, value } },
      include: { user: true },
    });
  }

  private identityInput(input: RegisterDto): {
    type: UserIdentityType;
    value: string;
  } {
    if (input.phone) {
      return {
        type: UserIdentityType.PHONE,
        value: this.normalizePhone(input.phone),
      };
    }
    if (input.email) {
      return {
        type: UserIdentityType.EMAIL,
        value: input.email.trim().toLowerCase(),
      };
    }
    throw new BadRequestException("Phone or email is required.");
  }

  private normalizePhone(value: string): string {
    const digits = value.replace(/\D/g, "");
    if (digits.startsWith("255")) return digits;
    if (digits.startsWith("0")) return `255${digits.slice(1)}`;
    if (digits.length === 9) return `255${digits}`;
    return digits;
  }

  private locale(locale?: "en" | "sw"): Locale {
    return locale === "sw" ? Locale.sw : Locale.en;
  }

  private selectedRole(roles: string[]): string {
    if (roles.includes("GROUP_ADMIN")) return "GROUP_ADMIN";
    if (roles.includes("TREASURER")) return "TREASURER";
    if (roles.includes("SECRETARY")) return "SECRETARY";
    if (roles.includes("MEMBER")) return "MEMBER";
    return "NEW_USER";
  }

  private userPayload(user: {
    id: string;
    displayName: string | null;
    preferredLocale: Locale;
    isPlatformAdmin?: boolean;
  }) {
    return {
      id: user.id,
      displayName: user.displayName,
      preferredLocale: user.preferredLocale,
      isPlatformAdmin: user.isPlatformAdmin ?? false,
    };
  }

  private otpCode(): string {
    return String(randomInt(100000, 999999));
  }

  private resetToken(): string {
    return randomBytes(32).toString("base64url");
  }

  private minutesFromNow(minutes: number): Date {
    return new Date(Date.now() + minutes * 60_000);
  }

  private hashToken(token: string): string {
    return createHash("sha256").update(token).digest("hex");
  }

  private passwordResetRequestedResponse(
    identifier: string,
    delivery?: { provider: string; delivered: boolean },
  ) {
    return {
      status: "RESET_CODE_SENT_IF_ACCOUNT_EXISTS",
      destination: identifier.includes("@")
        ? identifier.trim().toLowerCase()
        : this.normalizePhone(identifier),
      expiresInSeconds: 600,
      ...(delivery ? { delivery } : {}),
    };
  }
}
