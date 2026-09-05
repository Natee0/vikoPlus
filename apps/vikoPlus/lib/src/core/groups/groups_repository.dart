import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';

final groupsRepositoryProvider = Provider<GroupsRepository>((ref) {
  return GroupsRepository(ref.watch(apiClientProvider));
});

final activeGroupProvider =
    NotifierProvider<ActiveGroupNotifier, GroupAccessSummary?>(
      ActiveGroupNotifier.new,
    );

final selectedContributionPaymentProvider = NotifierProvider<
    SelectedContributionPaymentNotifier, SelectedContributionPayment?>(
  SelectedContributionPaymentNotifier.new,
);

class ActiveGroupNotifier extends Notifier<GroupAccessSummary?> {
  @override
  GroupAccessSummary? build() => null;

  void setGroup(GroupAccessSummary group) {
    state = group;
  }

  void clear() {
    state = null;
  }
}

class SelectedContributionPaymentNotifier
    extends Notifier<SelectedContributionPayment?> {
  @override
  SelectedContributionPayment? build() => null;

  void set(SelectedContributionPayment payment) {
    state = payment;
  }

  void clear() {
    state = null;
  }
}

class GroupsRepository {
  const GroupsRepository(this._dio);

  final Dio _dio;

  Future<CreateGroupResult> createGroup(CreateGroupInput input) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/groups',
      data: input.toJson(),
    );
    return CreateGroupResult.fromJson(_responseBody(response.data));
  }

  Future<MyGroupsResult> myGroups() async {
    final response = await _dio.get<Map<String, dynamic>>('/me/groups');
    return MyGroupsResult.fromJson(_responseBody(response.data));
  }

  Future<JoinGroupPreview> previewJoinCode(String code) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/groups/join/preview',
      queryParameters: {'code': code.trim()},
    );
    return JoinGroupPreview.fromJson(_responseBody(response.data));
  }

  Future<JoinGroupResult> joinGroup(String invitationCode) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/groups/join',
      data: {'invitationCode': invitationCode.trim()},
    );
    return JoinGroupResult.fromJson(_responseBody(response.data));
  }

  Future<void> saveFinancialYear(
    String groupId,
    FinancialYearInput input,
  ) async {
    await _dio.put<Map<String, dynamic>>(
      '/groups/$groupId/financial-year',
      data: input.toJson(),
    );
  }

  Future<GroupFinancialYearsResult> financialYears(String groupId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/groups/$groupId/financial-years',
    );
    return GroupFinancialYearsResult.fromJson(_responseBody(response.data));
  }

  Future<void> saveContributionSettings(
    String groupId,
    ContributionSettingsInput input,
  ) async {
    await _dio.put<Map<String, dynamic>>(
      '/groups/$groupId/contribution-settings',
      data: input.toJson(),
    );
  }

  Future<void> saveReminderSettings(
    String groupId,
    ReminderSettingsInput input,
  ) async {
    await _dio.put<Map<String, dynamic>>(
      '/groups/$groupId/reminder-settings',
      data: input.toJson(),
    );
  }

  Future<ReminderPackagesResult> reminderPackages(String groupId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/groups/$groupId/reminder-packages',
    );
    return ReminderPackagesResult.fromJson(_responseBody(response.data));
  }

  Future<ReminderPackageCheckoutResult> createReminderPackageCheckout(
    String groupId,
    ReminderPackageCheckoutInput input,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/groups/$groupId/reminder-packages/checkout',
      data: input.toJson(),
    );
    return ReminderPackageCheckoutResult.fromJson(
      _responseBody(response.data),
    );
  }

  Future<SendReminderResult> sendReminder(
    String groupId,
    SendReminderInput input,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/groups/$groupId/reminders/send',
      data: input.toJson(),
    );
    return SendReminderResult.fromJson(_responseBody(response.data));
  }

  Future<GroupDashboardResult> dashboard(String groupId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/groups/$groupId/dashboard',
    );
    return GroupDashboardResult.fromJson(_responseBody(response.data));
  }

  Future<ContributionReportResult> contributionReport(
    String groupId, {
    String? financialYearId,
  }) async {
    final query = <String, dynamic>{};
    final selectedFinancialYearId = _nonEmpty(financialYearId);
    if (selectedFinancialYearId != null) {
      query['financialYearId'] = selectedFinancialYearId;
    }
    final response = await _dio.get<Map<String, dynamic>>(
      '/groups/$groupId/reports/contributions/summary',
      queryParameters: query.isEmpty ? null : query,
    );
    return ContributionReportResult.fromJson(_responseBody(response.data));
  }

  Future<ContributionReportExportResult> exportContributionReport(
    String groupId, {
    String? financialYearId,
    String? memberStatus,
    String format = 'csv',
  }) async {
    final query = <String, dynamic>{'format': format};
    final selectedFinancialYearId = _nonEmpty(financialYearId);
    final selectedMemberStatus = _nonEmpty(memberStatus);
    if (selectedFinancialYearId != null) {
      query['financialYearId'] = selectedFinancialYearId;
    }
    if (selectedMemberStatus != null) {
      query['memberStatus'] = selectedMemberStatus;
    }

    final response = await _dio.get<Map<String, dynamic>>(
      '/groups/$groupId/reports/contributions/export',
      queryParameters: query,
    );
    return ContributionReportExportResult.fromJson(
      _responseBody(response.data),
    );
  }

  Future<ContributionRegisterResult> contributionRegister(
    String groupId,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/groups/$groupId/contributions/register',
    );
    return ContributionRegisterResult.fromJson(_responseBody(response.data));
  }

  Future<GroupMembersResult> listMembers(String groupId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/groups/$groupId/members',
    );
    return GroupMembersResult.fromJson(_responseBody(response.data));
  }

  Future<GroupMemberSummary> member(String groupId, String memberId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/groups/$groupId/members/$memberId',
    );
    return GroupMemberSummary.fromJson(_responseBody(response.data));
  }

  Future<void> importHistoricalPayment(
    String groupId,
    HistoricalPaymentInput input,
  ) async {
    await _dio.post<Map<String, dynamic>>(
      '/groups/$groupId/contributions/historical-payments',
      data: input.toJson(),
    );
  }

  Future<ContributionPaymentsResult> contributionPayments(
    String groupId,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/groups/$groupId/contributions/payments',
    );
    return ContributionPaymentsResult.fromJson(_responseBody(response.data));
  }

  Future<ContributionPaymentSummary> submitPaymentRequest(
    String groupId,
    SubmitPaymentRequestInput input,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/groups/$groupId/contributions/payment-requests',
      data: input.toJson(),
    );
    return ContributionPaymentSummary.fromJson(_responseBody(response.data));
  }

  Future<ContributionPaymentSummary> recordPayment(
    String groupId,
    RecordPaymentInput input,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/groups/$groupId/contributions/payments',
      data: input.toJson(),
    );
    return ContributionPaymentSummary.fromJson(_responseBody(response.data));
  }

  Future<ContributionPaymentSummary> approvePayment(
    String groupId,
    String paymentId, {
    String? reason,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/groups/$groupId/contributions/payments/$paymentId/approve',
      data: ReviewPaymentInput(reason: reason).toJson(),
    );
    return ContributionPaymentSummary.fromJson(_responseBody(response.data));
  }

  Future<ContributionPaymentSummary> rejectPayment(
    String groupId,
    String paymentId, {
    String? reason,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/groups/$groupId/contributions/payments/$paymentId/reject',
      data: ReviewPaymentInput(reason: reason).toJson(),
    );
    return ContributionPaymentSummary.fromJson(_responseBody(response.data));
  }

  Future<ContributionPaymentSummary> requestPaymentCorrection(
    String groupId,
    String paymentId, {
    String? reason,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/groups/$groupId/contributions/payments/$paymentId/request-correction',
      data: ReviewPaymentInput(reason: reason).toJson(),
    );
    return ContributionPaymentSummary.fromJson(_responseBody(response.data));
  }

  Future<ReceiptSummary> receipt(String groupId, String receiptId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/groups/$groupId/receipts/$receiptId',
    );
    return ReceiptSummary.fromJson(_responseBody(response.data));
  }

  Future<GroupMemberSummary> addMember(
    String groupId,
    AddMemberInput input,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/groups/$groupId/members',
      data: input.toJson(),
    );
    return GroupMemberSummary.fromJson(_responseBody(response.data));
  }

  Future<InviteMembersResult> inviteMembers(
    String groupId,
    InviteMembersInput input,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/groups/$groupId/invitations',
      data: input.toJson(),
    );
    return InviteMembersResult.fromJson(_responseBody(response.data));
  }

  Future<GroupMemberSummary> assignRole(
    String groupId,
    String memberId,
    String role,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/groups/$groupId/members/$memberId/role',
      data: {'role': role},
    );
    return GroupMemberSummary.fromJson(_responseBody(response.data));
  }

  Future<NotificationsResult> notifications() async {
    final response = await _dio.get<Map<String, dynamic>>('/notifications');
    return NotificationsResult.fromJson(_responseBody(response.data));
  }

  Future<NotificationSummary> markNotificationRead(
    String notificationId,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/notifications/$notificationId/read',
    );
    return NotificationSummary.fromJson(_responseBody(response.data));
  }

  Future<AuditLogResult> auditLog(String groupId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/groups/$groupId/audit-log',
    );
    return AuditLogResult.fromJson(_responseBody(response.data));
  }

  Map<String, dynamic> _responseBody(Map<String, dynamic>? json) {
    if (json == null) {
      throw const FormatException('API returned an empty response.');
    }

    final data = json['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }

    return json;
  }
}

