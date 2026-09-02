import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'db_constants.dart';

/// 单例 SQLite 数据库助手。负责：
/// - 初始化所有表（含应用设置表）
/// - 提供文件级操作：备份/恢复需要拷贝 db 文件
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;
  Completer<Database>? _opening;

  Future<Database> get database async {
    if (_db != null) return _db!;
    if (_opening != null) return _opening!.future;
    _opening = Completer<Database>();
    try {
      final db = await _open();
      _db = db;
      _opening!.complete(db);
      return db;
    } catch (e, st) {
      _opening!.completeError(e, st);
      rethrow;
    } finally {
      _opening = null;
    }
  }

  Future<String> get databasePath async {
    final dir = await getDatabasesPath();
    return p.join(dir, 'family_archive.db');
  }

  Future<Database> _open() async {
    final path = await databasePath;
    return openDatabase(
      path,
      version: DbConstants.version,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createMemberTable(db);
    await _createInsuranceTable(db);
    await _createMedicalTable(db);
    await _createEventTable(db);
    await _createSettingsTable(db);
  }

  Future<void> _createMemberTable(Database db) async {
    await db.execute('''
      CREATE TABLE ${DbConstants.tableMember} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        relation TEXT NOT NULL,
        birthday INTEGER,
        blood_type TEXT,
        id_card TEXT,
        allergy TEXT,
        chronic_disease TEXT,
        avatar_path TEXT,
        hidden INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _createInsuranceTable(Database db) async {
    await db.execute('''
      CREATE TABLE ${DbConstants.tableInsurance} (
        id TEXT PRIMARY KEY,
        member_id TEXT NOT NULL,
        type TEXT NOT NULL,
        company TEXT,
        policy_no TEXT,
        policy_holder TEXT,
        insured_person TEXT,
        beneficiary TEXT,
        purchase_date INTEGER,
        effective_date INTEGER,
        expire_date INTEGER,
        premium REAL,
        remind_enabled INTEGER NOT NULL DEFAULT 0,
        summary TEXT,
        attachments TEXT,
        remark TEXT,
        status TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (member_id) REFERENCES ${DbConstants.tableMember}(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_insurance_member ON ${DbConstants.tableInsurance}(member_id)',
    );
    await db.execute(
      'CREATE INDEX idx_insurance_expire ON ${DbConstants.tableInsurance}(expire_date)',
    );
  }

  Future<void> _createMedicalTable(Database db) async {
    await db.execute('''
      CREATE TABLE ${DbConstants.tableMedical} (
        id TEXT PRIMARY KEY,
        member_id TEXT NOT NULL,
        visit_time INTEGER NOT NULL,
        hospital TEXT,
        department TEXT,
        doctor TEXT,
        visit_type TEXT,
        chief_complaint TEXT,
        diagnosis TEXT,
        medication TEXT,
        revisit_time INTEGER,
        revisit_remind INTEGER NOT NULL DEFAULT 0,
        attachments TEXT,
        remark TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (member_id) REFERENCES ${DbConstants.tableMember}(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_medical_member ON ${DbConstants.tableMedical}(member_id)',
    );
    await db.execute(
      'CREATE INDEX idx_medical_visit_time ON ${DbConstants.tableMedical}(visit_time)',
    );
  }

  Future<void> _createEventTable(Database db) async {
    await db.execute('''
      CREATE TABLE ${DbConstants.tableEvent} (
        id TEXT PRIMARY KEY,
        member_ids TEXT NOT NULL,
        event_time INTEGER NOT NULL,
        category TEXT NOT NULL,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        attachments TEXT,
        related_id TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_event_time ON ${DbConstants.tableEvent}(event_time)',
    );
  }

  Future<void> _createSettingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE ${DbConstants.tableSettings} (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  // ---------- 文件级辅助 ----------

  /// 把 WAL 落盘，保证拷贝出来的 db 文件包含全部已写入数据。
  Future<void> checkpoint() async {
    final db = await database;
    await db.rawQuery('PRAGMA wal_checkpoint(TRUNCATE)');
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  /// 完全清空业务数据（保留设置与密码）。
  Future<void> clearAllBusinessData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(DbConstants.tableEvent);
      await txn.delete(DbConstants.tableMedical);
      await txn.delete(DbConstants.tableInsurance);
      await txn.delete(DbConstants.tableMember);
    });
  }

  /// 把当前 db 文件内容读成字节。
  Future<List<int>> readDatabaseBytes() async {
    await checkpoint();
    final path = await databasePath;
    return File(path).readAsBytes();
  }

  /// 用备份数据替换 db 文件并重开。导入后调用。
  Future<void> replaceDatabaseWithBytes(List<int> bytes) async {
    await close();
    final path = await databasePath;
    await File(path).writeAsBytes(bytes, flush: true);
    // 触发下次 get database 重新打开
  }

  /// 获取 db 文件所在目录（备份/恢复时用）。
  Future<String> get databaseFilePath => databasePath;
}
