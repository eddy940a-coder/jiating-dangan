import 'package:flutter/material.dart';

import '../../services/ocr_parser.dart';
import '../../services/ocr_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/form_widgets.dart';

/// OCR 适用的目标单据
enum OcrTarget { medical, insurance }

/// 一个可编辑的识别字段
class OcrFieldSpec {
  const OcrFieldSpec(this.key, this.label, {this.maxLines = 1});

  final String key;
  final String label;
  final int maxLines;
}

const List<OcrFieldSpec> ocrMedicalFields = <OcrFieldSpec>[
  OcrFieldSpec('hospital', '医院'),
  OcrFieldSpec('department', '科室'),
  OcrFieldSpec('doctor', '医生'),
  OcrFieldSpec('visitTime', '就诊日期'),
  OcrFieldSpec('diagnosis', '诊断结果', maxLines: 3),
  OcrFieldSpec('complaint', '主诉', maxLines: 2),
  OcrFieldSpec('medication', '用药记录', maxLines: 3),
];

const List<OcrFieldSpec> ocrInsuranceFields = <OcrFieldSpec>[
  OcrFieldSpec('company', '保险公司'),
  OcrFieldSpec('policyNo', '保单号'),
  OcrFieldSpec('type', '险种'),
  OcrFieldSpec('holder', '投保人'),
  OcrFieldSpec('insured', '被保人'),
  OcrFieldSpec('beneficiary', '受益人'),
  OcrFieldSpec('premium', '保费'),
  OcrFieldSpec('effectiveDate', '生效日期'),
  OcrFieldSpec('expireDate', '到期日期'),
];

List<OcrFieldSpec> ocrFieldsOf(OcrTarget target) =>
    target == OcrTarget.medical ? ocrMedicalFields : ocrInsuranceFields;

/// 一键 OCR 录入入口：
/// 选图 → 本地识别 → 解析 → 用户核对 → 返回确认后的字段。
///
/// 识别结果永远不直接落库，必须由用户在这里核对后点「确认填入」。
class OcrScan {
  OcrScan._();

  static Future<Map<String, String>?> run(
    BuildContext context,
    OcrTarget target,
  ) async {
    final fromCamera = await _askSource(context);
    if (fromCamera == null) return null;
    if (!context.mounted) return null;

    final path = await OcrService.instance.pickImage(fromCamera: fromCamera);
    if (path == null || path.isEmpty) return null;
    if (!context.mounted) return null;

    // 用 final + 确定性赋值，保证后续使用时一定非空
    final String text;
    try {
      text = await _withLoading(
        context,
        () => OcrService.instance.recognize(path),
      );
    } on OcrException catch (e) {
      if (context.mounted) _showError(context, e.message);
      return null;
    } catch (e) {
      if (context.mounted) {
        _showError(context, '识别失败：$e\n你也可以退出后手动录入。');
      }
      return null;
    }
    if (!context.mounted) return null;

    if (text.trim().isEmpty) {
      _showError(
        context,
        '没有在这张图片里识别到文字。\n建议正对单据、避免反光与阴影，或换一张更清晰的照片。',
      );
      return null;
    }

    final parsed = target == OcrTarget.medical
        ? OcrParser.parseMedical(text)
        : OcrParser.parseInsurance(text);

    return Navigator.of(context).push<Map<String, String>>(
      MaterialPageRoute<Map<String, String>>(
        builder: (_) => OcrReviewPage(
          target: target,
          rawText: text,
          parsed: parsed,
        ),
      ),
    );
  }

  static Future<bool?> _askSource(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '识别单据',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined,
                    color: AppColors.primary),
                title: const Text('拍照识别'),
                subtitle: const Text('正对单据，尽量拍清楚文字'),
                onTap: () => Navigator.of(ctx).pop(true),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: AppColors.primary),
                title: const Text('从相册选择'),
                subtitle: const Text('选择已拍好的单据照片'),
                onTap: () => Navigator.of(ctx).pop(false),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  static Future<T> _withLoading<T>(
    BuildContext context,
    Future<T> Function() task,
  ) async {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        barrierDismissible: false,
        opaque: false,
        pageBuilder: (_, __, ___) => const _LoadingLayer(text: '正在识别文字…'),
      ),
    );
    try {
      return await task();
    } finally {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 5)),
    );
  }
}

/// 识别结果核对页
class OcrReviewPage extends StatefulWidget {
  const OcrReviewPage({
    super.key,
    required this.target,
    required this.rawText,
    required this.parsed,
  });

  final OcrTarget target;
  final String rawText;
  final Map<String, String> parsed;

  @override
  State<OcrReviewPage> createState() => _OcrReviewPageState();
}

class _OcrReviewPageState extends State<OcrReviewPage> {
  final Map<String, TextEditingController> _ctrls = {};
  bool _showRaw = false;

  @override
  void initState() {
    super.initState();
    for (final f in ocrFieldsOf(widget.target)) {
      _ctrls[f.key] =
          TextEditingController(text: widget.parsed[f.key] ?? '');
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _confirm() {
    final out = <String, String>{};
    for (final f in ocrFieldsOf(widget.target)) {
      final v = (_ctrls[f.key]?.text ?? '').trim();
      if (v.isNotEmpty) out[f.key] = v;
    }
    Navigator.of(context).pop(out);
  }

  @override
  Widget build(BuildContext context) {
    final fields = ocrFieldsOf(widget.target);
    final hitCount = fields
        .where((f) => (widget.parsed[f.key] ?? '').isNotEmpty)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('核对识别结果'),
        actions: [
          TextButton(onPressed: _confirm, child: const Text('确认填入')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hitCount == 0
                        ? '没能自动识别出字段，请手动填写下面的内容，'
                            '或返回后手动录入。'
                        : '已识别出 $hitCount 个字段，请核对后再填入。'
                            '识别仅供参考，务必以单据原件为准。',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          for (final f in fields)
            LabeledField(
              label: f.label,
              child: TextField(
                controller: _ctrls[f.key],
                maxLines: f.maxLines,
                decoration: InputDecoration(
                  hintText: (widget.parsed[f.key] ?? '').isEmpty
                      ? '未识别到，可手动补充'
                      : '',
                ),
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => setState(() => _showRaw = !_showRaw),
            icon: Icon(_showRaw ? Icons.expand_less : Icons.expand_more),
            label: Text(_showRaw ? '收起识别原文' : '查看识别原文'),
          ),
          if (_showRaw) ...[
            const SizedBox(height: 8),
            AppCard(
              child: SelectableText(
                widget.rawText,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LoadingLayer extends StatelessWidget {
  const _LoadingLayer({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Container(
        color: Colors.black38,
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 14),
              Text(text, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
