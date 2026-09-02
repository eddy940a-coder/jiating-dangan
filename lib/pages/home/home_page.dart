import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/family_event.dart';
import '../../data/models/family_member.dart';
import '../../data/models/insurance.dart';
import '../../data/models/medical_record.dart';
import '../../providers/event_provider.dart';
import '../../providers/insurance_provider.dart';
import '../../providers/medical_provider.dart';
import '../../providers/member_provider.dart';
import '../../providers/tab_index_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/date_util.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/reminder_badge.dart';
import '../../widgets/section_title.dart';
import '../emergency/emergency_card_page.dart';
import '../insurance/insurance_detail_page.dart';
import '../member/member_edit_page.dart';
import '../medical/medical_detail_page.dart';
import '../settings/settings_page.dart';
import '../timeline/timeline_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final members = context.watch<MemberProvider>().all;
    final insurances = context.watch<InsuranceProvider>().all;
    final medicals = context.watch<MedicalProvider>().all;
    final events = context.watch<EventProvider>().all;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          '家庭档案',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: '设置',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
          ),
        ],
      ),
      body: members.isEmpty
          ? _EmptyHome()
          : ListView(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
              children: [
                _MembersHorizontal(members: members),
                const SectionTitle(title: '待办提醒'),
                _Reminders(
                  insurances: insurances,
                  medicals: medicals,
                  members: members,
                ),
                const SectionTitle(title: '功能'),
                const _FunctionGrid(),
                const SectionTitle(title: '最近动态'),
                _RecentEvents(events: events, members: members),
                const SizedBox(height: 16),
                const _Disclaimer(),
              ],
            ),
    );
  }
}

class _EmptyHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.family_restroom_outlined,
      message: '还没有添加任何家庭成员\n点击下方按钮，先添加第一位家人',
      action: ElevatedButton.icon(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MemberEditPage()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('添加家人'),
      ),
    );
  }
}

class _MembersHorizontal extends StatelessWidget {
  const _MembersHorizontal({required this.members});
  final List<FamilyMember> members;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 152,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: members.length + 1,
        itemBuilder: (context, i) {
          if (i == members.length) {
            return _AddMemberCard();
          }
          final m = members[i];
          return _MemberCard(
            member: m,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MemberEditPage(member: m),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member, required this.onTap});
  final FamilyMember member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 108,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppAvatar(member: member, size: 52),
            const SizedBox(height: 8),
            Text(
              member.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              member.hidden ? '已隐藏' : member.relation,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              member.birthday == null ? '未设生日' : '${member.age}岁',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddMemberCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const MemberEditPage()),
      ),
      child: Container(
        width: 108,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary, width: 1.2),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline,
                color: AppColors.primary, size: 36),
            SizedBox(height: 8),
            Text('添加家人',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
      ),
    );
  }
}

class _Reminders extends StatelessWidget {
  const _Reminders({
    required this.insurances,
    required this.medicals,
    required this.members,
  });

  final List<Insurance> insurances;
  final List<MedicalRecord> medicals;
  final List<FamilyMember> members;

  String _name(String id) {
    for (final m in members) {
      if (m.id == id) return m.name;
    }
    return '未知';
  }

