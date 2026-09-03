import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_archive/data/models/family_member.dart';
import 'package:family_archive/pages/main/main_page.dart';
import 'package:family_archive/pages/medical/medical_edit_page.dart';
import 'package:family_archive/providers/app_providers.dart';
import 'package:family_archive/widgets/home_sections.dart';

/// 首页改版回归测试：
/// - 家人卡片不再直接显示「已隐藏」文字，改为小问号
/// - 主账号（本人）有星标
/// - 添加家人改为小加号入口
/// - 待办 / 最近动态的空状态文案与快捷入口
/// - 紧急医疗卡放大置顶，其余功能入口弱化
/// - 底部导航不再重复保险 / 病历入口
void main() {
  FamilyMember member({
    required String id,
    required String name,
    String relation = '本人',
    bool hidden = false,
  }) {
    final now = DateTime.now();
    return FamilyMember(
      id: id,
      name: name,
      relation: relation,
      birthday: DateTime(1990, 1, 1),
      createdAt: now,
      updatedAt: now,
      hidden: hidden,
    );
  }

  /// 页面跳转会读取业务 Provider，因此统一挂在 BusinessProviders 下
  Widget wrap(Widget child) {
    return BusinessProviders(
      child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
    );
  }

  testWidgets('家人卡片：显示关系而不是「已隐藏」，主账号带星标', (tester) async {
    await tester.pumpWidget(
      wrap(
        HomeMemberCard(
          member: member(id: 'm1', name: '张三', relation: '本人'),
          onTap: () {},
          onToggleHidden: (_) {},
        ),
      ),
    );

    expect(find.text('张三'), findsOneWidget);
    expect(find.text('本人'), findsOneWidget);
    expect(find.text('已隐藏'), findsNothing);
    // 主账号星标
    expect(find.byIcon(Icons.star), findsOneWidget);
    // 未隐藏时不出现问号
    expect(find.byIcon(Icons.help_outline), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('隐藏成员用小问号提示，可在弹层里切换显示状态', (tester) async {
    final toggled = <bool>[];
    await tester.pumpWidget(
      wrap(
        HomeMemberCard(
          member: member(
            id: 'm2',
            name: '李四',
            relation: '弟弟',
            hidden: true,
          ),
          onTap: () {},
          onToggleHidden: toggled.add,
        ),
      ),
    );

    // 隐藏状态不再以文字占位
    expect(find.text('已隐藏'), findsNothing);
    expect(find.byIcon(Icons.help_outline), findsOneWidget);

    await tester.tap(find.byIcon(Icons.help_outline));
    await tester.pumpAndSettle();

    // 弹层说明隐藏的含义，并提供一键切换
    expect(find.textContaining('该档案已隐藏'), findsOneWidget);
    expect(find.text('取消隐藏，直接显示'), findsOneWidget);

    await tester.tap(find.text('取消隐藏，直接显示'));
    await tester.pumpAndSettle();

    // 传入的是切换后的目标状态
    expect(toggled, equals([false]));
    expect(tester.takeException(), isNull);
  });

  testWidgets('非隐藏成员同样可以一键设为隐藏', (tester) async {
    final toggled = <bool>[];
    await tester.pumpWidget(
      wrap(
        HomeMemberCard(
          member: member(id: 'm3', name: '王五', relation: '母亲'),
          onTap: () {},
          onToggleHidden: toggled.add,
        ),
      ),
    );

    // 非隐藏时没有角标，这里直接唤出说明弹层验证文案。
    // showHint 的 Future 要等弹层关闭才完成，因此不能 await。
    final card = tester.widget<HomeMemberCard>(find.byType(HomeMemberCard));
    unawaited(card.showHint(tester.element(find.byType(HomeMemberCard))));
    await tester.pumpAndSettle();

    expect(find.textContaining('该档案当前公开显示'), findsOneWidget);
    expect(find.text('设为隐藏，需密码查看'), findsOneWidget);

    await tester.tap(find.text('设为隐藏，需密码查看'));
    await tester.pumpAndSettle();

    expect(toggled, equals([true]));
    expect(tester.takeException(), isNull);
  });

  testWidgets('添加家人是小加号入口，不再占一大块卡片', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(HomeAddMemberChip(onTap: () => tapped = true)),
    );

    expect(find.text('添加'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
    // 不再是整块的「添加家人」卡片
    expect(find.text('添加家人'), findsNothing);

    await tester.tap(find.text('添加'));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('待办为空时给出来源说明与新建入口', (tester) async {
    await tester.pumpWidget(wrap(const ReminderEmptySection()));

    expect(
      find.text('暂无待办，可以新增复查、体检、保单缴费提醒'),
      findsOneWidget,
    );
    expect(find.text('新建提醒'), findsOneWidget);

    await tester.tap(find.text('新建提醒'));
    await tester.pumpAndSettle();

    expect(find.text('复诊 / 复查提醒'), findsOneWidget);
    expect(find.text('保单缴费 / 续保提醒'), findsOneWidget);
    expect(find.text('手动记录家庭大事'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('新建提醒可直达就诊记录录入页', (tester) async {
    await tester.pumpWidget(wrap(const ReminderEmptySection()));

    await tester.tap(find.text('新建提醒'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('复诊 / 复查提醒'));
    await tester.pumpAndSettle();

    expect(find.byType(MedicalEditPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('功能模块：紧急医疗卡置顶放大，其余入口弱化并带说明', (tester) async {
    await tester.pumpWidget(wrap(const FunctionEntries()));

    // 紧急卡是第一屏卖点
    expect(find.text('紧急医疗卡'), findsOneWidget);
    expect(
      find.text('一键展示血型、过敏史、既往病史，可存相册给医生看'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.emergency), findsOneWidget);

    // 其余三个入口：文案调整 + 功能说明
    expect(find.text('就医 & 病历'), findsOneWidget);
    expect(find.text('保险档案'), findsOneWidget);
    expect(find.text('家庭大事件'), findsOneWidget);
    expect(find.text('就诊记录与复诊'), findsOneWidget);
    expect(find.text('保单集中管理'), findsOneWidget);
    expect(find.text('健康大事时间线'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('最近动态为空时给出说明与「手动记录」入口', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(RecentEventsEmpty(onManualRecord: () => tapped = true)),
    );

    expect(find.text('暂无家庭事件'), findsOneWidget);
    expect(
      find.text('录入病历、保单将自动生成动态，也可以手动记录家庭健康大事'),
      findsOneWidget,
    );

    await tester.tap(find.text('手动记录'));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
    expect(tester.takeException(), isNull);
  });

  test('底部导航为首页 / 家庭档案 / 时间线 / 我的', () {
    expect(
      mainNavItems.map((e) => e.label).toList(),
      equals(['首页', '家庭档案', '时间线', '我的']),
    );
  });
}
