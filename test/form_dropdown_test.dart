import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_archive/widgets/form_widgets.dart';

void main() {
  Widget buildApp(FormDropdown<String> field) {
    return MaterialApp(home: Scaffold(body: SingleChildScrollView(child: field)));
  }

  testWidgets('候选项为空时不崩溃', (tester) async {
    await tester.pumpWidget(
      buildApp(
        FormDropdown<String>(
          label: '归属成员',
          value: 'member-1',
          items: const <DropdownMenuItem<String>>[],
          onChanged: (_) {},
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('归属成员'), findsOneWidget);
  });

  testWidgets('value 不在候选项中时回退为空选，不崩溃', (tester) async {
    await tester.pumpWidget(
      buildApp(
        FormDropdown<String>(
          label: '保单状态',
          value: '已失效',
          items: const [
            DropdownMenuItem<String>(value: '有效', child: Text('有效')),
            DropdownMenuItem<String>(value: '即将到期', child: Text('即将到期')),
          ],
          onChanged: (_) {},
        ),
      ),
    );

    expect(tester.takeException(), isNull);

    final dropdown = tester.widget<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>),
    );
    expect(dropdown.initialValue, isNull);
  });

  testWidgets('value 命中候选项时正常保留', (tester) async {
    await tester.pumpWidget(
      buildApp(
        FormDropdown<String>(
          label: '保单状态',
          value: '有效',
          items: const [
            DropdownMenuItem<String>(value: '有效', child: Text('有效')),
            DropdownMenuItem<String>(value: '已失效', child: Text('已失效')),
          ],
          onChanged: (_) {},
        ),
      ),
    );

    final dropdown = tester.widget<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>),
    );
    expect(dropdown.initialValue, '有效');
  });
}
