import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../data/models/family_member.dart';
import '../../data/models/insurance.dart';
import '../../providers/insurance_provider.dart';
import '../../providers/member_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/date_util.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/hidden_guard.dart';

class EmergencyCardPage extends StatefulWidget {
  const EmergencyCardPage({super.key});

  @override
  State<EmergencyCardPage> createState() => _EmergencyCardPageState();
}

class _EmergencyCardPageState extends State<EmergencyCardPage> {
  String? _memberId;
  final GlobalKey _cardKey = GlobalKey();
  bool _saving = false;

  FamilyMember? get _member {
    if (_memberId == null) return null;
    final list = context.read<MemberProvider>().all;
    for (final m in list) {
      if (m.id == _memberId) return m;
    }
    return null;
  }

  Future<void> _saveImage() async {
    if (_saving) return;
    final member = _member;
    if (member == null) return;
    setState(() => _saving = true);
    try {
      // 权限
      if (Platform.isAndroid) {
        await Permission.photos.request();
        await Permission.storage.request();
      }
      final boundary = _cardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('卡片尚未渲染，请稍后再试')),
          );
        }
        return;
      }
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      final result = await ImageGallerySaverPlus.saveImage(
        bytes,
        quality: 100,
        name: 'emergency_${member.name}_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (!mounted) return;
      if (result is Map && result['isSuccess'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已保存到相册，可在锁屏给医生查看')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存失败，请检查相册权限')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = context.watch<MemberProvider>().all;
    final insurances = context.watch<InsuranceProvider>().all;

    if (members.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('紧急医疗卡')),
        body: const EmptyState(
          icon: Icons.emergency_outlined,
          message: '请先添加家庭成员',
        ),
      );
    }

    final member = _member ?? members.first;
    if (_memberId == null) {
      // 首次进入默认选中第一个
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _memberId == null) {
          setState(() => _memberId = members.first.id);
        }
      });
    }

    final validInsurances = insurances
        .where((i) => i.memberId == member.id && i.status != '已失效')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('紧急医疗卡'),
        actions: [
          IconButton(
            tooltip: '保存到相册',
            icon: const Icon(Icons.save_alt),
            onPressed: member == null ? null : _saveImage,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.divider),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _memberId ?? members.first.id,
                items: members
                    .map((m) => DropdownMenuItem(
                          value: m.id,
                          child: Text(m.name),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _memberId = v);
                },
              ),
            ),
          ),
          RepaintBoundary(
            key: _cardKey,
            child: HiddenGuard(
              member: member,
              child: _EmergencyCard(
                member: member,
                insurances: validInsurances,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _saving ? null : _saveImage,
            icon: const Icon(Icons.image_outlined),
            label: const Text('一键保存为图片到相册'),
          ),
          const SizedBox(height: 8),
          const Text(
            '保存后可设为锁屏壁纸或发送给医生。\n本卡为纯本地生成，不会上传任何信息。',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textHint,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyCard extends StatelessWidget {
  const _EmergencyCard({required this.member, required this.insurances});
  final FamilyMember member;
  final List<Insurance> insurances;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.red, width: 1.4),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.red,
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                const Icon(Icons.emergency, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '紧急医疗卡',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  DateUtil.ymd(DateTime.now()),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _rowBig('姓名', member.name),
                _rowBig('年龄',
                    member.birthday == null ? '-' : '${member.age}岁'),
                _rowBig('血型',
                    member.bloodType.isEmpty ? '不详' : member.bloodType),
                if (member.allergy.isNotEmpty)
                  _rowBig('过敏史', member.allergy),
                if (member.chronicDisease.isNotEmpty)
                  _rowBig('既往病史', member.chronicDisease),
                if (insurances.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 8),
                  const Text(
                    '有效保险',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final i in insurances)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '· ${i.type}（${i.company.isEmpty ? "公司未填" : i.company}）',
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '本卡由家庭档案 App 生成 · 数据仅保存在本机',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowBig(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              k,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v.isEmpty ? '-' : v,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
