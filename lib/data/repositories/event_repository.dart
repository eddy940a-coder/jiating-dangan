import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import '../models/family_event.dart';

class EventRepository {
  EventRepository._();
  static final EventRepository instance = EventRepository._();

  static const String _table = 'family_event';

  Future<List<FamilyEvent>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(_table, orderBy: 'event_time DESC');
    return rows.map(FamilyEvent.fromMap).toList();
  }

  Future<List<FamilyEvent>> getByType(String type) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      _table,
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'event_time DESC',
    );
    return rows.map(FamilyEvent.fromMap).toList();
  }

  Future<List<FamilyEvent>> getByRelatedId(String relatedId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      _table,
      where: 'related_id = ?',
      whereArgs: [relatedId],
    );
    return rows.map(FamilyEvent.fromMap).toList();
  }

  Future<List<FamilyEvent>> getRecent({int limit = 3}) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      _table,
      orderBy: 'event_time DESC',
      limit: limit,
    );
    return rows.map(FamilyEvent.fromMap).toList();
  }

  Future<void> upsert(FamilyEvent e) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      _table,
      e.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteByRelatedId(String relatedId) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(_table, where: 'related_id = ?', whereArgs: [relatedId]);
  }
}
