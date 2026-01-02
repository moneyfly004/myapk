@echo off
REM NekoBox Windows 构建脚本
REM 在 Windows 机器上运行此脚本

echo ========================================
echo NekoBox Windows 构建脚本
echo ========================================
echo.

REM 检查 Flutter 是否安装
where flutter >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] Flutter 未安装或未添加到 PATH
    echo 请先安装 Flutter: https://flutter.dev/docs/get-started/install/windows
    pause
    exit /b 1
)

echo [1/5] 检查 Flutter 环境...
flutter doctor
if %errorlevel% neq 0 (
    echo [警告] Flutter 环境可能有问题，请检查上面的输出
    pause
)

echo.
echo [2/5] 清理之前的构建...
flutter clean

echo.
echo [3/5] 获取依赖...
flutter pub get
if %errorlevel% neq 0 (
    echo [错误] 依赖获取失败
    pause
    exit /b 1
)

echo.
echo [4/5] 分析代码...
flutter analyze
if %errorlevel% neq 0 (
    echo [警告] 代码分析发现问题，但继续构建...
)

echo.
echo [5/5] 开始构建 Windows 应用...
echo 选择构建类型:
echo 1. Debug 版本 (开发测试)
echo 2. Release 版本 (发布)
set /p build_type="请输入选择 (1 或 2): "

if "%build_type%"=="1" (
    echo 构建 Debug 版本...
    flutter build windows --debug
) else if "%build_type%"=="2" (
    echo 构建 Release 版本...
    flutter build windows --release
) else (
    echo [错误] 无效的选择
    pause
    exit /b 1
)

if %errorlevel% neq 0 (
    echo [错误] 构建失败
    pause
    exit /b 1
)

echo.
echo ========================================
echo 构建完成！
echo ========================================
echo.
echo 构建产物位置:
if "%build_type%"=="1" (
    echo build\windows\x64\debug\runner\
) else (
    echo build\windows\x64\runner\Release\
)
echo.
echo 可执行文件: nekobox_windows.exe
echo.
pause

