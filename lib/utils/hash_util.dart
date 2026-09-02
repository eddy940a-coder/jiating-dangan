import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

class HashUtil {
  HashUtil._();

  static Uint8List randomBytes(int length) {
    final rng = Random.secure();
    final list = Uint8List(length);
    for (var i = 0; i < length; i++) {
      list[i] = rng.nextInt(256);
    }
    return list;
  }

  static String bytesToHex(List<int> bytes) {
    final sb = StringBuffer();
    for (final b in bytes) {
      sb.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return sb.toString();
  }

  static Uint8List hexToBytes(String hex) {
    final clean = hex.replaceAll(' ', '');
    final out = Uint8List(clean.length ~/ 2);
    for (var i = 0; i < out.length; i++) {
      out[i] = int.parse(clean.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return out;
  }

  /// PBKDF2-HMAC-SHA256（纯 Dart 实现，不依赖第三方密码学库）。
  static Uint8List pbkdf2HmacSha256({
    required String password,
    required Uint8List salt,
    int iterations = 10000,
    int keyLength = 32,
  }) {
    final pwd = utf8.encode(password);
    final hLen = 32;
    final blockCount = (keyLength + hLen - 1) ~/ hLen;
    final out = BytesBuilder();
    for (var i = 1; i <= blockCount; i++) {
      final block = Uint8List(4);
      const bigEndian = Endian.big;
      ByteData.view(block.buffer).setUint32(0, i, bigEndian);
      final hmac = Hmac(sha256, pwd);
      var u = Uint8List.fromList(hmac.convert([...salt, ...block]).bytes);
      var t = Uint8List.fromList(u);
      for (var j = 1; j < iterations; j++) {
        u = Uint8List.fromList(hmac.convert(u).bytes);
        for (var k = 0; k < t.length; k++) {
          t[k] = t[k] ^ u[k];
        }
      }
      out.add(t);
    }
    final result = out.toBytes();
    return Uint8List.sublistView(result, 0, keyLength);
  }

  static String sha256Hex(String input) {
    final digest = sha256.convert(utf8.encode(input));
    return digest.toString();
  }
}
