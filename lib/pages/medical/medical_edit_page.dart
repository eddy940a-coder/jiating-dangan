import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/medical_record.dart';
import '../../pages/ocr/ocr_review_page.dart';
import '../../providers/medical_provider.dart';
import '../../providers/member_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/id_util.dart';
import '../../widgets/attachment_field.dart';
import '../../widgets/form_widgets.dart';
import '../../widgets/scan_banner.dart';

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
  DateTime? _nextCheckupDate;
  bool _checkupRemind = false;
  List<String> _attachments = <String>[];

  /// 新建后保存下来的记录，供「设置复查提醒」二次保存时复用
  MedicalRecord? _saved;

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
    _nextCheckupDate = r?.nextCheckupDate;
    _checkupRemind = r?.checkupRemind ?? false;
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

  /// 保存，并在没有复诊时间时引导用户顺手设置复查提醒。
  ///
  /// 用户最常忘的就是「医生让一个月后复查」，与其让他自己想到去新建提醒，
  /// 不如在保存病历的当下问一句。
  Future<void> _save() async {
    final ok = await _persist();
    if (!ok || !mounted) return;

    if (_visitType == '体检') {
      // 体检：默认建议一年后，帮用户把「明年还要体检」这件事记住
      if (_nextCheckupDate == null) {
        final want = await _askCheckupReminder();
        if (want && mounted) {
          final suggested =
              DateTime(_visitTime.year + 1, _visitTime.month, _visitTime.day);
          final picked = await showDatePicker(
            context: context,
            initialDate: suggested,
            firstDate: _visitTime,
            lastDate: DateTime(_visitTime.year + 5, 12, 31),
          );
          if (picked != null) {
            if (!mounted) return;
            setState(() {
              _nextCheckupDate = picked;
              _checkupRemind = true;
            });
            await _persist();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('已设置下次体检提醒')),
            );
          }
        }
      }
    } else if (_revisitTime == null) {
      final want = await _askRevisitReminder();
      if (want && mounted) {
        final picked = await showDatePicker(
          context: context,
          initialDate: _visitTime.add(const Duration(days: 30)),
          firstDate: _visitTime,
          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
        );
        if (picked != null) {
          if (!mounted) return;
          setState(() {
            _revisitTime = picked;
            _revisitRemind = true;
          });
          await _persist();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已设置复查提醒，会提前通知你')),
          );
        }
      }
    }

    if (mounted) Navigator.of(context).pop(true);
  }

  Future<bool> _askCheckupReminder() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('设置下次体检提醒？'),
          content: const Text(
            '体检一般一年一次。设置后，App 会在到期前提醒你，'
            '默认按本次日期推后一年，也可以自行调整。',
            style: TextStyle(height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('暂不'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('去设置'),
            ),
          ],
        );
      },
    );
    return res ?? false;
  }

  Future<bool> _askRevisitReminder() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('设置复查提醒？'),
          content: const Text(
            '医生经常会交代复诊时间。设置后，App 会在复诊前一天和当天提醒你。',
            style: TextStyle(height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('暂不'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('去设置'),
            ),
          ],
        );
      },
    );
    return res ?? false;
  }

  /// 写入数据库。新建后记住记录，避免二次保存时重复插入。
  Future<bool> _persist() async {
    if (_memberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择归属成员')),
      );
      return false;
    }
    final p = context.read<MedicalProvider>();
    final now = DateTime.now();
    if (_saved == null && widget.record == null) {
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
        nextCheckupDate: _nextCheckupDate,
        checkupRemind: _checkupRemind,
        attachments: _attachments,
        remark: _remark.text.trim(),
        createdAt: now,
        updatedAt: now,
      );
      await p.upsert(r);
      _saved = r;
    } else {
      final updated = (widget.record ?? _saved!).copyWith(
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
        nextCheckupDate: _nextCheckupDate,
        clearNextCheckupDate: _nextCheckupDate == null,
        checkupRemind: _checkupRemind,
        attachments: _attachments,
        remark: _remark.text.trim(),
        updatedAt: now,
      );
      await p.upsert(updated);
      _saved = updated;
    }
    return true;
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

  /// 拍照 / 选图识别单据，核对后填入表单（不直接落库）
  Future<void> _scanRecord() async {
    final fields = await OcrScan.run(context, OcrTarget.medical);
    if (fields == null || !mounted) return;
    setState(() {
      _hospital.text = fields['hospital'] ?? _hospital.text;
      _department.text = fields['department'] ?? _department.text;
      _doctor.text = fields['doctor'] ?? _doctor.text;
      _diagnosis.text = fields['diagnosis'] ?? _diagnosis.text;
      _complaint.text = fields['complaint'] ?? _complaint.text;
      _medication.text = fields['medication'] ?? _medication.text;
      final d = _parseDate(fields['visitTime']);
      if (d != null) {
        _visitTime = DateTime(d.year, d.month, d.day, _visitTime.hour,
            _visitTime.minute);
      }
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已填入识别结果，请核对后再保存')),
    );
  }

  /// 解析 `yyyy-MM-dd`
  static DateTime? _parseDate(String? s) {
    if (s == null) return null;
    final m = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})').firstMatch(s.trim());
    if (m == null) return null;
    final y = int.tryParse(m.group(1)!);
    final mo = int.tryParse(m.group(2)!);
    final d = int.tryParse(m.group(3)!);
    if (y == null || mo == null || d == null) return null;
    try {
      return DateTime(y, mo, d);
    } catch (_) {
      return null;
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
          ScanBanner(
            text: '拍照 / 选图识别病历、诊断证明，自动填入下方字段',
            onTap: _scanRecord,
          ),
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
          if (members.isEmpty) const NoMemberHint(),
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
          if (_visitType == '体检') ...[
            FormDateField(
              label: '下次体检日期',
              value: _nextCheckupDate,
              onChanged: (d) => setState(() {
                _nextCheckupDate = d;
                if (d != null) _checkupRemind = true;
              }),
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
                value: _checkupRemind,
                onChanged: (v) => setState(() => _checkupRemind = v),
                title: const Text('下次体检提醒'),
                subtitle: const Text(
                  '开启后将在体检日期前一天与当天提醒',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                activeColor: AppColors.primary,
              ),
            ),
          ],
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
