import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/models/family_event.dart';
import '../data/models/family_member.dart';
import '../data/models/insurance.dart';
import '../data/models/medical_record.dart';
import '../utils/date_util.dart';

/// 导出全部业务数据到一个 .xlsx 文件。
class ExcelExportService {
  ExcelExportService._();
  static final ExcelExportService instance = ExcelExportService._();

  Future<String> exportAll({
    required List<FamilyMember> members,
    required List<Insurance> insurances,
    required List<MedicalRecord> medicals,
    required List<FamilyEvent> events,
  }) async {
    final excel = Excel.createExcel();
    // 移除默认 Sheet1
    excel.rename('Sheet1', '家庭成员');
    _writeMembers(excel['家庭成员'], members);

    final s2 = excel['保险保单'];
    _writeInsurances(s2, insurances, members);

    final s3 = excel['就医病历'];
    _writeMedical(s3, medicals, members);

    final s4 = excel['家庭事件'];
    _writeEvents(s4, events, members);

    final bytes = excel.encode() ?? Uint8List(0);

    final dir = await getApplicationDocumentsDirectory();
    final expDir = Directory(p.join(dir.path, 'exports'));
    if (!await expDir.exists()) await expDir.create(recursive: true);
    final ts = _ts(DateTime.now());
    final file = File(p.join(expDir.path, '家庭档案_$ts.xlsx'));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  // ---------- helpers ----------

  static CellValue _s(String v) => TextCellValue(v);

  static String _ts(DateTime d) {
    String t(int v) => v.toString().padLeft(2, '0');
    return '${d.year}${t(d.month)}${t(d.day)}_${t(d.hour)}${t(d.minute)}';
  }

  static String _memberName(List<FamilyMember> ms, String id) {
    for (final m in ms) {
      if (m.id == id) return m.name;
    }
    return id;
  }

  static void _writeMembers(Sheet s, List<FamilyMember> ms) {
    s.appendRow(<CellValue>[
      _s('姓名'),
      _s('关系'),
      _s('生日'),
      _s('年龄'),
      _s('血型'),
      _s('身份证号'),
      _s('药物过敏史'),
      _s('既往基础疾病'),
      _s('档案隐藏'),
    ]);
    for (final m in ms) {
      s.appendRow(<CellValue>[
        _s(m.name),
        _s(m.relation),
        _s(DateUtil.ymd(m.birthday)),
        _s(m.birthday == null ? '' : m.age.toString()),
        _s(m.bloodType),
        _s(m.idCard),
        _s(m.allergy),
        _s(m.chronicDisease),
        _s(m.hidden ? '是' : '否'),
      ]);
    }
  }

  static void _writeInsurances(
    Sheet s,
    List<Insurance> ins,
    List<FamilyMember> ms,
  ) {
    s.appendRow(<CellValue>[
      _s('归属成员'),
      _s('类型'),
      _s('保险公司'),
      _s('保单号'),
      _s('投保人'),
      _s('被保人'),
      _s('受益人'),
      _s('投保日期'),
      _s('生效日期'),
      _s('到期日期'),
      _s('保费(元)'),
      _s('到期提醒'),
      _s('保障摘要'),
      _s('备注'),
      _s('状态'),
    ]);
    for (final i in ins) {
      s.appendRow(<CellValue>[
        _s(_memberName(ms, i.memberId)),
        _s(i.type),
        _s(i.company),
        _s(i.policyNo),
        _s(i.policyHolder),
        _s(i.insuredPerson),
        _s(i.beneficiary),
        _s(DateUtil.ymd(i.purchaseDate)),
        _s(DateUtil.ymd(i.effectiveDate)),
        _s(DateUtil.ymd(i.expireDate)),
        _s(i.premium == null ? '' : i.premium!.toStringAsFixed(2)),
        _s(i.remindEnabled ? '开启' : '关闭'),
        _s(i.summary),
        _s(i.remark),
        _s(i.status),
      ]);
    }
  }

  static void _writeMedical(
    Sheet s,
    List<MedicalRecord> rs,
    List<FamilyMember> ms,
  ) {
    s.appendRow(<CellValue>[
      _s('归属成员'),
      _s('就诊时间'),
      _s('医院'),
      _s('科室'),
      _s('医生'),
      _s('就诊类型'),
      _s('主诉'),
      _s('诊断结果'),
      _s('用药记录'),
      _s('复诊时间'),
      _s('复诊提醒'),
      _s('备注'),
    ]);
    for (final r in rs) {
      s.appendRow(<CellValue>[
        _s(_memberName(ms, r.memberId)),
        _s(DateUtil.ymdHm(r.visitTime)),
        _s(r.hospital),
        _s(r.department),
        _s(r.doctor),
        _s(r.visitType),
        _s(r.chiefComplaint),
        _s(r.diagnosis),
        _s(r.medication),
        _s(DateUtil.ymd(r.revisitTime)),
        _s(r.revisitRemind ? '开启' : '关闭'),
        _s(r.remark),
      ]);
    }
  }

  static void _writeEvents(
    Sheet s,
    List<FamilyEvent> es,
    List<FamilyMember> ms,
  ) {
    s.appendRow(<CellValue>[
      _s('关联成员'),
      _s('事件时间'),
      _s('分类'),
      _s('类型'),
      _s('标题'),
      _s('描述'),
    ]);
    for (final e in es) {
      final names = e.memberIds.map((id) => _memberName(ms, id)).join('、');
      s.appendRow(<CellValue>[
        _s(names),
        _s(DateUtil.ymdHm(e.eventTime)),
        _s(e.category),
        _s(eventTypeLabel(e.type)),
        _s(e.title),
        _s(e.description),
      ]);
    }
  }
}
