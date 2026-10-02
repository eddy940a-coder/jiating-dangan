import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/models/family_member.dart';
import '../data/models/insurance.dart';
import '../utils/date_util.dart';

/// 生成**结构化**的紧急医疗卡 PDF。
///
/// 与「截图存相册」的区别：PDF 里的文字是真正的文本，可被选中、复制、
/// 搜索，打印时也清晰，适合交给医生或随急救资料一起保存。
///
/// 中文字体随包内置（思源黑体，SIL OFL 授权），不依赖系统字体。
class PdfExportService {
  PdfExportService._();
  static final PdfExportService instance = PdfExportService._();

  // 注：pdf 包只支持 TrueType(glyf) 轮廓字体，思源黑体/Noto 是 CFF 轮廓会渲染失败。
  // 当前用等线(正文)+黑体(标题)做验证；如需合规分发，请替换为 OFL/开源授权的
  // TrueType 中文字体（如 Google Fonts 的 Noto Sans SC TTF、站酷系列等）放到这两个路径。
  static const String _regularAsset = 'assets/fonts/EnRegular.ttf';
  static const String _boldAsset = 'assets/fonts/EnBold.ttf';

  static final PdfColor _brandRed = PdfColor.fromHex('EF4444');
  static final PdfColor _textMain = PdfColor.fromHex('111827');
  static final PdfColor _textSub = PdfColor.fromHex('4B5563');
  static final PdfColor _lineColor = PdfColor.fromHex('E5E7EB');
  static final PdfColor _softBg = PdfColor.fromHex('F9FAFB');

  pw.Font? _regular;
  pw.Font? _bold;

  Future<void> _ensureFonts() async {
    if (_regular != null && _bold != null) return;
    final reg = await rootBundle.load(_regularAsset);
    final bold = await rootBundle.load(_boldAsset);
    _regular = pw.Font.ttf(reg);
    _bold = pw.Font.ttf(bold);
  }

