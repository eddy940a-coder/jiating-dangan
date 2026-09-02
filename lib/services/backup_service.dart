import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/db/database_helper.dart';
import '../data/repositories/event_repository.dart';
import '../data/repositories/insurance_repository.dart';
import '../data/repositories/medical_repository.dart';
import '../data/repositories/member_repository.dart';
import '../utils/hash_util.dart';
import 'attachment_service.dart';

/// 加密备份：把数据库文件 + 附件目录 zip 后用 AES-256-CBC 加密。
///
/// 文件格式 (.fda)：
///   magic:        'FDA1'            4 bytes
///   version:      0x01              1 byte
///   salt(16) + iv(16) + ciphertext
///
/// 解密时使用用户密码经 PBKDF2-HMAC-SHA256 派生 32 字节密钥。
class BackupService {
  BackupService._();
  static final BackupService instance = BackupService._();

  static const String _magic = 'FDA1';
  static const int _version = 1;
  static const int _pbkdf2Iters = 10000;

  /// 把所有数据加密导出为一个 .fda 文件，返回文件路径。
  Future<String> exportEncryptedBackup(String password) async {
    if (password.length < 6) {
      throw ArgumentError('备份密码至少 6 位');
    }
    // 1. 读 db 字节
    final dbBytes = await DatabaseHelper.instance.readDatabaseBytes();
    // 2. 读所有附件
    final members = await MemberRepository.instance.getAll();
    final insurances = await InsuranceRepository.instance.getAll();
    final medicals = await MedicalRepository.instance.getAll();
    final events = await EventRepository.instance.getAll();

    final attachmentNames = <String>{};
    for (final m in members) {
      if (m.avatarPath != null) attachmentNames.add(m.avatarPath!);
    }
    for (final i in insurances) {
      attachmentNames.addAll(i.attachments);
    }
    for (final r in medicals) {
      attachmentNames.addAll(r.attachments);
    }
    for (final e in events) {
      attachmentNames.addAll(e.attachments);
    }

    final archive = Archive();
    archive.addFile(ArchiveFile(
      'database/family_archive.db',
      dbBytes.length,
      dbBytes,
    ));

    final manifest = <String, Object?>{
      'version': _version,
      'created_at': DateTime.now().toIso8601String(),
      'attachments': attachmentNames.toList(),
      'member_count': members.length,
      'insurance_count': insurances.length,
      'medical_count': medicals.length,
      'event_count': events.length,
    };
    final manifestBytes = utf8.encode(jsonEncode(manifest));
    archive.addFile(ArchiveFile(
      'manifest.json',
      manifestBytes.length,
      manifestBytes,
    ));

    for (final name in attachmentNames) {
      final bytes = await AttachmentService.instance.readBytes(name);
      if (bytes == null) continue;
      archive.addFile(ArchiveFile(
        'attachments/$name',
        bytes.length,
        bytes,
      ));
    }

    final zipBytes = ZipEncoder().encode(archive) ?? Uint8List(0);

    // 3. AES 加密
    final salt = HashUtil.randomBytes(16);
    final iv = HashUtil.randomBytes(16);
    final keyBytes = HashUtil.pbkdf2HmacSha256(
      password: password,
      salt: salt,
      iterations: _pbkdf2Iters,
      keyLength: 32,
    );
    final encrypter = enc.Encrypter(
      enc.AES(
        enc.Key(keyBytes),
        mode: enc.AESMode.cbc,
        padding: 'PKCS7',
      ),
    );
    final encrypted = encrypter.encryptBytes(zipBytes, iv: enc.IV(iv));

    // 4. 写文件
    final dir = await getApplicationDocumentsDirectory();
    final exportDir = Directory(p.join(dir.path, 'exports'));
    if (!await exportDir.exists()) await exportDir.create(recursive: true);
    final ts = DateFormatSafe.compact(DateTime.now());
    final file = File(p.join(exportDir.path, 'family_archive_$ts.fda'));

    final out = BytesBuilder();
    out.add(utf8.encode(_magic));
    out.addByte(_version);
    out.add(salt);
    out.add(iv);
    out.add(encrypted.bytes);

    await file.writeAsBytes(out.toBytes(), flush: true);
    return file.path;
  }

  /// 从 .fda 文件恢复：解密 → 解压 → 替换 db + 附件 → 重开数据库。
  Future<void> importEncryptedBackup(String filePath, String password) async {
    final bytes = await File(filePath).readAsBytes();
    if (bytes.length < 4 + 1 + 16 + 16) {
      throw const FormatException('备份文件不完整');
    }
    final magic = utf8.decode(bytes.sublist(0, 4));
    if (magic != _magic) {
      throw const FormatException('备份文件格式错误');
    }
    final ver = bytes[4];
    if (ver != _version) {
      throw FormatException('备份版本不支持: $ver');
    }
    final salt = Uint8List.fromList(bytes.sublist(5, 21));
    final iv = Uint8List.fromList(bytes.sublist(21, 37));
    final cipher = Uint8List.fromList(bytes.sublist(37));

    final keyBytes = HashUtil.pbkdf2HmacSha256(
      password: password,
      salt: salt,
      iterations: _pbkdf2Iters,
      keyLength: 32,
    );
    final encrypter = enc.Encrypter(
      enc.AES(
        enc.Key(keyBytes),
        mode: enc.AESMode.cbc,
        padding: 'PKCS7',
      ),
    );
    final zipBytes = encrypter.decryptBytes(
      enc.Encrypted(cipher),
      iv: enc.IV(iv),
    );

    // 5. 解压
    final archive = ZipDecoder().decodeBytes(zipBytes);

    // 6. 替换 db 文件
    final dbEntry = archive.files.firstWhere(
      (f) => f.name == 'database/family_archive.db',
      orElse: () => throw const FormatException('备份缺少数据库文件'),
    );
    final dbBytes = dbEntry.content as List<int>;
    await DatabaseHelper.instance.replaceDatabaseWithBytes(dbBytes);

    // 7. 清空附件目录并恢复
    await AttachmentService.instance.deleteAll();
    for (final f in archive.files) {
      if (f.isFile && f.name.startsWith('attachments/')) {
        final name = f.name.substring('attachments/'.length);
        if (name.isEmpty) continue;
        final data = f.content as List<int>;
        await AttachmentService.instance.writeBytes(name, data);
      }
    }
  }
}

/// 简化日期格式化（避免再 import intl）
class DateFormatSafe {
  static String compact(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}${two(d.month)}${two(d.day)}_${two(d.hour)}${two(d.minute)}';
  }
}