class CreateGroupInput {
  const CreateGroupInput({
    required this.name,
    this.type,
    this.description,
    this.location,
    this.currency = 'TZS',
    this.establishedAt,
    this.historicalDataStartsAt,
  });

  final String name;
  final String? type;
  final String? description;
  final String? location;
  final String currency;
  final DateTime? establishedAt;
  final DateTime? historicalDataStartsAt;

  Map<String, dynamic> toJson() {
    return {
      'name': name.trim(),
      'type': _nonEmpty(type),
      'description': _nonEmpty(description),
      'location': _nonEmpty(location),
      'currency': currency.trim().toUpperCase(),
      'establishedAt': establishedAt?.toIso8601String(),
      'historicalDataStartsAt': historicalDataStartsAt?.toIso8601String(),
    };
  }

  String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

class CreateGroupResult {
  const CreateGroupResult({
    required this.id,
    required this.name,
    required this.currency,
    required this.currentUserRole,
    required this.nextStep,
  });

  factory CreateGroupResult.fromJson(Map<String, dynamic> json) {
    return CreateGroupResult(
      id: _requiredString(json, 'id'),
      name: _requiredString(json, 'name'),
      currency: json['currency'] as String? ?? 'TZS',
      currentUserRole: json['currentUserRole'] as String? ?? 'GROUP_ADMIN',
      nextStep: json['nextStep'] as String? ?? 'FINANCIAL_YEAR',
    );
  }

