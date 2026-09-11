// cspell:words Habari malipo yako yanatakiwa tarehe Kumbusho Ombi udhamini amekuomba mkopo yameidhinishwa yamekataliwa yanahitaji marekebisho amewasilisha marejesho Udhamini umekubaliwa amekubali amekataa
import {
  BadGatewayException,
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import {
  AuditAction,
  BillingInterval,
  ContributionFrequency,
  ContributionObligationStatus,
  ContributionPlanType,
  GroupExpenseStatus,
  GroupContributionPaymentStatus,
  GroupLoanStatus,
  GroupMemberStatus,
  GroupRole,
  LoanApplicationStatus,
  LoanGuarantorStatus,
  LoanRepaymentStatus,
  Locale,
  PaymentAllocationStatus,
  ReminderPackagePurchaseStatus,
  ReceiptStatus,
  SubscriptionPlanStatus,
  SubscriptionState,
  UserIdentityType,
} from "@prisma/client";
import type { GroupMember, Prisma } from "@prisma/client";
import { createHash, randomBytes, randomInt } from "crypto";
import { ConfigService } from "@nestjs/config";

import { AuthenticatedUser } from "../common/auth/authenticated-user";
import { ApiErrorCode } from "../common/errors/api-error-code";
import { hasPaidFeatureAccess } from "../common/subscriptions/subscription-access.policy";
import { PrismaService } from "../prisma/prisma.service";
import { SUBSCRIPTION_BILLING_PROVIDER } from "../billing/billing-provider.token";
import { SubscriptionBillingProvider } from "../billing/subscription-billing-provider";
import { BriqMessagingService } from "../messaging/briq-messaging.service";
import { FirebasePushService } from "../messaging/firebase-push.service";
import { SmtpEmailService } from "../messaging/smtp-email.service";
import { groupInvitationEmailTemplate } from "./group-invitation-email.template";
import { ReminderDispatchService } from "./reminder-dispatch.service";
import {
  AddMemberDto,
  AssignRoleDto,
  UpdateMemberStatusDto,
  ContributionSettingsDto,
  CreateGroupExpenseDto,
  CreateGroupDto,
  CreateLoanApplicationDto,
  CreateReminderPackageCheckoutDto,
  FinancialYearDto,
  HistoricalContributionPaymentDto,
  ImportHistoricalContributionPaymentsDto,
  InviteMembersDto,
  JoinGroupDto,
  PaymentRulesDto,
  RecordContributionPaymentDto,
  RecordLoanRepaymentDto,
  RegisterPushTokenDto,
  ReminderSettingsDto,
  ReviewContributionPaymentDto,
  ReviewGroupExpenseDto,
  ReviewLoanApplicationDto,
  SendReminderDto,
  SubmitContributionPaymentRequestDto,
  UpdateLanguageDto,
} from "./dto/group.dto";

type ScheduleFinancialYear = {
  id: string;
  name: string;
  startsAt: Date;
  endsAt: Date;
};

type ScheduleContributionPlan = {
  id: string;
  name: string;
  type: ContributionPlanType;
  frequency: ContributionFrequency;
  dueDayOfWeek: number | null;
  dueDayOfMonth: number | null;
  amountMinor: number;
  currency: string;
  cycleAnchorDate?: Date | null;
};

type ContributionPeriodSpec = {
  label: string;
  startsAt: Date;
  endsAt: Date;
  dueAt: Date;
  sortOrder: number;
};

type InvitationDeliveryResult = {
  channel: "sms" | "email";
  destination: string;
  provider: string;
  delivered: boolean;
};

type GroupCashClient = Pick<
  Prisma.TransactionClient,
  "groupContributionPayment" | "groupExpense" | "groupLoan"
>;

@Injectable()
export class GroupsService {
  constructor(
    private readonly prisma: PrismaService,
    @Inject(SUBSCRIPTION_BILLING_PROVIDER)
    private readonly billingProvider: SubscriptionBillingProvider,
    private readonly briq: BriqMessagingService,
    private readonly pushNotifications: FirebasePushService,
    private readonly email: SmtpEmailService,
    private readonly reminderDispatch: ReminderDispatchService,
    private readonly config: ConfigService = new ConfigService(),
  ) {}

  private imageUrl(key: string | null): string | null {
    const cloud = this.config.get<string>("CLOUDINARY_CLOUD_NAME");
    return key && cloud
      ? `https://res.cloudinary.com/${encodeURIComponent(cloud)}/image/upload/${key.split("/").map(encodeURIComponent).join("/")}`
      : null;
  }

  async profile(user: AuthenticatedUser) {
    const profile = await this.prisma.user.findUniqueOrThrow({
      where: { id: user.id },
      select: {
        id: true,
        displayName: true,
        profilePictureObjectKey: true,
        identities: {
          where: { isVerified: true },
          select: { type: true, value: true },
        },
      },
    });
    return {
      ...profile,
      profilePictureUrl: this.imageUrl(profile.profilePictureObjectKey),
    };
  }

  async updateProfile(user: AuthenticatedUser, name: string) {
    if (name.trim().length < 2)
      throw new BadRequestException("Enter your full name.");
    await this.prisma.user.update({
      where: { id: user.id },
      data: { displayName: name.trim() },
    });
    return this.profile(user);
  }

  async updateLanguage(user: AuthenticatedUser, input: UpdateLanguageDto) {
    const updated = await this.prisma.user.update({
      where: { id: user.id },
      data: { preferredLocale: input.locale === "sw" ? Locale.sw : Locale.en },
    });
    return { userId: updated.id, preferredLocale: updated.preferredLocale };
  }

  async registerPushToken(
    user: AuthenticatedUser,
    input: RegisterPushTokenDto,
  ) {
    const token = input.token.trim();
    if (token.length === 0) {
      throw new BadRequestException("Push token is required.");
    }

    await this.prisma.pushDeviceToken.upsert({
      where: { token },
      update: {
        userId: user.id,
        platform: input.platform,
        deviceId: input.deviceId,
        appVersion: input.appVersion,
        lastSeenAt: new Date(),
      },
      create: {
        userId: user.id,
        token,
        platform: input.platform,
        deviceId: input.deviceId,
        appVersion: input.appVersion,
      },
    });

    return { registered: true };
  }

  async paymentRules(user: AuthenticatedUser, groupId: string) {
    await this.requireMembership(user, groupId);
    return (
      (await this.prisma.groupPaymentRule.findUnique({
        where: { groupId },
      })) ?? {
        allowsPartial: true,
        penaltiesEnabled: false,
        penaltyAmountMinor: 0,
        graceDays: 0,
      }
    );
  }

  async savePaymentRules(
    user: AuthenticatedUser,
    groupId: string,
    input: PaymentRulesDto,
  ) {
    await this.requireMembership(user, groupId, [GroupRole.GROUP_ADMIN]);
    if (input.penaltiesEnabled && input.penaltyAmountMinor <= 0)
      throw new BadRequestException("Enter a positive penalty amount.");
    return this.prisma.$transaction(async (tx) => {
      const rule = await tx.groupPaymentRule.upsert({
        where: { groupId },
        update: { ...input, effectiveAt: new Date() },
        create: { groupId, ...input },
      });
      await tx.contributionPlan.updateMany({
        where: { groupId },
        data: { allowsPartial: input.allowsPartial },
      });
      return rule;
    });
  }

  private async applyLatePenalties(
    groupId: string,
    db: Prisma.TransactionClient,
  ) {
    const rule = await db.groupPaymentRule.findUnique({ where: { groupId } });
    if (!rule?.penaltiesEnabled || rule.penaltyAmountMinor <= 0) return;
    const cutoff = this.addDays(this.startOfDay(new Date()), -rule.graceDays);
    const obligations = await db.memberContributionObligation.findMany({
      where: {
        member: { groupId, status: GroupMemberStatus.ACTIVE },
        plan: { type: { not: ContributionPlanType.PENALTY } },
        dueAt: { gte: rule.effectiveAt, lt: cutoff },
        status: {
          in: [
            ContributionObligationStatus.DUE,
            ContributionObligationStatus.PARTIALLY_PAID,
            ContributionObligationStatus.OVERDUE,
          ],
        },
      },
    });
    for (const item of obligations) {
      if (item.amountPaidMinor >= item.amountDueMinor) continue;
      const plan = await db.contributionPlan.upsert({
        where: { groupId_name: { groupId, name: "Late penalty" } },
        update: {},
        create: {
          groupId,
          name: "Late penalty",
          type: ContributionPlanType.PENALTY,
          frequency: ContributionFrequency.ONCE,
          amountMinor: rule.penaltyAmountMinor,
          currency: item.currency,
          allowsPartial: rule.allowsPartial,
        },
      });
      await db.memberContributionObligation.upsert({
        where: { penaltySourceId: item.id },
        update: {},
        create: {
          penaltySourceId: item.id,
          groupMemberId: item.groupMemberId,
          planId: plan.id,
          amountDueMinor: rule.penaltyAmountMinor,
          currency: item.currency,
          dueAt: new Date(),
          status: ContributionObligationStatus.DUE,
        },
      });
    }
  }

  async myGroups(user: AuthenticatedUser) {
    const memberships = await this.prisma.groupMember.findMany({
      where: { userId: user.id, status: GroupMemberStatus.ACTIVE },
      include: {
        group: {
          include: {
            _count: { select: { members: true } },
            subscriptions: {
              include: { plan: true },
              orderBy: { updatedAt: "desc" },
              take: 1,
            },
          },
        },
      },
      orderBy: { updatedAt: "desc" },
    });
    const groups = await Promise.all(
      memberships.map(async (membership) => {
        const subscription = await this.syncProviderSubscription(
          membership.group.subscriptions[0] ?? null,
        );
        return {
          id: membership.groupId,
          membershipId: membership.id,
          name: membership.group.name,
          role: membership.role,
          status: membership.status,
          membersCount: membership.group._count.members,
          logoUrl: this.imageUrl(membership.group.logoObjectKey),
          subscription: subscription
            ? {
                planCode: subscription.plan.code,
                state: subscription.state,
                currentPeriodEndsAt: subscription.currentPeriodEndsAt,
                hasPaidFeatureAccess: hasPaidFeatureAccess({
                  state: subscription.state,
                  currentPeriodEndsAt: subscription.currentPeriodEndsAt,
                }),
              }
            : null,
        };
      }),
    );
    return { groups };
  }

  async createGroup(user: AuthenticatedUser, input: CreateGroupDto) {
    const name = input.name.trim();
    const slug = await this.uniqueSlug(name);
    const identities = await this.prisma.userIdentity.findMany({
      where: { userId: user.id, isVerified: true },
      select: { type: true, value: true },
    });
    const phone =
      identities.find((identity) => identity.type === UserIdentityType.PHONE)
        ?.value ?? null;
    const email =
      identities.find((identity) => identity.type === UserIdentityType.EMAIL)
        ?.value ?? null;
    const displayName = await this.displayName(user.id);
    const group = await this.prisma.$transaction(async (tx) => {
      const created = await tx.group.create({
        data: {
          name,
          slug,
          type: input.type?.trim() || undefined,
          description: input.description?.trim() || undefined,
          location: input.location?.trim() || undefined,
          currency: input.currency?.trim().toUpperCase() || "TZS",
          billingOwnerUserId: user.id,
          establishedAt: input.establishedAt
            ? new Date(input.establishedAt)
            : undefined,
          historicalDataStartsAt: input.historicalDataStartsAt
            ? new Date(input.historicalDataStartsAt)
            : undefined,
          members: {
            create: {
              userId: user.id,
              memberNumber: "MBR-000001",
              fullName: displayName,
              phone,
              email,
              role: GroupRole.GROUP_ADMIN,
              status: GroupMemberStatus.ACTIVE,
              joinedAt: new Date(),
            },
          },
        },
        include: { members: true },
      });
      const starterPlan = await this.findStarterPlan(tx);
      if (starterPlan) {
        const startsAt = new Date();
        await tx.billingCustomer.create({
          data: {
            groupId: created.id,
            userId: user.id,
            provider: this.billingProvider.provider,
            providerCustomerId: `starter_${created.id}`,
            email,
            phone,
            subscriptions: {
              create: {
                id: `${created.id}:${starterPlan.id}`,
                groupId: created.id,
                planId: starterPlan.id,
                provider: this.billingProvider.provider,
                state: SubscriptionState.TRIAL,
                currentPeriodStartsAt: startsAt,
                currentPeriodEndsAt: this.addDays(
                  startsAt,
                  Math.max(1, starterPlan.trialDays),
                ),
                trialEndsAt: this.addDays(
                  startsAt,
                  Math.max(1, starterPlan.trialDays),
                ),
              },
            },
          },
        });
      }
      return created;
    });
    await this.prisma.auditLog.create({
      data: {
        actorUserId: user.id,
        groupId: group.id,
        action: AuditAction.GROUP_UPDATED,
        entityType: "Group",
        entityId: group.id,
      },
    });
    return {
      id: group.id,
      membershipId:
        group.members.find((member) => member.userId === user.id)?.id ??
        group.members[0]?.id,
      name: group.name,
      currency: group.currency,
      establishedAt: group.establishedAt,
      historicalDataStartsAt: group.historicalDataStartsAt,
      currentUserRole: GroupRole.GROUP_ADMIN,
      nextStep: "FINANCIAL_YEAR",
    };
  }

  async previewJoinCode(invitationCode: string) {
    const code = this.normalizeInvitationCode(invitationCode);
    const invitation = await this.prisma.groupInvitation.findUnique({
      where: { tokenHash: this.hash(code) },
      include: {
        group: { include: { _count: { select: { members: true } } } },
      },
    });
    if (
      !invitation ||
      invitation.acceptedAt ||
      invitation.expiresAt <= new Date()
    ) {
      throw new NotFoundException("Invitation was not found or has expired.");
    }
    return {
      invitationCode: code,
      group: {
        id: invitation.group.id,
        name: invitation.group.name,
        membersCount: invitation.group._count.members,
      },
      roleOnJoin: invitation.role,
      fees: await this.prisma.contributionPlan.findMany({
        where: { groupId: invitation.groupId, isActive: true },
        select: { name: true, type: true, amountMinor: true, frequency: true },
        orderBy: { name: "asc" },
      }),
      currency: invitation.group.currency,
    };
  }

  private findStarterPlan(db: Prisma.TransactionClient | PrismaService) {
    return db.subscriptionPlan.findFirst({
      where: {
        status: SubscriptionPlanStatus.ACTIVE,
        priceMinor: 0,
        trialDays: { gt: 0 },
        OR: [
          { code: { contains: "starter", mode: "insensitive" } },
          { name: { contains: "starter", mode: "insensitive" } },
        ],
      },
      orderBy: [{ trialDays: "desc" }, { createdAt: "asc" }],
    });
  }

  async joinGroup(user: AuthenticatedUser, input: JoinGroupDto) {
    const code = this.normalizeInvitationCode(input.invitationCode);
    return this.prisma.$transaction(
      async (tx) => {
        const invitation = await tx.groupInvitation.findUnique({
          where: { tokenHash: this.hash(code) },
          include: { group: true, member: true },
        });
        if (
          !invitation ||
          invitation.acceptedAt ||
          invitation.expiresAt <= new Date()
        ) {
          throw new NotFoundException(
            "Invitation was not found or has expired.",
          );
        }
        const existingMembership = await tx.groupMember.findFirst({
          where: {
            groupId: invitation.groupId,
            userId: user.id,
            ...(invitation.groupMemberId
              ? { id: { not: invitation.groupMemberId } }
              : {}),
          },
        });
        if (existingMembership) {
          throw new ConflictException(
            "You are already a member of this group.",
          );
        }

        const now = new Date();
        const claimed = await tx.groupInvitation.updateMany({
          where: {
            id: invitation.id,
            acceptedAt: null,
            expiresAt: { gt: now },
          },
          data: { acceptedAt: now },
        });
        if (claimed.count !== 1) {
          throw new ConflictException(
            "This invitation has already been accepted.",
          );
        }
        const membership = invitation.member
          ? await this.activateInvitedMember(
              user,
              invitation.member,
              invitation.role,
              now,
              tx,
            )
          : await tx.groupMember.create({
              data: {
                groupId: invitation.groupId,
                userId: user.id,
                memberNumber: await this.nextMemberNumber(
                  invitation.groupId,
                  tx,
                ),
                fullName: await this.displayName(user.id),
                role: invitation.role,
                status: GroupMemberStatus.ACTIVE,
                joinedAt: now,
              },
            });
        await this.generateContributionSchedule(
          invitation.groupId,
          membership.id,
          tx,
        );
        return {
          groupId: invitation.groupId,
          membershipId: membership.id,
          role: membership.role,
          status: membership.status,
        };
      },
      { timeout: 30000 },
    );
  }

  async onboarding(user: AuthenticatedUser, groupId: string) {
    await this.requireMembership(user, groupId);
    const [financialYear, plansCount, membersCount] = await Promise.all([
      this.prisma.financialYear.findFirst({
        where: { groupId, isActive: true },
      }),
      this.prisma.contributionPlan.count({
        where: { groupId, isActive: true },
      }),
      this.prisma.groupMember.count({ where: { groupId } }),
    ]);
    return {
      groupId,
      steps: [
        { code: "GROUP_CREATED", completed: true },
        { code: "FINANCIAL_YEAR", completed: Boolean(financialYear) },
        { code: "CONTRIBUTIONS", completed: plansCount > 0 },
        { code: "FIRST_MEMBER", completed: membersCount > 1 },
      ],
    };
  }

  async saveFinancialYear(
    user: AuthenticatedUser,
    groupId: string,
    input: FinancialYearDto,
  ) {
    await this.requireMembership(user, groupId, [GroupRole.GROUP_ADMIN]);
    const startsAt = new Date(input.startsAt);
    const endsAt = new Date(input.endsAt);
    const duration = endsAt.getTime() - startsAt.getTime();
    if (duration <= 0 || duration > 367 * 86400000)
      throw new BadRequestException(
        "Enter a valid financial year of no more than 12 months.",
      );
    return this.prisma.$transaction(
      async (tx) => {
        await tx.financialYear.updateMany({
          where: { groupId },
          data: { isActive: false },
        });
        const financialYear = await tx.financialYear.upsert({
          where: { groupId_startsAt_endsAt: { groupId, startsAt, endsAt } },
          update: {
            name: input.name,
            isActive: true,
            automaticRollover: input.automaticRollover ?? true,
          },
          create: {
            groupId,
            name: input.name,
            startsAt: new Date(input.startsAt),
            endsAt: new Date(input.endsAt),
            isActive: true,
            automaticRollover: input.automaticRollover ?? true,
          },
        });
        await this.generateContributionSchedule(groupId, undefined, tx);
        return financialYear;
      },
      { isolationLevel: "Serializable", timeout: 30000 },
    );
  }

  async financialYears(user: AuthenticatedUser, groupId: string) {
    await this.requireMembership(user, groupId);
    const financialYears = await this.prisma.financialYear.findMany({
      where: { groupId },
      orderBy: { startsAt: "desc" },
      select: {
        id: true,
        name: true,
        startsAt: true,
        endsAt: true,
        isActive: true,
      },
    });
    return { groupId, financialYears };
  }

  async saveContributionSettings(
    user: AuthenticatedUser,
    groupId: string,
    input: ContributionSettingsDto,
  ) {
    await this.requireMembership(user, groupId, [GroupRole.GROUP_ADMIN]);
    const membershipFrequency = this.contributionFrequency(
      input.membershipFeeFrequency,
      ContributionFrequency.ANNUAL,
    );
    const memberContributionFrequency = this.contributionFrequency(
      input.memberContributionFrequency ?? input.frequency,
      ContributionFrequency.MONTHLY,
    );
    const memberContributionMinor =
      input.memberContributionMinor ?? input.membershipFeeMinor;
    const memberContributionWeekDays = this.memberContributionWeeklyDays(input);
    const memberContributionDueDayOfWeek =
      memberContributionFrequency === ContributionFrequency.WEEKLY
        ? memberContributionWeekDays[0]
        : (input.memberContributionDueDayOfWeek ?? input.dueDayOfWeek);
    this.validateContributionCycle(
      membershipFrequency,
      input.membershipDueDayOfWeek ?? input.dueDayOfWeek,
      input.membershipDueDayOfMonth ?? input.dueDayOfMonth,
    );
    this.validateContributionCycle(
      memberContributionFrequency,
      memberContributionDueDayOfWeek,
      input.memberContributionDueDayOfMonth ?? input.dueDayOfMonth,
    );
    const membershipCycleData = this.contributionCycleData(
      input,
      membershipFrequency,
      input.membershipDueDayOfWeek ?? input.dueDayOfWeek,
      input.membershipDueDayOfMonth ?? input.dueDayOfMonth,
    );
    const contributionPlanDays =
      memberContributionFrequency === ContributionFrequency.WEEKLY
        ? memberContributionWeekDays
        : [memberContributionDueDayOfWeek];
    await this.prisma.$transaction([
      this.prisma.contributionPlan.updateMany({
        where: {
          groupId,
          type: ContributionPlanType.RECURRING,
          name: { startsWith: "Member contribution" },
        },
        data: { isActive: false },
      }),
      this.prisma.contributionPlan.upsert({
        where: { groupId_name: { groupId, name: "Joining fee" } },
        update: {
          amountMinor: input.joiningFeeMinor,
          frequency: ContributionFrequency.ANNUAL,
          type: ContributionPlanType.JOINING_FEE,
        },
        create: {
          groupId,
          name: "Joining fee",
          amountMinor: input.joiningFeeMinor,
          frequency: ContributionFrequency.ANNUAL,
          type: ContributionPlanType.JOINING_FEE,
        },
      }),
      this.prisma.contributionPlan.upsert({
        where: { groupId_name: { groupId, name: "Membership fee" } },
        update: {
          amountMinor: input.membershipFeeMinor,
          frequency: membershipFrequency,
          ...membershipCycleData,
          type: ContributionPlanType.RECURRING,
        },
        create: {
          groupId,
          name: "Membership fee",
          amountMinor: input.membershipFeeMinor,
          frequency: membershipFrequency,
          ...membershipCycleData,
          type: ContributionPlanType.RECURRING,
        },
      }),
      ...contributionPlanDays.map((dueDayOfWeek, index) => {
        const planName = this.memberContributionPlanName(
          memberContributionFrequency,
          memberContributionWeekDays,
          dueDayOfWeek,
          index,
        );
        const contributionCycleData = this.contributionCycleData(
          input,
          memberContributionFrequency,
          dueDayOfWeek,
          input.memberContributionDueDayOfMonth ?? input.dueDayOfMonth,
        );

        return this.prisma.contributionPlan.upsert({
          where: { groupId_name: { groupId, name: planName } },
          update: {
            amountMinor: memberContributionMinor,
            frequency: memberContributionFrequency,
            ...contributionCycleData,
            type: ContributionPlanType.RECURRING,
            isActive: true,
          },
          create: {
            groupId,
            name: planName,
            amountMinor: memberContributionMinor,
            frequency: memberContributionFrequency,
            ...contributionCycleData,
            type: ContributionPlanType.RECURRING,
          },
        });
      }),
    ]);
    const paymentRule = await this.prisma.groupPaymentRule.findUnique({
      where: { groupId },
    });
    const group = await this.prisma.group.findUniqueOrThrow({
      where: { id: groupId },
      select: { currency: true },
    });
    await this.prisma.contributionPlan.updateMany({
      where: { groupId },
      data: {
        currency: group.currency,
        allowsPartial: paymentRule?.allowsPartial ?? true,
      },
    });
    await this.generateContributionSchedule(groupId);
    return {
      groupId,
      ...input,
      membershipFeeFrequency: membershipFrequency,
      memberContributionMinor,
      memberContributionFrequency,
      memberContributionDueDaysOfWeek:
        memberContributionFrequency === ContributionFrequency.WEEKLY
          ? memberContributionWeekDays
          : undefined,
    };
  }

  async saveReminderSettings(
    user: AuthenticatedUser,
    groupId: string,
    input: ReminderSettingsDto,
  ) {
    await this.requireMembership(user, groupId, [GroupRole.GROUP_ADMIN]);
    const locale = input.locale ?? "en";
    const existing = await this.prisma.groupReminderRule.findUnique({
      where: { groupId },
    });
    const body =
      input.dueReminderTemplate?.trim() ||
      existing?.body ||
      (locale === "sw"
        ? "Habari {member_name}, malipo yako ya {amount} yanatakiwa tarehe {due_date}."
        : "Hi {member_name}, your payment of {amount} is due on {due_date}.");
    const enabled = input.enabled ?? Boolean(input.dueReminderTemplate);
    const offsets = input.offsets ?? existing?.offsets ?? [-3, 0];
    if (enabled && offsets.length === 0)
      throw new BadRequestException("Select a reminder schedule.");
    await this.prisma.groupReminderRule.upsert({
      where: { groupId },
      update: { enabled, offsets, locale, body },
      create: { groupId, enabled, offsets, locale, body },
    });
    const template = await this.prisma.reminderTemplate.upsert({
      where: {
        groupId_locale_code: { groupId, locale, code: "dues" },
      },
      update: { body },
      create: {
        groupId,
        locale,
        code: "dues",
        title: "Outstanding dues",
        body,
      },
    });
    return { groupId, configured: true, templateId: template.id };
  }

  async reminderSettings(user: AuthenticatedUser, groupId: string) {
    await this.requireMembership(user, groupId, [GroupRole.GROUP_ADMIN]);
    return (
      (await this.prisma.groupReminderRule.findUnique({
        where: { groupId },
      })) ?? {
        groupId,
        enabled: false,
        offsets: [-3, 0],
        locale: "en",
        body: "",
      }
    );
  }

  async dashboard(user: AuthenticatedUser, groupId: string) {
    const membership = await this.requireMembership(user, groupId);
    const now = new Date();
    const [
      group,
      membersCount,
      paid,
      outstanding,
      expenses,
      activeLoans,
      monthlyTrend,
    ] = await Promise.all([
        this.prisma.group.findUniqueOrThrow({ where: { id: groupId } }),
        this.prisma.groupMember.count({ where: { groupId } }),
        this.prisma.groupContributionPayment.aggregate({
          where: { groupId, status: "APPROVED" },
          _sum: { amountMinor: true },
        }),
        this.prisma.memberContributionObligation.aggregate({
          where: {
            member: { groupId },
            dueAt: { lte: now },
            status: {
              in: [
                ContributionObligationStatus.UPCOMING,
                ContributionObligationStatus.DUE,
                ContributionObligationStatus.PARTIALLY_PAID,
                ContributionObligationStatus.OVERDUE,
              ],
            },
          },
          _sum: { amountDueMinor: true, amountPaidMinor: true },
        }),
        this.prisma.groupExpense.aggregate({
          where: { groupId, status: GroupExpenseStatus.APPROVED },
          _sum: { amountMinor: true },
        }),
        this.prisma.groupLoan.aggregate({
          where: { groupId, status: GroupLoanStatus.ACTIVE },
          _sum: { amountMinor: true, amountPaidMinor: true },
        }),
        this.monthlyContributionTrend(groupId, now),
      ]);
    const due = outstanding._sum.amountDueMinor ?? 0;
    const paidObligations = outstanding._sum.amountPaidMinor ?? 0;
    const collectedMinor = paid._sum.amountMinor ?? 0;
    const expensesMinor = expenses._sum.amountMinor ?? 0;
    const loanPrincipalOutMinor = Math.max(
      (activeLoans._sum.amountMinor ?? 0) -
        (activeLoans._sum.amountPaidMinor ?? 0),
      0,
    );
    return {
      groupId,
      role: membership.role,
      groupName: group.name,
      metrics: {
        membersCount,
        collectedMinor,
        outstandingMinor: Math.max(due - paidObligations, 0),
        expensesMinor,
        loanPrincipalOutMinor,
        cashBalanceMinor: Math.max(
          collectedMinor - expensesMinor - loanPrincipalOutMinor,
          0,
        ),
        monthlyTrend,
      },
    };
  }

  async expenses(user: AuthenticatedUser, groupId: string) {
    const membership = await this.requireMembership(user, groupId);
    const canReview = membership.role === GroupRole.GROUP_ADMIN;
    const [items, cash] = await Promise.all([
      this.prisma.groupExpense.findMany({
        where: { groupId },
        include: {
          createdBy: { select: { displayName: true } },
          reviewedBy: { select: { displayName: true } },
        },
        orderBy: { createdAt: "desc" },
      }),
      this.groupCashPosition(this.prisma, groupId),
    ]);
    return {
      groupId,
      canReview,
      summary: {
        approvedExpenseMinor: cash.approvedExpenseMinor,
        pendingExpenseMinor: cash.pendingExpenseMinor,
        pendingCount: cash.pendingCount,
        loanPrincipalOutMinor: cash.loanPrincipalOutMinor,
        cashBalanceMinor: cash.cashBalanceMinor,
        availableExpenseMinor: cash.availableExpenseMinor,
      },
      expenses: items.map((item) => this.groupExpenseSummary(item)),
    };
  }

  async createExpense(
    user: AuthenticatedUser,
    groupId: string,
    input: CreateGroupExpenseDto,
  ) {
    const membership = await this.requireMembership(user, groupId, [
      GroupRole.GROUP_ADMIN,
      GroupRole.TREASURER,
    ]);
    const group = await this.prisma.group.findUniqueOrThrow({
      where: { id: groupId },
      select: { currency: true, name: true },
    });
    return this.prisma.$transaction(async (tx) => {
      const cash = await this.groupCashPosition(tx, groupId);
      if (cash.availableExpenseMinor <= 0) {
        throw new BadRequestException(
          "Group has no available cash for expenses.",
        );
      }
      if (input.amountMinor > cash.availableExpenseMinor) {
        throw new BadRequestException(
          "Expense amount exceeds available group cash.",
        );
      }

      const expense = await tx.groupExpense.create({
        data: {
          groupId,
          createdByUserId: user.id,
          category: input.category.trim(),
          purpose: input.purpose.trim(),
          beneficiary: this.optionalTrim(input.beneficiary),
          amountMinor: input.amountMinor,
          currency: input.currency?.trim().toUpperCase() || group.currency,
          paymentRail: this.optionalTrim(input.paymentRail),
          reference: this.optionalTrim(input.reference),
          spentAt: input.spentAt ? new Date(input.spentAt) : new Date(),
        },
        include: {
          createdBy: { select: { displayName: true } },
          reviewedBy: { select: { displayName: true } },
        },
      });
      await tx.auditLog.create({
        data: {
          actorUserId: user.id,
          groupId,
          action: AuditAction.GROUP_EXPENSE_SUBMITTED,
          entityType: "GroupExpense",
          entityId: expense.id,
          newValue: {
            category: expense.category,
            amountMinor: expense.amountMinor,
            createdByRole: membership.role,
          },
        },
      });
      const admins = await tx.groupMember.findMany({
        where: {
          groupId,
          role: GroupRole.GROUP_ADMIN,
          status: GroupMemberStatus.ACTIVE,
          userId: { not: null },
        },
        select: { userId: true },
      });
      for (const admin of admins) {
        await this.createUserNotification(tx, {
          userId: admin.userId,
          titleEn: "Expense pending approval",
          titleSw: "Matumizi yanasubiri idhini",
          bodyEn: `${membership.fullName} recorded an expense of ${expense.currency} ${expense.amountMinor}.`,
          bodySw: `${membership.fullName} amerekodi matumizi ya ${expense.currency} ${expense.amountMinor}.`,
        });
      }
      return this.groupExpenseSummary(expense);
    });
  }

  async reviewExpense(
    user: AuthenticatedUser,
    groupId: string,
    expenseId: string,
    input: ReviewGroupExpenseDto,
  ) {
    await this.requireMembership(user, groupId, [GroupRole.GROUP_ADMIN]);
    return this.prisma.$transaction(async (tx) => {
      const expense = await tx.groupExpense.findFirst({
        where: { id: expenseId, groupId },
      });
      if (!expense) throw new NotFoundException("Expense was not found.");
      if (expense.status !== GroupExpenseStatus.SUBMITTED) {
        throw new BadRequestException("Expense has already been reviewed.");
      }
      if (input.approve) {
        const cash = await this.groupCashPosition(tx, groupId);
        if (expense.amountMinor > cash.cashBalanceMinor) {
          throw new BadRequestException(
            "Expense amount exceeds available group cash.",
          );
        }
      }
      const status = input.approve
        ? GroupExpenseStatus.APPROVED
        : GroupExpenseStatus.REJECTED;
      const updated = await tx.groupExpense.update({
        where: { id: expense.id },
        data: {
          status,
          reviewedByUserId: user.id,
          reviewedAt: new Date(),
          reviewNotes: this.optionalTrim(input.notes),
        },
        include: {
          createdBy: { select: { displayName: true } },
          reviewedBy: { select: { displayName: true } },
        },
      });
      await tx.auditLog.create({
        data: {
          actorUserId: user.id,
          groupId,
          action: input.approve
            ? AuditAction.GROUP_EXPENSE_APPROVED
            : AuditAction.GROUP_EXPENSE_REJECTED,
          entityType: "GroupExpense",
          entityId: expense.id,
          previousValue: { status: expense.status },
          newValue: { status, notes: input.notes },
        },
      });
      if (expense.createdByUserId && expense.createdByUserId !== user.id) {
        await this.createUserNotification(tx, {
          userId: expense.createdByUserId,
          titleEn: input.approve ? "Expense approved" : "Expense rejected",
          titleSw: input.approve
            ? "Matumizi yameidhinishwa"
            : "Matumizi yamekataliwa",
          bodyEn: `Your ${expense.currency} ${expense.amountMinor} expense has been ${input.approve ? "approved" : "rejected"}.`,
          bodySw: `Matumizi yako ya ${expense.currency} ${expense.amountMinor} ${input.approve ? "yameidhinishwa" : "yamekataliwa"}.`,
        });
      }
      return this.groupExpenseSummary(updated);
    });
  }

  async listMembers(user: AuthenticatedUser, groupId: string) {
    await this.requireMembership(user, groupId);
    const now = new Date();
    const members = await this.prisma.groupMember.findMany({
      where: { groupId },
      orderBy: [{ fullName: "asc" }],
      include: {
        user: { select: { displayName: true, profilePictureObjectKey: true } },
        obligations: {
          where: {
            dueAt: { lte: now },
            status: {
              in: [
                ContributionObligationStatus.UPCOMING,
                ContributionObligationStatus.DUE,
                ContributionObligationStatus.PARTIALLY_PAID,
                ContributionObligationStatus.OVERDUE,
              ],
            },
          },
          select: { amountDueMinor: true, amountPaidMinor: true },
        },
      },
    });
    return {
      members: members.map((member) => ({
        ...member,
        fullName: member.user?.displayName ?? member.fullName,
        profilePictureUrl: this.imageUrl(
          member.user?.profilePictureObjectKey ?? null,
        ),
        outstandingMinor: member.obligations.reduce(
          (sum, due) =>
            sum + Math.max(0, due.amountDueMinor - due.amountPaidMinor),
          0,
        ),
      })),
    };
  }

  async addMember(
    user: AuthenticatedUser,
    groupId: string,
    input: AddMemberDto,
  ) {
    const inviter = await this.requireMembership(user, groupId, [
      GroupRole.GROUP_ADMIN,
    ]);
    const group = await this.prisma.group.findUniqueOrThrow({
      where: { id: groupId },
    });
    const fullName = input.fullName.trim();
    const requestedNumber = this.optionalTrim(
      input.memberNumber,
    )?.toUpperCase();
    if (requestedNumber && !/^MBR-[0-9]{6}$/.test(requestedNumber)) {
      throw new BadRequestException(
        "Use member number format MBR-000001, or leave it empty.",
      );
    }
    const rawPhone = this.optionalTrim(input.phone);
    const phone = rawPhone ? this.normalizePhone(rawPhone) : null;
    const email = this.optionalTrim(input.email)?.toLowerCase() ?? null;

    if (!fullName) {
      throw new BadRequestException("Enter the member full name.");
    }
    if (!phone && !email) {
      throw new BadRequestException(
        "Provide a phone number or email address so the invitation can be delivered.",
      );
    }

    const role = input.role ?? GroupRole.MEMBER;
    const { member, invitation, token } = await this.prisma.$transaction(
      async (tx) => {
        const token = await this.uniqueInvitationCode(tx);
        await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext(${groupId}))`;
        const numbers = await tx.groupMember.findMany({
          where: { groupId },
          select: { memberNumber: true },
        });
        const next =
          numbers.reduce(
            (max, item) =>
              /^MBR-[0-9]{6}$/.test(item.memberNumber ?? "")
                ? Math.max(max, Number(item.memberNumber!.slice(4)))
                : max,
            0,
          ) + 1;
        if (!requestedNumber && next > 999999)
          throw new BadRequestException("Member number range exhausted.");
        const memberNumber =
          requestedNumber ?? `MBR-${String(next).padStart(6, "0")}`;
        if (numbers.some((item) => item.memberNumber === memberNumber)) {
          throw new ConflictException(
            "This member number is already used in the group.",
          );
        }
        const createdMember = await tx.groupMember.create({
          data: {
            groupId,
            memberNumber,
            fullName,
            phone,
            email,
            role,
            status: GroupMemberStatus.INVITED,
          },
        });
        const createdInvitation = await tx.groupInvitation.create({
          data: {
            groupId,
            groupMemberId: createdMember.id,
            tokenHash: this.hash(token),
            role,
            expiresAt: this.daysFromNow(14),
          },
        });
        return {
          member: createdMember,
          invitation: createdInvitation,
          token,
        };
      },
    );

    let deliveries: InvitationDeliveryResult[];
    try {
      deliveries = await this.deliverMemberInvitation({
        groupName: group.name,
        groupCode: group.slug,
        groupType: group.type,
        currency: group.currency,
        memberName: member.fullName,
        memberRole: role,
        inviterName: inviter.fullName,
        inviterRole: inviter.role,
        phone,
        email,
        invitationCode: token,
        expiresAt: invitation.expiresAt,
      });
    } catch (error) {
      await this.cleanupUndeliveredInvitedMember(member.id);
      throw error;
    }

    await this.prisma.auditLog.create({
      data: {
        actorUserId: user.id,
        groupId,
        action: AuditAction.MEMBER_CREATED,
        entityType: "GroupMember",
        entityId: member.id,
        newValue: {
          role: member.role,
          status: member.status,
          invitationId: invitation.id,
          deliveredChannels: deliveries.map((delivery) => delivery.channel),
        },
      },
    });

    return {
      ...member,
      invitationCode: token,
      invitationExpiresAt: invitation.expiresAt,
      inviteDeliveries: deliveries,
    };
  }

  async inviteMembers(
    user: AuthenticatedUser,
    groupId: string,
    input: InviteMembersDto,
  ) {
    await this.requireMembership(user, groupId, [GroupRole.GROUP_ADMIN]);
    const invitations = await Promise.all(
      input.recipients.map(async (recipient) => {
        const token = await this.uniqueInvitationCode(this.prisma);
        const invitation = await this.prisma.groupInvitation.create({
          data: {
            groupId,
            tokenHash: this.hash(token),
            role: input.role ?? GroupRole.MEMBER,
            expiresAt: this.daysFromNow(14),
          },
        });
        return {
          id: invitation.id,
          recipient,
          role: invitation.role,
          invitationCode: token,
          expiresAt: invitation.expiresAt,
        };
      }),
    );
    return { groupId, invitations };
  }

  async member(user: AuthenticatedUser, groupId: string, memberId: string) {
    await this.requireMembership(user, groupId);
    const member = await this.prisma.groupMember.findFirst({
      where: { id: memberId, groupId },
      include: {
        user: { select: { displayName: true, profilePictureObjectKey: true } },
        obligations: true,
        payments: { orderBy: { createdAt: "desc" } },
      },
    });
    if (!member) throw new NotFoundException("Member not found.");
    return {
      ...member,
      fullName: member.user?.displayName ?? member.fullName,
      profilePictureUrl: this.imageUrl(
        member.user?.profilePictureObjectKey ?? null,
      ),
    };
  }

  async assignRole(
    user: AuthenticatedUser,
    groupId: string,
    memberId: string,
    input: AssignRoleDto,
  ) {
    await this.requireMembership(user, groupId, [GroupRole.GROUP_ADMIN]);
    return this.prisma.$transaction(async (tx) => {
      const member = await tx.groupMember.findFirst({
        where: { id: memberId, groupId },
      });
      if (!member) throw new NotFoundException("Member not found.");

      if (
        member.role === GroupRole.GROUP_ADMIN &&
        input.role !== GroupRole.GROUP_ADMIN
      ) {
        const otherActiveAdmins = await tx.groupMember.count({
          where: {
            groupId,
            id: { not: memberId },
            role: GroupRole.GROUP_ADMIN,
            status: GroupMemberStatus.ACTIVE,
          },
        });
        if (otherActiveAdmins === 0) {
          throw new BadRequestException(
            "Add another group admin before changing this admin role.",
          );
        }
      }

      return tx.groupMember.update({
        where: { id: memberId, groupId },
        data: { role: input.role },
      });
    });
  }

  async updateMemberStatus(
    user: AuthenticatedUser,
    groupId: string,
    memberId: string,
    input: UpdateMemberStatusDto,
  ) {
    await this.requireMembership(user, groupId, [GroupRole.GROUP_ADMIN]);
    return this.prisma.$transaction(
      async (tx) => {
        const actor = await tx.groupMember.findFirst({
          where: {
            userId: user.id,
            groupId,
            role: GroupRole.GROUP_ADMIN,
            status: GroupMemberStatus.ACTIVE,
          },
        });
        if (!actor)
          throw new ForbiddenException(
            "Only an active group admin can manage member access.",
          );
        const member = await tx.groupMember.findFirst({
          where: { id: memberId, groupId },
          include: { group: true },
        });
        if (!member) throw new NotFoundException("Member not found.");
        if (
          member.userId === user.id ||
          member.role === GroupRole.GROUP_ADMIN ||
          (member.userId && member.userId === member.group.billingOwnerUserId)
        ) {
          throw new ForbiddenException(
            "Administrator and owner memberships cannot be suspended or removed.",
          );
        }
        if (
          input.status === "ACTIVE" &&
          (!member.userId || member.status === GroupMemberStatus.INVITED)
        ) {
          throw new BadRequestException(
            "An invited member must accept an invitation before gaining access.",
          );
        }
        if (member.status === input.status) return member;
        const updated = await tx.groupMember.update({
          where: { id: memberId, groupId },
          data: {
            status: input.status,
            deactivatedAt: input.status === "ACTIVE" ? null : new Date(),
          },
        });
        if (input.status !== "ACTIVE") {
          await tx.groupInvitation.updateMany({
            where: { groupId, groupMemberId: memberId, acceptedAt: null },
            data: { expiresAt: new Date() },
          });
        }
        await tx.auditLog.create({
          data: {
            actorUserId: user.id,
            groupId,
            action:
              input.status === "ACTIVE"
                ? AuditAction.GROUP_UPDATED
                : AuditAction.MEMBER_DEACTIVATED,
            entityType: "GroupMember",
            entityId: memberId,
            previousValue: { status: member.status },
            newValue: { status: input.status },
          },
        });
        return updated;
      },
      { isolationLevel: "Serializable" },
    );
  }

  async contributionRegister(user: AuthenticatedUser, groupId: string) {
    const membership = await this.requireMembership(user, groupId);
    await this.generateContributionSchedule(groupId);
    const rolesAllowedToSeeAllObligations: GroupRole[] = [
      GroupRole.GROUP_ADMIN,
      GroupRole.TREASURER,
      GroupRole.SECRETARY,
    ];
    const canSeeAllObligations = rolesAllowedToSeeAllObligations.includes(
      membership.role,
    );
    const obligations = await this.prisma.memberContributionObligation.findMany({
      where: {
        member: {
          groupId,
          ...(canSeeAllObligations ? {} : { id: membership.id }),
        },
      },
      include: {
        member: true,
        plan: true,
        period: true,
        allocations: {
          where: {
            status: PaymentAllocationStatus.PENDING,
            payment: {
              status: {
                in: [
                  GroupContributionPaymentStatus.PENDING_VERIFICATION,
                  GroupContributionPaymentStatus.SUBMITTED,
                ],
              },
            },
          },
          select: { amountMinor: true },
        },
      },
      orderBy: [{ dueAt: "asc" }],
    });
    return {
      groupId,
      obligations: obligations.map((obligation) => ({
        ...obligation,
        pendingAllocationMinor: obligation.allocations.reduce(
          (total, allocation) => total + allocation.amountMinor,
          0,
        ),
      })),
    };
  }

  async contributionPayments(user: AuthenticatedUser, groupId: string) {
    const membership = await this.requireMembership(user, groupId);
    const canReviewPayments = this.canReviewContributionPayments(
      membership.role,
    );

    return {
      payments: await this.prisma.groupContributionPayment.findMany({
        where: {
          groupId,
          ...(canReviewPayments ? {} : { groupMemberId: membership.id }),
        },
        include: { member: true, receipt: true },
        orderBy: { createdAt: "desc" },
      }),
    };
  }

  async submitPaymentRequest(
    user: AuthenticatedUser,
    groupId: string,
    input: SubmitContributionPaymentRequestDto,
  ) {
    const membership = await this.requireMembership(user, groupId);
    return this.prisma.$transaction(
      async (tx) => {
        const paidAt = input.paidAt ? new Date(input.paidAt) : new Date();
        const payment = await tx.groupContributionPayment.create({
          data: {
            groupId,
            groupMemberId: membership.id,
            createdByUserId: user.id,
            amountMinor: input.amountMinor,
            method: input.method,
            reference: input.reference,
            paidAt,
            status: GroupContributionPaymentStatus.PENDING_VERIFICATION,
            submittedAt: new Date(),
          },
        });
        await tx.auditLog.create({
          data: {
            actorUserId: user.id,
            groupId,
            action: AuditAction.GROUP_CONTRIBUTION_PAYMENT_SUBMITTED,
            entityType: "GroupContributionPayment",
            entityId: payment.id,
            newValue: {
              amountMinor: payment.amountMinor,
              method: payment.method,
              status: payment.status,
            },
          },
        });
        await this.allocatePaymentToObligations(
          groupId,
          payment.id,
          membership.id,
          input.amountMinor,
          input.obligationIds,
          false,
          tx,
        );
        const reviewers = await tx.groupMember.findMany({
          where: {
            groupId,
            status: GroupMemberStatus.ACTIVE,
            role: {
              in: [
                GroupRole.GROUP_ADMIN,
                GroupRole.TREASURER,
                GroupRole.SECRETARY,
              ],
            },
            id: { not: membership.id },
            userId: { not: null },
          },
          select: { userId: true },
        });
        for (const reviewer of reviewers) {
          await this.createUserNotification(tx, {
            userId: reviewer.userId,
            titleEn: "Payment awaiting review",
            titleSw: "Malipo yanasubiri ukaguzi",
            bodyEn: `${membership.fullName} submitted a payment of ${payment.currency} ${payment.amountMinor}.`,
            bodySw: `${membership.fullName} amewasilisha malipo ya ${payment.currency} ${payment.amountMinor}.`,
          });
        }
        return tx.groupContributionPayment.findUniqueOrThrow({
          where: { id: payment.id },
          include: { receipt: true, member: true },
        });
      },
      { isolationLevel: "Serializable" },
    );
  }

  async recordPayment(
    user: AuthenticatedUser,
    groupId: string,
    input: RecordContributionPaymentDto,
  ) {
    const reviewer = await this.requireMembership(user, groupId, [
      GroupRole.GROUP_ADMIN,
      GroupRole.TREASURER,
      GroupRole.SECRETARY,
    ]);
    if (reviewer.id === input.memberId)
      throw new ForbiddenException(
        "Submit your own payment request for another reviewer to verify.",
      );
    const member = await this.ensureGroupMember(groupId, input.memberId);
    this.ensureContributionPaymentReviewer(reviewer.role, member);
    return this.prisma.$transaction(
      async (tx) => {
        const paidAt = input.paidAt ? new Date(input.paidAt) : new Date();
        const payment = await tx.groupContributionPayment.create({
          data: {
            groupId,
            groupMemberId: input.memberId,
            createdByUserId: user.id,
            reviewedByUserId: user.id,
            amountMinor: input.amountMinor,
            method: input.method,
            reference: input.reference,
            paidAt,
            status: GroupContributionPaymentStatus.APPROVED,
            submittedAt: paidAt,
            reviewedAt: new Date(),
          },
        });
        await this.allocatePaymentToObligations(
          groupId,
          payment.id,
          input.memberId,
          input.amountMinor,
          input.obligationIds,
          true,
          tx,
        );
        await this.createReceiptForPayment(groupId, payment.id, tx);
        await this.createUserNotification(tx, {
          userId: member.userId,
          titleEn: "Payment recorded",
          titleSw: "Malipo yamerekodiwa",
          bodyEn: `Your payment of ${payment.currency} ${payment.amountMinor} has been recorded and approved.`,
          bodySw: `Malipo yako ya ${payment.currency} ${payment.amountMinor} yamerekodiwa na kuidhinishwa.`,
        });
        return tx.groupContributionPayment.findUniqueOrThrow({
          where: { id: payment.id },
          include: { receipt: true, member: true },
        });
      },
      { isolationLevel: "Serializable" },
    );
  }

  async importHistoricalPayments(
    user: AuthenticatedUser,
    groupId: string,
    input: ImportHistoricalContributionPaymentsDto,
  ) {
    return this.createHistoricalPayments(user, groupId, input.payments);
  }

  async importHistoricalPayment(
    user: AuthenticatedUser,
    groupId: string,
    input: HistoricalContributionPaymentDto,
  ) {
    const result = await this.createHistoricalPayments(user, groupId, [input]);
    return {
      imported: result.imported,
      paymentId: result.paymentIds[0],
    };
  }

  private async createHistoricalPayments(
    user: AuthenticatedUser,
    groupId: string,
    payments: HistoricalContributionPaymentDto[],
  ) {
    await this.requireMembership(user, groupId, [
      GroupRole.GROUP_ADMIN,
      GroupRole.SECRETARY,
    ]);
    const group = await this.prisma.group.findUniqueOrThrow({
      where: { id: groupId },
      select: { establishedAt: true, historicalDataStartsAt: true },
    });
    const requestedPlanKeys = Array.from(
      new Set(
        payments.map(
          (payment) =>
            payment.contributionType ?? ContributionPlanType.RECURRING,
        ),
      ),
    );
    const plans = await this.prisma.contributionPlan.findMany({
      where: {
        groupId,
        isActive: true,
        OR: [
          { type: ContributionPlanType.JOINING_FEE },
          { name: "Membership fee" },
          { name: { startsWith: "Member contribution" } },
        ],
      },
      orderBy: { createdAt: "asc" },
      select: { id: true, type: true, name: true },
    });
    const planByKey = new Map<string, { id: string }>();
    for (const plan of plans) {
      if (plan.type === ContributionPlanType.JOINING_FEE) {
        planByKey.set("JOINING_FEE", plan);
      } else if (plan.name === "Membership fee") {
        planByKey.set("MEMBERSHIP_FEE", plan);
      } else if (
        plan.name.startsWith("Member contribution") &&
        !planByKey.has("RECURRING")
      ) {
        planByKey.set("RECURRING", plan);
      }
    }
    for (const key of requestedPlanKeys) {
      if (!planByKey.has(key)) {
        throw new BadRequestException(
          "Contribution plan for historical type is not configured.",
        );
      }
    }
    const now = new Date();
    await Promise.all(
      payments.map((payment) =>
        this.ensureGroupMember(groupId, payment.memberId),
      ),
    );
    payments.forEach((payment) => {
      const paidAt = new Date(payment.paidAt);
      if (paidAt > now) {
        throw new BadRequestException(
          "Historical payment dates cannot be future dates.",
        );
      }
      const earliestHistoricalDate =
        group.historicalDataStartsAt ?? group.establishedAt;
      if (earliestHistoricalDate && paidAt < earliestHistoricalDate) {
        throw new BadRequestException(
          "Historical payment dates cannot be before the group historical start date.",
        );
      }
    });

    const created = await this.prisma.$transaction(async (tx) => {
      const createdPayments: { id: string }[] = [];
      for (const payment of payments) {
        const paidAt = new Date(payment.paidAt);
        const planKey = payment.contributionType ?? "RECURRING";
        const plan = planByKey.get(planKey)!;
        const createdPayment = await tx.groupContributionPayment.create({
          data: {
            groupId,
            groupMemberId: payment.memberId,
            createdByUserId: user.id,
            reviewedByUserId: user.id,
            amountMinor: payment.amountMinor,
            method: payment.method,
            reference: payment.reference,
            paidAt,
            status: GroupContributionPaymentStatus.APPROVED,
            submittedAt: paidAt,
            reviewedAt: new Date(),
          },
        });
        await tx.paymentAllocation.create({
          data: {
            paymentId: createdPayment.id,
            planId: plan.id,
            amountMinor: payment.amountMinor,
            status: PaymentAllocationStatus.APPLIED,
          },
        });
        createdPayments.push(createdPayment);
      }
      return createdPayments;
    });

    await Promise.all(
      created.map((payment) =>
        this.createReceiptForPayment(groupId, payment.id),
      ),
    );
    await this.prisma.auditLog.create({
      data: {
        actorUserId: user.id,
        groupId,
        action: AuditAction.GROUP_CONTRIBUTION_PAYMENT_APPROVED,
        entityType: "HistoricalContributionPaymentImport",
        entityId: groupId,
        newValue: {
          count: created.length,
          paymentIds: created.map((payment) => payment.id),
        },
      },
    });

    return {
      imported: created.length,
      paymentIds: created.map((item) => item.id),
    };
  }

  async approvePayment(
    user: AuthenticatedUser,
    groupId: string,
    paymentId: string,
    input: ReviewContributionPaymentDto,
  ) {
    const membership = await this.requireMembership(user, groupId, [
      GroupRole.GROUP_ADMIN,
      GroupRole.TREASURER,
      GroupRole.SECRETARY,
    ]);
    return this.prisma.$transaction(
      async (tx) => {
        const payment = await tx.groupContributionPayment.findFirstOrThrow({
          where: { id: paymentId, groupId },
          include: { member: true },
        });
        this.ensureContributionPaymentReviewer(membership.role, payment.member);
        const paymentStatusesAllowedForApproval: GroupContributionPaymentStatus[] =
          [
            GroupContributionPaymentStatus.SUBMITTED,
            GroupContributionPaymentStatus.PENDING_VERIFICATION,
            GroupContributionPaymentStatus.CORRECTION_REQUESTED,
          ];
        if (!paymentStatusesAllowedForApproval.includes(payment.status)) {
          throw new ForbiddenException(
            "Payment cannot be approved from this state.",
          );
        }

        await tx.groupContributionPayment.update({
          where: { id: payment.id },
          data: {
            reviewedByUserId: user.id,
            reviewedAt: new Date(),
            status: GroupContributionPaymentStatus.APPROVED,
            correctionMessage: null,
          },
        });
        await this.allocatePaymentToObligations(
          groupId,
          payment.id,
          payment.groupMemberId,
          payment.amountMinor,
          input.obligationIds,
          true,
          tx,
        );
        await this.createReceiptForPayment(groupId, payment.id, tx);
        const group = await tx.group.findUniqueOrThrow({
          where: { id: groupId },
          select: { name: true },
        });
        await this.createUserNotification(tx, {
          userId: payment.member.userId,
          titleEn: `Payment approved - ${group.name}`,
          titleSw: `Malipo yameidhinishwa - ${group.name}`,
          bodyEn: `Your ${group.name} payment of ${payment.currency} ${payment.amountMinor} has been approved.`,
          bodySw: `Malipo yako ya ${group.name} ya ${payment.currency} ${payment.amountMinor} yameidhinishwa.`,
        });
        await this.auditPaymentReview(
          user,
          groupId,
          payment.id,
          AuditAction.GROUP_CONTRIBUTION_PAYMENT_APPROVED,
          input.reason,
          tx,
        );
        return tx.groupContributionPayment.findUniqueOrThrow({
          where: { id: payment.id },
          include: { receipt: true, member: true },
        });
      },
      { isolationLevel: "Serializable" },
    );
  }

  async rejectPayment(
    user: AuthenticatedUser,
    groupId: string,
    paymentId: string,
    input: ReviewContributionPaymentDto,
  ) {
    const membership = await this.requireMembership(user, groupId, [
      GroupRole.GROUP_ADMIN,
      GroupRole.TREASURER,
      GroupRole.SECRETARY,
    ]);
    return this.prisma.$transaction(async (tx) => {
      const payment = await tx.groupContributionPayment.findFirstOrThrow({
        where: { id: paymentId, groupId },
        include: { member: true },
      });
      this.ensureContributionPaymentReviewer(membership.role, payment.member);
      if (
        ![
          GroupContributionPaymentStatus.SUBMITTED,
          GroupContributionPaymentStatus.PENDING_VERIFICATION,
          GroupContributionPaymentStatus.CORRECTION_REQUESTED,
        ].some((status) => status === payment.status)
      ) {
        throw new ConflictException("Only pending payments can be rejected.");
      }
      const updated = await tx.groupContributionPayment.update({
        where: { id: payment.id, status: payment.status },
        data: {
          reviewedByUserId: user.id,
          reviewedAt: new Date(),
          status: GroupContributionPaymentStatus.REJECTED,
          reversalReason: input.reason,
        },
      });
      const group = await tx.group.findUniqueOrThrow({
        where: { id: groupId },
        select: { name: true },
      });
      await this.createUserNotification(tx, {
        userId: payment.member.userId,
        titleEn: `Payment rejected - ${group.name}`,
        titleSw: `Malipo yamekataliwa - ${group.name}`,
        bodyEn:
          `Your ${group.name} payment of ${payment.currency} ${payment.amountMinor} was rejected. ${input.reason ?? ""}`.trim(),
        bodySw:
          `Malipo yako ya ${group.name} ya ${payment.currency} ${payment.amountMinor} yamekataliwa. ${input.reason ?? ""}`.trim(),
      });
      await this.auditPaymentReview(
        user,
        groupId,
        payment.id,
        AuditAction.GROUP_CONTRIBUTION_PAYMENT_REJECTED,
        input.reason,
        tx,
      );
      return updated;
    });
  }

  async requestPaymentCorrection(
    user: AuthenticatedUser,
    groupId: string,
    paymentId: string,
    input: ReviewContributionPaymentDto,
  ) {
    const membership = await this.requireMembership(user, groupId, [
      GroupRole.GROUP_ADMIN,
      GroupRole.TREASURER,
      GroupRole.SECRETARY,
    ]);
    const payment = await this.prisma.groupContributionPayment.findFirstOrThrow(
      {
        where: { id: paymentId, groupId },
        include: { member: true },
      },
    );
    this.ensureContributionPaymentReviewer(membership.role, payment.member);
    if (
      ![
        GroupContributionPaymentStatus.SUBMITTED,
        GroupContributionPaymentStatus.PENDING_VERIFICATION,
      ].some((status) => status === payment.status)
    ) {
      throw new ConflictException("Only pending payments can be corrected.");
    }
    const updated = await this.prisma.$transaction(async (tx) => {
      const reviewed = await tx.groupContributionPayment.update({
        where: { id: payment.id, status: payment.status },
        data: {
          reviewedByUserId: user.id,
          reviewedAt: new Date(),
          status: GroupContributionPaymentStatus.CORRECTION_REQUESTED,
          correctionMessage: input.reason,
        },
      });
      const group = await tx.group.findUniqueOrThrow({
        where: { id: groupId },
        select: { name: true },
      });
      await this.createUserNotification(tx, {
        userId: payment.member.userId,
        titleEn: `Payment needs correction - ${group.name}`,
        titleSw: `Malipo yanahitaji marekebisho - ${group.name}`,
        bodyEn:
          `Your ${group.name} payment of ${payment.currency} ${payment.amountMinor} needs correction. ${input.reason ?? ""}`.trim(),
        bodySw:
          `Malipo yako ya ${group.name} ya ${payment.currency} ${payment.amountMinor} yanahitaji marekebisho. ${input.reason ?? ""}`.trim(),
      });
      await this.auditPaymentReview(
        user,
        groupId,
        payment.id,
        AuditAction.GROUP_CONTRIBUTION_PAYMENT_CORRECTION_REQUESTED,
        input.reason,
        tx,
      );
      return reviewed;
    });
    return updated;
  }

  async receipt(user: AuthenticatedUser, groupId: string, receiptId: string) {
    const membership = await this.requireMembership(user, groupId);
    const receipt = await this.prisma.receipt.findFirst({
      where: {
        id: receiptId,
        groupId,
        ...(membership.role === GroupRole.MEMBER
          ? { payment: { groupMemberId: membership.id } }
          : {}),
      },
      include: { payment: { include: { member: true } } },
    });
    if (!receipt) throw new NotFoundException("Receipt not found.");
    return receipt;
  }

  async reminderTemplates(user: AuthenticatedUser, groupId: string) {
    await this.requireMembership(user, groupId);
    return {
      templates: await this.prisma.reminderTemplate.findMany({
        where: { groupId },
      }),
    };
  }

  async reminderPackages(user: AuthenticatedUser, groupId: string) {
    await this.requireMembership(user, groupId);
    await this.syncPendingReminderPackagePurchases(groupId);
    const creditTotals = await this.prisma.reminderPackagePurchase.aggregate({
      where: {
        groupId,
        status: ReminderPackagePurchaseStatus.PAID,
      },
      _sum: {
        quantity: true,
        usedQuantity: true,
      },
      _count: true,
    });
    const purchased = creditTotals._sum.quantity ?? 0;
    const used = creditTotals._sum.usedQuantity ?? 0;
    return {
      packages: await this.prisma.platformPrice.findMany({
        where: { isActive: true },
        orderBy: [{ channel: "asc" }, { amountMinor: "asc" }],
      }),
      credits: {
        purchases: creditTotals._count,
        purchased,
        used,
        remaining: Math.max(purchased - used, 0),
      },
    };
  }

  private async syncPendingReminderPackagePurchases(groupId: string) {
    const pendingPurchases = await this.prisma.reminderPackagePurchase.findMany({
      where: {
        groupId,
        status: ReminderPackagePurchaseStatus.PENDING,
        providerCheckoutId: { not: null },
      },
      take: 20,
      orderBy: { createdAt: "desc" },
    });

    await Promise.all(
      pendingPurchases.map(async (purchase) => {
        if (!purchase.providerCheckoutId) return;
        try {
          const providerOrder = await this.billingProvider.getSubscription(
            purchase.providerCheckoutId,
          );
          const nextStatus = this.reminderPurchaseStatusFromProviderStatus(
            providerOrder.status,
          );
          if (!nextStatus) return;
          await this.prisma.reminderPackagePurchase.update({
            where: { id: purchase.id },
            data: {
              status: nextStatus,
              ...(nextStatus === ReminderPackagePurchaseStatus.PAID
                ? { paidAt: new Date() }
                : {}),
            },
          });
        } catch {
          // Keep the purchase pending if the provider is temporarily unavailable.
        }
      }),
    );
  }

  private reminderPurchaseStatusFromProviderStatus(
    status: string,
  ): ReminderPackagePurchaseStatus | null {
    switch (status) {
      case "active":
        return ReminderPackagePurchaseStatus.PAID;
      case "cancelled":
        return ReminderPackagePurchaseStatus.CANCELLED;
      case "expired":
      case "past_due":
        return ReminderPackagePurchaseStatus.FAILED;
      default:
        return null;
    }
  }

  async createReminderPackageCheckout(
    user: AuthenticatedUser,
    groupId: string,
    input: CreateReminderPackageCheckoutDto,
  ) {
    await this.requireMembership(user, groupId, [
      GroupRole.GROUP_ADMIN,
      GroupRole.TREASURER,
    ]);

    const [group, reminderPackage, identity] = await Promise.all([
      this.prisma.group.findUniqueOrThrow({ where: { id: groupId } }),
      this.prisma.platformPrice.findUnique({
        where: { code: input.packageCode.trim().toLowerCase() },
      }),
      this.primaryIdentity(user.id),
    ]);

    if (!reminderPackage?.isActive) {
      throw new NotFoundException("Reminder package was not found.");
    }
    const buyerPhone = input.buyerPhone ?? identity.phone;
    if (!buyerPhone?.trim()) {
      throw new BadRequestException(
        "Enter a phone number to receive the Sayari Pay USSD prompt.",
      );
    }
    const quantity = reminderPackage.quantity;
    const amountMinor = reminderPackage.amountMinor * quantity;
    const customer = await this.billingProvider.createCustomer({
      groupId,
      name: group.name,
      email: input.buyerEmail ?? identity.email,
      phone: buyerPhone,
    });
    const checkout = await this.billingProvider.createCheckoutSession({
      groupId,
      planCode: reminderPackage.code,
      productType: "reminder-package",
      productName: reminderPackage.name,
      providerCustomerId: customer.providerCustomerId,
      amountMinor,
      currency: reminderPackage.currency,
      interval: BillingInterval.MONTH,
      intervalCount: 1,
      trialDays: 0,
      metadata: {
        packageId: reminderPackage.id,
        channel: reminderPackage.channel,
        quantity,
      },
      successUrl: input.successUrl,
      cancelUrl: input.cancelUrl,
      buyerEmail: input.buyerEmail ?? identity.email,
      buyerName: input.buyerName ?? group.name,
      buyerPhone,
    });
    const purchase = await this.prisma.reminderPackagePurchase.create({
      data: {
        groupId,
        platformPriceId: reminderPackage.id,
        createdByUserId: user.id,
        provider: this.billingProvider.provider,
        providerCheckoutId: checkout.providerSessionId,
        quantity,
        amountMinor,
        currency: reminderPackage.currency,
        checkoutUrl: checkout.checkoutUrl,
        expiresAt: checkout.expiresAt,
      },
    });
    await this.prisma.auditLog.create({
      data: {
        actorUserId: user.id,
        groupId,
        action: AuditAction.PLATFORM_PACKAGE_PURCHASE_CREATED,
        entityType: "ReminderPackagePurchase",
        entityId: purchase.id,
        newValue: {
          packageCode: reminderPackage.code,
          channel: reminderPackage.channel,
          quantity,
          amountMinor,
          currency: reminderPackage.currency,
        },
      },
    });

    return {
      purchaseId: purchase.id,
      checkoutUrl: checkout.checkoutUrl,
      expiresAt: checkout.expiresAt,
      amountMinor,
      currency: reminderPackage.currency,
      quantity,
      walletPaymentStarted: checkout.walletPaymentStarted ?? false,
    };
  }

  async reminderCampaigns(user: AuthenticatedUser, groupId: string) {
    await this.requireMembership(user, groupId);
    return {
      campaigns: await this.prisma.reminderCampaign.findMany({
        where: { groupId },
        orderBy: { createdAt: "desc" },
      }),
    };
  }

  async sendReminder(
    user: AuthenticatedUser,
    groupId: string,
    input: SendReminderDto,
  ) {
    await this.requireMembership(user, groupId, [
      GroupRole.GROUP_ADMIN,
      GroupRole.TREASURER,
      GroupRole.SECRETARY,
    ]);

    if (input.channel !== "SMS")
      throw new BadRequestException(
        "WhatsApp reminders are not available yet. Select SMS.",
      );
    const selectedMemberIds =
      input.memberIds?.map((id) => id.trim()).filter(Boolean) ?? [];
    const members =
      selectedMemberIds.length > 0
        ? await this.prisma.groupMember.findMany({
            where: {
              groupId,
              id: { in: selectedMemberIds },
              status: GroupMemberStatus.ACTIVE,
            },
            select: { id: true, userId: true, fullName: true, phone: true },
          })
        : await this.membersWithOutstandingObligations(groupId);

    if (members.length === 0) {
      throw new BadRequestException(
        "No eligible members were found for this reminder.",
      );
    }
    if (
      selectedMemberIds.length &&
      members.length !== new Set(selectedMemberIds).size
    ) {
      throw new BadRequestException("Select active members from this group.");
    }

    const notificationRecipients = members
      .map((member) => member.userId)
      .filter((userId): userId is string => Boolean(userId));
    const shouldSendSms = input.channel === "SMS" || input.channel === "BOTH";
    const smsRecipients = shouldSendSms
      ? members
          .map((member) => member.phone?.trim())
          .filter((phone): phone is string => Boolean(phone))
      : [];
    if (shouldSendSms && smsRecipients.length === 0) {
      throw new BadRequestException(
        "No phone numbers were found for the selected SMS reminder recipients.",
      );
    }
    const dispatchId = randomBytes(16).toString("hex");
    // Sequential reservations avoid contention on the group's shared credit packages.
    const smsResults: PromiseSettledResult<boolean>[] = [];
    for (const phone of new Set(smsRecipients)) {
      try {
        const sent = await this.reminderDispatch.send(
          groupId,
          `manual:${dispatchId}:${this.hash(phone)}`,
          phone,
          `Vikoplus: ${input.message}`,
        );
        smsResults.push({ status: "fulfilled", value: sent });
      } catch (error) {
        smsResults.push({ status: "rejected", reason: error });
      }
    }
    const smsSent = smsResults.filter(
      (result) => result.status === "fulfilled" && result.value,
    ).length;
    const smsFailed = smsResults.length - smsSent;
    if (shouldSendSms && smsSent === 0) {
      const creditFailure = smsResults.find(
        (result) =>
          result.status === "rejected" &&
          result.reason instanceof BadRequestException,
      );
      if (creditFailure?.status === "rejected") throw creditFailure.reason;
      throw new BadGatewayException("Briq SMS reminder delivery failed.");
    }

    const campaign = await this.prisma.reminderCampaign.create({
      data: {
        groupId,
        title: "Outstanding dues reminder",
        channel: input.channel,
        body: input.message,
        recipientCount: members.length,
        createdByUserId: user.id,
        sentAt: new Date(),
      },
    });

    if (notificationRecipients.length > 0) {
      const recipients = await this.prisma.user.findMany({
        where: { id: { in: notificationRecipients } },
        select: { id: true, preferredLocale: true },
      });
      await this.prisma.notification.createMany({
        data: recipients.map((recipient) => ({
          userId: recipient.id,
          title:
            recipient.preferredLocale === Locale.sw
              ? "Kumbusho la malipo"
              : "Payment reminder",
          body: input.message,
          locale: recipient.preferredLocale,
        })),
      });
    }

    await this.prisma.auditLog.create({
      data: {
        actorUserId: user.id,
        groupId,
        action: AuditAction.REMINDER_SENT,
        entityType: "ReminderCampaign",
        entityId: campaign.id,
        newValue: {
          channel: input.channel,
          recipientCount: members.length,
          appNotificationsCreated: notificationRecipients.length,
          smsRecipients: smsRecipients.length,
          smsSent,
          smsFailed,
          whatsappPending: 0,
        },
      },
    });

    return {
      campaignId: campaign.id,
      channel: campaign.channel,
      recipientCount: members.length,
      appNotificationsCreated: notificationRecipients.length,
      smsSent,
      smsFailed,
      whatsappPending: 0,
      sentAt: campaign.sentAt,
    };
  }

  async loansOverview(user: AuthenticatedUser, groupId: string) {
    const membership = await this.requireMembership(user, groupId);
    return this.loanOverviewForMember(membership, groupId);
  }

  private async loanOverviewForMember(
    membership: GroupMember,
    groupId: string,
    db: Prisma.TransactionClient = this.prisma,
  ) {
    const [group, savings, obligations, activeLoans, applications] =
      await Promise.all([
        db.group.findUniqueOrThrow({
          where: { id: groupId },
          select: { currency: true },
        }),
        db.paymentAllocation.aggregate({
          where: {
            payment: {
              groupId,
              groupMemberId: membership.id,
              status: GroupContributionPaymentStatus.APPROVED,
            },
            plan: {
              name: { startsWith: "Member contribution" },
              type: ContributionPlanType.RECURRING,
            },
            status: PaymentAllocationStatus.APPLIED,
          },
          _sum: { amountMinor: true },
        }),
        db.memberContributionObligation.aggregate({
          where: {
            groupMemberId: membership.id,
            dueAt: { lte: new Date() },
            status: {
              in: [
                ContributionObligationStatus.UPCOMING,
                ContributionObligationStatus.DUE,
                ContributionObligationStatus.PARTIALLY_PAID,
                ContributionObligationStatus.OVERDUE,
              ],
            },
          },
          _sum: { amountDueMinor: true, amountPaidMinor: true },
          _count: true,
        }),
        db.groupLoan.findMany({
          where: {
            groupId,
            groupMemberId: membership.id,
            status: GroupLoanStatus.ACTIVE,
          },
          include: { repayments: { orderBy: { createdAt: "desc" } } },
          orderBy: { createdAt: "desc" },
        }),
        db.loanApplication.findMany({
          where: {
            groupId,
            groupMemberId: membership.id,
            status: { in: [LoanApplicationStatus.SUBMITTED] },
          },
          orderBy: { createdAt: "desc" },
        }),
      ]);
    const totalSavingsMinor = savings._sum.amountMinor ?? 0;
    const outstandingMinor = Math.max(
      (obligations._sum.amountDueMinor ?? 0) -
        (obligations._sum.amountPaidMinor ?? 0),
      0,
    );
    const activeLoanBalanceMinor = activeLoans.reduce(
      (total, loan) =>
        total + Math.max(loan.totalPayableMinor - loan.amountPaidMinor, 0),
      0,
    );
    const creditLimitMinor = totalSavingsMinor * 2;
    const borrowingPowerMinor = Math.max(
      creditLimitMinor -
        activeLoanBalanceMinor -
        applications.reduce((total, item) => total + item.amountMinor, 0),
      0,
    );

    return {
      groupId,
      currency: group.currency,
      totalSavingsMinor,
      outstandingMinor,
      activeDefaults: obligations._count,
      creditLimitMinor,
      borrowingPowerMinor,
      tierLabel: totalSavingsMinor >= 1000000 ? "Tier 2 Member" : "Starter",
      pendingApplicationsCount: applications.length,
      activeLoans: activeLoans.map((loan) => this.loanSummary(loan)),
      eligibility: [
        {
          label: "Active group membership",
          achieved: membership.status === GroupMemberStatus.ACTIVE,
        },
        {
          label: "No overdue contribution balance",
          achieved: outstandingMinor === 0,
        },
        {
          label: "Contribution savings available for borrowing limit",
          achieved: totalSavingsMinor > 0,
        },
      ],
    };
  }

  async createLoanApplication(
    user: AuthenticatedUser,
    groupId: string,
    input: CreateLoanApplicationDto,
  ) {
    const membership = await this.requireMembership(user, groupId);
    return this.prisma.$transaction(
      async (tx) => {
        const guarantorIds = [...new Set(input.guarantorMemberIds)];
        if (guarantorIds.length < 2) {
          throw new BadRequestException(
            "Select at least two different guarantors.",
          );
        }
        const overview = await this.loanOverviewForMember(
          membership,
          groupId,
          tx,
        );
        if (
          overview.outstandingMinor > 0 ||
          input.amountMinor > overview.borrowingPowerMinor
        ) {
          throw new BadRequestException(
            "Clear overdue contributions and apply within your available borrowing limit.",
          );
        }
        if (guarantorIds.includes(membership.id)) {
          throw new BadRequestException("You cannot guarantee your own loan.");
        }
        const guarantors = await tx.groupMember.findMany({
          where: {
            id: { in: guarantorIds },
            groupId,
            status: GroupMemberStatus.ACTIVE,
          },
          select: { id: true, userId: true },
        });
        if (guarantors.length !== guarantorIds.length) {
          throw new BadRequestException(
            "Select active guarantors from this group.",
          );
        }

        const application = await tx.loanApplication.create({
          data: {
            groupId,
            groupMemberId: membership.id,
            requestedByUserId: user.id,
            amountMinor: input.amountMinor,
            currency: overview.currency,
            purpose: input.purpose.trim(),
            termMonths: input.termMonths,
            processingFeeMinor: this.processingFee(input.amountMinor),
            guarantors: {
              create: guarantorIds.map((groupMemberId) => ({ groupMemberId })),
            },
          },
          include: { member: true, guarantors: { include: { member: true } } },
        });
        for (const guarantor of guarantors) {
          await this.createUserNotification(tx, {
            userId: guarantor.userId,
            titleEn: "Guarantee request",
            titleSw: "Ombi la udhamini",
            bodyEn: `${membership.fullName} asked you to guarantee a loan of ${overview.currency} ${input.amountMinor}.`,
            bodySw: `${membership.fullName} amekuomba udhamini wa mkopo wa ${overview.currency} ${input.amountMinor}.`,
          });
        }
        await tx.auditLog.create({
          data: {
            actorUserId: user.id,
            groupId,
            action: AuditAction.LOAN_APPLICATION_SUBMITTED,
            entityType: "LoanApplication",
            entityId: application.id,
            newValue: {
              amountMinor: application.amountMinor,
              purpose: application.purpose,
              termMonths: application.termMonths,
              guarantors: guarantorIds.length,
            },
          },
        });
        return this.loanApplicationSummary(application);
      },
      { isolationLevel: "Serializable" },
    );
  }

  async listLoanApplications(user: AuthenticatedUser, groupId: string) {
    const membership = await this.requireMembership(user, groupId);
    const applications = await this.prisma.loanApplication.findMany({
      where: {
        groupId,
        ...(this.canReviewLoans(membership.role)
          ? {}
          : { groupMemberId: membership.id }),
      },
      include: { member: true, guarantors: { include: { member: true } } },
      orderBy: { createdAt: "desc" },
    });
    return {
      groupId,
      applications: applications.map((item) =>
        this.loanApplicationSummary(item),
      ),
    };
  }

  async loanApplication(
    user: AuthenticatedUser,
    groupId: string,
    applicationId: string,
  ) {
    const membership = await this.requireMembership(user, groupId);
    const application = await this.prisma.loanApplication.findFirst({
      where: {
        id: applicationId,
        groupId,
        ...(this.canReviewLoans(membership.role)
          ? {}
          : { groupMemberId: membership.id }),
      },
      include: { member: true, guarantors: { include: { member: true } } },
    });
    if (!application)
      throw new NotFoundException("Loan application not found.");
    return {
      ...this.loanApplicationSummary(application),
      canReview:
        this.canReviewLoans(membership.role) &&
        application.groupMemberId !== membership.id &&
        application.status === LoanApplicationStatus.SUBMITTED,
    };
  }

  async approveLoanApplication(
    user: AuthenticatedUser,
    groupId: string,
    applicationId: string,
    input: ReviewLoanApplicationDto,
  ) {
    await this.requireMembership(user, groupId, [
      GroupRole.GROUP_ADMIN,
      GroupRole.TREASURER,
    ]);
    const application = await this.prisma.loanApplication.findFirst({
      where: { id: applicationId, groupId },
      include: { member: true, guarantors: { include: { member: true } } },
    });
    if (!application)
      throw new NotFoundException("Loan application not found.");
    if (
      application.requestedByUserId === user.id ||
      application.member.userId === user.id
    ) {
      throw new ForbiddenException(
        "Another treasurer must review your loan application.",
      );
    }
    if (application.member.status !== GroupMemberStatus.ACTIVE) {
      throw new BadRequestException(
        "The applicant must be an active group member.",
      );
    }
    if (
      application.guarantors.filter(
        (item) =>
          item.status === LoanGuarantorStatus.CONFIRMED &&
          item.member.status === GroupMemberStatus.ACTIVE,
      ).length < 2
    ) {
      throw new BadRequestException(
        "At least two active guarantors must confirm before approval.",
      );
    }
    if (application.status !== LoanApplicationStatus.SUBMITTED) {
      throw new BadRequestException(
        "Only submitted applications can be approved.",
      );
    }
    const amountMinor = input.approvedAmountMinor ?? application.amountMinor;
    if (amountMinor > application.amountMinor) {
      throw new BadRequestException(
        "Approved amount cannot exceed the requested amount.",
      );
    }
    const totalPayableMinor = this.loanTotalPayable(
      amountMinor,
      application.termMonths,
      application.monthlyInterestRateBps,
      this.processingFee(amountMinor),
    );
    const dueAt = this.addMonths(new Date(), application.termMonths);
    const updated = await this.prisma.$transaction(
      async (tx) => {
        const eligibility = await this.loanOverviewForMember(
          application.member,
          groupId,
          tx,
        );
        if (
          eligibility.outstandingMinor > 0 ||
          amountMinor >
            eligibility.borrowingPowerMinor + application.amountMinor
        ) {
          throw new BadRequestException(
            "Applicant no longer meets the borrowing requirements.",
          );
        }
        const claimed = await tx.loanApplication.updateMany({
          where: {
            id: application.id,
            status: LoanApplicationStatus.SUBMITTED,
          },
          data: {
            status: LoanApplicationStatus.DISBURSED,
            approvedAmountMinor: amountMinor,
            processingFeeMinor: this.processingFee(amountMinor),
            reviewedByUserId: user.id,
            reviewNotes: input.notes,
            approvedAt: new Date(),
          },
        });
        if (claimed.count !== 1)
          throw new ConflictException("Application has already been reviewed.");
        const savedApplication = await tx.loanApplication.findUniqueOrThrow({
          where: { id: application.id },
          include: { member: true, guarantors: { include: { member: true } } },
        });
        await tx.groupLoan.create({
          data: {
            applicationId: application.id,
            groupId,
            groupMemberId: application.groupMemberId,
            amountMinor,
            totalPayableMinor,
            currency: application.currency,
            purpose: application.purpose,
            termMonths: application.termMonths,
            monthlyInterestRateBps: application.monthlyInterestRateBps,
            dueAt,
          },
        });
        await tx.auditLog.create({
          data: {
            actorUserId: user.id,
            groupId,
            action: AuditAction.LOAN_APPLICATION_APPROVED,
            entityType: "LoanApplication",
            entityId: application.id,
            newValue: { amountMinor, totalPayableMinor, dueAt },
          },
        });
        await this.createUserNotification(tx, {
          userId: savedApplication.member.userId,
          titleEn: "Loan approved",
          titleSw: "Mkopo umeidhinishwa",
          bodyEn: `Your loan request for ${savedApplication.currency} ${amountMinor} has been approved and disbursed.`,
          bodySw: `Ombi lako la mkopo wa ${savedApplication.currency} ${amountMinor} limeidhinishwa na fedha zimetolewa.`,
        });
        return savedApplication;
      },
      { isolationLevel: "Serializable" },
    );
    return this.loanApplicationSummary(updated);
  }

  async rejectLoanApplication(
    user: AuthenticatedUser,
    groupId: string,
    applicationId: string,
    input: ReviewLoanApplicationDto,
  ) {
    await this.requireMembership(user, groupId, [
      GroupRole.GROUP_ADMIN,
      GroupRole.TREASURER,
    ]);
    const application = await this.prisma.loanApplication.findFirst({
      where: { id: applicationId, groupId },
      select: {
        id: true,
        status: true,
        requestedByUserId: true,
        amountMinor: true,
        currency: true,
        member: { select: { userId: true } },
      },
    });
    if (!application)
      throw new NotFoundException("Loan application not found.");
    if (application.requestedByUserId === user.id) {
      throw new ForbiddenException(
        "Another treasurer must review your loan application.",
      );
    }
    if (application.status !== LoanApplicationStatus.SUBMITTED) {
      throw new BadRequestException(
        "Only submitted applications can be rejected.",
      );
    }
    const updated = await this.prisma.loanApplication.update({
      where: { id: application.id, status: LoanApplicationStatus.SUBMITTED },
      data: {
        status: LoanApplicationStatus.REJECTED,
        reviewedByUserId: user.id,
        rejectionReason: input.reason ?? input.notes,
        rejectedAt: new Date(),
      },
      include: { member: true, guarantors: { include: { member: true } } },
    });
    await this.prisma.$transaction(async (tx) => {
      await this.createUserNotification(tx, {
        userId: updated.member.userId,
        titleEn: "Loan rejected",
        titleSw: "Mkopo umekataliwa",
        bodyEn:
          `Your loan request for ${updated.currency} ${updated.amountMinor} was rejected. ${input.reason ?? input.notes ?? ""}`.trim(),
        bodySw:
          `Ombi lako la mkopo wa ${updated.currency} ${updated.amountMinor} limekataliwa. ${input.reason ?? input.notes ?? ""}`.trim(),
      });
    });
    await this.prisma.auditLog.create({
      data: {
        actorUserId: user.id,
        groupId,
        action: AuditAction.LOAN_APPLICATION_REJECTED,
        entityType: "LoanApplication",
        entityId: application.id,
        reason: input.reason ?? input.notes,
      },
    });
    return this.loanApplicationSummary(updated);
  }

  async loanRepayment(
    user: AuthenticatedUser,
    groupId: string,
    loanId: string,
  ) {
    const membership = await this.requireMembership(user, groupId);
    const loan = await this.prisma.groupLoan.findFirst({
      where: {
        id: loanId,
        groupId,
        ...(this.canReviewLoans(membership.role)
          ? {}
          : { groupMemberId: membership.id }),
      },
      include: {
        member: true,
        repayments: { orderBy: { createdAt: "desc" } },
      },
    });
    if (!loan) throw new NotFoundException("Loan not found.");
    return this.loanRepaymentSummary(loan);
  }

  async recordLoanRepayment(
    user: AuthenticatedUser,
    groupId: string,
    loanId: string,
    input: RecordLoanRepaymentDto,
  ) {
    const membership = await this.requireMembership(user, groupId);
    return this.prisma.$transaction(
      async (tx) => {
        const loan = await tx.groupLoan.findFirst({
          where: { id: loanId, groupId, groupMemberId: membership.id },
        });
        if (!loan) throw new NotFoundException("Loan not found.");
        if (loan.status !== GroupLoanStatus.ACTIVE) {
          throw new BadRequestException(
            "Only active loans can receive repayments.",
          );
        }
        const pending = await tx.loanRepayment.aggregate({
          where: { loanId, status: LoanRepaymentStatus.SUBMITTED },
          _sum: { amountMinor: true },
        });
        const available =
          loan.totalPayableMinor -
          loan.amountPaidMinor -
          (pending._sum.amountMinor ?? 0);
        if (input.amountMinor > available) {
          throw new BadRequestException(
            "Amount exceeds the balance remaining after pending repayments.",
          );
        }
        const repayment = await tx.loanRepayment.create({
          data: {
            loanId,
            groupId,
            groupMemberId: loan.groupMemberId,
            createdByUserId: user.id,
            amountMinor: input.amountMinor,
            currency: loan.currency,
            method: input.method,
            reference: input.reference,
            paidAt: input.paidAt ? new Date(input.paidAt) : new Date(),
            status: LoanRepaymentStatus.SUBMITTED,
          },
        });
        await tx.auditLog.create({
          data: {
            actorUserId: user.id,
            groupId,
            action: AuditAction.LOAN_REPAYMENT_SUBMITTED,
            entityType: "LoanRepayment",
            entityId: repayment.id,
            newValue: { loanId, amountMinor: repayment.amountMinor },
          },
        });
        const reviewers = await tx.groupMember.findMany({
          where: {
            groupId,
            status: GroupMemberStatus.ACTIVE,
            role: { in: [GroupRole.GROUP_ADMIN, GroupRole.TREASURER] },
            id: { not: membership.id },
            userId: { not: null },
          },
          select: { userId: true },
        });
        for (const reviewer of reviewers) {
          await this.createUserNotification(tx, {
            userId: reviewer.userId,
            titleEn: "Loan repayment awaiting review",
            titleSw: "Marejesho ya mkopo yanasubiri ukaguzi",
            bodyEn: `${membership.fullName} submitted a loan repayment of ${repayment.currency} ${repayment.amountMinor}.`,
            bodySw: `${membership.fullName} amewasilisha marejesho ya mkopo ya ${repayment.currency} ${repayment.amountMinor}.`,
          });
        }
        return repayment;
      },
      { isolationLevel: "Serializable" },
    );
  }

  async loanTasks(user: AuthenticatedUser, groupId: string) {
    const membership = await this.requireMembership(user, groupId);
    const [guarantees, repayments] = await Promise.all([
      this.prisma.loanGuarantor.findMany({
        where: {
          groupMemberId: membership.id,
          status: LoanGuarantorStatus.PENDING,
          application: { groupId, status: LoanApplicationStatus.SUBMITTED },
        },
        select: {
          id: true,
          application: {
            select: {
              amountMinor: true,
              currency: true,
              purpose: true,
              member: { select: { fullName: true } },
            },
          },
        },
      }),
      this.canReviewLoans(membership.role)
        ? this.prisma.loanRepayment.findMany({
            where: {
              groupId,
              status: LoanRepaymentStatus.SUBMITTED,
              groupMemberId: { not: membership.id },
            },
            select: {
              id: true,
              amountMinor: true,
              currency: true,
              method: true,
              reference: true,
              member: { select: { fullName: true } },
            },
            orderBy: { createdAt: "asc" },
          })
        : Promise.resolve([]),
    ]);
    return { guarantees, repayments };
  }

  async respondToGuarantee(
    user: AuthenticatedUser,
    groupId: string,
    guaranteeId: string,
    accept: boolean,
  ) {
    const membership = await this.requireMembership(user, groupId);
    await this.prisma.$transaction(async (tx) => {
      const guarantee = await tx.loanGuarantor.findFirst({
        where: {
          id: guaranteeId,
          groupMemberId: membership.id,
          status: LoanGuarantorStatus.PENDING,
          application: { groupId, status: LoanApplicationStatus.SUBMITTED },
        },
        include: { application: { include: { member: true } } },
      });
      if (!guarantee)
        throw new ConflictException(
          "Guarantee request is unavailable or already answered.",
        );
      await tx.loanGuarantor.update({
        where: { id: guarantee.id },
        data: {
          status: accept
            ? LoanGuarantorStatus.CONFIRMED
            : LoanGuarantorStatus.DECLINED,
          confirmedAt: accept ? new Date() : null,
        },
      });
      await this.createUserNotification(tx, {
        userId: guarantee.application.member.userId,
        titleEn: accept ? "Guarantee accepted" : "Guarantee declined",
        titleSw: accept ? "Udhamini umekubaliwa" : "Udhamini umekataliwa",
        bodyEn: `${membership.fullName} ${accept ? "accepted" : "declined"} your guarantee request for ${guarantee.application.currency} ${guarantee.application.amountMinor}.`,
        bodySw: `${membership.fullName} ${accept ? "amekubali" : "amekataa"} ombi lako la udhamini wa ${guarantee.application.currency} ${guarantee.application.amountMinor}.`,
      });
    });
    return { accepted: accept };
  }

  async reviewLoanRepayment(
    user: AuthenticatedUser,
    groupId: string,
    repaymentId: string,
    approve: boolean,
  ) {
    const membership = await this.requireMembership(user, groupId, [
      GroupRole.GROUP_ADMIN,
      GroupRole.TREASURER,
    ]);
    return this.prisma.$transaction(
      async (tx) => {
        const repayment = await tx.loanRepayment.findFirst({
          where: { id: repaymentId, groupId },
          include: { loan: true, member: true },
        });
        if (!repayment) throw new NotFoundException("Repayment not found.");
        if (
          repayment.groupMemberId === membership.id ||
          repayment.createdByUserId === user.id
        ) {
          throw new ForbiddenException(
            "Another treasurer must verify your repayment.",
          );
        }
        if (repayment.status !== LoanRepaymentStatus.SUBMITTED) {
          throw new ConflictException("Repayment has already been reviewed.");
        }
        const loan = repayment.loan;
        if (
          approve &&
          (loan.status !== GroupLoanStatus.ACTIVE ||
            repayment.amountMinor >
              loan.totalPayableMinor - loan.amountPaidMinor)
        ) {
          throw new BadRequestException(
            "Repayment exceeds the active loan balance.",
          );
        }
        const updated = await tx.loanRepayment.update({
          where: { id: repaymentId, status: LoanRepaymentStatus.SUBMITTED },
          data: {
            status: approve
              ? LoanRepaymentStatus.APPROVED
              : LoanRepaymentStatus.REJECTED,
            reviewedByUserId: user.id,
            reviewedAt: new Date(),
          },
        });
        if (approve) {
          const amountPaidMinor = loan.amountPaidMinor + repayment.amountMinor;
          await tx.groupLoan.update({
            where: { id: loan.id },
            data: {
              amountPaidMinor,
              status:
                amountPaidMinor === loan.totalPayableMinor
                  ? GroupLoanStatus.PAID
                  : GroupLoanStatus.ACTIVE,
            },
          });
        }
        await tx.auditLog.create({
          data: {
            actorUserId: user.id,
            groupId,
            action: approve
              ? AuditAction.LOAN_REPAYMENT_APPROVED
              : AuditAction.LOAN_REPAYMENT_REJECTED,
            entityType: "LoanRepayment",
            entityId: repaymentId,
            newValue: {
              amountMinor: repayment.amountMinor,
              status: updated.status,
            },
          },
        });
        await this.createUserNotification(tx, {
          userId: repayment.member.userId,
          titleEn: approve
            ? "Loan repayment approved"
            : "Loan repayment rejected",
          titleSw: approve
            ? "Marejesho ya mkopo yameidhinishwa"
            : "Marejesho ya mkopo yamekataliwa",
          bodyEn: `Your loan repayment of ${repayment.currency} ${repayment.amountMinor} was ${approve ? "approved" : "rejected"}.`,
          bodySw: `Marejesho yako ya mkopo ya ${repayment.currency} ${repayment.amountMinor} ${approve ? "yameidhinishwa" : "yamekataliwa"}.`,
        });
        return updated;
      },
      { isolationLevel: "Serializable" },
    );
  }

  private canReviewLoans(role: GroupRole): boolean {
    return role === GroupRole.GROUP_ADMIN || role === GroupRole.TREASURER;
  }

  private canReviewContributionPayments(role: GroupRole): boolean {
    return (
      role === GroupRole.GROUP_ADMIN ||
      role === GroupRole.TREASURER ||
      role === GroupRole.SECRETARY
    );
  }

  private ensureContributionPaymentReviewer(
    reviewerRole: GroupRole,
    paymentMember: Pick<GroupMember, "role">,
  ): void {
    const paymentMemberRole = paymentMember.role;
    if (reviewerRole === GroupRole.GROUP_ADMIN) {
      return;
    }
    const canReview =
      (reviewerRole === GroupRole.SECRETARY &&
        paymentMemberRole === GroupRole.TREASURER) ||
      (reviewerRole === GroupRole.TREASURER &&
        paymentMemberRole !== GroupRole.TREASURER);

    if (!canReview) {
      throw new ForbiddenException(
        "This payment must be reviewed by the other payment reviewer role.",
      );
    }
  }

  private processingFee(amountMinor: number): number {
    return Math.ceil(amountMinor * 0.02);
  }

  private loanTotalPayable(
    principalMinor: number,
    termMonths: number,
    monthlyInterestRateBps: number,
    processingFeeMinor: number,
  ): number {
    const interestMinor = Math.ceil(
      (principalMinor * monthlyInterestRateBps * termMonths) / 10000,
    );
    return principalMinor + interestMinor + processingFeeMinor;
  }

  private groupExpenseSummary(expense: {
    id: string;
    category: string;
    purpose: string;
    beneficiary: string | null;
    amountMinor: number;
    currency: string;
    paymentRail: string | null;
    reference: string | null;
    status: GroupExpenseStatus;
    spentAt: Date | null;
    reviewedAt: Date | null;
    reviewNotes: string | null;
    createdAt: Date;
    createdBy?: { displayName: string | null } | null;
    reviewedBy?: { displayName: string | null } | null;
  }) {
    return {
      id: expense.id,
      category: expense.category,
      purpose: expense.purpose,
      beneficiary: expense.beneficiary,
      amountMinor: expense.amountMinor,
      currency: expense.currency,
      paymentRail: expense.paymentRail,
      reference: expense.reference,
      status: expense.status,
      spentAt: expense.spentAt,
      reviewedAt: expense.reviewedAt,
      reviewNotes: expense.reviewNotes,
      createdAt: expense.createdAt,
      createdByName: expense.createdBy?.displayName ?? null,
      reviewedByName: expense.reviewedBy?.displayName ?? null,
    };
  }

  private loanSummary(loan: {
    id: string;
    amountMinor: number;
    totalPayableMinor: number;
    amountPaidMinor: number;
    currency: string;
    purpose: string;
    termMonths: number;
    monthlyInterestRateBps: number;
    status: GroupLoanStatus;
    disbursedAt: Date;
    dueAt: Date;
  }) {
    return {
      id: loan.id,
      amountMinor: loan.amountMinor,
      totalPayableMinor: loan.totalPayableMinor,
      amountPaidMinor: loan.amountPaidMinor,
      outstandingMinor: Math.max(
        loan.totalPayableMinor - loan.amountPaidMinor,
        0,
      ),
      currency: loan.currency,
      purpose: loan.purpose,
      termMonths: loan.termMonths,
      monthlyInterestRateBps: loan.monthlyInterestRateBps,
      status: loan.status,
      disbursedAt: loan.disbursedAt,
      dueAt: loan.dueAt,
    };
  }

  private async groupCashPosition(client: GroupCashClient, groupId: string) {
    const [paid, approvedExpenses, pendingExpenses, activeLoans] =
      await Promise.all([
        client.groupContributionPayment.aggregate({
          where: {
            groupId,
            status: GroupContributionPaymentStatus.APPROVED,
          },
          _sum: { amountMinor: true },
        }),
        client.groupExpense.aggregate({
          where: { groupId, status: GroupExpenseStatus.APPROVED },
          _sum: { amountMinor: true },
        }),
        client.groupExpense.aggregate({
          where: { groupId, status: GroupExpenseStatus.SUBMITTED },
          _sum: { amountMinor: true },
          _count: true,
        }),
        client.groupLoan.aggregate({
          where: { groupId, status: GroupLoanStatus.ACTIVE },
          _sum: { amountMinor: true, amountPaidMinor: true },
        }),
      ]);
    const collectedMinor = paid._sum.amountMinor ?? 0;
    const approvedExpenseMinor = approvedExpenses._sum.amountMinor ?? 0;
    const pendingExpenseMinor = pendingExpenses._sum.amountMinor ?? 0;
    const loanPrincipalOutMinor = Math.max(
      (activeLoans._sum.amountMinor ?? 0) -
        (activeLoans._sum.amountPaidMinor ?? 0),
      0,
    );
    const rawCashBalanceMinor =
      collectedMinor - approvedExpenseMinor - loanPrincipalOutMinor;
    const rawAvailableExpenseMinor = rawCashBalanceMinor - pendingExpenseMinor;
    return {
      collectedMinor,
      approvedExpenseMinor,
      pendingExpenseMinor,
      pendingCount: pendingExpenses._count,
      loanPrincipalOutMinor,
      cashBalanceMinor: Math.max(rawCashBalanceMinor, 0),
      availableExpenseMinor: Math.max(rawAvailableExpenseMinor, 0),
    };
  }

  private loanApplicationSummary(application: {
    id: string;
    amountMinor: number;
    approvedAmountMinor: number | null;
    currency: string;
    purpose: string;
    termMonths: number;
    monthlyInterestRateBps: number;
    processingFeeMinor: number;
    status: LoanApplicationStatus;
    reviewNotes: string | null;
    rejectionReason: string | null;
    createdAt: Date;
    approvedAt: Date | null;
    rejectedAt: Date | null;
    member: {
      id: string;
      fullName: string;
      memberNumber: string | null;
      status: GroupMemberStatus;
      joinedAt: Date | null;
    };
    guarantors: {
      id: string;
      status: string;
      confirmedAt: Date | null;
      member: {
        id: string;
        fullName: string;
        memberNumber: string | null;
      };
    }[];
  }) {
    const confirmedGuarantors = application.guarantors.filter(
      (guarantor) => guarantor.status === "CONFIRMED",
    ).length;
    return {
      id: application.id,
      amountMinor: application.amountMinor,
      approvedAmountMinor: application.approvedAmountMinor,
      currency: application.currency,
      purpose: application.purpose,
      termMonths: application.termMonths,
      monthlyInterestRateBps: application.monthlyInterestRateBps,
      processingFeeMinor: application.processingFeeMinor,
      estimatedTotalPayableMinor: this.loanTotalPayable(
        application.approvedAmountMinor ?? application.amountMinor,
        application.termMonths,
        application.monthlyInterestRateBps,
        application.processingFeeMinor,
      ),
      status: application.status,
      reviewNotes: application.reviewNotes,
      rejectionReason: application.rejectionReason,
      createdAt: application.createdAt,
      approvedAt: application.approvedAt,
      rejectedAt: application.rejectedAt,
      applicant: application.member,
      guarantors: application.guarantors.map((guarantor) => ({
        id: guarantor.id,
        status: guarantor.status,
        confirmedAt: guarantor.confirmedAt,
        member: guarantor.member,
      })),
      guarantorSummary: {
        confirmed: confirmedGuarantors,
        required: 2,
        total: application.guarantors.length,
      },
    };
  }

  private loanRepaymentSummary(loan: {
    id: string;
    amountMinor: number;
    totalPayableMinor: number;
    amountPaidMinor: number;
    currency: string;
    purpose: string;
    termMonths: number;
    monthlyInterestRateBps: number;
    status: GroupLoanStatus;
    disbursedAt: Date;
    dueAt: Date;
    repayments: {
      id: string;
      amountMinor: number;
      currency: string;
      method: string;
      reference: string | null;
      status: LoanRepaymentStatus;
      paidAt: Date | null;
      createdAt: Date;
    }[];
  }) {
    return {
      loan: this.loanSummary(loan),
      repayments: loan.repayments.map((repayment) => ({
        id: repayment.id,
        amountMinor: repayment.amountMinor,
        currency: repayment.currency,
        method: repayment.method,
        reference: repayment.reference,
        status: repayment.status,
        paidAt: repayment.paidAt,
        createdAt: repayment.createdAt,
      })),
    };
  }

  async settings(user: AuthenticatedUser, groupId: string) {
    await this.requireMembership(user, groupId);
    const [group, preferences] = await Promise.all([
      this.prisma.group.findUniqueOrThrow({ where: { id: groupId } }),
      this.prisma.notificationPreference.findMany({
        where: { userId: user.id },
      }),
    ]);
    return { group, notificationPreferences: preferences };
  }

  async auditLog(user: AuthenticatedUser, groupId: string) {
    await this.requireMembership(user, groupId, [GroupRole.GROUP_ADMIN]);
    return {
      entries: await this.prisma.auditLog.findMany({
        where: { groupId },
        orderBy: { createdAt: "desc" },
        take: 100,
      }),
    };
  }

  async notifications(user: AuthenticatedUser) {
    return {
      notifications: await this.prisma.notification.findMany({
        where: { userId: user.id },
        orderBy: { createdAt: "desc" },
      }),
    };
  }

  async markNotificationRead(user: AuthenticatedUser, notificationId: string) {
    const notification = await this.prisma.notification.findFirst({
      where: { id: notificationId, userId: user.id },
    });
    if (!notification) throw new NotFoundException("Notification not found.");
    return this.prisma.notification.update({
      where: { id: notification.id },
      data: { readAt: new Date() },
    });
  }

  private async createUserNotification(
    tx: Prisma.TransactionClient,
    input: {
      userId: string | null;
      titleEn: string;
      titleSw: string;
      bodyEn: string;
      bodySw: string;
    },
  ) {
    if (!input.userId) return;
    const recipient = await tx.user.findUnique({
      where: { id: input.userId },
      select: {
        id: true,
        preferredLocale: true,
        pushDeviceTokens: { select: { token: true } },
      },
    });
    if (!recipient) return;
    const title =
      recipient.preferredLocale === Locale.sw ? input.titleSw : input.titleEn;
    const body =
      recipient.preferredLocale === Locale.sw ? input.bodySw : input.bodyEn;
    const notification = await tx.notification.create({
      data: {
        userId: recipient.id,
        title,
        body,
        locale: recipient.preferredLocale,
      },
    });
    const pushResult = await this.pushNotifications.sendToTokens(
      recipient.pushDeviceTokens.map((item) => item.token),
      {
        title,
        body,
        data: { notificationId: notification.id },
      },
    );
    if (pushResult.invalidTokens.length > 0) {
      await tx.pushDeviceToken.deleteMany({
        where: { token: { in: pushResult.invalidTokens } },
      });
    }
  }

  private async requireMembership(
    user: AuthenticatedUser,
    groupId: string,
    allowedRoles?: GroupRole[],
  ) {
    const membership = await this.prisma.groupMember.findFirst({
      where: { userId: user.id, groupId, status: GroupMemberStatus.ACTIVE },
      include: {
        group: {
          include: {
            subscriptions: {
              include: { plan: true },
              orderBy: { updatedAt: "desc" },
              take: 1,
            },
          },
        },
      },
    });
    if (!membership) throw new ForbiddenException("Group access denied.");
    const subscription = await this.syncProviderSubscription(
      membership.group.subscriptions[0] ?? null,
    );
    if (
      !subscription ||
      !hasPaidFeatureAccess({
        state: subscription.state,
        currentPeriodEndsAt: subscription.currentPeriodEndsAt,
      })
    ) {
      throw new ForbiddenException({
        code: ApiErrorCode.SubscriptionExpired,
        message: "Group access has expired. Upgrade your plan to continue.",
      });
    }
    if (allowedRoles && !allowedRoles.includes(membership.role)) {
      throw new ForbiddenException("Role is not allowed for this action.");
    }
    return membership;
  }

  private async syncProviderSubscription<
    T extends {
      id: string;
      providerSubscriptionId: string | null;
      state: SubscriptionState;
      currentPeriodStartsAt: Date | null;
      currentPeriodEndsAt: Date | null;
      cancelAtPeriodEnd: boolean;
      plan: {
        interval: BillingInterval;
        intervalCount: number;
      };
    },
  >(subscription: T | null): Promise<T | null> {
    if (!subscription?.providerSubscriptionId) return subscription;

    try {
      const providerSubscription = await this.billingProvider.getSubscription(
        subscription.providerSubscriptionId,
      );
      const nextState = this.mapProviderSubscriptionStatus(
        providerSubscription.status,
      );
      const activePeriodStartsAt = new Date();
      const activePeriodEndsAt = this.addBillingPeriod(
        activePeriodStartsAt,
        subscription.plan.interval,
        subscription.plan.intervalCount,
      );
      const updated = await this.prisma.subscription.update({
        where: { id: subscription.id },
        data: {
          state: nextState,
          cancelAtPeriodEnd: providerSubscription.cancelAtPeriodEnd,
          currentPeriodStartsAt:
            nextState === SubscriptionState.ACTIVE
              ? activePeriodStartsAt
              : null,
          currentPeriodEndsAt:
            nextState === SubscriptionState.ACTIVE
              ? activePeriodEndsAt
              : null,
          cancelledAt:
            nextState === SubscriptionState.CANCELLED ? new Date() : null,
          expiredAt: nextState === SubscriptionState.EXPIRED ? new Date() : null,
          suspendedAt:
            nextState === SubscriptionState.SUSPENDED ? new Date() : null,
        },
        include: { plan: true },
      });
      return updated as unknown as T;
    } catch {
      return subscription;
    }
  }

  private mapProviderSubscriptionStatus(status: string): SubscriptionState {
    if (status === "active") return SubscriptionState.ACTIVE;
    if (status === "cancelled") return SubscriptionState.CANCELLED;
    if (status === "suspended") return SubscriptionState.SUSPENDED;
    if (status === "expired") return SubscriptionState.EXPIRED;
    return SubscriptionState.PAST_DUE;
  }

  private addBillingPeriod(
    date: Date,
    interval: BillingInterval,
    intervalCount: number,
  ): Date {
    const next = new Date(date);
    if (interval === BillingInterval.YEAR) {
      next.setFullYear(next.getFullYear() + intervalCount);
    } else {
      next.setMonth(next.getMonth() + intervalCount);
    }
    return next;
  }

  private async membersWithOutstandingObligations(groupId: string): Promise<
    Array<{
      id: string;
      userId: string | null;
      fullName: string;
      phone: string | null;
    }>
  > {
    return this.prisma.groupMember.findMany({
      where: {
        groupId,
        status: GroupMemberStatus.ACTIVE,
        obligations: {
          some: {
            dueAt: { lte: new Date() },
            status: {
              in: [
                ContributionObligationStatus.UPCOMING,
                ContributionObligationStatus.DUE,
                ContributionObligationStatus.PARTIALLY_PAID,
                ContributionObligationStatus.OVERDUE,
              ],
            },
          },
        },
      },
      select: { id: true, userId: true, fullName: true, phone: true },
      orderBy: { fullName: "asc" },
    });
  }

  private memberContributionWeeklyDays(
    input: ContributionSettingsDto,
  ): number[] {
    const configuredDays = input.memberContributionDueDaysOfWeek;
    const fallbackDay =
      input.memberContributionDueDayOfWeek ?? input.dueDayOfWeek;
    const days =
      configuredDays && configuredDays.length > 0
        ? configuredDays
        : fallbackDay
          ? [fallbackDay]
          : [];

    return [...new Set(days)].sort((a, b) => a - b);
  }

  private memberContributionPlanName(
    frequency: ContributionFrequency,
    weeklyDays: number[],
    dueDayOfWeek: number | undefined,
    index: number,
  ): string {
    if (frequency !== ContributionFrequency.WEEKLY || weeklyDays.length <= 1) {
      return "Member contribution";
    }

    return `Member contribution - ${this.weekdayName(dueDayOfWeek ?? index + 1)}`;
  }

  private weekdayName(day: number): string {
    const names = [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday",
    ];
    return names[day - 1] ?? `Day ${day}`;
  }

  private validateContributionCycle(
    frequency: ContributionFrequency,
    dueDayOfWeek?: number,
    dueDayOfMonth?: number,
  ): void {
    if (frequency === ContributionFrequency.WEEKLY && !dueDayOfWeek) {
      throw new BadRequestException(
        "Weekly contributions require a due weekday.",
      );
    }
    const monthlyLikeFrequencies: ContributionFrequency[] = [
      ContributionFrequency.MONTHLY,
      ContributionFrequency.QUARTERLY,
      ContributionFrequency.ANNUAL,
    ];
    if (monthlyLikeFrequencies.includes(frequency) && !dueDayOfMonth) {
      throw new BadRequestException(
        "Monthly, quarterly, and annual contributions require a due day.",
      );
    }
  }

  private contributionCycleData(
    input: ContributionSettingsDto,
    frequency: ContributionFrequency,
    dueDayOfWeek?: number,
    dueDayOfMonth?: number,
  ): {
    dueDayOfWeek: number | null;
    dueDayOfMonth: number | null;
    cycleAnchorDate: Date | null;
  } {
    const monthlyLikeFrequencies: ContributionFrequency[] = [
      ContributionFrequency.MONTHLY,
      ContributionFrequency.QUARTERLY,
      ContributionFrequency.ANNUAL,
    ];

    return {
      dueDayOfWeek:
        frequency === ContributionFrequency.WEEKLY ? dueDayOfWeek! : null,
      dueDayOfMonth: monthlyLikeFrequencies.includes(frequency)
        ? dueDayOfMonth!
        : null,
      cycleAnchorDate: input.cycleAnchorDate
        ? new Date(input.cycleAnchorDate)
        : null,
    };
  }

  private contributionFrequency(
    value: string | undefined,
    fallback: ContributionFrequency,
  ): ContributionFrequency {
    const normalized = value?.trim().toUpperCase();
    if (!normalized) return fallback;
    if (normalized in ContributionFrequency) {
      return normalized as ContributionFrequency;
    }
    throw new BadRequestException("Contribution frequency is not supported.");
  }

  private async generateContributionSchedule(
    groupId: string,
    memberId?: string,
    db: Prisma.TransactionClient = this.prisma,
  ): Promise<void> {
    let financialYear = await db.financialYear.findFirst({
      where: { groupId, isActive: true },
      select: {
        id: true,
        name: true,
        startsAt: true,
        endsAt: true,
        automaticRollover: true,
      },
    });
    if (!financialYear) return;
    if (financialYear.automaticRollover && financialYear.endsAt < new Date()) {
      let startsAt = this.addDays(this.startOfDay(financialYear.endsAt), 1);
      let endsAt = this.addDays(this.addMonths(startsAt, 12), -1);
      while (endsAt < this.startOfDay(new Date())) {
        startsAt = this.addDays(endsAt, 1);
        endsAt = this.addDays(this.addMonths(startsAt, 12), -1);
      }
      const nextYear = await db.financialYear.upsert({
        where: { groupId_startsAt_endsAt: { groupId, startsAt, endsAt } },
        update: { isActive: true },
        create: {
          groupId,
          name: `${startsAt.toISOString().slice(0, 10)} - ${endsAt.toISOString().slice(0, 10)}`,
          startsAt,
          endsAt,
          isActive: true,
          automaticRollover: true,
        },
      });
      await db.financialYear.updateMany({
        where: { groupId, id: { not: nextYear.id }, isActive: true },
        data: { isActive: false },
      });
      financialYear = nextYear;
    }

    const [plans, members] = await Promise.all([
      db.contributionPlan.findMany({
        where: {
          groupId,
          isActive: true,
          type: { not: ContributionPlanType.PENALTY },
        },
        select: {
          id: true,
          name: true,
          type: true,
          frequency: true,
          dueDayOfWeek: true,
          dueDayOfMonth: true,
          amountMinor: true,
          currency: true,
          cycleAnchorDate: true,
        },
      }),
      db.groupMember.findMany({
        where: {
          groupId,
          status: GroupMemberStatus.ACTIVE,
          ...(memberId ? { id: memberId } : {}),
        },
        select: { id: true, joinedAt: true },
      }),
    ]);
    await db.memberContributionObligation.updateMany({
      where: {
        member: { groupId },
        plan: { isActive: false },
        amountPaidMinor: 0,
        dueAt: { gt: new Date() },
        allocations: { none: {} },
      },
      data: { status: ContributionObligationStatus.WAIVED },
    });
    if (!plans.length || !members.length) return;

    await db.memberContributionObligation.updateMany({
      where: {
        member: { groupId },
        status: ContributionObligationStatus.UPCOMING,
        dueAt: { lte: new Date() },
      },
      data: { status: ContributionObligationStatus.DUE },
    });

    for (const plan of plans) {
      await db.memberContributionObligation.updateMany({
        where: {
          planId: plan.id,
          amountPaidMinor: 0,
          dueAt: { gt: new Date() },
          allocations: { none: {} },
          status: {
            in: [
              ContributionObligationStatus.DUE,
              ContributionObligationStatus.UPCOMING,
            ],
          },
        },
        data: {
          amountDueMinor: plan.amountMinor,
          currency: plan.currency,
          ...(plan.amountMinor === 0
            ? { status: ContributionObligationStatus.WAIVED }
            : {}),
        },
      });
      if (plan.amountMinor <= 0) continue;
      const periods = await this.ensureContributionPeriods(
        groupId,
        financialYear,
        plan,
        db,
      );
      for (const member of members) {
        const joinedAt = member.joinedAt
          ? this.startOfDay(member.joinedAt)
          : financialYear.startsAt;
        await Promise.all(
          periods
            .filter((period) => period.endsAt >= joinedAt)
            .map((period) =>
              db.memberContributionObligation.upsert({
                where: {
                  groupMemberId_planId_periodId: {
                    groupMemberId: member.id,
                    planId: plan.id,
                    periodId: period.id,
                  },
                },
                update: {},
                create: {
                  groupMemberId: member.id,
                  planId: plan.id,
                  periodId: period.id,
                  amountDueMinor: plan.amountMinor,
                  currency: plan.currency,
                  dueAt: period.dueAt < joinedAt ? joinedAt : period.dueAt,
                  status:
                    (period.dueAt < joinedAt ? joinedAt : period.dueAt) <=
                    new Date()
                      ? ContributionObligationStatus.DUE
                      : ContributionObligationStatus.UPCOMING,
                },
              }),
            ),
        );
      }
    }
    await this.applyLatePenalties(groupId, db);
  }

  private async ensureContributionPeriods(
    groupId: string,
    financialYear: ScheduleFinancialYear,
    plan: ScheduleContributionPlan,
    db: Prisma.TransactionClient = this.prisma,
  ) {
    const specs = this.contributionPeriodSpecs(financialYear, plan);
    const periods = [];
    for (const spec of specs) {
      periods.push(
        await db.contributionPeriod.upsert({
          where: {
            groupId_planId_startsAt: {
              groupId,
              planId: plan.id,
              startsAt: spec.startsAt,
            },
          },
          update: {
            label: spec.label,
            endsAt: spec.endsAt,
            dueAt: spec.dueAt,
            sortOrder: spec.sortOrder,
          },
          create: {
            groupId,
            financialYearId: financialYear.id,
            planId: plan.id,
            label: spec.label,
            startsAt: spec.startsAt,
            endsAt: spec.endsAt,
            dueAt: spec.dueAt,
            sortOrder: spec.sortOrder,
          },
        }),
      );
    }
    return periods;
  }

  private contributionPeriodSpecs(
    financialYear: ScheduleFinancialYear,
    plan: ScheduleContributionPlan,
  ): ContributionPeriodSpec[] {
    const startsAt = this.startOfDay(financialYear.startsAt);
    const endsAt = this.startOfDay(financialYear.endsAt);

    if (
      plan.type === ContributionPlanType.JOINING_FEE ||
      plan.frequency === ContributionFrequency.ANNUAL ||
      plan.frequency === ContributionFrequency.ONCE
    ) {
      return [
        {
          label: `${financialYear.name} ${plan.name}`,
          startsAt,
          endsAt,
          dueAt:
            plan.type === ContributionPlanType.JOINING_FEE
              ? startsAt
              : this.periodDueDate(plan, startsAt, endsAt),
          sortOrder: 0,
        },
      ];
    }

    const specs: ContributionPeriodSpec[] = [];
    let cursor = plan.cycleAnchorDate
      ? this.startOfDay(plan.cycleAnchorDate)
      : startsAt;
    while (cursor < startsAt) {
      const next = this.nextPeriodStart(cursor, plan.frequency);
      if (next > startsAt) break;
      cursor = next;
    }
    let sortOrder = 0;
    while (cursor <= endsAt && specs.length < 370) {
      const periodStart = cursor < startsAt ? startsAt : cursor;
      const nextStart = this.nextPeriodStart(cursor, plan.frequency);
      const periodEnd = this.minDate(this.addDays(nextStart, -1), endsAt);
      specs.push({
        label: this.periodLabel(plan, periodStart, sortOrder + 1),
        startsAt: periodStart,
        endsAt: periodEnd,
        dueAt: this.periodDueDate(plan, periodStart, periodEnd),
        sortOrder,
      });
      cursor = nextStart;
      sortOrder += 1;
    }
    return specs;
  }

  private async allocatePaymentToObligations(
    groupId: string,
    paymentId: string,
    memberId: string,
    amountMinor: number,
    obligationIds?: string[],
    applyImmediately = true,
    db: Prisma.TransactionClient = this.prisma,
  ): Promise<void> {
    const existingAllocations = await db.paymentAllocation.findMany({
      where: { paymentId },
      include: { obligation: true },
    });
    if (existingAllocations.length > 0) {
      if (!applyImmediately) return;
      const pendingAllocations = existingAllocations.filter(
        (allocation) => allocation.status === PaymentAllocationStatus.PENDING,
      );
      if (!pendingAllocations.length) return;
      await this.applyPendingPaymentAllocations(pendingAllocations, db);
      return;
    }

    const requestedIds = [...new Set(obligationIds ?? [])].filter(Boolean);
    const obligations = await db.memberContributionObligation.findMany({
      where: {
        ...(requestedIds.length ? { id: { in: requestedIds } } : {}),
        groupMemberId: memberId,
        member: { groupId },
        dueAt: { lte: new Date() },
        status: {
          in: [
            ContributionObligationStatus.DUE,
            ContributionObligationStatus.PARTIALLY_PAID,
            ContributionObligationStatus.OVERDUE,
          ],
        },
      },
      include: {
        plan: true,
        allocations: {
          where: {
            status: PaymentAllocationStatus.PENDING,
            payment: {
              status: {
                in: [
                  GroupContributionPaymentStatus.PENDING_VERIFICATION,
                  GroupContributionPaymentStatus.SUBMITTED,
                ],
              },
            },
          },
        },
      },
      orderBy: [{ dueAt: "asc" }, { createdAt: "asc" }],
    });

    if (requestedIds.length && obligations.length !== requestedIds.length) {
      throw new BadRequestException(
        "Some selected contributions are not payable.",
      );
    }

    const reserved = (obligation: (typeof obligations)[number]) =>
      obligation.allocations.reduce(
        (total, allocation) => total + allocation.amountMinor,
        0,
      );
    const payableObligations = obligations.filter(
      (obligation) =>
        obligation.amountDueMinor -
          obligation.amountPaidMinor -
          reserved(obligation) >
        0,
    );
    const totalOutstanding = payableObligations.reduce(
      (total, obligation) =>
        total +
        (obligation.amountDueMinor -
          obligation.amountPaidMinor -
          reserved(obligation)),
      0,
    );
    if (!payableObligations.length || amountMinor > totalOutstanding) {
      throw new BadRequestException(
        "Payment amount must match outstanding contributions.",
      );
    }

    let remaining = amountMinor;
    const operations = [];
    for (const obligation of payableObligations) {
      if (remaining <= 0) break;
      const outstanding =
        obligation.amountDueMinor -
        obligation.amountPaidMinor -
        reserved(obligation);
      const allocated = Math.min(outstanding, remaining);
      if (!obligation.plan.allowsPartial && allocated < outstanding) {
        throw new BadRequestException(
          "This contribution must be paid in full.",
        );
      }
      const amountPaidMinor = obligation.amountPaidMinor + allocated;
      operations.push(
        db.paymentAllocation.create({
          data: {
            paymentId,
            planId: obligation.planId,
            periodId: obligation.periodId,
            obligationId: obligation.id,
            amountMinor: allocated,
            status: applyImmediately
              ? PaymentAllocationStatus.APPLIED
              : PaymentAllocationStatus.PENDING,
          },
        }),
      );
      if (applyImmediately) {
        operations.push(
          db.memberContributionObligation.update({
            where: { id: obligation.id },
            data: {
              amountPaidMinor,
              status: this.obligationStatus(
                obligation.amountDueMinor,
                amountPaidMinor,
              ),
            },
          }),
        );
      }
      remaining -= allocated;
    }

    if (remaining > 0) {
      throw new BadRequestException(
        "Payment amount must match outstanding contributions.",
      );
    }
    await Promise.all(operations);
  }

  private async applyPendingPaymentAllocations(
    allocations: Array<{
      id: string;
      amountMinor: number;
      obligation: {
        id: string;
        amountDueMinor: number;
        amountPaidMinor: number;
      } | null;
    }>,
    db: Prisma.TransactionClient = this.prisma,
  ): Promise<void> {
    const operations = [];
    for (const allocation of allocations) {
      const obligation = allocation.obligation;
      if (!obligation) {
        throw new BadRequestException(
          "Payment allocation is missing an obligation.",
        );
      }
      const amountPaidMinor =
        obligation.amountPaidMinor + allocation.amountMinor;
      if (amountPaidMinor > obligation.amountDueMinor) {
        throw new BadRequestException(
          "Payment exceeds outstanding contribution.",
        );
      }
      operations.push(
        db.paymentAllocation.update({
          where: { id: allocation.id },
          data: { status: PaymentAllocationStatus.APPLIED },
        }),
      );
      operations.push(
        db.memberContributionObligation.update({
          where: { id: obligation.id },
          data: {
            amountPaidMinor,
            status: this.obligationStatus(
              obligation.amountDueMinor,
              amountPaidMinor,
            ),
          },
        }),
      );
    }
    await Promise.all(operations);
  }

  private obligationStatus(
    amountDueMinor: number,
    amountPaidMinor: number,
  ): ContributionObligationStatus {
    if (amountPaidMinor >= amountDueMinor) {
      return ContributionObligationStatus.PAID;
    }
    if (amountPaidMinor > 0) {
      return ContributionObligationStatus.PARTIALLY_PAID;
    }
    return ContributionObligationStatus.DUE;
  }

  private nextPeriodStart(date: Date, frequency: ContributionFrequency): Date {
    if (frequency === ContributionFrequency.DAILY) {
      return this.addDays(date, 1);
    }
    if (frequency === ContributionFrequency.WEEKLY) {
      return this.addDays(date, 7);
    }
    if (frequency === ContributionFrequency.QUARTERLY) {
      return this.addMonths(date, 3);
    }
    return this.addMonths(date, 1);
  }

  private periodDueDate(
    plan: ScheduleContributionPlan,
    startsAt: Date,
    endsAt: Date,
  ): Date {
    if (plan.frequency === ContributionFrequency.DAILY) return startsAt;
    if (plan.frequency === ContributionFrequency.WEEKLY) {
      return this.clampDate(
        this.weekdayDate(startsAt, plan.dueDayOfWeek ?? 1),
        startsAt,
        endsAt,
      );
    }
    const day = plan.dueDayOfMonth ?? startsAt.getUTCDate();
    return this.clampDate(this.monthDayDate(startsAt, day), startsAt, endsAt);
  }

  private periodLabel(
    plan: ScheduleContributionPlan,
    startsAt: Date,
    count: number,
  ): string {
    if (plan.frequency === ContributionFrequency.DAILY) {
      return `${plan.name} ${startsAt.toISOString().slice(0, 10)}`;
    }
    if (plan.frequency === ContributionFrequency.WEEKLY) {
      return `${plan.name} Week ${count}`;
    }
    if (plan.frequency === ContributionFrequency.QUARTERLY) {
      return `${plan.name} Quarter ${count}`;
    }
    return `${this.monthName(startsAt)} ${startsAt.getUTCFullYear()} ${plan.name}`;
  }

  private startOfDay(date: Date): Date {
    return new Date(
      Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()),
    );
  }

  private addDays(date: Date, days: number): Date {
    const next = new Date(date);
    next.setUTCDate(next.getUTCDate() + days);
    return next;
  }

  private addMonths(date: Date, months: number): Date {
    const next = new Date(date);
    next.setUTCMonth(next.getUTCMonth() + months);
    return next;
  }

  private minDate(first: Date, second: Date): Date {
    return first <= second ? first : second;
  }

  private clampDate(date: Date, startsAt: Date, endsAt: Date): Date {
    if (date < startsAt) return startsAt;
    if (date > endsAt) return endsAt;
    return date;
  }

  private weekdayDate(startsAt: Date, dueDayOfWeek: number): Date {
    const target = dueDayOfWeek % 7;
    const current = startsAt.getUTCDay() === 0 ? 7 : startsAt.getUTCDay();
    const offset = (target - current + 7) % 7;
    return this.addDays(startsAt, offset);
  }

  private monthDayDate(startsAt: Date, dueDayOfMonth: number): Date {
    const lastDay = new Date(
      Date.UTC(startsAt.getUTCFullYear(), startsAt.getUTCMonth() + 1, 0),
    ).getUTCDate();
    return new Date(
      Date.UTC(
        startsAt.getUTCFullYear(),
        startsAt.getUTCMonth(),
        Math.min(dueDayOfMonth, lastDay),
      ),
    );
  }

  private monthName(date: Date): string {
    const months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    return months[date.getUTCMonth()] ?? "Month";
  }

  private async ensureGroupMember(
    groupId: string,
    memberId: string,
  ): Promise<Pick<GroupMember, "id" | "role" | "userId">> {
    const member = await this.prisma.groupMember.findFirst({
      where: { id: memberId, groupId, status: GroupMemberStatus.ACTIVE },
      select: { id: true, role: true, userId: true },
    });
    if (!member) throw new NotFoundException("Member not found.");
    return member;
  }

  private async createReceiptForPayment(
    groupId: string,
    paymentId: string,
    db: Prisma.TransactionClient = this.prisma,
  ): Promise<void> {
    const existing = await db.receipt.findUnique({
      where: { paymentId },
      select: { id: true },
    });
    if (existing) return;

    const receiptNumber = `VKP-${Date.now()}-${randomBytes(3).toString("hex").toUpperCase()}`;
    const verificationHash = createHash("sha256")
      .update(`${groupId}:${paymentId}:${receiptNumber}`)
      .digest("hex");

    await db.receipt.create({
      data: {
        groupId,
        paymentId,
        receiptNumber,
        status: ReceiptStatus.VALID,
        verificationHash,
      },
    });
    await db.auditLog.create({
      data: {
        groupId,
        action: AuditAction.RECEIPT_CREATED,
        entityType: "Receipt",
        entityId: paymentId,
        newValue: { paymentId, receiptNumber },
      },
    });
  }

  private paymentWithReceipt(paymentId: string) {
    return this.prisma.groupContributionPayment.findUniqueOrThrow({
      where: { id: paymentId },
      include: { member: true, receipt: true },
    });
  }

  private auditPaymentReview(
    user: AuthenticatedUser,
    groupId: string,
    paymentId: string,
    action: AuditAction,
    reason?: string,
    db: Prisma.TransactionClient = this.prisma,
  ) {
    return db.auditLog.create({
      data: {
        actorUserId: user.id,
        groupId,
        action,
        entityType: "GroupContributionPayment",
        entityId: paymentId,
        newValue: { reason },
      },
    });
  }

  private async displayName(userId: string): Promise<string> {
    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
      select: { displayName: true, identities: true },
    });
    return user.displayName ?? user.identities[0]?.value ?? "Member";
  }

  private async uniqueSlug(name: string): Promise<string> {
    const base = name
      .trim()
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/(^-|-$)/g, "");
    let slug = base || "group";
    let index = 2;
    while (await this.prisma.group.findUnique({ where: { slug } })) {
      slug = `${base}-${index}`;
      index += 1;
    }
    return slug;
  }

  private normalizePhone(value: string): string {
    const digits = value.replace(/\D/g, "");
    if (digits.startsWith("255")) return digits;
    if (digits.startsWith("0")) return `255${digits.slice(1)}`;
    if (digits.length === 9) return `255${digits}`;
    return digits;
  }

  private optionalTrim(value?: string | null): string | null {
    const trimmed = value?.trim();
    return trimmed ? trimmed : null;
  }

  private async nextMemberNumber(
    groupId: string,
    tx: Prisma.TransactionClient,
  ): Promise<string> {
    await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext(${groupId}))`;
    const numbers = await tx.groupMember.findMany({
      where: { groupId },
      select: { memberNumber: true },
    });
    const next =
      numbers.reduce(
        (max, item) =>
          /^MBR-[0-9]{6}$/.test(item.memberNumber ?? "")
            ? Math.max(max, Number(item.memberNumber!.slice(4)))
            : max,
        0,
      ) + 1;
    if (next > 999999) {
      throw new BadRequestException("Member number range exhausted.");
    }
    return `MBR-${String(next).padStart(6, "0")}`;
  }

  private async activateInvitedMember(
    user: AuthenticatedUser,
    member: GroupMember,
    role: GroupRole,
    joinedAt: Date,
    tx: Prisma.TransactionClient,
  ) {
    if (member.status !== GroupMemberStatus.INVITED) {
      throw new ConflictException("This invitation has already been accepted.");
    }
    if (member.userId && member.userId !== user.id) {
      throw new ConflictException("This invitation belongs to another user.");
    }

    const identities = await tx.userIdentity.findMany({
      where: { userId: user.id, isVerified: true },
      select: { value: true },
    });
    const destinations = [member.email?.trim().toLowerCase(), member.phone];
    if (!identities.some((identity) => destinations.includes(identity.value))) {
      throw new ForbiddenException(
        "Sign in with the verified email or phone number that received this invitation.",
      );
    }

    const fullName =
      member.fullName.trim() || (await this.displayName(user.id));
    const memberNumber =
      member.memberNumber ?? (await this.nextMemberNumber(member.groupId, tx));
    return tx.groupMember.update({
      where: { id: member.id },
      data: {
        userId: user.id,
        memberNumber,
        fullName,
        role,
        status: GroupMemberStatus.ACTIVE,
        joinedAt,
      },
    });
  }

  private async deliverMemberInvitation(input: {
    groupName: string;
    groupCode: string | null;
    groupType: string | null;
    currency: string;
    memberName: string;
    memberRole: string;
    inviterName: string;
    inviterRole: string;
    phone: string | null;
    email: string | null;
    invitationCode: string;
    expiresAt: Date;
  }): Promise<InvitationDeliveryResult[]> {
    const deliveries: InvitationDeliveryResult[] = [];
    const failures: string[] = [];
    const text = this.memberInvitationText(input);

    if (input.phone) {
      try {
        const result = await this.briq.sendSms({
          to: input.phone,
          content: text,
        });
        deliveries.push({
          channel: "sms",
          destination: input.phone,
          provider: result.provider,
          delivered: result.delivered,
        });
      } catch (error) {
        failures.push(this.deliveryFailure("sms", error));
      }
    }

    if (input.email) {
      try {
        const message = groupInvitationEmailTemplate({
          ...input,
          recipientEmail: input.email,
        });
        const result = await this.email.sendEmail({
          to: input.email,
          subject: message.subject,
          text: message.text,
          html: message.html,
        });
        deliveries.push({
          channel: "email",
          destination: input.email,
          provider: result.provider,
          delivered: result.delivered,
        });
      } catch (error) {
        failures.push(this.deliveryFailure("email", error));
      }
    }

    if (deliveries.length === 0) {
      throw new BadGatewayException({
        message: "Member invitation could not be delivered.",
        failures,
      });
    }

    return deliveries;
  }

  private memberInvitationText(input: {
    groupName: string;
    memberName: string;
    invitationCode: string;
    expiresAt: Date;
  }): string {
    const expiresOn = input.expiresAt.toISOString().slice(0, 10);
    return [
      `Hello ${input.memberName},`,
      `You have been invited to join ${input.groupName} on Vikoplus.`,
      `Invitation code: ${input.invitationCode}`,
      `This code expires on ${expiresOn}.`,
    ].join(" ");
  }

  private deliveryFailure(channel: string, error: unknown): string {
    const message = error instanceof Error ? error.message : String(error);
    return `${channel}: ${message}`;
  }

  private async cleanupUndeliveredInvitedMember(memberId: string) {
    try {
      await this.prisma.groupMember.delete({ where: { id: memberId } });
    } catch {
      // Best-effort cleanup only. The original delivery error is returned.
    }
  }

  private async primaryIdentity(
    userId: string,
  ): Promise<{ email?: string; phone?: string }> {
    const identities = await this.prisma.userIdentity.findMany({
      where: { userId, isVerified: true },
      orderBy: { createdAt: "asc" },
    });
    return {
      email: identities.find((identity) => identity.type === "EMAIL")?.value,
      phone: identities.find((identity) => identity.type === "PHONE")?.value,
    };
  }

  private hash(value: string): string {
    return createHash("sha256").update(value.trim()).digest("hex");
  }

  private normalizeInvitationCode(value: string): string {
    return value.trim().replace(/\s+/g, "").toUpperCase();
  }

  private async uniqueInvitationCode(
    client: Pick<Prisma.TransactionClient, "groupInvitation">,
  ): Promise<string> {
    for (let attempt = 0; attempt < 20; attempt += 1) {
      const code = this.invitationCode();
      const existing = await client.groupInvitation.findUnique({
        where: { tokenHash: this.hash(code) },
        select: { id: true },
      });
      if (!existing) {
        return code;
      }
    }
    throw new ConflictException("Could not generate a unique invitation code.");
  }

  private invitationCode(): string {
    const letters = "ABCDEFGHJKLMNPQRSTUVWXYZ";
    const digits = "23456789";
    const alphabet = `${letters}${digits}`;
    const chars = [
      letters[randomInt(letters.length)],
      digits[randomInt(digits.length)],
    ];
    while (chars.length < 6) {
      chars.push(alphabet[randomInt(alphabet.length)]);
    }
    for (let index = chars.length - 1; index > 0; index -= 1) {
      const swapIndex = randomInt(index + 1);
      [chars[index], chars[swapIndex]] = [chars[swapIndex], chars[index]];
    }
    return chars.join("");
  }

  private async monthlyContributionTrend(groupId: string, now: Date) {
    const start = new Date(now.getFullYear(), now.getMonth() - 5, 1);
    const buckets = Array.from({ length: 6 }, (_, index) => {
      const date = new Date(start.getFullYear(), start.getMonth() + index, 1);
      return {
        month: this.monthKey(date),
        label: date.toLocaleString("en-US", { month: "short" }),
        amountMinor: 0,
        paymentsCount: 0,
      };
    });
    const bucketByMonth = new Map(buckets.map((bucket) => [bucket.month, bucket]));
    const payments = await this.prisma.groupContributionPayment.findMany({
      where: {
        groupId,
        status: GroupContributionPaymentStatus.APPROVED,
        OR: [{ paidAt: { gte: start } }, { paidAt: null, createdAt: { gte: start } }],
      },
      select: { amountMinor: true, paidAt: true, createdAt: true },
    });

    for (const payment of payments) {
      const paidOn = payment.paidAt ?? payment.createdAt;
      const bucket = bucketByMonth.get(this.monthKey(paidOn));
      if (!bucket) {
        continue;
      }
      bucket.amountMinor += payment.amountMinor;
      bucket.paymentsCount += 1;
    }

    return buckets;
  }

  private monthKey(date: Date): string {
    return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}`;
  }

  private daysFromNow(days: number): Date {
    return new Date(Date.now() + days * 24 * 60 * 60_000);
  }
}
