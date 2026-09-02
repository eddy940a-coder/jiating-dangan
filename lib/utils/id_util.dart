import 'dart:math';

class IdUtil {
  IdUtil._();

  static String newId() {
    final now = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final rand = Random.secure().nextInt(1 << 32).toRadixString(36);
    return '$now-$rand';
  }

  /// 把字符串 id 折叠成 31 位正整数，作为通知 id 用。
  static int intId(String s) => s.hashCode & 0x7fffffff;
}
