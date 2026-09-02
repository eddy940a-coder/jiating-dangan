import 'package:flutter/foundation.dart';

import '../data/models/family_event.dart';
import '../data/repositories/event_repository.dart';

class EventProvider extends ChangeNotifier {
  final EventRepository _repo = EventRepository.instance;

  List<FamilyEvent> _items = <FamilyEvent>[];
  bool _loaded = false;

  List<FamilyEvent> get all => List.unmodifiable(_items);
  bool get loaded => _loaded;

  Future<void> load() async {
    _items = await _repo.getAll();
    _loaded = true;
    notifyListeners();
  }

  Future<void> upsert(FamilyEvent e) async {
    await _repo.upsert(e);
    await load();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    await load();
  }
}