  final String id;
  final String name;
  final String currency;
  final String currentUserRole;
  final String nextStep;
}

class MyGroupsResult {
  const MyGroupsResult({required this.groups});

  factory MyGroupsResult.fromJson(Map<String, dynamic> json) {
    final items = json['groups'];
    return MyGroupsResult(
      groups: items is List
          ? items
              .whereType<Map>()
              .map((item) => GroupAccessSummary.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
          : const [],
    );
  }

  final List<GroupAccessSummary> groups;
}

class GroupAccessSummary {
  const GroupAccessSummary({
    required this.id,
    required this.name,
    required this.role,
    required this.status,
    required this.membersCount,
  });

  factory GroupAccessSummary.fromJson(Map<String, dynamic> json) {
    return GroupAccessSummary(
      id: _requiredString(json, 'id'),
      name: _requiredString(json, 'name'),
      role: json['role'] as String? ?? 'MEMBER',
      status: json['status'] as String? ?? 'ACTIVE',
      membersCount: json['membersCount'] as int? ?? 0,
    );
  }

  final String id;
  final String name;
  final String role;
  final String status;
  final int membersCount;
}

class JoinGroupPreview {
  const JoinGroupPreview({
    required this.invitationCode,
    required this.group,
    required this.roleOnJoin,
  });

  factory JoinGroupPreview.fromJson(Map<String, dynamic> json) {
    final group = json['group'];
    if (group is! Map) {
      throw const FormatException('Invitation response did not include group.');
    }

    return JoinGroupPreview(
      invitationCode: _requiredString(json, 'invitationCode'),
      group: JoinGroupSummary.fromJson(Map<String, dynamic>.from(group)),
      roleOnJoin: json['roleOnJoin'] as String? ?? 'MEMBER',
    );
  }

  final String invitationCode;
  final JoinGroupSummary group;
  final String roleOnJoin;
}

class JoinGroupSummary {
  const JoinGroupSummary({
    required this.id,
    required this.name,
    required this.membersCount,
  });

  factory JoinGroupSummary.fromJson(Map<String, dynamic> json) {
    return JoinGroupSummary(
      id: _requiredString(json, 'id'),
      name: _requiredString(json, 'name'),
      membersCount: json['membersCount'] as int? ?? 0,
    );
  }

  final String id;
  final String name;
  final int membersCount;
}

class JoinGroupResult {
  const JoinGroupResult({
    required this.groupId,
    required this.membershipId,
    required this.role,
    required this.status,
  });

  factory JoinGroupResult.fromJson(Map<String, dynamic> json) {
    return JoinGroupResult(
      groupId: _requiredString(json, 'groupId'),
      membershipId: _requiredString(json, 'membershipId'),
      role: json['role'] as String? ?? 'MEMBER',
      status: json['status'] as String? ?? 'ACTIVE',
    );
  }

  final String groupId;
  final String membershipId;
  final String role;
  final String status;
}

class FinancialYearInput {
  const FinancialYearInput({
    required this.name,
    required this.startsAt,
    required this.endsAt,
  });

  final String name;
  final DateTime startsAt;
  final DateTime endsAt;

  Map<String, dynamic> toJson() {
    return {
      'name': name.trim(),
      'startsAt': startsAt.toIso8601String(),
      'endsAt': endsAt.toIso8601String(),
    };
  }
}

class GroupFinancialYearsResult {
  const GroupFinancialYearsResult({
    required this.groupId,
    required this.financialYears,
  });

  factory GroupFinancialYearsResult.fromJson(Map<String, dynamic> json) {
    final items = json['financialYears'];
    return GroupFinancialYearsResult(
      groupId: _requiredString(json, 'groupId'),
      financialYears: items is List
          ? items
              .whereType<Map>()
              .map((item) => GroupFinancialYearSummary.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
          : const [],
    );
  }

  final String groupId;
  final List<GroupFinancialYearSummary> financialYears;
}

class GroupFinancialYearSummary {
  const GroupFinancialYearSummary({
    required this.id,
    required this.name,
    required this.startsAt,
    required this.endsAt,
    required this.isActive,
  });

