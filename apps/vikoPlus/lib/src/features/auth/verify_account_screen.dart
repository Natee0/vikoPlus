import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/auth/auth_session.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../common/vikoplus_design_widgets.dart';
import 'auth_widgets.dart';

class VerifyAccountScreen extends ConsumerStatefulWidget {
  const VerifyAccountScreen({
    this.nextRoute = '/create-or-join-group',
    this.backRoute = '/create-account',
    this.challengeId,
    this.destination,
    this.channel,
    super.key,
  });

  final String nextRoute;
  final String backRoute;
  final String? challengeId;
  final String? destination;
  final String? channel;

  @override
  ConsumerState<VerifyAccountScreen> createState() =>
      _VerifyAccountScreenState();
}

class _VerifyAccountScreenState extends ConsumerState<VerifyAccountScreen> {
  static const int _codeLength = 6;

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_codeLength, (_) => TextEditingController());
    _focusNodes = List.generate(_codeLength, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  bool get _isComplete {
    return _controllers.every((controller) => controller.text.length == 1);
  }

  String get _code {
    return _controllers.map((controller) => controller.text).join();
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }

    context.go(widget.backRoute);
  }

  void _handleCodeChanged(String value, int index) {
    final digits = value.replaceAll(RegExp(r'\D'), '');

    if (digits.isEmpty) {
      _controllers[index].clear();
      setState(() {});
      return;
    }

    if (digits.length > 1) {
      _applyPastedCode(digits, index);
      return;
    }

    _setDigit(index, digits);
    if (index < _codeLength - 1) {
      _focusNodes[index + 1].requestFocus();
    } else {
      _focusNodes[index].unfocus();
    }
    setState(() {});
  }

  void _applyPastedCode(String digits, int startIndex) {
    var writeIndex = startIndex;
    for (final digit in digits.split('')) {
      if (writeIndex >= _codeLength) {
        break;
      }
      _setDigit(writeIndex, digit);
      writeIndex++;
    }

    if (_isComplete) {
      _focusNodes.last.unfocus();
    } else {
      _focusNodes[writeIndex.clamp(0, _codeLength - 1)].requestFocus();
    }
    setState(() {});
  }

  void _setDigit(int index, String digit) {
    _controllers[index].value = TextEditingValue(
      text: digit,
      selection: TextSelection.collapsed(offset: digit.length),
    );
  }

  Future<void> _verify() async {
    if (!_isComplete) {
      _showMessage('Enter the full verification code.');
      return;
    }

    try {
      final route = await ref
          .read(authControllerProvider.notifier)
          .verifyPendingOtp(_code);
      if (!mounted) return;
      context.go(route);
    } on AuthFailure catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  KeyEventResult _handleKeyEvent(KeyEvent event, int index) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.backspace ||
        index == 0 ||
        _controllers[index].text.isNotEmpty) {
      return KeyEventResult.ignored;
    }

    _focusNodes[index - 1].requestFocus();
    _controllers[index - 1].clear();
    setState(() {});
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    final pending = session.pendingVerification;
    final destination =
        widget.destination ?? pending?.destination ?? 'your phone or email';
    final channel = widget.channel ?? pending?.channel ?? 'sms';
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go(widget.backRoute);
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: AppColors.background,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: AppColors.background,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenMobile,
                    AppSpacing.xs,
                    AppSpacing.screenMobile,
                    AppSpacing.md,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        VikoplusTopBar(
                          title: 'Vikoplus',
                          onBack: _goBack,
                          showBorder: false,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: AppSizes.maxContentWidth,
                            ),
                            child: AuthCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Center(
                                    child: Container(
                                      width: AppSizes.brandLogo,
                                      height: AppSizes.brandLogo,
                                      decoration: const BoxDecoration(
                                        color: AppColors.surfaceContainerLow,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.shield_outlined,
                                        color: AppColors.primary,
                                        size: 30,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    'Verify Account',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: AppColors.primaryText,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text.rich(
                                    TextSpan(
                                      text:
                                          'Enter the verification code sent to\n',
                                      children: [
                                        TextSpan(
                                          text: destination,
                                          style: const TextStyle(
                                            color: AppColors.primaryText,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppColors.onSurfaceVariant,
                                          height: 1.45,
                                        ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Row(
                                    children: List.generate(_codeLength, (
                                      index,
                                    ) {
                                      return Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                            right: index == _codeLength - 1
                                                ? 0
                                                : AppSpacing.xs,
                                          ),
                                          child: Focus(
                                            onKeyEvent: (node, event) {
                                              return _handleKeyEvent(
                                                event,
                                                index,
                                              );
                                            },
                                            child: SizedBox(
                                              height:
                                                  AppSizes.compactInputHeight,
                                              child: TextField(
                                                controller: _controllers[index],
                                                focusNode: _focusNodes[index],
                                                autofocus: index == 0,
                                                textAlign: TextAlign.center,
                                                keyboardType:
                                                    TextInputType.number,
                                                textInputAction:
                                                    index == _codeLength - 1
                                                    ? TextInputAction.done
                                                    : TextInputAction.next,
                                                inputFormatters: [
                                                  FilteringTextInputFormatter
                                                      .digitsOnly,
                                                ],
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      color:
                                                          AppColors.primaryText,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                decoration:
                                                    const InputDecoration(
                                                      counterText: '',
                                                      contentPadding:
                                                          EdgeInsets.zero,
                                                    ),
                                                onChanged: (value) {
                                                  _handleCodeChanged(
                                                    value,
                                                    index,
                                                  );
                                                },
                                                onTap: () {
                                                  _controllers[index]
                                                          .selection =
                                                      TextSelection(
                                                        baseOffset: 0,
                                                        extentOffset:
                                                            _controllers[index]
                                                                .text
                                                                .length,
                                                      );
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.timer_outlined,
                                        size: 14,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: AppSpacing.xxs),
                                      Text(
                                        '00:57',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.onSurfaceVariant,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: isLoading
                                        ? null
                                        : () {
                                            _showMessage(
                                              'Resend code will be enabled after the resend endpoint is added.',
                                            );
                                          },
                                    child: Text(
                                      channel == 'email'
                                          ? 'Resend email'
                                          : 'Resend code',
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  FilledButton.icon(
                                    onPressed:
                                        isLoading || !_isComplete ? null : _verify,
                                    iconAlignment: IconAlignment.end,
                                    icon: isLoading
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Icon(
                                            _isComplete
                                                ? Icons.check_circle_outline
                                                : Icons.verified_outlined,
                                            size: 18,
                                          ),
                                    label: Text(
                                      isLoading ? 'Verifying' : 'Verify',
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  TextButton(
                                    onPressed: _goBack,
                                    child: Text(
                                      channel == 'email'
                                          ? 'Change email address'
                                          : 'Change phone number',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
