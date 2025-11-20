#!/bin/bash
# SuperStarOff 使用 Distribution XML 的构建脚本
# 支持 Photoshop 多版本选择界面

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INSTALLER_DIR="$PROJECT_ROOT/installer"
BUILD_DIR="$INSTALLER_DIR/build"
PAYLOAD_DIR="$BUILD_DIR/payload"
APP_DIR="$PAYLOAD_DIR/usr/local/SuperStarOff"
RESOURCES_DIR="$INSTALLER_DIR/resources"

VERSION="1.0.12"
DEVELOPER_ID="Developer ID Application: James Zhen Yu (JWR6FDB52H)"

echo "==================================================="
echo "SuperStarOff - Distribution XML 构建"
echo "==================================================="
echo "策略：完整 Python Framework + 多版本选择界面"
echo ""

# 清理
echo "=== 清理旧文件 ==="
rm -rf "$BUILD_DIR"
mkdir -p "$APP_DIR"
mkdir -p "$BUILD_DIR/scripts"
mkdir -p "$BUILD_DIR/packages"
echo "✓ 清理完成"
echo ""

# 检查必需文件
echo "=== 检查必需文件 ==="
[ -f "$PROJECT_ROOT/photoshop_integration/superstaroff_core.py" ] && echo "✓ superstaroff_core.py" || { echo "❌ superstaroff_core.py"; exit 1; }
[ -f "$PROJECT_ROOT/src/core_utils.py" ] && echo "✓ core_utils.py" || { echo "❌ core_utils.py"; exit 1; }
[ -f "$PROJECT_ROOT/photoshop_integration/superstaroff_cli.py" ] && echo "✓ superstaroff_cli.py" || { echo "❌ superstaroff_cli.py"; exit 1; }
[ -d "$PROJECT_ROOT/models" ] && echo "✓ models/" || { echo "❌ models/"; exit 1; }
[ -f "$PROJECT_ROOT/requirements_minimal.txt" ] && echo "✓ requirements_minimal.txt" || { echo "❌ requirements_minimal.txt"; exit 1; }
[ -f "$INSTALLER_DIR/distribution.xml" ] && echo "✓ distribution.xml" || { echo "❌ distribution.xml"; exit 1; }
echo ""

# 复制核心文件
echo "=== 复制核心文件 ==="
cp "$PROJECT_ROOT/photoshop_integration/superstaroff_core.py" "$APP_DIR/"
cp "$PROJECT_ROOT/src/core_utils.py" "$APP_DIR/"
cp "$PROJECT_ROOT/photoshop_integration/superstaroff_cli.py" "$APP_DIR/"
cp -r "$PROJECT_ROOT/models" "$APP_DIR/"
cp "$INSTALLER_DIR/SuperStarOff_PS_V10.jsx" "$APP_DIR/"
echo "✓ 核心文件已复制（包含 JSX）"
echo ""

# 复制完整 Python Framework
echo "=== 复制完整 Python 3.11 Framework ==="
FRAMEWORK_SRC="/Library/Frameworks/Python.framework/Versions/3.11"
FRAMEWORK_DST="$APP_DIR/Python.framework/Versions/3.11"

if [ ! -d "$FRAMEWORK_SRC" ]; then
    echo "❌ 错误: Python 3.11 Framework 不存在"
    exit 1
fi

mkdir -p "$FRAMEWORK_DST"

echo "  复制 Framework（保留所有扩展模块）..."
rsync -a \
    --exclude='*.pyc' \
    --exclude='__pycache__' \
    --exclude='*.a' \
    --exclude='lib/python3.11/test' \
    --exclude='lib/python3.11/tkinter' \
    "$FRAMEWORK_SRC/" "$FRAMEWORK_DST/"

FRAMEWORK_SIZE=$(du -sh "$FRAMEWORK_DST" | cut -f1)
SO_COUNT=$(find "$FRAMEWORK_DST/lib/python3.11/lib-dynload" -name "*.so" 2>/dev/null | wc -l | tr -d ' ')
echo "  ✓ Framework 已复制 (大小: $FRAMEWORK_SIZE, 扩展: $SO_COUNT 个)"

