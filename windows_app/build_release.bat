@echo off
REM Windows Release 构建脚本
REM 参考 Android 端的 release 构建方式

echo ========================================
echo NekoBox Windows Release Build
echo ========================================
echo.

REM 检查 Flutter 环境
where flutter >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [错误] Flutter 未安装或未添加到 PATH
    pause
    exit /b 1
)

REM 进入项目目录
cd /d "%~dp0"

echo [1/5] 清理之前的构建...
call flutter clean
if %ERRORLEVEL% NEQ 0 (
    echo [错误] 清理失败
    pause
    exit /b 1
)

echo.
echo [2/5] 获取依赖...
call flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo [错误] 获取依赖失败
    pause
    exit /b 1
)

echo.
echo [3/5] 分析代码...
call flutter analyze --no-fatal-infos
if %ERRORLEVEL% NEQ 0 (
    echo [警告] 代码分析发现问题，但继续构建...
)

echo.
echo [4/5] 构建 Release 版本...
call flutter build windows --release
if %ERRORLEVEL% NEQ 0 (
    echo [错误] 构建失败
    pause
    exit /b 1
)

echo.
echo [5/5] 构建完成！
echo.
echo 输出目录: build\windows\x64\runner\Release\
echo.
echo ========================================
echo 构建成功！
echo ========================================
echo.

REM 可选：自动打开输出目录
REM explorer build\windows\x64\runner\Release

pause

