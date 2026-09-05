// cspell:words Habari malipo yako yanatakiwa tarehe Kumbusho
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
  GroupContributionPaymentStatus,
  GroupLoanStatus,
  GroupMemberStatus,
  GroupRole,
  LoanApplicationStatus,
  LoanGuarantorStatus,
  LoanRepaymentStatus,
  Locale,
  PaymentAllocationStatus,
  ReceiptStatus,
} from "@prisma/client";
import type { GroupMember, Prisma } from "@prisma/client";
import { createHash, randomBytes } from "crypto";

import { AuthenticatedUser } from "../common/auth/authenticated-user";
import { PrismaService } from "../prisma/prisma.service";
import { SUBSCRIPTION_BILLING_PROVIDER } from "../billing/billing-provider.token";
import { SubscriptionBillingProvider } from "../billing/subscription-billing-provider";
import { BriqMessagingService } from "../messaging/briq-messaging.service";
import { SmtpEmailService } from "../messaging/smtp-email.service";
import { groupInvitationEmailTemplate } from "./group-invitation-email.template";
import { ReminderDispatchService } from "./reminder-dispatch.service";
import {
  AddMemberDto,
  AssignRoleDto,
  ContributionSettingsDto,
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
  ReminderSettingsDto,
  ReviewContributionPaymentDto,
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

@Injectable()
export class GroupsService {
  constructor(
    private readonly prisma: PrismaService,
    @Inject(SUBSCRIPTION_BILLING_PROVIDER)
    private readonly billingProvider: SubscriptionBillingProvider,
    private readonly briq: BriqMessagingService,
    private readonly email: SmtpEmailService,
    private readonly reminderDispatch: ReminderDispatchService,
  ) {}

  async updateLanguage(user: AuthenticatedUser, input: UpdateLanguageDto) {
    const updated = await this.prisma.user.update({
      where: { id: user.id },
      data: { preferredLocale: input.locale === "sw" ? Locale.sw : Locale.en },
    });
    return { userId: updated.id, preferredLocale: updated.preferredLocale };
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
        group: { include: { _count: { select: { members: true } } } },
      },
      orderBy: { updatedAt: "desc" },
    });
    return {
      groups: memberships.map((membership) => ({
        id: membership.groupId,
        name: membership.group.name,
        role: membership.role,
        status: membership.status,
        membersCount: membership.group._count.members,
      })),
    };
  }

  async createGroup(user: AuthenticatedUser, input: CreateGroupDto) {
    const name = input.name.trim();
    const slug = await this.uniqueSlug(name);
    const group = await this.prisma.group.create({
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
            fullName: await this.displayName(user.id),
            role: GroupRole.GROUP_ADMIN,
            status: GroupMemberStatus.ACTIVE,
            joinedAt: new Date(),
          },
        },
      },
      include: { members: true },
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
      name: group.name,
      currency: group.currency,
      establishedAt: group.establishedAt,
      historicalDataStartsAt: group.historicalDataStartsAt,
      currentUserRole: GroupRole.GROUP_ADMIN,
      nextStep: "FINANCIAL_YEAR",
    };
  }

  async previewJoinCode(invitationCode: string) {
    const invitation = await this.prisma.groupInvitation.findUnique({
      where: { tokenHash: this.hash(invitationCode) },
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
      invitationCode,
      group: {
        id: invitation.group.id,
        name: invitation.group.name,
        membersCount: invitation.group._count.members,
      },
      roleOnJoin: invitation.role,
    };
  }

  async joinGroup(user: AuthenticatedUser, input: JoinGroupDto) {
    return this.prisma.$transaction(
      async (tx) => {
        const invitation = await tx.groupInvitation.findUnique({
          where: { tokenHash: this.hash(input.invitationCode) },
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
    const [group, membersCount, paid, outstanding] = await Promise.all([
      this.prisma.group.findUniqueOrThrow({ where: { id: groupId } }),
      this.prisma.groupMember.count({ where: { groupId } }),
      this.prisma.groupContributionPayment.aggregate({
        where: { groupId, status: "APPROVED" },
        _sum: { amountMinor: true },
      }),
      this.prisma.memberContributionObligation.aggregate({
        where: { member: { groupId } },
        _sum: { amountDueMinor: true, amountPaidMinor: true },
      }),
    ]);
    const due = outstanding._sum.amountDueMinor ?? 0;
    const paidObligations = outstanding._sum.amountPaidMinor ?? 0;
    return {
      groupId,
      role: membership.role,
      groupName: group.name,
      metrics: {
        membersCount,
        collectedMinor: paid._sum.amountMinor ?? 0,
        outstandingMinor: Math.max(due - paidObligations, 0),
      },
    };
  }

  async listMembers(user: AuthenticatedUser, groupId: string) {
    await this.requireMembership(user, groupId);
    const members = await this.prisma.groupMember.findMany({
      where: { groupId },
      orderBy: [{ fullName: "asc" }],
    });
    return { members };
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
    const memberNumber = this.optionalTrim(input.memberNumber);
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
    const token = randomBytes(18).toString("base64url");
    const { member, invitation } = await this.prisma.$transaction(
      async (tx) => {
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
        return { member: createdMember, invitation: createdInvitation };
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
        const token = randomBytes(18).toString("base64url");
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
        obligations: true,
        payments: { orderBy: { createdAt: "desc" } },
      },
    });
    if (!member) throw new NotFoundException("Member not found.");
    return member;
  }

  async assignRole(
    user: AuthenticatedUser,
    groupId: string,
    memberId: string,
    input: AssignRoleDto,
  ) {
    await this.requireMembership(user, groupId, [GroupRole.GROUP_ADMIN]);
    return this.prisma.groupMember.update({
      where: { id: memberId },
      data: { role: input.role },
    });
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
    const obligations = await this.prisma.memberContributionObligation.findMany(
      {
        where: {
          member: {
            groupId,
            ...(canSeeAllObligations ? {} : { id: membership.id }),
          },
        },
        include: { member: true, plan: true, period: true },
        orderBy: [{ dueAt: "asc" }],
      },
    );
    return { groupId, obligations };
  }

  async contributionPayments(user: AuthenticatedUser, groupId: string) {
    const membership = await this.requireMembership(user, groupId);
    const canReviewPayments = membership.role === GroupRole.TREASURER;

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
      GroupRole.TREASURER,
    ]);
    if (reviewer.id === input.memberId)
      throw new ForbiddenException(
        "Submit your own payment for another treasurer to verify.",
      );
    await this.ensureGroupMember(groupId, input.memberId);
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
      if (group.establishedAt && paidAt < group.establishedAt) {
        throw new BadRequestException(
          "Historical payment dates cannot be before the group established date.",
        );
      }
    });

    const created = await this.prisma.$transaction(
      payments.map((payment) => {
        const paidAt = new Date(payment.paidAt);
        return this.prisma.groupContributionPayment.create({
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
      }),
    );

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
      GroupRole.TREASURER,
    ]);
    return this.prisma.$transaction(
      async (tx) => {
        const payment = await tx.groupContributionPayment.findFirstOrThrow({
          where: { id: paymentId, groupId },
        });
        if (
          payment.createdByUserId === user.id ||
          payment.groupMemberId === membership.id
        )
          throw new ForbiddenException(
            "Another treasurer must verify this payment.",
          );
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
    await this.requireMembership(user, groupId, [GroupRole.TREASURER]);
    const payment = await this.findGroupPayment(groupId, paymentId);
    if (
      ![
        GroupContributionPaymentStatus.SUBMITTED,
        GroupContributionPaymentStatus.PENDING_VERIFICATION,
        GroupContributionPaymentStatus.CORRECTION_REQUESTED,
      ].some((status) => status === payment.status)
    ) {
      throw new ConflictException("Only pending payments can be rejected.");
    }
    const updated = await this.prisma.groupContributionPayment.update({
      where: { id: payment.id, status: payment.status },
      data: {
        reviewedByUserId: user.id,
        reviewedAt: new Date(),
        status: GroupContributionPaymentStatus.REJECTED,
        reversalReason: input.reason,
      },
    });
    await this.auditPaymentReview(
      user,
      groupId,
      payment.id,
      AuditAction.GROUP_CONTRIBUTION_PAYMENT_REJECTED,
      input.reason,
    );
    return updated;
  }

  async requestPaymentCorrection(
    user: AuthenticatedUser,
    groupId: string,
    paymentId: string,
    input: ReviewContributionPaymentDto,
  ) {
    await this.requireMembership(user, groupId, [GroupRole.TREASURER]);
    const payment = await this.findGroupPayment(groupId, paymentId);
    if (
      ![
        GroupContributionPaymentStatus.SUBMITTED,
        GroupContributionPaymentStatus.PENDING_VERIFICATION,
      ].some((status) => status === payment.status)
    ) {
      throw new ConflictException("Only pending payments can be corrected.");
    }
    const updated = await this.prisma.groupContributionPayment.update({
      where: { id: payment.id, status: payment.status },
      data: {
        reviewedByUserId: user.id,
        reviewedAt: new Date(),
        status: GroupContributionPaymentStatus.CORRECTION_REQUESTED,
        correctionMessage: input.reason,
      },
    });
    await this.auditPaymentReview(
      user,
      groupId,
      payment.id,
      AuditAction.GROUP_CONTRIBUTION_PAYMENT_CORRECTION_REQUESTED,
      input.reason,
    );
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
    return {
      packages: await this.prisma.platformPrice.findMany({
        where: { isActive: true, channel: "SMS" },
        orderBy: [{ channel: "asc" }, { amountMinor: "asc" }],
      }),
    };
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
    if (reminderPackage.channel !== "SMS")
      throw new BadRequestException(
        "Only SMS packages are available until WhatsApp is connected.",
      );

    const amountMinor = reminderPackage.amountMinor * input.quantity;
    const customer = await this.billingProvider.createCustomer({
      groupId,
      name: group.name,
      email: input.buyerEmail ?? identity.email,
      phone: input.buyerPhone ?? identity.phone,
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
        quantity: input.quantity,
      },
      successUrl: input.successUrl,
      cancelUrl: input.cancelUrl,
      buyerEmail: input.buyerEmail ?? identity.email,
      buyerName: input.buyerName ?? group.name,
      buyerPhone: input.buyerPhone ?? identity.phone,
    });
    const purchase = await this.prisma.reminderPackagePurchase.create({
      data: {
        groupId,
        platformPriceId: reminderPackage.id,
        createdByUserId: user.id,
        provider: this.billingProvider.provider,
        providerCheckoutId: checkout.providerSessionId,
        quantity: input.quantity,
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
          quantity: input.quantity,
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
            dueAt: { lt: this.startOfDay(new Date()) },
            status: {
              in: [
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
          select: { id: true },
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
    await this.requireMembership(user, groupId, [GroupRole.TREASURER]);
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
    await this.requireMembership(user, groupId, [GroupRole.TREASURER]);
    const application = await this.prisma.loanApplication.findFirst({
      where: { id: applicationId, groupId },
      select: { id: true, status: true, requestedByUserId: true },
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
      membership.role === GroupRole.TREASURER
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
    const updated = await this.prisma.loanGuarantor.updateMany({
      where: {
        id: guaranteeId,
        groupMemberId: membership.id,
        status: LoanGuarantorStatus.PENDING,
        application: { groupId, status: LoanApplicationStatus.SUBMITTED },
      },
      data: {
        status: accept
          ? LoanGuarantorStatus.CONFIRMED
          : LoanGuarantorStatus.DECLINED,
        confirmedAt: accept ? new Date() : null,
      },
    });
    if (updated.count !== 1)
      throw new ConflictException(
        "Guarantee request is unavailable or already answered.",
      );
    return { accepted: accept };
  }

  async reviewLoanRepayment(
    user: AuthenticatedUser,
    groupId: string,
    repaymentId: string,
    approve: boolean,
  ) {
    const membership = await this.requireMembership(user, groupId, [
      GroupRole.TREASURER,
    ]);
    return this.prisma.$transaction(
      async (tx) => {
        const repayment = await tx.loanRepayment.findFirst({
          where: { id: repaymentId, groupId },
          include: { loan: true },
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
        return updated;
      },
      { isolationLevel: "Serializable" },
    );
  }

  private canReviewLoans(role: GroupRole): boolean {
    return role === GroupRole.TREASURER;
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

  private async requireMembership(
    user: AuthenticatedUser,
    groupId: string,
    allowedRoles?: GroupRole[],
  ) {
    const membership = await this.prisma.groupMember.findFirst({
      where: { userId: user.id, groupId, status: GroupMemberStatus.ACTIVE },
    });
    if (!membership) throw new ForbiddenException("Group access denied.");
    if (allowedRoles && !allowedRoles.includes(membership.role)) {
      throw new ForbiddenException("Role is not allowed for this action.");
    }
    return membership;
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
            status: {
              in: [
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

    for (const plan of plans) {
      await db.memberContributionObligation.updateMany({
        where: {
          planId: plan.id,
          amountPaidMinor: 0,
          dueAt: { gt: new Date() },
          allocations: { none: {} },
          status: ContributionObligationStatus.DUE,
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
                  status: ContributionObligationStatus.DUE,
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
  ): Promise<void> {
    const member = await this.prisma.groupMember.findFirst({
      where: { id: memberId, groupId, status: GroupMemberStatus.ACTIVE },
      select: { id: true },
    });
    if (!member) throw new NotFoundException("Member not found.");
  }

  private async findGroupPayment(groupId: string, paymentId: string) {
    const payment = await this.prisma.groupContributionPayment.findFirst({
      where: { id: paymentId, groupId },
    });
    if (!payment) throw new NotFoundException("Payment not found.");
    return payment;
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
    return tx.groupMember.update({
      where: { id: member.id },
      data: {
        userId: user.id,
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

  private daysFromNow(days: number): Date {
    return new Date(Date.now() + days * 24 * 60 * 60_000);
  }
}
