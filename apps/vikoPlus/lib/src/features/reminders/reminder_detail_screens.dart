import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../common/vikoplus_components.dart';
import '../common/vikoplus_screen.dart';

class SendNewReminderScreen extends StatelessWidget {
  const SendNewReminderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return VikoplusScreen(
      title: 'New Reminder',
      backRoute: '/reminders',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _ReminderPreviewCard(),
          const SizedBox(height: AppSpacing.md),
          const _ReminderField(
            label: 'Audience',
            value: 'Members with outstanding July dues',
            icon: Icons.groups_2_outlined,
          ),
          const SizedBox(height: AppSpacing.sm),
          const _ReminderField(
            label: 'Channel',
            value: 'SMS + WhatsApp',
            icon: Icons.forum_outlined,
          ),
          const SizedBox(height: AppSpacing.sm),
          const TextField(
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'Message',
              hintText: 'Hi {member_name}, your {amount} contribution is due for Sofia Wajukuu.',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: () => context.go('/reminders/campaigns/july-dues'),
            icon: const Icon(Icons.schedule_send_outlined, size: 18),
            label: const Text('Send Reminder'),
          ),
        ],
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

class _ReminderPreviewCard extends StatelessWidget {
  const _ReminderPreviewCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.card,
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: AppShadows.level2(),
      ),
      child: Text(
        'Prepare targeted SMS and WhatsApp reminders for members who still owe contributions.',
        style: Theme.of(context).textTheme.bodyLarge
            ?.copyWith(color: AppColors.onPrimary, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ReminderField extends StatelessWidget {
  const _ReminderField({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      readOnly: true,
      controller: TextEditingController(text: value),
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
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