  factory GroupFinancialYearSummary.fromJson(Map<String, dynamic> json) {
    return GroupFinancialYearSummary(
      id: _requiredString(json, 'id'),
      name: _requiredString(json, 'name'),
      startsAt: _parseDate(json['startsAt']) ?? DateTime.now(),
      endsAt: _parseDate(json['endsAt']) ?? DateTime.now(),
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  final String id;
  final String name;
  final DateTime startsAt;
  final DateTime endsAt;
  final bool isActive;
}

class ContributionSettingsInput {
  const ContributionSettingsInput({
    required this.joiningFeeMinor,
    required this.membershipFeeMinor,
    required this.memberContributionMinor,
    required this.membershipFeeFrequency,
    required this.memberContributionFrequency,
    this.membershipDueDayOfMonth,
    this.memberContributionDueDayOfWeek,
    this.memberContributionDueDaysOfWeek,
    this.memberContributionDueDayOfMonth,
    this.cycleAnchorDate,
  });

  final int joiningFeeMinor;
  final int membershipFeeMinor;
  final int memberContributionMinor;
  final String membershipFeeFrequency;
  final String memberContributionFrequency;
  final int? membershipDueDayOfMonth;
  final int? memberContributionDueDayOfWeek;
  final List<int>? memberContributionDueDaysOfWeek;
  final int? memberContributionDueDayOfMonth;
  final DateTime? cycleAnchorDate;

  Map<String, dynamic> toJson() {
    return {
      'joiningFeeMinor': joiningFeeMinor,
      'membershipFeeMinor': membershipFeeMinor,
      'memberContributionMinor': memberContributionMinor,
      'membershipFeeFrequency': membershipFeeFrequency,
      'memberContributionFrequency': memberContributionFrequency,
      'frequency': memberContributionFrequency,
      'dueDayOfWeek': memberContributionDueDayOfWeek,
      'dueDayOfMonth': memberContributionDueDayOfMonth,
      'membershipDueDayOfMonth': membershipDueDayOfMonth,
      'memberContributionDueDayOfWeek': memberContributionDueDayOfWeek,
      'memberContributionDueDaysOfWeek': memberContributionDueDaysOfWeek,
      'memberContributionDueDayOfMonth': memberContributionDueDayOfMonth,
      'cycleAnchorDate': cycleAnchorDate?.toIso8601String(),
    };
  }
}

class ReminderSettingsInput {
  const ReminderSettingsInput({this.dueReminderTemplate});

  final String? dueReminderTemplate;

  Map<String, dynamic> toJson() {
    final template = dueReminderTemplate?.trim();
    return {
      if (template != null && template.isNotEmpty)
        'dueReminderTemplate': template,
    };
  }
}

class SendReminderInput {
  const SendReminderInput({
    required this.channel,
    required this.message,
    this.memberIds = const [],
  });

  final String channel;
  final String message;
  final List<String> memberIds;

  Map<String, dynamic> toJson() {
    return {
      'channel': channel,
      'message': message.trim(),
      if (memberIds.isNotEmpty) 'memberIds': memberIds,
    };
  }
}

class SendReminderResult {
  const SendReminderResult({
    required this.campaignId,
    required this.channel,
    required this.recipientCount,
    required this.appNotificationsCreated,
    required this.smsSent,
    required this.smsFailed,
    required this.whatsappPending,
    this.sentAt,
  });

  factory SendReminderResult.fromJson(Map<String, dynamic> json) {
    return SendReminderResult(
      campaignId: _requiredString(json, 'campaignId'),
      channel: json['channel'] as String? ?? 'SMS',
      recipientCount: json['recipientCount'] as int? ?? 0,
      appNotificationsCreated: json['appNotificationsCreated'] as int? ?? 0,
      smsSent: json['smsSent'] as int? ?? 0,
      smsFailed: json['smsFailed'] as int? ?? 0,
      whatsappPending: json['whatsappPending'] as int? ?? 0,
      sentAt: DateTime.tryParse(json['sentAt'] as String? ?? ''),
    );
  }

  final String campaignId;
  final String channel;
  final int recipientCount;
  final int appNotificationsCreated;
  final int smsSent;
  final int smsFailed;
  final int whatsappPending;
  final DateTime? sentAt;
}

class ReminderPackagesResult {
  const ReminderPackagesResult({required this.packages});

  factory ReminderPackagesResult.fromJson(Map<String, dynamic> json) {
    final items = json['packages'];
    return ReminderPackagesResult(
      packages: items is List
          ? items
              .whereType<Map>()
              .map((item) => ReminderPackageSummary.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
          : const [],
    );
  }

  final List<ReminderPackageSummary> packages;
}

class ReminderPackageSummary {
  const ReminderPackageSummary({
    required this.id,
    required this.code,
    required this.name,
    required this.amountMinor,
    required this.currency,
    required this.isActive,
    this.description,
    this.channel,
  });

  factory ReminderPackageSummary.fromJson(Map<String, dynamic> json) {
    return ReminderPackageSummary(
      id: _requiredString(json, 'id'),
      code: _requiredString(json, 'code'),
      name: _requiredString(json, 'name'),
      description: json['description'] as String?,
      channel: json['channel'] as String?,
      amountMinor: json['amountMinor'] as int? ?? 0,
      currency: json['currency'] as String? ?? 'TZS',
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  final String id;
  final String code;
  final String name;
  final String? description;
  final String? channel;
  final int amountMinor;
  final String currency;
  final bool isActive;
}

class ReminderPackageCheckoutInput {
  const ReminderPackageCheckoutInput({
    required this.packageCode,
    required this.quantity,
    required this.successUrl,
    required this.cancelUrl,
    this.buyerEmail,
    this.buyerName,
    this.buyerPhone,
  });

  final String packageCode;
  final int quantity;
  final String successUrl;
  final String cancelUrl;
  final String? buyerEmail;
  final String? buyerName;
  final String? buyerPhone;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'packageCode': packageCode.trim(),
      'quantity': quantity,
      'successUrl': successUrl,
      'cancelUrl': cancelUrl,
    };
    final emailValue = _nonEmpty(buyerEmail);
    final nameValue = _nonEmpty(buyerName);
    final phoneValue = _nonEmpty(buyerPhone);
    if (emailValue != null) json['buyerEmail'] = emailValue;
    if (nameValue != null) json['buyerName'] = nameValue;
    if (phoneValue != null) json['buyerPhone'] = phoneValue;
    return json;
  }
}

class ReminderPackageCheckoutResult {
  const ReminderPackageCheckoutResult({
    required this.purchaseId,
    required this.checkoutUrl,
    required this.amountMinor,
    required this.currency,
    this.expiresAt,
  });

  factory ReminderPackageCheckoutResult.fromJson(Map<String, dynamic> json) {
    return ReminderPackageCheckoutResult(
      purchaseId: _requiredString(json, 'purchaseId'),
      checkoutUrl: _requiredString(json, 'checkoutUrl'),
      amountMinor: json['amountMinor'] as int? ?? 0,
      currency: json['currency'] as String? ?? 'TZS',
      expiresAt: _parseDate(json['expiresAt']),
    );
  }

  final String purchaseId;
  final String checkoutUrl;
  final int amountMinor;
  final String currency;
  final DateTime? expiresAt;
}

class GroupDashboardResult {
  const GroupDashboardResult({
    required this.groupId,
    required this.role,
    required this.groupName,
    required this.metrics,
  });

  factory GroupDashboardResult.fromJson(Map<String, dynamic> json) {
    final metrics = json['metrics'];
    return GroupDashboardResult(
      groupId: _requiredString(json, 'groupId'),
      role: json['role'] as String? ?? 'MEMBER',
      groupName: json['groupName'] as String? ?? 'Group',
      metrics: GroupDashboardMetrics.fromJson(
        metrics is Map ? Map<String, dynamic>.from(metrics) : const {},
      ),
    );
  }

  final String groupId;
  final String role;
  final String groupName;
  final GroupDashboardMetrics metrics;
}

class GroupDashboardMetrics {
  const GroupDashboardMetrics({
    required this.membersCount,
    required this.collectedMinor,
    required this.outstandingMinor,
  });

  factory GroupDashboardMetrics.fromJson(Map<String, dynamic> json) {
    return GroupDashboardMetrics(
      membersCount: json['membersCount'] as int? ?? 0,
      collectedMinor: json['collectedMinor'] as int? ?? 0,
      outstandingMinor: json['outstandingMinor'] as int? ?? 0,
    );
  }

  final int membersCount;
  final int collectedMinor;
  final int outstandingMinor;
}

class GroupMembersResult {
  const GroupMembersResult({required this.members});

  factory GroupMembersResult.fromJson(Map<String, dynamic> json) {
    final items = json['members'];
    return GroupMembersResult(
      members: items is List
          ? items
              .whereType<Map>()
              .map((item) => GroupMemberSummary.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
          : const [],
    );
  }

  final List<GroupMemberSummary> members;
}

class GroupMemberSummary {
  const GroupMemberSummary({
    required this.id,
    required this.fullName,
    required this.role,
    required this.status,
    this.memberNumber,
    this.phone,
    this.email,
  });

  factory GroupMemberSummary.fromJson(Map<String, dynamic> json) {
    return GroupMemberSummary(
      id: _requiredString(json, 'id'),
      fullName: _requiredString(json, 'fullName'),
      role: json['role'] as String? ?? 'MEMBER',
      status: json['status'] as String? ?? 'ACTIVE',
      memberNumber: json['memberNumber'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
    );
  }

  final String id;
  final String fullName;
  final String role;
  final String status;
  final String? memberNumber;
  final String? phone;
  final String? email;
}

class HistoricalPaymentInput {
  const HistoricalPaymentInput({
    required this.memberId,
    required this.amountMinor,
    required this.method,
    required this.paidAt,
    this.reference,
  });

  final String memberId;
  final int amountMinor;
  final String method;
  final DateTime paidAt;
  final String? reference;

  Map<String, dynamic> toJson() {
    final trimmedReference = reference?.trim();
    return {
      'memberId': memberId,
      'amountMinor': amountMinor,
      'method': method,
      'paidAt': paidAt.toIso8601String(),
      if (trimmedReference != null && trimmedReference.isNotEmpty)
        'reference': trimmedReference,
    };
  }
}

class SubmitPaymentRequestInput {
  const SubmitPaymentRequestInput({
    required this.amountMinor,
    required this.method,
    this.obligationIds = const [],
    this.reference,
    this.paidAt,
  });

  final int amountMinor;
  final String method;
  final List<String> obligationIds;
  final String? reference;
  final DateTime? paidAt;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'amountMinor': amountMinor,
      'method': method,
    };
    if (obligationIds.isNotEmpty) json['obligationIds'] = obligationIds;
    final referenceValue = _nonEmpty(reference);
    if (referenceValue != null) json['reference'] = referenceValue;
    if (paidAt != null) json['paidAt'] = paidAt!.toIso8601String();
    return json;
  }
}

class RecordPaymentInput {
  const RecordPaymentInput({
    required this.memberId,
    required this.amountMinor,
    required this.method,
    this.obligationIds = const [],
    this.reference,
    this.paidAt,
  });

  final String memberId;
  final int amountMinor;
  final String method;
  final List<String> obligationIds;
  final String? reference;
  final DateTime? paidAt;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'memberId': memberId,
      'amountMinor': amountMinor,
      'method': method,
    };
    if (obligationIds.isNotEmpty) json['obligationIds'] = obligationIds;
    final referenceValue = _nonEmpty(reference);
    if (referenceValue != null) json['reference'] = referenceValue;
    if (paidAt != null) json['paidAt'] = paidAt!.toIso8601String();
    return json;
  }
}

class ReviewPaymentInput {
  const ReviewPaymentInput({this.reason});