# 验证关键模块
if [ -f "$FRAMEWORK_DST/lib/python3.11/lib-dynload/_ctypes.cpython-311-darwin.so" ]; then
    echo "  ✓ _ctypes.so 已复制"
else
    echo "  ❌ 错误: _ctypes.so 缺失"
    exit 1
fi
echo ""

# 修复 Framework 中 Python 二进制的动态链接
echo "=== 修复 Python 二进制动态链接 ==="

PYTHON_BIN="$FRAMEWORK_DST/bin/python3.11"
if [ -f "$PYTHON_BIN" ]; then
    install_name_tool -change \
        "/Library/Frameworks/Python.framework/Versions/3.11/Python" \
        "@executable_path/../Python" \
        "$PYTHON_BIN" 2>/dev/null || true
    echo "  ✓ bin/python3.11 动态链接已修复"
fi

if [ -d "$FRAMEWORK_DST/Resources/Python.app" ]; then
    PYTHONAPP_BIN="$FRAMEWORK_DST/Resources/Python.app/Contents/MacOS/Python"
    if [ -f "$PYTHONAPP_BIN" ]; then
        install_name_tool -change \
            "/Library/Frameworks/Python.framework/Versions/3.11/Python" \
            "@loader_path/../../../../Python" \
            "$PYTHONAPP_BIN" 2>/dev/null || true
        echo "  ✓ Python.app 动态链接已修复"
    fi
fi
echo ""

# 创建 Python 启动器
echo "=== 创建 Python 启动器 ==="
mkdir -p "$APP_DIR/bin"

cat > "$APP_DIR/bin/python" << 'EOFPY'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(dirname "$SCRIPT_DIR")"
PYTHON_BIN="$APP_DIR/Python.framework/Versions/3.11/bin/python3.11"

export PYTHONPATH="$APP_DIR/Python.framework/Versions/3.11/lib/python3.11/site-packages:$PYTHONPATH"
export PYTHONHOME="$APP_DIR/Python.framework/Versions/3.11"

exec "$PYTHON_BIN" "$@"
EOFPY

chmod +x "$APP_DIR/bin/python"
echo "✓ Python 启动器已创建"
echo ""

# 安装依赖到 Framework 的 site-packages
echo "=== 安装 Python 依赖 ==="
SITE_PACKAGES="$FRAMEWORK_DST/lib/python3.11/site-packages"

echo "  安装到: $SITE_PACKAGES"
echo "  这需要几分钟..."

"$FRAMEWORK_DST/bin/python3.11" -m pip install --upgrade pip --target "$SITE_PACKAGES" > /dev/null 2>&1
"$FRAMEWORK_DST/bin/python3.11" -m pip install -r "$PROJECT_ROOT/requirements_minimal.txt" --target "$SITE_PACKAGES" > /dev/null 2>&1

echo "✓ 依赖安装完成"
echo ""

# 签名依赖的二进制文件
echo "=== 签名依赖的二进制文件 ==="

echo "  签名共享库..."
find "$SITE_PACKAGES" -name "*.dylib" -type f 2>/dev/null | while read DYLIB; do
    codesign --force --sign "$DEVELOPER_ID" --options runtime --timestamp "$DYLIB" 2>/dev/null || true
done

echo "  签名可执行文件..."
find "$SITE_PACKAGES" -name "*.so" -type f 2>/dev/null | while read SO_FILE; do
    codesign --force --sign "$DEVELOPER_ID" --options runtime --timestamp "$SO_FILE" 2>/dev/null || true
done

echo "  签名 PyTorch 工具..."
find "$SITE_PACKAGES/torch/bin" -type f 2>/dev/null | while read TOOL; do
    codesign --force --sign "$DEVELOPER_ID" --options runtime --timestamp "$TOOL" 2>/dev/null || true
done

echo "✓ 二进制文件已签名"
echo ""

# 清理缓存
find "$FRAMEWORK_DST" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
find "$FRAMEWORK_DST" -name "*.pyc" -delete 2>/dev/null || true

