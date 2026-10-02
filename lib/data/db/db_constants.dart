/// 数据库表名与字段常量集中管理。
class DbConstants {
  DbConstants._();

  /// 版本历史：
  /// - 1：初始版本（成员 / 保单 / 病历 / 事件 / 设置）
  /// - 2：病历表增加体检字段（next_checkup_date、checkup_remind）
  static const int version = 2;

  // 4 张核心业务表
  static const String tableMember = 'family_member';
  static const String tableInsurance = 'insurance';
  static const String tableMedical = 'medical_record';
  static const String tableEvent = 'family_event';

  // 应用级设置（密码 / 字体 / 开关等）
  static const String tableSettings = 'app_settings';
}
