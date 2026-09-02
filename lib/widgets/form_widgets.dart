import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 通用标签 + 内容卡片（用作文案区）
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.child,
    this.hint,
    this.required = false,
  });

  final String label;
  final Widget child;
  final String? hint;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (required)
                const Text(' *',
                    style: TextStyle(color: AppColors.red, fontSize: 14)),
              if (hint != null) ...[
                const SizedBox(width: 8),
                Text(
                  hint!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class FormDropdown<T> extends StatelessWidget {
  const FormDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint = '请选择',
    this.required = false,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String hint;
  final bool required;

  @override
  Widget build(BuildContext context) {
    // 候选项为空、或 value 已不在候选项中时，DropdownButtonFormField 会直接
    // 断言失败导致页面红屏，这里回退成 null，保证页面仍能正常打开。
    final effectiveValue = items.any((item) => item.value == value) ? value : null;
    return LabeledField(
      label: label,
      required: required,
      child: DropdownButtonFormField<T>(
        // Flutter 3.33 起 `value` 已废弃，改用 initialValue；
        // 组件在 initialValue 变化时会自动 setValue，外部 setState 同样生效。
        initialValue: effectiveValue,
        isExpanded: true,
        decoration: InputDecoration(hintText: hint),
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}

/// 还没有家庭成员时的引导提示，避免用户面对一个空下拉框不知所措。
class NoMemberHint extends StatelessWidget {
  const NoMemberHint({
    super.key,
    this.text = '还没有家庭成员，请先到「首页 → 家庭成员」添加成员后再录入。',
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class FormDateField extends StatelessWidget {
  const FormDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint = '点击选择',
    this.clearable = false,
    this.onClear,
    this.firstDate,
    this.lastDate,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final String hint;
  final bool clearable;
  final VoidCallback? onClear;
  final DateTime? firstDate;
  final DateTime? lastDate;

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return LabeledField(
      label: label,
      child: InkWell(
        onTap: () async {
          final now = DateTime.now();
          final init = value ?? now;
          final picked = await showDatePicker(
            context: context,
            initialDate: init,
            firstDate: firstDate ?? DateTime(1900),
            lastDate: lastDate ?? DateTime(now.year + 50),
          );
          if (picked != null) onChanged(picked);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value == null ? hint : _fmt(value!),
                  style: TextStyle(
                    fontSize: 16,
                    color: value == null
                        ? AppColors.textHint
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              if (clearable && value != null)
                GestureDetector(
                  onTap: () {
                    onChanged(null);
                    onClear?.call();
                  },
                  child: const Icon(Icons.close,
                      size: 18, color: AppColors.textHint),
                )
              else
                const Icon(Icons.calendar_today_outlined,
                    size: 18, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}
