import 'package:intl/intl.dart';

class DateUtil {
  DateUtil._();

  static final DateFormat _ymd = DateFormat('yyyy-MM-dd');
  static final DateFormat _ymdHm = DateFormat('yyyy-MM-dd HH:mm');
  static final DateFormat _ymdCn = DateFormat('yyyy年MM月dd日');
  static final DateFormat _hm = DateFormat('HH:mm');

  static String ymd(DateTime? d) => d == null ? '-' : _ymd.format(d);
  static String ymdHm(DateTime? d) => d == null ? '-' : _ymdHm.format(d);
  static String ymdCn(DateTime? d) => d == null ? '-' : _ymdCn.format(d);
  static String hm(DateTime? d) => d == null ? '-' : _hm.format(d);

  static int? toTs(DateTime? d) => d?.millisecondsSinceEpoch;
  static DateTime? fromTs(int? ts) =>
      ts == null ? null : DateTime.fromMillisecondsSinceEpoch(ts);

  static int age(DateTime? birthday) {
    if (birthday == null) return 0;
    final now = DateTime.now();
    var a = now.year - birthday.year;
    if (now.month < birthday.month ||
        (now.month == birthday.month && now.day < birthday.day)) {
      a--;
    }
    return a < 0 ? 0 : a;
  }

  static int daysUntil(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    return target.difference(today).inDays;
  }

  static DateTime at(DateTime d, int hour, int minute) =>
      DateTime(d.year, d.month, d.day, hour, minute);

  static DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
}
