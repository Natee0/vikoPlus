import { Injectable, NotFoundException } from "@nestjs/common";

import {
  AddMemberDto,
  AssignRoleDto,
  ContributionSettingsDto,
  CreateGroupDto,
  CreateLoanApplicationDto,
  FinancialYearDto,
  InviteMembersDto,
  JoinGroupDto,
  LoginDto,
  RecordContributionPaymentDto,
  RecordLoanRepaymentDto,
  RegisterDto,
  ReminderSettingsDto,
  ReviewLoanApplicationDto,
  SendReminderDto,
  UpdateLanguageDto,
  VerifyOtpDto,
} from "./dto/mobile-api.dto";

type JsonObject = Record<string, unknown>;

const groupId = "grp_sofia_wajukuu";
const userId = "usr_demo_admin";

const members = [
  {
    id: "mem_aginess",
    memberNumber: "SW-001",
    fullName: "Aginess Lupili",
    initials: "AL",
    role: "MEMBER",
    status: "ACTIVE",
    paidMinor: 0,
    outstandingMinor: 15000,
  },
  {
    id: "mem_boniphace",
    memberNumber: "SW-004",
    fullName: "Boniphace Lupili",
    initials: "BL",
    role: "TREASURER",
    status: "ACTIVE",
    paidMinor: 20000,
    outstandingMinor: 0,
  },
  {
    id: "mem_emmanuel",
    memberNumber: "SW-005",
    fullName: "Emmanuel Malekela Madahula",
    initials: "EM",
    role: "MEMBER",
    status: "ACTIVE",
    paidMinor: 70000,
    outstandingMinor: 0,
  },
  {
    id: "mem_hans",
    memberNumber: "SW-009",
    fullName: "Hans Lupili",
    initials: "HL",
    role: "MEMBER",
    status: "ACTIVE",
    paidMinor: 15000,
    outstandingMinor: 5000,
  },
];

const loanApplications = [
  {
    id: "loan_app_david",
    applicantName: "David Kiprop",
    memberId: "mem_david",
    memberNumber: "VK-4832",
    amountMinor: 500000,
    currency: "TZS",
    purpose: "Business Growth",
    termMonths: 6,
    monthlyInstallmentMinor: 92500,
    interestRateMonthly: 1.5,
    guarantorsConfirmed: 2,
    guarantorsRequired: 2,
    riskLabel: "Low Risk",
    riskScore: 41,
    status: "PENDING_REVIEW",
  },
  {
    id: "loan_app_grace",
    applicantName: "Grace Wanjiku",
    memberId: "mem_grace",
    memberNumber: "VK-4901",
    amountMinor: 250000,
    currency: "TZS",
    purpose: "School Fees",
    termMonths: 2,
    monthlyInstallmentMinor: 128500,
    interestRateMonthly: 1.5,
    guarantorsConfirmed: 1,
    guarantorsRequired: 2,
    riskLabel: "Medium Risk",
    riskScore: 62,
    status: "GUARANTOR_PENDING",
  },
  {
    id: "loan_app_samuel",
    applicantName: "Samuel Otieno",
    memberId: "mem_samuel",
    memberNumber: "VK-4902",
    amountMinor: 1000000,
    currency: "TZS",
    purpose: "Agriculture",
    termMonths: 12,
    monthlyInstallmentMinor: 94000,
    interestRateMonthly: 1.5,
    guarantorsConfirmed: 0,
    guarantorsRequired: 2,
    riskLabel: "High Risk",
    riskScore: 65,
    status: "GUARANTOR_PENDING",
  },
];

@Injectable()
export class MobileApiService {
  bootstrap(): JsonObject {
    return {
      defaultLocale: "en",
      supportedLocales: ["en", "sw"],
      currency: "TZS",
      pricing: {
        annualGroupAccessMinor: 1000000,
        smsReminderMinor: 5000,
        whatsappReminderMinor: 5000,
        smsAndWhatsappReminderMinor: 10000,
      },
      screensCovered: [
        "auth",
        "language",
        "groups",
        "group-onboarding",
        "admin-dashboard",
        "secretary-dashboard",
        "member-dashboard",
        "treasurer-loans",
        "members",
        "contributions",
        "payments",
        "receipts",
        "reports",
        "reminders",
        "settings",
        "notifications",
        "loans",
      ],
    };
  }

