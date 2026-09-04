import 'package:flutter_riverpod/flutter_riverpod.dart';

final groupSetupDraftProvider =
    NotifierProvider<GroupSetupDraftNotifier, GroupSetupDraft>(
  GroupSetupDraftNotifier.new,
);

class GroupSetupDraft {
  const GroupSetupDraft({
    this.createdGroupId,
    this.profile = const GroupProfileDraft(),
    this.financialYear = const FinancialYearDraft(),
    this.contributions = const ContributionSettingsDraft(),
  });

  final String? createdGroupId;
  final GroupProfileDraft profile;
  final FinancialYearDraft financialYear;
  final ContributionSettingsDraft contributions;

  GroupSetupDraft copyWith({
    String? createdGroupId,
    GroupProfileDraft? profile,
    FinancialYearDraft? financialYear,
    ContributionSettingsDraft? contributions,
  }) {
    return GroupSetupDraft(
      createdGroupId: createdGroupId ?? this.createdGroupId,
      profile: profile ?? this.profile,
      financialYear: financialYear ?? this.financialYear,
      contributions: contributions ?? this.contributions,
    );
  }
}

class GroupProfileDraft {
  const GroupProfileDraft({
    this.name = '',
    this.type,
    this.description = '',
    this.location = '',
    this.establishedAt,
    this.historicalDataStartsAt,
    this.logoObjectKey,
    this.logoUrl,
    this.localLogoPath,
  });

  final String name;
  final String? type;
  final String description;
  final String location;
  final DateTime? establishedAt;
  final DateTime? historicalDataStartsAt;
  final String? logoObjectKey;
  final String? logoUrl;
  final String? localLogoPath;

  GroupProfileDraft copyWith({
    String? name,
    String? type,
    String? description,
    String? location,
    DateTime? establishedAt,
    DateTime? historicalDataStartsAt,
    String? logoObjectKey,
    String? logoUrl,
    String? localLogoPath,
  }) {
    return GroupProfileDraft(
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      location: location ?? this.location,
      establishedAt: establishedAt ?? this.establishedAt,
      historicalDataStartsAt:
          historicalDataStartsAt ?? this.historicalDataStartsAt,
      logoObjectKey: logoObjectKey ?? this.logoObjectKey,
      logoUrl: logoUrl ?? this.logoUrl,
      localLogoPath: localLogoPath ?? this.localLogoPath,
    );
  }
}

class FinancialYearDraft {
  const FinancialYearDraft({
    this.startMonth = 7,
    this.startDate,
    this.automaticRollover = true,
  });

  final int startMonth;
  final DateTime? startDate;
  final bool automaticRollover;

  FinancialYearDraft copyWith({
    int? startMonth,
    DateTime? startDate,
    bool? automaticRollover,
  }) {
    return FinancialYearDraft(
      startMonth: startMonth ?? this.startMonth,
      startDate: startDate ?? this.startDate,
      automaticRollover: automaticRollover ?? this.automaticRollover,
    );
  }
}

class ContributionSettingsDraft {
  const ContributionSettingsDraft({
    this.joiningFee = '10000',
    this.membershipFee = '5000',
    this.memberContribution = '20000',
    this.membershipFeeFrequency = 'Yearly',
    this.memberContributionFrequency = 'Monthly',
    this.membershipDueDay = 1,
    this.weeklyDays = const [6],
    this.monthlyDay = 5,
    this.joiningFeeEnabled = true,
    this.allowPartialPayments = true,
    this.autoAllocatePayments = true,
  });

  final String joiningFee;
  final String membershipFee;
  final String memberContribution;
  final String membershipFeeFrequency;
  final String memberContributionFrequency;
  final int membershipDueDay;
  final List<int> weeklyDays;
  final int monthlyDay;
  final bool joiningFeeEnabled;
  final bool allowPartialPayments;
  final bool autoAllocatePayments;

  ContributionSettingsDraft copyWith({
    String? joiningFee,
    String? membershipFee,
    String? memberContribution,
    String? membershipFeeFrequency,
    String? memberContributionFrequency,
    int? membershipDueDay,
    List<int>? weeklyDays,
    int? monthlyDay,
    bool? joiningFeeEnabled,
    bool? allowPartialPayments,
    bool? autoAllocatePayments,
  }) {
    return ContributionSettingsDraft(
      joiningFee: joiningFee ?? this.joiningFee,
      membershipFee: membershipFee ?? this.membershipFee,
      memberContribution: memberContribution ?? this.memberContribution,
      membershipFeeFrequency:
          membershipFeeFrequency ?? this.membershipFeeFrequency,
      memberContributionFrequency:
          memberContributionFrequency ?? this.memberContributionFrequency,
      membershipDueDay: membershipDueDay ?? this.membershipDueDay,
      weeklyDays: weeklyDays ?? this.weeklyDays,
      monthlyDay: monthlyDay ?? this.monthlyDay,
      joiningFeeEnabled: joiningFeeEnabled ?? this.joiningFeeEnabled,
      allowPartialPayments: allowPartialPayments ?? this.allowPartialPayments,
      autoAllocatePayments: autoAllocatePayments ?? this.autoAllocatePayments,
    );
  }
}

class GroupSetupDraftNotifier extends Notifier<GroupSetupDraft> {
  @override
  GroupSetupDraft build() => const GroupSetupDraft();

  void updateProfile(GroupProfileDraft profile) {
    state = state.copyWith(profile: profile);
  }

  void updateFinancialYear(FinancialYearDraft financialYear) {
    state = state.copyWith(financialYear: financialYear);
  }

  void updateContributions(ContributionSettingsDraft contributions) {
    state = state.copyWith(contributions: contributions);
  }

  void markGroupCreated(String groupId) {
    state = state.copyWith(createdGroupId: groupId);
  }

  void reset() {
    state = const GroupSetupDraft();
  }
}
