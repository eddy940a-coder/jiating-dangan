import 'package:flutter/material.dart';

import 'app_colors.dart';

/// 字体三档
enum FontScaleLevel {
  small,
  normal,
  large;

  double get factor {
    switch (this) {
      case FontScaleLevel.small:
        return 0.9;
      case FontScaleLevel.normal:
        return 1.0;
      case FontScaleLevel.large:
        return 1.18;
    }
  }

  String get label {
    switch (this) {
      case FontScaleLevel.small:
        return '小';
      case FontScaleLevel.normal:
        return '标准';
      case FontScaleLevel.large:
        return '大';
    }
  }
}

/// 全局文本风格封装。页面通过 `context.text` 获取当前档位下的样式集。
class AppText {
  AppText({this.scale = 1.0});

  final double scale;

  TextStyle get title => TextStyle(
        fontSize: 18 * scale,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  TextStyle get body => TextStyle(
        fontSize: 16 * scale,
        color: AppColors.textPrimary,
        height: 1.45,
      );

  TextStyle get caption => TextStyle(
        fontSize: 14 * scale,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  TextStyle get hint => TextStyle(
        fontSize: 14 * scale,
        color: AppColors.textHint,
        height: 1.4,
      );

  TextStyle get titleLarge => TextStyle(
        fontSize: 22 * scale,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  TextStyle get button => TextStyle(
        fontSize: 16 * scale,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        height: 1.2,
      );

  TextStyle get tag => TextStyle(
        fontSize: 12 * scale,
        fontWeight: FontWeight.w500,
        color: Colors.white,
        height: 1.1,
      );
}

/// 通过 Provider 暴露当前档位的 AppText。
class AppTextProvider extends InheritedWidget {
  const AppTextProvider({
    super.key,
    required this.text,
    required super.child,
  });

  final AppText text;

  static AppText of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<AppTextProvider>();
    return provider?.text ?? AppText();
  }

  @override
  bool updateShouldNotify(AppTextProvider oldWidget) => oldWidget.text.scale != text.scale;
}
