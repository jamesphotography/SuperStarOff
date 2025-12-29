#!/bin/bash
set -e

echo "==================================================="
echo "SuperStarOff - Photoshop 插件安装包构建"
echo "==================================================="
echo ""

PROJECT_ROOT="/Users/jameszhenyu/PycharmProjects/SuperStarOff"
BUILD_DIR="$PROJECT_ROOT/installer/build"
PAYLOAD_DIR="$BUILD_DIR/payload"
SCRIPTS_DIR="$BUILD_DIR/scripts"
APP_DIR="$PAYLOAD_DIR/usr/local/SuperStarOff"
DIST_DIR="$PROJECT_ROOT/dist/superstaroff"
VERSION="1.1.0"

echo "项目根目录: $PROJECT_ROOT"
echo ""

# 步骤1: 清理
echo "=== 步骤 1: 清理旧的构建文件 ==="
rm -rf "$BUILD_DIR" 2>/dev/null || true
echo "✓ 清理完成"
echo ""

# 步骤2: 检查 PyInstaller 打包结果
echo "=== 步骤 2: 检查打包文件 ==="

if [ ! -f "$DIST_DIR/superstaroff" ]; then
    echo "❌ 错误: 找不到 PyInstaller 打包的可执行文件"
    echo "请先运行: .venv_build/bin/pyinstaller superstaroff.spec --clean"
    exit 1
fi
echo "✓ superstaroff 可执行文件存在"

if [ ! -f "$PROJECT_ROOT/src/慧眼去星.jsx" ]; then
    echo "❌ 错误: 找不到 慧眼去星.jsx"
    exit 1
fi
echo "✓ 慧眼去星.jsx 存在"

DIST_SIZE=$(du -sh "$DIST_DIR" | cut -f1)
echo "✓ 打包目录大小: $DIST_SIZE"
echo ""

# 步骤3: 创建目录结构
echo "=== 步骤 3: 创建目录结构 ==="
mkdir -p "$APP_DIR"
mkdir -p "$SCRIPTS_DIR"
echo "✓ 目录结构创建完成"
echo ""

# 步骤4: 复制文件
echo "=== 步骤 4: 复制文件 ==="

echo "  - 复制 PyInstaller 打包结果..."
cp -R "$DIST_DIR/"* "$APP_DIR/"
echo "    ✓ 可执行文件和依赖已复制"

echo "  - 复制 JSX 脚本..."
cp "$PROJECT_ROOT/src/慧眼去星.jsx" "$APP_DIR/"
echo "    ✓ 慧眼去星.jsx"

echo "  - 编译 GUI 安装工具..."
osacompile -o "$APP_DIR/安装到Photoshop.app" "$PROJECT_ROOT/installer/setup_photoshop_gui.scpt"
echo "    ✓ 安装到Photoshop.app (编译完成)"

APP_SIZE=$(du -sh "$APP_DIR" | cut -f1)
echo "  ✓ 应用目录大小: $APP_SIZE"
echo ""

# 步骤5: 签名所有二进制文件
echo "=== 步骤 5: 签名二进制文件 ==="

CERT_NAME="Developer ID Application: James Zhen Yu (JWR6FDB52H)"
echo "  证书: $CERT_NAME"

# 签名主可执行文件
echo "  签名主可执行文件..."
codesign --force --sign "$CERT_NAME" --timestamp --options runtime "$APP_DIR/superstaroff" 2>/dev/null || true
echo "    ✓ superstaroff"

# 签名 _internal 目录中的所有二进制文件
echo "  签名 _internal 目录中的二进制文件..."
BINARY_COUNT=0
find "$APP_DIR/_internal" -type f \( -name "*.so" -o -name "*.dylib" \) | while read binary; do
    codesign --force --sign "$CERT_NAME" --timestamp --options runtime "$binary" 2>/dev/null || true
done
echo "    ✓ 动态库签名完成"

# 签名可执行文件
find "$APP_DIR/_internal" -type f -perm +111 | while read binary; do
    if file "$binary" | grep -q "Mach-O"; then
        codesign --force --sign "$CERT_NAME" --timestamp --options runtime "$binary" 2>/dev/null || true
    fi
done
echo "    ✓ 可执行文件签名完成"

