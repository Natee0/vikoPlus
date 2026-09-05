import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Put,
  Query,
} from "@nestjs/common";
import { ApiBearerAuth, ApiTags } from "@nestjs/swagger";
import { Throttle } from "@nestjs/throttler";

import { CurrentUser } from "../common/auth/auth-user.decorator";
import { AuthenticatedUser } from "../common/auth/authenticated-user";
import { GroupsService } from "./groups.service";
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
  LoanDecisionDto,
  PreviewJoinCodeDto,
  RecordContributionPaymentDto,
  RecordLoanRepaymentDto,
  ReminderSettingsDto,
  ReviewContributionPaymentDto,
  ReviewLoanApplicationDto,
  SendReminderDto,
  SubmitContributionPaymentRequestDto,
  UpdateLanguageDto,
} from "./dto/group.dto";

@ApiBearerAuth()
@ApiTags("groups")
@Controller({ path: "", version: "1" })
export class GroupsController {
  constructor(private readonly groups: GroupsService) {}

  @Patch("me/language")
  @Throttle({ default: { limit: 30, ttl: 60000, blockDuration: 60000 } })
  updateLanguage(
    @CurrentUser() user: AuthenticatedUser,
    @Body() body: UpdateLanguageDto,
  ) {
    return this.groups.updateLanguage(user, body);
  }

  @Get("me/groups")
  myGroups(@CurrentUser() user: AuthenticatedUser) {
    return this.groups.myGroups(user);
  }

  @Post("groups")
  @Throttle({ default: { limit: 10, ttl: 60000, blockDuration: 300000 } })
  createGroup(
    @CurrentUser() user: AuthenticatedUser,
    @Body() body: CreateGroupDto,
  ) {
    return this.groups.createGroup(user, body);
  }

  @Get("groups/join/preview")
  @Throttle({ default: { limit: 20, ttl: 60000, blockDuration: 300000 } })
  previewJoinCode(@Query() query: PreviewJoinCodeDto) {
    return this.groups.previewJoinCode(query.code);
  }

  @Post("groups/join")
  @Throttle({ default: { limit: 10, ttl: 60000, blockDuration: 300000 } })
  joinGroup(
    @CurrentUser() user: AuthenticatedUser,
    @Body() body: JoinGroupDto,
  ) {
    return this.groups.joinGroup(user, body);
  }

  @Get("groups/:groupId/onboarding")
  onboarding(
    @CurrentUser() user: AuthenticatedUser,
    @Param("groupId") groupId: string,
  ) {
    return this.groups.onboarding(user, groupId);
  }

  @Get("groups/:groupId/financial-years")
  financialYears(
    @CurrentUser() user: AuthenticatedUser,
    @Param("groupId") groupId: string,
  ) {
    return this.groups.financialYears(user, groupId);
  }

  @Put("groups/:groupId/financial-year")
  @Throttle({ default: { limit: 20, ttl: 60000, blockDuration: 120000 } })
  saveFinancialYear(
    @CurrentUser() user: AuthenticatedUser,
    @Param("groupId") groupId: string,
    @Body() body: FinancialYearDto,
  ) {
    return this.groups.saveFinancialYear(user, groupId, body);
  }

  @Put("groups/:groupId/contribution-settings")
  @Throttle({ default: { limit: 20, ttl: 60000, blockDuration: 120000 } })
  saveContributionSettings(
    @CurrentUser() user: AuthenticatedUser,
    @Param("groupId") groupId: string,
    @Body() body: ContributionSettingsDto,
  ) {
    return this.groups.saveContributionSettings(user, groupId, body);
  }

  @Put("groups/:groupId/reminder-settings")
  @Throttle({ default: { limit: 20, ttl: 60000, blockDuration: 120000 } })
  saveReminderSettings(
    @CurrentUser() user: AuthenticatedUser,
    @Param("groupId") groupId: string,
    @Body() body: ReminderSettingsDto,
  ) {
    return this.groups.saveReminderSettings(user, groupId, body);
  }

  @Get("groups/:groupId/dashboard")
  dashboard(
    @CurrentUser() user: AuthenticatedUser,
    @Param("groupId") groupId: string,
  ) {
    return this.groups.dashboard(user, groupId);
  }

