import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/family_member.dart';
import '../../providers/member_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_card.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../insurance/insurance_list_page.dart';
import '../medical/medical_list_page.dart';
import 'member_edit_page.dart';

class MemberListPage extends StatelessWidget {
  const MemberListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('家庭成员'),
      ),
      body: Consumer<MemberProvider>(
        builder: (context, p, _) {
          if (p.all.isEmpty) {
            return EmptyState(
              icon: Icons.family_restroom_outlined,
              message: '还没有添加家庭成员\n点击右下角按钮添加',
              action: ElevatedButton.icon(
                onPressed: () => _goAdd(context),
                icon: const Icon(Icons.add),
                label: const Text('添加家人'),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            itemCount: p.all.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _MemberCard(member: p.all[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _goAdd(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('添加家人', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _goAdd(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MemberEditPage()),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member});
  final FamilyMember member;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => MemberEditPage(member: member)),
      ),
      child: Row(
        children: [
          AppAvatar(member: member, size: 52),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (member.hidden) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('隐藏',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            )),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  member.relation +
                      (member.birthday == null
                          ? ''
                          : ' · ${member.age}岁'),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (member.bloodType.isNotEmpty ||
                    member.allergy.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (member.bloodType.isNotEmpty) '血型 ${member.bloodType}',
                      if (member.allergy.isNotEmpty) '过敏 ${member.allergy}',
                    ].join(' · '),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz, color: AppColors.textHint),
            onSelected: (v) async {
              if (v == 'edit') {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => MemberEditPage(member: member)));
              } else if (v == 'insurance') {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => InsuranceListPage(memberId: member.id)));
              } else if (v == 'medical') {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => MedicalListPage(memberId: member.id)));
              } else if (v == 'delete') {
                final ok = await ConfirmDialog.show(
                  context,
                  title: '删除成员',
                  message: '将同时删除该成员的所有保单与病历记录，此操作不可恢复，是否继续？',
                  confirmText: '删除',
                  danger: true,
                );
                if (ok && context.mounted) {
                  await context.read<MemberProvider>().delete(member.id);
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('编辑')),
              PopupMenuItem(value: 'insurance', child: Text('查看保单')),
              PopupMenuItem(value: 'medical', child: Text('查看病历')),
              PopupMenuItem(
                  value: 'delete',
                  child: Text('删除',
                      style: TextStyle(color: AppColors.red))),
            ],
          ),
        ],
      ),
    );
  }
}