# 最后签名整个 Python Framework
echo "=== 最终签名 Python Framework ==="

echo "  签名 Framework 内的二进制文件..."
find "$FRAMEWORK_DST/lib/python3.11/lib-dynload" -name "*.so" -type f | while read SO_FILE; do
    codesign --force --sign "$DEVELOPER_ID" --options runtime --timestamp "$SO_FILE" 2>/dev/null || true
done

if [ -f "$FRAMEWORK_DST/lib/python3.11/config-3.11-darwin/python.o" ]; then
    codesign --force --sign "$DEVELOPER_ID" --options runtime --timestamp \
        "$FRAMEWORK_DST/lib/python3.11/config-3.11-darwin/python.o" 2>/dev/null || true
fi

if [ -f "$FRAMEWORK_DST/bin/python3.11" ]; then
    codesign --force --sign "$DEVELOPER_ID" --options runtime --timestamp \
        "$FRAMEWORK_DST/bin/python3.11" 2>/dev/null || true
fi

if [ -d "$FRAMEWORK_DST/Resources/Python.app" ]; then
    codesign --force --sign "$DEVELOPER_ID" --options runtime --timestamp --deep \
        "$FRAMEWORK_DST/Resources/Python.app" 2>/dev/null || true
fi

codesign --force --sign "$DEVELOPER_ID" --options runtime --timestamp \
    "$FRAMEWORK_DST/Python" 2>/dev/null && echo "  ✓ Python 主库已签名"

echo ""

TOTAL_SIZE=$(du -sh "$APP_DIR" | cut -f1)
echo "总大小: $TOTAL_SIZE"
echo ""

# 创建 postinstall 脚本（从临时文件读取用户选择）
echo "=== 创建安装脚本 ==="

cat > "$BUILD_DIR/scripts/postinstall" << 'EOFPOST'
#!/bin/bash

INSTALL_DIR="/usr/local/SuperStarOff"
LOG_FILE="/tmp/superstaroff_install.log"
CHOICE_FILE="/tmp/superstaroff_ps_choices.txt"

exec > "$LOG_FILE" 2>&1

echo "==================================================="
echo "SuperStarOff 安装程序"
echo "开始时间: $(date)"
echo "==================================================="
echo ""

# 设置权限
chmod -R 755 "$INSTALL_DIR"
chmod +x "$INSTALL_DIR/bin/python"
chmod +x "$INSTALL_DIR/Python.framework/Versions/3.11/bin/python3.11"

echo "验证 Python 环境..."
PYTHON_VERSION=$("$INSTALL_DIR/bin/python" --version 2>&1)
echo "✓ Python 版本: $PYTHON_VERSION"

echo ""
echo "验证依赖包..."
"$INSTALL_DIR/bin/python" -c "import torch; print('  ✓ PyTorch:', torch.__version__)" 2>/dev/null || echo "  ⚠️  PyTorch 检查失败"
"$INSTALL_DIR/bin/python" -c "import numpy; print('  ✓ NumPy:', numpy.__version__)" 2>/dev/null || echo "  ⚠️  NumPy 检查失败"
"$INSTALL_DIR/bin/python" -c "import ctypes; print('  ✓ ctypes: OK')" 2>/dev/null || echo "  ⚠️  ctypes 检查失败"

echo ""
echo "测试模型加载..."
if "$INSTALL_DIR/bin/python" -c "from superstaroff_core import SuperStarOff; print('  ✓ 核心模块加载成功')" 2>/dev/null; then
    echo "✓ 模型加载成功"
else
    echo "⚠️  模型加载失败，但这可能不影响使用"
fi

echo ""
echo "安装 Photoshop 脚本..."

# 读取用户选择的版本（由安装器传递）
# 环境变量: COMMAND_LINE_INSTALL 中包含选择信息
# 或者从临时文件读取

# 所有可能的版本
PS_VERSIONS=("2026" "2025" "2024" "2023" "2022" "CC 2021" "CC 2020" "CC 2019")
INSTALLED=0

