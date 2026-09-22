import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sayari_oauth_flutter_sdk/sayari_oauth_flutter_sdk.dart'
    as sayari_sdk;

import 'auth_repository.dart';
import 'sayari_account_config.dart';

final sayariAccountAuthServiceProvider = Provider<SayariAccountAuthService>((
  ref,
) {
  return SayariAccountAuthService(ref.watch(authRepositoryProvider));
});

class SayariAccountAuthService {
  SayariAccountAuthService(this._authRepository);

  final AuthRepository _authRepository;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _pendingStateKey = 'vikoplus.sayariOAuth.state';
  static const _pendingVerifierKey = 'vikoplus.sayariOAuth.codeVerifier';
  static const _pendingChallengeKey = 'vikoplus.sayariOAuth.codeChallenge';
  static const _pendingRedirectUriKey = 'vikoplus.sayariOAuth.redirectUri';
  static const _pendingScopeKey = 'vikoplus.sayariOAuth.scope';
  static const _pendingDeliveryMethodKey =
      'vikoplus.sayariOAuth.deliveryMethod';
  static const _pendingParentOriginKey = 'vikoplus.sayariOAuth.parentOrigin';
  static const _pendingAppNameKey = 'vikoplus.sayariOAuth.appName';
  static const _pendingAppIconKey = 'vikoplus.sayariOAuth.appIcon';

  Future<void> signIn() async {
    final config = await SayariAccountConfig.load();
    final sdk = _sdk(config);
    final tx = _newTransaction(config);
    await _clearPending();
    await _savePending(tx);

    final opened = await sdk.launchAuthorize(
      pkce: tx.pkce,
      redirectUri: tx.redirectUri,
      scope: tx.scope,
      deliveryMethod: tx.deliveryMethod,
      parentOrigin: tx.parentOrigin,
      loginHint: tx.loginHint,
      appName: tx.clientAppName,
      appIcon: tx.clientAppIcon,
    );
    if (!opened) {
      throw StateError('Could not open Sayari Account.');
    }
  }

  Future<AuthTokens> completeSignIn(Uri callbackUri) async {
    final config = await SayariAccountConfig.load();
    final sdk = _sdk(config);
    final callback = sdk.parseCallback(callbackUri);
    if (callback.isError) {
      throw StateError(
        callback.errorDescription ?? callback.error ?? 'Sayari sign-in failed.',
      );
    }

    final pending = await _readPending();
    if (pending == null) {
      throw StateError('No pending Sayari sign-in was found.');
    }

    final tx = _transactionFromPending(config, pending);
    if (!_matchesCallback(callbackUri, tx.redirectUri)) {
      throw StateError('Unexpected Sayari sign-in callback.');
    }
    if (!tx.validateCallback(callback) || callback.code == null) {
      throw StateError('Invalid Sayari sign-in state.');
    }

    final payload = Map<String, dynamic>.from(tx.exchangePayload(callback.code!))
      ..remove('grantType');
    final tokens = await _authRepository.exchangeSayariAccount(
      payload: payload,
    );
    await _clearPending();
    return tokens;
  }

  bool isCallback(Uri uri) {
    return uri.scheme == 'com.vikoplus' &&
        uri.host == 'oauth' &&
        uri.path == '/callback';
  }

  sayari_sdk.SayariOAuthFlutterSdk _sdk(SayariAccountConfig config) {
    return sayari_sdk.SayariOAuthFlutterSdk(
      sayari_sdk.SayariOAuthConfig(
        appId: config.appId,
        appName: config.appName,
        appIcon: config.appIcon.isEmpty ? null : config.appIcon,
        authorizeUrl: config.authorizeUrl,
        tokenUrl: config.tokenUrl,
        redirectUri: config.redirectUri,
        providerOrigin: config.providerOrigin,
        scope: config.scope,
      ),
    );
  }

  sayari_sdk.SayariOAuthTransaction _newTransaction(
    SayariAccountConfig config,
  ) {
    final sdk = _sdk(config);
    return sdk.createTransaction(
      pkce: sdk.createPkce(),
      redirectUri: config.redirectUri,
      scope: config.scope,
      deliveryMethod: 'email',
      parentOrigin: config.allowedOrigin,
      appName: config.appName,
      appIcon: config.appIcon.isEmpty ? null : config.appIcon,
    );
  }

