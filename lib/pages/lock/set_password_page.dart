import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_settings_provider.dart';
import '../../theme/app_colors.dart';

/// 首次使用：创建 6 位密码。
class SetPasswordPage extends StatefulWidget {
  const SetPasswordPage({super.key});

  @override
  State<SetPasswordPage> createState() => _SetPasswordPageState();
}

class _SetPasswordPageState extends State<SetPasswordPage> {
  String _first = '';
  String _confirm = '';
  String? _error;
  bool _stage = true; // true: 输入第一遍；false: 确认

  void _onKey(String v) {
    if (_stage ? _first.length >= 6 : _confirm.length >= 6) return;
    setState(() {
      _error = null;
      if (_stage) {
        _first = _first + v;
        if (_first.length == 6) {
          _stage = false;
        }
      } else {
        _confirm = _confirm + v;
        if (_confirm.length == 6) {
          _submit();
        }
      }
    });
  }

  void _onDelete() {
    setState(() {
      _error = null;
      if (_stage) {
        if (_first.isNotEmpty) _first = _first.substring(0, _first.length - 1);
      } else {
        if (_confirm.isNotEmpty) {
          _confirm = _confirm.substring(0, _confirm.length - 1);
        } else {
          _stage = true;
        }
      }
    });
  }

  Future<void> _submit() async {
    if (_first != _confirm) {
      setState(() {
        _error = '两次密码不一致，请重新输入';
        _confirm = '';
      });
      return;
    }
    // 保存密码后，根 widget 会监听到 hasPassword 变化并自动切到解锁页。
    await context.read<AppSettingsProvider>().setPassword(_first);
  }

  @override
  Widget build(BuildContext context) {
    final current = _stage ? _first : _confirm;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('创建应用密码')),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Icon(
              _stage ? Icons.shield_outlined : Icons.check_circle_outline,
              size: 48,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            Text(
              _stage ? '请设置 6 位数字密码' : '请再次输入以确认',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _error ?? '密码用于保护您家人的隐私数据',
              style: TextStyle(
                fontSize: 13,
                color: _error == null ? AppColors.textHint : AppColors.red,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (i) {
                final filled = i < current.length;
                return Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? AppColors.primary : Colors.white,
                    border: Border.all(color: AppColors.primary, width: 1.4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  _row(['1', '2', '3']),
                  const SizedBox(height: 16),
                  _row(['4', '5', '6']),
                  const SizedBox(height: 16),
                  _row(['7', '8', '9']),
                  const SizedBox(height: 16),
                  _row(['', '0', '⌫']),
                ],
              ),
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Text(
                '提醒：密码仅保存在本机，忘记将无法找回。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textHint,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(List<String> labels) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: labels.map((l) {
        return SizedBox(
          width: 72,
          height: 72,
          child: Material(
            color: l.isEmpty ? Colors.transparent : AppColors.card,
            shape:
                const CircleBorder(side: BorderSide(color: AppColors.divider)),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: l.isEmpty
                  ? null
                  : () {
                      if (l == '⌫') {
                        _onDelete();
                      } else {
                        _onKey(l);
                      }
                    },
              child: Center(
                child: Text(
                  l,
                  style: TextStyle(
                    fontSize: l == '⌫' ? 22 : 24,
                    fontWeight: FontWeight.w600,
                    color: l.isEmpty ? Colors.transparent : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
