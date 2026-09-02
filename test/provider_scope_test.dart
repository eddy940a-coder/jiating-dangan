import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:family_archive/pages/insurance/insurance_edit_page.dart';
import 'package:family_archive/pages/medical/medical_edit_page.dart';
import 'package:family_archive/pages/timeline/event_edit_page.dart';
import 'package:family_archive/providers/app_providers.dart';
import 'package:family_archive/providers/member_provider.dart';

/// 回归测试：业务 Provider 必须注册在 Navigator 之上。
///
/// 历史 bug：Provider 曾挂在 MainPage（MaterialApp 的 home）内部，导致所有
/// `Navigator.push` 打开的页面在 build 第一行 `context.watch<MemberProvider>()`
/// 就抛 ProviderNotFoundException，表现为「新增保单 / 病历 / 事件点进去是红屏」。
void main() {
  Widget buildApp() {
    return const BusinessProviders(
      child: MaterialApp(home: _Launcher()),
    );
  }

  testWidgets('新增保单页：push 之后仍能读取业务 Provider', (tester) async {
    await tester.pumpWidget(buildApp());

    await tester.tap(find.text('打开-保单'));
    await tester.pumpAndSettle();

    expect(find.byType(InsuranceEditPage), findsOneWidget);
    expect(find.text('新增保单'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final element = tester.element(find.byType(InsuranceEditPage));
    expect(Provider.of<MemberProvider>(element, listen: false), isNotNull);
  });

  testWidgets('新增病历页：push 之后仍能读取业务 Provider', (tester) async {
    await tester.pumpWidget(buildApp());

    await tester.tap(find.text('打开-病历'));
    await tester.pumpAndSettle();

    expect(find.byType(MedicalEditPage), findsOneWidget);
    expect(find.text('新增病历'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final element = tester.element(find.byType(MedicalEditPage));
    expect(Provider.of<MemberProvider>(element, listen: false), isNotNull);
  });

  testWidgets('新增事件页：push 之后仍能读取业务 Provider', (tester) async {
    await tester.pumpWidget(buildApp());

    await tester.tap(find.text('打开-事件'));
    await tester.pumpAndSettle();

    expect(find.byType(EventEditPage), findsOneWidget);
    expect(find.text('新增家庭事件'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final element = tester.element(find.byType(EventEditPage));
    expect(Provider.of<MemberProvider>(element, listen: false), isNotNull);
  });

  testWidgets('还没有成员时，编辑页给出引导提示而不是空白下拉框', (tester) async {
    await tester.pumpWidget(buildApp());

    await tester.tap(find.text('打开-保单'));
    await tester.pumpAndSettle();
    expect(find.textContaining('还没有家庭成员'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('打开-病历'));
    await tester.pumpAndSettle();
    expect(find.textContaining('还没有家庭成员'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('打开-事件'));
    await tester.pumpAndSettle();
    expect(find.textContaining('还没有家庭成员'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _Launcher extends StatelessWidget {
  const _Launcher();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                    builder: (_) => const InsuranceEditPage()),
              ),
              child: const Text('打开-保单'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                    builder: (_) => const MedicalEditPage()),
              ),
              child: const Text('打开-病历'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const EventEditPage()),
              ),
              child: const Text('打开-事件'),
            ),
          ],
        ),
      ),
    );
  }
}
