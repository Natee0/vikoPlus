import {
  BadRequestException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
  NotImplementedException,
} from "@nestjs/common";
import {
  AuditAction,
  BillingInterval,
  ContributionFrequency,
  ContributionPlanType,
  GroupContributionPaymentStatus,
  GroupMemberStatus,
  GroupRole,
  Locale,
  ReceiptStatus,
} from "@prisma/client";
import { createHash, randomBytes } from "crypto";

import { AuthenticatedUser } from "../common/auth/authenticated-user";
import { PrismaService } from "../prisma/prisma.service";
import { SUBSCRIPTION_BILLING_PROVIDER } from "../billing/billing-provider.token";
import { SubscriptionBillingProvider } from "../billing/subscription-billing-provider";
import {
  AddMemberDto,
  AssignRoleDto,
  ContributionSettingsDto,
  CreateReminderPackageCheckoutDto,
  CreateGroupDto,
  FinancialYearDto,
  HistoricalContributionPaymentDto,
  ImportHistoricalContributionPaymentsDto,
  InviteMembersDto,
  JoinGroupDto,
  RecordContributionPaymentDto,
  ReminderSettingsDto,
  ReviewContributionPaymentDto,
  SendReminderDto,
  SubmitContributionPaymentRequestDto,
  UpdateLanguageDto,
} from "./dto/group.dto";

@Injectable()
export class GroupsService {
  constructor(
    private readonly prisma: PrismaService,
    @Inject(SUBSCRIPTION_BILLING_PROVIDER)
    private readonly billingProvider: SubscriptionBillingProvider,
  ) {}

  async updateLanguage(user: AuthenticatedUser, input: UpdateLanguageDto) {
    const updated = await this.prisma.user.update({
      where: { id: user.id },
      data: { preferredLocale: input.locale === "sw" ? Locale.sw : Locale.en },
    });
    return { userId: updated.id, preferredLocale: updated.preferredLocale };
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
    const invitation = await this.prisma.groupInvitation.findUnique({
      where: { tokenHash: this.hash(input.invitationCode) },
      include: { group: true },
    });
    if (
      !invitation ||
      invitation.acceptedAt ||
      invitation.expiresAt <= new Date()
    ) {
      throw new NotFoundException("Invitation was not found or has expired.");
    }

    const membership = await this.prisma.groupMember.create({
      data: {
        groupId: invitation.groupId,
        userId: user.id,
        fullName: await this.displayName(user.id),
        role: invitation.role,
        status: GroupMemberStatus.ACTIVE,
        joinedAt: new Date(),
      },
    });
    await this.prisma.groupInvitation.update({
      where: { id: invitation.id },
      data: { acceptedAt: new Date() },
    });
    return {
      groupId: invitation.groupId,
      membershipId: membership.id,
      role: membership.role,
      status: membership.status,
    };
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
    await this.prisma.financialYear.updateMany({
      where: { groupId },
      data: { isActive: false },
    });
    return this.prisma.financialYear.create({
      data: {
        groupId,
        name: input.name,
        startsAt: new Date(input.startsAt),
        endsAt: new Date(input.endsAt),
        isActive: true,
      },
    });
  }

  async saveContributionSettings(
    user: AuthenticatedUser,
    groupId: string,
    input: ContributionSettingsDto,
  ) {
    await this.requireMembership(user, groupId, [GroupRole.GROUP_ADMIN]);
    const frequency = (input.frequency ??
      ContributionFrequency.MONTHLY) as ContributionFrequency;
    this.validateContributionCycle(input);
    const cycleData = this.contributionCycleData(input, frequency);
    await Promise.all([
      this.prisma.contributionPlan.upsert({
        where: { groupId_name: { groupId, name: "Joining fee" } },
        update: {
          amountMinor: input.joiningFeeMinor,
          frequency: ContributionFrequency.ONCE,
          type: ContributionPlanType.JOINING_FEE,
        },
        create: {
          groupId,
          name: "Joining fee",
          amountMinor: input.joiningFeeMinor,
          frequency: ContributionFrequency.ONCE,
          type: ContributionPlanType.JOINING_FEE,
        },
      }),
      this.prisma.contributionPlan.upsert({
        where: { groupId_name: { groupId, name: "Membership fee" } },
        update: {
          amountMinor: input.membershipFeeMinor,
          frequency,
          ...cycleData,
          type: ContributionPlanType.RECURRING,
        },
        create: {
          groupId,
          name: "Membership fee",
          amountMinor: input.membershipFeeMinor,
          frequency,
          ...cycleData,
          type: ContributionPlanType.RECURRING,
        },
      }),
    ]);
    return { groupId, ...input, frequency };
  }

