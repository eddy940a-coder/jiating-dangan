import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/family_member.dart';
import '../../providers/member_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/id_util.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/form_widgets.dart';

class MemberEditPage extends StatefulWidget {
  const MemberEditPage({super.key, this.member});
  final FamilyMember? member;

  @override
  State<MemberEditPage> createState() => _MemberEditPageState();
}

class _MemberEditPageState extends State<MemberEditPage> {
  late TextEditingController _name;
  late TextEditingController _blood;
  late TextEditingController _idCard;
  late TextEditingController _allergy;
  late TextEditingController _chronic;
  String _relation = '本人';
  DateTime? _birthday;
  bool _hidden = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final m = widget.member;
    _name = TextEditingController(text: m?.name ?? '');
    _blood = TextEditingController(text: m?.bloodType ?? '');
    _idCard = TextEditingController(text: m?.idCard ?? '');
    _allergy = TextEditingController(text: m?.allergy ?? '');
    _chronic = TextEditingController(text: m?.chronicDisease ?? '');
    _relation = m?.relation ?? '本人';
    _birthday = m?.birthday;
    _hidden = m?.hidden ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _blood.dispose();
    _idCard.dispose();
    _allergy.dispose();
    _chronic.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写姓名')),
      );
      return;
    }
    setState(() => _saving = true);
    final now = DateTime.now();
    final p = context.read<MemberProvider>();
    if (widget.member == null) {
      final m = FamilyMember(
        id: IdUtil.newId(),
        name: _name.text.trim(),
        relation: _relation,
        birthday: _birthday,
        bloodType: _blood.text.trim(),
        idCard: _idCard.text.trim(),
        allergy: _allergy.text.trim(),
        chronicDisease: _chronic.text.trim(),
        hidden: _hidden,
        createdAt: now,
        updatedAt: now,
      );
      await p.upsert(m);
    } else {
      final updated = widget.member!.copyWith(
        name: _name.text.trim(),
        relation: _relation,
        birthday: _birthday,
        bloodType: _blood.text.trim(),
        idCard: _idCard.text.trim(),
        allergy: _allergy.text.trim(),
        chronicDisease: _chronic.text.trim(),
        hidden: _hidden,
        updatedAt: now,
      );
      await p.upsert(updated);
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.member != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? '编辑成员' : '添加家人'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('保存'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          LabeledField(
            label: '姓名',
            required: true,
            child: TextField(
              controller: _name,
              maxLength: 20,
              decoration: const InputDecoration(counterText: '', hintText: '请输入姓名'),
            ),
          ),
          FormDropdown<String>(
            label: '关系',
            required: true,
            value: _relation,
            items: memberRelations
                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                .toList(),
            onChanged: (v) => setState(() => _relation = v ?? '本人'),
          ),
          FormDateField(
            label: '生日',
            value: _birthday,
            onChanged: (d) => setState(() => _birthday = d),
            hint: '点击选择生日',
            clearable: true,
          ),
          FormDropdown<String>(
            label: '血型',
            value: _blood.text.isEmpty ? null : _blood.text,
            items: bloodTypes
                .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                .toList(),
            onChanged: (v) => setState(() => _blood.text = v ?? ''),
          ),
          LabeledField(
            label: '身份证号',
            hint: '选填',
            child: TextField(
              controller: _idCard,
              decoration: const InputDecoration(hintText: '选填'),
            ),
          ),
          LabeledField(
            label: '药物过敏史',
            child: TextField(
              controller: _allergy,
              maxLines: 2,
              decoration: const InputDecoration(hintText: '如：青霉素、磺胺类'),
            ),
          ),
          LabeledField(
            label: '既往基础疾病',
            child: TextField(
              controller: _chronic,
              maxLines: 2,
              decoration: const InputDecoration(hintText: '如：高血压、糖尿病'),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SwitchListTile(
              value: _hidden,
              onChanged: (v) => setState(() => _hidden = v),
              title: const Text('档案隐藏'),
              subtitle: const Text(
                '开启后，查看该成员的保单/病历等需输入应用密码',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              activeColor: AppColors.primary,
            ),
          ),
          if (isEdit) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                final ok = await ConfirmDialog.show(
                  context,
                  title: '删除成员',
                  message:
                      '将同时删除该成员的所有保单与病历记录，此操作不可恢复。',
                  confirmText: '删除',
                  danger: true,
                );
                if (ok && context.mounted) {
                  await context.read<MemberProvider>().delete(widget.member!.id);
                  if (mounted) Navigator.of(context).pop();
                }
              },
              icon: const Icon(Icons.delete_outline, color: AppColors.red),
              label: const Text('删除此成员',
                  style: TextStyle(color: AppColors.red)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.red,
                side: const BorderSide(color: AppColors.red),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
