import '../data/models/insurance.dart';
import '../data/models/medical_record.dart';

/// 从 OCR 文本里提取病历字段。
///
/// 单据版式千差万别，这里做的是「尽力而为」的抽取：
/// 命中就填表单，没命中就留空让用户手动补。识别结果一律不直接落库，
/// 必须经用户确认。
class OcrParser {
  OcrParser._();

  /// 病历 / 诊断证明 / 检查报告
  static Map<String, String> parseMedical(String text) {
    final lines = _lines(text);
    final out = <String, String>{};

    _put(out, 'hospital', _firstMatchByLine(lines, _kHospital));
    _put(out, 'department', _kv(lines, ['科室', '就诊科室', '科别']));
    _put(out, 'department', _firstMatchByLine(lines, _kDepartment));
    _put(out, 'doctor', _kv(lines, ['医生', '医师', '主治医生', '接诊医生']));

    final visitTime = _firstDate(text);
    if (visitTime != null) {
      _put(out, 'visitTime', _fmtDate(visitTime));
    }

    _put(out, 'diagnosis', _kv(lines, ['诊断', '初步诊断', '临床诊断', '诊断结果']));
    _put(out, 'complaint', _kv(lines, ['主诉', '症状']));
    _put(out, 'medication', _kv(lines, ['用药', '处方', '用法用量']));

    // 诊断经常是多行文本，抽取其后几行非键值对内容
    if ((out['diagnosis'] ?? '').isEmpty) {
      _put(out, 'diagnosis', _multilineAfter(lines, ['诊断', '初步诊断', '临床诊断']));
    }

    return out;
  }

  /// 保单 / 投保单
  static Map<String, String> parseInsurance(String text) {
    final lines = _lines(text);
    final out = <String, String>{};

    _put(out, 'company', _firstMatchByLine(lines, _kCompany));
    _put(out, 'policyNo', _kv(lines, ['保单号', '保单编号', '合同号', '保单号码']));
    if ((out['policyNo'] ?? '').isEmpty) {
      _put(out, 'policyNo', _policyNoGuess(text));
    }
    _put(out, 'type', _kv(lines, ['险种', '保险险种', '产品', '保险产品']));
    if ((out['type'] ?? '').isEmpty) {
      _put(out, 'type', _firstMatchByLine(lines, _kInsuranceType));
    }
    _put(out, 'holder', _kv(lines, ['投保人', '投保人姓名']));
    _put(out, 'insured', _kv(lines, ['被保险人', '被保人']));
    _put(out, 'beneficiary', _kv(lines, ['受益人']));

    final premium = _firstAmount(text, ['保险费', '保费', '应缴保费', '金额']);
    if (premium != null) _put(out, 'premium', premium);

    final dates = _allDates(text);
    if (dates.isNotEmpty) {
      _put(out, 'effectiveDate', _fmtDate(dates.first));
      if (dates.length > 1) _put(out, 'expireDate', _fmtDate(dates.last));
    }

    return out;
  }

