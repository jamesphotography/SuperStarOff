#!/bin/bash

# SuperStarOff - 批量签名虚拟环境中的所有二进制文件
# 这是为了通过 Apple 公证所必需的

set -e

echo "==================================================="
echo "SuperStarOff - 批量签名虚拟环境二进制文件"
echo "==================================================="
echo ""

# 配置
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VENV_DIR="$PROJECT_ROOT/.venv"
DEVELOPER_ID="Developer ID Application: James Zhen Yu (JWR6FDB52H)"

# 检查虚拟环境
if [ ! -d "$VENV_DIR" ]; then
    echo "❌ 错误: 找不到虚拟环境"
    echo "   路径: $VENV_DIR"
    exit 1
fi

echo "虚拟环境路径: $VENV_DIR"
echo "签名证书: $DEVELOPER_ID"
echo ""

# 统计需要签名的文件
echo "=== 步骤 1: 扫描需要签名的文件 ==="
echo "正在扫描..."

# 查找所有需要签名的文件类型
PYTHON_BINS=$(find "$VENV_DIR/bin" -type f -perm +111 2>/dev/null || true)
SO_FILES=$(find "$VENV_DIR/lib" -name "*.so" -type f 2>/dev/null || true)
DYLIB_FILES=$(find "$VENV_DIR/lib" -name "*.dylib" -type f 2>/dev/null || true)
FRAMEWORK_BINS=$(find "$VENV_DIR" -path "*/Versions/*/MacOS/*" -type f 2>/dev/null || true)

# 统计
PYTHON_COUNT=$(echo "$PYTHON_BINS" | grep -v "^$" | wc -l | xargs)
SO_COUNT=$(echo "$SO_FILES" | grep -v "^$" | wc -l | xargs)
DYLIB_COUNT=$(echo "$DYLIB_FILES" | grep -v "^$" | wc -l | xargs)
FRAMEWORK_COUNT=$(echo "$FRAMEWORK_BINS" | grep -v "^$" | wc -l | xargs)

TOTAL_COUNT=$((PYTHON_COUNT + SO_COUNT + DYLIB_COUNT + FRAMEWORK_COUNT))

echo "找到需要签名的文件:"
echo "  - Python 可执行文件: $PYTHON_COUNT"
echo "  - .so 库文件: $SO_COUNT"
echo "  - .dylib 库文件: $DYLIB_COUNT"
echo "  - Framework 二进制: $FRAMEWORK_COUNT"
echo "  总计: $TOTAL_COUNT 个文件"
echo ""

if [ $TOTAL_COUNT -eq 0 ]; then
    echo "✓ 没有需要签名的文件"
    exit 0
fi

# 询问确认
echo "这可能需要 10-30 分钟，具体取决于文件数量。"
echo ""

# 创建签名函数
sign_file() {
    local file="$1"
    local relative_path="${file#$VENV_DIR/}"

    # 检查文件是否已签名
    if codesign -v "$file" 2>/dev/null; then
        echo "  ⏭  跳过（已签名）: $relative_path"
        return 0
    fi

    # 签名文件
    if codesign --force --sign "$DEVELOPER_ID" \
        --options runtime \
        --timestamp \
        "$file" 2>/dev/null; then
        echo "  ✓ 已签名: $relative_path"
        return 0
    else
        echo "  ⚠️  签名失败: $relative_path"
        return 1
    fi
}

# 导出函数和变量供 xargs 使用
export -f sign_file
export DEVELOPER_ID
export VENV_DIR

# ==============================================
# 步骤 2: 签名所有文件
# ==============================================
echo "=== 步骤 2: 开始批量签名 ==="
echo ""

SIGNED_COUNT=0
FAILED_COUNT=0

# 签名 Python 可执行文件
if [ $PYTHON_COUNT -gt 0 ]; then
    echo "正在签名 Python 可执行文件 ($PYTHON_COUNT)..."
    echo "$PYTHON_BINS" | while read -r file; do
        if [ -n "$file" ] && [ -f "$file" ]; then
            if sign_file "$file"; then
                SIGNED_COUNT=$((SIGNED_COUNT + 1))
            else
                FAILED_COUNT=$((FAILED_COUNT + 1))
            fi
        fi
    done
    echo ""
fi

# 签名 .so 文件
if [ $SO_COUNT -gt 0 ]; then
    echo "正在签名 .so 库文件 ($SO_COUNT)..."
    echo "这可能需要一些时间..."

    COUNTER=0
    echo "$SO_FILES" | while read -r file; do
        if [ -n "$file" ] && [ -f "$file" ]; then
            sign_file "$file" > /dev/null 2>&1 || true
            COUNTER=$((COUNTER + 1))
            if [ $((COUNTER % 100)) -eq 0 ]; then
                echo "  进度: $COUNTER/$SO_COUNT"
            fi
        fi
    done
    echo "  完成: $SO_COUNT/$SO_COUNT"
    echo ""
fi

# 签名 .dylib 文件
if [ $DYLIB_COUNT -gt 0 ]; then
    echo "正在签名 .dylib 库文件 ($DYLIB_COUNT)..."
    echo "$DYLIB_FILES" | while read -r file; do
        if [ -n "$file" ] && [ -f "$file" ]; then
            sign_file "$file" > /dev/null 2>&1 || true
        fi
    done
    echo ""
fi

# 签名 Framework 二进制文件
if [ $FRAMEWORK_COUNT -gt 0 ]; then
    echo "正在签名 Framework 二进制文件 ($FRAMEWORK_COUNT)..."
    COUNTER=0
    echo "$FRAMEWORK_BINS" | while read -r file; do
        if [ -n "$file" ] && [ -f "$file" ]; then
            sign_file "$file" > /dev/null 2>&1 || true
            COUNTER=$((COUNTER + 1))
            if [ $((COUNTER % 10)) -eq 0 ]; then
                echo "  进度: $COUNTER/$FRAMEWORK_COUNT"
            fi
        fi
    done
    echo "  完成: $FRAMEWORK_COUNT/$FRAMEWORK_COUNT"
    echo ""
fi

# ==============================================
# 步骤 3: 验证签名
# ==============================================
echo "=== 步骤 3: 验证签名 ==="
echo "随机抽查几个文件..."
echo ""

# 验证 python3 可执行文件
if [ -f "$VENV_DIR/bin/python3" ]; then
    echo "验证: bin/python3"
    codesign -vv "$VENV_DIR/bin/python3" 2>&1 | head -3
    echo ""
fi

# 验证一个 .so 文件
SAMPLE_SO=$(find "$VENV_DIR/lib" -name "*.so" -type f | head -1)
if [ -n "$SAMPLE_SO" ]; then
    SAMPLE_NAME=$(basename "$SAMPLE_SO")
    echo "验证: $SAMPLE_NAME"
    codesign -vv "$SAMPLE_SO" 2>&1 | head -3
    echo ""
fi

# ==============================================
# 完成
# ==============================================
echo ""
echo "==================================================="
echo "✅ 批量签名完成！"
echo "==================================================="
echo ""
echo "统计信息:"
echo "  - 总文件数: $TOTAL_COUNT"
echo "  - Python 可执行文件: $PYTHON_COUNT"
echo "  - .so 库文件: $SO_COUNT"
echo "  - .dylib 库文件: $DYLIB_COUNT"
echo "  - Framework 二进制: $FRAMEWORK_COUNT"
echo ""
echo "下一步:"
echo "  1. 运行构建脚本: ./build_pkg_complete.sh --skip-gui"
echo "  2. 运行签名和公证脚本: ./sign_and_notarize.sh"
echo ""
echo "==================================================="
echo ""
