@echo off
chcp 65001 >nul
title 家庭档案 - 一键构建并安装到模拟器

rem ============================================================
rem 重要排错提示
rem 若脚本卡在 "Building flutter tool..." 或报
rem "Unable to determine engine version"，多半是 Windows Defender
rem 实时保护正在扫描刚解压的 Flutter SDK。请把以下目录加入
rem Windows Defender 排除项（Windows 安全中心 → 病毒和威胁防护
rem → 管理设置 → 排除项 → 添加或删除排除项 → 文件夹）：
rem     D:\flutter
rem     D:\.pub-cache
rem     D:\.gradle
rem     本项目的目录 (D:\yuan\ai-app\jiating-dangan)
rem 或者直接临时关闭“实时保护”再运行本脚本即可。
rem ============================================================

set "FLUTTER=D:\flutter\bin"
set "PATH=%FLUTTER%;%PATH%"
set "PUB_HOSTED_URL=https://pub.flutter-io.cn"
set "FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn"
set "PUB_CACHE=D:\.pub-cache"
set "ANDROID_HOME=C:\Users\14869\AppData\Local\Android\Sdk"
set "ANDROID_SDK_ROOT=C:\Users\14869\AppData\Local\Android\Sdk"
set "JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-21.0.11.10-hotspot"
set "GRADLE_USER_HOME=D:\.gradle"
set "FLUTTER_SUPPRESS_ANALYTICS=true"

cd /d D:\yuan\ai-app\jiating-dangan

echo ============================================
echo  1/5 修正 Flutter SDK 路径 (指向 D:\flutter)
echo ============================================
(
echo sdk.dir=C:/Users/14869/AppData/Local/Android/Sdk
echo flutter.sdk=D:\\flutter
echo flutter.buildMode=debug
echo flutter.versionName=1.0.0
echo flutter.versionCode=1
) > android\local.properties
type android\local.properties

echo.
echo ============================================
echo  2/5 构建 APK (首次约 5-15 分钟，请勿关闭窗口)
echo      构建期间不要开模拟器，以免内存不足
echo ============================================
call flutter build apk --debug
if errorlevel 1 (
    echo.
    echo [失败] 构建出错，请把上面的红字截图发给助手
    pause
    exit /b 1
)

echo.
echo ============================================
echo  3/5 启动模拟器 Pixel_9
echo ============================================
start "" "%ANDROID_HOME%\emulator\emulator.exe" -avd Pixel_9 -gpu host
echo 模拟器启动中，等待其开机（约 1 分钟）...
"%ANDROID_HOME%\platform-tools\adb.exe" wait-for-device

echo.
echo ============================================
echo  4/5 安装 APK 到模拟器
echo ============================================
"%ANDROID_HOME%\platform-tools\adb.exe" install -r build\app\outputs\flutter-apk\app-debug.apk

echo.
echo ============================================
echo  5/5 启动 App
echo ============================================
"%ANDROID_HOME%\platform-tools\adb.exe" shell monkey -p com.yuan.family_archive -c android.intent.category.LAUNCHER 1

echo.
echo [完成] 请查看模拟器窗口
pause