  /// 把解析结果套用到已有就诊类型列表（命中则使用列表里的标准值）
  static String? matchVisitType(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final t in medicalVisitTypes) {
      if (value.contains(t)) return t;
    }
    return null;
  }

  static String? matchInsuranceType(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final t in insuranceTypes) {
      if (value.contains(t)) return t;
    }
    return null;
  }

  // ---------- 内部工具 ----------

  static final RegExp _kHospital =
      RegExp(r'[\u4e00-\u9fa5]{2,20}(?:医院|人民医院|中医院|妇幼|卫生院|诊所|中心)');
  static final RegExp _kDepartment =
      RegExp(r'[\u4e00-\u9fa5]{2,8}(?:内科|外科|儿科|妇科|产科|骨科|眼科|耳鼻喉科|口腔科|皮肤科|神经科|心内科|急诊科|中医科|全科)');
  static final RegExp _kCompany =
      RegExp(r'[\u4e00-\u9fa5]{2,20}(?:保险股份有限公司|人寿保险|财产保险|保险有限公司|保险公司)');
  static final RegExp _kInsuranceType =
      RegExp(r'[\u4e00-\u9fa5]{2,12}(?:险|保险)');

  static final RegExp _dateRe = RegExp(
    r'(20\d{2})\s*[-/年.]\s*(\d{1,2})\s*[-/月.]\s*(\d{1,2})',
  );

  static final RegExp _amountRe =
      RegExp(r'(?:[¥￥]?\s*)(\d+(?:\.\d{1,2})?)\s*(?:元|圆)?');

  static List<String> _lines(String text) {
    return text
        .split(RegExp(r'\r?\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static void _put(Map<String, String> out, String key, String? value) {
    if (value == null) return;
    final v = value.trim();
    if (v.isEmpty) return;
    // 已有值时不覆盖（先命中的规则更可信）
    if ((out[key] ?? '').isNotEmpty) return;
    out[key] = v;
  }

  /// 提取 `键：值` 形式，支持中文冒号与连续空格
  static String? _kv(List<String> lines, List<String> keys) {
    for (final line in lines) {
      for (final k in keys) {
        final idx = line.indexOf(k);
        if (idx < 0) continue;
        var rest = line.substring(idx + k.length);
        rest = rest.replaceFirst(RegExp(r'^\s*[:： ]+'), '');
        rest = rest.trim();
        if (rest.isEmpty) continue;
        // 去掉后面跟着的另一个键（同一行多个字段的情况）
        rest = rest.split(RegExp(r'\s{2,}|[\u4e00-\u9fa5]{2,6}[:：]')).first.trim();
        if (rest.isNotEmpty) return _clip(rest);
      }
    }
    return null;
  }

  /// 从整段文本里找第一个符合关键词的正则片段
  static String? _firstMatchByLine(List<String> lines, RegExp re) {
    for (final line in lines) {
      if (line.length > 60) continue;
      final m = re.firstMatch(line);
      if (m != null) return _clip(m.group(0)!);
    }
    // 单行没命中就在整段里找
    final all = lines.join(' ');
    final m = re.firstMatch(all);
    return m == null ? null : _clip(m.group(0)!);
  }

  /// 取关键词所在行之后的内容（用于多行诊断）
  static String? _multilineAfter(List<String> lines, List<String> keys) {
    for (var i = 0; i < lines.length; i++) {
      for (final k in keys) {
        final idx = lines[i].indexOf(k);
        if (idx < 0) continue;
        final buf = <String>[];
        var rest = lines[i].substring(idx + k.length).trim();
        rest = rest.replaceFirst(RegExp(r'^[:： ]+'), '');
        if (rest.isNotEmpty) buf.add(rest);
        for (var j = i + 1; j < lines.length && buf.length < 3; j++) {
          if (_looksLikeKey(lines[j])) break;
          buf.add(lines[j]);
        }
        final text = buf.join(' ').trim();
        if (text.isNotEmpty) return _clip(text);
      }
    }
    return null;
  }

  static bool _looksLikeKey(String line) {
    return RegExp(r'^[\u4e00-\u9fa5]{2,8}[:：]').hasMatch(line);
  }

  static DateTime? _firstDate(String text) {
    final m = _dateRe.firstMatch(text);
    return m == null ? null : _toDate(m);
  }

  static List<DateTime> _allDates(String text) {
    final out = <DateTime>[];
    for (final m in _dateRe.allMatches(text)) {
      final d = _toDate(m);
      if (d != null && !out.contains(d)) out.add(d);
    }
    out.sort();
    return out;
  }

  static DateTime? _toDate(Match m) {
    final y = int.tryParse(m.group(1)!);
    final mo = int.tryParse(m.group(2)!);
    final d = int.tryParse(m.group(3)!);
    if (y == null || mo == null || d == null) return null;
    if (mo < 1 || mo > 12 || d < 1 || d > 31) return null;
    try {
      return DateTime(y, mo, d);
    } catch (_) {
      return null;
    }
  }

  static String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String? _firstAmount(String text, List<String> keys) {
    final lines = _lines(text);
    for (final line in lines) {
      for (final k in keys) {
        final idx = line.indexOf(k);
        if (idx < 0) continue;
        final rest = line.substring(idx + k.length);
        final m = _amountRe.firstMatch(rest);
        if (m != null) return m.group(1);
      }
    }
    return null;
  }

  /// 保单号兜底：一串 10 位以上的数字或数字字母混合
  static String? _policyNoGuess(String text) {
    final m = RegExp(r'\b(?=[A-Z0-9]*[0-9])[A-Z0-9]{10,25}\b').firstMatch(text);
    return m?.group(0);
  }

  static String _clip(String s) {
    final v = s.trim();
    return v.length > 60 ? v.substring(0, 60) : v;
  }
}
