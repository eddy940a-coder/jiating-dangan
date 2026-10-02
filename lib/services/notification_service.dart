import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/models/insurance.dart';
import '../data/models/medical_record.dart';
import '../utils/date_util.dart';
import '../utils/id_util.dart';

/// 本地通知服务（无需后端）。计划通知在系统杀死 App 时会失效，文档化提示。
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'family_archive_reminder';
  static const String _channelName = '家庭档案提醒';
  static const String _channelDesc = '保单到期、复诊等本地提醒';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onTap,
    );
    _initialized = true;
  }

  void _onTap(NotificationResponse r) {
    // MVP 阶段不处理深链；保留扩展点。
  }

  Future<void> requestPermissionIfNeeded() async {
    if (Platform.isAndroid) {
      await Permission.notification.request();
      // 部分 ROM 还需 schedule exact alarm
      await Permission.scheduleExactAlarm
          .request()
          .catchError((_) => PermissionStatus.denied);
    } else if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  NotificationDetails _details() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  // ---------- 公开 API ----------

  /// 计划一条保单到期提醒（前 30 天 + 当天两次）。
  Future<void> scheduleInsuranceReminders(Insurance item) async {
    if (!item.remindEnabled || item.expireDate == null) {
      await cancelInsuranceReminders(item.id);
      return;
    }
    final base = IdUtil.intId('ins_${item.id}');
    const title = '保单即将到期';
    final body =
        '${item.type}（${item.company}）将于 ${DateUtil.ymd(item.expireDate)} 到期，请及时办理续保。';

    // 到期当天 09:00
    await _scheduleAt(
      id: base,
      when: DateUtil.at(item.expireDate!, 9, 0),
      title: '保单今日到期',
      body: body,
    );
    // 到期前 30 天 09:00
    final before30 = item.expireDate!.subtract(const Duration(days: 30));
    await _scheduleAt(
      id: base + 1,
      when: DateUtil.at(before30, 9, 0),
      title: title,
      body: body,
    );
  }

  Future<void> cancelInsuranceReminders(String insuranceId) async {
    final base = IdUtil.intId('ins_$insuranceId');
    await _plugin.cancel(base);
    await _plugin.cancel(base + 1);
  }

  /// 复诊提醒：复诊前一天晚 20:00 + 当天早 08:00
  Future<void> scheduleRevisitReminders(MedicalRecord r) async {
    if (!r.revisitRemind || r.revisitTime == null) {
      await cancelRevisitReminders(r.id);
      return;
    }
    final base = IdUtil.intId('med_${r.id}');
    final body =
        '复诊时间：${DateUtil.ymd(r.revisitTime)}${r.hospital.isNotEmpty ? "（${r.hospital}）" : ""}';

    await _scheduleAt(
      id: base,
      when: DateUtil.at(r.revisitTime!, 8, 0),
      title: '今日复诊提醒',
      body: body,
    );
    final dayBefore = r.revisitTime!.subtract(const Duration(days: 1));
    await _scheduleAt(
      id: base + 1,
      when: DateUtil.at(dayBefore, 20, 0),
      title: '明日复诊提醒',
      body: body,
    );
  }

  Future<void> cancelRevisitReminders(String medicalId) async {
    final base = IdUtil.intId('med_$medicalId');
    await _plugin.cancel(base);
    await _plugin.cancel(base + 1);
  }

  /// 体检提醒：体检前 7 天晚 20:00 + 当天早 08:00
  ///
  /// 通知 id 在复诊的基础上偏移 2，避免同一条病历的两种提醒互相覆盖。
  Future<void> scheduleCheckupReminders(MedicalRecord r) async {
    if (!r.checkupRemind || r.nextCheckupDate == null) {
      await cancelCheckupReminders(r.id);
      return;
    }
    final base = IdUtil.intId('med_${r.id}') + 2;
    final body = '计划体检日：${DateUtil.ymd(r.nextCheckupDate)}';

    await _scheduleAt(
      id: base,
      when: DateUtil.at(r.nextCheckupDate!, 8, 0),
      title: '今日体检提醒',
      body: body,
    );
    final daysBefore = r.nextCheckupDate!.subtract(const Duration(days: 7));
    await _scheduleAt(
      id: base + 1,
      when: DateUtil.at(daysBefore, 20, 0),
      title: '体检提醒：还有 7 天',
      body: body,
    );
  }

  Future<void> cancelCheckupReminders(String medicalId) async {
    final base = IdUtil.intId('med_$medicalId') + 2;
    await _plugin.cancel(base);
    await _plugin.cancel(base + 1);
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  // ---------- 内部 ----------

  Future<void> _scheduleAt({
    required int id,
    required DateTime when,
    required String title,
    required String body,
  }) async {
    // 仅计划未来时间
    final now = DateTime.now();
    if (!when.isAfter(now)) {
      await _plugin.cancel(id);
      return;
    }
    // 以 UTC 为基准：把「本地目标时间」减去本机时区偏移，换算成对应的 UTC 时刻。
    // 这样无需依赖 flutter_native_timezone 去拿 IANA 时区名，跨时区同样准确。
    final utcTarget = when.subtract(DateTime.now().timeZoneOffset);
    final tzWhen = tz.TZDateTime.from(utcTarget, tz.UTC);
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzWhen,
        _details(),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      // 缺少精确闹钟权限时退回 inexact
      debugPrint('zonedSchedule exact fail, fallback: $e');
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzWhen,
        _details(),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }
}
