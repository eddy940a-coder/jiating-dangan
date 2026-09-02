import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'services/notification_service.dart';
import 'services/settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 仅竖屏
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);

  // 启动关键服务（无网络，零后端）
  await SettingsService.instance.init();
  await NotificationService.instance.init();

  runApp(const FamilyArchiveApp());
}
