import 'dart:io';

import 'package:flutter/material.dart';

import '../data/models/family_member.dart';
import '../services/attachment_service.dart';
import '../theme/app_colors.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.member,
    this.size = 48,
  });

  final FamilyMember member;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hasAvatar =
        member.avatarPath != null && member.avatarPath!.isNotEmpty;
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _colorFor(member.name),
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: hasAvatar
          ? _AvatarImage(name: member.avatarPath!, size: size)
          : _initial(member, size),
    );
  }

  Widget _initial(FamilyMember m, double size) {
    final s = m.name.isEmpty ? '?' : m.name.characters.first;
    return Center(
      child: Text(
        s,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.42,
        ),
      ),
    );
  }

  static Color _colorFor(String name) {
    const palette = <Color>[
      AppColors.primary,
      AppColors.orange,
      Color(0xFF14B8A6),
      Color(0xFFA855F7),
      Color(0xFFEC4899),
      Color(0xFF0EA5E9),
      Color(0xFF10B981),
    ];
    if (name.isEmpty) return palette.first;
    final h = name.codeUnits.fold<int>(0, (a, b) => (a + b) & 0xffff);
    return palette[h % palette.length];
  }
}

class _AvatarImage extends StatelessWidget {
  const _AvatarImage({required this.name, required this.size});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: AttachmentService.instance.resolve(name),
      builder: (context, snap) {
        if (!snap.hasData) {
          return SizedBox(
            width: size,
            height: size,
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final file = File(snap.data!);
        return Image.file(
          file,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        );
      },
    );
  }
}