  register(body: RegisterDto): JsonObject {
    return {
      user: {
        id: userId,
        displayName: body.fullName,
        preferredLocale: body.preferredLocale ?? "en",
        phone: body.phone ?? null,
        email: body.email ?? null,
        rolePreview: "NEW_USER",
      },
      otpChallenge: {
        id: "otp_demo_register",
        destination: body.phone ?? body.email,
        expiresInSeconds: 300,
      },
    };
  }

  login(body: LoginDto): JsonObject {
    return {
      accessToken: "demo-access-token",
      refreshToken: "demo-refresh-token",
      user: {
        id: userId,
        displayName: "Vikoplus Demo User",
        preferredLocale: "en",
        selectedRole: body.rolePreview ?? "GROUP_ADMIN",
        identifier: body.identifier,
      },
    };
  }

  verifyOtp(body: VerifyOtpDto): JsonObject {
    return {
      challengeId: body.challengeId,
      verified: body.code.length >= 4,
      nextRoute: "/groups",
    };
  }

  updateLanguage(body: UpdateLanguageDto): JsonObject {
    return { userId, preferredLocale: body.locale };
  }

  currentUser(): JsonObject {
    return {
      id: userId,
      displayName: "Vikoplus Demo User",
      preferredLocale: "en",
      rolePreview: "GROUP_ADMIN",
    };
  }

  myGroups(): JsonObject {
    return {
      groups: [
        {
          id: groupId,
          name: "Sofia Wajukuu",
          role: "GROUP_ADMIN",
          status: "ACTIVE",
          membersCount: 23,
        },
        {
          id: "grp_upendo_savings",
          name: "Upendo Savings",
          role: "TREASURER",
          status: "ACTIVE",
          membersCount: 41,
        },
        {
          id: "grp_familia_mshikamano",
          name: "Familia Mshikamano",
          role: "SECRETARY",
          status: "ACTIVE",
          membersCount: 18,
        },
        {
          id: "grp_bima_ya_jamii",
          name: "Bima ya Jamii",
          role: "MEMBER",
          status: "ACTIVE",
          membersCount: 12,
        },
      ],
    };
  }

  createGroup(body: CreateGroupDto): JsonObject {
    return {
      id: "grp_new_demo",
      name: body.name,
      type: body.type ?? "Savings Group",
      description: body.description ?? null,
      location: body.location ?? null,
      currency: body.currency ?? "TZS",
      currentUserRole: "GROUP_ADMIN",
      nextStep: "FINANCIAL_YEAR",
    };
  }

  previewJoinCode(code: string): JsonObject {
    return {
      invitationCode: code,
      group: {
        id: groupId,
        name: "Sofia Wajukuu",
        membersCount: 23,
        inviterName: "Group Administrator",
      },
      roleOnJoin: "MEMBER",
    };
  }

  joinGroup(body: JoinGroupDto): JsonObject {
    return {
      invitationCode: body.invitationCode,
      groupId,
      membershipId: "mem_joined_demo",
      status: "ACTIVE",
      role: "MEMBER",
      nextRoute: "/member/dashboard",
    };
  }

  onboarding(groupIdParam: string): JsonObject {
    return {
      groupId: groupIdParam,
      steps: [
        { code: "GROUP_CREATED", label: "Group Created", completed: true },
        { code: "FINANCIAL_YEAR", label: "Financial Year", completed: true },
        { code: "CONTRIBUTIONS", label: "Contributions", completed: false },
        { code: "REMINDERS", label: "Reminders", completed: false },
        { code: "FIRST_MEMBER", label: "First Member", completed: false },
      ],
    };
  }

  saveFinancialYear(groupIdParam: string, body: FinancialYearDto): JsonObject {
    return {
      id: "fy_2026_2027",
      groupId: groupIdParam,
      ...body,
      isActive: true,
    };
  }

  saveContributionSettings(
    groupIdParam: string,
    body: ContributionSettingsDto,
  ): JsonObject {
    return {
      groupId: groupIdParam,
      currency: "TZS",
      joiningFeeMinor: body.joiningFeeMinor,
      membershipFeeMinor: body.membershipFeeMinor,
      frequency: body.frequency ?? "MONTHLY",
    };
  }

