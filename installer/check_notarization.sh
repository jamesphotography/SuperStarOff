#!/bin/bash

# SuperStarOff - 检查公证状态并完成装订

set -e

echo "==================================================="
echo "SuperStarOff - 检查公证状态"
echo "==================================================="
echo ""

# 配置
INSTALLER_DIR="$(cd "$(dirname "$0")" && pwd)"
SIGNED_PKG="$INSTALLER_DIR/SuperStarOff-PS-Installer-Signed.pkg"

# Apple Developer 信息
APPLE_ID="james@jamesphotography.com.au"
TEAM_ID="JWR6FDB52H"
APP_SPECIFIC_PASSWORD="vfmy-vjcb-injx-guid"
SUBMISSION_ID="b26d91a6-7e10-484c-a256-624a3de8d327"

echo "检查提交 ID: $SUBMISSION_ID"
echo ""

# 检查公证状态
xcrun notarytool info "$SUBMISSION_ID" \
    --apple-id "$APPLE_ID" \
    --password "$APP_SPECIFIC_PASSWORD" \
    --team-id "$TEAM_ID"

echo ""
echo "==================================================="
echo ""

# 获取状态
STATUS=$(xcrun notarytool info "$SUBMISSION_ID" \
    --apple-id "$APPLE_ID" \
    --password "$APP_SPECIFIC_PASSWORD" \
    --team-id "$TEAM_ID" | grep "status:" | awk '{print $2}')

echo "当前状态: $STATUS"
echo ""

if [ "$STATUS" = "Accepted" ]; then
    echo "✅ 公证已通过！"
    echo ""

    # 装订公证票据
    echo "=== 装订公证票据到 PKG ==="
    xcrun stapler staple "$SIGNED_PKG"

    if [ $? -ne 0 ]; then
        echo "❌ 错误: 装订失败"
        exit 1
    fi

    echo "✓ 装订成功"
    echo ""

    # 验证结果
    echo "=== 验证签名和公证 ==="

    echo "验证签名..."
    pkgutil --check-signature "$SIGNED_PKG"
    echo ""

    echo "验证公证票据..."
    xcrun stapler validate "$SIGNED_PKG"
    echo ""

    SIGNED_SIZE=$(du -h "$SIGNED_PKG" | cut -f1)

    echo ""
    echo "==================================================="
    echo "✅ 签名和公证完成！"
    echo "==================================================="
    echo ""
    echo "已签名和公证的安装包:"
    echo "  文件: $SIGNED_PKG"
    echo "  大小: $SIGNED_SIZE"
    echo ""
    echo "此安装包现在可以："
    echo "  ✓ 在任何 macOS 设备上安装"
    echo "  ✓ 不会显示"来自未识别的开发者"警告"
    echo "  ✓ 通过 Gatekeeper 安全检查"
    echo ""
    echo "分发方式："
    echo "  1. 直接分发 .pkg 文件"
    echo "  2. 上传到您的网站"
    echo "  3. 通过电子邮件发送"
    echo ""
    echo "==================================================="

elif [ "$STATUS" = "In" ]; then
    echo "⏳ 公证仍在处理中..."
    echo "   通常需要 5-15 分钟"
    echo ""
    echo "请稍后再运行此脚本检查状态:"
    echo "  ./check_notarization.sh"

elif [ "$STATUS" = "Invalid" ]; then
    echo "❌ 公证失败"
    echo ""
    echo "查看详细日志:"
    xcrun notarytool log "$SUBMISSION_ID" \
        --apple-id "$APPLE_ID" \
        --password "$APP_SPECIFIC_PASSWORD" \
        --team-id "$TEAM_ID"

else
    echo "未知状态: $STATUS"
fi

echo ""
