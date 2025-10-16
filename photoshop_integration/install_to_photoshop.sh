#!/bin/bash
# 安装 SuperStarOff Photoshop 脚本

echo "慧眼去星 - Photoshop 集成安装脚本"
echo "=================================="
echo ""

# 查找 Photoshop 安装目录
PS_DIRS=(
    "/Applications/Adobe Photoshop 2024"
    "/Applications/Adobe Photoshop 2023"
    "/Applications/Adobe Photoshop 2022"
    "/Applications/Adobe Photoshop CC 2021"
    "/Applications/Adobe Photoshop CC 2020"
)

PS_DIR=""
for dir in "${PS_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        PS_DIR="$dir"
        echo "✓ 找到 Photoshop: $PS_DIR"
        break
    fi
done

if [ -z "$PS_DIR" ]; then
    echo "✗ 未找到 Photoshop 安装目录"
    echo ""
    echo "请手动复制文件到 Photoshop Scripts 目录："
    echo "  源文件: $(pwd)/SuperStarOff_PS.jsx"
    echo "  目标目录: /Applications/Adobe Photoshop [版本]/Presets/Scripts/"
    exit 1
fi

# Scripts 目录
SCRIPTS_DIR="$PS_DIR/Presets/Scripts"

if [ ! -d "$SCRIPTS_DIR" ]; then
    echo "✗ Scripts 目录不存在: $SCRIPTS_DIR"
    exit 1
fi

# 复制脚本
SOURCE_FILE="$(pwd)/SuperStarOff_PS.jsx"
TARGET_FILE="$SCRIPTS_DIR/SuperStarOff_PS.jsx"

echo ""
echo "正在安装..."
echo "  源文件: $SOURCE_FILE"
echo "  目标文件: $TARGET_FILE"
echo ""

if [ ! -f "$SOURCE_FILE" ]; then
    echo "✗ 源文件不存在: $SOURCE_FILE"
    exit 1
fi

# 复制文件
cp "$SOURCE_FILE" "$TARGET_FILE"

if [ $? -eq 0 ]; then
    echo "✓ 安装成功！"
    echo ""
    echo "下一步："
    echo "1. 重启 Photoshop"
    echo "2. 在 Photoshop 中选择: 文件 > 脚本 > SuperStarOff_PS"
    echo "3. 或设置快捷键: 编辑 > 键盘快捷键 > 文件 > 脚本 > SuperStarOff_PS"
    echo ""
    echo "提示: 在运行脚本前，请确保："
    echo "  - Python 环境已正确配置"
    echo "  - 模型文件存在: models/SuperStarOff2025.pt"
    echo "  - 已安装依赖: pip install torch torchvision tifffile pillow numpy"
else
    echo "✗ 安装失败"
    echo ""
    echo "可能需要管理员权限，请尝试："
    echo "  sudo $0"
fi
