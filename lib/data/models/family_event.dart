import 'dart:convert';

import '../../utils/date_util.dart';

/// 事件类型 - 决定时间线圆点颜色
const String kEventTypeInsurance = 'insurance';
const String kEventTypeMedical = 'medical';
const String kEventTypeManual = 'manual';

const List<String> eventTypeLabels = <String>[kEventTypeInsurance, kEventTypeMedical, kEventTypeManual];

/// 手动事件可选分类
const List<String> manualEventCategories = <String>[
  '生活',
  '生日',
  '旅行',
  '升学',
  '搬家',
  '纪念日',
  '婚嫁',
  '工作',
  '健康',
  '其他',
];

String eventTypeLabel(String t) {
  switch (t) {
    case kEventTypeInsurance:
      return '保险';
    case kEventTypeMedical:
      return '就医';
    case kEventTypeManual:
      return '家庭';
    default:
      return '其他';
  }
}

class FamilyEvent {
  FamilyEvent({
    required this.id,
    required this.memberIds,
    required this.eventTime,
    required this.category,
    required this.type,
    required this.title,
    this.description = '',
    this.attachments = const <String>[],
    this.relatedId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  List<String> memberIds;
  DateTime eventTime;
  String category;
  String type;
  String title;
  String description;
  List<String> attachments;
  String? relatedId;
  final DateTime createdAt;
  final DateTime updatedAt;

  FamilyEvent copyWith({
    List<String>? memberIds,
    DateTime? eventTime,
    String? category,
    String? type,
    String? title,
    String? description,
    List<String>? attachments,
    String? relatedId,
    bool clearRelatedId = false,
    DateTime? updatedAt,
  }) {
    return FamilyEvent(
      id: id,
      memberIds: memberIds ?? this.memberIds,
      eventTime: eventTime ?? this.eventTime,
      category: category ?? this.category,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      attachments: attachments ?? this.attachments,
      relatedId: clearRelatedId ? null : (relatedId ?? this.relatedId),
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'member_ids': jsonEncode(memberIds),
        'event_time': eventTime.millisecondsSinceEpoch,
        'category': category,
        'type': type,
        'title': title,
        'description': description,
        'attachments': jsonEncode(attachments),
        'related_id': relatedId,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory FamilyEvent.fromMap(Map<String, Object?> m) {
    List<String> parseList(String? raw) {
      if (raw == null || raw.isEmpty) return const <String>[];
      try {
        final v = jsonDecode(raw);
        if (v is List) return v.map((e) => e.toString()).toList();
      } catch (_) {}
      return const <String>[];
    }

    final atts = <String>[];
    final attRaw = m['attachments'] as String?;
    if (attRaw != null && attRaw.isNotEmpty) {
      try {
        final v = jsonDecode(attRaw);
        if (v is List) atts.addAll(v.map((e) => e.toString()));
      } catch (_) {}
    }
    return FamilyEvent(
      id: m['id'] as String,
      memberIds: parseList(m['member_ids'] as String?),
      eventTime: DateTime.fromMillisecondsSinceEpoch(m['event_time'] as int),
      category: (m['category'] as String?) ?? '生活',
      type: m['type'] as String,
      title: m['title'] as String,
      description: (m['description'] as String?) ?? '',
      attachments: atts,
      relatedId: m['related_id'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(m['updated_at'] as int),
    );
  }
}
