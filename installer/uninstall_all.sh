#!/bin/bash
# SuperStarOff 完整卸载脚本

echo "==================================================="
echo "SuperStarOff 完整卸载程序"
echo "==================================================="
echo ""

# 检查是否以 root 运行
if [ "$EUID" -ne 0 ]; then
    echo "请使用 sudo 运行此脚本"
    echo "用法: sudo ./uninstall_all.sh"
    exit 1
fi

# 1. 删除核心安装目录
echo "1. 删除核心安装目录..."
if [ -d "/usr/local/SuperStarOff" ]; then
    rm -rf /usr/local/SuperStarOff
    echo "   ✓ 已删除 /usr/local/SuperStarOff"
else
    echo "   - /usr/local/SuperStarOff 不存在"
fi
echo ""

# 2. 删除 Photoshop 脚本
echo "2. 删除 Photoshop 脚本..."
PS_VERSIONS=("2023" "2024" "2025" "2026")
for VERSION in "${PS_VERSIONS[@]}"; do
    SCRIPT_DIR="/Applications/Adobe Photoshop $VERSION/Presets/Scripts"
    if [ -d "$SCRIPT_DIR" ]; then
        rm -f "$SCRIPT_DIR/慧眼去星.jsx" 2>/dev/null
        rm -f "$SCRIPT_DIR/SuperStarOff"* 2>/dev/null
        echo "   ✓ 已清理 Photoshop $VERSION 脚本目录"
    fi
done
echo ""

# 3. 删除用户级配置和日志
echo "3. 删除用户配置和日志..."
CURRENT_USER=$(stat -f "%Su" /dev/console)
USER_HOME=$(eval echo ~$CURRENT_USER)

if [ -d "$USER_HOME/.superstaroff" ]; then
    rm -rf "$USER_HOME/.superstaroff"
    echo "   ✓ 已删除 $USER_HOME/.superstaroff"
else
    echo "   - 用户配置目录不存在"
fi

# 4. 删除临时文件
echo ""
echo "4. 删除临时文件..."
if [ -d "$USER_HOME/Documents/.superstaroff_temp" ]; then
    rm -rf "$USER_HOME/Documents/.superstaroff_temp"
    echo "   ✓ 已删除临时文件目录"
else
    echo "   - 临时文件目录不存在"
fi

# 5. 删除命令行快捷方式
echo ""
echo "5. 删除命令行快捷方式..."
if [ -f "/usr/local/bin/superstaroff" ]; then
    rm -f /usr/local/bin/superstaroff
    echo "   ✓ 已删除 /usr/local/bin/superstaroff"
else
    echo "   - 命令行快捷方式不存在"
fi

echo ""
echo "==================================================="
echo "✅ SuperStarOff 已完全卸载！"
echo "==================================================="
echo ""
echo "提示: 请重启 Photoshop 以确保更改生效"
echo ""
