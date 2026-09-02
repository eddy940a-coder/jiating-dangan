# 家庭档案 (Family Archive)

一款 **纯本地** 的家庭隐私记录移动端 App，使用 Flutter 开发。
面向 Android / iOS 双端，**全部数据存储在本地 SQLite，不搭建后端服务器，不上传任何用户隐私数据，无网络请求**。

> 工具定位：家庭成员档案 · 保险保单 · 就医病历 · 家庭大事件 · 紧急医疗卡片生成。
>
> 不做：AI 问诊 · 保险推销 · 疾病诊断 · 云端同步 · 多人协同。

---

## ✨ 已实现功能

- **隐私安全**：6 位数字密码解锁 + 指纹 / Face ID；密码错误抖动提示；忘记密码无法找回（数据在本地）。
- **家庭成员管理**：姓名 / 关系 / 生日 / 血型 / 身份证 / 药物过敏史 / 既往基础疾病；支持"档案隐藏"。
- **保险档案**：归属成员分组；筛选（全部 / 有效 / 即将到期 / 已失效）；保单号、投保人、被保人、受益人、生效/到期日期、保费、保障摘要；多附件（图片 / PDF）；到期本地通知提醒（30 天前 + 当天）。
- **就医病历**：按成员筛选；就诊类型（门诊 / 住院 / 手术 / 体检）；主诉 / 诊断 / 用药；复诊时间 + 本地通知提醒。
- **家庭大事件时间线**：按成员 / 类型筛选；垂直时间轴（蓝-保险 / 红-就医 / 黄-家庭手动）；保存保单与病历会自动生成事件。
- **紧急医疗卡**：选择成员自动聚合关键信息，一键保存为图片到相册（可设为锁屏给医生看）。
- **设置中心**：
  - 隐私安全：密码锁 / 生物识别 / 修改密码
  - 数据管理：**AES-256 加密压缩包**导出、加密备份恢复、Excel 导出、清除全部数据（红色确认）
  - 显示设置：字体大小三档（全局生效）
  - 关于、隐私政策
- **本地通知**：使用 `flutter_local_notifications`，无需后端。

---

## 🎨 设计规范

| 项目 | 值 |
| --- | --- |
| 主色 | `#1E4ED8` |
| 提醒橙 | `#F97316` |
| 医疗红 | `#EF4444` |
| 事件黄 | `#EAB308` |
| 背景 | `#FFFFFF` |
| 卡片背景 | `#F9FAFB` |
| 分割线 | `#E5E7EB` |
| 标题 | 18 号加粗（字号放大档位 ×1.18） |
| 正文 | 16 号 |
| 辅助小字 | 14 号 |
| 卡片圆角 | 12px |
| 按钮圆角 | 8px |
| 弹窗圆角 | 16px |

> 空状态统一为：居中图标 + 提示文字 + 操作引导。

---

## 📁 项目结构

```
lib/
├── main.dart                 入口
├── app.dart                  MaterialApp + 解锁 / 主页路由
├── theme/                    颜色 / 字体 / 主题
├── utils/                    日期、ID、PBKDF2 / SHA-256
├── data/
│   ├── db/                   SQLite helper & 表结构
│   ├── models/               4 张核心表对应模型
│   └── repositories/         数据访问层
├── services/                 通知 / 生物识别 / 附件 / 备份 / Excel / 同步
├── providers/                ChangeNotifier 状态管理
├── widgets/                  通用组件
└── pages/                    各功能页面
    ├── splash/               启动页
    ├── lock/                 解锁 / 创建密码
    ├── main/                 底部 Tab 容器
    ├── home/                 家庭仪表盘
    ├── member/               成员列表 / 编辑
    ├── insurance/            保单列表 / 编辑 / 详情
    ├── medical/              病历列表 / 编辑 / 详情
    ├── timeline/             时间线 / 事件编辑
    ├── emergency/            紧急医疗卡
    └── settings/             设置 / 关于 / 隐私政策
```

---

## 🗃️ 数据库（SQLite，4 张核心表 + 1 张设置表）

| 表 | 作用 |
| --- | --- |
| `family_member` | 家庭成员 |
| `insurance` | 保险保单 |
| `medical_record` | 就医病历 |
| `family_event` | 家庭大事件 |
| `app_settings` | 应用级设置（密码 / 字体 / 开关） |

> 附件不存数据库，只存文件名；磁盘文件位于 App 私有目录 `attachments/`，便于跨设备恢复。

---

## 🛠️ 编译运行

> 本机已安装 **Flutter 3.22+** 与对应平台工具链（Android Studio / Xcode）。

