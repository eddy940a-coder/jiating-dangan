import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/family_member.dart';
import '../../data/models/insurance.dart';
import '../../pages/ocr/ocr_review_page.dart';
import '../../providers/insurance_provider.dart';
import '../../providers/member_provider.dart';
import '../../services/ocr_parser.dart';
import '../../theme/app_colors.dart';
import '../../utils/date_util.dart';
import '../../utils/id_util.dart';
import '../../widgets/attachment_field.dart';
import '../../widgets/form_widgets.dart';
import '../../widgets/scan_banner.dart';

class InsuranceEditPage extends StatefulWidget {
  const InsuranceEditPage({super.key, this.insurance, this.memberId});
  final Insurance? insurance;
  final String? memberId;

  @override
  State<InsuranceEditPage> createState() => _InsuranceEditPageState();
}

class _InsuranceEditPageState extends State<InsuranceEditPage> {
  late TextEditingController _company;
  late TextEditingController _policyNo;
  late TextEditingController _holder;
  late TextEditingController _insured;
  late TextEditingController _beneficiary;
  late TextEditingController _premium;
  late TextEditingController _summary;
  late TextEditingController _remark;
  String? _memberId;
  String _type = insuranceTypes.first;
  DateTime? _purchaseDate;
  DateTime? _effectiveDate;
  DateTime? _expireDate;
  bool _remind = false;
  String _status = insuranceStatuses.first;
  List<String> _attachments = <String>[];

  @override
  void initState() {
    super.initState();
    final i = widget.insurance;
    _company = TextEditingController(text: i?.company ?? '');
    _policyNo = TextEditingController(text: i?.policyNo ?? '');
    _holder = TextEditingController(text: i?.policyHolder ?? '');
    _insured = TextEditingController(text: i?.insuredPerson ?? '');
    _beneficiary = TextEditingController(text: i?.beneficiary ?? '');
    _premium = TextEditingController(
      text: i?.premium == null ? '' : i!.premium!.toString(),
    );
    _summary = TextEditingController(text: i?.summary ?? '');
    _remark = TextEditingController(text: i?.remark ?? '');
    _memberId = i?.memberId ?? widget.memberId;
    _type = i?.type ?? insuranceTypes.first;
    _purchaseDate = i?.purchaseDate;
    _effectiveDate = i?.effectiveDate;
    _expireDate = i?.expireDate;
    _remind = i?.remindEnabled ?? false;
    _status = i?.status ?? insuranceStatuses.first;
    _attachments = List<String>.from(i?.attachments ?? const <String>[]);
  }

