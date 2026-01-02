#!/bin/bash
# Windows Release 构建脚本（在 Windows 上使用 Git Bash 或 WSL）
# 参考 Android 端的 release 构建方式

set -e

echo "========================================"
echo "NekoBox Windows Release Build"
echo "========================================"
echo ""

# 检查 Flutter 环境
if ! command -v flutter &> /dev/null; then
    echo "[错误] Flutter 未安装或未添加到 PATH"
    exit 1
fi

# 进入项目目录
cd "$(dirname "$0")"

echo "[1/5] 清理之前的构建..."
flutter clean

echo ""
echo "[2/5] 获取依赖..."
flutter pub get

echo ""
echo "[3/5] 分析代码..."
flutter analyze --no-fatal-infos || echo "[警告] 代码分析发现问题，但继续构建..."

echo ""
echo "[4/5] 构建 Release 版本..."
flutter build windows --release

echo ""
echo "[5/5] 构建完成！"
echo ""
echo "输出目录: build/windows/x64/runner/Release/"
echo ""
echo "========================================"
echo "构建成功！"
echo "========================================"
echo ""

