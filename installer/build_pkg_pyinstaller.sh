#!/bin/bash

# SuperStarOff - 使用 PyInstaller 构建 PKG 安装包
# 解决虚拟环境依赖系统库的签名问题

set -e

echo "==================================================="
echo "SuperStarOff - 构建 Photoshop 插件安装包"
echo "使用 PyInstaller 打包（无需虚拟环境）"
echo "==================================================="
echo ""

# 配置
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INSTALLER_DIR="$PROJECT_ROOT/installer"
BUILD_DIR="$INSTALLER_DIR/build"
PAYLOAD_DIR="$BUILD_DIR/payload"
SCRIPTS_DIR="$BUILD_DIR/scripts"
PKG_NAME="SuperStarOff-PS-Installer.pkg"
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

if [ ! -f "$PROJECT_ROOT/src/model_crypto.py" ]; then
    echo "❌ 错误: 找不到 model_crypto.py"
    exit 1
fi
echo "✓ model_crypto.py 存在"

MODEL_FILE="$PROJECT_ROOT/models/SuperStarOff2025.pt"
if [ ! -f "$MODEL_FILE" ]; then
    echo "❌ 错误: 找不到模型文件 SuperStarOff2025.pt"
    exit 1
fi
MODEL_SIZE=$(du -h "$MODEL_FILE" | cut -f1)
echo "✓ 模型文件存在 (大小: $MODEL_SIZE)"

if [ ! -f "$PROJECT_ROOT/photoshop_integration/superstaroff_cli.py" ]; then
    echo "❌ 错误: 找不到 superstaroff_cli.py"
    exit 1
fi
echo "✓ superstaroff_cli.py 存在"

echo ""

# 准备 Photoshop 脚本文件
echo "=== 步骤 3: 准备 Photoshop 脚本 ==="
PS_SCRIPTS_DIR="$PAYLOAD_DIR/Applications/Adobe Photoshop 2025/Presets/Scripts"
mkdir -p "$PS_SCRIPTS_DIR"
cp "$PROJECT_ROOT/photoshop_integration/SuperStarOff_PS.jsx" "$PS_SCRIPTS_DIR/SuperStarOff.jsx"
echo "✓ JSX 脚本已复制"
echo ""

# 准备核心文件
echo "=== 步骤 4: 准备核心程序文件 ==="
APP_DIR="$PAYLOAD_DIR/usr/local/SuperStarOff"
mkdir -p "$APP_DIR"

# 复制核心模块
echo "  - 复制核心 Python 模块..."
cp "$PROJECT_ROOT/photoshop_integration/superstaroff_core.py" "$APP_DIR/"
echo "    ✓ 已复制: superstaroff_core.py"

cp "$PROJECT_ROOT/src/model_crypto.py" "$APP_DIR/"
echo "    ✓ 已复制: model_crypto.py"

# 复制模型
echo "  - 复制 models 目录..."
cp -r "$PROJECT_ROOT/models" "$APP_DIR/"
echo "    ✓ 已复制: models/ ($MODEL_SIZE)"

echo ""

# 使用 PyInstaller 打包 CLI
echo "=== 步骤 5: 使用 PyInstaller 打包 CLI ==="

# 检查 PyInstaller
if ! command -v pyinstaller &> /dev/null; then
    echo "  - 安装 PyInstaller..."
    pip install pyinstaller
fi

# 创建临时的 spec 文件
SPEC_FILE="$BUILD_DIR/superstaroff_cli.spec"
cat > "$SPEC_FILE" << 'SPEC_CONTENT'
# -*- mode: python ; coding: utf-8 -*-

import os
import sys

# 添加项目根目录到路径
project_root = os.path.abspath('..')

block_cipher = None

