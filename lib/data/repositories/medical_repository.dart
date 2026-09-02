import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import '../models/medical_record.dart';

class MedicalRepository {
  MedicalRepository._();
  static final MedicalRepository instance = MedicalRepository._();

  static const String _table = 'medical_record';

  Future<List<MedicalRecord>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(_table, orderBy: 'visit_time DESC');
    return rows.map(MedicalRecord.fromMap).toList();
  }

  Future<List<MedicalRecord>> getByMember(String memberId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      _table,
      where: 'member_id = ?',
      whereArgs: [memberId],
      orderBy: 'visit_time DESC',
    );
    return rows.map(MedicalRecord.fromMap).toList();
  }

  Future<MedicalRecord?> getById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final rows =
        await db.query(_table, where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return MedicalRecord.fromMap(rows.first);
  }

  Future<void> upsert(MedicalRecord r) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      _table,
      r.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<MedicalRecord>> getUpcomingRevisits({int withinDays = 7}) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    final limit = DateTime(now.year, now.month, now.day)
        .add(Duration(days: withinDays))
        .millisecondsSinceEpoch;
    final rows = await db.query(
      _table,
      where:
          'revisit_time IS NOT NULL AND revisit_time >= ? AND revisit_time <= ? AND revisit_remind = 1',
      whereArgs: [now.millisecondsSinceEpoch, limit],
      orderBy: 'revisit_time ASC',
    );
    return rows.map(MedicalRecord.fromMap).toList();
  }
}
