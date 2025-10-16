#!/bin/bash

# SuperStarOff - 签名和公证脚本
# 用于对 PKG 安装包进行代码签名和 Apple 公证

set -e

echo "==================================================="
echo "SuperStarOff - PKG 签名和公证"
echo "==================================================="
echo ""

# 配置
INSTALLER_DIR="$(cd "$(dirname "$0")" && pwd)"
UNSIGNED_PKG="$INSTALLER_DIR/SuperStarOff-PS-Installer.pkg"
SIGNED_PKG="$INSTALLER_DIR/SuperStarOff-PS-Installer-Signed.pkg"

# Apple Developer 信息
DEVELOPER_ID_INSTALLER="Developer ID Installer: James Zhen Yu (JWR6FDB52H)"
APPLE_ID="james@jamesphotography.com.au"
TEAM_ID="JWR6FDB52H"
APP_SPECIFIC_PASSWORD="vfmy-vjcb-injx-guid"

# 检查未签名的包是否存在
if [ ! -f "$UNSIGNED_PKG" ]; then
    echo "❌ 错误: 找不到未签名的 PKG 文件"
    echo "   路径: $UNSIGNED_PKG"
    exit 1
fi

PKG_SIZE=$(du -h "$UNSIGNED_PKG" | cut -f1)
echo "✓ 找到未签名的 PKG ($PKG_SIZE)"
echo ""

# ============================================
# 步骤 1: 签名 PKG
# ============================================
echo "=== 步骤 1: 签名 PKG 安装包 ==="
echo "使用证书: $DEVELOPER_ID_INSTALLER"

productsign --sign "$DEVELOPER_ID_INSTALLER" \
    "$UNSIGNED_PKG" \
    "$SIGNED_PKG"

if [ $? -ne 0 ]; then
    echo "❌ 错误: PKG 签名失败"
    exit 1
fi

echo "✓ PKG 签名成功"
echo ""

# 验证签名
echo "验证签名..."
pkgutil --check-signature "$SIGNED_PKG"
echo ""

# ============================================
# 步骤 2: 上传公证
# ============================================
echo "=== 步骤 2: 上传到 Apple 进行公证 ==="
echo "这可能需要几分钟..."
echo ""

# 使用 notarytool 上传
xcrun notarytool submit "$SIGNED_PKG" \
    --apple-id "$APPLE_ID" \
    --password "$APP_SPECIFIC_PASSWORD" \
    --team-id "$TEAM_ID" \
    --wait

if [ $? -ne 0 ]; then
    echo "❌ 错误: 公证提交失败"
    echo ""
    echo "可能的原因："
    echo "  1. 密码不正确（需要使用 App-Specific Password）"
    echo "  2. Apple ID 或 Team ID 不正确"
    echo "  3. 网络连接问题"
    echo ""
    echo "请访问 https://appleid.apple.com 生成 App-Specific Password"
    exit 1
fi

echo ""
echo "✓ 公证成功！"
echo ""

# ============================================
# 步骤 3: 装订公证票据
# ============================================
echo "=== 步骤 3: 装订公证票据到 PKG ==="

xcrun stapler staple "$SIGNED_PKG"

if [ $? -ne 0 ]; then
    echo "❌ 错误: 装订失败"
    exit 1
fi

echo "✓ 装订成功"
echo ""

# ============================================
# 步骤 4: 验证结果
# ============================================
echo "=== 步骤 4: 验证签名和公证 ==="

echo "验证签名..."
pkgutil --check-signature "$SIGNED_PKG"
echo ""

echo "验证公证票据..."
xcrun stapler validate "$SIGNED_PKG"
echo ""

# ============================================
# 完成
# ============================================
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
echo ""
