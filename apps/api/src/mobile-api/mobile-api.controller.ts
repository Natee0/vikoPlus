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
import { ApiTags } from "@nestjs/swagger";

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
import { MobileApiService } from "./mobile-api.service";

@ApiTags("mobile-ui-contract")
@Controller({ path: "", version: "1" })
export class MobileApiController {
  constructor(private readonly mobileApi: MobileApiService) {}

  @Get("mobile/bootstrap")
  bootstrap() {
    return this.mobileApi.bootstrap();
  }

  @Post("auth/register")
  register(@Body() body: RegisterDto) {
    return this.mobileApi.register(body);
  }

  @Post("auth/login")
  login(@Body() body: LoginDto) {
    return this.mobileApi.login(body);
  }

  @Post("auth/verify-otp")
  verifyOtp(@Body() body: VerifyOtpDto) {
    return this.mobileApi.verifyOtp(body);
  }

  @Post("auth/logout")
  logout() {
    return { status: "LOGGED_OUT" };
  }

  @Get("me")
  currentUser() {
    return this.mobileApi.currentUser();
  }

  @Get("me/groups")
  myGroups() {
    return this.mobileApi.myGroups();
  }

  @Patch("me/language")
  updateLanguage(@Body() body: UpdateLanguageDto) {
    return this.mobileApi.updateLanguage(body);
  }

  @Post("groups")
  createGroup(@Body() body: CreateGroupDto) {
    return this.mobileApi.createGroup(body);
  }

  @Get("groups/join/preview")
  previewJoinCode(@Query("code") code = "SOFIA-2026") {
    return this.mobileApi.previewJoinCode(code);
  }

  @Post("groups/join")
  joinGroup(@Body() body: JoinGroupDto) {
    return this.mobileApi.joinGroup(body);
  }

  @Get("groups/:groupId/onboarding")
  onboarding(@Param("groupId") groupId: string) {
    return this.mobileApi.onboarding(groupId);
  }

  @Put("groups/:groupId/financial-year")
  saveFinancialYear(
    @Param("groupId") groupId: string,
    @Body() body: FinancialYearDto,
  ) {
    return this.mobileApi.saveFinancialYear(groupId, body);
  }

  @Put("groups/:groupId/contribution-settings")
  saveContributionSettings(
    @Param("groupId") groupId: string,
    @Body() body: ContributionSettingsDto,
  ) {
    return this.mobileApi.saveContributionSettings(groupId, body);
  }

  @Put("groups/:groupId/reminder-settings")
  saveReminderSettings(
    @Param("groupId") groupId: string,
    @Body() body: ReminderSettingsDto,
  ) {
    return this.mobileApi.saveReminderSettings(groupId, body);
  }

  @Get("groups/:groupId/dashboard/:role")
  dashboard(@Param("groupId") groupId: string, @Param("role") role: string) {
    return this.mobileApi.dashboard(groupId, role);
  }

  @Get("groups/:groupId/members")
  listMembers() {
    return this.mobileApi.listMembers();
  }

  @Post("groups/:groupId/members")
  addMember(@Param("groupId") groupId: string, @Body() body: AddMemberDto) {
    return this.mobileApi.addMember(groupId, body);
  }

  @Post("groups/:groupId/invitations")
  inviteMembers(
    @Param("groupId") groupId: string,
    @Body() body: InviteMembersDto,
  ) {
    return this.mobileApi.inviteMembers(groupId, body);
  }

  @Get("groups/:groupId/members/:memberId")
  member(@Param("memberId") memberId: string) {
    return this.mobileApi.member(memberId);
  }

  @Patch("groups/:groupId/members/:memberId/role")
  assignRole(@Param("memberId") memberId: string, @Body() body: AssignRoleDto) {
    return this.mobileApi.assignRole(memberId, body);
  }

  @Post("groups/:groupId/members/:memberId/reminders")
  remindMember(
    @Param("groupId") groupId: string,
    @Param("memberId") memberId: string,
    @Body() body: SendReminderDto,
  ) {
    return this.mobileApi.sendReminder(groupId, {
      ...body,
      memberIds: [memberId],
    });
  }

  @Get("groups/:groupId/contributions/register")
  contributionRegister(@Param("groupId") groupId: string) {
    return this.mobileApi.contributionRegister(groupId);
  }

  @Post("groups/:groupId/contributions/payments")
  recordPayment(
    @Param("groupId") groupId: string,
    @Body() body: RecordContributionPaymentDto,
  ) {
    return this.mobileApi.recordPayment(groupId, body);
  }

  @Get("groups/:groupId/receipts/:receiptId")
  receipt(@Param("receiptId") receiptId: string) {
    return this.mobileApi.receipt(receiptId);
  }

  @Get("groups/:groupId/reminders/templates")
  reminderTemplates() {
    return this.mobileApi.reminderTemplates();
  }

  @Get("groups/:groupId/reminders/campaigns")
  reminderCampaigns() {
    return this.mobileApi.reminderCampaigns();
  }

  @Post("groups/:groupId/reminders/send")
  sendReminder(
    @Param("groupId") groupId: string,
    @Body() body: SendReminderDto,
  ) {
    return this.mobileApi.sendReminder(groupId, body);
  }

  @Get("groups/:groupId/loans/overview")
  loansOverview(@Param("groupId") groupId: string) {
    return this.mobileApi.loansOverview(groupId);
  }

  @Post("groups/:groupId/loans/applications")
  createLoanApplication(
    @Param("groupId") groupId: string,
    @Body() body: CreateLoanApplicationDto,
  ) {
    return this.mobileApi.createLoanApplication(groupId, body);
  }

  @Get("groups/:groupId/loans/applications")
  listLoanApplications() {
    return this.mobileApi.listLoanApplications();
  }

  @Get("groups/:groupId/loans/applications/:applicationId")
  loanApplication(@Param("applicationId") applicationId: string) {
    return this.mobileApi.loanApplication(applicationId);
  }

  @Post("groups/:groupId/loans/applications/:applicationId/approve")
  approveLoanApplication(
    @Param("applicationId") applicationId: string,
    @Body() body: ReviewLoanApplicationDto,
  ) {
    return this.mobileApi.approveLoanApplication(applicationId, body);
  }

  @Post("groups/:groupId/loans/applications/:applicationId/reject")
  rejectLoanApplication(
    @Param("applicationId") applicationId: string,
    @Body() body: ReviewLoanApplicationDto,
  ) {
    return this.mobileApi.rejectLoanApplication(applicationId, body);
  }

  @Get("groups/:groupId/loans/:loanId/repayment")
  loanRepayment(@Param("loanId") loanId: string) {
    return this.mobileApi.loanRepayment(loanId);
  }

  @Post("groups/:groupId/loans/:loanId/repayments")
  recordLoanRepayment(
    @Param("loanId") loanId: string,
    @Body() body: RecordLoanRepaymentDto,
  ) {
    return this.mobileApi.recordLoanRepayment(loanId, body);
  }

  @Get("notifications")
  notifications() {
    return this.mobileApi.notifications();
  }

  @Patch("notifications/:notificationId/read")
  markNotificationRead(@Param("notificationId") notificationId: string) {
    return { notificationId, readAt: new Date().toISOString() };
  }

  @Get("groups/:groupId/settings")
  settings(@Param("groupId") groupId: string) {
    return this.mobileApi.settings(groupId);
  }

  @Get("groups/:groupId/audit-log")
  auditLog(@Param("groupId") groupId: string) {
    return this.mobileApi.auditLog(groupId);
  }
}
