import 'package:flutter/foundation.dart';

import '../data/models/insurance.dart';
import '../data/repositories/insurance_repository.dart';
import '../services/record_sync_service.dart';

class InsuranceProvider extends ChangeNotifier {
  final InsuranceRepository _repo = InsuranceRepository.instance;
  final RecordSyncService _sync = RecordSyncService.instance;

  List<Insurance> _items = <Insurance>[];
  bool _loaded = false;

  List<Insurance> get all => List.unmodifiable(_items);
  bool get loaded => _loaded;

  List<Insurance> byMember(String id) =>
      _items.where((i) => i.memberId == id).toList();

  List<Insurance> byStatus(String status) =>
      _items.where((i) => i.status == status).toList();

  Insurance? byId(String id) {
    for (final i in _items) {
      if (i.id == id) return i;
    }
    return null;
  }

  Future<void> load() async {
    _items = await _repo.getAll();
    _loaded = true;
    notifyListeners();
  }

  Future<void> upsert(Insurance item) async {
    await _repo.upsert(item);
    await _sync.afterSaveInsurance(item);
    await load();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    await _sync.afterDeleteInsurance(id);
    await load();
  }
}