  async saveReminderSettings(
    user: AuthenticatedUser,
    groupId: string,
    input: ReminderSettingsDto,
  ) {
    await this.requireMembership(user, groupId, [GroupRole.GROUP_ADMIN]);
    if (!input.dueReminderTemplate) return { groupId, configured: false };
    const template = await this.prisma.reminderTemplate.upsert({
      where: {
        groupId_locale_code: { groupId, locale: Locale.en, code: "dues" },
      },
      update: { body: input.dueReminderTemplate },
      create: {
        groupId,
        locale: Locale.en,
        code: "dues",
        title: "Outstanding dues",
        body: input.dueReminderTemplate,
      },
    });
    return { groupId, configured: true, templateId: template.id };
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
    await this.requireMembership(user, groupId, [GroupRole.GROUP_ADMIN]);
    return this.prisma.groupMember.create({
      data: {
        groupId,
        fullName: input.fullName.trim(),
        phone: input.phone ? this.normalizePhone(input.phone) : null,
        email: input.email?.trim().toLowerCase(),
        role: input.role ?? GroupRole.MEMBER,
        status: GroupMemberStatus.ACTIVE,
        joinedAt: new Date(),
      },
    });
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
    await this.requireMembership(user, groupId);
    const obligations = await this.prisma.memberContributionObligation.findMany(
      {
        where: { member: { groupId } },
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
    const paidAt = input.paidAt ? new Date(input.paidAt) : new Date();
    const payment = await this.prisma.groupContributionPayment.create({
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
    await this.prisma.auditLog.create({
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
    return payment;
  }

  async recordPayment(
    user: AuthenticatedUser,
    groupId: string,
    input: RecordContributionPaymentDto,
  ) {
    await this.requireMembership(user, groupId, [GroupRole.TREASURER]);
    await this.ensureGroupMember(groupId, input.memberId);
    const paidAt = input.paidAt ? new Date(input.paidAt) : new Date();
    const payment = await this.prisma.groupContributionPayment.create({
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
    await this.createReceiptForPayment(groupId, payment.id);
    return this.paymentWithReceipt(payment.id);
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
      payments.map((payment) => this.ensureGroupMember(groupId, payment.memberId)),
    );
    payments.forEach((payment) => {
      const paidAt = new Date(payment.paidAt);
      if (paidAt > now) {
        throw new BadRequestException("Historical payment dates cannot be future dates.");
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
      created.map((payment) => this.createReceiptForPayment(groupId, payment.id)),
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

    return { imported: created.length, paymentIds: created.map((item) => item.id) };
  }

  async approvePayment(
    user: AuthenticatedUser,
    groupId: string,
    paymentId: string,
    input: ReviewContributionPaymentDto,
  ) {
    await this.requireMembership(user, groupId, [GroupRole.TREASURER]);
    const payment = await this.findGroupPayment(groupId, paymentId);
    const approvableStatuses: GroupContributionPaymentStatus[] = [
      GroupContributionPaymentStatus.SUBMITTED,
      GroupContributionPaymentStatus.PENDING_VERIFICATION,
      GroupContributionPaymentStatus.CORRECTION_REQUESTED,
    ];
    if (
      !approvableStatuses.includes(payment.status)
    ) {
      throw new ForbiddenException("Payment cannot be approved from this state.");
    }

    await this.prisma.groupContributionPayment.update({
      where: { id: payment.id },
      data: {
        reviewedByUserId: user.id,
        reviewedAt: new Date(),
        status: GroupContributionPaymentStatus.APPROVED,
        correctionMessage: null,
      },
    });
    await this.createReceiptForPayment(groupId, payment.id);
    await this.auditPaymentReview(
      user,
      groupId,
      payment.id,
      AuditAction.GROUP_CONTRIBUTION_PAYMENT_APPROVED,
      input.reason,
    );
    return this.paymentWithReceipt(payment.id);
  }

  async rejectPayment(
    user: AuthenticatedUser,
    groupId: string,
    paymentId: string,
    input: ReviewContributionPaymentDto,
  ) {
    await this.requireMembership(user, groupId, [GroupRole.TREASURER]);
    const payment = await this.findGroupPayment(groupId, paymentId);
    const updated = await this.prisma.groupContributionPayment.update({
      where: { id: payment.id },
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
    const updated = await this.prisma.groupContributionPayment.update({
      where: { id: payment.id },
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
    await this.requireMembership(user, groupId);
    const receipt = await this.prisma.receipt.findFirst({
      where: { id: receiptId, groupId },
      include: { payment: true },
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
        where: { isActive: true },
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

  sendReminder(
    user: AuthenticatedUser,
    groupId: string,
    input: SendReminderDto,
  ): never {
    void user;
    void groupId;
    void input;
    throw new NotImplementedException(
      "Production reminder dispatch is not implemented yet.",
    );
  }

  loans(): never {
    throw new NotImplementedException(
      "Production loan persistence is not implemented yet.",
    );
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

  private validateContributionCycle(input: ContributionSettingsDto): void {
    const frequency = input.frequency ?? ContributionFrequency.MONTHLY;
    if (frequency === ContributionFrequency.WEEKLY && !input.dueDayOfWeek) {
      throw new BadRequestException(
        "Weekly contributions require a due weekday.",
      );
    }
    const monthlyLikeFrequencies: ContributionFrequency[] = [
      ContributionFrequency.MONTHLY,
      ContributionFrequency.QUARTERLY,
      ContributionFrequency.ANNUAL,
    ];
    if (
      monthlyLikeFrequencies.includes(frequency) &&
      !input.dueDayOfMonth
    ) {
      throw new BadRequestException(
        "Monthly, quarterly, and annual contributions require a due day.",
      );
    }
  }

  private contributionCycleData(
    input: ContributionSettingsDto,
    frequency: ContributionFrequency,
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
        frequency === ContributionFrequency.WEEKLY ? input.dueDayOfWeek! : null,
      dueDayOfMonth: monthlyLikeFrequencies.includes(frequency)
        ? input.dueDayOfMonth!
        : null,
      cycleAnchorDate: input.cycleAnchorDate
        ? new Date(input.cycleAnchorDate)
        : null,
    };
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
  ): Promise<void> {
    const existing = await this.prisma.receipt.findUnique({
      where: { paymentId },
      select: { id: true },
    });
    if (existing) return;

    const receiptNumber = `VKP-${Date.now()}-${randomBytes(3).toString("hex").toUpperCase()}`;
    const verificationHash = createHash("sha256")
      .update(`${groupId}:${paymentId}:${receiptNumber}`)
      .digest("hex");

    await this.prisma.receipt.create({
      data: {
        groupId,
        paymentId,
        receiptNumber,
        status: ReceiptStatus.VALID,
        verificationHash,
      },
    });
    await this.prisma.auditLog.create({
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
  ) {
    return this.prisma.auditLog.create({
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
