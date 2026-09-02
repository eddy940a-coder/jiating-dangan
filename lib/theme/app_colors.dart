import 'package:flutter/material.dart';

/// 全局配色，严格遵循设计规范。
class AppColors {
  AppColors._();

  /// 主色 - 档案蓝
  static const Color primary = Color(0xFF1E4ED8);
  static const Color primaryDark = Color(0xFF1738A6);
  static const Color primaryLight = Color(0xFFE8EDFC);

  /// 提醒橙
  static const Color orange = Color(0xFFF97316);

  /// 医疗红
  static const Color red = Color(0xFFEF4444);

  /// 事件黄
  static const Color yellow = Color(0xFFEAB308);

  /// 中性
  static const Color background = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFF9FAFB);
  static const Color divider = Color(0xFFE5E7EB);

  /// 文本
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textHint = Color(0xFF9CA3AF);

  /// 成功
  static const Color success = Color(0xFF16A34A);

  /// 事件类型色
  static const Color eventInsurance = primary;
  static const Color eventMedical = red;
  static const Color eventManual = yellow;
}
