#!/bin/bash
# 等待公证完成后自动装订

PKG_PATH="release_pkg/慧眼去星_StarOFF_V1_20251124.pkg"

echo "等待公证完成..."
echo "文件: $PKG_PATH"
echo ""

# 检查公证状态（这个脚本在公证完成后手动运行）
echo "装订公证票据..."
xcrun stapler staple "$PKG_PATH"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 装订成功！"
    echo ""
    echo "验证装订结果："
    xcrun stapler validate "$PKG_PATH"
    echo ""
    echo "最终包信息："
    ls -lh "$PKG_PATH"
    md5 -q "$PKG_PATH"
else
    echo ""
    echo "❌ 装订失败"
    exit 1
fi
