import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';

final loansRepositoryProvider = Provider<LoansRepository>((ref) {
  return LoansRepository(ref.watch(apiClientProvider));
});

class LoansRepository {
  const LoansRepository(this._dio);

  final Dio _dio;

  Future<LoanOverviewResult> overview(String groupId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/groups/$groupId/loans/overview',
    );
    return LoanOverviewResult.fromJson(_responseBody(response.data));
  }

  Future<LoanApplicationSummary> createApplication(
    String groupId,
    CreateLoanApplicationInput input,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/groups/$groupId/loans/applications',
      data: input.toJson(),
    );
    return LoanApplicationSummary.fromJson(_responseBody(response.data));
  }

  Future<LoanApplicationsResult> applications(String groupId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/groups/$groupId/loans/applications',
    );
    return LoanApplicationsResult.fromJson(_responseBody(response.data));
  }

  Future<LoanApplicationSummary> application(
    String groupId,
    String applicationId,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/groups/$groupId/loans/applications/$applicationId',
    );
    return LoanApplicationSummary.fromJson(_responseBody(response.data));
  }

  Future<LoanApplicationSummary> approveApplication(
    String groupId,
    String applicationId, {
    int? approvedAmountMinor,
    String? notes,
  }) async {
    final data = <String, dynamic>{};
    if (approvedAmountMinor != null) {
      data['approvedAmountMinor'] = approvedAmountMinor;
    }
    final trimmedNotes = notes?.trim();
    if (trimmedNotes != null && trimmedNotes.isNotEmpty) {
      data['notes'] = trimmedNotes;
    }

    final response = await _dio.post<Map<String, dynamic>>(
      '/groups/$groupId/loans/applications/$applicationId/approve',
      data: data,
    );
    return LoanApplicationSummary.fromJson(_responseBody(response.data));
  }

  Future<LoanApplicationSummary> rejectApplication(
    String groupId,
    String applicationId, {
    String? reason,
  }) async {
    final data = <String, dynamic>{};
    final trimmedReason = reason?.trim();
    if (trimmedReason != null && trimmedReason.isNotEmpty) {
      data['reason'] = trimmedReason;
    }

    final response = await _dio.post<Map<String, dynamic>>(
      '/groups/$groupId/loans/applications/$applicationId/reject',
      data: data,
    );
    return LoanApplicationSummary.fromJson(_responseBody(response.data));
  }

  Future<LoanRepaymentResult> repayment(String groupId, String loanId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/groups/$groupId/loans/$loanId/repayment',
    );
    return LoanRepaymentResult.fromJson(_responseBody(response.data));
  }

  Future<LoanRepaymentSummary> recordRepayment(
    String groupId,
    String loanId,
    RecordLoanRepaymentInput input,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/groups/$groupId/loans/$loanId/repayments',
      data: input.toJson(),
    );
    return LoanRepaymentSummary.fromJson(_responseBody(response.data));
  }

  Map<String, dynamic> _responseBody(Map<String, dynamic>? json) {
    if (json == null) {
      throw const FormatException('API returned an empty response.');
    }
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    return json;
  }
}

class LoanOverviewResult {
  const LoanOverviewResult({
    required this.groupId,
    required this.currency,
    required this.totalSavingsMinor,
    required this.outstandingMinor,
    required this.activeDefaults,
    required this.creditLimitMinor,
    required this.borrowingPowerMinor,
    required this.tierLabel,
    required this.pendingApplicationsCount,
    required this.activeLoans,
    required this.eligibility,
  });

