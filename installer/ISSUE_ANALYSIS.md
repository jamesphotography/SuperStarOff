# 🐛 安装包问题分析

## 问题总结

当前构建的安装包有**严重bug**，用户安装后无法使用！

---

## 🔍 发现的问题

### 问题 1: JSX 文件未打包 ❌

**位置:** `build_ps_only.sh` 第 66-80 行

**问题:**
```bash
# 步骤4: 复制核心文件
cp "$PROJECT_ROOT/photoshop_integration/superstaroff_core.py" "$APP_DIR/"
cp "$PROJECT_ROOT/src/core_utils.py" "$APP_DIR/"
cp -r "$PROJECT_ROOT/models" "$APP_DIR/"
cp "$PROJECT_ROOT/photoshop_integration/superstaroff_cli.py" "$APP_DIR/"

# ❌ 完全没有复制 SuperStarOff_PS.jsx！
```

**结果:** JSX 文件根本没有打包到安装包中

---

### 问题 2: postinstall 使用错误路径 ❌

**位置:** `postinstall` 脚本第 151、160 行

**错误代码:**
```bash
# 第 151 行 - 错误的相对路径
JSX_SOURCE="/usr/local/SuperStarOff/../../../photoshop_integration/SuperStarOff_PS.jsx"

# 第 160 行 - 硬编码开发路径
if [ -f "/Users/jameszhenyu/PycharmProjects/SuperStarOff/photoshop_integration/SuperStarOff_PS.jsx" ]; then
    cp "/Users/jameszhenyu/PycharmProjects/SuperStarOff/photoshop_integration/SuperStarOff_PS.jsx" "$PS_DIR/"
fi
```

**问题:**
1. 用户机器上没有 `/Users/jameszhenyu/PycharmProjects/SuperStarOff/` 路径
2. JSX 文件没有打包，所以即使路径对也找不到文件

---

## ✅ 正确的做法

### 方案：将 JSX 打包到 `/usr/local/SuperStarOff/`

**安装包应该包含：**
```
/usr/local/SuperStarOff/
├── .venv/                          ← Python 虚拟环境
├── models/                         ← 模型文件
│   └── SuperStarOff2025.pt
├── core_utils.py                   ← Python 模块
├── superstaroff_core.py            ← Python 模块
├── superstaroff_cli.py             ← CLI 脚本
└── SuperStarOff_PS.jsx             ← ✅ JSX 脚本（需要添加！）
```

**postinstall 应该：**
```bash
#!/bin/bash

# 获取当前用户
CURRENT_USER=$(stat -f "%Su" /dev/console)
USER_HOME=$(eval echo ~$CURRENT_USER)

# JSX 源文件（从安装目录）
JSX_SOURCE="/usr/local/SuperStarOff/SuperStarOff_PS.jsx"

# Photoshop Scripts 目录
PS_DIRS=(
    "$USER_HOME/Library/Application Support/Adobe/Adobe Photoshop 2025/Presets/Scripts"
    "$USER_HOME/Library/Application Support/Adobe/Adobe Photoshop 2024/Presets/Scripts"
    "$USER_HOME/Library/Application Support/Adobe/Adobe Photoshop 2023/Presets/Scripts"
    "$USER_HOME/Library/Application Support/Adobe/Adobe Photoshop 2022/Presets/Scripts"
)

# 复制到所有找到的 Photoshop 版本
INSTALLED=0
for PS_DIR in "${PS_DIRS[@]}"; do
    if [ -d "$(dirname "$PS_DIR")" ]; then
        echo "  找到 Photoshop: $(dirname "$PS_DIR")"
        mkdir -p "$PS_DIR"

        # 从安装目录复制
        if [ -f "$JSX_SOURCE" ]; then
            cp "$JSX_SOURCE" "$PS_DIR/SuperStarOff_PS.jsx"
            chown "$CURRENT_USER:staff" "$PS_DIR/SuperStarOff_PS.jsx"
            chmod 644 "$PS_DIR/SuperStarOff_PS.jsx"
            echo "  ✓ JSX 已安装到: $PS_DIR"
            INSTALLED=$((INSTALLED + 1))
        else
            echo "  ❌ 错误: 找不到 JSX 源文件: $JSX_SOURCE"
        fi
    fi
done

if [ $INSTALLED -eq 0 ]; then
    echo "  ⚠️  未找到 Photoshop 或 JSX 安装失败"
    echo "  请手动复制 $JSX_SOURCE 到 Photoshop Scripts 目录"
fi
```

---

## 🔧 需要修改的文件

### 1. `build_ps_only.sh` - 添加 JSX 复制

**在第 80 行后添加：**
```bash
echo "  - 复制 CLI 脚本..."
cp "$PROJECT_ROOT/photoshop_integration/superstaroff_cli.py" "$APP_DIR/"
echo "    ✓ 已复制: superstaroff_cli.py"

# ✅ 添加这部分
echo "  - 复制 JSX 脚本..."
cp "$PROJECT_ROOT/photoshop_integration/SuperStarOff_PS.jsx" "$APP_DIR/"
echo "    ✓ 已复制: SuperStarOff_PS.jsx"
```

### 2. `build_ps_only.sh` - 修复 postinstall 脚本

