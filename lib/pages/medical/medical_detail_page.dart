import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';

import '../../data/models/family_member.dart';
import '../../data/models/medical_record.dart';
import '../../providers/medical_provider.dart';
import '../../providers/member_provider.dart';
import '../../services/attachment_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/date_util.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/hidden_guard.dart';
import 'medical_edit_page.dart';

class MedicalDetailPage extends StatefulWidget {
  const MedicalDetailPage({super.key, required this.record});
  final MedicalRecord record;

  @override
  State<MedicalDetailPage> createState() => _MedicalDetailPageState();
}

class _MedicalDetailPageState extends State<MedicalDetailPage> {
  late MedicalRecord _item;

  @override
  void initState() {
    super.initState();
    _item = widget.record;
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
        title: const Text('病历详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final res = await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => MedicalEditPage(record: _item)));
              if (res == true && mounted) {
                final updated = context.read<MedicalProvider>().byId(_item.id);
                if (updated != null) setState(() => _item = updated);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.red),
            onPressed: () async {
              final ok = await ConfirmDialog.show(
                context,
                title: '删除病历',
                message: '将同时删除该病历关联的家庭事件，已设置的复诊提醒也会取消。是否继续？',
                confirmText: '删除',
                danger: true,
              );
              if (ok && context.mounted) {
                await context.read<MedicalProvider>().delete(_item.id);
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
              _kv('就诊时间', DateUtil.ymdHm(_item.visitTime)),
              _kv('就诊类型', _item.visitType),
              _kv('医院', _item.hospital),
              _kv('科室', _item.department),
              _kv('医生', _item.doctor),
            ],
          ),
          if (_item.chiefComplaint.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Section(
              title: '主诉',
              children: [_textBlock(_item.chiefComplaint)],
            ),
          ],
          if (_item.diagnosis.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Section(
              title: '诊断结果',
              children: [_textBlock(_item.diagnosis)],
            ),
          ],
          if (_item.medication.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Section(
              title: '用药记录',
              children: [_textBlock(_item.medication)],
            ),
          ],
          if (_item.revisitTime != null) ...[
            const SizedBox(height: 12),
            _Section(
              title: '复诊',
              children: [
                _kv('复诊时间', DateUtil.ymd(_item.revisitTime)),
                _kv('复诊提醒', _item.revisitRemind ? '开启' : '关闭'),
              ],
            ),
          ],
          if (_item.attachments.isNotEmpty) ...[
            const SizedBox(height: 12),
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
                              Text(n, style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
          if (_item.remark.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Section(
              title: '备注',
              children: [_textBlock(_item.remark)],
            ),
          ],
        ],
      ),
            ),
    );
  }

  Widget _textBlock(String t) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(t, style: const TextStyle(height: 1.6, fontSize: 15)),
    );
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

  FamilyMember? _findMember(List<FamilyMember> ms, String id) {
    for (final m in ms) {
      if (m.id == id) return m;
    }
    return null;
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.item, required this.memberName});
  final MedicalRecord item;
  final String memberName;

  @override
  Widget build(BuildContext context) {
    final color = switch (item.visitType) {
      '手术' => AppColors.red,
      '住院' => AppColors.orange,
      '体检' => AppColors.success,
      _ => AppColors.primary,
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.medical_services, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.hospital.isEmpty ? '就医记录' : item.hospital,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$memberName · ${item.department.isEmpty ? "未填科室" : item.department}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              item.visitType,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
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
