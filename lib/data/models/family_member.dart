import 'dart:convert';

import '../../utils/date_util.dart';

class FamilyMember {
  FamilyMember({
    required this.id,
    required this.name,
    required this.relation,
    this.birthday,
    this.bloodType = '',
    this.idCard = '',
    this.allergy = '',
    this.chronicDisease = '',
    this.avatarPath,
    this.hidden = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  String name;
  String relation;
  DateTime? birthday;
  String bloodType;
  String idCard;
  String allergy;
  String chronicDisease;
  String? avatarPath;
  bool hidden;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get age => DateUtil.age(birthday);

  FamilyMember copyWith({
    String? name,
    String? relation,
    DateTime? birthday,
    bool clearBirthday = false,
    String? bloodType,
    String? idCard,
    String? allergy,
    String? chronicDisease,
    String? avatarPath,
    bool clearAvatar = false,
    bool? hidden,
    DateTime? updatedAt,
  }) {
    return FamilyMember(
      id: id,
      name: name ?? this.name,
      relation: relation ?? this.relation,
      birthday: clearBirthday ? null : (birthday ?? this.birthday),
      bloodType: bloodType ?? this.bloodType,
      idCard: idCard ?? this.idCard,
      allergy: allergy ?? this.allergy,
      chronicDisease: chronicDisease ?? this.chronicDisease,
      avatarPath: clearAvatar ? null : (avatarPath ?? this.avatarPath),
      hidden: hidden ?? this.hidden,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'relation': relation,
        'birthday': DateUtil.toTs(birthday),
        'blood_type': bloodType,
        'id_card': idCard,
        'allergy': allergy,
        'chronic_disease': chronicDisease,
        'avatar_path': avatarPath,
        'hidden': hidden ? 1 : 0,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory FamilyMember.fromMap(Map<String, Object?> m) => FamilyMember(
        id: m['id'] as String,
        name: m['name'] as String,
        relation: m['relation'] as String,
        birthday: DateUtil.fromTs(m['birthday'] as int?),
        bloodType: (m['blood_type'] as String?) ?? '',
        idCard: (m['id_card'] as String?) ?? '',
        allergy: (m['allergy'] as String?) ?? '',
        chronicDisease: (m['chronic_disease'] as String?) ?? '',
        avatarPath: m['avatar_path'] as String?,
        hidden: ((m['hidden'] as int?) ?? 0) == 1,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(m['updated_at'] as int),
      );

  String toJson() => jsonEncode(toMap());
}

/// 固定的几个关系选项
const List<String> memberRelations = <String>[
  '本人',
  '配偶',
  '父亲',
  '母亲',
  '儿子',
  '女儿',
  '爷爷',
  '奶奶',
  '外公',
  '外婆',
  '兄弟',
  '姐妹',
  '其他亲属',
  '朋友',
  '其他',
];

const List<String> bloodTypes = <String>['A型', 'B型', 'O型', 'AB型', 'Rh阴性', '不详'];
