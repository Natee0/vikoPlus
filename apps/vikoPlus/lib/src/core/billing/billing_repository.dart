import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';

final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  return BillingRepository(ref.watch(apiClientProvider));
});

class BillingRepository {
  const BillingRepository(this._dio);

  final Dio _dio;

  Future<AccessPlansResult> accessPlans(String groupId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/groups/$groupId/subscription/plans',
    );
    return AccessPlansResult.fromJson(_responseBody(response.data));
  }

  Future<GroupSubscriptionSummary> subscription(String groupId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/groups/$groupId/subscription',
    );
    return GroupSubscriptionSummary.fromJson(_responseBody(response.data));
  }

  Future<BillingCheckoutResult> createAccessCheckout(
    String groupId,
    AccessCheckoutInput input,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/groups/$groupId/subscription/checkout',
      data: input.toJson(),
    );
    return BillingCheckoutResult.fromJson(_responseBody(response.data));
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

class AccessPlansResult {
  const AccessPlansResult({
    required this.groupId,
    required this.plans,
  });

  factory AccessPlansResult.fromJson(Map<String, dynamic> json) {
    final items = json['plans'];
    return AccessPlansResult(
      groupId: _requiredString(json, 'groupId'),
      plans: items is List
          ? items
              .whereType<Map>()
              .map((item) => AccessPlanSummary.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
          : const [],
    );
  }

  final String groupId;
  final List<AccessPlanSummary> plans;
}

class AccessPlanSummary {
  const AccessPlanSummary({
    required this.id,
    required this.code,
    required this.name,
    required this.priceMinor,
    required this.currency,
    required this.interval,
    required this.intervalCount,
    required this.trialDays,
    this.description,
  });

  factory AccessPlanSummary.fromJson(Map<String, dynamic> json) {
    return AccessPlanSummary(
      id: _requiredString(json, 'id'),
      code: _requiredString(json, 'code'),
      name: _requiredString(json, 'name'),
      description: json['description'] as String?,
      priceMinor: json['priceMinor'] as int? ?? 0,
      currency: json['currency'] as String? ?? 'TZS',
      interval: json['interval'] as String? ?? 'MONTH',
      intervalCount: json['intervalCount'] as int? ?? 1,
      trialDays: json['trialDays'] as int? ?? 0,
    );
  }

  final String id;
  final String code;
  final String name;
  final String? description;
  final int priceMinor;
  final String currency;
  final String interval;
  final int intervalCount;
  final int trialDays;
}

class AccessCheckoutInput {
  const AccessCheckoutInput({
    required this.planCode,
    required this.successUrl,
    required this.cancelUrl,
    this.buyerEmail,
    this.buyerName,
    this.buyerPhone,
  });

  final String planCode;
  final String successUrl;
  final String cancelUrl;
  final String? buyerEmail;
  final String? buyerName;
  final String? buyerPhone;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'planCode': planCode,
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

class GroupSubscriptionSummary {
  const GroupSubscriptionSummary({
    required this.id,
    required this.groupId,
    required this.planCode,
    required this.state,
    required this.hasPaidFeatureAccess,
    required this.cancelAtPeriodEnd,
    this.currentPeriodEndsAt,
  });

  factory GroupSubscriptionSummary.fromJson(Map<String, dynamic> json) {
    return GroupSubscriptionSummary(
      id: _requiredString(json, 'id'),
      groupId: _requiredString(json, 'groupId'),
      planCode: _requiredString(json, 'planCode'),
      state: json['state'] as String? ?? 'TRIAL',
      hasPaidFeatureAccess: json['hasPaidFeatureAccess'] as bool? ?? false,
      currentPeriodEndsAt: _parseDate(json['currentPeriodEndsAt']),
      cancelAtPeriodEnd: json['cancelAtPeriodEnd'] as bool? ?? false,
    );
  }

  final String id;
  final String groupId;
  final String planCode;
  final String state;
  final bool hasPaidFeatureAccess;
  final DateTime? currentPeriodEndsAt;
  final bool cancelAtPeriodEnd;
}

class BillingCheckoutResult {
  const BillingCheckoutResult({
    required this.checkoutUrl,
    this.expiresAt,
  });

  factory BillingCheckoutResult.fromJson(Map<String, dynamic> json) {
    return BillingCheckoutResult(
      checkoutUrl: _requiredString(json, 'checkoutUrl'),
      expiresAt: _parseDate(json['expiresAt']),
    );
  }

  final String checkoutUrl;
  final DateTime? expiresAt;
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