  saveReminderSettings(
    groupIdParam: string,
    body: ReminderSettingsDto,
  ): JsonObject {
    return {
      groupId: groupIdParam,
      channels: {
        sms: {
          enabled: body.smsEnabled,
          priceMinor: body.smsPriceMinor ?? 5000,
        },
        whatsapp: {
          enabled: body.whatsappEnabled,
          priceMinor: body.whatsappPriceMinor ?? 5000,
        },
      },
    };
  }

  dashboard(groupIdParam: string, role: string): JsonObject {
    return {
      groupId: groupIdParam,
      role,
      groupName: "Sofia Wajukuu",
      setupProgress: { completed: 2, total: 5 },
      metrics: {
        membersCount: 23,
        collectedMinor: 65000,
        outstandingMinor: 150000,
        activeLoansMinor: 500000,
      },
      quickActions: ["ADD_MEMBER", "RECORD_PAYMENT", "SEND_REMINDER", "LOANS"],
    };
  }

  listMembers(): JsonObject {
    return { members };
  }

  addMember(groupIdParam: string, body: AddMemberDto): JsonObject {
    return {
      id: "mem_new_demo",
      groupId: groupIdParam,
      fullName: body.fullName,
      phone: body.phone ?? null,
      email: body.email ?? null,
      role: body.role ?? "MEMBER",
      status: "ACTIVE",
    };
  }

  inviteMembers(groupIdParam: string, body: InviteMembersDto): JsonObject {
    return {
      groupId: groupIdParam,
      role: body.role ?? "MEMBER",
      invitations: body.recipients.map((recipient, index) => ({
        id: `invite_${index + 1}`,
        recipient,
        status: "SENT",
      })),
    };
  }

  member(memberId: string): JsonObject {
    const member = members.find((candidate) => candidate.id === memberId);
    if (!member) {
      throw new NotFoundException("Member not found");
    }
    return {
      ...member,
      paymentHistory: [
        {
          id: "pay_1",
          label: "Joining fee",
          amountMinor: 10000,
          status: "PAID",
        },
        {
          id: "pay_2",
          label: "July contribution",
          amountMinor: 5000,
          status: "PAID",
        },
      ],
    };
  }

  assignRole(memberId: string, body: AssignRoleDto): JsonObject {
    return { memberId, role: body.role, status: "UPDATED" };
  }

  contributionRegister(groupIdParam: string): JsonObject {
    return {
      groupId: groupIdParam,
      financialYear: "July 2026 - June 2027",
      period: "July 2026",
      totals: { paidMinor: 65000, outstandingMinor: 150000 },
      members,
    };
  }

  recordPayment(
    groupIdParam: string,
    body: RecordContributionPaymentDto,
  ): JsonObject {
    return {
      id: "pay_demo_latest",
      groupId: groupIdParam,
      memberId: body.memberId,
      amountMinor: body.amountMinor,
      method: body.method,
      reference: body.reference ?? null,
      status: "APPROVED",
      receiptId: "receipt_demo_latest",
    };
  }

  receipt(receiptId: string): JsonObject {
    return {
      id: receiptId,
      receiptNumber: "SW-2026-0001",
      status: "VALID",
      issuedAt: new Date().toISOString(),
      amountMinor: 15000,
      currency: "TZS",
    };
  }

  reminderTemplates(): JsonObject {
    return {
      templates: [
        {
          id: "tpl_due",
          title: "Outstanding dues",
          body: "Dear member, this is a friendly reminder regarding your outstanding dues.",
        },
        {
          id: "tpl_meeting",
          title: "Meeting reminder",
          body: "Please remember the upcoming group meeting.",
        },
      ],
    };
  }

  reminderCampaigns(): JsonObject {
    return {
      campaigns: [
        {
          id: "rem_july_dues",
          title: "July dues reminder",
          channel: "BOTH",
          recipientsCount: 14,
          status: "SENT",
        },
      ],
    };
  }

