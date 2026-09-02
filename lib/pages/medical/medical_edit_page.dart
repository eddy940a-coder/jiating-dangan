import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/medical_record.dart';
import '../../providers/medical_provider.dart';
import '../../providers/member_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/id_util.dart';
import '../../widgets/attachment_field.dart';
import '../../widgets/form_widgets.dart';

class MedicalEditPage extends StatefulWidget {
  const MedicalEditPage({super.key, this.record, this.memberId});
  final MedicalRecord? record;
  final String? memberId;

  @override
  State<MedicalEditPage> createState() => _MedicalEditPageState();
}

class _MedicalEditPageState extends State<MedicalEditPage> {
  late TextEditingController _hospital;
  late TextEditingController _department;
  late TextEditingController _doctor;
  late TextEditingController _complaint;
  late TextEditingController _diagnosis;
  late TextEditingController _medication;
  late TextEditingController _remark;
  String? _memberId;
  String _visitType = medicalVisitTypes.first;
  DateTime _visitTime = DateTime.now();
  DateTime? _revisitTime;
  bool _revisitRemind = false;
  List<String> _attachments = <String>[];

  @override
  void initState() {
    super.initState();
    final r = widget.record;
    _hospital = TextEditingController(text: r?.hospital ?? '');
    _department = TextEditingController(text: r?.department ?? '');
    _doctor = TextEditingController(text: r?.doctor ?? '');
    _complaint = TextEditingController(text: r?.chiefComplaint ?? '');
    _diagnosis = TextEditingController(text: r?.diagnosis ?? '');
    _medication = TextEditingController(text: r?.medication ?? '');
    _remark = TextEditingController(text: r?.remark ?? '');
    _memberId = r?.memberId ?? widget.memberId;
    _visitType = r?.visitType ?? medicalVisitTypes.first;
    _visitTime = r?.visitTime ?? DateTime.now();
    _revisitTime = r?.revisitTime;
    _revisitRemind = r?.revisitRemind ?? false;
    _attachments = List<String>.from(r?.attachments ?? const <String>[]);
  }

  @override
  void dispose() {
    for (final c in [
      _hospital,
      _department,
      _doctor,
      _complaint,
      _diagnosis,
      _medication,
      _remark,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_memberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择归属成员')),
      );
      return;
    }
    final p = context.read<MedicalProvider>();
    final now = DateTime.now();
    if (widget.record == null) {
      final r = MedicalRecord(
        id: IdUtil.newId(),
        memberId: _memberId!,
        visitTime: _visitTime,
        hospital: _hospital.text.trim(),
        department: _department.text.trim(),
        doctor: _doctor.text.trim(),
        visitType: _visitType,
        chiefComplaint: _complaint.text.trim(),
        diagnosis: _diagnosis.text.trim(),
        medication: _medication.text.trim(),
        revisitTime: _revisitTime,
        revisitRemind: _revisitRemind,
        attachments: _attachments,
        remark: _remark.text.trim(),
        createdAt: now,
        updatedAt: now,
      );
      await p.upsert(r);
    } else {
      final updated = widget.record!.copyWith(
        memberId: _memberId!,
        visitTime: _visitTime,
        hospital: _hospital.text.trim(),
        department: _department.text.trim(),
        doctor: _doctor.text.trim(),
        visitType: _visitType,
        chiefComplaint: _complaint.text.trim(),
        diagnosis: _diagnosis.text.trim(),
        medication: _medication.text.trim(),
        revisitTime: _revisitTime,
        clearRevisitTime: _revisitTime == null,
        revisitRemind: _revisitRemind,
        attachments: _attachments,
        remark: _remark.text.trim(),
        updatedAt: now,
      );
      await p.upsert(updated);
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _pickVisitTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _visitTime,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_visitTime),
    );
    if (time == null) {
      setState(() => _visitTime = date);
    } else {
      setState(() => _visitTime =
          DateTime(date.year, date.month, date.day, time.hour, time.minute));
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = context.watch<MemberProvider>().all;
    final isEdit = widget.record != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? '编辑病历' : '新增病历'),
        actions: [TextButton(onPressed: _save, child: const Text('保存'))],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          FormDropdown<String>(
            label: '归属成员',
            required: true,
            value: _memberId,
            items: members
                .map((m) => DropdownMenuItem(
                      value: m.id,
                      child: Text(
                        m.hidden ? '${m.name} (已隐藏)' : m.name,
                      ),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _memberId = v),
          ),
          LabeledField(
            label: '就诊时间',
            required: true,
            child: InkWell(
              onTap: _pickVisitTime,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.divider),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_visitTime.year}-${_visitTime.month.toString().padLeft(2, '0')}-${_visitTime.day.toString().padLeft(2, '0')} '
                        '${_visitTime.hour.toString().padLeft(2, '0')}:${_visitTime.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const Icon(Icons.access_time,
                        size: 18, color: AppColors.textHint),
                  ],
                ),
              ),
            ),
          ),
          FormDropdown<String>(
            label: '就诊类型',
            required: true,
            value: _visitType,
            items: medicalVisitTypes
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) => setState(() => _visitType = v ?? _visitType),
          ),
          LabeledField(
            label: '医院',
            child: TextField(
              controller: _hospital,
              decoration: const InputDecoration(hintText: '如：北京协和医院'),
            ),
          ),
          LabeledField(
            label: '科室',
            child: TextField(
              controller: _department,
              decoration: const InputDecoration(hintText: '如：心内科'),
            ),
          ),
          LabeledField(
            label: '医生',
            child: TextField(
              controller: _doctor,
              decoration: const InputDecoration(hintText: '选填'),
            ),
          ),
          LabeledField(
            label: '主诉',
            child: TextField(
              controller: _complaint,
              maxLines: 3,
              decoration: const InputDecoration(hintText: '患者主诉 / 症状'),
            ),
          ),
          LabeledField(
            label: '诊断结果',
            child: TextField(
              controller: _diagnosis,
              maxLines: 3,
              decoration: const InputDecoration(hintText: '医生诊断'),
            ),
          ),
          LabeledField(
            label: '用药记录',
            child: TextField(
              controller: _medication,
              maxLines: 3,
              decoration: const InputDecoration(hintText: '药品名 / 用法用量'),
            ),
          ),
          FormDateField(
            label: '复诊时间',
            value: _revisitTime,
            onChanged: (d) => setState(() => _revisitTime = d),
            clearable: true,
            lastDate: DateTime(DateTime.now().year + 10),
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SwitchListTile(
              value: _revisitRemind,
              onChanged: (v) => setState(() => _revisitRemind = v),
              title: const Text('复诊提醒'),
              subtitle: const Text(
                '开启后将通过本地通知在复诊前一天与当天提醒',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              activeColor: AppColors.primary,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: AttachmentField(
              value: _attachments,
              onChanged: (v) => setState(() => _attachments = v),
            ),
          ),
          LabeledField(
            label: '备注',
            child: TextField(
              controller: _remark,
              maxLines: 3,
              decoration: const InputDecoration(hintText: '其他需要记录的信息'),
            ),
          ),
        ],
      ),
    );
  }
}
