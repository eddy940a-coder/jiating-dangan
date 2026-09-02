import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'event_provider.dart';
import 'hidden_member_unlock_provider.dart';
import 'insurance_provider.dart';
import 'medical_provider.dart';
import 'member_provider.dart';
import 'tab_index_provider.dart';

/// 把业务 Provider 注入子树。
///
/// 必须注册在 `MaterialApp` **之上**：Navigator 的各个路由页与 home 是平级的
/// Overlay entry，若把 Provider 挂在 home（MainPage）内部，所有通过
/// `Navigator.push` 打开的页面（新增保单 / 新增病历 / 新增事件等）都取不到
/// 这些 Provider，会在 build 第一行抛 ProviderNotFoundException 而红屏。
class BusinessProviders extends StatelessWidget {
  const BusinessProviders({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<MemberProvider>(create: (_) => MemberProvider()),
        ChangeNotifierProvider<InsuranceProvider>(
            create: (_) => InsuranceProvider()),
        ChangeNotifierProvider<MedicalProvider>(
            create: (_) => MedicalProvider()),
        ChangeNotifierProvider<EventProvider>(create: (_) => EventProvider()),
        ChangeNotifierProvider<HiddenMemberUnlockProvider>(
          create: (_) => HiddenMemberUnlockProvider(),
        ),
        ChangeNotifierProvider<TabIndexProvider>(
          create: (_) => TabIndexProvider(),
        ),
      ],
      child: child,
    );
  }
}