  /// 生成紧急医疗卡 PDF 的字节内容。
  Future<Uint8List> buildEmergencyCard({
    required FamilyMember member,
    required List<Insurance> insurances,
  }) async {
    await _ensureFonts();

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: _regular!, bold: _bold!),
      title: '紧急医疗卡 - ${member.name}',
      author: '家庭档案',
    );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => _buildBody(member, insurances),
      ),
    );

    return doc.save();
  }

  /// 生成并落盘，返回 PDF 文件路径。
  Future<String> exportEmergencyCard({
    required FamilyMember member,
    required List<Insurance> insurances,
  }) async {
    final bytes = await buildEmergencyCard(
      member: member,
      insurances: insurances,
    );

    final dir = await getApplicationDocumentsDirectory();
    final expDir = Directory(p.join(dir.path, 'exports'));
    if (!await expDir.exists()) await expDir.create(recursive: true);

    final ts = _timestamp(DateTime.now());
    final safeName = member.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '');
    final file = File(p.join(expDir.path, '紧急医疗卡_${safeName}_$ts.pdf'));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  // ---------- 排版 ----------

  pw.Widget _buildBody(FamilyMember m, List<Insurance> insurances) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _header(m),
        pw.SizedBox(height: 16),
        _sectionTitle('基本信息'),
        _infoGrid(m),
        pw.SizedBox(height: 14),
        _sectionTitle('过敏史'),
        _alertBlock(
          m.allergy.isEmpty ? '未填写' : m.allergy,
          empty: m.allergy.isEmpty,
        ),
        pw.SizedBox(height: 14),
        _sectionTitle('既往病史 / 基础疾病'),
        _block(m.chronicDisease.isEmpty
            ? '未填写'
            : m.chronicDisease),
        if (insurances.isNotEmpty) ...[
          pw.SizedBox(height: 14),
          _sectionTitle('有效保险'),
          _insuranceTable(insurances),
        ],
        pw.Spacer(),
        pw.SizedBox(height: 16),
        _footer(),
      ],
    );
  }

  pw.Widget _header(FamilyMember m) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: pw.BoxDecoration(
        color: _brandRed,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '紧急医疗卡',
                  style: pw.TextStyle(
                    font: _bold,
                    fontSize: 20,
                    color: PdfColors.white,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '${m.name} · ${m.relation} · 生成于 ${DateUtil.ymd(DateTime.now())}',
                  style: pw.TextStyle(
                    font: _regular,
                    fontSize: 11,
                    color: PdfColors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _sectionTitle(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        children: [
          pw.Container(
            width: 3,
            height: 13,
            color: _brandRed,
          ),
          pw.SizedBox(width: 6),
          pw.Text(
            text,
            style: pw.TextStyle(
              font: _bold,
              fontSize: 13,
              color: _textMain,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _infoGrid(FamilyMember m) {
    final items = <List<String>>[
      ['姓名', m.name],
      ['与本人关系', m.relation],
      ['年龄', m.birthday == null ? '未填写' : '${m.age} 岁'],
      ['出生日期', DateUtil.ymd(m.birthday)],
      ['血型', m.bloodType.isEmpty ? '不详' : m.bloodType],
      ['身份证号', _maskIdCard(m.idCard)],
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: _lineColor, width: 0.6),
      columnWidths: {
        0: const pw.FlexColumnWidth(2.2),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(2.2),
        3: const pw.FlexColumnWidth(3),
      },
      children: [
        for (var i = 0; i < items.length; i += 2)
          pw.TableRow(
            children: [
              _cell(items[i][0], isLabel: true),
              _cell(items[i][1]),
              if (i + 1 < items.length) _cell(items[i + 1][0], isLabel: true),
              if (i + 1 < items.length) _cell(items[i + 1][1]),
            ],
          ),
      ],
    );
  }

  pw.Widget _cell(String text, {bool isLabel = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      color: isLabel ? _softBg : null,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: isLabel ? _regular : _regular,
          fontSize: 11,
          color: isLabel ? _textSub : _textMain,
        ),
      ),
    );
  }

  /// 过敏史用醒目的红框，急救场景下第一眼看到
  pw.Widget _alertBlock(String text, {bool empty = false}) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: empty ? _softBg : PdfColor.fromHex('FEF2F2'),
        border: pw.Border.all(
          color: empty ? _lineColor : _brandRed,
          width: 0.9,
        ),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: _regular,
          fontSize: 12,
          color: empty ? _textSub : _textMain,
          lineSpacing: 2,
        ),
      ),
    );
  }

  pw.Widget _block(String text) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _softBg,
        border: pw.Border.all(color: _lineColor, width: 0.6),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: _regular,
          fontSize: 12,
          color: _textMain,
          lineSpacing: 2,
        ),
      ),
    );
  }

  pw.Widget _insuranceTable(List<Insurance> list) {
    return pw.Table(
      border: pw.TableBorder.all(color: _lineColor, width: 0.6),
      columnWidths: {
        0: const pw.FlexColumnWidth(2.4),
        1: const pw.FlexColumnWidth(2.6),
        2: const pw.FlexColumnWidth(3),
        3: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _softBg),
          children: [
            _cell('险种', isLabel: true),
            _cell('保险公司', isLabel: true),
            _cell('保单号', isLabel: true),
            _cell('到期日', isLabel: true),
          ],
        ),
        for (final i in list)
          pw.TableRow(
            children: [
              _cell(i.type),
              _cell(i.company.isEmpty ? '-' : i.company),
              _cell(i.policyNo.isEmpty ? '-' : i.policyNo),
              _cell(DateUtil.ymd(i.expireDate)),
            ],
          ),
      ],
    );
  }

  pw.Widget _footer() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _lineColor, width: 0.6)),
      ),
      child: pw.Text(
        '本卡片由「家庭档案」App 生成，所有数据仅保存在本机，未上传任何服务器。'
        '信息以实际就诊资料为准，仅供参考。',
        style: pw.TextStyle(
          font: _regular,
          fontSize: 9,
          color: _textSub,
          lineSpacing: 2,
        ),
      ),
    );
  }

  // ---------- 工具 ----------

  /// 身份证号脱敏：保留前 6 位与后 4 位
  static String _maskIdCard(String id) {
    final s = id.trim();
    if (s.isEmpty) return '未填写';
    if (s.length <= 10) return s;
    return '${s.substring(0, 6)}****${s.substring(s.length - 4)}';
  }

  static String _timestamp(DateTime d) {
    String t(int v) => v.toString().padLeft(2, '0');
    return '${d.year}${t(d.month)}${t(d.day)}_${t(d.hour)}${t(d.minute)}';
  }
}
