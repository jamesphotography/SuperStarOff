#!/bin/bash

# SuperStarOff - PKG 安装包构建脚本
# 此脚本会创建一个 macOS .pkg 安装包

set -e

echo "==================================================="
echo "SuperStarOff - 构建 macOS 安装包"
echo "==================================================="
echo ""

# 配置
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INSTALLER_DIR="$PROJECT_ROOT/installer"
BUILD_DIR="$INSTALLER_DIR/build"
PAYLOAD_DIR="$BUILD_DIR/payload"
SCRIPTS_DIR="$BUILD_DIR/scripts"
PKG_NAME="SuperStarOff-Installer.pkg"
VERSION="1.0.0"

# 清理旧的构建
echo "清理旧的构建文件..."
rm -rf "$BUILD_DIR"
mkdir -p "$PAYLOAD_DIR"
mkdir -p "$SCRIPTS_DIR"

# 1. 准备 Photoshop 脚本文件
echo "准备 Photoshop 脚本..."
PS_SCRIPTS_DIR="$PAYLOAD_DIR/Applications/Adobe Photoshop 2025/Presets/Scripts"
mkdir -p "$PS_SCRIPTS_DIR"
cp "$PROJECT_ROOT/photoshop_integration/SuperStarOff_PS.jsx" "$PS_SCRIPTS_DIR/SuperStarOff.jsx"

# 2. 准备 Python CLI 和依赖
echo "准备 Python 程序..."
APP_DIR="$PAYLOAD_DIR/usr/local/SuperStarOff"
mkdir -p "$APP_DIR"

# 复制必要的 Python 文件
cp -r "$PROJECT_ROOT/src" "$APP_DIR/"
cp -r "$PROJECT_ROOT/models" "$APP_DIR/"
cp "$PROJECT_ROOT/photoshop_integration/superstaroff_cli.py" "$APP_DIR/"
cp "$PROJECT_ROOT/requirements.txt" "$APP_DIR/"

# 3. 准备 GUI 应用（如果存在）
if [ -d "$PROJECT_ROOT/dist/SuperStarOff.app" ]; then
    echo "准备 GUI 应用..."
    APPLICATIONS_DIR="$PAYLOAD_DIR/Applications"
    mkdir -p "$APPLICATIONS_DIR"
    cp -r "$PROJECT_ROOT/dist/SuperStarOff.app" "$APPLICATIONS_DIR/"

    # 修改 app 中的路径，指向共享的安装目录
    # 这样 GUI 和 JSX 都使用同一套文件
fi

# 3. 创建安装后脚本（postinstall）
echo "创建安装脚本..."
cat > "$SCRIPTS_DIR/postinstall" << 'POSTINSTALL_SCRIPT'
#!/bin/bash

echo "正在安装 SuperStarOff..."

# 安装 Python 依赖
INSTALL_DIR="/usr/local/SuperStarOff"

# 检查是否有 Python 3
if ! command -v python3 &> /dev/null; then
    echo "错误: 未找到 Python 3，请先安装 Python 3.8 或更高版本"
    exit 1
fi

# 创建虚拟环境
echo "创建 Python 虚拟环境..."
cd "$INSTALL_DIR"
python3 -m venv .venv

# 激活虚拟环境并安装依赖
echo "安装 Python 依赖..."
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# 更新 JSX 脚本中的路径
echo "配置 Photoshop 脚本..."
JSX_FILE="/Applications/Adobe Photoshop 2025/Presets/Scripts/SuperStarOff.jsx"
if [ -f "$JSX_FILE" ]; then
    # 替换 Python 解释器路径
    sed -i '' "s|var PYTHON_INTERPRETER = \".*\";|var PYTHON_INTERPRETER = \"$INSTALL_DIR/.venv/bin/python\";|g" "$JSX_FILE"
    # 替换 CLI 路径
    sed -i '' "s|var PYTHON_CLI_PATH = \".*\";|var PYTHON_CLI_PATH = \"$INSTALL_DIR/superstaroff_cli.py\";|g" "$JSX_FILE"
fi

# 配置 GUI 应用（如果存在）
if [ -d "/Applications/SuperStarOff.app" ]; then
    echo "配置 GUI 应用..."
    # GUI 应用也使用共享的虚拟环境和模型
    # 这样只需要维护一份模型文件
fi

echo "SuperStarOff 安装完成！"
echo ""
echo "==================================================="
echo "使用方法："
echo "==================================================="
echo ""
echo "方式 1: Photoshop 插件"
echo "  1. 启动 Adobe Photoshop"
echo "  2. 打开一张星空图片"
echo "  3. 选择菜单: 文件 > 脚本 > SuperStarOff"
echo ""
if [ -d "/Applications/SuperStarOff.app" ]; then
    echo "方式 2: 独立 GUI 应用"
    echo "  1. 在应用程序中找到 SuperStarOff"
    echo "  2. 双击打开"
    echo "  3. 拖拽图片处理"
    echo ""
fi
echo "==================================================="
echo ""

exit 0
POSTINSTALL_SCRIPT

chmod +x "$SCRIPTS_DIR/postinstall"

# 4. 创建卸载脚本
echo "创建卸载脚本..."
cat > "$BUILD_DIR/uninstall.sh" << 'UNINSTALL_SCRIPT'
#!/bin/bash

echo "==================================================="
echo "SuperStarOff - 卸载程序"
echo "==================================================="
echo ""

# 删除 Photoshop 脚本
if [ -f "/Applications/Adobe Photoshop 2025/Presets/Scripts/SuperStarOff.jsx" ]; then
    echo "删除 Photoshop 脚本..."
    rm "/Applications/Adobe Photoshop 2025/Presets/Scripts/SuperStarOff.jsx"
fi

# 删除程序文件
if [ -d "/usr/local/SuperStarOff" ]; then
    echo "删除程序文件..."
    rm -rf "/usr/local/SuperStarOff"
fi

# 删除 GUI 应用
if [ -d "/Applications/SuperStarOff.app" ]; then
    echo "删除 GUI 应用..."
    rm -rf "/Applications/SuperStarOff.app"
fi

echo ""
echo "SuperStarOff 已完全卸载。"
echo ""
UNINSTALL_SCRIPT

chmod +x "$BUILD_DIR/uninstall.sh"

# 5. 构建 PKG 包
echo "构建 PKG 安装包..."
pkgbuild \
    --root "$PAYLOAD_DIR" \
    --scripts "$SCRIPTS_DIR" \
    --identifier "com.superstaroff.photoshop" \
    --version "$VERSION" \
    --install-location "/" \
    "$BUILD_DIR/SuperStarOff-Component.pkg"

# 6. 创建产品包（带欢迎界面等）
echo "创建最终安装包..."
productbuild \
    --package "$BUILD_DIR/SuperStarOff-Component.pkg" \
    "$INSTALLER_DIR/$PKG_NAME"

# 清理中间文件
rm -rf "$BUILD_DIR/SuperStarOff-Component.pkg"

echo ""
echo "==================================================="
echo "✅ 安装包构建完成！"
echo "==================================================="
echo ""
echo "安装包位置: $INSTALLER_DIR/$PKG_NAME"
echo ""
echo "用户可以双击此文件进行安装。"
echo ""
echo "卸载脚本: $BUILD_DIR/uninstall.sh"
echo "用户可以运行此脚本卸载 SuperStarOff。"
echo ""