  factory LoanOverviewResult.fromJson(Map<String, dynamic> json) {
    final loans = json['activeLoans'];
    final eligibility = json['eligibility'];
    return LoanOverviewResult(
      groupId: json['groupId'] as String? ?? '',
      currency: json['currency'] as String? ?? 'TZS',
      totalSavingsMinor: json['totalSavingsMinor'] as int? ?? 0,
      outstandingMinor: json['outstandingMinor'] as int? ?? 0,
      activeDefaults: json['activeDefaults'] as int? ?? 0,
      creditLimitMinor: json['creditLimitMinor'] as int? ?? 0,
      borrowingPowerMinor: json['borrowingPowerMinor'] as int? ?? 0,
      tierLabel: json['tierLabel'] as String? ?? 'Starter',
      pendingApplicationsCount: json['pendingApplicationsCount'] as int? ?? 0,
      activeLoans: loans is List
          ? loans
              .whereType<Map>()
              .map((item) => LoanSummary.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
          : const [],
      eligibility: eligibility is List
          ? eligibility
              .whereType<Map>()
              .map((item) => LoanEligibilityItem.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
          : const [],
    );
  }

  final String groupId;
  final String currency;
  final int totalSavingsMinor;
  final int outstandingMinor;
  final int activeDefaults;
  final int creditLimitMinor;
  final int borrowingPowerMinor;
  final String tierLabel;
  final int pendingApplicationsCount;
  final List<LoanSummary> activeLoans;
  final List<LoanEligibilityItem> eligibility;
}

class LoanSummary {
  const LoanSummary({
    required this.id,
    required this.amountMinor,
    required this.totalPayableMinor,
    required this.amountPaidMinor,
    required this.outstandingMinor,
    required this.currency,
    required this.purpose,
    required this.termMonths,
    required this.monthlyInterestRateBps,
    required this.status,
    this.disbursedAt,
    this.dueAt,
  });

  factory LoanSummary.fromJson(Map<String, dynamic> json) {
    return LoanSummary(
      id: json['id'] as String? ?? '',
      amountMinor: json['amountMinor'] as int? ?? 0,
      totalPayableMinor: json['totalPayableMinor'] as int? ?? 0,
      amountPaidMinor: json['amountPaidMinor'] as int? ?? 0,
      outstandingMinor: json['outstandingMinor'] as int? ?? 0,
      currency: json['currency'] as String? ?? 'TZS',
      purpose: json['purpose'] as String? ?? 'Group loan',
      termMonths: json['termMonths'] as int? ?? 0,
      monthlyInterestRateBps: json['monthlyInterestRateBps'] as int? ?? 0,
      status: json['status'] as String? ?? 'ACTIVE',
      disbursedAt: _parseDate(json['disbursedAt']),
      dueAt: _parseDate(json['dueAt']),
    );
  }

  final String id;
  final int amountMinor;
  final int totalPayableMinor;
  final int amountPaidMinor;
  final int outstandingMinor;
  final String currency;
  final String purpose;
  final int termMonths;
  final int monthlyInterestRateBps;
  final String status;
  final DateTime? disbursedAt;
  final DateTime? dueAt;
}

class LoanEligibilityItem {
  const LoanEligibilityItem({required this.label, required this.achieved});

  factory LoanEligibilityItem.fromJson(Map<String, dynamic> json) {
    return LoanEligibilityItem(
      label: json['label'] as String? ?? '',
      achieved: json['achieved'] as bool? ?? false,
    );
  }

  final String label;
  final bool achieved;
}

class LoanApplicationsResult {
  const LoanApplicationsResult({required this.groupId, required this.applications});

  factory LoanApplicationsResult.fromJson(Map<String, dynamic> json) {
    final items = json['applications'];
    return LoanApplicationsResult(
      groupId: json['groupId'] as String? ?? '',
      applications: items is List
          ? items
              .whereType<Map>()
              .map((item) => LoanApplicationSummary.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
          : const [],
    );
  }

  final String groupId;
  final List<LoanApplicationSummary> applications;
}

class LoanApplicationSummary {
  const LoanApplicationSummary({
    required this.id,
    required this.amountMinor,
    required this.currency,
    required this.purpose,
    required this.termMonths,
    required this.monthlyInterestRateBps,
    required this.processingFeeMinor,
    required this.estimatedTotalPayableMinor,
    required this.status,
    required this.applicant,
    required this.guarantors,
    required this.guarantorSummary,
    this.approvedAmountMinor,
    this.reviewNotes,
    this.rejectionReason,
    this.createdAt,
  });

  factory LoanApplicationSummary.fromJson(Map<String, dynamic> json) {
    final applicant = json['applicant'];
    final guarantors = json['guarantors'];
    final guarantorSummary = json['guarantorSummary'];
    return LoanApplicationSummary(
      id: json['id'] as String? ?? '',
      amountMinor: json['amountMinor'] as int? ?? 0,
      approvedAmountMinor: json['approvedAmountMinor'] as int?,
      currency: json['currency'] as String? ?? 'TZS',
      purpose: json['purpose'] as String? ?? 'Group loan',
      termMonths: json['termMonths'] as int? ?? 0,
      monthlyInterestRateBps: json['monthlyInterestRateBps'] as int? ?? 0,
      processingFeeMinor: json['processingFeeMinor'] as int? ?? 0,
      estimatedTotalPayableMinor:
          json['estimatedTotalPayableMinor'] as int? ?? 0,
      status: json['status'] as String? ?? 'SUBMITTED',
      reviewNotes: json['reviewNotes'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      createdAt: _parseDate(json['createdAt']),
      applicant: applicant is Map
          ? LoanMemberSummary.fromJson(Map<String, dynamic>.from(applicant))
          : const LoanMemberSummary(id: '', fullName: 'Member'),
      guarantors: guarantors is List
          ? guarantors
              .whereType<Map>()
              .map((item) => LoanGuarantorSummary.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
          : const [],
      guarantorSummary: guarantorSummary is Map
          ? GuarantorSummary.fromJson(
              Map<String, dynamic>.from(guarantorSummary),
            )
          : const GuarantorSummary(confirmed: 0, required: 2, total: 0),
    );
  }

  final String id;
  final int amountMinor;
  final int? approvedAmountMinor;
  final String currency;
  final String purpose;
  final int termMonths;
  final int monthlyInterestRateBps;
  final int processingFeeMinor;
  final int estimatedTotalPayableMinor;
  final String status;
  final String? reviewNotes;
  final String? rejectionReason;
  final DateTime? createdAt;
  final LoanMemberSummary applicant;
  final List<LoanGuarantorSummary> guarantors;
  final GuarantorSummary guarantorSummary;
}

class LoanMemberSummary {
  const LoanMemberSummary({
    required this.id,
    required this.fullName,
    this.memberNumber,
    this.status,
  });

  factory LoanMemberSummary.fromJson(Map<String, dynamic> json) {
    return LoanMemberSummary(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? 'Member',
      memberNumber: json['memberNumber'] as String?,
      status: json['status'] as String?,
    );
  }

  final String id;
  final String fullName;
  final String? memberNumber;
  final String? status;
}

class LoanGuarantorSummary {
  const LoanGuarantorSummary({
    required this.id,
    required this.status,
    required this.member,
  });

  factory LoanGuarantorSummary.fromJson(Map<String, dynamic> json) {
    final member = json['member'];
    return LoanGuarantorSummary(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      member: member is Map
          ? LoanMemberSummary.fromJson(Map<String, dynamic>.from(member))
          : const LoanMemberSummary(id: '', fullName: 'Member'),
    );
  }

  final String id;
  final String status;
  final LoanMemberSummary member;
}

class GuarantorSummary {
  const GuarantorSummary({
    required this.confirmed,
    required this.required,
    required this.total,
  });

  factory GuarantorSummary.fromJson(Map<String, dynamic> json) {
    return GuarantorSummary(
      confirmed: json['confirmed'] as int? ?? 0,
      required: json['required'] as int? ?? 2,
      total: json['total'] as int? ?? 0,
    );
  }

  final int confirmed;
  final int required;
  final int total;
}

class LoanRepaymentResult {
  const LoanRepaymentResult({required this.loan, required this.repayments});

  factory LoanRepaymentResult.fromJson(Map<String, dynamic> json) {
    final loan = json['loan'];
    final repayments = json['repayments'];
    return LoanRepaymentResult(
      loan: loan is Map
          ? LoanSummary.fromJson(Map<String, dynamic>.from(loan))
          : const LoanSummary(
              id: '',
              amountMinor: 0,
              totalPayableMinor: 0,
              amountPaidMinor: 0,
              outstandingMinor: 0,
              currency: 'TZS',
              purpose: 'Group loan',
              termMonths: 0,
              monthlyInterestRateBps: 0,
              status: 'ACTIVE',
            ),
      repayments: repayments is List
          ? repayments
              .whereType<Map>()
              .map((item) => LoanRepaymentSummary.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
          : const [],
    );
  }

  final LoanSummary loan;
  final List<LoanRepaymentSummary> repayments;
}

class LoanRepaymentSummary {
  const LoanRepaymentSummary({
    required this.id,
    required this.amountMinor,
    required this.currency,
    required this.method,
    required this.status,
    this.reference,
    this.paidAt,
    this.createdAt,
  });

  factory LoanRepaymentSummary.fromJson(Map<String, dynamic> json) {
    return LoanRepaymentSummary(
      id: json['id'] as String? ?? '',
      amountMinor: json['amountMinor'] as int? ?? 0,
      currency: json['currency'] as String? ?? 'TZS',
      method: json['method'] as String? ?? 'CASH',
      status: json['status'] as String? ?? 'SUBMITTED',
      reference: json['reference'] as String?,
      paidAt: _parseDate(json['paidAt']),
      createdAt: _parseDate(json['createdAt']),
    );
  }

  final String id;
  final int amountMinor;
  final String currency;
  final String method;
  final String status;
  final String? reference;
  final DateTime? paidAt;
  final DateTime? createdAt;
}

class CreateLoanApplicationInput {
  const CreateLoanApplicationInput({
    required this.amountMinor,
    required this.purpose,
    required this.termMonths,
    required this.guarantorMemberIds,
  });

  final int amountMinor;
  final String purpose;
  final int termMonths;
  final List<String> guarantorMemberIds;

  Map<String, dynamic> toJson() {
    return {
      'amountMinor': amountMinor,
      'purpose': purpose.trim(),
      'termMonths': termMonths,
      'guarantorMemberIds': guarantorMemberIds,
    };
  }
}

class RecordLoanRepaymentInput {
  const RecordLoanRepaymentInput({
    required this.amountMinor,
    required this.method,
    this.reference,
    this.paidAt,
  });

  final int amountMinor;
  final String method;
  final String? reference;
  final DateTime? paidAt;

  Map<String, dynamic> toJson() {
    final trimmedReference = reference?.trim();
    return {
      'amountMinor': amountMinor,
      'method': method,
      if (trimmedReference != null && trimmedReference.isNotEmpty)
        'reference': trimmedReference,
      'paidAt': paidAt?.toIso8601String(),
    };
  }
}

DateTime? _parseDate(dynamic value) {
  if (value is String) return DateTime.tryParse(value);
  return null;
}
