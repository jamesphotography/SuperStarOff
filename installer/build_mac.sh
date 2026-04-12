#!/bin/bash
# SuperStarOff - macOS PKG 一键构建脚本
# 包含: PyInstaller 打包 → 深度签名 → 构建 PKG → 公证 → 钉入票据
set -e

# ============================================================
# 配置
# ============================================================
VERSION="1.1.2"
APP_BUNDLE_ID="com.jameszhengyu.superstaroff"
INSTALL_LOCATION="/usr/local/SuperStarOff"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

DIST_DIR="$PROJECT_ROOT/dist/superstaroff"
BUILD_DIR="$PROJECT_ROOT/build/mac_pkg"
OUTPUT_DIR="$PROJECT_ROOT/installer_output"
PKG_FINAL="$OUTPUT_DIR/SuperStarOff-v$VERSION.pkg"
VENV_DIR="$PROJECT_ROOT/.venv_dist"

APP_SIGN_ID="Developer ID Application: James Zhen Yu (JWR6FDB52H)"
PKG_SIGN_ID="Developer ID Installer: James Zhen Yu (JWR6FDB52H)"
NOTARY_PROFILE="superstaroff-notary"

# ============================================================
echo ""
echo "==================================================="
echo "  SuperStarOff macOS PKG 构建 v$VERSION"
echo "==================================================="
echo ""

# ============================================================
# Step 1: 检查前提条件
# ============================================================
echo "=== Step 1: 检查前提条件 ==="

if [ ! -f "$PROJECT_ROOT/superstaroff.spec" ]; then
    echo "[ERROR] 找不到 superstaroff.spec，请在项目根目录运行"
    exit 1
fi

if ! command -v python3 &>/dev/null; then
    echo "[ERROR] 未找到 python3"
    exit 1
fi

if ! security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
    echo "[ERROR] 未找到 Developer ID Application 证书"
    exit 1
fi

if ! security find-identity -v | grep -q "Developer ID Installer"; then
    echo "[ERROR] 未找到 Developer ID Installer 证书"
    exit 1
fi

echo "[OK] 所有前提条件满足"
echo ""

# ============================================================
# Step 2: 准备干净的打包专用虚拟环境
# ============================================================
echo "=== Step 2: 准备打包虚拟环境 ==="

if [ ! -f "$VENV_DIR/bin/python" ]; then
    echo "创建干净的虚拟环境: $VENV_DIR"
    python3 -m venv "$VENV_DIR"
    "$VENV_DIR/bin/pip" install --upgrade pip -q
    echo "安装依赖（首次较慢，约 3-5 分钟）..."
    "$VENV_DIR/bin/pip" install \
        torch \
        "numpy>=1.24.0,<2.0" \
        Pillow tifffile imagecodecs \
        cryptography \
        pyinstaller -q
    echo "[OK] 虚拟环境准备完成"
else
    echo "[OK] 已有虚拟环境，跳过安装"
fi

PYINSTALLER="$VENV_DIR/bin/pyinstaller"
echo ""

# ============================================================
# Step 3: PyInstaller 打包（含签名）
# ============================================================
echo "=== Step 3: PyInstaller 打包 ==="

cd "$PROJECT_ROOT"
export SUPERSTAROFF_CODESIGN_IDENTITY="$APP_SIGN_ID"
"$PYINSTALLER" superstaroff.spec --noconfirm

if [ ! -f "$DIST_DIR/superstaroff" ]; then
    echo "[ERROR] PyInstaller 打包失败，找不到可执行文件"
    exit 1
fi
echo "[OK] PyInstaller 打包完成"
echo ""

# ============================================================
# Step 3: 深度签名所有二进制文件
# ============================================================
echo "=== Step 4: 深度签名二进制文件 ==="

# 签名所有 .so 和 .dylib
find "$DIST_DIR" -type f \( -name "*.so" -o -name "*.dylib" \) | while read -r f; do
    codesign --force --sign "$APP_SIGN_ID" --timestamp "$f" 2>/dev/null || true
done

# 签名主可执行文件
codesign --force --sign "$APP_SIGN_ID" --timestamp \
    --options runtime "$DIST_DIR/superstaroff"

