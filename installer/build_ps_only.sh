#!/bin/bash
set -e

echo "==================================================="
echo "SuperStarOff - Photoshop插件轻量级安装包"
echo "==================================================="
echo ""

PROJECT_ROOT="/Users/jameszhenyu/PycharmProjects/SuperStarOff"
BUILD_DIR="$PROJECT_ROOT/installer/build"
PAYLOAD_DIR="$BUILD_DIR/payload"
SCRIPTS_DIR="$BUILD_DIR/scripts"
APP_DIR="$PAYLOAD_DIR/usr/local/SuperStarOff"

echo "项目根目录: $PROJECT_ROOT"
echo ""

# 步骤1: 清理
echo "=== 步骤 1: 清理旧的构建文件 ==="
rm -rf "$BUILD_DIR/SuperStarOff-PS-Only.pkg" "$PAYLOAD_DIR" "$SCRIPTS_DIR" 2>/dev/null || true
echo "✓ 清理完成"
echo ""

# 步骤2: 检查必需文件
echo "=== 步骤 2: 检查必需文件 ==="
if [ ! -f "$PROJECT_ROOT/photoshop_integration/SuperStarOff_PS.jsx" ]; then
    echo "❌ 错误: 找不到 SuperStarOff_PS.jsx"
    exit 1
fi
echo "✓ SuperStarOff_PS.jsx 存在"

if [ ! -f "$PROJECT_ROOT/photoshop_integration/superstaroff_core.py" ]; then
    echo "❌ 错误: 找不到 superstaroff_core.py"
    exit 1
fi
echo "✓ superstaroff_core.py 存在"

if [ ! -f "$PROJECT_ROOT/src/core_utils.py" ]; then
    echo "❌ 错误: 找不到 core_utils.py"
    exit 1
fi
echo "✓ core_utils.py 存在"

if [ ! -f "$PROJECT_ROOT/models/SuperStarOff2025.pt" ]; then
    echo "❌ 错误: 找不到模型文件"
    exit 1
fi
MODEL_SIZE=$(du -h "$PROJECT_ROOT/models/SuperStarOff2025.pt" | cut -f1)
echo "✓ 模型文件存在 (大小: $MODEL_SIZE)"

if [ ! -f "$PROJECT_ROOT/photoshop_integration/superstaroff_cli.py" ]; then
    echo "❌ 错误: 找不到 superstaroff_cli.py"
    exit 1
fi
echo "✓ superstaroff_cli.py 存在"
echo ""

# 步骤3: 创建目录结构
echo "=== 步骤 3: 创建目录结构 ==="
mkdir -p "$APP_DIR"
mkdir -p "$SCRIPTS_DIR"
echo "✓ 目录结构创建完成"
echo ""

# 步骤4: 复制核心文件（不包含GUI）
echo "=== 步骤 4: 复制核心文件 ==="
echo "  - 复制核心 Python 模块..."
cp "$PROJECT_ROOT/photoshop_integration/superstaroff_core.py" "$APP_DIR/"
echo "    ✓ 已复制: superstaroff_core.py"

cp "$PROJECT_ROOT/src/core_utils.py" "$APP_DIR/"
echo "    ✓ 已复制: core_utils.py"

echo "  - 复制 models 目录..."
cp -r "$PROJECT_ROOT/models" "$APP_DIR/"
echo "    ✓ 已复制: models/ ($MODEL_SIZE)"

echo "  - 复制 CLI 脚本..."
cp "$PROJECT_ROOT/photoshop_integration/superstaroff_cli.py" "$APP_DIR/"
echo "    ✓ 已复制: superstaroff_cli.py"

echo "  - 复制 JSX 脚本..."
cp "$PROJECT_ROOT/photoshop_integration/SuperStarOff_PS.jsx" "$APP_DIR/"
echo "    ✓ 已复制: SuperStarOff_PS.jsx"

echo "  - 打包 Python framework (真正独立)..."
# 使用 Python.org Python
PYTHON_BIN="/Library/Frameworks/Python.framework/Versions/3.11/bin/python3"
if [ ! -f "$PYTHON_BIN" ]; then
    echo "❌ 错误: 找不到 Python.org Python 3.11"
    echo "请从 https://www.python.org 安装 Python 3.11"
    exit 1
