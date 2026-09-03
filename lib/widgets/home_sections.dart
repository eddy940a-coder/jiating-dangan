import 'package:flutter/material.dart';

import '../data/models/family_member.dart';
import '../pages/emergency/emergency_card_page.dart';
import '../pages/insurance/insurance_edit_page.dart';
import '../pages/insurance/insurance_list_page.dart';
import '../pages/medical/medical_edit_page.dart';
import '../pages/medical/medical_list_page.dart';
import '../pages/timeline/event_edit_page.dart';
import '../pages/timeline/timeline_page.dart';
import '../theme/app_colors.dart';
import 'app_avatar.dart';
import 'app_card.dart';

/// 首页 - 家人卡片。
///
/// 设计要点：
/// - 隐藏状态不再用「已隐藏」文字占位（用户看不懂），改为头像角标小问号，
///   点击后解释含义并可一键切换；
/// - 主账号（本人）用星标区分。
class HomeMemberCard extends StatelessWidget {
  const HomeMemberCard({
    super.key,
    required this.member,
    required this.onTap,
    required this.onToggleHidden,
  });

  final FamilyMember member;

  /// 点击卡片本体：进入编辑
  final VoidCallback onTap;

  /// 在弹层里切换显示 / 隐藏，参数为切换后的目标状态
  final ValueChanged<bool> onToggleHidden;

  Future<void> showHint(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '「${member.name}」的档案',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  member.hidden
                      ? '该档案已隐藏。查看 TA 的保单、病历、紧急医疗卡时，需要输入应用密码。'
                      : '该档案当前公开显示，打开 App 即可直接查看。',
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: Icon(
                      member.hidden
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 18,
                    ),
                    label: Text(
                      member.hidden ? '取消隐藏，直接显示' : '设为隐藏，需密码查看',
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      onToggleHidden(!member.hidden);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSelf = member.relation == '本人';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 96,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelf ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AppAvatar(member: member, size: 52),
                if (isSelf)
                  const Positioned(
                    right: -2,
                    bottom: -2,
                    child: _SelfBadge(),
                  ),
                if (member.hidden)
                  Positioned(
                    left: -4,
                    top: -6,
                    child: GestureDetector(
                      onTap: () => showHint(context),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: const Icon(
                          Icons.help_outline,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
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
              member.relation,
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

/// 主账号（本人）的星标徽章
class _SelfBadge extends StatelessWidget {
  const _SelfBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: AppColors.fnEvent,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: const Icon(Icons.star, size: 13, color: Colors.white),
    );
  }
}

/// 家人列表末尾的小加号入口（不再占一整块卡片位置）
class HomeAddMemberChip extends StatelessWidget {
  const HomeAddMemberChip({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withOpacity(0.35)),
              ),
              child: const Icon(Icons.add, color: AppColors.primary, size: 24),
            ),
            const SizedBox(height: 8),
            const Text(
              '添加',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 待办提醒的空状态：说明提醒从哪来，并提供快捷新建入口。
class ReminderEmptySection extends StatelessWidget {
  const ReminderEmptySection({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.notifications_none_outlined,
                  color: AppColors.textHint, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '暂无待办，可以新增复查、体检、保单缴费提醒',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () => showAddReminderSheet(context),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('新建提醒'),
            ),
          ),
        ],
      ),
    );
  }
}

/// 新建提醒入口：提醒都依附在保单 / 病历 / 事件上，
/// 因此这里引导用户去对应的录入页。
Future<void> showAddReminderSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '新建提醒',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.medical_services_outlined,
                  color: AppColors.fnMedical),
              title: const Text('复诊 / 复查提醒'),
              subtitle: const Text('录入就诊记录时设置复诊时间'),
              onTap: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const MedicalEditPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.shield_outlined,
                  color: AppColors.fnInsurance),
              title: const Text('保单缴费 / 续保提醒'),
              subtitle: const Text('录入保单到期日自动生成'),
              onTap: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const InsuranceEditPage()),
                );
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.event_note_outlined, color: AppColors.fnEvent),
              title: const Text('手动记录家庭大事'),
              subtitle: const Text('体检、手术、疫苗等一次性事项'),
              onTap: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const EventEditPage()),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      );
    },
  );
}

/// 首页功能入口。
///
/// 紧急医疗卡是应急场景下的差异化卖点，单独放大置顶；
/// 其余三个弱化，横向三等分，并各自带一句说明降低学习成本。
class FunctionEntries extends StatelessWidget {
  const FunctionEntries({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_Fn>[
      _Fn(
        '保险档案',
        '保单集中管理',
        Icons.shield_outlined,
        AppColors.fnInsurance,
        () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
                builder: (_) => const InsuranceListPage()),
          );
        },
      ),
      _Fn(
        '就医 & 病历',
        '就诊记录与复诊',
        Icons.medical_services_outlined,
        AppColors.fnMedical,
        () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const MedicalListPage()),
          );
        },
      ),
      _Fn(
        '家庭大事件',
        '健康大事时间线',
        Icons.timeline_outlined,
        AppColors.fnEvent,
        () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const TimelinePage()),
          );
        },
      ),
    ];

    return Column(
      children: [
        _EmergencyBanner(),
        const SizedBox(height: 12),
        Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(child: _FnCard(item: items[i])),
            ],
          ],
        ),
      ],
    );
  }
}

/// 紧急医疗卡大卡：第一屏就要看见
class _EmergencyBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
              builder: (_) => const EmergencyCardPage()),
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: [AppColors.red, Color(0xFFDC2626)],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.emergency,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '紧急医疗卡',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      '一键展示血型、过敏史、既往病史，可存相册给医生看',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _Fn {
  _Fn(this.label, this.hint, this.icon, this.color, this.onTap);
  final String label;
  final String hint;
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.hint,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

/// 最近动态空状态
class RecentEventsEmpty extends StatelessWidget {
  const RecentEventsEmpty({super.key, required this.onManualRecord});

  final VoidCallback onManualRecord;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          const Icon(Icons.event_note_outlined,
              color: AppColors.textHint, size: 28),
          const SizedBox(height: 8),
          const Text(
            '暂无家庭事件',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '录入病历、保单将自动生成动态，也可以手动记录家庭健康大事',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onManualRecord,
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('手动记录'),
          ),
        ],
      ),
    );
  }
}