  @Get("groups/:groupId/members")
  listMembers(
    @CurrentUser() user: AuthenticatedUser,
    @Param("groupId") groupId: string,
  ) {
    return this.groups.listMembers(user, groupId);
  }

  @Post("groups/:groupId/members")
  @Throttle({ default: { limit: 30, ttl: 60000, blockDuration: 120000 } })
  addMember(
    @CurrentUser() user: AuthenticatedUser,
    @Param("groupId") groupId: string,
    @Body() body: AddMemberDto,
  ) {
    return this.groups.addMember(user, groupId, body);
  }

  @Post("groups/:groupId/invitations")
  @Throttle({ default: { limit: 10, ttl: 60000, blockDuration: 300000 } })
  inviteMembers(
    @CurrentUser() user: AuthenticatedUser,
    @Param("groupId") groupId: string,
    @Body() body: InviteMembersDto,
  ) {
    return this.groups.inviteMembers(user, groupId, body);
  }

  @Get("groups/:groupId/members/:memberId")
  member(
    @CurrentUser() user: AuthenticatedUser,
    @Param("groupId") groupId: string,
    @Param("memberId") memberId: string,
  ) {
    return this.groups.member(user, groupId, memberId);
  }

  @Patch("groups/:groupId/members/:memberId/role")
  @Throttle({ default: { limit: 20, ttl: 60000, blockDuration: 120000 } })
  assignRole(
    @CurrentUser() user: AuthenticatedUser,
    @Param("groupId") groupId: string,
    @Param("memberId") memberId: string,
    @Body() body: AssignRoleDto,
  ) {
    return this.groups.assignRole(user, groupId, memberId, body);
  }

  @Get("groups/:groupId/contributions/register")
  contributionRegister(
    @CurrentUser() user: AuthenticatedUser,
    @Param("groupId") groupId: string,
  ) {
    return this.groups.contributionRegister(user, groupId);
  }

  @Get("groups/:groupId/contributions/payments")
  contributionPayments(
    @CurrentUser() user: AuthenticatedUser,
    @Param("groupId") groupId: string,
  ) {
    return this.groups.contributionPayments(user, groupId);
  }

  @Post("groups/:groupId/contributions/payment-requests")
  @Throttle({ default: { limit: 20, ttl: 60000, blockDuration: 120000 } })
  submitPaymentRequest(
    @CurrentUser() user: AuthenticatedUser,
    @Param("groupId") groupId: string,
    @Body() body: SubmitContributionPaymentRequestDto,
  ) {
    return this.groups.submitPaymentRequest(user, groupId, body);
  }

  @Post("groups/:groupId/contributions/payments")
  @Throttle({ default: { limit: 30, ttl: 60000, blockDuration: 120000 } })
  recordPayment(
    @CurrentUser() user: AuthenticatedUser,
    @Param("groupId") groupId: string,
    @Body() body: RecordContributionPaymentDto,
  ) {
    return this.groups.recordPayment(user, groupId, body);
  }

  @Post("groups/:groupId/contributions/historical-payments")
  @Throttle({ default: { limit: 30, ttl: 60000, blockDuration: 120000 } })
  importHistoricalPayment(
    @CurrentUser() user: AuthenticatedUser,
    @Param("groupId") groupId: string,
    @Body() body: HistoricalContributionPaymentDto,
  ) {
    return this.groups.importHistoricalPayment(user, groupId, body);
  }

  @Post("groups/:groupId/contributions/historical-payments/bulk")
  @Throttle({ default: { limit: 10, ttl: 60000, blockDuration: 300000 } })
  importHistoricalPayments(
    @CurrentUser() user: AuthenticatedUser,
    @Param("groupId") groupId: string,
    @Body() body: ImportHistoricalContributionPaymentsDto,
  ) {
    return this.groups.importHistoricalPayments(user, groupId, body);
  }

  @Post("groups/:groupId/contributions/payments/:paymentId/approve")
  @Throttle({ default: { limit: 30, ttl: 60000, blockDuration: 120000 } })
  approvePayment(
    @CurrentUser() user: AuthenticatedUser,
    @Param("groupId") groupId: string,
    @Param("paymentId") paymentId: string,
    @Body() body: ReviewContributionPaymentDto,
  ) {
    return this.groups.approvePayment(user, groupId, paymentId, body);
  }