fi

# 创建 Python framework 目录
mkdir -p "$APP_DIR/Python.framework/Versions/3.11"

echo "    复制 Python framework（这需要几分钟）..."
# 复制整个 Python framework
rsync -a --exclude='*.pyc' --exclude='__pycache__' \
    /Library/Frameworks/Python.framework/Versions/3.11/ \
    "$APP_DIR/Python.framework/Versions/3.11/"

FRAMEWORK_SIZE=$(du -sh "$APP_DIR/Python.framework" | cut -f1)
echo "    ✓ Python framework 已打包 (大小: $FRAMEWORK_SIZE)"

echo "  - 创建独立的虚拟环境..."

echo "    使用 Python.org Python 3.11"
PYTHON_VERSION=$($PYTHON_BIN --version)
echo "    Python 版本: $PYTHON_VERSION"

echo "    创建虚拟环境..."
$PYTHON_BIN -m venv "$APP_DIR/.venv" --copies
echo "    ✓ 虚拟环境独立，不依赖 conda"

# 验证虚拟环境的 base prefix
VENV_PREFIX=$("$APP_DIR/.venv/bin/python" -c "import sys; print(sys.base_prefix)")
echo "    Base prefix: $VENV_PREFIX"

echo "    升级 pip..."
"$APP_DIR/.venv/bin/python" -m pip install --upgrade pip > /dev/null 2>&1

echo "    安装依赖（这需要几分钟）..."
"$APP_DIR/.venv/bin/pip" install -r "$PROJECT_ROOT/requirements.txt" > /dev/null 2>&1

VENV_SIZE=$(du -sh "$APP_DIR/.venv" | cut -f1)
echo "    ✓ 虚拟环境创建完成 (大小: $VENV_SIZE)"

# 签名虚拟环境中的二进制文件
echo ""
echo "  - 签名虚拟环境中的二进制文件（这需要几分钟）..."
echo "    正在扫描和签名..."

CERT_NAME="Developer ID Application: James Zhen Yu (JWR6FDB52H)"
SIGNED_COUNT=0

# 查找并签名所有二进制文件
find "$APP_DIR/.venv" -type f \( -name "*.so" -o -name "*.dylib" -o -perm +111 \) | while read binary; do
    # 检查是否是真正的二进制文件
    if file "$binary" | grep -q "Mach-O"; then
        codesign --force --sign "$CERT_NAME" --timestamp --options runtime "$binary" 2>/dev/null || true
        SIGNED_COUNT=$((SIGNED_COUNT + 1))
    fi
done

echo "    ✓ 二进制文件签名完成"
echo ""

# 步骤5: 创建安装脚本
echo "=== 步骤 5: 创建安装脚本 ==="
cat > "$SCRIPTS_DIR/postinstall" << 'POSTINSTALL_EOF'
#!/bin/bash

LOG_FILE="/tmp/superstaroff_install.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "==================================================="
echo "SuperStarOff - 安装 Photoshop 插件"
echo "开始时间: $(date)"
echo "==================================================="
echo ""

# 步骤1: 安装 Python framework 到系统目录
echo "=== 步骤 1: 安装 Python framework ==="
FRAMEWORK_SOURCE="/usr/local/SuperStarOff/Python.framework"
FRAMEWORK_TARGET="/Library/Frameworks/Python.framework"

if [ -d "$FRAMEWORK_SOURCE" ]; then
    echo "正在安装 Python 3.11 framework..."

    # 创建目标目录
    mkdir -p "$FRAMEWORK_TARGET/Versions"

    # 复制 framework
    rsync -a "$FRAMEWORK_SOURCE/Versions/3.11/" "$FRAMEWORK_TARGET/Versions/3.11/"

    # 创建符号链接（如果不存在）
    if [ ! -e "$FRAMEWORK_TARGET/Versions/Current" ]; then
        ln -sf 3.11 "$FRAMEWORK_TARGET/Versions/Current"
    fi

    echo "✓ Python framework 已安装到 $FRAMEWORK_TARGET"