echo "[OK] 签名完成"
echo ""

# ============================================================
# Step 4: 编译并签名 安装到Photoshop.app
# ============================================================
echo "=== Step 4: 编译 安装到Photoshop.app ==="

APPLESCRIPT_SRC="$SCRIPT_DIR/macos/安装到Photoshop.applescript"
APPLET_OUT="$SCRIPT_DIR/macos/安装到Photoshop.app"

# 每次重新编译，确保内容最新
rm -rf "$APPLET_OUT"
osacompile -o "$APPLET_OUT" "$APPLESCRIPT_SRC"

if [ ! -d "$APPLET_OUT" ]; then
    echo "[ERROR] AppleScript 编译失败"
    exit 1
fi

# 签名 applet
codesign --force --sign "$APP_SIGN_ID" --timestamp \
    --options runtime "$APPLET_OUT"

echo "[OK] 安装到Photoshop.app 编译并签名完成"
echo ""

# ============================================================
# Step 4b: 准备 PKG Payload
# ============================================================
echo "=== Step 4b: 准备 PKG Payload ==="

PAYLOAD_DIR="$BUILD_DIR/payload$INSTALL_LOCATION"
rm -rf "$BUILD_DIR"
mkdir -p "$PAYLOAD_DIR"
mkdir -p "$OUTPUT_DIR"

# 复制可执行文件和依赖
cp -r "$DIST_DIR/." "$PAYLOAD_DIR/"

# 复制 JSX 脚本（生产版，不含 DEV 版）
cp "$PROJECT_ROOT/src/慧眼去星.jsx" "$PAYLOAD_DIR/慧眼去星.jsx"

# 复制 GUI 安装工具
cp -r "$APPLET_OUT" "$PAYLOAD_DIR/安装到Photoshop.app"

echo "[OK] Payload 准备完成"
echo ""

# ============================================================
# Step 5: 构建组件包（component.pkg）
# ============================================================
echo "=== Step 5: 构建 PKG ==="

SCRIPTS_DIR="$SCRIPT_DIR/macos/scripts"
chmod +x "$SCRIPTS_DIR/postinstall"

COMPONENT_PKG="$BUILD_DIR/component.pkg"
pkgbuild \
    --root "$BUILD_DIR/payload" \
    --scripts "$SCRIPTS_DIR" \
    --identifier "$APP_BUNDLE_ID" \
    --version "$VERSION" \
    --install-location "/" \
    --sign "$PKG_SIGN_ID" \
    "$COMPONENT_PKG"

echo "[OK] 组件包构建完成"
echo ""

# ============================================================
# Step 6: 构建最终分发 PKG（productbuild）
# ============================================================
echo "=== Step 6: 生成最终 PKG ==="

productbuild \
    --package "$COMPONENT_PKG" \
    --sign "$PKG_SIGN_ID" \
    "$PKG_FINAL"

echo "[OK] PKG 生成: $PKG_FINAL"
echo ""

# ============================================================
# Step 7: 提交公证
# ============================================================
echo "=== Step 7: 提交公证（约 2-5 分钟）==="

xcrun notarytool submit "$PKG_FINAL" \
    --keychain-profile "$NOTARY_PROFILE" \
    --wait

echo "[OK] 公证完成"
echo ""

# ============================================================
# Step 8: 钉入公证票据
# ============================================================
echo "=== Step 8: 钉入公证票据 ==="

xcrun stapler staple "$PKG_FINAL"

echo "[OK] 票据钉入完成"
echo ""

# ============================================================
# Step 9: 验证
# ============================================================
echo "=== Step 9: 验证结果 ==="

spctl --assess --type install "$PKG_FINAL" && echo "[OK] Gatekeeper 验证通过" || echo "[WARN] Gatekeeper 验证失败"

PKG_SIZE=$(du -sh "$PKG_FINAL" | cut -f1)
echo ""
echo "==================================================="
echo "[SUCCESS] 构建完成!"
echo "==================================================="
echo ""
echo "版本:   $VERSION"
echo "文件:   $PKG_FINAL"
echo "大小:   $PKG_SIZE"
echo ""
