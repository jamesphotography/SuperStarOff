#!/bin/bash
# SuperStarOff - Photoshop 版本选择安装脚本
# 运行方式: /usr/local/SuperStarOff/setup_photoshop.sh

APP_DIR="/usr/local/SuperStarOff"
JSX_SOURCE="$APP_DIR/慧眼去星.jsx"

echo ""
echo "==================================================="
echo "  慧眼去星 - Photoshop 插件安装"
echo "==================================================="
echo ""

# 检查 JSX 文件
if [ ! -f "$JSX_SOURCE" ]; then
    echo "错误: 找不到 JSX 脚本文件"
    echo "   请确保 SuperStarOff 已正确安装"
    exit 1
fi

# 扫描已安装的 Photoshop 版本
echo "正在扫描已安装的 Photoshop 版本..."
echo ""

PS_VERSIONS=()
PS_PATHS=()

for YEAR in 2026 2025 2024 2023 2022; do
    PS_PATH="/Applications/Adobe Photoshop $YEAR"
    SCRIPT_PATH="$PS_PATH/Presets/Scripts"

    if [ -d "$PS_PATH" ] && [ -d "$SCRIPT_PATH" ]; then
        PS_VERSIONS+=("$YEAR")
        PS_PATHS+=("$SCRIPT_PATH")
    fi
done

# 检查是否找到 Photoshop
if [ ${#PS_VERSIONS[@]} -eq 0 ]; then
    echo "未找到已安装的 Adobe Photoshop"
    echo ""
    echo "请确保 Photoshop 已安装在 /Applications 目录"
    echo "支持的版本: 2022, 2023, 2024, 2025, 2026"
    echo ""
    exit 1
fi

# 显示找到的版本
echo "找到以下 Photoshop 版本:"
echo ""
for i in "${!PS_VERSIONS[@]}"; do
    INDEX=$((i + 1))
    YEAR="${PS_VERSIONS[$i]}"

    if [ -f "${PS_PATHS[$i]}/慧眼去星.jsx" ]; then
        echo "  $INDEX. Photoshop $YEAR [已安装]"
    else
        echo "  $INDEX. Photoshop $YEAR"
    fi
done
echo ""
echo "  A. 安装到所有版本"
echo "  Q. 退出"
echo ""

# 获取用户选择
read -p "请选择要安装的版本 (输入数字、A 或 Q): " CHOICE

case "$CHOICE" in
    [Qq])
        echo ""
        echo "已取消安装"
        exit 0
        ;;
    [Aa])
        echo ""
        echo "正在安装到所有 Photoshop 版本..."
        for i in "${!PS_VERSIONS[@]}"; do
            YEAR="${PS_VERSIONS[$i]}"
            TARGET="${PS_PATHS[$i]}/慧眼去星.jsx"
            if sudo cp "$JSX_SOURCE" "$TARGET" 2>/dev/null; then
                sudo chmod 644 "$TARGET"
                echo "  Photoshop $YEAR - 安装成功"
            else
                echo "  Photoshop $YEAR - 安装失败 (权限不足?)"
            fi
        done
        ;;
    [1-9])
        INDEX=$((CHOICE - 1))
        if [ $INDEX -ge 0 ] && [ $INDEX -lt ${#PS_VERSIONS[@]} ]; then
            YEAR="${PS_VERSIONS[$INDEX]}"
            TARGET="${PS_PATHS[$INDEX]}/慧眼去星.jsx"
            echo ""
            echo "正在安装到 Photoshop $YEAR..."
            if sudo cp "$JSX_SOURCE" "$TARGET" 2>/dev/null; then
                sudo chmod 644 "$TARGET"
                echo "  安装成功"
            else
                echo "  安装失败，请尝试使用 sudo 运行此脚本"
                exit 1
            fi
        else
            echo ""
            echo "无效的选择"
            exit 1
        fi
        ;;
    *)
        echo ""
        echo "无效的选择"
        exit 1
        ;;
esac

echo ""
echo "==================================================="
echo "安装完成!"
echo "==================================================="
echo ""
echo "使用方法:"
echo "  1. 重启 Adobe Photoshop"
echo "  2. 打开星空图片"
echo "  3. 菜单: 文件 > 脚本 > 慧眼去星"
echo ""