  final String? reason;

  Map<String, dynamic> toJson() {
    final reasonValue = _nonEmpty(reason);
    final json = <String, dynamic>{};
    if (reasonValue != null) json['reason'] = reasonValue;
    return json;
  }
}

class ContributionRegisterResult {
  const ContributionRegisterResult({
    required this.groupId,
    required this.obligations,
  });

  factory ContributionRegisterResult.fromJson(Map<String, dynamic> json) {
    final items = json['obligations'];
    return ContributionRegisterResult(
      groupId: _requiredString(json, 'groupId'),
      obligations: items is List
          ? items
              .whereType<Map>()
              .map((item) => ContributionObligationSummary.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
          : const [],
    );
  }

  final String groupId;
  final List<ContributionObligationSummary> obligations;
}

class ContributionObligationSummary {
  const ContributionObligationSummary({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.planId,
    required this.planName,
    required this.planType,
    required this.periodLabel,
    required this.amountDueMinor,
    required this.amountPaidMinor,
    required this.currency,
    required this.status,
    required this.dueAt,
  });

  factory ContributionObligationSummary.fromJson(Map<String, dynamic> json) {
    final member = json['member'];
    final plan = json['plan'];
    final period = json['period'];
    final memberJson =
        member is Map ? Map<String, dynamic>.from(member) : null;
    final planJson = plan is Map ? Map<String, dynamic>.from(plan) : null;
    final periodJson = period is Map ? Map<String, dynamic>.from(period) : null;

    return ContributionObligationSummary(
      id: _requiredString(json, 'id'),
      memberId: json['groupMemberId'] as String? ?? '',
      memberName: memberJson?['fullName'] as String? ?? 'Member',
      planId: json['planId'] as String? ?? '',
      planName: planJson?['name'] as String? ?? 'Contribution',
      planType: planJson?['type'] as String? ?? 'RECURRING',
      periodLabel: periodJson?['label'] as String? ?? 'Current period',
      amountDueMinor: json['amountDueMinor'] as int? ?? 0,
      amountPaidMinor: json['amountPaidMinor'] as int? ?? 0,
      currency: json['currency'] as String? ?? 'TZS',
      status: json['status'] as String? ?? 'DUE',
      dueAt: _parseDate(json['dueAt']) ?? DateTime.now(),
    );
  }

