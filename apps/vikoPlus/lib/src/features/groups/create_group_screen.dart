import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../common/vikoplus_design_widgets.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  String? _groupType;
  DateTime? _establishedAt;
  DateTime? _historicalDataStartsAt;

  void _goBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }

    context.go('/create-or-join-group');
  }

  String _formatDate(DateTime value) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${value.day} ${months[value.month - 1]} ${value.year}';
  }

  Future<void> _pickEstablishedDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _establishedAt ?? DateTime(2015),
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      _establishedAt = picked;
      if (_historicalDataStartsAt != null &&
          _historicalDataStartsAt!.isBefore(picked)) {
        _historicalDataStartsAt = picked;
      }
    });
  }

  Future<void> _pickHistoricalStartDate() async {
    final firstDate = _establishedAt ?? DateTime(1970);
    final picked = await showDatePicker(
      context: context,
      initialDate: _historicalDataStartsAt ?? _establishedAt ?? DateTime(2015),
      firstDate: firstDate,
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() => _historicalDataStartsAt = picked);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go('/create-or-join-group');
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: AppColors.surface,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: AppColors.surface,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: AppColors.surface,
          body: SafeArea(
            child: Column(
              children: [
                VikoplusTopBar(title: 'Create Group', onBack: _goBack),
                Expanded(
                  child: VikoplusConstrainedContent(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenEdge,
                        AppSpacing.md,
                        AppSpacing.screenEdge,
                        AppSpacing.lg,
                      ),
                      children: [
                        const _LogoUploader(),
                        const SizedBox(height: AppSpacing.md),
                        const _GroupTextField(
                          label: 'Group Name',
                          hint: 'Enter group name',
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _GroupTypeField(
                          value: _groupType,
                          onChanged: (value) {
                            setState(() => _groupType = value);
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const _GroupTextField(
                          label: 'Description',
                          optionalLabel: '(Optional)',
                          hint: 'What is this group about?',
                          minLines: 3,
                          maxLines: 3,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const _GroupTextField(
                          label: 'Location',
                          hint: 'City or Region',
                          prefixIcon: Icons.location_on_outlined,
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _DateField(
                          label: 'Group Established Date',
                          hint: 'When did this group start?',
                          value: _establishedAt == null
                              ? null
                              : _formatDate(_establishedAt!),
                          onTap: _pickEstablishedDate,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _DateField(
                          label: 'Historical Records Start',
                          optionalLabel: '(Optional)',
                          hint: 'Earliest data to import',
                          value: _historicalDataStartsAt == null
                              ? null
                              : _formatDate(_historicalDataStartsAt!),
                          onTap: _pickHistoricalStartDate,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const _HistoryNoteCard(),
                        const SizedBox(height: AppSpacing.sm),
                        const _LockedCurrencyField(),
                      ],
                    ),
                  ),
                ),
                VikoplusBottomActionBar(
                  label: 'Continue',
                  onPressed: () => context.push('/groups/financial-year'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.hint,
    required this.onTap,
    this.optionalLabel,
    this.value,
  });

  final String label;
  final String hint;
  final VoidCallback onTap;
  final String? optionalLabel;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldLabel(label: label, optionalLabel: optionalLabel),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          readOnly: true,
          controller: TextEditingController(text: value ?? ''),
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: const Icon(Icons.event_outlined, size: 22),
            suffixIcon: const Icon(Icons.expand_more, size: 22),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
            ),
          ),
        ),
      ],
    );
  }
}

class _HistoryNoteCard extends StatelessWidget {
  const _HistoryNoteCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.compactCard,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.history_edu_outlined, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Existing groups can keep their real start date and import previous contribution records after setup.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.onSurfaceVariant, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoUploader extends StatelessWidget {
  const _LogoUploader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: AppColors.surfaceContainer,
          shape: const CircleBorder(
            side: BorderSide(
              color: AppColors.outlineVariant,
              width: 1.6,
              style: BorderStyle.solid,
            ),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {},
            child: Container(
              width: AppSizes.uploadLogo,
              height: AppSizes.uploadLogo,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.outlineVariant, width: 1.4),
              ),
              child: const Icon(
                Icons.add_a_photo_outlined,
                color: AppColors.outline,
                size: 28,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Upload Group Logo',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, this.optionalLabel});

  final String label;
  final String? optionalLabel;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: label,
        children: [
          if (optionalLabel != null)
            TextSpan(
              text: ' $optionalLabel',
              style: const TextStyle(
                color: AppColors.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
      style: Theme.of(context).textTheme.labelMedium
          ?.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w700),
    );
  }
}

class _GroupTextField extends StatelessWidget {
  const _GroupTextField({
    required this.label,
    required this.hint,
    this.optionalLabel,
    this.prefixIcon,
    this.minLines = 1,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final String hint;
  final String? optionalLabel;
  final IconData? prefixIcon;
  final int minLines;
  final int maxLines;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldLabel(label: label, optionalLabel: optionalLabel),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          minLines: minLines,
          maxLines: maxLines,
          textCapitalization: textCapitalization,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 22),
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: maxLines > 1 ? AppSpacing.sm : 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _GroupTypeField extends StatelessWidget {
  const _GroupTypeField({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FieldLabel(label: 'Group Type'),
        const SizedBox(height: AppSpacing.xs),
        DropdownButtonFormField<String>(
          initialValue: value,
          icon: const Icon(Icons.keyboard_arrow_down),
          decoration: const InputDecoration(
            hintText: 'Select group type',
            contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          ),
          items: const [
            DropdownMenuItem(value: 'family', child: Text('Family')),
            DropdownMenuItem(value: 'savings', child: Text('Savings')),
            DropdownMenuItem(value: 'welfare', child: Text('Welfare')),
            DropdownMenuItem(value: 'investment', child: Text('Investment')),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _LockedCurrencyField extends StatelessWidget {
  const _LockedCurrencyField();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FieldLabel(label: 'Primary Currency'),
        const SizedBox(height: AppSpacing.xs),
        Container(
          height: AppSizes.inputHeight,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.payments_outlined,
                size: 22,
                color: AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'TZS - Tanzanian Shilling (Locked)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
