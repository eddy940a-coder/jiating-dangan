import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'pages/lock/lock_page.dart';
import 'pages/lock/set_password_page.dart';
import 'pages/main/main_page.dart';
import 'pages/splash/splash_page.dart';
import 'providers/app_providers.dart';
import 'providers/app_settings_provider.dart';
import 'theme/app_theme.dart';

class FamilyArchiveApp extends StatelessWidget {
  const FamilyArchiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppSettingsProvider>(
      create: (_) => AppSettingsProvider()..load(),
      child: const _Root(),
    );
  }
}

class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

/// 统一的 MaterialApp 壳：固定中文 locale，使系统日期选择器、对话框等
/// 全部显示中文。
class _App extends StatelessWidget {
  const _App({required this.home});

  final Widget home;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '家庭档案',
      theme: AppTheme.build(settings.fontLevel),
      // 强制中文，日历、日期选择器等系统组件会显示"2026年 9月"、"星期三"等。
      locale: const Locale('zh', 'CN'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
      ],
      home: home,
    );
  }
}

class _RootState extends State<_Root> {
  bool _splashDone = false;
  bool _unlocked = false;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();

    // 未解锁前不加载任何业务数据
    final Widget body;
    if (!_splashDone) {
      body = SplashPage(onFinish: () => setState(() => _splashDone = true));
    } else if (!settings.hasPassword) {
      body = const SetPasswordPage();
    } else if (settings.lockEnabled && !_unlocked) {
      body = LockPage(onUnlocked: () => setState(() => _unlocked = true));
    } else {
      body = const MainPage();
    }

    return BusinessProviders(
      child: _App(home: body),
    );
  }
}