  @Post("groups/:groupId/contributions/payments/:paymentId/reject")
  @Throttle({ default: { limit: 30, ttl: 60000, blockDuration: 120000 } })
  rejectPayment(
    @CurrentUser() user: AuthenticatedUser,
    @Param("groupId") groupId: string,
    @Param("paymentId") paymentId: string,
    @Body() body: ReviewContributionPaymentDto,
  ) {
    return this.groups.rejectPayment(user, groupId, paymentId, body);
  }

  @Post("groups/:groupId/contributions/payments/:paymentId/request-correction")
  @Throttle({ default: { limit: 30, ttl: 60000, blockDuration: 120000 } })
  requestPaymentCorrection(
    @CurrentUser() user: AuthenticatedUser,
    @Param("groupId") groupId: string,
    @Param("paymentId") paymentId: string,
    @Body() body: ReviewContributionPaymentDto,
  ) {
    return this.groups.requestPaymentCorrection(user, groupId, paymentId, body);
  }

  @Get("groups/:groupId/receipts/:receiptId")
  receipt(
    @CurrentUser() user: AuthenticatedUser,
    @Param("groupId") groupId: string,
    @Param("receiptId") receiptId: string,
  ) {
    return this.groups.receipt(user, groupId, receiptId);
  }

  @Get("groups/:groupId/reminders/templates")
  reminderTemplates(
    @CurrentUser() user: AuthenticatedUser,
    @Param("groupId") groupId: string,
  ) {
    return this.groups.reminderTemplates(user, groupId);
  }

  @Get("groups/:groupId/reminder-packages")
  reminderPackages(
    @CurrentUser() user: AuthenticatedUser,
    @Param("groupId") groupId: string,
  ) {
    return this.groups.reminderPackages(user, groupId);
  }

  @Post("groups/:groupId/reminder-packages/checkout")
  @Throttle({ default: { limit: 10, ttl: 60000, blockDuration: 300000 } })
  createReminderPackageCheckout(
    @CurrentUser() user: AuthenticatedUser,
    @Param("groupId") groupId: string,
    @Body() body: CreateReminderPackageCheckoutDto,
  ) {
    return this.groups.createReminderPackageCheckout(user, groupId, body);
  }

  @Get("groups/:groupId/reminders/campaigns")
  reminderCampaigns(
    @CurrentUser() user: AuthenticatedUser,
    @Param("groupId") groupId: string,
  ) {
    return this.groups.reminderCampaigns(user, groupId);
  }

  @Post("groups/:groupId/reminders/send")
  @Throttle({ default: { limit: 5, ttl: 60000, blockDuration: 300000 } })
  sendReminder(
    @CurrentUser() user: AuthenticatedUser,
    @Param("groupId") groupId: string,
    @Body() body: SendReminderDto,
  ) {
    return this.groups.sendReminder(user, groupId, body);
  }

  @Get("groups/:groupId/loans/overview")
  loansOverview(
    @CurrentUser() user: AuthenticatedUser,
    @Param("groupId") groupId: string,
  ) {
    return this.groups.loansOverview(user, groupId);
  }

  @Get("groups/:groupId/loans/tasks")
  loanTasksEntry(
    @CurrentUser() user: AuthenticatedUser,
    @Param("groupId") groupId: string,
  ) {
    return this.groups.loanTasks(user, groupId);
  }

  @Get("groups/:groupId/payment-rules")
  paymentRules(
    @CurrentUser() user: AuthenticatedUser,
    @Param("groupId") groupId: string,
  ) {
    return this.groups.paymentRules(user, groupId);
  }

  @Put("groups/:groupId/payment-rules")
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  savePaymentRules(
    @CurrentUser() user: AuthenticatedUser,
    @Param("groupId") groupId: string,
    @Body() body: PaymentRulesDto,
  ) {
    return this.groups.savePaymentRules(user, groupId, body);
  }

  @Get("groups/:groupId/reminder-settings")
  reminderSettings(
    @CurrentUser() user: AuthenticatedUser,
    @Param("groupId") groupId: string,
  ) {
    return this.groups.reminderSettings(user, groupId);
  }

