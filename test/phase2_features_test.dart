import 'package:flutter_test/flutter_test.dart';

import 'package:family_archive/data/models/family_member.dart';
import 'package:family_archive/data/models/insurance.dart';
import 'package:family_archive/data/models/medical_record.dart';
import 'package:family_archive/services/ocr_parser.dart';
import 'package:family_archive/services/pdf_export_service.dart';

/// 第 2 批功能回归测试：
/// - OCR 文本解析（不依赖设备，纯逻辑）
/// - 体检字段在模型上的读写
/// - 紧急医疗卡 PDF 生成
void main() {
  // ---------- OCR 解析 ----------

  group('OCR 解析 - 病历', () {
    const sample = '''
      北京协和医院
      门诊病历
      科室：心内科
      医生：张伟
      就诊日期：2026-08-20
      主诉：胸闷气短一周
      临床诊断：冠心病 稳定性心绞痛
      用药：阿司匹林 100mg 每日一次
    ''';

    final parsed = OcrParser.parseMedical(sample);

    test('提取医院', () {
      expect(parsed['hospital'], contains('北京协和医院'));
    });

    test('提取科室与医生', () {
      expect(parsed['department'], contains('心内科'));
      expect(parsed['doctor'], '张伟');
    });

    test('提取就诊日期并规范化为 yyyy-MM-dd', () {
      expect(parsed['visitTime'], '2026-08-20');
    });

    test('提取主诉、诊断与用药', () {
      expect(parsed['complaint'], contains('胸闷'));
      expect(parsed['diagnosis'], contains('冠心病'));
      expect(parsed['medication'], contains('阿司匹林'));
    });

    test('无法解析的字段留空而不是乱填', () {
      final empty = OcrParser.parseMedical('');
      expect(empty, isEmpty);
    });
  });

  group('OCR 解析 - 保单', () {
    const sample = '''
      中国人寿保险股份有限公司
      保险单
      保单号：202611000123456789
      险种：重大疾病保险
      投保人：李雷
      被保险人：韩梅梅
      保险费：5280.00
      保险期间：2026-01-01 至 2027-01-01
    ''';

    final parsed = OcrParser.parseInsurance(sample);

    test('提取保险公司', () {
      expect(parsed['company'], contains('中国人寿保险'));
    });

    test('提取保单号', () {
      expect(parsed['policyNo'], '202611000123456789');
    });

    test('提取投保人与被保人', () {
      expect(parsed['holder'], '李雷');
      expect(parsed['insured'], '韩梅梅');
    });

    test('提取保费金额', () {
      expect(parsed['premium'], '5280.00');
    });

    test('保险期间拆成生效日与到期日', () {
      expect(parsed['effectiveDate'], '2026-01-01');
      expect(parsed['expireDate'], '2027-01-01');
    });
  });

  test('日期解析会拒绝非法月份', () {
    final parsed = OcrParser.parseMedical('就诊日期：2026-13-45');
    expect(parsed['visitTime'], isNull);
  });

  // ---------- 体检字段 ----------

  group('体检字段', () {
    MedicalRecord base({
      DateTime? nextCheckup,
      bool remind = false,
    }) {
      final now = DateTime(2026, 9, 3);
      return MedicalRecord(
        id: 'm1',
        memberId: 'mem1',
        visitTime: now,
        visitType: '体检',
        nextCheckupDate: nextCheckup,
        checkupRemind: remind,
        createdAt: now,
        updatedAt: now,
      );
    }

    test('isCheckup 依据就诊类型判断', () {
      expect(base().isCheckup, isTrue);
      expect(base().copyWith(visitType: '门诊').isCheckup, isFalse);
    });

    test('toMap / fromMap 保留体检字段', () {
      final date = DateTime(2027, 9, 3);
      final r = base(nextCheckup: date, remind: true);
      final restored = MedicalRecord.fromMap(r.toMap());

      expect(restored.nextCheckupDate, date);
      expect(restored.checkupRemind, isTrue);
    });

    test('未设置体检日期时读到 null 而不是报错', () {
      final restored = MedicalRecord.fromMap(base().toMap());
      expect(restored.nextCheckupDate, isNull);
      expect(restored.checkupRemind, isFalse);
    });

    test('copyWith 可以清空体检日期', () {
      final r = base(nextCheckup: DateTime(2027, 9, 3), remind: true);
      final cleared = r.copyWith(clearNextCheckupDate: true);
      expect(cleared.nextCheckupDate, isNull);
      // 提醒开关不受影响，由调用方决定
      expect(cleared.checkupRemind, isTrue);
    });

    test('老数据（没有体检列的 Map）读取时不报错', () {
      final legacy = <String, Object?>{
        'id': 'old1',
        'member_id': 'mem1',
        'visit_time': DateTime(2026, 1, 1).millisecondsSinceEpoch,
        'hospital': '某医院',
        'visit_type': '门诊',
        'revisit_remind': 0,
        'attachments': '[]',
        'remark': '',
        'created_at': DateTime(2026, 1, 1).millisecondsSinceEpoch,
        'updated_at': DateTime(2026, 1, 1).millisecondsSinceEpoch,
      };
      final r = MedicalRecord.fromMap(legacy);
      expect(r.nextCheckupDate, isNull);
      expect(r.checkupRemind, isFalse);
    });
  });

  // ---------- PDF ----------

  testWidgets('生成结构化的紧急医疗卡 PDF', (tester) async {
    final now = DateTime(2026, 9, 3);
    final member = FamilyMember(
      id: 'mem1',
      name: '朱思源',
      relation: '本人',
      birthday: DateTime(1990, 5, 20),
      bloodType: 'O型',
      idCard: '110101199005201234',
      allergy: '青霉素、头孢',
      chronicDisease: '高血压',
      createdAt: now,
      updatedAt: now,
    );
    final insurance = Insurance(
      id: 'ins1',
      memberId: 'mem1',
      type: '医疗险',
      company: '中国人寿',
      policyNo: '202611000123456789',
      expireDate: DateTime(2027, 1, 1),
      status: '有效',
      createdAt: now,
      updatedAt: now,
    );

    final bytes = await PdfExportService.instance.buildEmergencyCard(
      member: member,
      insurances: [insurance],
    );

    // PDF 文件头
    expect(bytes.lengthInBytes, greaterThan(2000));
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(tester.takeException(), isNull);
  });

  testWidgets('没有保险与病史时也能生成 PDF', (tester) async {
    final now = DateTime(2026, 9, 3);
    final member = FamilyMember(
      id: 'mem2',
      name: '小明',
      relation: '儿子',
      createdAt: now,
      updatedAt: now,
    );

    final bytes = await PdfExportService.instance.buildEmergencyCard(
      member: member,
      insurances: const <Insurance>[],
    );

    expect(bytes.lengthInBytes, greaterThan(2000));
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(tester.takeException(), isNull);
  });
}
