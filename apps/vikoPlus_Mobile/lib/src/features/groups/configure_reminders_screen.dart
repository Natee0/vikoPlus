import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/sample/sofia_sample_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../common/vikoplus_screen.dart';

class ConfigureRemindersScreen extends StatelessWidget {
  const ConfigureRemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return VikoplusScreen(
      title: 'Configure Reminders',
      backRoute: '/groups/contributions',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _ToggleCard(),
          const SizedBox(height: AppSpacing.md),
          const _SectionLabel('Delivery Channels'),
          const SizedBox(height: AppSpacing.sm),
          const Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _ChannelChip(
                label: 'SMS',
                icon: Icons.sms_outlined,
                price: 'TZS $vikoplusSmsReminderPrice per SMS',
                selected: true,
              ),
              _ChannelChip(
                label: 'WhatsApp',
                icon: Icons.chat_outlined,
                price: 'TZS $vikoplusWhatsAppReminderPrice per message',
              ),
              _ChannelChip(
                label: 'Both',
                icon: Icons.forum_outlined,
                price: 'TZS $vikoplusSmsAndWhatsAppReminderPrice total',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const _SectionLabel('Schedule'),
          const SizedBox(height: AppSpacing.sm),
          const _ScheduleTile(label: '3 days before due date', selected: true),
          const SizedBox(height: AppSpacing.xs),
          const _ScheduleTile(label: 'On due date', selected: true),
          const SizedBox(height: AppSpacing.xs),
          const _ScheduleTile(label: '3 days overdue'),
          const SizedBox(height: AppSpacing.md),
          const _SectionLabel('Message Preview'),
          const SizedBox(height: AppSpacing.sm),
          const _MessagePreview(),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: () => context.go('/groups/onboarding-success'),
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Save and Continue'),
          ),
        ],
      ),
    );
  }
}

class _ToggleCard extends StatelessWidget {
  const _ToggleCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.compactCard,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: AppShadows.level1(),
      ),
      child: Material(
        color: Colors.transparent,
        child: SwitchListTile(
          value: true,
          contentPadding: EdgeInsets.zero,
          onChanged: (_) {},
          title: Text(
            'Enable Automatic Reminders',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: const Text(
            'Send automated payment alerts to members. Admin pays messaging costs separately from member contributions.',
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: AppColors.onSurfaceVariant,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ChannelChip extends StatelessWidget {
  const _ChannelChip({
    required this.label,
    required this.icon,
    required this.price,
    this.selected = false,
  });

  final String label;
  final IconData icon;
  final String price;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primaryContainer
            : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(
          color: selected ? AppColors.primaryContainer : AppColors.outline,
        ),
        boxShadow: selected ? AppShadows.level2() : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: selected ? AppColors.onPrimary : AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected ? AppColors.onPrimary : AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                price,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: selected
                      ? AppColors.onPrimary.withValues(alpha: 0.78)
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: selected
              ? AppColors.primaryContainer
              : AppColors.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Checkbox(value: selected, onChanged: (_) {}),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

class _MessagePreview extends StatelessWidget {
  const _MessagePreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.compactCard,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.sms_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Hi {member_name}, this is a friendly reminder that your payment of {amount} for Sofia Wajukuu is due soon.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurface,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
