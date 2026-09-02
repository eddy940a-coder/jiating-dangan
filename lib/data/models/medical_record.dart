import 'dart:convert';

import '../../utils/date_util.dart';

const List<String> medicalVisitTypes = <String>['门诊', '住院', '手术', '体检', '其他'];

class MedicalRecord {
  MedicalRecord({
    required this.id,
    required this.memberId,
    required this.visitTime,
    this.hospital = '',
    this.department = '',
    this.doctor = '',
    this.visitType = '门诊',
    this.chiefComplaint = '',
    this.diagnosis = '',
    this.medication = '',
    this.revisitTime,
    this.revisitRemind = false,
    this.attachments = const <String>[],
    this.remark = '',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  String memberId;
  DateTime visitTime;
  String hospital;
  String department;
  String doctor;
  String visitType;
  String chiefComplaint;
  String diagnosis;
  String medication;
  DateTime? revisitTime;
  bool revisitRemind;
  List<String> attachments;
  String remark;
  final DateTime createdAt;
  final DateTime updatedAt;

  MedicalRecord copyWith({
    String? memberId,
    DateTime? visitTime,
    String? hospital,
    String? department,
    String? doctor,
    String? visitType,
    String? chiefComplaint,
    String? diagnosis,
    String? medication,
    DateTime? revisitTime,
    bool clearRevisitTime = false,
    bool? revisitRemind,
    List<String>? attachments,
    String? remark,
    DateTime? updatedAt,
  }) {
    return MedicalRecord(
      id: id,
      memberId: memberId ?? this.memberId,
      visitTime: visitTime ?? this.visitTime,
      hospital: hospital ?? this.hospital,
      department: department ?? this.department,
      doctor: doctor ?? this.doctor,
      visitType: visitType ?? this.visitType,
      chiefComplaint: chiefComplaint ?? this.chiefComplaint,
      diagnosis: diagnosis ?? this.diagnosis,
      medication: medication ?? this.medication,
      revisitTime: clearRevisitTime ? null : (revisitTime ?? this.revisitTime),
      revisitRemind: revisitRemind ?? this.revisitRemind,
      attachments: attachments ?? this.attachments,
      remark: remark ?? this.remark,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'member_id': memberId,
        'visit_time': visitTime.millisecondsSinceEpoch,
        'hospital': hospital,
        'department': department,
        'doctor': doctor,
        'visit_type': visitType,
        'chief_complaint': chiefComplaint,
        'diagnosis': diagnosis,
        'medication': medication,
        'revisit_time': DateUtil.toTs(revisitTime),
        'revisit_remind': revisitRemind ? 1 : 0,
        'attachments': jsonEncode(attachments),
        'remark': remark,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory MedicalRecord.fromMap(Map<String, Object?> m) {
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
    return MedicalRecord(
      id: m['id'] as String,
      memberId: m['member_id'] as String,
      visitTime:
          DateTime.fromMillisecondsSinceEpoch(m['visit_time'] as int),
      hospital: (m['hospital'] as String?) ?? '',
      department: (m['department'] as String?) ?? '',
      doctor: (m['doctor'] as String?) ?? '',
      visitType: (m['visit_type'] as String?) ?? '门诊',
      chiefComplaint: (m['chief_complaint'] as String?) ?? '',
      diagnosis: (m['diagnosis'] as String?) ?? '',
      medication: (m['medication'] as String?) ?? '',
      revisitTime: DateUtil.fromTs(m['revisit_time'] as int?),
      revisitRemind: ((m['revisit_remind'] as int?) ?? 0) == 1,
      attachments: atts,
      remark: (m['remark'] as String?) ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(m['updated_at'] as int),
    );
  }
}
