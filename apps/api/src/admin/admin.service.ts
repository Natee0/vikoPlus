import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import {
  BillingTransactionStatus,
  GroupContributionPaymentStatus,
  GroupMemberStatus,
  Prisma,
  SubscriptionPlanStatus,
} from "@prisma/client";
import { AuthenticatedUser } from "../common/auth/authenticated-user";
import { PrismaService } from "../prisma/prisma.service";
import { PlatformPricingService } from "../platform/platform-pricing.service";
import {
  CreateAccessPlanDto,
  CreateReminderPackageDto,
  UpdateAccessPlanDto,
  UpdateReminderPackageDto,
} from "./dto/admin-platform.dto";

@Injectable()
export class AdminService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly pricing: PlatformPricingService,
  ) {}

  packageSettings() {
    return this.pricing.adminPackages();
  }

  async createAccessPlan(user: AuthenticatedUser, input: CreateAccessPlanDto) {
    const code = this.normalizeCode(input.code);
    await this.ensureAccessPlanCodeAvailable(code);
    const featureEntitlements = this.featureEntitlements(
      input.featureEntitlements,
    );

    const plan = await this.prisma.subscriptionPlan.create({
      data: {
        code,
        name: input.name.trim(),
        description: input.description?.trim(),
        priceMinor: input.priceMinor,
        currency: input.currency.toUpperCase(),
        interval: input.interval,
        intervalCount: input.intervalCount,
        trialDays: input.trialDays ?? 30,
        status: input.status ?? "ACTIVE",
        featureEntitlements,
      },
    });
    await this.auditPackageChange(user, "SubscriptionPlan", plan.id, plan);
    return plan;
  }

  listAccessPlans() {
    return this.prisma.subscriptionPlan.findMany({
      orderBy: [
        { status: "asc" },
        { interval: "asc" },
        { intervalCount: "asc" },
        { priceMinor: "asc" },
      ],
    });
  }

  async updateAccessPlan(
    user: AuthenticatedUser,
    code: string,
    input: UpdateAccessPlanDto,
  ) {
    if (Object.keys(input).length === 0) {
      throw new BadRequestException("At least one field must be provided.");
    }
    const normalizedCode = this.normalizeCode(code);
    await this.ensureAccessPlanExists(normalizedCode);

    const plan = await this.prisma.subscriptionPlan.update({
      where: { code: normalizedCode },
      data: {
        name: input.name?.trim(),
        description: input.description?.trim(),
        priceMinor: input.priceMinor,
        currency: input.currency?.toUpperCase(),
        interval: input.interval,
        intervalCount: input.intervalCount,
        trialDays: input.trialDays,
        status: input.status,
        featureEntitlements: input.featureEntitlements as
          | Prisma.InputJsonValue
          | undefined,
      },
    });
    await this.auditPackageChange(user, "SubscriptionPlan", plan.id, plan);
    return plan;
  }

  async createReminderPackage(
    user: AuthenticatedUser,
    input: CreateReminderPackageDto,
  ) {
    const code = this.normalizeCode(input.code);
    await this.ensureReminderPackageCodeAvailable(code);

    const reminderPackage = await this.prisma.platformPrice.create({
      data: {
        code,
        name: input.name.trim(),
        description: input.description?.trim(),
        channel: input.channel,
        amountMinor: input.amountMinor,
        currency: input.currency.toUpperCase(),
        isActive: input.isActive ?? true,
        updatedByUserId: user.id,
      },
    });
    await this.auditPackageChange(
      user,
      "PlatformPrice",
      reminderPackage.id,
      reminderPackage,
    );
    return reminderPackage;
  }

  listReminderPackages() {
    return this.prisma.platformPrice.findMany({
      orderBy: [{ isActive: "desc" }, { channel: "asc" }, { code: "asc" }],
    });
  }

  async updateReminderPackage(
    user: AuthenticatedUser,
    code: string,
    input: UpdateReminderPackageDto,
  ) {
    if (Object.keys(input).length === 0) {
      throw new BadRequestException("At least one field must be provided.");
    }
    const normalizedCode = this.normalizeCode(code);
    await this.ensureReminderPackageExists(normalizedCode);

    const reminderPackage = await this.prisma.platformPrice.update({
      where: { code: normalizedCode },
      data: {
        name: input.name?.trim(),
        description: input.description?.trim(),
        channel: input.channel,
        amountMinor: input.amountMinor,
        currency: input.currency?.toUpperCase(),
        isActive: input.isActive,
        updatedByUserId: user.id,
      },
    });
    await this.auditPackageChange(
      user,
      "PlatformPrice",
      reminderPackage.id,
      reminderPackage,
    );
    return reminderPackage;
  }

  async metrics() {
    const [
      totalUsers,
      verifiedUsers,
      platformAdmins,
      totalGroups,
      activeMembers,
      activeSubscriptions,
      totalSubscriptions,
      contributionPayments,
      billingTransactions,
      pendingInvitations,
      remindersSent,
      accessPackages,
      reminderPackages,
    ] = await Promise.all([
      this.prisma.user.count(),
      this.prisma.userIdentity.count({ where: { isVerified: true } }),
      this.prisma.user.count({ where: { isPlatformAdmin: true } }),
      this.prisma.group.count(),
      this.prisma.groupMember.count({
        where: { status: GroupMemberStatus.ACTIVE },
      }),
      this.prisma.subscription.count({ where: { state: "ACTIVE" } }),
      this.prisma.subscription.count(),
      this.prisma.groupContributionPayment.aggregate({
        where: { status: GroupContributionPaymentStatus.APPROVED },
        _sum: { amountMinor: true },
        _count: true,
      }),
      this.prisma.billingTransaction.aggregate({
        where: { status: BillingTransactionStatus.SUCCEEDED },
        _sum: { amountMinor: true },
        _count: true,
      }),
      this.prisma.groupInvitation.count({ where: { acceptedAt: null } }),
      this.prisma.reminderCampaign.count({ where: { sentAt: { not: null } } }),
      this.prisma.subscriptionPlan.count({
        where: { status: SubscriptionPlanStatus.ACTIVE },
      }),
      this.prisma.platformPrice.count({ where: { isActive: true } }),
    ]);

    return {
      users: {
        total: totalUsers,
        verifiedIdentities: verifiedUsers,
        platformAdmins,
      },
      groups: {
        total: totalGroups,
        activeMembers,
        pendingInvitations,
      },
      subscriptions: {
        total: totalSubscriptions,
        active: activeSubscriptions,
        activeAccessPackages: accessPackages,
      },
      contributions: {
        approvedPayments: contributionPayments._count,
        approvedAmountMinor: contributionPayments._sum.amountMinor ?? 0,
      },
      billing: {
        successfulTransactions: billingTransactions._count,
        successfulAmountMinor: billingTransactions._sum.amountMinor ?? 0,
      },
      reminders: {
        sentCampaigns: remindersSent,
        activePackages: reminderPackages,
      },
    };
  }

  private normalizeCode(code: string): string {
    return code.trim().toLowerCase();
  }

  private async ensureAccessPlanCodeAvailable(code: string): Promise<void> {
    const existing = await this.prisma.subscriptionPlan.findUnique({
      where: { code },
      select: { id: true },
    });
    if (existing) {
      throw new ConflictException("Access plan code already exists.");
    }
  }

  private async ensureAccessPlanExists(code: string): Promise<void> {
    const existing = await this.prisma.subscriptionPlan.findUnique({
      where: { code },
      select: { id: true },
    });
    if (!existing) {
      throw new NotFoundException("Access plan was not found.");
    }
  }

  private async ensureReminderPackageCodeAvailable(code: string): Promise<void> {
    const existing = await this.prisma.platformPrice.findUnique({
      where: { code },
      select: { id: true },
    });
    if (existing) {
      throw new ConflictException("Reminder package code already exists.");
    }
  }

  private async ensureReminderPackageExists(code: string): Promise<void> {
    const existing = await this.prisma.platformPrice.findUnique({
      where: { code },
      select: { id: true },
    });
    if (!existing) {
      throw new NotFoundException("Reminder package was not found.");
    }
  }

  private auditPackageChange(
    user: AuthenticatedUser,
    entityType: string,
    entityId: string,
    newValue: unknown,
  ) {
    return this.prisma.auditLog.create({
      data: {
        actorUserId: user.id,
        action: "PLATFORM_PRICE_CHANGED",
        entityType,
        entityId,
        newValue: newValue as Prisma.InputJsonValue,
      },
    });
  }

  private featureEntitlements(
    value?: Record<string, unknown>,
  ): Prisma.InputJsonValue {
    return (
      value ?? {
        groupAccess: true,
        reminders: true,
        reports: true,
      }
    ) as Prisma.InputJsonValue;
  }
}
