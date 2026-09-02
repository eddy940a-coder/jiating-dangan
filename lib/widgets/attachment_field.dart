import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../services/attachment_service.dart';
import '../theme/app_colors.dart';

/// 通用附件上传/预览组件（图片 + PDF）。
class AttachmentField extends StatefulWidget {
  const AttachmentField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = '附件',
  });

  final List<String> value;
  final ValueChanged<List<String>> onChanged;
  final String label;

  @override
  State<AttachmentField> createState() => _AttachmentFieldState();
}

class _AttachmentFieldState extends State<AttachmentField> {
  bool _picking = false;

  bool _isImage(String name) {
    final lower = name.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.heic') ||
        lower.endsWith('.webp');
  }

  Future<void> _pick() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final res = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'heic', 'webp', 'pdf'],
      );
      if (res == null) return;
      final list = <String>[];
      for (final f in res.files) {
        if (f.path == null) continue;
        final name = await AttachmentService.instance.savePickedFile(f.path!);
        list.add(name);
      }
      widget.onChanged([...widget.value, ...list]);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _preview(String name) async {
    final path = await AttachmentService.instance.resolve(name);
    if (_isImage(name)) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => _ImagePreviewDialog(path: path, name: name),
      );
    } else {
      await OpenFilex.open(path);
    }
  }

  void _remove(String name) async {
    widget.onChanged(widget.value.where((n) => n != name).toList());
    try {
      await AttachmentService.instance.delete(name);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _picking ? null : _pick,
              icon: const Icon(Icons.upload_file_outlined, size: 18),
              label: const Text('上传'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (widget.value.isEmpty)
          const Text(
            '支持 jpg / png / pdf',
            style: TextStyle(fontSize: 13, color: AppColors.textHint),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.value.map((n) {
              return _AttachmentTile(
                name: n,
                isImage: _isImage(n),
                onTap: () => _preview(n),
                onRemove: () => _remove(n),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({
    required this.name,
    required this.isImage,
    required this.onTap,
    required this.onRemove,
  });

  final String name;
  final bool isImage;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        children: [
          Positioned.fill(
            child: Material(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: onTap,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: isImage
                      ? FutureBuilder<String>(
                          future: AttachmentService.instance.resolve(name),
                          builder: (context, snap) {
                            if (!snap.hasData) {
                              return const Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                ),
                              );
                            }
                            return Image.file(
                              File(snap.data!),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.broken_image_outlined,
                                    color: AppColors.textHint),
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.picture_as_pdf,
                                  color: AppColors.red, size: 28),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4),
                                child: Text(
                                  name.length > 14
                                      ? '${name.substring(0, 14)}…'
                                      : name,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePreviewDialog extends StatelessWidget {
  const _ImagePreviewDialog({required this.path, required this.name});
  final String path;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(8),
      backgroundColor: Colors.black,
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: SizedBox(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.8,
          child: InteractiveViewer(
            child: Center(
              child: Image.file(
                File(path),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '无法打开：$name',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