  sendReminder(groupIdParam: string, body: SendReminderDto): JsonObject {
    const recipientsCount = body.memberIds?.length ?? 14;
    return {
      id: "rem_demo_latest",
      groupId: groupIdParam,
      channel: body.channel,
      message: body.message,
      recipientsCount,
      estimatedCostMinor:
        recipientsCount * (body.channel === "BOTH" ? 10000 : 5000),
      status: "SENT",
    };
  }

  loansOverview(groupIdParam: string): JsonObject {
    return {
      groupId: groupIdParam,
      borrowingPowerMinor: 1200000,
      creditLimitMinor: 5000000,
      tier: "Tier 2 Member",
      activeLoans: [
        {
          id: "loan_active_1",
          title: "Emergency Micro-Loan",
          remainingMinor: 150000,
          paidMinor: 350000,
          nextInstallmentMinor: 75000,
          status: "ON_TRACK",
        },
      ],
      eligibility: [
        "Min. 3 months community membership",
        "Zero active defaults or overdue fees",
        "Minimum monthly savings streak of TZS 50,000",
      ],
    };
  }

  createLoanApplication(
    groupIdParam: string,
    body: CreateLoanApplicationDto,
  ): JsonObject {
    return {
      id: "loan_app_new_demo",
      groupId: groupIdParam,
      amountMinor: body.amountMinor,
      purpose: body.purpose,
      termMonths: body.termMonths,
      guarantorMemberIds: body.guarantorMemberIds,
      status: "PENDING_REVIEW",
    };
  }

  listLoanApplications(): JsonObject {
    return { applications: loanApplications };
  }

  loanApplication(applicationId: string): JsonObject {
    const application = loanApplications.find(
      (candidate) => candidate.id === applicationId,
    );
    if (!application) {
      throw new NotFoundException("Loan application not found");
    }
    return {
      ...application,
      savingsMinor: 1850000,
      activeDefaults: 0,
      guarantors: [
        {
          id: "mem_amina",
          name: "Amina Mwangi",
          status: "CONFIRMED",
          trustScore: 98,
        },
        {
          id: "mem_john",
          name: "John Ochieng",
          status: "CONFIRMED",
          trustScore: 95,
        },
      ],
    };
  }

  approveLoanApplication(
    applicationId: string,
    body: ReviewLoanApplicationDto,
  ): JsonObject {
    return {
      applicationId,
      status: "APPROVED",
      approvedAmountMinor: body.approvedAmountMinor ?? 500000,
      notes: body.notes ?? null,
      disbursementId: "disb_demo_latest",
    };
  }

  rejectLoanApplication(
    applicationId: string,
    body: ReviewLoanApplicationDto,
  ): JsonObject {
    return {
      applicationId,
      status: "REJECTED",
      notes: body.notes ?? null,
    };
  }

  loanRepayment(loanId: string): JsonObject {
    return {
      id: loanId,
      title: "Business Growth Fund",
      remainingMinor: 500000,
      nextInstallmentMinor: 125000,
      repaymentHistory: [
        {
          id: "loan_pay_3",
          amountMinor: 125000,
          provider: "M-Pesa",
          status: "COMPLETED",
        },
        {
          id: "loan_pay_2",
          amountMinor: 125000,
          provider: "M-Pesa",
          status: "COMPLETED",
        },
      ],
    };
  }

  recordLoanRepayment(
    loanId: string,
    body: RecordLoanRepaymentDto,
  ): JsonObject {
    return {
      id: "loan_payment_demo_latest",
      loanId,
      amountMinor: body.amountMinor,
      provider: body.provider,
      reference: body.reference ?? null,
      status: "COMPLETED",
    };
  }

  notifications(): JsonObject {
    return {
      notifications: [
        {
          id: "not_due",
          title: "Outstanding dues",
          body: "14 members have outstanding dues.",
          readAt: null,
        },
      ],
    };
  }

  settings(groupIdParam: string): JsonObject {
    return {
      groupId: groupIdParam,
      currency: "TZS",
      language: "en",
      security: { pinEnabled: false },
      notifications: { sms: true, whatsapp: true, push: true },
    };
  }

  auditLog(groupIdParam: string): JsonObject {
    return {
      groupId: groupIdParam,
      entries: [
        {
          id: "audit_1",
          action: "MEMBER_CREATED",
          actorName: "Group Admin",
          createdAt: new Date().toISOString(),
        },
      ],
    };
  }
}