  @override
  Widget build(BuildContext context) {
    final items = <_ReminderItem>[];

    for (final i in insurances) {
      if (!i.remindEnabled || i.expireDate == null) continue;
      if (i.status == '已失效') continue;
      final d = DateUtil.daysUntil(i.expireDate!);
      if (d < 0) {
        items.add(_ReminderItem(
          icon: Icons.shield_outlined,
          color: AppColors.red,
          title: '保单已过期 · ${i.type}',
          subtitle: '${_name(i.memberId)} · ${i.company}',
          timeText: '已过期 ${-d} 天',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => InsuranceDetailPage(insurance: i),
            ),
          ),
        ));
      } else if (d <= 30) {
        items.add(_ReminderItem(
          icon: Icons.shield_outlined,
          color: AppColors.orange,
          title: '保单即将到期 · ${i.type}',
          subtitle: '${_name(i.memberId)} · ${i.company}',
          timeText: '$d 天后到期',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => InsuranceDetailPage(insurance: i),
            ),
          ),
        ));
      }
    }

    for (final r in medicals) {
      if (!r.revisitRemind || r.revisitTime == null) continue;
      final d = DateUtil.daysUntil(r.revisitTime!);
      if (d < 0) {
        items.add(_ReminderItem(
          icon: Icons.medical_services_outlined,
          color: AppColors.red,
          title: '复诊已逾期 · ${r.visitType}',
          subtitle:
              '${_name(r.memberId)} · ${r.hospital.isEmpty ? "复诊" : r.hospital}',
          timeText: '逾期 ${-d} 天',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MedicalDetailPage(record: r),
            ),
          ),
        ));
      } else if (d <= 7) {
        items.add(_ReminderItem(
          icon: Icons.medical_services_outlined,
          color: AppColors.orange,
          title: '复诊提醒 · ${r.visitType}',
          subtitle:
              '${_name(r.memberId)} · ${r.hospital.isEmpty ? "复诊" : r.hospital}',
          timeText: d == 0 ? '今日复诊' : '$d 天后',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MedicalDetailPage(record: r),
            ),
          ),
        ));
      }
    }

    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: AppCard(
          child: Row(
            children: [
              Icon(Icons.notifications_off_outlined, color: AppColors.textHint),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '近期没有需要处理的提醒',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AppCard(
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: AppColors.divider),
              InkWell(
                onTap: items[i].onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: items[i].color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(items[i].icon, color: items[i].color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(items[i].title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                )),
                            const SizedBox(height: 2),
                            Text(items[i].subtitle,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                )),
                          ],
                        ),
                      ),
                      ReminderBadge(
                        color: items[i].color,
                        text: items[i].timeText,
                      ),
                    ],
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class _ReminderItem {
  _ReminderItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.timeText,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String timeText;
  final VoidCallback onTap;
}

class _FunctionGrid extends StatelessWidget {
  const _FunctionGrid();

  @override
  Widget build(BuildContext context) {
    final items = <_Fn>[
      _Fn('保险档案', Icons.shield_outlined, AppColors.primary, () {
        context.read<TabIndexProvider>().set(1);
      }),
      _Fn('就医病历', Icons.medical_services_outlined, AppColors.red, () {
        context.read<TabIndexProvider>().set(2);
      }),
      _Fn('家庭大事件', Icons.timeline_outlined, AppColors.yellow, () {
        context.read<TabIndexProvider>().set(3);
      }),
      _Fn('紧急医疗卡', Icons.emergency_outlined, AppColors.orange, () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const EmergencyCardPage()),
        );
      }),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.6,
        children: items.map((e) => _FnCard(item: e)).toList(),
      ),
    );
  }
}

class _Fn {
  _Fn(this.label, this.icon, this.color, this.onTap);
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _FnCard extends StatelessWidget {
  const _FnCard({required this.item});
  final _Fn item;
  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: item.onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textHint),
        ],
      ),
    );
  }
}

class _RecentEvents extends StatelessWidget {
  const _RecentEvents({required this.events, required this.members});
  final List<FamilyEvent> events;
  final List<FamilyMember> members;

  String _name(String id) {
    for (final m in members) {
      if (m.id == id) return m.name;
    }
    return '未知';
  }

  @override
  Widget build(BuildContext context) {
    final list = events.take(3).toList();
    if (list.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: AppCard(
          child: Text(
            '暂无家庭事件。保存保单或病历会自动生成事件，也可以手动记录。',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AppCard(
        child: Column(
          children: [
            for (var i = 0; i < list.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: AppColors.divider),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _EventDot(type: list[i].type),
                title: Text(list[i].title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                subtitle: Text(
                  '${DateUtil.ymd(list[i].eventTime)} · ${list[i].memberIds.map(_name).join("、")}',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
            ],
            const Divider(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const TimelinePage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chevron_right, size: 18),
                  label: const Text('查看全部'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventDot extends StatelessWidget {
  const _EventDot({required this.type});
  final String type;
  @override
  Widget build(BuildContext context) {
    final c = switch (type) {
      kEventTypeInsurance => AppColors.eventInsurance,
      kEventTypeMedical => AppColors.eventMedical,
      _ => AppColors.eventManual,
    };
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        '免责声明：本 App 仅做记录，不提供医疗诊断或保险建议，所有数据仅保存在本机，App 被系统杀死后本地通知可能不再触发。',
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textHint,
          height: 1.5,
        ),
      ),
    );
  }
}
