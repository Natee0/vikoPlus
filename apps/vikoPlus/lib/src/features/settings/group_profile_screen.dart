import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/auth/auth_controller.dart';
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
  String _errorMessage = '';

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
      setState(() => _errorMessage = AuthFailure.from(error).message);
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = ref.watch(activeGroupProvider);
    final canEdit = group?.role == 'GROUP_ADMIN' && !_isUploading;
    final hasLogo = (group?.logoUrl ?? '').isNotEmpty;

    return VikoplusScreen(
      title: context.vt('Group Profile'),
      backRoute: '/settings/admin',
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
        ],
      ),
    );
  }
}
