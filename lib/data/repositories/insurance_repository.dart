import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import '../models/insurance.dart';

class InsuranceRepository {
  InsuranceRepository._();
  static final InsuranceRepository instance = InsuranceRepository._();

  static const String _table = 'insurance';

  Future<List<Insurance>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(_table, orderBy: 'created_at DESC');
    return rows.map(Insurance.fromMap).toList();
  }

  Future<List<Insurance>> getByMember(String memberId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      _table,
      where: 'member_id = ?',
      whereArgs: [memberId],
      orderBy: 'created_at DESC',
    );
    return rows.map(Insurance.fromMap).toList();
  }

  Future<Insurance?> getById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final rows =
        await db.query(_table, where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Insurance.fromMap(rows.first);
  }

  Future<void> upsert(Insurance item) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      _table,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Insurance>> getByStatus(String status) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      _table,
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'expire_date ASC',
    );
    return rows.map(Insurance.fromMap).toList();
  }

  Future<List<Insurance>> getExpiringWithin(int days) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    final limit = DateTime(now.year, now.month, now.day)
        .add(Duration(days: days))
        .millisecondsSinceEpoch;
    final rows = await db.query(
      _table,
      where: 'expire_date IS NOT NULL AND expire_date >= ? AND expire_date <= ? AND status != ?',
      whereArgs: [now.millisecondsSinceEpoch, limit, '已失效'],
      orderBy: 'expire_date ASC',
    );
    return rows.map(Insurance.fromMap).toList();
  }
}
