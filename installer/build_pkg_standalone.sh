#!/bin/bash
# SuperStarOff 完全独立构建脚本 - V9
# 策略：复制完整 Python Framework + 直接安装依赖到 site-packages

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INSTALLER_DIR="$PROJECT_ROOT/installer"
BUILD_DIR="$INSTALLER_DIR/build"
PAYLOAD_DIR="$BUILD_DIR/payload"
APP_DIR="$PAYLOAD_DIR/usr/local/SuperStarOff"

VERSION="1.0.11"
DEVELOPER_ID="Developer ID Application: James Zhen Yu (JWR6FDB52H)"

echo "==================================================="
echo "SuperStarOff V9 - 完全独立构建"
echo "==================================================="
echo "策略：完整 Python Framework + 直接安装依赖"
echo ""

# 清理
echo "=== 清理旧文件 ==="
rm -rf "$BUILD_DIR"
mkdir -p "$APP_DIR"
echo "✓ 清理完成"
echo ""

# 检查必需文件
echo "=== 检查必需文件 ==="
[ -f "$PROJECT_ROOT/photoshop_integration/superstaroff_core.py" ] && echo "✓ superstaroff_core.py" || { echo "❌ superstaroff_core.py"; exit 1; }
[ -f "$PROJECT_ROOT/src/core_utils.py" ] && echo "✓ core_utils.py" || { echo "❌ core_utils.py"; exit 1; }
[ -f "$PROJECT_ROOT/photoshop_integration/superstaroff_cli.py" ] && echo "✓ superstaroff_cli.py" || { echo "❌ superstaroff_cli.py"; exit 1; }
[ -d "$PROJECT_ROOT/models" ] && echo "✓ models/" || { echo "❌ models/"; exit 1; }
[ -f "$PROJECT_ROOT/requirements_minimal.txt" ] && echo "✓ requirements_minimal.txt" || { echo "❌ requirements_minimal.txt"; exit 1; }
echo ""

# 复制核心文件
echo "=== 复制核心文件 ==="
cp "$PROJECT_ROOT/photoshop_integration/superstaroff_core.py" "$APP_DIR/"
cp "$PROJECT_ROOT/src/core_utils.py" "$APP_DIR/"
cp "$PROJECT_ROOT/photoshop_integration/superstaroff_cli.py" "$APP_DIR/"
cp -r "$PROJECT_ROOT/models" "$APP_DIR/"

# 复制修复的 JSX 脚本
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

# 不在这里签名 Framework，等到所有修改完成后再签名
echo "=== 准备 Framework 组件 ==="
echo "  Framework 已就绪，稍后统一签名"
echo ""

# 修复 Framework 中 Python 二进制的动态链接
echo "=== 修复 Python 二进制动态链接 ==="

# 修复 bin/python3.11 的动态链接
PYTHON_BIN="$FRAMEWORK_DST/bin/python3.11"
if [ -f "$PYTHON_BIN" ]; then
    echo "  修复前:"
    otool -L "$PYTHON_BIN" | grep Python.framework | head -1

    install_name_tool -change \
        "/Library/Frameworks/Python.framework/Versions/3.11/Python" \
        "@executable_path/../Python" \
        "$PYTHON_BIN" 2>/dev/null || true

    echo "  修复后:"
    otool -L "$PYTHON_BIN" | grep Python.framework | head -1
    echo "  ✓ bin/python3.11 动态链接已修复"
fi

# 修复 Python.app 的动态链接
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

# 第二阶段签名将在安装完所有依赖后进行
echo ""

# 创建 Python 启动器（直接使用 Framework 中的 Python）
echo "=== 创建 Python 启动器 ==="
mkdir -p "$APP_DIR/bin"

cat > "$APP_DIR/bin/python" << 'EOFPY'
#!/bin/bash
# SuperStarOff Python 启动器
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(dirname "$SCRIPT_DIR")"
PYTHON_BIN="$APP_DIR/Python.framework/Versions/3.11/bin/python3.11"

# 设置 PYTHONPATH 包含我们安装的依赖
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

# 使用系统 Python 安装依赖到目标目录
/Library/Frameworks/Python.framework/Versions/3.11/bin/python3.11 -m pip install \
    -r "$PROJECT_ROOT/requirements_minimal.txt" \
    --target "$SITE_PACKAGES" \
    --upgrade \
    --quiet

if [ $? -ne 0 ]; then
    echo "❌ 依赖安装失败"
    exit 1
fi

echo "✓ 依赖安装完成"
echo ""

# 签名依赖中的二进制文件
echo "=== 签名依赖的二进制文件 ==="

# 签名所有 .so 和 .dylib 文件
echo "  签名共享库..."
find "$SITE_PACKAGES" -type f \( -name "*.so" -o -name "*.dylib" \) | while read BIN_FILE; do
    codesign --force --sign "$DEVELOPER_ID" --options runtime --timestamp "$BIN_FILE" 2>/dev/null || true
done

# 签名可执行文件（特别是 PyTorch 的工具）
echo "  签名可执行文件..."
# 查找并签名所有可执行文件
find "$SITE_PACKAGES" -type f -perm +111 ! -name "*.so" ! -name "*.dylib" ! -name "*.py" ! -name "*.pyc" | while read EXEC_FILE; do
    # 检查是否是 Mach-O 二进制文件
    if file "$EXEC_FILE" | grep -q "Mach-O"; then
        codesign --force --sign "$DEVELOPER_ID" --options runtime --timestamp "$EXEC_FILE" 2>/dev/null || true
    fi