  @override
  void dispose() {
    for (final c in [
      _company,
      _policyNo,
      _holder,
      _insured,
      _beneficiary,
      _premium,
      _summary,
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
    final p = context.read<InsuranceProvider>();
    final premium = double.tryParse(_premium.text.trim());
    final now = DateTime.now();
    if (widget.insurance == null) {
      final item = Insurance(
        id: IdUtil.newId(),
        memberId: _memberId!,
        type: _type,
        company: _company.text.trim(),
        policyNo: _policyNo.text.trim(),
        policyHolder: _holder.text.trim(),
        insuredPerson: _insured.text.trim(),
        beneficiary: _beneficiary.text.trim(),
        purchaseDate: _purchaseDate,
        effectiveDate: _effectiveDate,
        expireDate: _expireDate,
        premium: premium,
        remindEnabled: _remind,
        summary: _summary.text.trim(),
        attachments: _attachments,
        remark: _remark.text.trim(),
        status: _status,
        createdAt: now,
        updatedAt: now,
      );
      await p.upsert(item);
    } else {
      final updated = widget.insurance!.copyWith(
        memberId: _memberId!,
        type: _type,
        company: _company.text.trim(),
        policyNo: _policyNo.text.trim(),
        policyHolder: _holder.text.trim(),
        insuredPerson: _insured.text.trim(),
        beneficiary: _beneficiary.text.trim(),
        purchaseDate: _purchaseDate,
        clearPurchaseDate: _purchaseDate == null,
        effectiveDate: _effectiveDate,
        clearEffectiveDate: _effectiveDate == null,
        expireDate: _expireDate,
        clearExpireDate: _expireDate == null,
        premium: premium,
        clearPremium: premium == null,
        remindEnabled: _remind,
        summary: _summary.text.trim(),
        attachments: _attachments,
        remark: _remark.text.trim(),
        status: _status,
        updatedAt: now,
      );
      await p.upsert(updated);
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  /// 拍照 / 选图识别保单，核对后填入表单（不直接落库）
  Future<void> _scanPolicy() async {
    final fields = await OcrScan.run(context, OcrTarget.insurance);
    if (fields == null || !mounted) return;
    setState(() {
      _company.text = fields['company'] ?? _company.text;
      _policyNo.text = fields['policyNo'] ?? _policyNo.text;
      _holder.text = fields['holder'] ?? _holder.text;
      _insured.text = fields['insured'] ?? _insured.text;
      _beneficiary.text = fields['beneficiary'] ?? _beneficiary.text;
      _premium.text = fields['premium'] ?? _premium.text;

      final matchedType = OcrParser.matchInsuranceType(fields['type']);
      if (matchedType != null) _type = matchedType;

      final eff = _parseDate(fields['effectiveDate']);
      if (eff != null) _effectiveDate = eff;
      final exp = _parseDate(fields['expireDate']);
      if (exp != null) {
        _expireDate = exp;
        // 识别到到期日就顺手打开续保提醒
        _remind = true;
      }
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已填入识别结果，请核对后再保存')),
    );
  }

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
    final isEdit = widget.insurance != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? '编辑保单' : '新增保单'),
        actions: [
          TextButton(onPressed: _save, child: const Text('保存')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          ScanBanner(
            text: '拍照 / 选图识别保单，自动填入公司、保单号与到期日',
            onTap: _scanPolicy,
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
          FormDropdown<String>(
            label: '保险类型',
            required: true,
            value: _type,
            items: insuranceTypes
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) => setState(() => _type = v ?? _type),
          ),
          LabeledField(
            label: '保险公司',
            child: TextField(
                controller: _company,
                decoration: const InputDecoration(hintText: '如：中国人寿')),
          ),
          LabeledField(
            label: '保单号',
            child: TextField(
              controller: _policyNo,
              decoration: const InputDecoration(hintText: '选填'),
            ),
          ),
          LabeledField(
            label: '投保人',
            child: TextField(
              controller: _holder,
              decoration: const InputDecoration(hintText: '选填'),
            ),
          ),
          LabeledField(
            label: '被保人',
            child: TextField(
              controller: _insured,
              decoration: const InputDecoration(hintText: '选填'),
            ),
          ),
          LabeledField(
            label: '受益人',
            child: TextField(
              controller: _beneficiary,
              decoration: const InputDecoration(hintText: '选填'),
            ),
          ),
          FormDateField(
            label: '投保日期',
            value: _purchaseDate,
            onChanged: (d) => setState(() => _purchaseDate = d),
            clearable: true,
          ),
          FormDateField(
            label: '生效日期',
            value: _effectiveDate,
            onChanged: (d) => setState(() => _effectiveDate = d),
            clearable: true,
          ),
          FormDateField(
            label: '到期日期',
            value: _expireDate,
            onChanged: (d) => setState(() {
              _expireDate = d;
              _autoStatus();
            }),
            clearable: true,
          ),
          LabeledField(
            label: '保费（元）',
            child: TextField(
              controller: _premium,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(hintText: '选填'),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SwitchListTile(
              value: _remind,
              onChanged: (v) => setState(() => _remind = v),
              title: const Text('到期提醒'),
              subtitle: const Text(
                '开启后将通过本地通知在到期前 30 天与当天提醒',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              activeColor: AppColors.primary,
            ),
          ),
          FormDropdown<String>(
            label: '保单状态',
            required: true,
            value: _status,
            items: insuranceStatuses
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => _status = v ?? _status),
          ),
          LabeledField(
            label: '保障摘要',
            child: TextField(
              controller: _summary,
              maxLines: 4,
              decoration: const InputDecoration(
                  hintText: '例如：住院 200 万、意外 50 万'),
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
              decoration:
                  const InputDecoration(hintText: '其他需要记录的信息'),
            ),
          ),
        ],
      ),
    );
  }

  void _autoStatus() {
    if (_expireDate == null) return;
    final d = DateUtil.daysUntil(_expireDate!);
    if (d < 0) {
      _status = '已失效';
    } else if (d <= 30) {
      _status = '即将到期';
    } else {
      _status = '有效';
    }
  }
}
