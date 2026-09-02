import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';

import '../../data/models/family_event.dart';
import '../../data/models/family_member.dart';
import '../../providers/event_provider.dart';
import '../../providers/member_provider.dart';
import '../../services/attachment_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/date_util.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import 'event_edit_page.dart';

class TimelinePage extends StatefulWidget {
  const TimelinePage({super.key});

  @override
  State<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage> {
  String? _memberId;
  String _type = 'all';

  @override
  Widget build(BuildContext context) {
    final events = context.watch<EventProvider>().all;
    final members = context.watch<MemberProvider>().all;

    final filtered = events.where((e) {
      if (_memberId != null && !e.memberIds.contains(_memberId)) return false;
      if (_type != 'all' && e.type != _type) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.eventTime.compareTo(a.eventTime));

    return Scaffold(
      appBar: AppBar(
        title: const Text('家庭大事件'),
      ),
      body: Column(
        children: [
          _Filter(
            members: members,
            memberId: _memberId,
            type: _type,
            onMemberChange: (v) => setState(() => _memberId = v),
            onTypeChange: (v) => setState(() => _type = v),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const EmptyState(
                    icon: Icons.timeline_outlined,
                    message: '暂无家庭事件\n记录保单/病历会自动生成',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 88),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _TimelineItem(
                      event: filtered[i],
                      members: members,
                      isFirst: i == 0,
                      isLast: i == filtered.length - 1,
                      onTap: () => _openEvent(filtered[i]),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const EventEditPage()),
        ),
        backgroundColor: AppColors.yellow,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('新增事件', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Future<void> _openEvent(FamilyEvent e) async {
    if (e.relatedId != null) {
      // 自动事件只读：提示
      await showModalBottomSheet<void>(
        context: context,
        builder: (_) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.title,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text('该事件由保单/病历自动生成，如需修改请前往对应记录。',
                    style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('知道了'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => EventEditPage(event: e)),
      );
    }
  }
}

class _Filter extends StatelessWidget {
  const _Filter({
    required this.members,
    required this.memberId,
    required this.type,
    required this.onMemberChange,
    required this.onTypeChange,
  });

  final List<FamilyMember> members;
  final String? memberId;
  final String type;
  final ValueChanged<String?> onMemberChange;
  final ValueChanged<String> onTypeChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline,
                  size: 18, color: AppColors.textHint),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    isExpanded: true,
                    value: memberId,
                    hint: const Text('全部成员'),
                    items: <DropdownMenuItem<String?>>[
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('全部成员'),
                      ),
                      for (final m in members)
                        DropdownMenuItem<String?>(
                          value: m.id,
                          child: Text(m.name),
                        ),
                    ],
                    onChanged: onMemberChange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _typeChip('all', '全部'),
                _typeChip(kEventTypeInsurance, '保险'),
                _typeChip(kEventTypeMedical, '就医'),
                _typeChip(kEventTypeManual, '家庭'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeChip(String value, String label) {
    final selected = value == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTypeChange(value),
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.card,
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        side:
            BorderSide(color: selected ? AppColors.primary : AppColors.divider),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.event,
    required this.members,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  final FamilyEvent event;
  final List<FamilyMember> members;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  Color get _color {
    switch (event.type) {
      case kEventTypeInsurance:
        return AppColors.eventInsurance;
      case kEventTypeMedical:
        return AppColors.eventMedical;
      default:
        return AppColors.eventManual;
    }
  }

  String _name(String id) {
    for (final m in members) {
      if (m.id == id) return m.name;
    }
    return '未知';
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 48,
            child: Stack(
              children: [
                if (!isLast)
                  Positioned(
                    top: 18,
                    left: 23,
                    bottom: 0,
                    child: Container(
                      width: 2,
                      color: AppColors.divider,
                    ),
                  ),
                Positioned(
                  top: 12,
                  left: 16,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _color,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 4, 8, 12),
              child: Material(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              DateUtil.ymd(event.eventTime),
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textHint,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: _color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                eventTypeLabel(event.type),
                                style: TextStyle(
                                  color: _color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (event.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            event.description,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (event.memberIds.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            '关联：${event.memberIds.map(_name).join("、")}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                        if (event.attachments.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: _AttachmentRow(
                              names: event.attachments,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentRow extends StatelessWidget {
  const _AttachmentRow({required this.names});
  final List<String> names;

  bool _isImage(String n) {
    final l = n.toLowerCase();
    return l.endsWith('.jpg') ||
        l.endsWith('.jpeg') ||
        l.endsWith('.png') ||
        l.endsWith('.heic') ||
        l.endsWith('.webp');
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: names.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final n = names[i];
          if (_isImage(n)) {
            return GestureDetector(
              onTap: () async {
                final p = await AttachmentService.instance.resolve(n);
                if (!context.mounted) return;
                await showDialog<void>(
                  context: context,
                  builder: (_) => Dialog(
                    insetPadding: const EdgeInsets.all(8),
                    backgroundColor: Colors.black,
                    child: SizedBox(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height * 0.8,
                      child: InteractiveViewer(
                        child: Center(child: Image.file(File(p))),
                      ),
                    ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: FutureBuilder<String>(
                  future: AttachmentService.instance.resolve(n),
                  builder: (_, snap) {
                    if (!snap.hasData) {
                      return Container(
                        width: 64,
                        height: 64,
                        color: AppColors.divider,
                      );
                    }
                    return Image.file(
                      File(snap.data!),
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),
            );
          } else {
            return GestureDetector(
              onTap: () async {
                final p = await AttachmentService.instance.resolve(n);
                await OpenFilex.open(p);
              },
              child: Container(
                width: 96,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.divider),
                ),
                child: const Center(
                  child: Icon(Icons.picture_as_pdf,
                      color: AppColors.red, size: 22),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
