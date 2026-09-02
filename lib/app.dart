import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/lock/lock_page.dart';
import 'pages/lock/set_password_page.dart';
import 'pages/main/main_page.dart';
import 'pages/splash/splash_page.dart';
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

class _RootState extends State<_Root> {
  bool _splashDone = false;
  bool _unlocked = false;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();

    if (!_splashDone) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(settings.fontLevel),
        home: SplashPage(onFinish: () => setState(() => _splashDone = true)),
      );
    }

    // 未解锁前不加载任何业务数据
    final Widget body;
    if (!settings.hasPassword) {
      body = const SetPasswordPage();
    } else if (settings.lockEnabled && !_unlocked) {
      body = LockPage(onUnlocked: () => setState(() => _unlocked = true));
    } else {
      body = const MainPage();
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '家庭档案',
      theme: AppTheme.build(settings.fontLevel),
      home: body,
    );
  }
}
