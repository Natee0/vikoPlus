class ContributionRegisterCell {
  ContributionRegisterCell.fromJson(Map<String, dynamic> json)
    : memberId = json['memberId'] as String,
      periodKey = json['periodKey'] as String,
      label = json['label'] as String,
      sortOrder = json['sortOrder'] as int,
      paidMinor = json['paidMinor'] as int;

  final String memberId;
  final String periodKey;
  final String label;
  final int sortOrder;
  final int paidMinor;
}

class ContributionReportRate {
  ContributionReportRate.fromJson(Map<String, dynamic> json)
    : name = json['name'] as String,
      frequency = json['frequency'] as String,
      amountMinor = json['amountMinor'] as int,
      currency = json['currency'] as String;

  final String name;
  final String frequency;
  final int amountMinor;
  final String currency;
}