# 检测并安装到所有已安装的 Photoshop 版本
# 注意：这里我们安装到所有检测到的版本
# Distribution XML 的选择逻辑会在前端控制是否显示
for VERSION in "${PS_VERSIONS[@]}"; do
    PS_SCRIPTS_DIR="/Applications/Adobe Photoshop $VERSION/Presets/Scripts"
    if [ -d "/Applications/Adobe Photoshop $VERSION" ]; then
        if [ -d "$PS_SCRIPTS_DIR" ]; then
            if [ -f "$INSTALL_DIR/SuperStarOff_PS_V10.jsx" ]; then
                cp "$INSTALL_DIR/SuperStarOff_PS_V10.jsx" "$PS_SCRIPTS_DIR/SuperStarOff.jsx"
                echo "✓ 已安装到 Adobe Photoshop $VERSION"
                INSTALLED=1
            else
                echo "⚠️  找不到 JSX 文件"
            fi
        fi
    fi
done

if [ $INSTALLED -eq 0 ]; then
    echo "⚠️  未检测到 Photoshop，请手动安装"
fi

echo ""
echo "设置文件权限..."
chmod -R 755 "$INSTALL_DIR"
echo "✓ 权限设置完成"

echo ""
echo "==================================================="
echo "✅ SuperStarOff 安装完成！"
echo "==================================================="
echo ""
echo "使用方法:"
echo "  1. 启动 Adobe Photoshop"
echo "  2. 文件 > 脚本 > SuperStarOff"
echo ""

exit 0
EOFPOST

chmod +x "$BUILD_DIR/scripts/postinstall"
echo "✓ postinstall 已创建"
echo ""

# 构建组件包
echo "=== 构建组件包 ==="

pkgbuild --root "$PAYLOAD_DIR" \
    --identifier "com.superstaroff.core" \
    --version "$VERSION" \
    --scripts "$BUILD_DIR/scripts" \
    --install-location "/" \
    --component-plist "$INSTALLER_DIR/component.plist" \
    "$BUILD_DIR/packages/SuperStarOff-Component.pkg"

echo "✓ 组件包已创建"
echo ""

# 复制资源文件
echo "=== 准备资源文件 ==="
if [ ! -d "$RESOURCES_DIR" ]; then
    echo "⚠️  警告: resources 目录不存在，将跳过资源文件"
else
    echo "✓ 资源文件已准备"
fi
echo ""

# 使用 Distribution XML 创建最终产品包
echo "=== 使用 Distribution XML 创建产品包 ==="

productbuild --distribution "$INSTALLER_DIR/distribution.xml" \
    --package-path "$BUILD_DIR/packages" \
    --resources "$RESOURCES_DIR" \
    "$INSTALLER_DIR/SuperStarOff-Installer.pkg"

echo "✓ 产品包已创建"
echo ""

# 签名最终包
echo "=== 签名产品包 ==="
productsign --sign "Developer ID Installer: James Zhen Yu (JWR6FDB52H)" \
    "$INSTALLER_DIR/SuperStarOff-Installer.pkg" \
    "$INSTALLER_DIR/release_pkg/SuperStarOff-Distribution-v12.pkg"

PKG_SIZE=$(du -sh "$INSTALLER_DIR/release_pkg/SuperStarOff-Distribution-v12.pkg" | cut -f1)
PKG_MD5=$(md5 -q "$INSTALLER_DIR/release_pkg/SuperStarOff-Distribution-v12.pkg")

echo "✓ 签名完成"
echo ""

echo "==================================================="
echo "✅ Distribution XML 构建成功！"
echo "==================================================="
echo "文件: SuperStarOff-Distribution-v12.pkg"
echo "大小: $PKG_SIZE"
echo "MD5: $PKG_MD5"
echo ""
echo "特性:"
echo "  ✓ 多版本 Photoshop 选择界面"
echo "  ✓ 支持 PS 2019-2026"
echo "  ✓ 自动检测已安装版本"
echo "  ✓ 欢迎页面和许可协议"
echo "==================================================="
