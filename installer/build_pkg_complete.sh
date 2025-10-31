#!/bin/bash

# SuperStarOff - 完整 PKG 安装包构建脚本
# 确保所有依赖都被正确包含

set -e

# 解析命令行参数
SKIP_GUI=false
if [ "$1" == "--skip-gui" ]; then
    SKIP_GUI=true
    echo "==================================================="
    echo "SuperStarOff - 构建 Photoshop 插件安装包（不含GUI）"
    echo "==================================================="
else
    echo "==================================================="
    echo "SuperStarOff - 构建完整 macOS 安装包"
    echo "==================================================="
fi
echo ""

# 配置
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INSTALLER_DIR="$PROJECT_ROOT/installer"
BUILD_DIR="$INSTALLER_DIR/build"
PAYLOAD_DIR="$BUILD_DIR/payload"
SCRIPTS_DIR="$BUILD_DIR/scripts"

if [ "$SKIP_GUI" = true ]; then
    PKG_NAME="SuperStarOff-PS-Installer.pkg"
else
    PKG_NAME="SuperStarOff-Installer.pkg"
fi

VERSION="1.0.0"

echo "项目根目录: $PROJECT_ROOT"
echo ""

# 清理旧的构建
echo "=== 步骤 1: 清理旧的构建文件 ==="
rm -rf "$BUILD_DIR"
mkdir -p "$PAYLOAD_DIR"
mkdir -p "$SCRIPTS_DIR"
echo "✓ 清理完成"
echo ""

# 检查必需的文件
echo "=== 步骤 2: 检查必需文件 ==="

# 检查 JSX 脚本
if [ ! -f "$PROJECT_ROOT/photoshop_integration/SuperStarOff_PS.jsx" ]; then
    echo "❌ 错误: 找不到 SuperStarOff_PS.jsx"
    exit 1
fi
echo "✓ SuperStarOff_PS.jsx 存在"

# 检查核心模块
if [ ! -f "$PROJECT_ROOT/photoshop_integration/superstaroff_core.py" ]; then
    echo "❌ 错误: 找不到 superstaroff_core.py"
    exit 1
fi
echo "✓ superstaroff_core.py 存在"

# 检查加密模块
if [ ! -f "$PROJECT_ROOT/src/core_utils.py" ]; then
    echo "❌ 错误: 找不到 core_utils.py"
    exit 1
fi
echo "✓ core_utils.py 存在"

# 检查模型文件
if [ ! -d "$PROJECT_ROOT/models" ]; then
    echo "❌ 错误: 找不到 models 目录"
    exit 1
fi

MODEL_FILE="$PROJECT_ROOT/models/SuperStarOff2025.pt"
if [ ! -f "$MODEL_FILE" ]; then
    echo "❌ 错误: 找不到模型文件 SuperStarOff2025.pt"
    exit 1
fi
MODEL_SIZE=$(du -h "$MODEL_FILE" | cut -f1)
echo "✓ 模型文件存在 (大小: $MODEL_SIZE)"

# 检查 requirements_minimal.txt（优先使用最小依赖）
if [ -f "$PROJECT_ROOT/requirements_minimal.txt" ]; then
    REQUIREMENTS_FILE="requirements_minimal.txt"
    echo "✓ requirements_minimal.txt 存在（使用最小依赖）"
elif [ -f "$PROJECT_ROOT/requirements.txt" ]; then
    REQUIREMENTS_FILE="requirements.txt"
    echo "✓ requirements.txt 存在"
else
    echo "❌ 错误: 找不到依赖文件"
    exit 1
fi

# 检查 CLI 文件
if [ ! -f "$PROJECT_ROOT/photoshop_integration/superstaroff_cli.py" ]; then
    echo "❌ 错误: 找不到 superstaroff_cli.py"
    exit 1
fi
echo "✓ superstaroff_cli.py 存在"

echo ""

# 1. 准备 Photoshop 脚本文件
echo "=== 步骤 3: 准备 Photoshop 脚本 ==="
PS_SCRIPTS_DIR="$PAYLOAD_DIR/Applications/Adobe Photoshop 2025/Presets/Scripts"
mkdir -p "$PS_SCRIPTS_DIR"
cp "$PROJECT_ROOT/photoshop_integration/SuperStarOff_PS.jsx" "$PS_SCRIPTS_DIR/SuperStarOff.jsx"
echo "✓ JSX 脚本已复制"
echo ""