  @Post("groups/:groupId/loans/guarantees/:guaranteeId/respond")
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  respondToGuarantee(
    @CurrentUser() user: AuthenticatedUser,
    @Param("groupId") groupId: string,
    @Param("guaranteeId") guaranteeId: string,
    @Body() body: LoanDecisionDto,
  ) {
    return this.groups.respondToGuarantee(
      user,
      groupId,
      guaranteeId,
      body.approve,
    );
  }

  @Post("groups/:groupId/loans/repayments/:repaymentId/review")
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  reviewLoanRepayment(
    @CurrentUser() user: AuthenticatedUser,
    @Param("groupId") groupId: string,
    @Param("repaymentId") repaymentId: string,
    @Body() body: LoanDecisionDto,
  ) {
    return this.groups.reviewLoanRepayment(
      user,
      groupId,
      repaymentId,
      body.approve,
    );
  }

  @Post("groups/:groupId/loans/applications")
  @Throttle({ default: { limit: 10, ttl: 60000, blockDuration: 300000 } })
  createLoanApplication(
    @CurrentUser() user: AuthenticatedUser,
    @Param("groupId") groupId: string,
    @Body() body: CreateLoanApplicationDto,
  ) {
    return this.groups.createLoanApplication(user, groupId, body);
  }

  @Get("groups/:groupId/loans/applications")
  listLoanApplications(
    @CurrentUser() user: AuthenticatedUser,
    @Param("groupId") groupId: string,
  ) {
    return this.groups.listLoanApplications(user, groupId);
  }

  @Get("groups/:groupId/loans/applications/:applicationId")
  loanApplication(
    @CurrentUser() user: AuthenticatedUser,
    @Param("groupId") groupId: string,
    @Param("applicationId") applicationId: string,
  ) {
    return this.groups.loanApplication(user, groupId, applicationId);
  }

  @Post("groups/:groupId/loans/applications/:applicationId/approve")
  @Throttle({ default: { limit: 30, ttl: 60000, blockDuration: 120000 } })
  approveLoanApplication(
    @CurrentUser() user: AuthenticatedUser,
    @Param("groupId") groupId: string,
    @Param("applicationId") applicationId: string,
    @Body() body: ReviewLoanApplicationDto,
  ) {
    return this.groups.approveLoanApplication(
      user,
      groupId,
      applicationId,
      body,
    );
  }

  @Post("groups/:groupId/loans/applications/:applicationId/reject")
  @Throttle({ default: { limit: 30, ttl: 60000, blockDuration: 120000 } })
  rejectLoanApplication(
    @CurrentUser() user: AuthenticatedUser,
    @Param("groupId") groupId: string,
    @Param("applicationId") applicationId: string,
    @Body() body: ReviewLoanApplicationDto,
  ) {
    return this.groups.rejectLoanApplication(
      user,
      groupId,
      applicationId,
      body,
    );
  }

  @Get("groups/:groupId/loans/:loanId/repayment")
  loanRepayment(
    @CurrentUser() user: AuthenticatedUser,
    @Param("groupId") groupId: string,
    @Param("loanId") loanId: string,
  ) {
    return this.groups.loanRepayment(user, groupId, loanId);
  }

  @Post("groups/:groupId/loans/:loanId/repayments")
  @Throttle({ default: { limit: 20, ttl: 60000, blockDuration: 120000 } })
  recordLoanRepayment(
    @CurrentUser() user: AuthenticatedUser,
    @Param("groupId") groupId: string,
    @Param("loanId") loanId: string,
    @Body() body: RecordLoanRepaymentDto,
  ) {
    return this.groups.recordLoanRepayment(user, groupId, loanId, body);
  }

  @Get("notifications")
  notifications(@CurrentUser() user: AuthenticatedUser) {
    return this.groups.notifications(user);
  }

  @Patch("notifications/:notificationId/read")
  markNotificationRead(
    @CurrentUser() user: AuthenticatedUser,
    @Param("notificationId") notificationId: string,
  ) {
    return this.groups.markNotificationRead(user, notificationId);
  }

  @Get("groups/:groupId/settings")
  settings(
    @CurrentUser() user: AuthenticatedUser,
    @Param("groupId") groupId: string,
  ) {
    return this.groups.settings(user, groupId);
  }

  @Get("groups/:groupId/audit-log")
  auditLog(
    @CurrentUser() user: AuthenticatedUser,
    @Param("groupId") groupId: string,
  ) {
    return this.groups.auditLog(user, groupId);
  }
}
