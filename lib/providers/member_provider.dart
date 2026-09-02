import 'package:flutter/foundation.dart';

import '../data/models/family_member.dart';
import '../data/repositories/member_repository.dart';

class MemberProvider extends ChangeNotifier {
  final MemberRepository _repo = MemberRepository.instance;

  List<FamilyMember> _members = <FamilyMember>[];
  bool _loaded = false;

  List<FamilyMember> get all => List.unmodifiable(_members);
  bool get loaded => _loaded;

  List<FamilyMember> get visible =>
      _members.where((m) => !m.hidden).toList();

  FamilyMember? byId(String id) {
    for (final m in _members) {
      if (m.id == id) return m;
    }
    return null;
  }

  Future<void> load() async {
    _members = await _repo.getAll();
    _loaded = true;
    notifyListeners();
  }

  Future<void> upsert(FamilyMember m) async {
    await _repo.upsert(m);
    await load();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    await load();
  }
}
