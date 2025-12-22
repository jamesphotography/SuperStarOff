#!/bin/bash
# 使用现有组件包重新打包为 Distribution XML 格式

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INSTALLER_DIR="$PROJECT_ROOT/installer"
BUILD_DIR="$INSTALLER_DIR/build"
RESOURCES_DIR="$INSTALLER_DIR/resources"

echo "==================================================="
echo "重新打包为 Distribution XML 格式"
echo "==================================================="
echo ""

# 检查必需文件
echo "=== 检查必需文件 ==="
[ -f "$INSTALLER_DIR/distribution.xml" ] && echo "✓ distribution.xml" || { echo "❌ distribution.xml"; exit 1; }
[ -f "$BUILD_DIR/SuperStarOff-Component.pkg" ] && echo "✓ SuperStarOff-Component.pkg" || { echo "❌ SuperStarOff-Component.pkg 不存在，请先运行 build_pkg_standalone.sh"; exit 1; }
[ -d "$RESOURCES_DIR" ] && echo "✓ resources/" || { echo "❌ resources/"; exit 1; }
echo ""

# 创建 packages 目录并复制组件包
echo "=== 准备组件包 ==="
mkdir -p "$BUILD_DIR/packages"
cp "$BUILD_DIR/SuperStarOff-Component.pkg" "$BUILD_DIR/packages/"
echo "✓ 组件包已复制"
echo ""

# 使用 Distribution XML 创建产品包
echo "=== 使用 Distribution XML 创建产品包 ==="
productbuild --distribution "$INSTALLER_DIR/distribution.xml" \
    --package-path "$BUILD_DIR/packages" \
    --resources "$RESOURCES_DIR" \
    "$INSTALLER_DIR/SuperStarOff-Distribution.pkg"

echo "✓ Distribution 包已创建"
echo ""

# 签名
echo "=== 签名产品包 ==="
productsign --sign "Developer ID Installer: James Zhen Yu (JWR6FDB52H)" \
    "$INSTALLER_DIR/SuperStarOff-Distribution.pkg" \
    "$INSTALLER_DIR/release_pkg/SuperStarOff-Distribution-v12.pkg"

PKG_SIZE=$(du -sh "$INSTALLER_DIR/release_pkg/SuperStarOff-Distribution-v12.pkg" | cut -f1)
PKG_MD5=$(md5 -q "$INSTALLER_DIR/release_pkg/SuperStarOff-Distribution-v12.pkg")

echo "✓ 签名完成"
echo ""

echo "==================================================="
echo "✅ Distribution XML 打包成功！"
echo "==================================================="
echo "文件: SuperStarOff-Distribution-v12.pkg"
echo "位置: installer/release_pkg/"
echo "大小: $PKG_SIZE"
echo "MD5: $PKG_MD5"
echo ""
echo "特性:"
echo "  ✓ 多版本 Photoshop 选择界面"
echo "  ✓ 支持 PS 2019-2026"
echo "  ✓ 欢迎页面和许可协议"
echo "  ✓ 安装总结页面"
echo ""
echo "测试:"
echo "  open installer/release_pkg/SuperStarOff-Distribution-v12.pkg"
echo "==================================================="
