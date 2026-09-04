import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/uploads/uploads_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../common/vikoplus_screen.dart';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  String? _localImagePath;
  String? _profileImageUrl;
  String _errorMessage = '';
  bool _isUploading = false;

  Future<void> _pickProfilePicture() async {
    if (_isUploading) return;

    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 84,
    );
    if (image == null) return;

    setState(() {
      _localImagePath = image.path;
      _errorMessage = '';
      _isUploading = true;
    });
    try {
      final uploaded =
          await ref.read(uploadsRepositoryProvider).uploadProfilePicture(image);
      if (!mounted) return;
      setState(() => _profileImageUrl = uploaded.url);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = AuthFailure.from(error).message);
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return VikoplusScreen(
      title: 'Complete Profile',
      backRoute: '/more',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: _ProfilePhotoUploader(
              imageUrl: _profileImageUrl,
              localImagePath: _localImagePath,
              isUploading: _isUploading,
              onTap: _pickProfilePicture,
            ),
          ),
          if (_errorMessage.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Full name',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Phone number',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Email address',
              prefixIcon: Icon(Icons.mail_outline),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: _isUploading ? null : () => context.go('/more'),
            child: const Text('Save Profile'),
          ),
        ],
      ),
    );
  }
}

class _ProfilePhotoUploader extends StatelessWidget {
  const _ProfilePhotoUploader({
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
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: isUploading ? null : onTap,
            child: Container(
              width: 96,
              height: 96,
              alignment: Alignment.center,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.outlineVariant, width: 2),
              ),
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
                        color: AppColors.primary,
                        size: 40,
                      ),
                    ),
                  if (isUploading)
                    const ColoredBox(
                      color: Color(0x66000000),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
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
              ? 'Change Profile Photo'
              : 'Upload Profile Photo',
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }
}
