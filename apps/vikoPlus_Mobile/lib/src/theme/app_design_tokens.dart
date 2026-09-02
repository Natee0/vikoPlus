import 'package:flutter/material.dart';

class AppSpacing {
  static const unit = 8.0;
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 16.0;
  static const md = 24.0;
  static const lg = 32.0;
  static const xl = 40.0;
  static const screenMobile = 16.0;
  static const screenEdge = 24.0;
  static const gutter = 16.0;
}

class AppRadii {
  static const sm = 4.0;
  static const base = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const pill = 28.0;
}

class AppSizes {
  static const topBarHeight = 56.0;
  static const buttonHeight = 56.0;
  static const inputHeight = 56.0;
  static const compactInputHeight = 48.0;
  static const iconButton = 48.0;
  static const brandLogo = 56.0;
  static const splashLogo = 72.0;
  static const uploadLogo = 84.0;
  static const choiceIcon = 52.0;
  static const maxContentWidth = 420.0;
}

class AppInsets {
  static const screen = EdgeInsets.all(AppSpacing.screenMobile);
  static const screenEdge = EdgeInsets.symmetric(
    horizontal: AppSpacing.screenEdge,
  );
  static const card = EdgeInsets.all(AppSpacing.md);
  static const compactCard = EdgeInsets.all(AppSpacing.sm);
}

class AppShadows {
  static List<BoxShadow> level1() {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ];
  }

  static List<BoxShadow> level2() {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.08),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ];
  }
}
