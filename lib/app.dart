import 'package:flutter/material.dart';
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

    // 业务 Provider 必须位于 Navigator 之上，否则所有 push 出来的页面
    // （新增保单 / 新增病历 / 新增事件…）都读不到数据而红屏。
    return BusinessProviders(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: '家庭档案',
        theme: AppTheme.build(settings.fontLevel),
        home: body,
      ),
    );
  }
}
