import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/event_provider.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  /// 业务 Provider 由 `BusinessProviders` 注册在 MaterialApp 之上，
  /// 因此这里以及所有 push 出去的页面都可以正常读取。
  Future<void> _loadAll() async {
    await context.read<MemberProvider>().load();
    if (!mounted) return;
    await context.read<InsuranceProvider>().load();
    if (!mounted) return;
    await context.read<MedicalProvider>().load();
    if (!mounted) return;
    await context.read<EventProvider>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TabIndexProvider>(
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
    );
  }
}