else
    echo "⚠️  警告: Python framework 未找到，虚拟环境可能无法工作"
fi
echo ""

# 步骤2: 安装 JSX 脚本到系统级目录（所有用户可用）
echo "=== 步骤 2: 安装 JSX 脚本 ==="

# JSX 源文件
JSX_SOURCE="/usr/local/SuperStarOff/SuperStarOff_PS.jsx"

# 检查 JSX 文件是否存在
if [ ! -f "$JSX_SOURCE" ]; then
    echo "❌ 错误: JSX 文件不存在: $JSX_SOURCE"
    exit 1
fi
echo "✓ 找到 JSX 文件: $JSX_SOURCE"
echo ""

# 系统级 Photoshop Scripts 目录（所有用户共享）
PS_DIRS=(
    "/Library/Application Support/Adobe/Adobe Photoshop 2025/Presets/Scripts"
    "/Library/Application Support/Adobe/Adobe Photoshop 2024/Presets/Scripts"
    "/Library/Application Support/Adobe/Adobe Photoshop 2023/Presets/Scripts"
    "/Library/Application Support/Adobe/Adobe Photoshop 2022/Presets/Scripts"
)

echo "正在安装 JSX 脚本到系统级目录（所有用户可用）..."
INSTALLED=0

for PS_DIR in "${PS_DIRS[@]}"; do
    # 检查 Photoshop 版本是否存在
    PS_VERSION_DIR="$(dirname "$(dirname "$PS_DIR")")"

    if [ -d "$PS_VERSION_DIR" ]; then
        echo "  找到 Photoshop: $PS_VERSION_DIR"

        # 创建 Scripts 目录
        mkdir -p "$PS_DIR"

        # 复制 JSX 文件
        cp "$JSX_SOURCE" "$PS_DIR/SuperStarOff_PS.jsx"

        # 设置权限（所有用户可读）
        chown root:wheel "$PS_DIR/SuperStarOff_PS.jsx"
        chmod 644 "$PS_DIR/SuperStarOff_PS.jsx"

        echo "  ✓ JSX 已安装到: $PS_DIR/SuperStarOff_PS.jsx"
        INSTALLED=$((INSTALLED + 1))
    fi
done

echo ""
if [ $INSTALLED -eq 0 ]; then
    echo "⚠️  警告: 未找到 Photoshop 安装"
    echo ""
    echo "请手动安装 JSX 脚本："
    echo "  1. 复制: $JSX_SOURCE"
    echo "  2. 到: /Library/Application Support/Adobe/Adobe Photoshop 202X/Presets/Scripts/"
    echo ""
else
    echo "✓ JSX 脚本已安装到 $INSTALLED 个 Photoshop 版本（系统级，所有用户可用）"
fi

# 设置 SuperStarOff 目录权限
echo "设置权限..."
chown -R root:wheel /usr/local/SuperStarOff
chmod -R 755 /usr/local/SuperStarOff
chmod 644 /usr/local/SuperStarOff/SuperStarOff_PS.jsx
echo "✓ 权限设置完成"
echo ""

echo "==================================================="
echo "✅ SuperStarOff 安装完成！"
echo "==================================================="
echo ""
echo "安装位置:"
echo "  核心文件: /usr/local/SuperStarOff/"
if [ $INSTALLED -gt 0 ]; then
    echo "  JSX 脚本: Photoshop Scripts 目录"
fi
echo ""
echo "使用方法:"
echo "  1. 重启 Adobe Photoshop"
echo "  2. 打开星空图片"
echo "  3. 菜单: 文件 > 脚本 > SuperStarOff_PS"
echo "  4. 选择参数，等待处理完成"
echo ""
echo "日志文件: $LOG_FILE"
echo "==================================================="
echo ""

exit 0
POSTINSTALL_EOF

chmod +x "$SCRIPTS_DIR/postinstall"
echo "✓ postinstall 脚本已创建"
echo ""

