# SuperStarOff - 统一安装指南

## 一次安装，双重体验

SuperStarOff 提供**统一的 PKG 安装包**，一次安装即可同时获得：

### 🎨 方式 1: Photoshop 插件
- 在 Photoshop 中无缝集成
- 直接处理当前图层
- 自动生成三个图层（原图、去星、星点）
- 使用方法：文件 > 脚本 > SuperStarOff

### 🖥️ 方式 2: 独立 GUI 应用
- 不依赖 Photoshop，随时使用
- 拖拽图片快速处理
- 批量处理多张图片
- 使用方法：双击 SuperStarOff.app

**关键优势：**
- ✅ 共享同一套 AI 模型（节省磁盘空间）
- ✅ 共享同一个 Python 环境（只需安装一次依赖）
- ✅ 统一更新，两种方式同步升级

---

## 方案对比

### 方案 1: PKG 安装包（推荐）

**优点：**
- ✅ 用户体验最好，双击安装
- ✅ 自动复制脚本到 Photoshop 目录
- ✅ 自动创建虚拟环境和安装依赖
- ✅ 自动配置路径
- ✅ 提供卸载脚本

**缺点：**
- ❌ 需要管理员权限（会提示输入密码）
- ❌ macOS 可能提示"来自身份不明的开发者"（需要开发者签名）

**构建方法：**

```bash
cd /Users/jameszhenyu/PycharmProjects/SuperStarOff/installer
./build_pkg.sh
```

构建完成后会生成 `SuperStarOff-Installer.pkg`

**安装方法：**
1. 双击 `SuperStarOff-Installer.pkg`
2. 按照提示完成安装（需要输入管理员密码）
3. 重启 Photoshop
4. 在 Photoshop 中：文件 > 脚本 > SuperStarOff

**卸载方法：**
运行生成的卸载脚本：
```bash
sudo installer/build/uninstall.sh
```

---

### 方案 2: 手动安装脚本（当前方案）

**优点：**
- ✅ 简单直接
- ✅ 不需要构建过程
- ✅ 用户可以看到每一步操作

**缺点：**
- ❌ 需要手动运行命令
- ❌ 需要管理员权限
- ❌ 路径已硬编码，不够灵活

**使用方法：**

```bash
sudo /Users/jameszhenyu/PycharmProjects/SuperStarOff/photoshop_integration/install_script.sh
```

---

## PKG 安装包详细说明

### 安装包会做什么？

1. **复制 Photoshop 脚本**
   - 将 `SuperStarOff_PS.jsx` 复制到 Photoshop 脚本目录
   - 位置：`/Applications/Adobe Photoshop 2025/Presets/Scripts/SuperStarOff.jsx`

2. **安装 Python 程序**
   - 复制所有必要文件到 `/usr/local/SuperStarOff/`
   - 包括：src、models、CLI、requirements.txt

3. **配置 Python 环境**
   - 创建虚拟环境：`/usr/local/SuperStarOff/.venv`
   - 安装所有依赖（torch, numpy, tifffile 等）

4. **更新配置**
   - 自动修改 JSX 脚本中的路径
   - 指向安装后的虚拟环境和 CLI

### 文件结构

安装后的文件结构：

```
/usr/local/SuperStarOff/
├── .venv/                      # Python 虚拟环境
├── src/                        # 源代码
│   ├── starnet_v2_pytorch.py
│   └── model_crypto.py
├── models/                     # 模型文件
│   └── SuperStarOff2025.pt
├── superstaroff_cli.py         # CLI 工具
└── requirements.txt

/Applications/Adobe Photoshop 2025/Presets/Scripts/
└── SuperStarOff.jsx            # Photoshop 脚本
```

### 构建签名的 PKG（可选）

如果你有 Apple 开发者账号，可以签名安装包避免安全警告：

```bash
# 签名 PKG
productsign --sign "Developer ID Installer: Your Name" \
    SuperStarOff-Installer.pkg \
    SuperStarOff-Installer-Signed.pkg

# 公证（需要 Apple 开发者账号）
xcrun notarytool submit SuperStarOff-Installer-Signed.pkg \
    --apple-id "your@email.com" \
    --password "app-specific-password" \
    --team-id "YOUR_TEAM_ID" \
    --wait

# 装订公证票据
xcrun stapler staple SuperStarOff-Installer-Signed.pkg
```

---

## 最佳实践建议

**对于开发测试：**
- 使用方案 2（手动脚本）更快速

**对于最终发布：**
- 使用方案 1（PKG 安装包）
- 如果可能，进行代码签名和公证
- 提供 DMG 格式会更专业（可以在 DMG 中放入 PKG）

### 创建 DMG 安装包

如果想要更专业的安装体验，可以创建 DMG：

```bash
# 创建 DMG
hdiutil create -volname "SuperStarOff" \
    -srcfolder installer/ \
    -ov -format UDZO \
    SuperStarOff-Installer.dmg
```

用户只需：
1. 下载并打开 DMG
2. 双击 PKG 安装
3. 完成！

---

## 故障排除

### 安装包提示"来自身份不明的开发者"

**临时解决方法：**
```bash
sudo installer -pkg SuperStarOff-Installer.pkg -target /
```

或者在系统设置中允许：
系统偏好设置 > 安全性与隐私 > 通用 > 允许从以下来源下载的应用

### Python 依赖安装失败

检查是否有网络连接，某些依赖（如 PyTorch）需要从网络下载。

### Photoshop 找不到脚本

1. 检查文件是否存在：
   ```bash
   ls "/Applications/Adobe Photoshop 2025/Presets/Scripts/SuperStarOff.jsx"
   ```

2. 重启 Photoshop

### 脚本执行报错

查看日志文件：
```bash
cat /var/folders/*/T/SuperStarOff/jsx_execution_log.txt
cat /var/folders/*/T/SuperStarOff/python_log_*.txt
```

---

## 许可证

SuperStarOff © 2025
