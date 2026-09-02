import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/family_member.dart';
import '../../data/models/medical_record.dart';
import '../../providers/medical_provider.dart';
import '../../providers/member_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/date_util.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/reminder_badge.dart';
import 'medical_detail_page.dart';
import 'medical_edit_page.dart';

class MedicalListPage extends StatefulWidget {
  const MedicalListPage({super.key, this.memberId});
  final String? memberId;

  @override
  State<MedicalListPage> createState() => _MedicalListPageState();
}

class _MedicalListPageState extends State<MedicalListPage> {
  String? _filterMember;

  @override
  Widget build(BuildContext context) {
    final all = context.watch<MedicalProvider>().all;
    final members = context.watch<MemberProvider>().all;

    final filtered = all.where((r) {
      if (_filterMember != null && r.memberId != _filterMember) return false;
      if (widget.memberId != null && r.memberId != widget.memberId) return false;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.memberId == null
            ? '就医病历'
            : '${_name(members, widget.memberId!)} 的病历'),
      ),
      body: Column(
        children: [
          _MemberFilter(
            members: members,
            value: _filterMember,
            onChanged: (v) => setState(() => _filterMember = v),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const EmptyState(
                    icon: Icons.medical_services_outlined,
                    message: '暂无病历记录\n点击右下角添加',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final r = filtered[i];
                      return _RecordCard(
                        record: r,
                        memberName: _name(members, r.memberId),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MedicalEditPage(memberId: widget.memberId),
          ),
        ),
        backgroundColor: AppColors.red,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('新增病历', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  String _name(List<FamilyMember> ms, String id) {
    for (final m in ms) {
      if (m.id == id) return m.name;
    }
    return '未知';
  }
}

class _MemberFilter extends StatelessWidget {
  const _MemberFilter({
    required this.members,
    required this.value,
    required this.onChanged,
  });
  final List<FamilyMember> members;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.filter_alt_outlined,
              size: 18, color: AppColors.textHint),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                isExpanded: true,
                value: value,
                hint: const Text('全部成员'),
                items: <DropdownMenuItem<String?>>[
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('全部成员'),
                  ),
                  for (final m in members)
                    DropdownMenuItem<String?>(
                      value: m.id,
                      child: Text(m.name),
                    ),
                ],
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.record, required this.memberName});
  final MedicalRecord record;
  final String memberName;

  Color get _typeColor {
    switch (record.visitType) {
      case '手术':
        return AppColors.red;
      case '住院':
        return AppColors.orange;
      case '体检':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MedicalDetailPage(record: record),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TagPill(text: record.visitType, color: _typeColor),
              const SizedBox(width: 8),
              Text(
                DateUtil.ymd(record.visitTime),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textHint,
                ),
              ),
              const Spacer(),
              if (record.revisitTime != null && record.revisitRemind)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '复诊提醒',
                    style: TextStyle(
                      color: AppColors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${record.hospital.isEmpty ? "未填医院" : record.hospital}'
            '${record.department.isEmpty ? "" : " · ${record.department}"}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$memberName · ${record.doctor.isEmpty ? "未填医生" : record.doctor}',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          if (record.diagnosis.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '诊断：${record.diagnosis}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