  sayari_sdk.SayariOAuthTransaction _transactionFromPending(
    SayariAccountConfig config,
    _PendingSayariOAuth pending,
  ) {
    final sdk = _sdk(config);
    final pkce = sayari_sdk.SayariPkce(
      state: pending.state,
      codeVerifier: pending.codeVerifier,
      codeChallenge: pending.codeChallenge,
    );
    return sdk.createTransaction(
      pkce: pkce,
      redirectUri: pending.redirectUri,
      scope: pending.scope,
      deliveryMethod: pending.deliveryMethod,
      parentOrigin: pending.parentOrigin,
      appName: pending.appName,
      appIcon: pending.appIcon,
    );
  }

  bool _matchesCallback(Uri incomingUri, String redirectUri) {
    final expectedUri = Uri.parse(redirectUri);
    return incomingUri.scheme == expectedUri.scheme &&
        incomingUri.host == expectedUri.host &&
        incomingUri.path == expectedUri.path;
  }

  Future<void> _savePending(sayari_sdk.SayariOAuthTransaction tx) async {
    await Future.wait([
      _storage.write(key: _pendingStateKey, value: tx.state),
      _storage.write(key: _pendingVerifierKey, value: tx.codeVerifier),
      _storage.write(key: _pendingChallengeKey, value: tx.codeChallenge),
      _storage.write(key: _pendingRedirectUriKey, value: tx.redirectUri),
      _storage.write(key: _pendingScopeKey, value: tx.scope),
      _writeOrDelete(_pendingDeliveryMethodKey, tx.deliveryMethod),
      _writeOrDelete(_pendingParentOriginKey, tx.parentOrigin),
      _writeOrDelete(_pendingAppNameKey, tx.clientAppName),
      _writeOrDelete(_pendingAppIconKey, tx.clientAppIcon),
    ]);
  }

  Future<_PendingSayariOAuth?> _readPending() async {
    final state = await _storage.read(key: _pendingStateKey);
    final codeVerifier = await _storage.read(key: _pendingVerifierKey);
    final codeChallenge = await _storage.read(key: _pendingChallengeKey);
    final redirectUri = await _storage.read(key: _pendingRedirectUriKey);
    final scope = await _storage.read(key: _pendingScopeKey);
    if (state == null ||
        codeVerifier == null ||
        codeChallenge == null ||
        redirectUri == null ||
        scope == null) {
      return null;
    }

    return _PendingSayariOAuth(
      state: state,
      codeVerifier: codeVerifier,
      codeChallenge: codeChallenge,
      redirectUri: redirectUri,
      scope: scope,
      deliveryMethod: await _storage.read(key: _pendingDeliveryMethodKey),
      parentOrigin: await _storage.read(key: _pendingParentOriginKey),
      appName: await _storage.read(key: _pendingAppNameKey),
      appIcon: await _storage.read(key: _pendingAppIconKey),
    );
  }

  Future<void> _clearPending() async {
    await Future.wait([
      _storage.delete(key: _pendingStateKey),
      _storage.delete(key: _pendingVerifierKey),
      _storage.delete(key: _pendingChallengeKey),
      _storage.delete(key: _pendingRedirectUriKey),
      _storage.delete(key: _pendingScopeKey),
      _storage.delete(key: _pendingDeliveryMethodKey),
      _storage.delete(key: _pendingParentOriginKey),
      _storage.delete(key: _pendingAppNameKey),
      _storage.delete(key: _pendingAppIconKey),
    ]);
  }

  Future<void> _writeOrDelete(String key, String? value) {
    if (value == null || value.isEmpty) {
      return _storage.delete(key: key);
    }
    return _storage.write(key: key, value: value);
  }
}

class _PendingSayariOAuth {
  const _PendingSayariOAuth({
    required this.state,
    required this.codeVerifier,
    required this.codeChallenge,
    required this.redirectUri,
    required this.scope,
    this.deliveryMethod,
    this.parentOrigin,
    this.appName,
    this.appIcon,
  });

  final String state;
  final String codeVerifier;
  final String codeChallenge;
  final String redirectUri;
  final String scope;
  final String? deliveryMethod;
  final String? parentOrigin;
  final String? appName;
  final String? appIcon;
}
