import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/groups/groups_repository.dart';
import '../../l10n/vikoplus_translations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../auth/auth_widgets.dart';
import '../common/vikoplus_components.dart';
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
  String? _memberFutureKey;
  Future<GroupMemberSummary>? _memberFuture;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController(
      text:
          'Dear member, please review your outstanding group dues and contact the treasurer to arrange payment.',
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
      setState(
        () => _errorMessage = context.vt(
          'Open a group before sending reminders.',
        ),
      );
      return;
    }

    final message = _messageController.text.trim();
    if (message.isEmpty) {
      setState(() => _errorMessage = context.vt('Write a reminder message.'));
      return;
    }

    try {
      setState(() {
        _errorMessage = '';
        _successMessage = '';
        _isSending = true;
      });
      final result = await ref
          .read(groupsRepositoryProvider)
          .sendReminder(
            activeGroup.id,
            SendReminderInput(
              channel: _useSms ? 'SMS' : 'WHATSAPP',
              message: message,
              memberIds: widget.memberId == null
                  ? const []
                  : [widget.memberId!],
            ),
          );
      if (!mounted) return;
      setState(
        () => _successMessage = context.vtf(
          'SMS delivered to {count} members.',
          {'count': result.smsSent},
        ),
      );
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = context.vt(AuthFailure.from(error).message));
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<GroupMemberSummary>? _selectedMemberFuture(String? groupId) {
    final memberId = widget.memberId;
    if (groupId == null ||
        groupId.isEmpty ||
        memberId == null ||
        memberId.isEmpty) {
      return null;
    }
    final key = '$groupId:$memberId';
    if (_memberFutureKey != key || _memberFuture == null) {
      _memberFutureKey = key;
      _memberFuture = ref.read(groupsRepositoryProvider).member(
            groupId,
            memberId,
          );
    }
    return _memberFuture;
  }

  @override
  Widget build(BuildContext context) {
    final activeGroup = ref.watch(activeGroupProvider);
    final selectedMemberFuture = _selectedMemberFuture(activeGroup?.id);

    return VikoplusScreen(
      title: context.vt('Send Reminder'),
      backRoute: '/reminders',
      preferBackRoute: true,
      showBottomNavigation: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AudienceCard(
            isSingleMember: widget.memberId != null,
            selectedMemberFuture: selectedMemberFuture,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.vt('Channel'),
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
                  context.vt('Message'),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => context.go('/reminders/templates'),
                icon: const Icon(Icons.copy_all_outlined, size: 16),
                label: Text(context.vt('Use Template')),
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
            decoration: InputDecoration(
              counterText: '',
              hintText: context.vt('Write reminder message'),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${_messageController.text.length}/$_limit',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
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
                context.vt('Message Preview'),
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
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
            label: Text(context.vt(_isSending ? 'Sending' : 'Send Reminder')),
          ),
        ],
      ),
    );
  }
}

class _AudienceCard extends StatelessWidget {
  const _AudienceCard({
    required this.isSingleMember,
    required this.selectedMemberFuture,
  });

  final bool isSingleMember;
  final Future<GroupMemberSummary>? selectedMemberFuture;

  String _titleFor(
    BuildContext context,
    AsyncSnapshot<GroupMemberSummary> snapshot,
  ) {
    final member = snapshot.data;
    if (!isSingleMember) {
      return context.vt('Members with Outstanding Dues');
    }
    if (snapshot.connectionState == ConnectionState.waiting) {
      return context.vt('Loading member');
    }
    final name = member?.fullName.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }
    return context.vt('Selected Member');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<GroupMemberSummary>(
      future: selectedMemberFuture,
      builder: (context, snapshot) {
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
                child: Icon(
                  isSingleMember
                      ? Icons.person_outline
                      : Icons.group_outlined,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.vt('To'),
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    Text(
                      _titleFor(context, snapshot),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    if (isSingleMember &&
                        snapshot.data?.memberNumber?.trim().isNotEmpty ==
                            true) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        snapshot.data!.memberNumber!.trim(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
                context.vt('Vikoplus:'),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TemplateTile(
            title: 'Before due date',
            subtitle: 'Friendly reminder sent 3 days before due date.',
            icon: Icons.event_available_outlined,
          ),
          const SizedBox(height: AppSpacing.sm),
          _TemplateTile(
            title: 'Due today',
            subtitle: 'Same-day contribution reminder.',
            icon: Icons.today_outlined,
          ),
          const SizedBox(height: AppSpacing.sm),
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
