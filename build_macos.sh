#!/bin/bash
# macOS 打包脚本 - 慧眼去星V1

set -e  # 遇到错误立即退出

echo "=================================================="
echo "  慧眼去星V1 - macOS 打包工具"
echo "=================================================="
echo ""

# 代码签名证书
SIGNING_IDENTITY="Developer ID Application: James Zhen Yu (JWR6FDB52H)"

# 检查虚拟环境
if [ ! -d ".venv" ]; then
    echo "❌ 错误: 未找到虚拟环境 .venv"
    echo "请先创建虚拟环境: python3 -m venv .venv"
    exit 1
fi

# 激活虚拟环境
echo "✓ 激活虚拟环境..."
source .venv/bin/activate

# 安装 PyInstaller
echo ""
echo "✓ 安装 PyInstaller..."
pip install pyinstaller

# 清理旧的打包文件
echo ""
echo "✓ 清理旧的打包文件..."
rm -rf build dist

# 开始打包
echo ""
echo "✓ 开始打包应用..."
echo "  这可能需要几分钟时间，请耐心等待..."
echo ""

pyinstaller build_app.spec

# 检查打包结果
if [ -d "dist/慧眼去星V1.app" ]; then
    echo ""
    echo "=================================================="
    echo "  ✅ PyInstaller 打包成功!"
    echo "=================================================="
    echo ""

    # 代码签名
    echo "✓ 开始代码签名..."
    echo "  使用证书: $SIGNING_IDENTITY"
    echo ""

    # 签名所有动态库和框架
    echo "  签名动态库和框架..."
    find "dist/慧眼去星V1.app/Contents/MacOS" -name "*.dylib" -o -name "*.so" | while read file; do
        echo "    签名: $file"
        codesign --force --deep --sign "$SIGNING_IDENTITY" "$file" 2>/dev/null || true
    done

    # 创建 entitlements 文件
    echo ""
    echo "  创建 entitlements 文件..."
    cat > /tmp/entitlements.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.cs.allow-unsigned-executable-memory</key>
    <true/>
    <key>com.apple.security.cs.disable-library-validation</key>
    <true/>
</dict>
</plist>
EOF

    # 签名整个应用
    echo ""
    echo "  签名应用程序..."
    codesign --force --deep --sign "$SIGNING_IDENTITY" \
        --options runtime \
        --entitlements /tmp/entitlements.plist \
        "dist/慧眼去星V1.app"

    # 验证签名
    echo ""
    echo "✓ 验证签名..."
    if codesign --verify --deep --strict --verbose=2 "dist/慧眼去星V1.app" 2>&1; then
        echo ""
        echo "=================================================="
        echo "  ✅ 签名成功!"
        echo "=================================================="
        echo ""
        echo "应用位置: dist/慧眼去星V1.app"

        # 获取应用大小
        app_size=$(du -sh "dist/慧眼去星V1.app" | cut -f1)
        echo "应用大小: $app_size"

        # 显示签名信息
        echo ""
        echo "签名信息:"
        codesign -dv --verbose=4 "dist/慧眼去星V1.app" 2>&1 | grep -E "(Authority|Identifier|TeamIdentifier|Signature size)"

        echo ""
        echo "=================================================="
        echo "  后续步骤"
        echo "=================================================="
        echo ""
        echo "1. 测试应用:"
        echo "   open dist/慧眼去星V1.app"
        echo ""
        echo "2. 创建 DMG (由你手动执行)"
        echo ""
        echo "3. 公证应用 (由你手动执行)"
        echo ""
        echo "=================================================="
    else
        echo ""
        echo "❌ 签名验证失败!"
        exit 1
    fi

else
    echo ""
    echo "❌ 打包失败!"
    echo "请检查上面的错误信息"
    exit 1
fi
