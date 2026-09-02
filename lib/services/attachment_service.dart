import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 附件文件管理：只保存相对文件名到数据库，磁盘上集中放在 attachments/ 目录。
class AttachmentService {
  AttachmentService._();
  static final AttachmentService instance = AttachmentService._();

  Future<Directory> get _dir async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(root.path, 'attachments'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// 把外部挑选的源文件复制到附件目录，返回新文件名（basename）。
  Future<String> savePickedFile(String sourcePath) async {
    final dir = await _dir;
    final ext = p.extension(sourcePath).toLowerCase();
    final ts = DateTime.now().millisecondsSinceEpoch.toString();
    final name = 'att_$ts$ext';
    final dest = File(p.join(dir.path, name));
    await File(sourcePath).copy(dest.path);
    return name;
  }

  Future<String> resolve(String name) async {
    final dir = await _dir;
    return p.join(dir.path, name);
  }

  Future<bool> exists(String name) async {
    final f = File(await resolve(name));
    return f.exists();
  }

  Future<void> delete(String name) async {
    final f = File(await resolve(name));
    if (await f.exists()) {
      await f.delete();
    }
  }

  Future<List<String>> resolveAll(List<String> names) async {
    final dir = await _dir;
    return names.map((n) => p.join(dir.path, n)).toList();
  }

  Future<void> deleteAll() async {
    final dir = await _dir;
    if (await dir.exists()) {
      await for (final entity in dir.list()) {
        try {
          await entity.delete(recursive: true);
        } catch (_) {}
      }
    }
  }

  /// 读取附件二进制，用于打包备份。
  Future<List<int>?> readBytes(String name) async {
    final f = File(await resolve(name));
    if (!await f.exists()) return null;
    return f.readAsBytes();
  }

  /// 恢复时把文件写入附件目录。
  Future<void> writeBytes(String name, List<int> bytes) async {
    final f = File(await resolve(name));
    await f.writeAsBytes(bytes, flush: true);
  }
}
