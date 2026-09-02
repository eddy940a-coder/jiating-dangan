import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';

import '../../data/models/family_member.dart';
import '../../data/models/insurance.dart';
import '../../providers/insurance_provider.dart';
import '../../providers/member_provider.dart';
import '../../services/attachment_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/date_util.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/hidden_guard.dart';
import 'insurance_edit_page.dart';

class InsuranceDetailPage extends StatefulWidget {
  const InsuranceDetailPage({super.key, required this.insurance});
  final Insurance insurance;

  @override
  State<InsuranceDetailPage> createState() => _InsuranceDetailPageState();
}

class _InsuranceDetailPageState extends State<InsuranceDetailPage> {
  late Insurance _item;

  @override
  void initState() {
    super.initState();
    _item = widget.insurance;
  }

  Future<void> _openAttach(String name) async {
    final path = await AttachmentService.instance.resolve(name);
    if (name.toLowerCase().endsWith('.pdf')) {
      await OpenFilex.open(path);
    } else {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          insetPadding: const EdgeInsets.all(8),
          backgroundColor: Colors.black,
          child: SizedBox(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.8,
            child: InteractiveViewer(
              child: Center(
                child: Image.file(
                  File(path),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Text(
                    '无法打开',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = context.watch<MemberProvider>().all;
    final m = _findMember(members, _item.memberId);
    return Scaffold(
      appBar: AppBar(
        title: const Text('保单详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final res = await Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => InsuranceEditPage(insurance: _item)),
              );
              if (res == true && mounted) {
                final updated =
                    context.read<InsuranceProvider>().byId(_item.id);
                if (updated != null) setState(() => _item = updated);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.red),
            onPressed: () async {
              final ok = await ConfirmDialog.show(
                context,
                title: '删除保单',
                message: '将同时删除该保单关联的家庭事件，已设置的到期提醒也会取消。是否继续？',
                confirmText: '删除',
                danger: true,
              );
              if (ok && context.mounted) {
                await context.read<InsuranceProvider>().delete(_item.id);
                if (mounted) Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: m == null
          ? const Center(child: Text('成员不存在'))
          : HiddenGuard(
              member: m,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
          _Header(item: _item, memberName: m?.name ?? '-'),
          const SizedBox(height: 16),
          _Section(
            title: '基本信息',
            children: [
              _kv('归属成员', m?.name ?? '-'),
              _kv('保险类型', _item.type),
              _kv('保险公司', _item.company),
              _kv('保单号', _item.policyNo),
              _kv('投保人', _item.policyHolder),
              _kv('被保人', _item.insuredPerson),
              _kv('受益人', _item.beneficiary),
            ],
          ),
          const SizedBox(height: 12),
          _Section(
            title: '时间与费用',
            children: [
              _kv('投保日期', DateUtil.ymd(_item.purchaseDate)),
              _kv('生效日期', DateUtil.ymd(_item.effectiveDate)),
              _kv('到期日期', DateUtil.ymd(_item.expireDate)),
              _kv('保费', _item.premium == null
                  ? '-'
                  : '${_item.premium!.toStringAsFixed(2)} 元'),
              _kv('到期提醒', _item.remindEnabled ? '开启' : '关闭'),
              _kv('保单状态', _item.status),
            ],
          ),
          const SizedBox(height: 12),
          if (_item.summary.isNotEmpty)
            _Section(
              title: '保障摘要',
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_item.summary,
                      style: const TextStyle(height: 1.6, fontSize: 15)),
                ),
              ],
            ),
          if (_item.summary.isNotEmpty) const SizedBox(height: 12),
          if (_item.attachments.isNotEmpty) ...[
            _Section(
              title: '附件',
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _item.attachments.map((n) {
                      return GestureDetector(
                        onTap: () => _openAttach(n),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.attach_file,
                                  size: 18, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(n,
                                  style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (_item.remark.isNotEmpty)
            _Section(
              title: '备注',
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_item.remark,
                      style: const TextStyle(height: 1.6, fontSize: 15)),
                ),
              ],
            ),
        ],
      ),
            ),
    );
  }

  FamilyMember? _findMember(List<FamilyMember> ms, String id) {
    for (final m in ms) {
      if (m.id == id) return m;
    }
    return null;
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(k,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 14)),
          ),
          Expanded(
            child: Text(
              v.isEmpty ? '-' : v,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 15, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.item, required this.memberName});
  final Insurance item;
  final String memberName;

  @override
  Widget build(BuildContext context) {
    final color = switch (item.status) {
      '有效' => AppColors.success,
      '即将到期' => AppColors.orange,
      '已失效' => AppColors.textHint,
      _ => AppColors.primary,
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.shield,
                    color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.type,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        )),
                    const SizedBox(height: 4),
                    Text(
                      '$memberName · ${item.company.isEmpty ? "未填公司" : item.company}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.status,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
