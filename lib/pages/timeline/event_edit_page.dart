import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/family_event.dart';
import '../../providers/event_provider.dart';
import '../../providers/member_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/id_util.dart';
import '../../widgets/attachment_field.dart';
import '../../widgets/form_widgets.dart';

class EventEditPage extends StatefulWidget {
  const EventEditPage({super.key, this.event});
  final FamilyEvent? event;

  @override
  State<EventEditPage> createState() => _EventEditPageState();
}

class _EventEditPageState extends State<EventEditPage> {
  late TextEditingController _title;
  late TextEditingController _description;
  DateTime _eventTime = DateTime.now();
  String _category = manualEventCategories.first;
  List<String> _memberIds = <String>[];
  List<String> _attachments = <String>[];

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    _title = TextEditingController(text: e?.title ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _eventTime = e?.eventTime ?? DateTime.now();
    _category = e?.category ?? manualEventCategories.first;
    _memberIds = List<String>.from(e?.memberIds ?? const <String>[]);
    _attachments = List<String>.from(e?.attachments ?? const <String>[]);
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写事件标题')),
      );
      return;
    }
    final p = context.read<EventProvider>();
    final now = DateTime.now();
    if (widget.event == null) {
      final e = FamilyEvent(
        id: IdUtil.newId(),
        memberIds: _memberIds,
        eventTime: _eventTime,
        category: _category,
        type: kEventTypeManual,
        title: _title.text.trim(),
        description: _description.text.trim(),
        attachments: _attachments,
        createdAt: now,
        updatedAt: now,
      );
      await p.upsert(e);
    } else {
      final updated = widget.event!.copyWith(
        memberIds: _memberIds,
        eventTime: _eventTime,
        category: _category,
        title: _title.text.trim(),
        description: _description.text.trim(),
        attachments: _attachments,
        updatedAt: now,
      );
      await p.upsert(updated);
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final members = context.watch<MemberProvider>().all;
    final isEdit = widget.event != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? '编辑事件' : '新增家庭事件'),
        actions: [TextButton(onPressed: _save, child: const Text('保存'))],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const SectionTitleInline('关联成员（可多选）'),
          if (members.isEmpty)
            const NoMemberHint(
              text: '还没有家庭成员，可先到「首页 → 家庭成员」添加；事件也可以暂不关联成员。',
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: members.map((m) {
              final selected = _memberIds.contains(m.id);
              return FilterChip(
                label: Text(m.name),
                selected: selected,
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      _memberIds.add(m.id);
                    } else {
                      _memberIds.remove(m.id);
                    }
                  });
                },
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.card,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                side: BorderSide(
                    color: selected ? AppColors.primary : AppColors.divider),
              );
            }).toList(),
          ),
          FormDateField(
            label: '事件时间',
            value: _eventTime,
            onChanged: (d) => setState(() => _eventTime = d ?? _eventTime),
          ),
          FormDropdown<String>(
            label: '事件分类',
            value: _category,
            items: manualEventCategories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _category = v ?? _category),
          ),
          LabeledField(
            label: '标题',
            required: true,
            child: TextField(
              controller: _title,
              decoration: const InputDecoration(hintText: '一句话描述'),
            ),
          ),
          LabeledField(
            label: '详情',
            child: TextField(
              controller: _description,
              maxLines: 4,
              decoration: const InputDecoration(hintText: '详细描述'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: AttachmentField(
              value: _attachments,
              onChanged: (v) => setState(() => _attachments = v),
            ),
          ),
        ],
      ),
    );
  }
}

class SectionTitleInline extends StatelessWidget {
  const SectionTitleInline(this.title, {super.key});
  final String title;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
