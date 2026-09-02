import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/event_provider.dart';
import '../../providers/hidden_member_unlock_provider.dart';
import '../../providers/insurance_provider.dart';
import '../../providers/medical_provider.dart';
import '../../providers/member_provider.dart';
import '../../providers/tab_index_provider.dart';
import '../home/home_page.dart';
import '../insurance/insurance_list_page.dart';
import '../medical/medical_list_page.dart';
import '../timeline/timeline_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late final List<Widget> _pages = <Widget>[
    const HomePage(),
    const InsuranceListPage(),
    const MedicalListPage(),
    const TimelinePage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<MemberProvider>().load();
      await context.read<InsuranceProvider>().load();
      await context.read<MedicalProvider>().load();
      await context.read<EventProvider>().load();
    });
  }

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
      child: Consumer<TabIndexProvider>(
        builder: (context, tab, _) {
          return Scaffold(
            body: SafeArea(
              child: IndexedStack(
                index: tab.index,
                children: _pages,
              ),
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: tab.index,
              onTap: tab.set,
              items: const [
                BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    activeIcon: Icon(Icons.home),
                    label: '首页'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.shield_outlined),
                    activeIcon: Icon(Icons.shield),
                    label: '保险'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.medical_services_outlined),
                    activeIcon: Icon(Icons.medical_services),
                    label: '病历'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.timeline_outlined),
                    activeIcon: Icon(Icons.timeline),
                    label: '时间线'),
              ],
            ),
          );
        },
      ),
    );
  }
}