```bash
# 1. 拉取依赖
flutter pub get

# 2. 生成 iOS / Android 工程（首次或新增原生配置后）
#    - 已包含 android/ 完整配置
#    - iOS 需要生成 .xcodeproj：
flutter create --platforms=ios --org com.yuan .

# 3. 运行
flutter run                    # 自动选择已连接设备
# 或指定平台
flutter run -d android
flutter run -d ios
```

### 单独生成 Android / iOS 工程

如果希望完全使用本仓库目录结构，可在空目录中执行：

```bash
flutter create --org com.yuan --project-name family_archive . \
  && cp -R ../本仓库/lib . \
  && cp ../本仓库/pubspec.yaml .
```

### 仅生成启动图标

图标脚本（已生成于 `android/app/src/main/res/mipmap-*/ic_launcher.png`）使用 Python 3 重新生成：

```bash
python tools/gen_launcher_icon.py
```

---

## 🔐 权限说明

### Android (`android/app/src/main/AndroidManifest.xml`)

| 权限 | 用途 |
| --- | --- |
| `POST_NOTIFICATIONS` | 发送保单到期 / 复诊提醒 |
| `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM` | 精确时间触发本地通知 |
| `USE_BIOMETRIC` / `USE_FINGERPRINT` | 指纹 / 面容解锁 |
| `READ_MEDIA_IMAGES` (33+) / `READ_MEDIA_VIDEO` | 附件图片选择 |
| `READ_EXTERNAL_STORAGE` (≤ 32) | 旧版 Android 读取附件 |
| `WRITE_EXTERNAL_STORAGE` (≤ 28) | 旧版 Android 保存图片到相册 |

### iOS (`ios/Runner/Info.plist`)

| Key | 用途 |
| --- | --- |
| `NSFaceIDUsageDescription` | Face ID 解锁 |
| `NSPhotoLibraryUsageDescription` | 读取相册选图 |
| `NSPhotoLibraryAddUsageDescription` | 保存紧急医疗卡到相册 |
| `NSUserNotificationsUsageDescription` | 本地通知 |

> 任何一项权限被拒，App 仍可使用核心功能，对应特性会降级或给出提示。

---

## 🔒 加密备份格式

`.fda` 文件结构：

```
[ magic 'FDA1' (4B) ][ version (1B) ][ salt (16B) ][ iv (16B) ][ ciphertext ]
```

- 压缩：`archive` 库将数据库文件 + 附件 + manifest.json 打包为 zip。
- 加密：用户密码经 **PBKDF2-HMAC-SHA256**（10 000 轮）派生 32 字节密钥，再以 **AES-256-CBC + PKCS7** 加密整个 zip。
- 解密：相同流程解密 → 解压 → 替换 `family_archive.db` 并恢复附件目录。

> 备份不含任何网络上传步骤；导出后由用户通过系统分享面板自行决定保存位置。

---

## ⚠️ 重要使用说明

1. **本地通知限制**：本 App 提醒由系统本地通知实现，App 被系统杀死或清理后台后通知可能不再触发。Android 上请允许"自启动" / "后台运行"，iOS 上请允许"通知"。
2. **附件备份**：附件按相对文件名存储在 `attachments/`，加密备份会包含全部附件。
3. **数据迁移**：通过设置 → 加密备份导出 → 在新设备上"备份恢复导入"。
4. **密码不可恢复**：密码以 SHA-256 哈希形式保存在本地，忘记后无法找回，请妥善保管。
5. **免责声明**：本 App 仅做记录，不提供医疗诊断或保险建议。

---

## 📦 依赖一览

```yaml
sqflite: ^2.3.3                 # SQLite
flutter_local_notifications     # 本地通知
timezone: ^0.9.4                # tz 数据库
flutter_native_timezone: ^2.0.0 # 获取本地时区
local_auth: ^2.2.0              # 指纹/面容
file_picker: ^8.1.2             # 选择附件
open_filex: ^4.5.0              # 预览 PDF
image_gallery_saver_plus        # 保存图片到相册
permission_handler: ^11.3.1     # 运行时权限
archive: ^3.6.1                 # zip 打包
crypto: ^3.0.5                  # SHA-256 / HMAC / PBKDF2
encrypt: ^5.0.3                 # AES-CBC
excel: ^4.0.0                   # xlsx 导出
share_plus: ^10.1.2             # 系统分享
provider: ^6.1.2                # 状态管理
intl: ^0.19.0                   # 日期格式
```

---

## 🪪 License

MIT
