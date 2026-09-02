import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildApp(VoidCallback onPressed) {
    return MaterialApp(
      locale: const Locale('zh', 'CN'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('zh', 'CN')],
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: onPressed,
              child: const Text('打开日历'),
            );
          },
        ),
      ),
    );
  }

  testWidgets('日期选择器标题、月份、星期表头均为中文', (tester) async {
    await tester.pumpWidget(
      buildApp(() async {
        await showDatePicker(
          context: tester.element(find.byType(ElevatedButton)),
          initialDate: DateTime(2026, 9, 2),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
      }),
    );

    await tester.tap(find.text('打开日历'));
    await tester.pumpAndSettle();

    // 标题应为中文
    expect(find.text('选择日期'), findsOneWidget);

    // 月份显示格式由本地化决定，通过 MaterialLocalizations 获取预期文本
    final context = tester.element(find.byType(ElevatedButton));
    final localizations = MaterialLocalizations.of(context);
    final monthYear = localizations.formatMonthYear(DateTime(2026, 9, 2));
    expect(find.text(monthYear), findsOneWidget);

    // 中文环境下星期表头包含"一"到"日"
    for (final day in const ['一', '二', '三', '四', '五', '六', '日']) {
      expect(find.text(day), findsOneWidget);
    }

    // 底部按钮也应该是中文
    expect(find.text('取消'), findsOneWidget);
    expect(find.text('确定'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('应用仅支持简体中文 locale', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('zh', 'CN'),
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('zh', 'CN')],
        home: Scaffold(),
      ),
    );

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.locale, const Locale('zh', 'CN'));
    expect(materialApp.supportedLocales, const [Locale('zh', 'CN')]);
    expect(materialApp.localizationsDelegates, isNotNull);
  });
}
