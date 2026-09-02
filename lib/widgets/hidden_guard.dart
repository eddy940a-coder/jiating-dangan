import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/family_member.dart';
import '../providers/hidden_member_unlock_provider.dart';
import '../theme/app_colors.dart';
import 'confirm_dialog.dart';

/// 渲染一个被隐藏成员档案时使用的解锁包装：未解锁则显示"需要解锁"占位。
class HiddenGuard extends StatelessWidget {
  const HiddenGuard({
    super.key,
    required this.member,
    required this.child,
  });

  final FamilyMember member;
  final Widget child;

  Future<bool> _unlock(BuildContext context) async {
    final ok = await ConfirmDialog.show(
      context,
      title: '档案已隐藏',
      message: '「${member.name}」的档案已开启隐藏，请输入应用密码以查看',
      confirmText: '解锁',
    );
    if (!ok) return false;
    if (!context.mounted) return false;
    final pin = await _askPassword(context);
    if (pin == null) return false;
    final res =
        await context.read<HiddenMemberUnlockProvider>().unlock(member.id, pin);
    if (!res && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('密码错误')));
    }
    return res;
  }

  Future<String?> _askPassword(BuildContext context) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('请输入应用密码'),
          content: TextField(
            controller: controller,
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
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: const Text('解锁'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!member.hidden) return child;
    final unlocked =
        context.watch<HiddenMemberUnlockProvider>().isUnlocked(member.id);
    if (unlocked) return child;
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline,
                size: 56, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              '${member.name}的档案已隐藏',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '查看详情需要输入应用密码',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _unlock(context),
              icon: const Icon(Icons.lock_open),
              label: const Text('解锁查看'),
            ),
          ],
        ),
      ),
    );
  }
}
