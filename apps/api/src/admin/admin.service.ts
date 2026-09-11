import {
  BadRequestException,
  ConflictException,
  Inject,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import {
  AuditAction,
  BillingTransactionStatus,
  GroupContributionPaymentStatus,
  GroupMemberStatus,
  Prisma,
  ReminderPackagePurchaseStatus,
  SubscriptionPlanStatus,
  SubscriptionState,
} from "@prisma/client";
import { SUBSCRIPTION_BILLING_PROVIDER } from "../billing/billing-provider.token";
import { SubscriptionBillingProvider } from "../billing/subscription-billing-provider";
import { AuthenticatedUser } from "../common/auth/authenticated-user";
import { PrismaService } from "../prisma/prisma.service";
import { PlatformPricingService } from "../platform/platform-pricing.service";
import {
  CreateAdminGroupDto,
  CreateAccessPlanDto,
  CreateReminderPackageDto,
  UpdateAdminGroupDto,
  UpdateAccessPlanDto,
  UpdateReminderPackageDto,
} from "./dto/admin-platform.dto";

@Injectable()
export class AdminService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly pricing: PlatformPricingService,
    @Inject(SUBSCRIPTION_BILLING_PROVIDER)
    private readonly billingProvider: SubscriptionBillingProvider,
  ) {}

  packageSettings() {
    return this.pricing.adminPackages();
  }

  async createGroup(user: AuthenticatedUser, input: CreateAdminGroupDto) {
    const name = input.name.trim();
    const group = await this.prisma.group.create({
      data: {
        name,
        slug: await this.uniqueGroupSlug(name),
        type: input.type?.trim() || undefined,
        description: input.description?.trim() || undefined,
        location: input.location?.trim() || undefined,
        currency: input.currency?.trim().toUpperCase() || "TZS",
        billingOwnerUserId: user.id,
      },
    });
    await this.auditPackageChange(user, "Group", group.id, {
      action: AuditAction.GROUP_UPDATED,
      group,
    });
    return group;
  }

  async updateGroup(
    user: AuthenticatedUser,
    groupId: string,
    input: UpdateAdminGroupDto,
  ) {
    if (Object.keys(input).length === 0) {
      throw new BadRequestException("At least one field must be provided.");
    }
    await this.ensureGroupExists(groupId);
    const name = input.name?.trim();
    const group = await this.prisma.group.update({
      where: { id: groupId },
      data: {
        name,
        slug: name ? await this.uniqueGroupSlug(name, groupId) : undefined,
        type: input.type?.trim(),
        description: input.description?.trim(),
        location: input.location?.trim(),
        currency: input.currency?.trim().toUpperCase(),
      },
    });
    await this.auditPackageChange(user, "Group", group.id, {
      action: AuditAction.GROUP_UPDATED,
      group,
    });
    return group;
  }

  async deleteGroup(user: AuthenticatedUser, groupId: string) {
    await this.ensureGroupExists(groupId);
    const deleted = await this.prisma.$transaction(async (tx) => {
      const group = await tx.group.findUniqueOrThrow({
        where: { id: groupId },
        select: { id: true, name: true },
      });

      await tx.auditLog.deleteMany({ where: { groupId } });
      await tx.reminderDelivery.deleteMany({ where: { groupId } });
      await tx.reminderCampaign.deleteMany({ where: { groupId } });
      await tx.reminderTemplate.deleteMany({ where: { groupId } });
      await tx.groupReminderRule.deleteMany({ where: { groupId } });
      await tx.groupPaymentRule.deleteMany({ where: { groupId } });
      await tx.reminderPackagePurchase.deleteMany({ where: { groupId } });

      await tx.billingTransaction.deleteMany({
        where: { subscription: { groupId } },
      });
      await tx.billingInvoice.deleteMany({
        where: { subscription: { groupId } },
      });
      await tx.subscription.deleteMany({ where: { groupId } });
      await tx.billingPaymentMethod.deleteMany({
        where: { billingCustomer: { groupId } },
      });
      await tx.billingCustomer.deleteMany({ where: { groupId } });

      await tx.loanRepayment.deleteMany({ where: { groupId } });
      await tx.groupLoan.deleteMany({ where: { groupId } });
      await tx.loanGuarantor.deleteMany({
        where: {
          OR: [
            { application: { groupId } },
            { member: { groupId } },
          ],
        },
      });
      await tx.loanApplication.deleteMany({ where: { groupId } });
      await tx.groupExpense.deleteMany({ where: { groupId } });

      await tx.receipt.deleteMany({ where: { groupId } });
      await tx.paymentAllocation.deleteMany({
        where: {
          OR: [
            { payment: { groupId } },
            { plan: { groupId } },
            { period: { groupId } },
            { obligation: { member: { groupId } } },
          ],
        },
      });
      await tx.groupContributionPayment.deleteMany({ where: { groupId } });
      await tx.memberContributionObligation.deleteMany({
        where: {
          OR: [
            { member: { groupId } },
            { plan: { groupId } },
            { period: { groupId } },
          ],
        },
      });
      await tx.groupInvitation.deleteMany({ where: { groupId } });
      await tx.contributionPeriod.deleteMany({ where: { groupId } });
      await tx.contributionPlan.deleteMany({ where: { groupId } });
      await tx.financialYear.deleteMany({ where: { groupId } });
      await tx.groupMember.deleteMany({ where: { groupId } });
      await tx.group.delete({ where: { id: groupId } });

      await tx.auditLog.create({
        data: {
          actorUserId: user.id,
          action: AuditAction.GROUP_UPDATED,
          entityType: "Group",
          entityId: group.id,
          newValue: { deleted: true, name: group.name },
        },
      });
      return group;
    });
    return { id: deleted.id, deleted: true };
  }

  async groups() {
    const groups = await this.prisma.group.findMany({
      orderBy: { updatedAt: "desc" },
      take: 100,
      include: {
        _count: { select: { members: true, invitations: true } },
        subscriptions: {
          orderBy: { updatedAt: "desc" },
          take: 1,
          include: { plan: true },
        },
        payments: {
          where: { status: GroupContributionPaymentStatus.APPROVED },
          select: { amountMinor: true },
        },
        members: {
          where: { role: "GROUP_ADMIN" },
          orderBy: { createdAt: "asc" },
          take: 1,
          select: { fullName: true, email: true, phone: true },
        },
      },
    });

    return {
      groups: groups.map((group) => ({
        id: group.id,
        name: group.name,
        type: group.type ?? "Community group",
        country: group.location ?? "Not set",
        primaryContact:
          group.members[0]?.fullName ??
          group.members[0]?.email ??
          group.members[0]?.phone ??
          "Not assigned",
        membersCount: group._count.members,
        pendingInvitations: group._count.invitations,
        balanceMinor: group.payments.reduce(
          (total, payment) => total + payment.amountMinor,
          0,
        ),
        currency: group.currency,
        subscriptionState: group.subscriptions[0]?.state ?? "NONE",
        planName: group.subscriptions[0]?.plan.name ?? "No plan",
        status: group.subscriptions[0]?.state === "ACTIVE" ? "Active" : "Pending",
        createdAt: group.createdAt,
        updatedAt: group.updatedAt,
      })),
    };
  }

  async users() {
    const users = await this.prisma.user.findMany({
      orderBy: { updatedAt: "desc" },
      take: 100,
      include: {
        identities: true,
        memberships: {
          orderBy: { updatedAt: "desc" },
          take: 1,
          include: { group: true },
        },
      },
    });

    return {
      users: users.map((user) => {
        const verifiedIdentity = user.identities.find(
          (identity) => identity.isVerified,
        );
        const primaryIdentity = verifiedIdentity ?? user.identities[0];
        const membership = user.memberships[0];
        return {
          id: user.id,
          name: user.displayName ?? "Unnamed user",
          email:
            user.identities.find((identity) => identity.type === "EMAIL")
              ?.value ?? null,
          phone:
            user.identities.find((identity) => identity.type === "PHONE")
              ?.value ?? null,
          primaryIdentity: primaryIdentity?.value ?? null,
          role: user.isPlatformAdmin
            ? "Super Admin"
            : (membership?.role ?? "Member"),
          groupName: membership?.group.name ?? "System Platform",
          kycStatus: verifiedIdentity ? "Verified" : "Pending",
          twoFactorStatus: user.securityPinHash ? "Enabled" : "Disabled",
          preferredLocale: user.preferredLocale,
          createdAt: user.createdAt,
          updatedAt: user.updatedAt,
        };
      }),
    };
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
        quantity: input.quantity ?? 1,
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
        quantity: input.quantity,
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
    await this.reconcilePendingProviderPayments();

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
      activeTrials,
      subscriptionPlans,
      reminderPackageRows,
      activeSubscriptionsByPlan,
      accessRevenueTransactions,
      reminderPurchases,
      billingEvents,
    ] = await Promise.all([
      this.prisma.user.count(),
      this.prisma.userIdentity.count({ where: { isVerified: true } }),
      this.prisma.user.count({ where: { isPlatformAdmin: true } }),
      this.prisma.group.count(),
      this.prisma.groupMember.count({
        where: { status: GroupMemberStatus.ACTIVE },
      }),
      this.prisma.subscription.count({ where: { state: SubscriptionState.ACTIVE } }),
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
      this.prisma.subscription.count({ where: { state: SubscriptionState.TRIAL } }),
      this.prisma.subscriptionPlan.findMany({
        orderBy: [{ status: "asc" }, { priceMinor: "asc" }],
      }),
      this.prisma.platformPrice.findMany({
        orderBy: [{ isActive: "desc" }, { amountMinor: "asc" }],
      }),
      this.prisma.subscription.groupBy({
        by: ["planId"],
        where: { state: SubscriptionState.ACTIVE },
        _count: { _all: true },
      }),
      this.prisma.billingTransaction.findMany({
        where: { status: BillingTransactionStatus.SUCCEEDED },
        select: {
          amountMinor: true,
          currency: true,
          subscription: {
            select: {
              planId: true,
              plan: { select: { code: true, name: true } },
            },
          },
        },
      }),
      this.prisma.reminderPackagePurchase.findMany({
        where: { status: ReminderPackagePurchaseStatus.PAID },
        select: {
          amountMinor: true,
          currency: true,
          quantity: true,
          usedQuantity: true,
          platformPrice: {
            select: {
              id: true,
              code: true,
              name: true,
              channel: true,
              isActive: true,
            },
          },
        },
      }),
      this.prisma.billingEvent.findMany({
        select: { payload: true },
      }),
    ]);

    const activeSubscriptionsByPlanId = new Map(
      activeSubscriptionsByPlan.map((entry) => [entry.planId, entry._count._all]),
    );
    const planByCode = new Map(subscriptionPlans.map((plan) => [plan.code, plan]));
    const reminderPackageByCode = new Map(
      reminderPackageRows.map((item) => [item.code, item]),
    );
    const completedProviderOrders = new Map<
      string,
      {
        externalRef: string;
        productCode: string;
        amountMinor: number;
        currency: string;
      }
    >();
    for (const event of billingEvents) {
      const payload = event.payload as Record<string, unknown>;
      const status = this.firstString(payload, [
        "paymentStatus",
        "status",
        "result",
      ]);
      if (String(status ?? "").toUpperCase() !== "COMPLETED") continue;
      const orderId = this.firstString(payload, ["orderId", "providerRef"]);
      const externalRef = this.firstString(payload, ["externalRef"]);
      if (!orderId || !externalRef) continue;
      const [, productCode] = externalRef.split(":");
      if (!productCode) continue;
      completedProviderOrders.set(orderId, {
        externalRef,
        productCode,
        amountMinor: this.numberValue(payload["amount"]) ?? 0,
        currency: this.firstString(payload, ["currency"]) ?? "TZS",
      });
    }
    const accessRevenueByPlanId = new Map<
      string,
      { revenueMinor: number; transactions: number; currency: string }
    >();
    for (const transaction of accessRevenueTransactions) {
      const planId = transaction.subscription.planId;
      const current = accessRevenueByPlanId.get(planId) ?? {
        revenueMinor: 0,
        transactions: 0,
        currency: transaction.currency,
      };
      current.revenueMinor += transaction.amountMinor;
      current.transactions += 1;
      current.currency = transaction.currency;
      accessRevenueByPlanId.set(planId, current);
    }
    const providerAccessRevenueByPlanCode = new Map<
      string,
      { revenueMinor: number; transactions: number; currency: string }
    >();
    const providerReminderRevenueByPackageCode = new Map<
      string,
      { revenueMinor: number; purchases: number; creditsSold: number; currency: string }
    >();
    for (const order of completedProviderOrders.values()) {
      const plan = planByCode.get(order.productCode);
      if (plan) {
        const current = providerAccessRevenueByPlanCode.get(order.productCode) ?? {
          revenueMinor: 0,
          transactions: 0,
          currency: order.currency,
        };
        current.revenueMinor += order.amountMinor;
        current.transactions += 1;
        current.currency = order.currency;
        providerAccessRevenueByPlanCode.set(order.productCode, current);
        continue;
      }
      const reminderPackage = reminderPackageByCode.get(order.productCode);
      if (reminderPackage) {
        const current =
          providerReminderRevenueByPackageCode.get(order.productCode) ?? {
            revenueMinor: 0,
            purchases: 0,
            creditsSold: 0,
            currency: order.currency,
          };
        current.revenueMinor += order.amountMinor;
        current.purchases += 1;
        current.creditsSold += reminderPackage.quantity;
        current.currency = order.currency;
        providerReminderRevenueByPackageCode.set(order.productCode, current);
      }
    }
    const hasProviderOrderRevenue = completedProviderOrders.size > 0;

    const reminderRevenueByPackageId = new Map<
      string,
      {
        revenueMinor: number;
        purchases: number;
        creditsSold: number;
        creditsUsed: number;
        currency: string;
      }
    >();
    for (const purchase of reminderPurchases) {
      const packageId = purchase.platformPrice.id;
      const current = reminderRevenueByPackageId.get(packageId) ?? {
        revenueMinor: 0,
        purchases: 0,
        creditsSold: 0,
        creditsUsed: 0,
        currency: purchase.currency,
      };
      current.revenueMinor += purchase.amountMinor;
      current.purchases += 1;
      current.creditsSold += purchase.quantity;
      current.creditsUsed += purchase.usedQuantity;
      current.currency = purchase.currency;
      reminderRevenueByPackageId.set(packageId, current);
    }

    const reminderRevenueMinor = reminderPurchases.reduce(
      (total, purchase) => total + purchase.amountMinor,
      0,
    );
    const reminderCreditsSold = reminderPurchases.reduce(
      (total, purchase) => total + purchase.quantity,
      0,
    );
    const reminderCreditsUsed = reminderPurchases.reduce(
      (total, purchase) => total + purchase.usedQuantity,
      0,
    );
    const providerAccessRevenueMinor = [
      ...providerAccessRevenueByPlanCode.values(),
    ].reduce((total, item) => total + item.revenueMinor, 0);
    const providerAccessTransactions = [
      ...providerAccessRevenueByPlanCode.values(),
    ].reduce((total, item) => total + item.transactions, 0);
    const providerReminderRevenueMinor = [
      ...providerReminderRevenueByPackageCode.values(),
    ].reduce((total, item) => total + item.revenueMinor, 0);
    const providerReminderPurchases = [
      ...providerReminderRevenueByPackageCode.values(),
    ].reduce((total, item) => total + item.purchases, 0);
    const providerReminderCreditsSold = [
      ...providerReminderRevenueByPackageCode.values(),
    ].reduce((total, item) => total + item.creditsSold, 0);
    const accessRevenueMinor = hasProviderOrderRevenue
      ? providerAccessRevenueMinor
      : billingTransactions._sum.amountMinor ?? 0;
    const effectiveReminderRevenueMinor = hasProviderOrderRevenue
      ? providerReminderRevenueMinor
      : reminderRevenueMinor;
    const effectiveReminderPurchases = hasProviderOrderRevenue
      ? providerReminderPurchases
      : reminderPurchases.length;
    const effectiveReminderCreditsSold = hasProviderOrderRevenue
      ? providerReminderCreditsSold
      : reminderCreditsSold;

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
        activeTrials,
      },
      contributions: {
        approvedPayments: contributionPayments._count,
        approvedAmountMinor: contributionPayments._sum.amountMinor ?? 0,
      },
      billing: {
        successfulTransactions: hasProviderOrderRevenue
          ? providerAccessTransactions
          : billingTransactions._count,
        successfulAmountMinor: accessRevenueMinor,
        totalRevenueMinor: accessRevenueMinor + effectiveReminderRevenueMinor,
        accessRevenueMinor,
        reminderRevenueMinor: effectiveReminderRevenueMinor,
      },
      reminders: {
        sentCampaigns: remindersSent,
        activePackages: reminderPackages,
        paidPackages: effectiveReminderPurchases,
        creditsSold: effectiveReminderCreditsSold,
        creditsUsed: reminderCreditsUsed,
        remainingCredits: Math.max(
          effectiveReminderCreditsSold - reminderCreditsUsed,
          0,
        ),
      },
      packages: {
        accessPlans: subscriptionPlans.map((plan) => {
          const providerRevenue = providerAccessRevenueByPlanCode.get(plan.code);
          const revenue = hasProviderOrderRevenue
            ? providerRevenue
            : accessRevenueByPlanId.get(plan.id);
          return {
            code: plan.code,
            name: plan.name,
            status: plan.status,
            priceMinor: plan.priceMinor,
            currency: plan.currency,
            interval: plan.interval,
            intervalCount: plan.intervalCount,
            trialDays: plan.trialDays,
            activeSubscriptions: activeSubscriptionsByPlanId.get(plan.id) ?? 0,
            successfulTransactions: revenue?.transactions ?? 0,
            revenueMinor: revenue?.revenueMinor ?? 0,
          };
        }),
        reminderPackages: reminderPackageRows.map((item) => {
          const providerRevenue = providerReminderRevenueByPackageCode.get(
            item.code,
          );
          const revenue = hasProviderOrderRevenue
            ? providerRevenue
            : reminderRevenueByPackageId.get(item.id);
          const localUsage = reminderRevenueByPackageId.get(item.id);
          return {
            code: item.code,
            name: item.name,
            channel: item.channel,
            isActive: item.isActive,
            purchases: revenue?.purchases ?? 0,
            creditsSold: revenue?.creditsSold ?? 0,
            creditsUsed: localUsage?.creditsUsed ?? 0,
            revenueMinor: revenue?.revenueMinor ?? 0,
            currency: revenue?.currency ?? "TZS",
          };
        }),
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

  private async ensureGroupExists(groupId: string): Promise<void> {
    const existing = await this.prisma.group.findUnique({
      where: { id: groupId },
      select: { id: true },
    });
    if (!existing) {
      throw new NotFoundException("Group was not found.");
    }
  }

  private firstString(
    payload: Record<string, unknown>,
    keys: string[],
  ): string | undefined {
    for (const key of keys) {
      const value = payload[key];
      if (typeof value === "string" && value.trim()) return value.trim();
      if (typeof value === "number") return String(value);
    }
    return undefined;
  }

  private numberValue(value: unknown): number | undefined {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? Math.round(parsed) : undefined;
  }

  private async reconcilePendingProviderPayments(): Promise<void> {
    const [subscriptions, reminderPurchases] = await Promise.all([
      this.prisma.subscription.findMany({
        where: {
          providerSubscriptionId: { not: null },
          plan: { priceMinor: { gt: 0 } },
        },
        include: {
          plan: true,
          transactions: { select: { id: true }, take: 1 },
        },
        orderBy: { updatedAt: "desc" },
        take: 50,
      }),
      this.prisma.reminderPackagePurchase.findMany({
        where: {
          status: ReminderPackagePurchaseStatus.PENDING,
          providerCheckoutId: { not: null },
        },
        orderBy: { updatedAt: "desc" },
        take: 50,
      }),
    ]);

    await Promise.all(
      subscriptions.map(async (subscription) => {
        if (!subscription.providerSubscriptionId) return;
        if (
          subscription.state === SubscriptionState.ACTIVE &&
          subscription.transactions.length > 0
        ) {
          return;
        }
        try {
          const providerOrder = await this.billingProvider.getSubscription(
            subscription.providerSubscriptionId,
          );
          if (providerOrder.status !== "active") return;
          const now = new Date();
          await this.prisma.subscription.update({
            where: { id: subscription.id },
            data: {
              state: SubscriptionState.ACTIVE,
              currentPeriodStartsAt: providerOrder.currentPeriodStartsAt,
              currentPeriodEndsAt: providerOrder.currentPeriodEndsAt,
              cancelAtPeriodEnd: providerOrder.cancelAtPeriodEnd,
              cancelledAt: null,
              expiredAt: null,
              suspendedAt: null,
            },
          });
          if (subscription.transactions.length === 0) {
            await this.prisma.billingTransaction.upsert({
              where: {
                providerTransactionId: subscription.providerSubscriptionId,
              },
              create: {
                subscriptionId: subscription.id,
                providerTransactionId: subscription.providerSubscriptionId,
                status: BillingTransactionStatus.SUCCEEDED,
                amountMinor: subscription.plan.priceMinor,
                currency: subscription.plan.currency,
                processedAt: now,
              },
              update: {
                status: BillingTransactionStatus.SUCCEEDED,
                processedAt: now,
              },
            });
          }
        } catch {
          // Keep dashboard reads resilient if the provider is temporarily unavailable.
        }
      }),
    );

    await Promise.all(
      reminderPurchases.map(async (purchase) => {
        if (!purchase.providerCheckoutId) return;
        try {
          const providerOrder = await this.billingProvider.getSubscription(
            purchase.providerCheckoutId,
          );
          if (providerOrder.status !== "active") return;
          await this.prisma.reminderPackagePurchase.update({
            where: { id: purchase.id },
            data: {
              status: ReminderPackagePurchaseStatus.PAID,
              paidAt: new Date(),
            },
          });
        } catch {
          // Keep dashboard reads resilient if the provider is temporarily unavailable.
        }
      }),
    );
  }

  private async uniqueGroupSlug(name: string, currentGroupId?: string) {
    const base =
      name
        .trim()
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, "-")
        .replace(/(^-|-$)/g, "") || "group";
    let slug = base;
    let index = 2;
    while (true) {
      const existing = await this.prisma.group.findUnique({
        where: { slug },
        select: { id: true },
      });
      if (!existing || existing.id === currentGroupId) {
        return slug;
      }
      slug = `${base}-${index}`;
      index += 1;
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