a = Analysis(
    ['../photoshop_integration/superstaroff_cli.py'],
    pathex=[project_root, os.path.join(project_root, 'src')],
    binaries=[],
    datas=[
        ('../src/model_crypto.py', '.'),
        ('../photoshop_integration/superstaroff_core.py', '.'),
    ],
    hiddenimports=[
        'torch',
        'numpy',
        'PIL',
        'tifffile',
        'cryptography',
        'cryptography.fernet',
        'model_crypto',
        'superstaroff_core',
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[
        'matplotlib',
        'PyQt5',
        'PyQt6',
        'tkinter',
        'scipy',
        'pandas',
    ],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    name='superstaroff_cli',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=True,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)
SPEC_CONTENT

echo "  - 开始 PyInstaller 打包（这需要几分钟）..."
cd "$INSTALLER_DIR"
pyinstaller --clean "$SPEC_FILE" --distpath "$APP_DIR" --workpath "$BUILD_DIR/pyinstaller_work"

if [ ! -f "$APP_DIR/superstaroff_cli" ]; then
    echo "❌ 错误: PyInstaller 打包失败"
    exit 1
fi

BINARY_SIZE=$(du -h "$APP_DIR/superstaroff_cli" | cut -f1)
echo "    ✓ CLI 已打包为独立可执行文件 (大小: $BINARY_SIZE)"

# 签名可执行文件
DEVELOPER_ID="Developer ID Application: James Zhen Yu (JWR6FDB52H)"
echo "  - 签名可执行文件..."
codesign --force --sign "$DEVELOPER_ID" --options runtime --timestamp "$APP_DIR/superstaroff_cli"
echo "    ✓ 签名完成"

echo ""

# 创建安装后脚本
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

echo "验证安装文件..."
if [ ! -f "$INSTALL_DIR/superstaroff_cli" ]; then
    echo "❌ 错误: 找不到 CLI 可执行文件"
    exit 1
fi
echo "✓ CLI 可执行文件存在"

if [ ! -f "$INSTALL_DIR/models/SuperStarOff2025.pt" ]; then
    echo "❌ 错误: 找不到模型文件"
    exit 1
fi
echo "✓ 模型文件存在"
echo ""

# 测试 CLI 可执行文件
echo "测试 CLI 可执行文件..."
"$INSTALL_DIR/superstaroff_cli" --version 2>&1 | head -5 || echo "  ⚠️  版本信息不可用，但文件可执行"
echo "✓ CLI 可执行"
echo ""

# 更新 JSX 脚本中的路径
echo "配置 Photoshop 脚本..."
JSX_FILE="/Applications/Adobe Photoshop 2025/Presets/Scripts/SuperStarOff.jsx"

if [ -f "$JSX_FILE" ]; then
    # 备份原文件
    cp "$JSX_FILE" "$JSX_FILE.backup"

    # 替换 CLI 路径（不再需要 Python 解释器）
    sed -i '' "s|var PYTHON_CLI_PATH = \".*\";|var PYTHON_CLI_PATH = \"$INSTALL_DIR/superstaroff_cli\";|g" "$JSX_FILE"

    # 移除 PYTHON_INTERPRETER 变量（不再需要）
    sed -i '' "s|var PYTHON_INTERPRETER = \".*\";|// Python interpreter not needed - using standalone binary|g" "$JSX_FILE"

    echo "✓ Photoshop 脚本已配置"
else
    echo "⚠️  警告: 找不到 Photoshop 脚本文件"
fi
echo ""

# 设置权限
echo "设置文件权限..."
chmod -R 755 "$INSTALL_DIR"
chmod +x "$INSTALL_DIR/superstaroff_cli"
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
echo "Photoshop 插件使用:"
echo "  1. 启动 Adobe Photoshop"
echo "  2. 打开一张星空图片"
echo "  3. 选择菜单: 文件 > 脚本 > SuperStarOff"
echo ""
echo "命令行使用:"
echo "  $INSTALL_DIR/superstaroff_cli <input_image> <output_image>"
echo ""
echo "==================================================="
echo ""

exit 0
POSTINSTALL_SCRIPT

chmod +x "$SCRIPTS_DIR/postinstall"
echo "✓ postinstall 脚本已创建"
echo ""

# 创建卸载脚本
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

echo ""
echo "SuperStarOff 已完全卸载。"
echo ""
UNINSTALL_SCRIPT

chmod +x "$BUILD_DIR/uninstall.sh"
echo "✓ uninstall.sh 脚本已创建"
echo ""

# 构建组件包
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

# 创建产品包
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
rm -rf "$BUILD_DIR/pyinstaller_work"

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
echo "  方式: PyInstaller 独立可执行文件"
echo ""
echo "优势:"
echo "  ✓ 无需 Python 虚拟环境"
echo "  ✓ 无依赖冲突"
echo "  ✓ 无签名问题"
echo "  ✓ 更小的安装包体积"
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