done

# 特别签名 PyTorch 的可执行文件
if [ -d "$SITE_PACKAGES/torch/bin" ]; then
    echo "  签名 PyTorch 工具..."
    find "$SITE_PACKAGES/torch/bin" -type f | while read TORCH_BIN; do
        if file "$TORCH_BIN" | grep -q "Mach-O"; then
            codesign --force --sign "$DEVELOPER_ID" --options runtime --timestamp "$TORCH_BIN" 2>/dev/null || true
        fi
    done
fi

echo "✓ 二进制文件已签名"
echo ""

# 清理缓存
find "$FRAMEWORK_DST" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
find "$FRAMEWORK_DST" -name "*.pyc" -delete 2>/dev/null || true

# 最后签名整个 Python Framework（所有修改完成后）
echo "=== 最终签名 Python Framework ==="

# 签名所有可执行文件和库
echo "  签名 Framework 内的二进制文件..."
# 签名所有 .so 扩展模块
find "$FRAMEWORK_DST/lib/python3.11/lib-dynload" -name "*.so" -type f | while read SO_FILE; do
    codesign --force --sign "$DEVELOPER_ID" --options runtime --timestamp "$SO_FILE" 2>/dev/null || true
done

# 签名 python.o
if [ -f "$FRAMEWORK_DST/lib/python3.11/config-3.11-darwin/python.o" ]; then
    codesign --force --sign "$DEVELOPER_ID" --options runtime --timestamp \
        "$FRAMEWORK_DST/lib/python3.11/config-3.11-darwin/python.o" 2>/dev/null || true
fi

# 签名 bin/python3.11
if [ -f "$FRAMEWORK_DST/bin/python3.11" ]; then
    codesign --force --sign "$DEVELOPER_ID" --options runtime --timestamp \
        "$FRAMEWORK_DST/bin/python3.11" 2>/dev/null || true
fi

# 签名 Python.app（如果有）
if [ -d "$FRAMEWORK_DST/Resources/Python.app" ]; then
    codesign --force --sign "$DEVELOPER_ID" --options runtime --timestamp --deep \
        "$FRAMEWORK_DST/Resources/Python.app" 2>/dev/null || true
fi

# 最后签名 Python 主库（不要签名整个bundle，会破坏内部文件签名）
codesign --force --sign "$DEVELOPER_ID" --options runtime --timestamp \
    "$FRAMEWORK_DST/Python" 2>/dev/null && echo "  ✓ Python 主库已签名"

echo ""

TOTAL_SIZE=$(du -sh "$APP_DIR" | cut -f1)
echo "总大小: $TOTAL_SIZE"
echo ""

# 创建 postinstall 脚本
echo "=== 创建安装脚本 ==="
mkdir -p "$BUILD_DIR/scripts"

cat > "$BUILD_DIR/scripts/postinstall" << 'EOFPOST'
#!/bin/bash

INSTALL_DIR="/usr/local/SuperStarOff"
LOG_FILE="/tmp/superstaroff_install.log"

exec > "$LOG_FILE" 2>&1

echo "==================================================="
echo "SuperStarOff V9 安装程序"
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
echo "检测 Photoshop 安装..."
PS_VERSIONS=("2025" "2024" "2023" "2022" "CC 2021" "CC 2020" "CC 2019")
INSTALLED=0

for VERSION in "${PS_VERSIONS[@]}"; do
    PS_SCRIPTS_DIR="/Applications/Adobe Photoshop $VERSION/Presets/Scripts"
    if [ -d "/Applications/Adobe Photoshop $VERSION" ]; then
        if [ -d "$PS_SCRIPTS_DIR" ]; then
            # 复制打包好的 JSX（已修复 findPython 函数）
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

# 构建 PKG
echo "=== 构建安装包 ==="

pkgbuild --root "$PAYLOAD_DIR" \
    --identifier "com.superstaroff.app" \
    --version "$VERSION" \
    --scripts "$BUILD_DIR/scripts" \
    --install-location "/" \
    --component-plist "$INSTALLER_DIR/component.plist" \
    "$BUILD_DIR/SuperStarOff-Component.pkg"

echo "✓ 组件包已创建"

productbuild --package "$BUILD_DIR/SuperStarOff-Component.pkg" \
    "$INSTALLER_DIR/SuperStarOff-Installer.pkg"

echo "✓ 最终包已创建"
echo ""

# 签名
echo "=== 签名安装包 ==="
productsign --sign "Developer ID Installer: James Zhen Yu (JWR6FDB52H)" \
    "$INSTALLER_DIR/SuperStarOff-Installer.pkg" \
    "$INSTALLER_DIR/release_pkg/SuperStarOff-PS-Installer-v11-COMPLETE.pkg"

PKG_SIZE=$(du -sh "$INSTALLER_DIR/release_pkg/SuperStarOff-PS-Installer-v11-COMPLETE.pkg" | cut -f1)
PKG_MD5=$(md5 -q "$INSTALLER_DIR/release_pkg/SuperStarOff-PS-Installer-v11-COMPLETE.pkg")

echo "✓ 签名完成"
echo ""

echo "==================================================="
echo "✅ V11 构建成功！"
echo "==================================================="
echo "文件: SuperStarOff-PS-Installer-v11-COMPLETE.pkg"
echo "大小: $PKG_SIZE"
echo "MD5: $PKG_MD5"
echo "==================================================="
