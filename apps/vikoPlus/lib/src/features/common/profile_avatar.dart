import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    required this.name,
    this.url,
    this.radius = 24,
    super.key,
  });
  final String name;
  final String? url;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final fallback = Center(
      child: Text(
        name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase(),
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    return SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: ClipOval(
        child: ColoredBox(
          color: AppColors.progressTrack,
          child: url == null || url!.isEmpty
              ? fallback
              : Image.network(
                  url!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => fallback,
                ),
        ),
      ),
    );
  }
}
