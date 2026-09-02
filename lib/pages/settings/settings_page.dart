import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/family_event.dart';
import '../../data/models/family_member.dart';
import '../../data/models/insurance.dart';
import '../../data/models/medical_record.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/insurance_provider.dart';
import '../../providers/medical_provider.dart';
import '../../providers/member_provider.dart';
import '../../services/backup_service.dart';
import '../../services/biometric_service.dart';
import '../../services/excel_export_service.dart';
import '../../services/notification_service.dart';
import '../../services/settings_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/app_card.dart';
import '../../widgets/confirm_dialog.dart';
import 'about_page.dart';
import 'privacy_policy_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _section('隐私安全'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  value: settings.lockEnabled,
                  onChanged: (v) async {
                    if (v) {
                      await context
                          .read<AppSettingsProvider>()
                          .setLockEnabled(true);
                    } else {
                      final pin = await _askPassword(context);
                      if (pin == null) return;
                      if (!await context
                          .read<AppSettingsProvider>()
                          .verifyPassword(pin)) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('密码错误')),
                          );
                        }
                        return;
                      }
                      await context
                          .read<AppSettingsProvider>()
                          .setLockEnabled(false);
                    }
                  },
                  title: const Text('应用密码锁'),
                  subtitle: const Text('启动或回到前台时要求输入密码',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  activeColor: AppColors.primary,
                ),
                const Divider(height: 1, color: AppColors.divider),
                SwitchListTile(
                  value: settings.biometricEnabled,
                  onChanged: (v) async {
                    if (v) {
                      final ok = await BiometricService.instance.isAvailable();
                      if (!ok) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('当前设备不支持生物识别')),
                          );
                        }
                        return;
                      }
                      final auth = await BiometricService.instance
                          .authenticate(reason: '请验证生物特征');
                      if (!auth) return;
                    }
                    if (!context.mounted) return;
                    await context
                        .read<AppSettingsProvider>()
                        .setBiometricEnabled(v);
                  },
                  title: const Text('生物识别解锁'),
                  subtitle: const Text('Face ID / 指纹',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  activeColor: AppColors.primary,
                ),
                const Divider(height: 1, color: AppColors.divider),
                ListTile(
                  title: const Text('修改密码'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _changePassword(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _section('数据管理'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading:
                      const Icon(Icons.lock_outline, color: AppColors.primary),
                  title: const Text('加密备份导出'),
                  subtitle: const Text('生成 .fda 加密压缩包',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _exportBackup(context),
                ),
                const Divider(height: 1, color: AppColors.divider),
                ListTile(
                  leading: const Icon(Icons.file_download_outlined,
                      color: AppColors.primary),
                  title: const Text('备份恢复导入'),
                  subtitle: const Text('选择 .fda 文件并输入密码恢复',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _importBackup(context),
                ),
                const Divider(height: 1, color: AppColors.divider),
                ListTile(
                  leading: const Icon(Icons.grid_on_outlined,
                      color: AppColors.primary),
                  title: const Text('导出全部 Excel'),
                  subtitle: const Text('4 个工作表：成员/保单/病历/事件',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _exportExcel(context),
                ),
                const Divider(height: 1, color: AppColors.divider),
                ListTile(
                  leading: const Icon(Icons.delete_outline,
                      color: AppColors.red),
                  title: const Text('清除全部本地数据',
                      style: TextStyle(color: AppColors.red)),
                  subtitle: const Text('保留应用密码',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textHint)),
                  onTap: () => _clearAll(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _section('显示设置'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('字体大小',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 4),
                const Text('调整后全局生效',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                    )),
                const SizedBox(height: 10),
                SegmentedButton<FontScaleLevel>(
                  segments: const [
                    ButtonSegment(value: FontScaleLevel.small, label: Text('小')),
                    ButtonSegment(
                        value: FontScaleLevel.normal, label: Text('标准')),
                    ButtonSegment(value: FontScaleLevel.large, label: Text('大')),
                  ],
                  selected: <FontScaleLevel>{settings.fontLevel},
                  onSelectionChanged: (s) {
                    context.read<AppSettingsProvider>().setFontLevel(s.first);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _section('其他'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_outlined,
                      color: AppColors.primary),
                  title: const Text('申请通知权限'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await NotificationService.instance.requestPermissionIfNeeded();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('已尝试申请通知权限')),
                      );
                    }
                  },
                ),
                const Divider(height: 1, color: AppColors.divider),
                ListTile(
                  leading: const Icon(Icons.info_outline,
                      color: AppColors.primary),
                  title: const Text('关于'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AboutPage()),
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined,
                      color: AppColors.primary),
                  title: const Text('隐私政策'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const PrivacyPolicyPage()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '提醒说明：本地通知在系统杀死 App、清理后台或重启后可能不再触发，请在系统设置中允许「后台运行」和「自启动」。',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Future<String?> _askPassword(BuildContext context) async {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('请输入当前应用密码'),
          content: TextField(
            controller: c,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(counterText: ''),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(c.text.trim()),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _changePassword(BuildContext context) async {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('修改密码'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: '当前密码',
                  counterText: '',
                ),
              ),
              TextField(
                controller: newCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: '新密码（6 位）',
                  counterText: '',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
    if (ok != true) return;
    final changed = await context
        .read<AppSettingsProvider>()
        .changePassword(oldCtrl.text.trim(), newCtrl.text.trim());
    if (!context.mounted) return;
    if (changed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('密码已修改')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('当前密码错误')),
      );
    }
  }

  Future<void> _exportBackup(BuildContext context) async {
    final pwCtrl = TextEditingController();
    final pw2Ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('设置备份密码'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pwCtrl,
                obscureText: true,
                maxLength: 32,
                decoration: const InputDecoration(
                  labelText: '请输入密码（至少 6 位）',
                  counterText: '',
                ),
              ),
              TextField(
                controller: pw2Ctrl,
                obscureText: true,
                maxLength: 32,
                decoration: const InputDecoration(
                  labelText: '再次输入',
                  counterText: '',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('导出'),
            ),
          ],
        );
      },
    );
    if (ok != true) return;
    final pw = pwCtrl.text.trim();
    if (pw.length < 6) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('密码至少 6 位')),
        );
      }
      return;
    }
    if (pw != pw2Ctrl.text.trim()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('两次输入不一致')),
        );
      }
      return;
    }
    try {
      final path = await BackupService.instance.exportEncryptedBackup(pw);
      if (!context.mounted) return;
      await Share.shareXFiles(
        [XFile(path)],
        text: '家庭档案加密备份',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败：$e')),
        );
      }
    }
  }

  Future<void> _importBackup(BuildContext context) async {
    final res = await FilePicker.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    if (res == null || res.files.isEmpty) return;
    final path = res.files.first.path;
    if (path == null) return;
    final pwCtrl = TextEditingController();
    if (!context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('请输入备份密码'),
          content: TextField(
            controller: pwCtrl,
            obscureText: true,
            decoration: const InputDecoration(hintText: '备份密码'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('恢复'),
            ),
          ],
        );
      },
    );
    if (ok != true) return;
    try {
      await BackupService.instance
          .importEncryptedBackup(path, pwCtrl.text.trim());
      if (!context.mounted) return;
      final okReload = await ConfirmDialog.show(
        context,
        title: '恢复成功',
        message: '数据已成功导入，是否立即重启 App？',
        confirmText: '重启',
        cancelText: '稍后',
      );
      if (okReload) {
        // 关闭数据库，下次启动时重新打开
        if (Platform.isAndroid || Platform.isIOS) {
          // 通过退出进程方式重启
          // ignore: use_build_context_synchronously
          // 在生产中应实现 Process.kill，这里采用引导用户重启
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('请手动关闭 App 后重新打开')),
          );
        }
      } else {
        // 强制刷新
        if (context.mounted) {
          await context.read<MemberProvider>().load();
          await context.read<InsuranceProvider>().load();
          await context.read<MedicalProvider>().load();
          await context.read<EventProvider>().load();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('数据已加载')),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('恢复失败：$e')),
        );
      }
    }
  }

  Future<void> _exportExcel(BuildContext context) async {
    final members = context.read<MemberProvider>().all;
    final insurances = context.read<InsuranceProvider>().all;
    final medicals = context.read<MedicalProvider>().all;
    final events = context.read<EventProvider>().all;
    try {
      final path = await ExcelExportService.instance.exportAll(
        members: members,
        insurances: insurances,
        medicals: medicals,
        events: events,
      );
      if (!context.mounted) return;
      await Share.shareXFiles(
        [XFile(path)],
        text: '家庭档案 - Excel 导出',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败：$e')),
        );
      }
    }
  }

  Future<void> _clearAll(BuildContext context) async {
    final confirm = await ConfirmDialog.show(
      context,
      title: '清除全部本地数据',
      message: '将清空所有家庭成员、保单、病历、家庭事件及其附件。\n应用密码会保留。此操作不可恢复，是否继续？',
      confirmText: '我已了解，清除',
      danger: true,
    );
    if (!confirm) return;
    if (!context.mounted) return;
    final pin = await _askPassword(context);
    if (pin == null) return;
    final ok = await SettingsService.instance.verifyPassword(pin);
    if (!ok) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('密码错误')),
        );
      }
      return;
    }
    await SettingsService.instance.clearAllBusinessData();
    await context.read<MemberProvider>().load();
    await context.read<InsuranceProvider>().load();
    await context.read<MedicalProvider>().load();
    await context.read<EventProvider>().load();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已清除全部数据')),
      );
    }
  }
}
