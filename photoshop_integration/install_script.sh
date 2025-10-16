#!/bin/bash

# SuperStarOff - 安装 Photoshop 脚本
# 将 JSX 脚本复制到 Photoshop 的脚本目录

echo "=================================================="
echo "SuperStarOff - Photoshop 脚本安装程序"
echo "=================================================="
echo ""

# Photoshop 脚本目录
PS_SCRIPTS_DIR="/Applications/Adobe Photoshop 2025/Presets/Scripts"

# 源文件
SOURCE_SCRIPT="$(dirname "$0")/SuperStarOff_PS.jsx"

# 检查源文件是否存在
if [ ! -f "$SOURCE_SCRIPT" ]; then
    echo "❌ 错误: 找不到源脚本文件"
    echo "   期望位置: $SOURCE_SCRIPT"
    exit 1
fi

# 检查目标目录是否存在
if [ ! -d "$PS_SCRIPTS_DIR" ]; then
    echo "❌ 错误: 找不到 Photoshop 脚本目录"
    echo "   期望位置: $PS_SCRIPTS_DIR"
    echo ""
    echo "请确认:"
    echo "1. Adobe Photoshop 2025 已安装"
    echo "2. 或修改脚本中的 PS_SCRIPTS_DIR 变量为正确的路径"
    exit 1
fi

echo "源文件: $SOURCE_SCRIPT"
echo "目标目录: $PS_SCRIPTS_DIR"
echo ""

# 复制文件
echo "正在安装脚本..."
cp "$SOURCE_SCRIPT" "$PS_SCRIPTS_DIR/SuperStarOff.jsx"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 安装成功!"
    echo ""
    echo "=================================================="
    echo "使用方法:"
    echo "=================================================="
    echo ""
    echo "1. 重启 Adobe Photoshop"
    echo "2. 在 Photoshop 中打开一张星空图片"
    echo "3. 选择菜单: 文件 > 脚本 > SuperStarOff"
    echo "4. 等待处理完成（30秒-2分钟）"
    echo "5. 新图层会自动创建"
    echo ""
    echo "=================================================="
    echo ""
    echo "脚本位置: $PS_SCRIPTS_DIR/SuperStarOff.jsx"
    echo ""
    echo "如需卸载，删除该文件即可。"
    echo ""
else
    echo ""
    echo "❌ 安装失败!"
    echo ""
    echo "可能的原因:"
    echo "1. 没有权限写入 Photoshop 目录"
    echo "2. Photoshop 正在运行（请先关闭）"
    echo ""
    echo "尝试使用 sudo:"
    echo "  sudo $0"
    echo ""
    exit 1
fi
