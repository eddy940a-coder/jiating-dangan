@echo off
chcp 65001 >nul
title 家庭档案 - 打包 Release APK

rem ============================================================
rem  一键打包发布版 APK
rem  产物：build\app\outputs\flutter-apk\app-release.apk
rem  签名：android\family-archive.jks（配置见 android\key.properties）
rem  若卡在 "Building flutter tool..." 或报 "Unable to determine
rem  engine version"，多半是 Windows Defender 实时保护在扫描，
rem  请把 D:\flutter、D:\.pub-cache、D:\.gradle 及本目录加入
rem  Defender 排除项后重试。
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
echo  1/2 拉取依赖
echo ============================================
call flutter pub get
if errorlevel 1 goto :fail

echo.
echo ============================================
echo  2/3 构建 Release APK（通用版，首次约 5-15 分钟）
echo ============================================
call flutter build apk --release
if errorlevel 1 goto :fail

echo.
echo ============================================
echo  3/3 构建按 CPU 架构拆分的小体积 APK
echo      （绝大多数手机装 arm64-v8a 那个）
echo ============================================
call flutter build apk --release --split-per-abi
if errorlevel 1 goto :fail

echo.
echo [完成] APK 输出目录：
echo   D:\yuan\ai-app\jiating-dangan\build\app\outputs\flutter-apk
echo   通用版：app-release.apk
echo   小体积：app-armeabi-v7a-release.apk / app-arm64-v8a-release.apk / app-x86_64-release.apk
goto :end

:fail
echo.
echo [失败] 构建出错，请查看上方红字

:end
