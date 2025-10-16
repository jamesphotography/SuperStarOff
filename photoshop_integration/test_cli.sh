#!/bin/bash
# 测试 SuperStarOff CLI 工具

echo "慧眼去星 CLI 工具测试"
echo "===================="
echo ""

# 测试文件
TEST_INPUT="examples/海豚星云-Sh2-308-S-4天数据.jpg"
TEST_OUTPUT="/tmp/test_output.jpg"

if [ ! -f "$TEST_INPUT" ]; then
    echo "✗ 测试图片不存在: $TEST_INPUT"
    echo "请确保在项目根目录运行此脚本"
    exit 1
fi

echo "测试配置:"
echo "  输入: $TEST_INPUT"
echo "  输出: $TEST_OUTPUT"
echo "  步长: 256"
echo "  设备: auto"
echo ""

echo "开始测试..."
echo "----------------------------------------"

python photoshop_integration/superstaroff_cli.py \
    "$TEST_INPUT" \
    "$TEST_OUTPUT" \
    --stride 256 \
    --device auto \
    --verbose

if [ $? -eq 0 ] && [ -f "$TEST_OUTPUT" ]; then
    echo ""
    echo "✓ 测试成功！"
    echo ""
    echo "输出文件: $TEST_OUTPUT"
    echo "文件大小: $(du -h "$TEST_OUTPUT" | cut -f1)"
    echo ""
    echo "你可以打开输出文件查看结果："
    echo "  open $TEST_OUTPUT"
    echo ""
    echo "或在 Photoshop 中测试："
    echo "  1. 打开 Photoshop"
    echo "  2. 打开一张图片"
    echo "  3. 运行 文件 > 脚本 > 浏览 > SuperStarOff_PS.jsx"
else
    echo ""
    echo "✗ 测试失败"
    echo ""
    echo "请检查:"
    echo "  1. Python 环境是否正确"
    echo "  2. 依赖库是否安装: pip install torch torchvision tifffile pillow numpy"
    echo "  3. 模型文件是否存在: models/SuperStarOff2025.pt"
fi
