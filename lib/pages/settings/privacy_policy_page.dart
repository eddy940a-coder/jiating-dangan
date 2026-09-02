import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('隐私政策')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _Section(
            title: '我们收集什么',
            body: '家庭档案不会收集、上传、分享任何您的个人信息。所有成员信息、保单、病历、家庭事件及附件都只保存在您的设备本地。',
          ),
          _Section(
            title: '数据存储位置',
            body: '数据保存在 App 私有目录的 SQLite 数据库与附件文件夹中，卸载 App 将一并删除。建议您定期使用 App 提供的「加密备份导出」功能保存数据。',
          ),
          _Section(
            title: '本地通知',
            body: '保单到期、复诊等提醒由系统本地通知触发。App 不会也无法向任何服务器发送通知请求，App 被系统杀死或清理后台后，本地通知可能不再触发。',
          ),
          _Section(
            title: '权限使用',
            body:
                '· 通知权限：用于发送保单到期与复诊提醒；\n'
                '· 存储/相册权限：用于保存附件与紧急医疗卡到相册；\n'
                '· 生物识别：用于解锁 App。\n'
                '以上权限均不会用于其他用途。',
          ),
          _Section(
            title: '免责声明',
            body: '本 App 仅做记录，不提供任何医疗诊断或保险建议。请勿将本 App 作为诊断、治疗或保险理赔的唯一依据。',
          ),
          _Section(
            title: '联系我们',
            body: '如您对隐私有任何疑问，请通过 App 内反馈渠道联系开发者。',
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              )),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}
