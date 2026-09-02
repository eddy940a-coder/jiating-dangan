import 'package:flutter/foundation.dart';

import '../data/models/medical_record.dart';
import '../data/repositories/medical_repository.dart';
import '../services/record_sync_service.dart';

class MedicalProvider extends ChangeNotifier {
  final MedicalRepository _repo = MedicalRepository.instance;
  final RecordSyncService _sync = RecordSyncService.instance;

  List<MedicalRecord> _items = <MedicalRecord>[];
  bool _loaded = false;

  List<MedicalRecord> get all => List.unmodifiable(_items);
  bool get loaded => _loaded;

  List<MedicalRecord> byMember(String id) =>
      _items.where((i) => i.memberId == id).toList();

  MedicalRecord? byId(String id) {
    for (final r in _items) {
      if (r.id == id) return r;
    }
    return null;
  }

  Future<void> load() async {
    _items = await _repo.getAll();
    _loaded = true;
    notifyListeners();
  }

  Future<void> upsert(MedicalRecord r) async {
    await _repo.upsert(r);
    await _sync.afterSaveMedical(r);
    await load();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    await _sync.afterDeleteMedical(id);
    await load();
  }
}
