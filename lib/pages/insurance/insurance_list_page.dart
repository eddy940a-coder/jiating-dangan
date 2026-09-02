import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/family_member.dart';
import '../../data/models/insurance.dart';
import '../../providers/insurance_provider.dart';
import '../../providers/member_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/reminder_badge.dart';
import 'insurance_detail_page.dart';
import 'insurance_edit_page.dart';

class InsuranceListPage extends StatefulWidget {
  const InsuranceListPage({super.key, this.memberId});
  final String? memberId;

  @override
  State<InsuranceListPage> createState() => _InsuranceListPageState();
}

class _InsuranceListPageState extends State<InsuranceListPage> {
  int _filter = 0; // 0全部 1有效 2即将到期 3已失效

  @override
  Widget build(BuildContext context) {
    final ins = context.watch<InsuranceProvider>().all;
    final members = context.watch<MemberProvider>().all;

    final filtered = ins.where((i) {
      if (widget.memberId != null && i.memberId != widget.memberId) return false;
      switch (_filter) {
        case 1:
          return i.status == '有效';
        case 2:
          return i.status == '即将到期';
        case 3:
          return i.status == '已失效';
        default:
          return true;
      }
    }).toList();

    final grouped = <String, List<Insurance>>{};
    for (final i in filtered) {
      grouped.putIfAbsent(i.memberId, () => <Insurance>[]).add(i);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.memberId == null
            ? '保险档案'
            : '${_name(members, widget.memberId!)} 的保单'),
      ),
      body: Column(
        children: [
          _FilterRow(
            index: _filter,
            onChange: (i) => setState(() => _filter = i),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const EmptyState(
                    icon: Icons.shield_outlined,
                    message: '暂无保单记录\n点击右下角添加',
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                    children: [
                      for (final entry in grouped.entries)
                        _GroupSection(
                          name: _name(members, entry.key),
                          items: entry.value,
                        ),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => InsuranceEditPage(memberId: widget.memberId),
          ),
        ),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('新增保单', style: TextStyle(color: Colors.white)),
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

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.index, required this.onChange});
  final int index;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) {
    const labels = ['全部', '有效', '即将到期', '已失效'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(labels.length, (i) {
            final selected = i == index;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(labels[i]),
                selected: selected,
                onSelected: (_) => onChange(i),
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.card,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                side: BorderSide(
                    color:
                        selected ? AppColors.primary : AppColors.divider),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _GroupSection extends StatelessWidget {
  const _GroupSection({required this.name, required this.items});
  final String name;
  final List<Insurance> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
          child: Text(
            name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: AppColors.divider),
                _InsuranceTile(item: items[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _InsuranceTile extends StatelessWidget {
  const _InsuranceTile({required this.item});
  final Insurance item;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(item.status);
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => InsuranceDetailPage(insurance: item),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.shield_outlined, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.type,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.company.isEmpty ? "未填公司" : item.company}'
                    '${item.policyNo.isEmpty ? "" : " · ${item.policyNo}"}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TagPill(text: item.status, color: color),
                if (item.expireDate != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '到 ${_ymd(item.expireDate!)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Color _statusColor(String s) {
    switch (s) {
      case '有效':
        return AppColors.success;
      case '即将到期':
        return AppColors.orange;
      case '已失效':
        return AppColors.textHint;
      default:
        return AppColors.primary;
    }
  }
}
