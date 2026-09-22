import 'dart:convert';

import 'package:flutter/services.dart';

class SayariAccountConfig {
  const SayariAccountConfig({
    required this.appId,
    required this.appName,
    required this.appIcon,
    required this.authorizeUrl,
    required this.tokenUrl,
    required this.userInfoUrl,
    required this.redirectUri,
    required this.allowedOrigin,
    required this.providerOrigin,
    required this.scope,
  });

  final String appId;
  final String appName;
  final String appIcon;
  final String authorizeUrl;
  final String tokenUrl;
  final String userInfoUrl;
  final String redirectUri;
  final String allowedOrigin;
  final String providerOrigin;
  final String scope;

  static Future<SayariAccountConfig> load() async {
    final raw = await rootBundle.loadString(
      'assets/config/sayari-oauth-config.json',
    );
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final app = json['sayariAuthApp'] as Map<String, dynamic>;
    final redirectUris = app['redirectUris'] as List<dynamic>? ?? const [];

    return SayariAccountConfig(
      appId: '${app['appId']}',
      appName: '${app['appName'] ?? json['appName'] ?? 'VikoPlus'}',
      appIcon: '${app['appIcon'] ?? ''}',
      authorizeUrl: '${app['authorizeUrl']}',
      tokenUrl: '${app['tokenUrl']}',
      userInfoUrl: '${app['userInfoUrl']}',
      redirectUri:
          '${app['primaryRedirectUri'] ?? (redirectUris.isNotEmpty ? redirectUris.first : 'com.vikoplus://oauth/callback')}',
      allowedOrigin: '${app['primaryAllowedOrigin'] ?? 'com.vikoplus://oauth'}',
      providerOrigin:
          '${app['providerOrigin'] ?? app['authDomain'] ?? 'https://accounts.sayarisoftware.com'}',
      scope: '${json['scope'] ?? app['scope'] ?? 'openid profile email'}',
    );
  }
}
