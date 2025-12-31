#!/bin/bash

echo "========================================="
echo "  NekoBox 构建状态检查"
echo "========================================="
echo ""

# 检查 libcore 编译状态
echo "📦 libcore 编译状态:"
if [ -f "app/libs/libcore.aar" ]; then
    echo "  ✅ libcore.aar 已生成"
    ls -lh app/libs/libcore.aar
else
    echo "  ⏳ libcore.aar 尚未生成，正在编译中..."
    echo "  💡 编译时间约 15-30 分钟，请耐心等待"
fi

echo ""
echo "🔍 当前编译进程:"
ps aux | grep -E "(gomobile|build\.sh)" | grep -v grep || echo "  无活动编译进程"

echo ""
echo "📊 libcore 目录状态:"
ls -lh libcore/.build/ 2>/dev/null || echo "  .build 目录尚未创建"

echo ""
echo "========================================="
echo "  使用说明:"
echo "========================================="
echo "1. 等待 libcore 编译完成（约 15-30 分钟）"
echo "2. 编译完成后运行: ./gradlew app:assemblePlayDebug"
echo "3. APK 位置: app/build/outputs/apk/play/debug/"
echo ""
echo "💡 提示: 可以运行此脚本随时检查进度"
echo "========================================="

