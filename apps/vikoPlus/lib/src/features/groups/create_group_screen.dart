import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/groups/group_setup_draft.dart';
import '../../core/groups/groups_repository.dart';
import '../../core/uploads/uploads_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../auth/auth_widgets.dart';
import '../common/vikoplus_design_widgets.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  String? _groupType;
  DateTime? _establishedAt;
  DateTime? _historicalDataStartsAt;
  String? _logoObjectKey;
  String? _logoUrl;
  String? _localLogoPath;
  String _errorMessage = '';
  bool _nameHasError = false;
  bool _isSubmitting = false;
  bool _isUploadingLogo = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(groupSetupDraftProvider).profile;
    _nameController.text = profile.name;
    _descriptionController.text = profile.description;
    _locationController.text = profile.location;
    _groupType = profile.type;
    _establishedAt = profile.establishedAt;
    _historicalDataStartsAt = profile.historicalDataStartsAt;
    _logoObjectKey = profile.logoObjectKey;
    _logoUrl = profile.logoUrl;
    _localLogoPath = profile.localLogoPath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _goBack() {
    _persistProfile();
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
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _establishedAt ?? today,
      firstDate: DateTime(1970),
      lastDate: today,
    );
    if (picked == null) return;
    setState(() {
      _establishedAt = picked;
      if (_historicalDataStartsAt != null &&
          _historicalDataStartsAt!.isBefore(picked)) {
        _historicalDataStartsAt = picked;
      }
    });
    _persistProfile();
  }

  Future<void> _pickHistoricalStartDate() async {
    final firstDate = _establishedAt ?? DateTime(1970);
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _historicalDataStartsAt ?? _establishedAt ?? today,
      firstDate: firstDate,
      lastDate: today,
    );
    if (picked == null) return;
    setState(() => _historicalDataStartsAt = picked);
    _persistProfile();
  }

  void _clearError() {
    if (_errorMessage.isEmpty && !_nameHasError) return;
    setState(() {
      _errorMessage = '';
      _nameHasError = false;
    });
  }

  void _persistProfile() {
    ref.read(groupSetupDraftProvider.notifier).updateProfile(
          GroupProfileDraft(
            name: _nameController.text,
            type: _groupType,
            description: _descriptionController.text,
            location: _locationController.text,
            establishedAt: _establishedAt,
            historicalDataStartsAt: _historicalDataStartsAt,
            logoObjectKey: _logoObjectKey,
            logoUrl: _logoUrl,
            localLogoPath: _localLogoPath,
          ),
        );
  }

  Future<void> _pickLogo() async {
    if (_isSubmitting || _isUploadingLogo) return;

    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 84,
    );
    if (image == null) return;

    setState(() {
      _localLogoPath = image.path;
      _logoObjectKey = null;
      _logoUrl = null;
    });
    _persistProfile();

    final groupId = ref.read(groupSetupDraftProvider).createdGroupId;
    if (groupId != null && groupId.isNotEmpty) {
      await _uploadLogo(groupId);
    }
  }

  Future<void> _uploadLogo(String groupId) async {
    if (_localLogoPath == null || _localLogoPath!.isEmpty || _isUploadingLogo) {
      return;
    }

    setState(() => _isUploadingLogo = true);
    try {
      final image = await ref.read(uploadsRepositoryProvider).uploadGroupImage(
            groupId: groupId,
            image: XFile(_localLogoPath!),
          );
      if (!mounted) return;
      setState(() {
        _logoObjectKey = image.objectKey;
        _logoUrl = image.url;
      });
      _persistProfile();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = AuthFailure.from(error).message);
    } finally {
      if (mounted) {
        setState(() => _isUploadingLogo = false);
      }
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final name = _nameController.text.trim();
    if (name.length < 2) {
      setState(() {
        _errorMessage = 'Enter a valid group name.';
        _nameHasError = true;
      });
      return;
    }

    try {
      setState(() {
        _errorMessage = '';
        _nameHasError = false;
        _isSubmitting = true;
      });
      _persistProfile();
      final existingGroupId = ref.read(groupSetupDraftProvider).createdGroupId;
      if (existingGroupId != null && existingGroupId.isNotEmpty) {
        await _uploadLogo(existingGroupId);
        if (!mounted) return;
        context.go(
          '/groups/financial-year?groupId=${Uri.encodeComponent(existingGroupId)}',
        );
        return;
      }
      final group = await ref.read(groupsRepositoryProvider).createGroup(
            CreateGroupInput(
              name: name,
              type: _groupType,
              description: _descriptionController.text,
              location: _locationController.text,
              establishedAt: _establishedAt,
              historicalDataStartsAt: _historicalDataStartsAt,
            ),
          );
      if (!mounted) return;
      ref.read(activeGroupProvider.notifier).setGroup(
            GroupAccessSummary(
              id: group.id,
              name: group.name,
              role: group.currentUserRole,
              status: 'ACTIVE',
              membersCount: 1,
            ),
          );
      ref.read(groupSetupDraftProvider.notifier).markGroupCreated(group.id);
      await _uploadLogo(group.id);
      if (!mounted) return;
      context.go(
        '/groups/financial-year?groupId=${Uri.encodeComponent(group.id)}',
      );
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = AuthFailure.from(error).message);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _persistProfile();
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
                        _LogoUploader(
                          imageUrl: _logoUrl,
                          localImagePath: _localLogoPath,
                          isUploading: _isUploadingLogo,
                          onTap: _pickLogo,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _GroupTextField(
                          label: 'Group Name',
                          hint: 'Enter group name',
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          hasError: _nameHasError,
                          onChanged: (_) {
                            _clearError();
                            _persistProfile();
                          },
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _GroupTypeField(
                          value: _groupType,
                          onChanged: (value) {
                            setState(() => _groupType = value);
                            _persistProfile();
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _GroupTextField(
                          label: 'Description',
                          optionalLabel: '(Optional)',
                          hint: 'What is this group about?',
                          controller: _descriptionController,
                          onChanged: (_) {
                            _clearError();
                            _persistProfile();
                          },
                          minLines: 3,
                          maxLines: 3,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _GroupTextField(
                          label: 'Location',
                          hint: 'City or Region',
                          controller: _locationController,
                          textInputAction: TextInputAction.next,
                          onChanged: (_) {
                            _clearError();
                            _persistProfile();
                          },
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
                        const SizedBox(height: AppSpacing.sm),
                        AuthErrorMessage(message: _errorMessage),
                      ],
                    ),
                  ),
                ),
                VikoplusBottomActionBar(
                  label: _isSubmitting ? 'Creating group' : 'Continue',
                  isLoading: _isSubmitting,
                  onPressed: _submit,
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
  const _LogoUploader({
    required this.isUploading,
    required this.onTap,
    this.imageUrl,
    this.localImagePath,
  });

  final bool isUploading;
  final VoidCallback onTap;
  final String? imageUrl;
  final String? localImagePath;

  @override
  Widget build(BuildContext context) {
    final localPath = localImagePath;
    final hasLocalPreview = localPath != null && localPath.isNotEmpty;
    final hasRemotePreview = imageUrl != null && imageUrl!.isNotEmpty;

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
            onTap: isUploading ? null : onTap,
            child: Container(
              width: AppSizes.uploadLogo,
              height: AppSizes.uploadLogo,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.outlineVariant, width: 1.4),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasLocalPreview)
                    Image.file(File(localPath), fit: BoxFit.cover)
                  else if (hasRemotePreview)
                    Image.network(imageUrl!, fit: BoxFit.cover)
                  else
                    const Center(
                      child: Icon(
                        Icons.add_a_photo_outlined,
                        color: AppColors.outline,
                        size: 28,
                      ),
                    ),
                  if (isUploading)
                    const ColoredBox(
                      color: Color(0x66000000),
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          hasLocalPreview || hasRemotePreview
              ? 'Change Group Logo'
              : 'Upload Group Logo',
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
    this.controller,
    this.textInputAction,
    this.onChanged,
    this.minLines = 1,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
    this.hasError = false,
  });

  final String label;
  final String hint;
  final String? optionalLabel;
  final IconData? prefixIcon;
  final TextEditingController? controller;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final int minLines;
  final int maxLines;
  final TextCapitalization textCapitalization;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldLabel(label: label, optionalLabel: optionalLabel),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller,
          minLines: minLines,
          maxLines: maxLines,
          textInputAction: textInputAction,
          onChanged: onChanged,
          textCapitalization: textCapitalization,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 22),
            enabledBorder: hasError
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    borderSide: const BorderSide(
                      color: AppColors.error,
                      width: 1.6,
                    ),
                  )
                : null,
            focusedBorder: hasError
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    borderSide: const BorderSide(
                      color: AppColors.error,
                      width: 2,
                    ),
                  )
                : null,
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
