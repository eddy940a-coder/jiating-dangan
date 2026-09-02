import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('关于')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          Center(
            child: Column(
              children: [
                SizedBox(height: 24),
                Icon(Icons.folder_special_outlined,
                    size: 72, color: AppColors.primary),
                SizedBox(height: 12),
                Text(
                  '家庭档案',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'v1.0.0',
                  style: TextStyle(color: AppColors.textHint),
                ),
              ],
            ),
          ),
          SizedBox(height: 32),
          _Item(
            title: '产品定位',
            content:
                '本 App 是一款纯本地工具，用于记录家人、保险保单、病历与家庭大事件，不会采集任何用户隐私数据。',
          ),
          _Item(
            title: '免责声明',
            content:
                '本 App 仅做记录，不提供任何医疗诊断或保险建议，相关数据请以专业医疗机构和保险公司提供的信息为准。',
          ),
          _Item(
            title: '开源许可',
            content:
                '本 App 使用 Flutter 开源框架构建，遵循 BSD / MIT 等开源协议。',
          ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.title, required this.content});
  final String title;
  final String content;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
