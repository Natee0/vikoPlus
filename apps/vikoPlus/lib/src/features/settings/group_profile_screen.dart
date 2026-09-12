import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/formatters/app_formatters.dart';
import '../../core/groups/groups_repository.dart';
import '../../core/uploads/uploads_repository.dart';
import '../../l10n/vikoplus_translations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../auth/auth_widgets.dart';
import '../common/profile_avatar.dart';
import '../common/vikoplus_screen.dart';

class GroupProfileScreen extends ConsumerStatefulWidget {
  const GroupProfileScreen({super.key});

  @override
  ConsumerState<GroupProfileScreen> createState() => _GroupProfileScreenState();
}

class _GroupProfileScreenState extends ConsumerState<GroupProfileScreen> {
  bool _isUploading = false;
  bool _isDeletionActionRunning = false;
  String _errorMessage = '';
  String? _settingsFutureGroupId;
  Future<GroupSettingsResult>? _settingsFuture;

  Future<void> _pickAndUpload() async {
    final group = ref.read(activeGroupProvider);
    if (_isUploading || group == null || group.role != 'GROUP_ADMIN') {
      return;
    }

    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1200,
    );
    if (image == null) {
      return;
    }

    setState(() {
      _errorMessage = '';
      _isUploading = true;
    });

    try {
      final uploaded = await ref
          .read(uploadsRepositoryProvider)
          .uploadGroupImage(groupId: group.id, image: image);
      if (!mounted) {
        return;
      }
      ref.read(activeGroupProvider.notifier).updateGroupLogo(uploaded.url);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.vt('Group icon updated.'))),
      );
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = context.vt(AuthFailure.from(error).message));
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<GroupSettingsResult>? _settingsFor(String? groupId) {
    if (groupId == null || groupId.isEmpty) return null;
    if (_settingsFutureGroupId != groupId || _settingsFuture == null) {
      _settingsFutureGroupId = groupId;
      _settingsFuture = ref.read(groupsRepositoryProvider).settings(groupId);
    }
    return _settingsFuture;
  }

  void _refreshSettings(String groupId) {
    _settingsFutureGroupId = groupId;
    _settingsFuture = ref.read(groupsRepositoryProvider).settings(groupId);
  }

  Future<void> _requestDeletion(String groupId) async {
    final reasonController = TextEditingController();
    final successMessage = context.vt('Group deletion request submitted.');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.vt('Request group deletion')),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: context.vt('Reason'),
            hintText: context.vt('Explain why this group should be deleted'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.vt('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.vt('Submit request')),
          ),
        ],
      ),
    );
    final reason = reasonController.text;
    reasonController.dispose();
    if (!mounted || confirmed != true || _isDeletionActionRunning) return;
    await _runDeletionAction(
      groupId,
      () => ref.read(groupsRepositoryProvider).requestGroupDeletion(
            groupId,
            reason: reason,
          ),
      successMessage,
    );
  }

  Future<void> _approveDeletion(String groupId) async {
    final notesController = TextEditingController();
    final successMessage = context.vt('Group deletion request approved.');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.vt('Approve group deletion request')),
        content: TextField(
          controller: notesController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: context.vt('Approval notes'),
            hintText: context.vt('Optional note for super admin'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.vt('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.vt('Approve request')),
          ),
        ],
      ),
    );
    final notes = notesController.text;
    notesController.dispose();
    if (!mounted || confirmed != true || _isDeletionActionRunning) return;
    await _runDeletionAction(
      groupId,
      () => ref.read(groupsRepositoryProvider).approveGroupDeletion(
            groupId,
            notes: notes,
          ),
      successMessage,
    );
  }

  Future<void> _cancelDeletion(String groupId) async {
    final successMessage = context.vt('Group deletion request cancelled.');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.vt('Cancel deletion request')),
        content: Text(
          context.vt('This will stop the open group deletion request.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.vt('Close')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.vt('Cancel request')),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true || _isDeletionActionRunning) return;
    await _runDeletionAction(
      groupId,
      () => ref.read(groupsRepositoryProvider).cancelGroupDeletion(groupId),
      successMessage,
    );
  }

  Future<void> _runDeletionAction(
    String groupId,
    Future<GroupDeletionRequestSummary> Function() action,
    String successMessage,
  ) async {
    setState(() {
      _errorMessage = '';
      _isDeletionActionRunning = true;
    });
    try {
      await action();
      if (!mounted) return;
      setState(() => _refreshSettings(groupId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = context.vt(AuthFailure.from(error).message));
    } finally {
      if (mounted) {
        setState(() => _isDeletionActionRunning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = ref.watch(activeGroupProvider);
    final canEdit = group?.role == 'GROUP_ADMIN' && !_isUploading;
    final hasLogo = (group?.logoUrl ?? '').isNotEmpty;
    final settingsFuture = _settingsFor(group?.id);

    return VikoplusScreen(
      title: context.vt('Group Profile'),
      backRoute: group?.role == 'GROUP_ADMIN' ? '/settings/admin' : '/more',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: AppInsets.compactCard,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              boxShadow: AppShadows.level1(),
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ProfileAvatar(
                      name: group?.name ?? 'Group',
                      url: group?.logoUrl,
                      radius: 54,
                    ),
                    if (_isUploading)
                      const SizedBox(
                        width: 108,
                        height: 108,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  group?.name ?? context.vt('No active group'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  context.vt(
                    'Add or replace the group icon shown in the app bar and group list.',
                  ),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AuthErrorMessage(message: _errorMessage),
          const SizedBox(height: AppSpacing.sm),
          FilledButton.icon(
            onPressed: canEdit ? _pickAndUpload : null,
            icon: _isUploading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_photo_alternate_outlined, size: 18),
            label: Text(
              _isUploading
                  ? context.vt('Uploading')
                  : context.vt(
                      hasLogo ? 'Replace Group Icon' : 'Add Group Icon',
                    ),
            ),
          ),
          if (group?.role != 'GROUP_ADMIN') ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.vt('Only group admins can update the group icon.'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
          if (group != null) ...[
            const SizedBox(height: AppSpacing.lg),
            FutureBuilder<GroupSettingsResult>(
              future: settingsFuture,
              builder: (context, snapshot) {
                final isLoading =
                    snapshot.connectionState == ConnectionState.waiting;
                final settings = snapshot.data;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _GroupProfileDetailsCard(
                      details: settings?.group,
                      role: group.role,
                      isLoading: isLoading,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _GroupDeletionRequestCard(
                      role: group.role,
                      request: settings?.deletionRequest,
                      isLoading: isLoading,
                      isBusy: _isDeletionActionRunning,
                      onRequest: () => _requestDeletion(group.id),
                      onApprove: () => _approveDeletion(group.id),
                      onCancel: () => _cancelDeletion(group.id),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _GroupProfileDetailsCard extends StatelessWidget {
  const _GroupProfileDetailsCard({
    required this.details,
    required this.role,
    required this.isLoading,
  });

  final GroupProfileDetails? details;
  final String role;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final formatters = AppFormatters(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final group = details;

    return Container(
      padding: AppInsets.card,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  context.vt('Group details'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.vt('Description'),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            group?.description ?? context.vt('No description provided.'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _DetailRow(
            label: context.vt('Type'),
            value: _valueOrNotSet(
              context,
              _groupTypeLabel(context, group?.type),
            ),
          ),
          _DetailRow(
            label: context.vt('Location'),
            value: _valueOrNotSet(context, group?.location),
          ),
          _DetailRow(
            label: context.vt('Currency'),
            value: _valueOrNotSet(context, group?.currency),
          ),
          _DetailRow(
            label: context.vt('Default language'),
            value: _valueOrNotSet(context, group?.defaultLocale?.toUpperCase()),
          ),
          _DetailRow(
            label: context.vt('Established'),
            value: _dateOrNotSet(context, formatters, group?.establishedAt),
          ),
          _DetailRow(
            label: context.vt('Historical data starts'),
            value: _dateOrNotSet(
              context,
              formatters,
              group?.historicalDataStartsAt,
            ),
          ),
          _DetailRow(
            label: context.vt('Created'),
            value: _dateOrNotSet(context, formatters, group?.createdAt),
          ),
          _DetailRow(
            label: context.vt('Updated'),
            value: _dateOrNotSet(context, formatters, group?.updatedAt),
          ),
          _DetailRow(
            label: context.vt('Your role'),
            value: _roleLabel(context, role),
            isLast: true,
          ),
        ],
      ),
    );
  }

  String _dateOrNotSet(
    BuildContext context,
    AppFormatters formatters,
    DateTime? value,
  ) {
    if (value == null) return context.vt('Not set');
    return formatters.date(value.toLocal());
  }

  String _valueOrNotSet(BuildContext context, String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? context.vt('Not set') : trimmed;
  }

  String? _groupTypeLabel(BuildContext context, String? type) {
    final normalized = type?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return null;
    return switch (normalized) {
      'family' => context.vt('Family'),
      'savings' => context.vt('Savings'),
      'welfare' => context.vt('Welfare'),
      'investment' => context.vt('Investment'),
      _ => type,
    };
  }

  String _roleLabel(BuildContext context, String role) {
    return switch (role) {
      'GROUP_ADMIN' => context.vt('Group admin'),
      'TREASURER' => context.vt('Treasurer'),
      'SECRETARY' => context.vt('Secretary'),
      _ => context.vt('Member'),
    };
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupDeletionRequestCard extends StatelessWidget {
  const _GroupDeletionRequestCard({
    required this.role,
    required this.request,
    required this.isLoading,
    required this.isBusy,
    required this.onRequest,
    required this.onApprove,
    required this.onCancel,
  });

  final String role;
  final GroupDeletionRequestSummary? request;
  final bool isLoading;
  final bool isBusy;
  final VoidCallback onRequest;
  final VoidCallback onApprove;
  final VoidCallback onCancel;

  bool get _isAdmin => role == 'GROUP_ADMIN';
  bool get _canApprove => role == 'TREASURER' || role == 'SECRETARY';

  @override
  Widget build(BuildContext context) {
    final current = request;
    return Container(
      padding: AppInsets.card,
      decoration: BoxDecoration(
        color: AppColors.errorContainer.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.delete_outline, color: AppColors.error),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.vt('Group deletion request'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      context.vt(
                        'A group admin can request deletion, then a treasurer or secretary must approve before super admin review.',
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (current == null) ...[
            Text(
              context.vt('No deletion request is open.'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
            if (_isAdmin) ...[
              const SizedBox(height: AppSpacing.sm),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.onError,
                ),
                onPressed: isBusy ? null : onRequest,
                icon: const Icon(Icons.delete_forever_outlined, size: 18),
                label: Text(context.vt('Request deletion')),
              ),
            ],
          ] else ...[
            _DeletionStatusPill(request: current),
            if (current.reason?.trim().isNotEmpty == true) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                current.reason!.trim(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurface,
                    ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Text(
              context
                  .vt('Requested by {name}')
                  .replaceAll(
                    '{name}',
                    current.requestedByName ?? context.vt('Group admin'),
                  ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
            if (current.approvedByName != null)
              Text(
                context
                    .vt('Approved by {name}')
                    .replaceAll('{name}', current.approvedByName!),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
            if (current.isPendingInternalApproval && _canApprove) ...[
              const SizedBox(height: AppSpacing.sm),
              FilledButton.icon(
                onPressed: isBusy ? null : onApprove,
                icon: const Icon(Icons.verified_outlined, size: 18),
                label: Text(context.vt('Approve deletion request')),
              ),
            ],
            if (_isAdmin) ...[
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: isBusy ? null : onCancel,
                icon: const Icon(Icons.close, size: 18),
                label: Text(context.vt('Cancel request')),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _DeletionStatusPill extends StatelessWidget {
  const _DeletionStatusPill({required this.request});

  final GroupDeletionRequestSummary request;

  @override
  Widget build(BuildContext context) {
    final label = request.isApprovedForSuperAdmin
        ? context.vt('Ready for super admin review')
        : context.vt('Waiting for treasurer or secretary approval');
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: request.isApprovedForSuperAdmin
                    ? AppColors.primary
                    : AppColors.error,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}