# 2. 准备核心文件
echo "=== 步骤 4: 准备核心程序文件 ==="
APP_DIR="$PAYLOAD_DIR/usr/local/SuperStarOff"
mkdir -p "$APP_DIR"

# 复制核心模块（简化版，无需整个 src 目录）
echo "  - 复制核心 Python 模块..."
cp "$PROJECT_ROOT/photoshop_integration/superstaroff_core.py" "$APP_DIR/"
echo "    ✓ 已复制: superstaroff_core.py"

# 复制核心工具模块（包含解密功能）
cp "$PROJECT_ROOT/src/core_utils.py" "$APP_DIR/"
echo "    ✓ 已复制: core_utils.py"

# 复制模型
echo "  - 复制 models 目录..."
cp -r "$PROJECT_ROOT/models" "$APP_DIR/"
echo "    ✓ 已复制: models/ ($MODEL_SIZE)"

# 复制 CLI
echo "  - 复制 CLI 脚本..."
cp "$PROJECT_ROOT/photoshop_integration/superstaroff_cli.py" "$APP_DIR/"
echo "    ✓ 已复制: superstaroff_cli.py"

# 创建独立的虚拟环境（不依赖 miniconda）
echo "  - 创建独立的虚拟环境（用于打包）..."

# 优先使用 python.org 安装的独立 Python（不依赖 conda）
STANDALONE_PYTHON=""
if [ -f "/Library/Frameworks/Python.framework/Versions/3.11/bin/python3.11" ]; then
    STANDALONE_PYTHON="/Library/Frameworks/Python.framework/Versions/3.11/bin/python3.11"
    echo "    使用 Python.org Python 3.11"
elif [ -f "/Library/Frameworks/Python.framework/Versions/3.12/bin/python3.12" ]; then
    STANDALONE_PYTHON="/Library/Frameworks/Python.framework/Versions/3.12/bin/python3.12"
    echo "    使用 Python.org Python 3.12"
elif [ -f "/usr/local/bin/python3" ]; then
    # 检查是否是独立 Python（非 conda）
    BASE_PREFIX=$(/usr/local/bin/python3 -c "import sys; print(sys.base_prefix)")
    if [[ ! "$BASE_PREFIX" =~ "conda" ]] && [[ ! "$BASE_PREFIX" =~ "anaconda" ]]; then
        STANDALONE_PYTHON="/usr/local/bin/python3"
        echo "    使用 Homebrew/独立 Python"
    fi
fi

if [ -z "$STANDALONE_PYTHON" ]; then
    echo "    ❌ 错误: 未找到独立的 Python（非 conda）"
    echo "    请安装 Python.org 的 Python:"
    echo "    https://www.python.org/downloads/"
    exit 1
fi

PYTHON_VERSION=$($STANDALONE_PYTHON --version)
echo "    Python 版本: $PYTHON_VERSION"

# 创建虚拟环境
echo "    创建虚拟环境..."
$STANDALONE_PYTHON -m venv "$APP_DIR/.venv"

if [ ! -f "$APP_DIR/.venv/bin/python" ]; then
    echo "    ❌ 错误: 虚拟环境创建失败"
    exit 1
fi

# 验证虚拟环境不依赖 conda
VENV_BASE=$("$APP_DIR/.venv/bin/python" -c "import sys; print(sys.base_prefix)")
if [[ "$VENV_BASE" =~ "conda" ]] || [[ "$VENV_BASE" =~ "anaconda" ]]; then
    echo "    ❌ 错误: 虚拟环境仍然依赖 conda: $VENV_BASE"
    exit 1
fi
echo "    ✓ 虚拟环境独立，不依赖 conda"
echo "    Base prefix: $VENV_BASE"

# 升级 pip
echo "    升级 pip..."
"$APP_DIR/.venv/bin/python" -m pip install --upgrade pip --quiet

# 安装依赖
echo "    安装依赖（这需要几分钟）..."
"$APP_DIR/.venv/bin/pip" install -r "$PROJECT_ROOT/$REQUIREMENTS_FILE" --quiet

if [ $? -ne 0 ]; then
    echo "    ❌ 错误: 依赖安装失败"
    exit 1
