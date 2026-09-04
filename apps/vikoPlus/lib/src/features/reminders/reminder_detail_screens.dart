import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/groups/groups_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../auth/auth_widgets.dart';
import '../common/vikoplus_components.dart';
import '../common/vikoplus_design_widgets.dart';
import '../common/vikoplus_screen.dart';

class SendNewReminderScreen extends ConsumerStatefulWidget {
  const SendNewReminderScreen({this.memberId, super.key});

  @override
  ConsumerState<SendNewReminderScreen> createState() =>
      _SendNewReminderScreenState();

  final String? memberId;
}

class _SendNewReminderScreenState extends ConsumerState<SendNewReminderScreen> {
  static const _limit = 160;
  late final TextEditingController _messageController;
  bool _useSms = true;
  String _errorMessage = '';
  String _successMessage = '';
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController(
      text: 'Dear member, this is a friendly reminder regarding your outstanding dues of TZS 45,000 for the current month. Please complete the payment by Friday.',
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendReminder() async {
    if (_isSending) return;

    final activeGroup = ref.read(activeGroupProvider);
    if (activeGroup == null) {
      setState(() => _errorMessage = 'Open a group before sending reminders.');
      return;
    }

    final message = _messageController.text.trim();
    if (message.isEmpty) {
      setState(() => _errorMessage = 'Write a reminder message.');
      return;
    }

    try {
      setState(() {
        _errorMessage = '';
        _successMessage = '';
        _isSending = true;
      });
      final result = await ref.read(groupsRepositoryProvider).sendReminder(
            activeGroup.id,
            SendReminderInput(
              channel: _useSms ? 'SMS' : 'WHATSAPP',
              message: message,
              memberIds: widget.memberId == null ? const [] : [widget.memberId!],
            ),
          );
      if (!mounted) return;
      setState(
        () => _successMessage =
            'SMS delivered to ${result.smsSent} member${result.smsSent == 1 ? '' : 's'}.',
      );
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = AuthFailure.from(error).message);
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/dashboard');
              break;
            case 1:
              context.go('/members');
              break;
            case 2:
              context.go('/reminders');
              break;
            case 3:
              context.go('/settings/admin');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_2_outlined),
            selectedIcon: Icon(Icons.groups_2),
            label: 'Members',
          ),
          NavigationDestination(
            icon: Icon(Icons.insert_chart_outlined),
            selectedIcon: Icon(Icons.insert_chart),
            label: 'Activity',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _ReminderTopBar(
              title: 'Dashboard',
              onBack: () => context.go('/dashboard'),
            ),
            VikoplusTopBar(
              title: 'Send Reminder',
              onBack: () => context.go('/reminders'),
              showBorder: false,
            ),
            Expanded(
              child: VikoplusConstrainedContent(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenMobile,
                    AppSpacing.sm,
                    AppSpacing.screenMobile,
                    AppSpacing.lg,
                  ),
                  children: [
                    _AudienceCard(isSingleMember: widget.memberId != null),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Channel',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Expanded(
                          child: _ChannelButton(
                            label: 'SMS',
                            icon: Icons.sms_outlined,
                            selected: _useSms,
                            onPressed: () => setState(() => _useSms = true),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _ChannelButton(
                            label: 'WhatsApp',
                            icon: Icons.chat_outlined,
                            selected: !_useSms,
                            onPressed: null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Message',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => context.go('/reminders/templates'),
                          icon: const Icon(Icons.copy_all_outlined, size: 16),
                          label: const Text('Use Template'),
                        ),
                      ],
                    ),
                    TextField(
                      controller: _messageController,
                      maxLines: 6,
                      maxLength: _limit,
                      onChanged: (_) {
                        setState(() {
                          _errorMessage = '';
                          _successMessage = '';
                        });
                      },
                      decoration: const InputDecoration(
                        counterText: '',
                        hintText: 'Write reminder message',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${_messageController.text.length}/$_limit',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        const Icon(
                          Icons.remove_red_eye_outlined,
                          color: AppColors.onSurfaceVariant,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Message Preview',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _MessagePreview(message: _messageController.text),
                    const SizedBox(height: AppSpacing.md),
                    AuthErrorMessage(message: _errorMessage),
                    if (_successMessage.isNotEmpty)
                      Text(
                        _successMessage,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton.icon(
                      onPressed: _isSending ? null : _sendReminder,
                      icon: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_outlined),
                      label: Text(_isSending ? 'Sending' : 'Send Reminder'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderTopBar extends StatelessWidget {
  const _ReminderTopBar({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.topBarHeight,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: AppSizes.iconButton,
            child: IconButton(
              tooltip: 'Back',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
            ),
          ),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary,
              child: const Icon(
                Icons.person_outline,
                color: AppColors.onPrimary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AudienceCard extends StatelessWidget {
  const _AudienceCard({required this.isSingleMember});

  final bool isSingleMember;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.compactCard,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.errorContainer,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: const Icon(Icons.group_outlined, color: AppColors.error),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'To',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
                Text(
                  isSingleMember
                      ? 'Selected Member'
                      : 'Members with Outstanding\nDues',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChannelButton extends StatelessWidget {
  const _ChannelButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: selected
          ? FilledButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 17),
              label: Text(label),
            )
          : FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.surfaceContainer,
                foregroundColor: AppColors.onSurface,
                elevation: 0,
              ),
              onPressed: onPressed,
              icon: Icon(icon, size: 17),
              label: Text(label),
            ),
    );
  }
}

class _MessagePreview extends StatelessWidget {
  const _MessagePreview({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.card,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F1FB),
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
      child: Align(
        alignment: Alignment.center,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          padding: AppInsets.compactCard,
          decoration: BoxDecoration(
            color: const Color(0xFFE0E1EB),
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vikoplus:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.62),
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Delivered',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.58),
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MessageTemplatesScreen extends StatelessWidget {
  const MessageTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return VikoplusScreen(
      title: 'Message Templates',
      backRoute: '/reminders',
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TemplateTile(
            title: 'Before due date',
            subtitle: 'Friendly reminder sent 3 days before due date.',
            icon: Icons.event_available_outlined,
          ),
          SizedBox(height: AppSpacing.sm),
          _TemplateTile(
            title: 'Due today',
            subtitle: 'Same-day contribution reminder.',
            icon: Icons.today_outlined,
          ),
          SizedBox(height: AppSpacing.sm),
          _TemplateTile(
            title: 'Overdue follow-up',
            subtitle: 'Follow-up after the grace period.',
            icon: Icons.notification_important_outlined,
          ),
        ],
      ),
    );
  }
}

class CampaignDetailsScreen extends StatelessWidget {
  const CampaignDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return VikoplusScreen(
      title: 'Campaign Details',
      backRoute: '/reminders',
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProgressBlock(
            title: 'July dues reminder',
            value: '18 delivered',
            caption: '18 delivered, 2 pending, 0 failed',
            progress: 0.9,
          ),
          SizedBox(height: AppSpacing.md),
          _CampaignMetric(
            title: 'SMS sent',
            value: '10',
            icon: Icons.sms_outlined,
          ),
          SizedBox(height: AppSpacing.sm),
          _CampaignMetric(
            title: 'WhatsApp sent',
            value: '8',
            icon: Icons.chat_outlined,
          ),
          SizedBox(height: AppSpacing.sm),
          _CampaignMetric(
            title: 'Estimated cost',
            value: 'TZS 1,800',
            icon: Icons.payments_outlined,
          ),
        ],
      ),
    );
  }
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ActionTile(
      title: title,
      subtitle: subtitle,
      icon: icon,
      route: '/reminders/new',
    );
  }
}

class _CampaignMetric extends StatelessWidget {
  const _CampaignMetric({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.compactCard,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.surfaceContainer,
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(title)),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
