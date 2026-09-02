import 'dart:convert';

import '../../utils/date_util.dart';

const List<String> insuranceTypes = <String>[
  '医疗险',
  '重疾险',
  '寿险',
  '意外险',
  '养老险',
  '年金险',
  '车险',
  '财产险',
  '其他',
];

/// 状态：用户手动选择，最终一致性以前端为准。
const List<String> insuranceStatuses = <String>['有效', '即将到期', '已失效'];

class Insurance {
  Insurance({
    required this.id,
    required this.memberId,
    required this.type,
    this.company = '',
    this.policyNo = '',
    this.policyHolder = '',
    this.insuredPerson = '',
    this.beneficiary = '',
    this.purchaseDate,
    this.effectiveDate,
    this.expireDate,
    this.premium,
    this.remindEnabled = false,
    this.summary = '',
    this.attachments = const <String>[],
    this.remark = '',
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  String memberId;
  String type;
  String company;
  String policyNo;
  String policyHolder;
  String insuredPerson;
  String beneficiary;
  DateTime? purchaseDate;
  DateTime? effectiveDate;
  DateTime? expireDate;
  double? premium;
  bool remindEnabled;
  String summary;
  List<String> attachments;
  String remark;
  String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isExpiringSoon {
    if (expireDate == null) return false;
    final d = DateUtil.daysUntil(expireDate!);
    return d >= 0 && d <= 30;
  }

  bool get isExpired =>
      expireDate != null && DateUtil.daysUntil(expireDate!) < 0;

  Insurance copyWith({
    String? memberId,
    String? type,
    String? company,
    String? policyNo,
    String? policyHolder,
    String? insuredPerson,
    String? beneficiary,
    DateTime? purchaseDate,
    bool clearPurchaseDate = false,
    DateTime? effectiveDate,
    bool clearEffectiveDate = false,
    DateTime? expireDate,
    bool clearExpireDate = false,
    double? premium,
    bool clearPremium = false,
    bool? remindEnabled,
    String? summary,
    String? remark,
    List<String>? attachments,
    String? status,
    DateTime? updatedAt,
  }) {
    return Insurance(
      id: id,
      memberId: memberId ?? this.memberId,
      type: type ?? this.type,
      company: company ?? this.company,
      policyNo: policyNo ?? this.policyNo,
      policyHolder: policyHolder ?? this.policyHolder,
      insuredPerson: insuredPerson ?? this.insuredPerson,
      beneficiary: beneficiary ?? this.beneficiary,
      purchaseDate: clearPurchaseDate ? null : (purchaseDate ?? this.purchaseDate),
      effectiveDate:
          clearEffectiveDate ? null : (effectiveDate ?? this.effectiveDate),
      expireDate: clearExpireDate ? null : (expireDate ?? this.expireDate),
      premium: clearPremium ? null : (premium ?? this.premium),
      remindEnabled: remindEnabled ?? this.remindEnabled,
      summary: summary ?? this.summary,
      attachments: attachments ?? this.attachments,
      remark: remark ?? this.remark,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'member_id': memberId,
        'type': type,
        'company': company,
        'policy_no': policyNo,
        'policy_holder': policyHolder,
        'insured_person': insuredPerson,
        'beneficiary': beneficiary,
        'purchase_date': DateUtil.toTs(purchaseDate),
        'effective_date': DateUtil.toTs(effectiveDate),
        'expire_date': DateUtil.toTs(expireDate),
        'premium': premium,
        'remind_enabled': remindEnabled ? 1 : 0,
        'summary': summary,
        'attachments': jsonEncode(attachments),
        'remark': remark,
        'status': status,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory Insurance.fromMap(Map<String, Object?> m) {
    final attRaw = m['attachments'] as String?;
    final atts = <String>[];
    if (attRaw != null && attRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(attRaw);
        if (decoded is List) {
          atts.addAll(decoded.map((e) => e.toString()));
        }
      } catch (_) {}
    }
    return Insurance(
      id: m['id'] as String,
      memberId: m['member_id'] as String,
      type: m['type'] as String,
      company: (m['company'] as String?) ?? '',
      policyNo: (m['policy_no'] as String?) ?? '',
      policyHolder: (m['policy_holder'] as String?) ?? '',
      insuredPerson: (m['insured_person'] as String?) ?? '',
      beneficiary: (m['beneficiary'] as String?) ?? '',
      purchaseDate: DateUtil.fromTs(m['purchase_date'] as int?),
      effectiveDate: DateUtil.fromTs(m['effective_date'] as int?),
      expireDate: DateUtil.fromTs(m['expire_date'] as int?),
      premium: (m['premium'] as num?)?.toDouble(),
      remindEnabled: ((m['remind_enabled'] as int?) ?? 0) == 1,
      summary: (m['summary'] as String?) ?? '',
      attachments: atts,
      remark: (m['remark'] as String?) ?? '',
      status: m['status'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(m['updated_at'] as int),
    );
  }
}