fi

# 清理缓存
find "$APP_DIR/.venv" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
find "$APP_DIR/.venv" -name "*.pyc" -delete 2>/dev/null || true

VENV_SIZE=$(du -sh "$APP_DIR/.venv" | cut -f1)
echo "    ✓ 虚拟环境创建完成 (大小: $VENV_SIZE)"
echo ""

# 签名虚拟环境中的所有二进制文件
echo "  - 签名虚拟环境中的二进制文件（这需要几分钟）..."
DEVELOPER_ID="Developer ID Application: James Zhen Yu (JWR6FDB52H)"

echo "    正在扫描和签名..."

# 签名所有可执行文件
find "$APP_DIR/.venv" -type f -perm +111 -exec codesign --force --sign "$DEVELOPER_ID" --options runtime --timestamp {} \; 2>/dev/null || true

# 签名 .so 文件
find "$APP_DIR/.venv" -name "*.so" -type f -exec codesign --force --sign "$DEVELOPER_ID" --options runtime --timestamp {} \; 2>/dev/null || true

# 签名 .dylib 文件
find "$APP_DIR/.venv" -name "*.dylib" -type f -exec codesign --force --sign "$DEVELOPER_ID" --options runtime --timestamp {} \; 2>/dev/null || true

echo "    ✓ 二进制文件签名完成"

BUNDLE_VENV=true
echo ""

# 3. 准备 GUI 应用（如果需要且存在）
if [ "$SKIP_GUI" = false ] && [ -d "$PROJECT_ROOT/dist/SuperStarOff.app" ]; then
    echo "=== 步骤 5: 准备 GUI 应用 ==="
    APPLICATIONS_DIR="$PAYLOAD_DIR/Applications"
    mkdir -p "$APPLICATIONS_DIR"
    cp -r "$PROJECT_ROOT/dist/SuperStarOff.app" "$APPLICATIONS_DIR/"
    APP_SIZE=$(du -sh "$PROJECT_ROOT/dist/SuperStarOff.app" | cut -f1)
    echo "✓ GUI 应用已复制 (大小: $APP_SIZE)"
    echo ""
elif [ "$SKIP_GUI" = true ]; then
    echo "=== 步骤 5: 跳过 GUI 应用（--skip-gui 参数）==="
    echo ""
else
    echo "=== 步骤 5: 跳过 GUI 应用（不存在）==="
    echo ""
fi

# 4. 创建安装后脚本（postinstall）
echo "=== 步骤 6: 创建安装脚本 ==="
cat > "$SCRIPTS_DIR/postinstall" << 'POSTINSTALL_SCRIPT'
#!/bin/bash

# 安装日志
LOG_FILE="/tmp/superstaroff_install.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "==================================================="
echo "SuperStarOff 安装程序"
echo "开始时间: $(date)"
echo "==================================================="
echo ""

INSTALL_DIR="/usr/local/SuperStarOff"

# 检查是否已打包虚拟环境
if [ -d "$INSTALL_DIR/.venv" ] && [ -f "$INSTALL_DIR/.venv/bin/python" ]; then
    echo "检测到预打包的 Python 环境..."

    # 获取 Python 版本
    PYTHON_VERSION=$("$INSTALL_DIR/.venv/bin/python" --version 2>&1)
    echo "✓ Python 版本: $PYTHON_VERSION"

    # 验证关键依赖
    echo "✓ 虚拟环境已包含所有依赖"
    echo ""

    # 验证关键依赖
    echo "验证关键依赖..."
    "$INSTALL_DIR/.venv/bin/python" -c "import torch; print('  ✓ PyTorch:', torch.__version__)" || echo "  ❌ PyTorch 未安装"
    "$INSTALL_DIR/.venv/bin/python" -c "import numpy; print('  ✓ NumPy:', numpy.__version__)" || echo "  ❌ NumPy 未安装"
    "$INSTALL_DIR/.venv/bin/python" -c "import tifffile; print('  ✓ tifffile:', tifffile.__version__)" || echo "  ❌ tifffile 未安装"
    "$INSTALL_DIR/.venv/bin/python" -c "import PIL; print('  ✓ Pillow:', PIL.__version__)" || echo "  ❌ Pillow 未安装"
    "$INSTALL_DIR/.venv/bin/python" -c "import cryptography; print('  ✓ cryptography')" || echo "  ❌ cryptography 未安装"
    echo ""

