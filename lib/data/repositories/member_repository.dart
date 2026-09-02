import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import '../models/family_member.dart';

class MemberRepository {
  MemberRepository._();
  static final MemberRepository instance = MemberRepository._();

  static const String _table = 'family_member';

  Future<List<FamilyMember>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(_table, orderBy: 'created_at ASC');
    return rows.map(FamilyMember.fromMap).toList();
  }

  Future<FamilyMember?> getById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return FamilyMember.fromMap(rows.first);
  }

  Future<void> upsert(FamilyMember m) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      _table,
      m.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}