**替换第 134-189 行的 postinstall heredoc：**
```bash
cat > "$SCRIPTS_DIR/postinstall" << 'POSTINSTALL_EOF'
#!/bin/bash

LOG_FILE="/tmp/superstaroff_install.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "==================================================="
echo "SuperStarOff - 安装 Photoshop 插件"
echo "开始时间: $(date)"
echo "==================================================="
echo ""

# 获取当前用户
CURRENT_USER=$(stat -f "%Su" /dev/console)
USER_HOME=$(eval echo ~$CURRENT_USER)

echo "当前用户: $CURRENT_USER"
echo "用户主目录: $USER_HOME"
echo ""

# JSX 源文件（从安装目录）
JSX_SOURCE="/usr/local/SuperStarOff/SuperStarOff_PS.jsx"

# 检查 JSX 文件是否存在
if [ ! -f "$JSX_SOURCE" ]; then
    echo "❌ 错误: JSX 文件不存在: $JSX_SOURCE"
    exit 1
fi
echo "✓ 找到 JSX 文件: $JSX_SOURCE"
echo ""

# Photoshop Scripts 目录（支持多个版本）
PS_DIRS=(
    "$USER_HOME/Library/Application Support/Adobe/Adobe Photoshop 2025/Presets/Scripts"
    "$USER_HOME/Library/Application Support/Adobe/Adobe Photoshop 2024/Presets/Scripts"
    "$USER_HOME/Library/Application Support/Adobe/Adobe Photoshop 2023/Presets/Scripts"
    "$USER_HOME/Library/Application Support/Adobe/Adobe Photoshop 2022/Presets/Scripts"
)

echo "正在安装 JSX 脚本到 Photoshop..."
INSTALLED=0

for PS_DIR in "${PS_DIRS[@]}"; do
    # 检查 Photoshop 版本是否存在（检查父目录）
    PS_VERSION_DIR="$(dirname "$(dirname "$PS_DIR")")"

    if [ -d "$PS_VERSION_DIR" ]; then
        echo "  找到 Photoshop: $PS_VERSION_DIR"

        # 创建 Scripts 目录
        mkdir -p "$PS_DIR"

        # 复制 JSX 文件
        cp "$JSX_SOURCE" "$PS_DIR/SuperStarOff_PS.jsx"

        # 设置权限
        chown "$CURRENT_USER:staff" "$PS_DIR/SuperStarOff_PS.jsx"
        chmod 644 "$PS_DIR/SuperStarOff_PS.jsx"

        echo "  ✓ JSX 已安装到: $PS_DIR/SuperStarOff_PS.jsx"
        INSTALLED=$((INSTALLED + 1))
    fi
done

echo ""
if [ $INSTALLED -eq 0 ]; then
    echo "⚠️  警告: 未找到 Photoshop 安装"
    echo ""
    echo "请手动安装 JSX 脚本："
    echo "  1. 复制: $JSX_SOURCE"
    echo "  2. 到: ~/Library/Application Support/Adobe/Adobe Photoshop 202X/Presets/Scripts/"
    echo ""
else
    echo "✓ JSX 脚本已安装到 $INSTALLED 个 Photoshop 版本"
fi

# 设置 SuperStarOff 目录权限
echo "设置权限..."
chown -R root:wheel /usr/local/SuperStarOff
chmod -R 755 /usr/local/SuperStarOff
chmod 644 /usr/local/SuperStarOff/SuperStarOff_PS.jsx
echo "✓ 权限设置完成"
echo ""

echo "==================================================="
echo "✅ SuperStarOff 安装完成！"
echo "==================================================="
echo ""
echo "安装位置:"
echo "  核心文件: /usr/local/SuperStarOff/"
if [ $INSTALLED -gt 0 ]; then
    echo "  JSX 脚本: Photoshop Scripts 目录"
fi
echo ""
echo "使用方法:"
echo "  1. 重启 Adobe Photoshop"
echo "  2. 打开星空图片"
echo "  3. 菜单: 文件 > 脚本 > SuperStarOff_PS"
echo "  4. 选择参数，等待处理完成"
echo ""
echo "日志文件: $LOG_FILE"
echo "==================================================="
echo ""

exit 0
POSTINSTALL_EOF
```

---

## 📋 修复步骤

1. **编辑 `build_ps_only.sh`**
   - 添加 JSX 文件复制（第 80 行后）
   - 替换 postinstall 脚本（第 134-189 行）

2. **重新构建**
   ```bash
   cd installer
   rm -rf build/ *.pkg
   ./build_ps_only.sh
   ```

3. **重新签名**
   ```bash
   productsign --sign "Developer ID Installer: James Zhen Yu (JWR6FDB52H)" \
       SuperStarOff-PS-Only.pkg \
       SuperStarOff-PS-Only-Signed.pkg
   ```

4. **重新公证**
   ```bash
   xcrun notarytool submit SuperStarOff-PS-Only-Signed.pkg \
       --apple-id "james@jamesphotography.com.au" \
       --password "vfmy-vjcb-injx-guid" \
       --team-id "JWR6FDB52H" \
       --wait

   xcrun stapler staple SuperStarOff-PS-Only-Signed.pkg
   ```

---

## ⚠️ 影响

**当前版本的问题：**
- ❌ 用户安装后，Photoshop 中不会出现 SuperStarOff_PS 脚本
- ❌ 完全无法使用
- ❌ 必须重新构建和分发

**修复后：**
- ✅ JSX 文件正确打包
- ✅ 自动安装到所有 Photoshop 版本
- ✅ 用户可以直接使用

---

## 🎯 建议

**立即修复并重新构建！**

这是一个阻塞性 bug，当前版本完全不可用。
