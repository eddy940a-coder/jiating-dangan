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
import '../../theme/app_colors.dart';
import '../../utils/date_util.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/home_sections.dart';
import '../../widgets/reminder_badge.dart';
import '../../widgets/section_title.dart';
import '../insurance/insurance_detail_page.dart';
import '../member/member_edit_page.dart';
import '../medical/medical_detail_page.dart';
import '../timeline/event_edit_page.dart';
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
      ),
      body: members.isEmpty
          ? const _EmptyHome()
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
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: FunctionEntries(),
                ),
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
  const _EmptyHome();

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.family_restroom_outlined,
      message: '还没有添加任何家庭成员\n点击下方按钮，先添加第一位家人',
      action: ElevatedButton.icon(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
              builder: (_) => const MemberEditPage()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('添加家人'),
      ),
    );
  }
}

/// 家人横向卡片，家人多的时候横向滚动切换
class _MembersHorizontal extends StatelessWidget {
  const _MembersHorizontal({required this.members});
  final List<FamilyMember> members;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 148,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: members.length + 1,
        itemBuilder: (context, i) {
          if (i == members.length) {
            return HomeAddMemberChip(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                    builder: (_) => const MemberEditPage()),
              ),
            );
          }
          final m = members[i];
          return HomeMemberCard(
            member: m,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                  builder: (_) => MemberEditPage(member: m)),
            ),
            onToggleHidden: (hidden) async {
              await context
                  .read<MemberProvider>()
                  .setHidden(m.id, hidden);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    hidden
                        ? '「${m.name}」已设为隐藏'
                        : '「${m.name}」已取消隐藏',
                  ),
                ),
              );
            },
          );
        },
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
          days: d,
          icon: Icons.shield_outlined,
          color: AppColors.red,
          title: '保单已过期 · ${i.type}',
          subtitle: '${_name(i.memberId)} · ${i.company}',
          timeText: '已过期 ${-d} 天',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
                builder: (_) => InsuranceDetailPage(insurance: i)),
          ),
        ));
      } else if (d <= 30) {
        items.add(_ReminderItem(
          days: d,
          icon: Icons.shield_outlined,
          color: AppColors.orange,
          title: '保单即将到期 · ${i.type}',
          subtitle: '${_name(i.memberId)} · ${i.company}',
          timeText: '$d 天后到期',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
                builder: (_) => InsuranceDetailPage(insurance: i)),
          ),
        ));
      }
    }

    for (final r in medicals) {
      final toDetail = () => Navigator.of(context).push(
            MaterialPageRoute<void>(
                builder: (_) => MedicalDetailPage(record: r)),
          );

      if (r.revisitRemind && r.revisitTime != null) {
        final d = DateUtil.daysUntil(r.revisitTime!);
        if (d < 0) {
          items.add(_ReminderItem(
            days: d,
            icon: Icons.medical_services_outlined,
            color: AppColors.red,
            title: '复诊已逾期 · ${r.visitType}',
            subtitle:
                '${_name(r.memberId)} · ${r.hospital.isEmpty ? "复诊" : r.hospital}',
            timeText: '逾期 ${-d} 天',
            onTap: toDetail,
          ));
        } else if (d <= 7) {
          items.add(_ReminderItem(
            days: d,
            icon: Icons.medical_services_outlined,
            color: AppColors.orange,
            title: '复诊提醒 · ${r.visitType}',
            subtitle:
                '${_name(r.memberId)} · ${r.hospital.isEmpty ? "复诊" : r.hospital}',
            timeText: d == 0 ? '今日复诊' : '$d 天后',
            onTap: toDetail,
          ));
        }
      }

      // 体检是一年一次，提前 30 天开始提醒
      if (r.checkupRemind && r.nextCheckupDate != null) {
        final d = DateUtil.daysUntil(r.nextCheckupDate!);
        if (d < 0) {
          items.add(_ReminderItem(
            days: d,
            icon: Icons.monitor_heart_outlined,
            color: AppColors.red,
            title: '体检已逾期',
            subtitle: '${_name(r.memberId)} · 距计划体检日已过 ${-d} 天',
            timeText: '逾期 ${-d} 天',
            onTap: toDetail,
          ));
        } else if (d <= 30) {
          items.add(_ReminderItem(
            days: d,
            icon: Icons.monitor_heart_outlined,
            color: AppColors.orange,
            title: '体检提醒',
            subtitle: '${_name(r.memberId)} · 一年一度的体检时间到了',
            timeText: d == 0 ? '今日体检' : '$d 天后',
            onTap: toDetail,
          ));
        }
      }
    }

    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: ReminderEmptySection(),
      );
    }

    // 越临近（含已逾期）的排越前，最紧急的一条高亮
    items.sort((a, b) => a.days.compareTo(b.days));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: AppColors.divider),
              _ReminderTile(
                item: items[i],
                highlight: i == 0,
                roundBottom: items.length == 1,
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({
    required this.item,
    required this.highlight,
    required this.roundBottom,
  });

  final _ReminderItem item;
  final bool highlight;
  final bool roundBottom;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: highlight
          ? BoxDecoration(
              color: item.color.withOpacity(0.08),
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(12),
                bottom: Radius.circular(roundBottom ? 12 : 0),
              ),
            )
          : null,
      child: InkWell(
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(item.icon, color: item.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (highlight) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: item.color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '最紧急',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ReminderBadge(
                color: item.color,
                text: item.timeText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReminderItem {
  _ReminderItem({
    required this.days,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.timeText,
    required this.onTap,
  });

  /// 距离到期 / 复诊日的天数，负数表示已逾期，用于紧急度排序。
  final int days;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String timeText;
  final VoidCallback onTap;
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
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: RecentEventsEmpty(
          onManualRecord: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const EventEditPage()),
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
                      MaterialPageRoute<void>(
                          builder: (_) => const TimelinePage()),
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