# 签名 GUI 安装工具
echo "  签名 GUI 安装工具..."
codesign --force --deep --sign "$CERT_NAME" --timestamp --options runtime "$APP_DIR/安装到Photoshop.app" 2>/dev/null || true
echo "    ✓ 安装到Photoshop.app"

echo "  ✓ 签名完成"
echo ""

# 步骤6: 创建 postinstall 脚本
echo "=== 步骤 6: 创建安装脚本 ==="

cat > "$SCRIPTS_DIR/postinstall" << 'POSTINSTALL_EOF'
#!/bin/bash

LOG_FILE="/tmp/superstaroff_install.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "==================================================="
echo "SuperStarOff - 安装核心组件"
echo "开始时间: $(date)"
echo "==================================================="
echo ""

APP_DIR="/usr/local/SuperStarOff"

# 设置权限
echo "设置权限..."
chown -R root:wheel "$APP_DIR"
chmod -R 755 "$APP_DIR"
chmod +x "$APP_DIR/superstaroff"

# 创建命令行快捷方式
echo "创建命令行快捷方式..."
mkdir -p /usr/local/bin
ln -sf "$APP_DIR/superstaroff" /usr/local/bin/superstaroff

# 扫描 Photoshop 版本
echo ""
echo "扫描已安装的 Photoshop 版本..."

PS_FOUND=""
for YEAR in 2026 2025 2024 2023 2022; do
    PS_PATH="/Applications/Adobe Photoshop $YEAR/Presets/Scripts"
    if [ -d "$PS_PATH" ]; then
        PS_FOUND="$PS_FOUND $YEAR"
    fi
done

echo ""
echo "==================================================="
echo "✅ SuperStarOff 核心组件安装完成！"
echo "==================================================="
echo ""

if [ -n "$PS_FOUND" ]; then
    echo "检测到 Photoshop 版本:$PS_FOUND"
    echo ""
    echo "即将打开安装工具，请选择要安装插件的版本..."
    echo ""
else
    echo "⚠️  未检测到已安装的 Photoshop"
    echo ""
    echo "安装 Photoshop 后，请打开以下工具安装插件:"
    echo "    /usr/local/SuperStarOff/安装到Photoshop.app"
    echo ""
fi

echo "命令行使用:"
echo "  superstaroff input.tif output.tif"
echo ""
echo "==================================================="

# 获取当前登录用户并打开 GUI 安装工具
CURRENT_USER=$(stat -f "%Su" /dev/console)
if [ -n "$CURRENT_USER" ] && [ "$CURRENT_USER" != "root" ]; then
    sudo -u "$CURRENT_USER" open "$APP_DIR/安装到Photoshop.app" &
fi

exit 0
POSTINSTALL_EOF

chmod +x "$SCRIPTS_DIR/postinstall"
echo "✓ postinstall 脚本已创建"
echo ""

# 步骤7: 构建 PKG
echo "=== 步骤 7: 构建 PKG ==="

pkgbuild --root "$PAYLOAD_DIR" \
    --scripts "$SCRIPTS_DIR" \
    --identifier "com.jameszhenyu.superstaroff" \
    --version "$VERSION" \
    --install-location "/" \
    "$BUILD_DIR/SuperStarOff-Component.pkg"

echo "✓ 组件包构建完成"
echo ""

# 步骤8: 签名 PKG
echo "=== 步骤 8: 签名安装包 ==="

INSTALLER_CERT="Developer ID Installer: James Zhen Yu (JWR6FDB52H)"

productbuild --package "$BUILD_DIR/SuperStarOff-Component.pkg" \
    --sign "$INSTALLER_CERT" \
    "$PROJECT_ROOT/installer/SuperStarOff-Installer-$VERSION.pkg"

echo "✓ 安装包签名完成"

# 计算大小
PKG_FILE="$PROJECT_ROOT/installer/SuperStarOff-Installer-$VERSION.pkg"
PKG_SIZE=$(du -h "$PKG_FILE" | cut -f1)

echo ""
echo "==================================================="
echo "✅ 构建成功！"
echo "==================================================="
echo ""
echo "版本: $VERSION"
echo "安装包: $PKG_FILE"
echo "大小: $PKG_SIZE"
echo ""
echo "下一步: 公证安装包"
echo "  xcrun notarytool submit SuperStarOff-Installer-$VERSION.pkg --keychain-profile notarytool-password --wait"
echo ""
echo "==================================================="
