import '../data/models/family_event.dart';
import '../data/models/insurance.dart';
import '../data/models/medical_record.dart';
import '../data/repositories/event_repository.dart';
import 'notification_service.dart';

/// 保存 / 删除 业务记录时，同步处理衍生事件与本地通知。
class RecordSyncService {
  RecordSyncService._();
  static final RecordSyncService instance = RecordSyncService._();

  final EventRepository _events = EventRepository.instance;
  final NotificationService _notify = NotificationService.instance;

  /// 保存保单后调用：写/更新一条家庭事件 + 计划到期提醒。
  Future<void> afterSaveInsurance(Insurance item) async {
    final eventTime =
        item.effectiveDate ?? item.purchaseDate ?? item.updatedAt;
    final event = FamilyEvent(
      id: 'evt_ins_${item.id}',
      memberIds: [item.memberId],
      eventTime: eventTime,
      category: '保险',
      type: kEventTypeInsurance,
      title: '投保「${item.type}」- ${item.company.isEmpty ? "未填写保险公司" : item.company}',
      description: item.summary.isNotEmpty
          ? item.summary
          : '保单号：${item.policyNo.isEmpty ? "-" : item.policyNo}',
      relatedId: item.id,
      createdAt: item.createdAt,
      updatedAt: DateTime.now(),
    );
    await _events.upsert(event);
    await _notify.scheduleInsuranceReminders(item);
  }

  Future<void> afterDeleteInsurance(String insuranceId) async {
    await _events.deleteByRelatedId(insuranceId);
    await _notify.cancelInsuranceReminders(insuranceId);
  }

  Future<void> afterSaveMedical(MedicalRecord r) async {
    final event = FamilyEvent(
      id: 'evt_med_${r.id}',
      memberIds: [r.memberId],
      eventTime: r.visitTime,
      category: '就医',
      type: kEventTypeMedical,
      title:
          '${r.visitType} - ${r.hospital.isEmpty ? "未填写医院" : r.hospital}',
      description: r.diagnosis.isNotEmpty
          ? r.diagnosis
          : (r.chiefComplaint.isNotEmpty ? r.chiefComplaint : '本次就诊记录'),
      relatedId: r.id,
      createdAt: r.createdAt,
      updatedAt: DateTime.now(),
    );
    await _events.upsert(event);
    await _notify.scheduleRevisitReminders(r);
    await _notify.scheduleCheckupReminders(r);
  }

  Future<void> afterDeleteMedical(String medicalId) async {
    await _events.deleteByRelatedId(medicalId);
    await _notify.cancelRevisitReminders(medicalId);
    await _notify.cancelCheckupReminders(medicalId);
  }
}
