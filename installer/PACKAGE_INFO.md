# SuperStarOff PS-Only 安装包信息

> **构建时间:** 2025-11-12 21:03
> **版本:** 1.0.0
> **类型:** Photoshop 插件（不含 GUI）

---

## 📦 安装包详情

### 文件信息
```
文件名: SuperStarOff-PS-Only-Signed.pkg
大小: 273 MB
位置: /Users/jameszhenyu/PycharmProjects/SuperStarOff/installer/
MD5: 376977a7ecaa0f088a7d76da596af5a2
```

### 签名状态 ✅
```
状态: ✅ 已签名
签名者: Developer ID Installer: James Zhen Yu (JWR6FDB52H)
证书链:
  1. Developer ID Installer: James Zhen Yu (JWR6FDB52H)
     过期时间: 2027-02-01
  2. Developer ID Certification Authority
  3. Apple Root CA

时间戳: 2025-11-12 10:33:31 UTC
公证状态: ❌ 未公证（按要求跳过）
```

---

## 📋 包含内容

### 安装位置
```
/usr/local/SuperStarOff/
├── .venv/                              (621 MB - 独立 Python 环境)
│   ├── bin/python                      Python 3.11.9
│   └── lib/python3.11/site-packages/
│       ├── torch/                      PyTorch 2.8.0
│       ├── numpy/                      NumPy 1.26.4
│       ├── PIL/                        Pillow 11.3.0
│       ├── tifffile/                   tifffile 2025.10.4
│       └── cryptography/               cryptography 46.0.2
├── models/
│   └── SuperStarOff2025.pt             (168 MB - 加密模型)
├── core_utils.py                       加密工具模块
├── superstaroff_core.py                核心处理逻辑
└── superstaroff_cli.py                 CLI 接口

Photoshop Scripts:
~/Library/Application Support/Adobe/Adobe Photoshop 202X/Presets/Scripts/
└── SuperStarOff_PS.jsx                 JSX 脚本
```

### 核心依赖（已打包）
- ✅ Python 3.11.9（独立虚拟环境）
- ✅ PyTorch 2.8.0
- ✅ NumPy 1.26.4
- ✅ Pillow 11.3.0
- ✅ tifffile 2025.10.4
- ✅ cryptography 46.0.2

---

## 🎯 特性

### 完全自包含 ✅
- ✅ 无需用户安装 Python
- ✅ 无需用户安装任何库
- ✅ 所有依赖都在虚拟环境中
- ✅ 不依赖 conda 或其他包管理器

### 无后台程序 ✅
- ✅ 按需运行，不常驻内存
- ✅ 处理完成自动退出
- ✅ 不占用系统资源

### 代码签名 ✅
- ✅ 所有二进制文件已签名
- ✅ 安装包已签名
- ✅ 支持 macOS Gatekeeper
- ❌ 未公证（按要求）

---

## 📥 安装方法

### 用户安装步骤
1. 双击 `SuperStarOff-PS-Only-Signed.pkg`
2. 按照安装向导完成安装
3. 重启 Adobe Photoshop

### 系统要求
- macOS 10.15 (Catalina) 或更高
- Adobe Photoshop 2022/2023/2024/2025
- 800MB 可用磁盘空间
- 4GB+ RAM（推荐 8GB）

---

## 🚀 使用方法

### 在 Photoshop 中使用
1. 打开一张星空图片
2. 选择菜单：**文件 > 脚本 > SuperStarOff_PS**
3. 在弹出的对话框中选择参数：
   - Stride: 处理步长（256 = 快速，128 = 精细）
   - Device: 处理设备（auto = 自动，cpu = CPU）
4. 点击 OK，等待处理完成
5. 处理后会自动创建新图层 `*_starless`

### 处理时间参考
- 1K 图片: ~30秒
- 4K 图片: ~2分钟
- 8K 图片: ~5-8分钟

---

## 🗑️ 卸载方法

### 手动卸载
```bash
# 1. 删除程序文件
sudo rm -rf /usr/local/SuperStarOff

# 2. 删除 JSX 脚本
rm -f ~/Library/Application\ Support/Adobe/Adobe\ Photoshop\ */Presets/Scripts/SuperStarOff_PS.jsx

# 3. 删除临时文件
rm -rf /tmp/SuperStarOff
```

### 使用卸载脚本
```bash
sudo /Users/jameszhenyu/PycharmProjects/SuperStarOff/installer/build/uninstall.sh
```

---

## ⚠️ 重要说明

### 关于未公证
- ⚠️ 本安装包**已签名但未公证**
- ⚠️ 首次安装时，macOS 可能显示警告
- ⚠️ 解决方法：右键点击安装包 → "打开" → 确认打开

### 为什么未公证？
按用户要求，本版本跳过了 Apple 公证流程，以加快发布速度。

### 如何公证（可选）
如果需要公证，运行：
```bash
cd /Users/jameszhenyu/PycharmProjects/SuperStarOff/installer
./sign_and_notarize.sh SuperStarOff-PS-Only-Signed.pkg
```

---

## 🔍 技术细节

### 虚拟环境
- 类型: Python venv（--copies 模式）
- Python: 3.11.9 (Python.org 独立版本)
- 独立性: 完全独立，不依赖系统 Python
- 大小: 621 MB

### 模型加密
- 算法: PBKDF2 + Fernet (AES-128)
- 密钥派生: 6层混淆 + 1000轮哈希
- 存储: 仅在内存中解密，不写入磁盘

### 性能优化
- Tiling: 512x512 窗口，256 stride
- 设备支持: CPU / MPS (Apple Silicon)
- 内存管理: 分块处理，避免 OOM

---

## 📊 与其他版本对比

| 特性 | PS-Only | 完整版 |
|------|---------|--------|
| 大小 | 273 MB | ~2 GB |
| GUI 应用 | ❌ | ✅ |
| PS 插件 | ✅ | ✅ |
| 独立使用 | ❌ | ✅ |
| 构建时间 | 15分钟 | 40分钟 |
| 用户依赖 | 需要 Photoshop | 可独立运行 |

---

## 📝 版本历史

### v1.0.0 (2025-11-12)
- ✅ 首次发布
- ✅ 支持 Photoshop 2022-2025
- ✅ PyTorch 2.8.0 模型
- ✅ 代码签名（未公证）
- ✅ 完全自包含

---

## 🔗 相关文件

- **安装包:** `SuperStarOff-PS-Only-Signed.pkg` (273 MB)
- **未签名版本:** `SuperStarOff-PS-Only.pkg` (273 MB)
- **卸载脚本:** `build/uninstall.sh`
- **构建脚本:** `build_ps_only.sh`

---

## 📞 技术支持

### 常见问题

**Q: 为什么安装时显示"无法验证开发者"？**
A: 因为未公证。右键点击 → "打开" → 确认即可。

**Q: 处理速度慢怎么办？**
A: 降低 stride 值（256→384 更快，但质量略降）

**Q: 支持哪些图像格式？**
A: TIFF, PNG, JPEG（推荐 16-bit TIFF）

**Q: 需要网络连接吗？**
A: 不需要，完全离线运行

**Q: 会收集数据吗？**
A: 不会，无任何遥测或数据收集

---

**构建者:** Claude Code AI + James Zhen Yu
**构建时间:** 2025-11-12 21:03 UTC
**签名状态:** ✅ 已签名
**公证状态:** ❌ 未公证（按要求）
