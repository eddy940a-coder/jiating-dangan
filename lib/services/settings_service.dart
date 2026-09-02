import 'package:sqflite/sqflite.dart';

import '../data/db/database_helper.dart';
import '../data/repositories/member_repository.dart';
import '../theme/app_text.dart';
import '../utils/hash_util.dart';

/// 应用级设置服务（密码、字体档位、生物识别等）。表: app_settings。
class SettingsService {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  static const String _table = 'app_settings';
  static const String _kPasswordHash = 'password_hash';
  static const String _kPasswordSalt = 'password_salt';
  static const String _kLockEnabled = 'lock_enabled';
  static const String _kBiometricEnabled = 'biometric_enabled';
  static const String _kFontLevel = 'font_level';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    final db = await DatabaseHelper.instance.database;
    // 即使 main 中已经 await database，这里也再保险一次确认表已创建
    await db.query(_table, limit: 1);
    _initialized = true;
  }

  Future<String?> _getRaw(String key) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(_table, where: 'key = ?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> _setRaw(String key, String? value) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      _table,
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ---------- 密码 ----------

  Future<bool> hasPassword() async {
    final v = await _getRaw(_kPasswordHash);
    return v != null && v.isNotEmpty;
  }

  Future<void> setPassword(String pin) async {
    final salt = HashUtil.randomBytes(16);
    final hash = HashUtil.sha256Hex(
        '${HashUtil.bytesToHex(salt)}::$pin');
    await _setRaw(_kPasswordSalt, HashUtil.bytesToHex(salt));
    await _setRaw(_kPasswordHash, hash);
  }

  Future<bool> verifyPassword(String pin) async {
    final saltHex = await _getRaw(_kPasswordSalt);
    final stored = await _getRaw(_kPasswordHash);
    if (saltHex == null || stored == null) return false;
    final expect = HashUtil.sha256Hex('$saltHex::$pin');
    return expect == stored;
  }

  Future<bool> changePassword(String oldPin, String newPin) async {
    if (!await verifyPassword(oldPin)) return false;
    await setPassword(newPin);
    return true;
  }

  // ---------- 锁 / 生物识别 ----------

  Future<bool> isLockEnabled() async {
    final v = await _getRaw(_kLockEnabled);
    // 默认开启密码锁
    if (v == null) return true;
    return v == '1';
  }

  Future<void> setLockEnabled(bool enabled) async {
    await _setRaw(_kLockEnabled, enabled ? '1' : '0');
  }

  Future<bool> isBiometricEnabled() async {
    final v = await _getRaw(_kBiometricEnabled);
    return v == '1';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _setRaw(_kBiometricEnabled, enabled ? '1' : '0');
  }

  // ---------- 字体 ----------

  Future<FontScaleLevel> getFontLevel() async {
    final v = await _getRaw(_kFontLevel);
    switch (v) {
      case 'small':
        return FontScaleLevel.small;
      case 'large':
        return FontScaleLevel.large;
      default:
        return FontScaleLevel.normal;
    }
  }

  Future<void> setFontLevel(FontScaleLevel level) async {
    final v = switch (level) {
      FontScaleLevel.small => 'small',
      FontScaleLevel.normal => 'normal',
      FontScaleLevel.large => 'large',
    };
    await _setRaw(_kFontLevel, v);
  }

  // ---------- 测试 / 工具 ----------

  /// 重置全部业务数据但保留密码与设置。
  Future<void> clearAllBusinessData() async {
    await DatabaseHelper.instance.clearAllBusinessData();
    // 通知一下侧效应（保险/病历自动事件会随外键级联删除）
  }
}