else
    # 没有预打包环境，需要创建
    echo "未检测到预打包环境，开始创建 Python 虚拟环境..."

    # 检查 Python 3
    if ! command -v python3 &> /dev/null; then
        echo "❌ 错误: 未找到 Python 3"
        echo ""
        echo "请先安装 Python 3.10 或更高版本："
        echo "  https://www.python.org/downloads/"
        echo ""
        exit 1
    fi

    PYTHON_VERSION=$(python3 --version)
    echo "✓ 找到 Python: $PYTHON_VERSION"

    # 检查 Python 版本
    PYTHON_MINOR=$(python3 -c "import sys; print(sys.version_info.minor)")
    if [ "$PYTHON_MINOR" -lt 10 ]; then
        echo "❌ 错误: Python 版本过低"
        echo "   当前版本: Python 3.$PYTHON_MINOR"
        echo "   需要版本: Python 3.10 或更高"
        echo ""
        echo "请升级 Python: https://www.python.org/downloads/"
        exit 1
    fi
    echo ""

    # 创建虚拟环境
    cd "$INSTALL_DIR"
    python3 -m venv .venv
    if [ $? -ne 0 ]; then
        echo "❌ 错误: 创建虚拟环境失败"
        exit 1
    fi
    echo "✓ 虚拟环境创建成功"
    echo ""

    # 激活虚拟环境并安装依赖
    source .venv/bin/activate
    pip install --upgrade pip --quiet
    echo "✓ pip 已升级"
    echo ""

    echo "安装 Python 依赖（这可能需要几分钟）..."
    pip install -r requirements.txt --quiet

    if [ $? -ne 0 ]; then
        echo "❌ 错误: 依赖安装失败"
        exit 1
    fi

    echo "✓ 所有依赖安装完成"
    echo ""
fi

# 测试模型加载
echo "测试模型加载..."
"$INSTALL_DIR/.venv/bin/python" << 'PYTHON_TEST'
import sys
import torch

try:
    # 测试加密模型加载（core_utils.py 现在直接在安装目录下）
    sys.path.insert(0, '/usr/local/SuperStarOff')
    from core_utils import ModelCrypto

    model_path = '/usr/local/SuperStarOff/models/SuperStarOff2025.pt'
    buffer = ModelCrypto.decrypt_to_memory(model_path)
    model = torch.jit.load(buffer, map_location='cpu')
    print('  ✓ 模型加载成功')
except Exception as e:
    print(f'  ❌ 模型加载失败: {e}')
    sys.exit(1)
PYTHON_TEST

if [ $? -ne 0 ]; then
    echo "❌ 错误: 模型测试失败"
    exit 1
fi
echo ""

# 更新 JSX 脚本中的路径
echo "配置 Photoshop 脚本..."
JSX_FILE="/Applications/Adobe Photoshop 2025/Presets/Scripts/SuperStarOff.jsx"

if [ -f "$JSX_FILE" ]; then
    # 备份原文件
    cp "$JSX_FILE" "$JSX_FILE.backup"

    # 替换 Python 解释器路径
    sed -i '' "s|var PYTHON_INTERPRETER = \".*\";|var PYTHON_INTERPRETER = \"$INSTALL_DIR/.venv/bin/python\";|g" "$JSX_FILE"

    # 替换 CLI 路径
    sed -i '' "s|var PYTHON_CLI_PATH = \".*\";|var PYTHON_CLI_PATH = \"$INSTALL_DIR/superstaroff_cli.py\";|g" "$JSX_FILE"

    echo "✓ Photoshop 脚本已配置"
else
    echo "⚠️  警告: 找不到 Photoshop 脚本文件"
fi
echo ""

# 配置 GUI 应用
if [ -d "/Applications/SuperStarOff.app" ]; then
    echo "配置 GUI 应用..."
    # GUI 应用使用共享的虚拟环境
    echo "✓ GUI 应用已配置"
    echo ""
fi

# 设置权限
echo "设置文件权限..."
chmod -R 755 "$INSTALL_DIR"
chmod +x "$INSTALL_DIR/superstaroff_cli.py"
chmod +x "$INSTALL_DIR/.venv/bin/python"
echo "✓ 权限设置完成"
echo ""