  final String id;
  final String memberId;
  final String memberName;
  final String planId;
  final String planName;
  final String planType;
  final String periodLabel;
  final int amountDueMinor;
  final int amountPaidMinor;
  final String currency;
  final String status;
  final DateTime dueAt;

  int get outstandingMinor => amountDueMinor - amountPaidMinor;
}

class SelectedContributionPayment {
  const SelectedContributionPayment({
    required this.obligations,
    this.method = 'Mobile money',
  });

  final List<ContributionObligationSummary> obligations;
  final String method;

  int get amountMinor => obligations.fold(
        0,
        (total, obligation) => total + obligation.outstandingMinor,
      );

  List<String> get obligationIds =>
      obligations.map((obligation) => obligation.id).toList();

  SelectedContributionPayment copyWith({String? method}) {
    return SelectedContributionPayment(
      obligations: obligations,
      method: method ?? this.method,
    );
  }
}

class ContributionReportResult {
  const ContributionReportResult({
    required this.membersCount,
    required this.totalPaidMinor,
    required this.totalOutstandingMinor,
    required this.joiningFeesPaidMinor,
    required this.recurringPaidMinor,
    required this.periodTotals,
    required this.memberAnalysis,
  });

  factory ContributionReportResult.fromJson(Map<String, dynamic> json) {
    final periodItems = json['periodTotals'];
    final memberItems = json['memberAnalysis'];
    return ContributionReportResult(
      membersCount: json['membersCount'] as int? ?? 0,
      totalPaidMinor: json['totalPaidMinor'] as int? ?? 0,
      totalOutstandingMinor: json['totalOutstandingMinor'] as int? ?? 0,
      joiningFeesPaidMinor: json['joiningFeesPaidMinor'] as int? ?? 0,
      recurringPaidMinor: json['recurringPaidMinor'] as int? ?? 0,
      periodTotals: periodItems is List
          ? periodItems
              .whereType<Map>()
              .map((item) => ContributionPeriodTotal.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
          : const [],
      memberAnalysis: memberItems is List
          ? memberItems
              .whereType<Map>()
              .map((item) => MemberContributionAnalysis.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
          : const [],
    );
  }

  final int membersCount;
  final int totalPaidMinor;
  final int totalOutstandingMinor;
  final int joiningFeesPaidMinor;
  final int recurringPaidMinor;
  final List<ContributionPeriodTotal> periodTotals;
  final List<MemberContributionAnalysis> memberAnalysis;
}

class ContributionReportExportResult {
  const ContributionReportExportResult({
    required this.fileName,
    required this.mimeType,
    required this.format,
    required this.content,
  });

  factory ContributionReportExportResult.fromJson(Map<String, dynamic> json) {
    return ContributionReportExportResult(
      fileName: json['fileName'] as String? ?? 'vikoplus-report.csv',
      mimeType: json['mimeType'] as String? ?? 'text/csv',
      format: json['format'] as String? ?? 'csv',
      content: json['content'] as String? ?? '',
    );
  }

  final String fileName;
  final String mimeType;
  final String format;
  final String content;
}

class ContributionPeriodTotal {
  const ContributionPeriodTotal({
    required this.label,
    required this.sortOrder,
    required this.paidMinor,
  });

  factory ContributionPeriodTotal.fromJson(Map<String, dynamic> json) {
    return ContributionPeriodTotal(
      label: json['label'] as String? ?? 'Period',
      sortOrder: json['sortOrder'] as int? ?? 0,
      paidMinor: json['paidMinor'] as int? ?? 0,
    );
  }

  final String label;
  final int sortOrder;
  final int paidMinor;
}

class MemberContributionAnalysis {
  const MemberContributionAnalysis({
    required this.memberId,
    required this.memberName,
    required this.joiningFeePaidMinor,
    required this.recurringPaidMinor,
    required this.totalPaidMinor,
    required this.outstandingMinor,
    required this.paidRecurringPeriods,
    required this.percentageOfGroupTotal,
    this.memberNumber,
  });

  factory MemberContributionAnalysis.fromJson(Map<String, dynamic> json) {
    return MemberContributionAnalysis(
      memberId: _requiredString(json, 'memberId'),
      memberNumber: json['memberNumber'] as String?,
      memberName: json['memberName'] as String? ?? 'Member',
      joiningFeePaidMinor: json['joiningFeePaidMinor'] as int? ?? 0,
      recurringPaidMinor: json['recurringPaidMinor'] as int? ?? 0,
      totalPaidMinor: json['totalPaidMinor'] as int? ?? 0,
      outstandingMinor: json['outstandingMinor'] as int? ?? 0,
      paidRecurringPeriods: json['paidRecurringPeriods'] as int? ?? 0,
      percentageOfGroupTotal:
          (json['percentageOfGroupTotal'] as num?)?.toDouble() ?? 0,
    );
  }

  final String memberId;
  final String? memberNumber;
  final String memberName;
  final int joiningFeePaidMinor;
  final int recurringPaidMinor;
  final int totalPaidMinor;
  final int outstandingMinor;
  final int paidRecurringPeriods;
  final double percentageOfGroupTotal;
}

class ContributionPaymentsResult {
  const ContributionPaymentsResult({required this.payments});

  factory ContributionPaymentsResult.fromJson(Map<String, dynamic> json) {
    final items = json['payments'];
    return ContributionPaymentsResult(
      payments: items is List
          ? items
              .whereType<Map>()
              .map((item) => ContributionPaymentSummary.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
          : const [],
    );
  }

  final List<ContributionPaymentSummary> payments;
}

class ContributionPaymentSummary {
  const ContributionPaymentSummary({
    required this.id,
    required this.groupId,
    required this.memberId,
    required this.memberName,
    required this.amountMinor,
    required this.currency,
    required this.method,
    required this.status,
    required this.createdAt,
    this.reference,
    this.paidAt,
    this.submittedAt,
    this.reviewedAt,
    this.correctionMessage,
    this.reversalReason,
    this.receipt,
  });

  factory ContributionPaymentSummary.fromJson(Map<String, dynamic> json) {
    final member = json['member'];
    final receipt = json['receipt'];
    final memberJson =
        member is Map ? Map<String, dynamic>.from(member) : null;
    final receiptJson =
        receipt is Map ? Map<String, dynamic>.from(receipt) : null;

    return ContributionPaymentSummary(
      id: _requiredString(json, 'id'),
      groupId: json['groupId'] as String? ?? '',
      memberId: json['groupMemberId'] as String? ?? '',
      memberName: memberJson?['fullName'] as String? ?? 'Member',
      amountMinor: json['amountMinor'] as int? ?? 0,
      currency: json['currency'] as String? ?? 'TZS',
      method: json['method'] as String? ?? 'OTHER',
      status: json['status'] as String? ?? 'SUBMITTED',
      reference: json['reference'] as String?,
      paidAt: _parseDate(json['paidAt']),
      submittedAt: _parseDate(json['submittedAt']),
      reviewedAt: _parseDate(json['reviewedAt']),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      correctionMessage: json['correctionMessage'] as String?,
      reversalReason: json['reversalReason'] as String?,
      receipt:
          receiptJson == null ? null : ReceiptSummary.fromJson(receiptJson),
    );
  }

  final String id;
  final String groupId;
  final String memberId;
  final String memberName;
  final int amountMinor;
  final String currency;
  final String method;
  final String status;
  final DateTime createdAt;
  final String? reference;
  final DateTime? paidAt;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? correctionMessage;
  final String? reversalReason;
  final ReceiptSummary? receipt;
}

class ReceiptSummary {
  const ReceiptSummary({
    required this.id,
    required this.groupId,
    required this.paymentId,
    required this.receiptNumber,
    required this.status,
    required this.issuedAt,
    required this.verificationHash,
    this.payment,
  });

  factory ReceiptSummary.fromJson(Map<String, dynamic> json) {
    final payment = json['payment'];
    final paymentJson =
        payment is Map ? Map<String, dynamic>.from(payment) : null;

    return ReceiptSummary(
      id: _requiredString(json, 'id'),
      groupId: json['groupId'] as String? ?? '',
      paymentId: json['paymentId'] as String? ?? '',
      receiptNumber: json['receiptNumber'] as String? ?? '',
      status: json['status'] as String? ?? 'VALID',
      issuedAt: _parseDate(json['issuedAt']) ?? DateTime.now(),
      verificationHash: json['verificationHash'] as String? ?? '',
      payment: paymentJson == null
          ? null
          : ContributionPaymentSummary.fromJson(paymentJson),
    );
  }

  final String id;
  final String groupId;
  final String paymentId;
  final String receiptNumber;
  final String status;
  final DateTime issuedAt;
  final String verificationHash;
  final ContributionPaymentSummary? payment;
}

class AddMemberInput {
  const AddMemberInput({
    required this.fullName,
    required this.role,
    this.memberNumber,
    this.phone,
    this.email,
  });

  final String fullName;
  final String role;
  final String? memberNumber;
  final String? phone;
  final String? email;

  Map<String, dynamic> toJson() {
    final memberNumberValue = _nonEmpty(memberNumber);
    final phoneValue = _nonEmpty(phone);
    final emailValue = _nonEmpty(email);
    final json = <String, dynamic>{
      'fullName': fullName.trim(),
      'role': role,
    };
    if (memberNumberValue != null) json['memberNumber'] = memberNumberValue;
    if (phoneValue != null) json['phone'] = phoneValue;
    if (emailValue != null) json['email'] = emailValue;
    return json;
  }
}

class InviteMembersInput {
  const InviteMembersInput({required this.recipients, required this.role});

  final List<String> recipients;
  final String role;

  Map<String, dynamic> toJson() {
    return {
      'recipients': recipients
          .map((recipient) => recipient.trim())
          .where((recipient) => recipient.isNotEmpty)
          .toList(),
      'role': role,
    };
  }
}

class InviteMembersResult {
  const InviteMembersResult({
    required this.groupId,
    required this.invitations,
  });

  factory InviteMembersResult.fromJson(Map<String, dynamic> json) {
    final items = json['invitations'];
    return InviteMembersResult(
      groupId: _requiredString(json, 'groupId'),
      invitations: items is List
          ? items
              .whereType<Map>()
              .map((item) => MemberInvitation.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
          : const [],
    );
  }

  final String groupId;
  final List<MemberInvitation> invitations;
}

class MemberInvitation {
  const MemberInvitation({
    required this.id,
    required this.recipient,
    required this.role,
    required this.invitationCode,
    required this.expiresAt,
  });

  factory MemberInvitation.fromJson(Map<String, dynamic> json) {
    return MemberInvitation(
      id: _requiredString(json, 'id'),
      recipient: _requiredString(json, 'recipient'),
      role: json['role'] as String? ?? 'MEMBER',
      invitationCode: _requiredString(json, 'invitationCode'),
      expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? ''),
    );
  }

  final String id;
  final String recipient;
  final String role;
  final String invitationCode;
  final DateTime? expiresAt;
}

class NotificationsResult {
  const NotificationsResult({required this.notifications});

  factory NotificationsResult.fromJson(Map<String, dynamic> json) {
    final items = json['notifications'];
    return NotificationsResult(
      notifications: items is List
          ? items
              .whereType<Map>()
              .map((item) => NotificationSummary.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
          : const [],
    );
  }

  final List<NotificationSummary> notifications;
}

class NotificationSummary {
  const NotificationSummary({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.readAt,
  });

  factory NotificationSummary.fromJson(Map<String, dynamic> json) {
    return NotificationSummary(
      id: _requiredString(json, 'id'),
      title: _requiredString(json, 'title'),
      body: _requiredString(json, 'body'),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      readAt: _parseDate(json['readAt']),
    );
  }

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isUnread => readAt == null;
}

class AuditLogResult {
  const AuditLogResult({required this.entries});

  factory AuditLogResult.fromJson(Map<String, dynamic> json) {
    final items = json['entries'];
    return AuditLogResult(
      entries: items is List
          ? items
              .whereType<Map>()
              .map((item) => AuditLogEntrySummary.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
          : const [],
    );
  }

  final List<AuditLogEntrySummary> entries;
}

class AuditLogEntrySummary {
  const AuditLogEntrySummary({
    required this.id,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.createdAt,
    this.reason,
  });

  factory AuditLogEntrySummary.fromJson(Map<String, dynamic> json) {
    return AuditLogEntrySummary(
      id: _requiredString(json, 'id'),
      action: json['action'] as String? ?? 'AUDIT_EVENT',
      entityType: json['entityType'] as String? ?? 'Record',
      entityId: json['entityId'] as String? ?? '',
      reason: json['reason'] as String?,
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
    );
  }

  final String id;
  final String action;
  final String entityType;
  final String entityId;
  final String? reason;
  final DateTime createdAt;
}

String? _nonEmpty(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.isNotEmpty) return value;
  throw FormatException('API response did not include $key.');
}

DateTime? _parseDate(dynamic value) {
  if (value is String) return DateTime.tryParse(value);
  return null;
}
