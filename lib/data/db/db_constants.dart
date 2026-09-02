/// 数据库表名与字段常量集中管理。
class DbConstants {
  DbConstants._();

  static const int version = 1;

  // 4 张核心业务表
  static const String tableMember = 'family_member';
  static const String tableInsurance = 'insurance';
  static const String tableMedical = 'medical_record';
  static const String tableEvent = 'family_event';

  // 应用级设置（密码 / 字体 / 开关等）
  static const String tableSettings = 'app_settings';
}