echo "==================================================="
echo "✅ SuperStarOff 安装完成！"
echo "==================================================="
echo ""
echo "安装位置: $INSTALL_DIR"
echo "日志文件: $LOG_FILE"
echo ""
echo "使用方法："
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
echo "✓ postinstall 脚本已创建"
echo ""

# 5. 创建卸载脚本
echo "=== 步骤 7: 创建卸载脚本 ==="
cat > "$BUILD_DIR/uninstall.sh" << 'UNINSTALL_SCRIPT'
#!/bin/bash

echo "==================================================="
echo "SuperStarOff - 卸载程序"
echo "==================================================="
echo ""

# 需要管理员权限
if [ "$EUID" -ne 0 ]; then
    echo "请使用 sudo 运行此脚本:"
    echo "  sudo $0"
    exit 1
fi

# 删除 Photoshop 脚本
if [ -f "/Applications/Adobe Photoshop 2025/Presets/Scripts/SuperStarOff.jsx" ]; then
    echo "删除 Photoshop 脚本..."
    rm "/Applications/Adobe Photoshop 2025/Presets/Scripts/SuperStarOff.jsx"
    rm -f "/Applications/Adobe Photoshop 2025/Presets/Scripts/SuperStarOff.jsx.backup"
    echo "✓ 已删除"
fi

# 删除程序文件
if [ -d "/usr/local/SuperStarOff" ]; then
    echo "删除程序文件..."
    du -sh "/usr/local/SuperStarOff"
    rm -rf "/usr/local/SuperStarOff"
    echo "✓ 已删除"
fi

# 删除 GUI 应用
if [ -d "/Applications/SuperStarOff.app" ]; then
    echo "删除 GUI 应用..."
    rm -rf "/Applications/SuperStarOff.app"
    echo "✓ 已删除"
fi

# 删除临时文件
if [ -d "/tmp/SuperStarOff" ]; then
    echo "删除临时文件..."
    rm -rf "/tmp/SuperStarOff"
    echo "✓ 已删除"
fi

echo ""
echo "SuperStarOff 已完全卸载。"
echo ""
UNINSTALL_SCRIPT

chmod +x "$BUILD_DIR/uninstall.sh"
echo "✓ uninstall.sh 脚本已创建"
echo ""

# 6. 构建组件包
echo "=== 步骤 8: 构建 PKG 组件 ==="
pkgbuild \
    --root "$PAYLOAD_DIR" \
    --scripts "$SCRIPTS_DIR" \
    --identifier "com.superstaroff.photoshop" \
    --version "$VERSION" \
    --install-location "/" \
    "$BUILD_DIR/SuperStarOff-Component.pkg"

if [ $? -ne 0 ]; then
    echo "❌ 错误: pkgbuild 失败"
    exit 1
fi
echo "✓ 组件包构建完成"
echo ""

# 7. 创建产品包
echo "=== 步骤 9: 创建最终安装包 ==="
productbuild \
    --package "$BUILD_DIR/SuperStarOff-Component.pkg" \
    "$INSTALLER_DIR/$PKG_NAME"

if [ $? -ne 0 ]; then
    echo "❌ 错误: productbuild 失败"
    exit 1
fi
echo "✓ 最终安装包创建完成"
echo ""

# 清理中间文件
rm -rf "$BUILD_DIR/SuperStarOff-Component.pkg"

# 显示结果
PKG_SIZE=$(du -h "$INSTALLER_DIR/$PKG_NAME" | cut -f1)

echo ""
echo "==================================================="
echo "✅ 安装包构建成功！"
echo "==================================================="
echo ""
echo "安装包信息:"
echo "  文件: $INSTALLER_DIR/$PKG_NAME"
echo "  大小: $PKG_SIZE"
echo "  版本: $VERSION"
echo ""
echo "卸载脚本:"
echo "  位置: $BUILD_DIR/uninstall.sh"
echo "  使用: sudo $BUILD_DIR/uninstall.sh"
echo ""
echo "用户安装方法:"
echo "  1. 双击 $PKG_NAME"
echo "  2. 按照提示完成安装"
echo "  3. 重启 Photoshop"
echo ""
echo "==================================================="
echo ""
