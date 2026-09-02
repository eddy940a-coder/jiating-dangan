import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_settings_provider.dart';
import '../../services/biometric_service.dart';
import '../../theme/app_colors.dart';

class LockPage extends StatefulWidget {
  const LockPage({super.key, required this.onUnlocked});

  final VoidCallback onUnlocked;

  @override
  State<LockPage> createState() => _LockPageState();
}

class _LockPageState extends State<LockPage>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  late final AnimationController _shake;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  Future<void> _tryBiometric() async {
    final settings = context.read<AppSettingsProvider>();
    if (!settings.biometricEnabled) return;
    final ok = await BiometricService.instance.authenticate();
    if (ok && mounted) widget.onUnlocked();
  }

  Future<void> _onKey(String v) async {
    if (_busy) return;
    if (_pin.length >= 6) return;
    setState(() {
      _pin = _pin + v;
      _error = null;
    });
    if (_pin.length == 6) {
      await _verify();
    }
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  Future<void> _verify() async {
    setState(() => _busy = true);
    final ok = await context.read<AppSettingsProvider>().verifyPassword(_pin);
    if (!mounted) return;
    if (ok) {
      widget.onUnlocked();
    } else {
      _shake.forward(from: 0);
      setState(() {
        _pin = '';
        _busy = false;
        _error = '密码错误，请重新输入';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),
            const Icon(Icons.lock_outline,
                size: 48, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text(
              '请输入应用密码',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '6 位数字密码',
              style: TextStyle(
                fontSize: 14,
                color: _error == null ? AppColors.textHint : AppColors.red,
              ),
            ),
            const SizedBox(height: 24),
            AnimatedBuilder(
              animation: _shake,
              builder: (context, child) {
                final t = _shake.value;
                final dx = t == 0
                    ? 0.0
                    : 12 *
                        (1 - t) *
                        ((t * 6 * 3.1415).remainder(2) > 3.1415 ? -1 : 1);
                return Transform.translate(
                  offset: Offset(dx, 0),
                  child: child,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  final filled = i < _pin.length;
                  return Container(
                    width: 14,
                    height: 14,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? AppColors.primary : Colors.white,
                      border:
                          Border.all(color: AppColors.primary, width: 1.4),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 32),
            _Keypad(
              onKey: _onKey,
              onDelete: _onDelete,
              onBiometric: () async {
                final ok = await BiometricService.instance.authenticate();
                if (ok && mounted) widget.onUnlocked();
              },
              biometricEnabled:
                  context.watch<AppSettingsProvider>().biometricEnabled,
            ),
            const SizedBox(height: 16),
            const Text(
              '忘记密码？本 App 数据全部保存在本机，密码无法找回。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textHint,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.onKey,
    required this.onDelete,
    required this.onBiometric,
    required this.biometricEnabled,
  });

  final ValueChanged<String> onKey;
  final VoidCallback onDelete;
  final VoidCallback onBiometric;
  final bool biometricEnabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          _row(['1', '2', '3']),
          const SizedBox(height: 16),
          _row(['4', '5', '6']),
          const SizedBox(height: 16),
          _row(['7', '8', '9']),
          const SizedBox(height: 16),
          _row([biometricEnabled ? '指纹' : '', '0', '⌫']),
        ],
      ),
    );
  }

  Widget _row(List<String> labels) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: labels.map((l) => _KeyButton(label: l, onTap: () {
        if (l == '⌫') return onDelete();
        if (l == '指纹') return onBiometric();
        if (l.isEmpty) return null;
        return onKey(l);
      })).toList(),
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final empty = label.isEmpty;
    return SizedBox(
      width: 72,
      height: 72,
      child: Material(
        color: empty ? Colors.transparent : AppColors.card,
        shape: const CircleBorder(side: BorderSide(color: AppColors.divider)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: empty ? null : onTap,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: label == '⌫' ? 22 : 24,
                color: empty
                    ? Colors.transparent
                    : (label == '指纹'
                        ? AppColors.primary
                        : AppColors.textPrimary),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
