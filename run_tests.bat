@echo off
chcp 65001 >nul
title 家庭档案 - 静态检查 + 单元测试

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
echo  1/3 拉取依赖
echo ============================================
call flutter pub get
if errorlevel 1 goto :fail

echo.
echo ============================================
echo  2/3 静态检查（只有 error 才算失败）
echo ============================================
call flutter analyze --no-fatal-warnings --no-fatal-infos
if errorlevel 1 goto :fail

echo.
echo ============================================
echo  3/3 单元测试 / Widget 测试
echo ============================================
call flutter test
if errorlevel 1 goto :fail

echo.
echo [完成] 全部检查通过
goto :end

:fail
echo.
echo [失败] 请查看上方输出

:end
