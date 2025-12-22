#!/bin/bash
set -e

echo "==================================================="
echo "清理并重新构建 SuperStarOff PS-Only"
echo "==================================================="
echo ""

cd /Users/jameszhenyu/PycharmProjects/SuperStarOff/installer

echo "步骤 1: 清理旧文件..."
rm -rf build/ 2>/dev/null || true
rm -f SuperStarOff-PS-Only.pkg 2>/dev/null || true
rm -f SuperStarOff-PS-Only-Signed.pkg 2>/dev/null || true
echo "✓ 清理完成"
echo ""

echo "步骤 2: 运行构建脚本..."
./build_ps_only.sh

echo ""
echo "==================================================="
echo "✅ 构建完成！"
echo "==================================================="