# 步骤6: 创建卸载脚本
echo "=== 步骤 6: 创建卸载脚本 ==="
cat > "$BUILD_DIR/uninstall.sh" << 'UNINSTALL_EOF'
#!/bin/bash

echo "==================================================="
echo "SuperStarOff Photoshop插件 - 卸载程序"
echo "==================================================="
echo ""

# 检查是否以 root 运行
if [ "$EUID" -ne 0 ]; then
    echo "❌ 请使用 sudo 运行此脚本"
    echo "用法: sudo ./uninstall.sh"
    exit 1
fi

# 删除核心文件
echo "正在删除核心文件..."
if [ -d "/usr/local/SuperStarOff" ]; then
    rm -rf /usr/local/SuperStarOff
    echo "✓ 已删除: /usr/local/SuperStarOff"
fi

# 删除 JSX 脚本
echo ""
echo "正在删除 Photoshop 脚本..."
CURRENT_USER=$(stat -f "%Su" /dev/console)
USER_HOME=$(eval echo ~$CURRENT_USER)

PS_DIRS=(
    "$USER_HOME/Library/Application Support/Adobe/Adobe Photoshop 2024/Presets/Scripts"
    "$USER_HOME/Library/Application Support/Adobe/Adobe Photoshop 2023/Presets/Scripts"
    "$USER_HOME/Library/Application Support/Adobe/Adobe Photoshop 2022/Presets/Scripts"
)

for PS_DIR in "${PS_DIRS[@]}"; do
    if [ -f "$PS_DIR/SuperStarOff_PS.jsx" ]; then
        rm -f "$PS_DIR/SuperStarOff_PS.jsx"
        echo "✓ 已删除: $PS_DIR/SuperStarOff_PS.jsx"
    fi
done

echo ""
echo "✓ SuperStarOff 已完全卸载"
echo ""

exit 0
UNINSTALL_EOF

chmod +x "$BUILD_DIR/uninstall.sh"
echo "✓ uninstall.sh 脚本已创建"
echo ""

# 步骤7: 构建 PKG
echo "=== 步骤 7: 构建 PKG 组件 ==="
pkgbuild --root "$PAYLOAD_DIR" \
    --scripts "$SCRIPTS_DIR" \
    --identifier "com.jameszhenyu.superstaroff.ps" \
    --version "1.0.0" \
    --install-location "/" \
    "$BUILD_DIR/SuperStarOff-PS-Component.pkg"

echo "✓ 组件包构建完成"
echo ""

# 步骤8: 创建最终安装包
echo "=== 步骤 8: 创建最终安装包 ==="
productbuild --package "$BUILD_DIR/SuperStarOff-PS-Component.pkg" \
    "$PROJECT_ROOT/installer/SuperStarOff-PS-Only.pkg"

echo "✓ 最终安装包创建完成"
echo ""
echo ""

# 计算大小
PKG_SIZE=$(du -h "$PROJECT_ROOT/installer/SuperStarOff-PS-Only.pkg" | cut -f1)

echo "==================================================="
echo "✅ Photoshop插件安装包构建成功！"
echo "==================================================="
echo ""
echo "安装包信息:"
echo "  文件: $PROJECT_ROOT/installer/SuperStarOff-PS-Only.pkg"
echo "  大小: $PKG_SIZE"
echo "  版本: 1.0.0"
echo ""
echo "包含内容:"
echo "  • Photoshop JSX 脚本"
echo "  • Python 核心模块 (core_utils.py)"
echo "  • 加密模型文件"
echo "  • CLI 工具"
echo "  • 独立虚拟环境"
echo ""
echo "不包含:"
echo "  ✗ GUI 应用 (减少 6GB)"
echo ""
echo "卸载脚本:"
echo "  位置: $BUILD_DIR/uninstall.sh"
echo "  使用: sudo $BUILD_DIR/uninstall.sh"
echo ""
echo "用户安装方法:"
echo "  1. 双击 SuperStarOff-PS-Only.pkg"
echo "  2. 按照提示完成安装"
echo "  3. 重启 Photoshop"
echo ""
echo "==================================================="
echo ""
