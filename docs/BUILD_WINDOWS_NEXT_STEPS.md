# Windows 构建步骤 - 修复 CLI 脚本问题

## 问题已修复

已修复 `build_windows.bat` 中的变量定义 bug，现在可以正确复制 `StarOff.jsx` 到安装包。

## 在 Windows 上执行以下步骤

### 前置要求

确保已安装：
- Python 3.11
- PyInstaller (`pip install pyinstaller`)
- Inno Setup 6 (https://jrsoftware.org/isinfo.php)

### 步骤 1: 拉取最新代码

```powershell
cd D:\path\to\SuperStarOff
git pull origin master
```

### 步骤 2: 用 PyInstaller 打包

```powershell
# 在项目根目录执行
pyinstaller superstaroff_windows.spec --noconfirm --distpath dist2
```

等待完成，确认 `dist2\superstaroff\superstaroff.exe` 已生成。

### 步骤 3: 运行构建脚本

```powershell
cd installer
.\build_windows.bat
```

脚本会自动：
1. 检查 PyInstaller 输出
2. 复制 `StarOff.jsx` 到 `dist2\superstaroff\scripts\`
3. 复制安装/卸载批处理脚本
4. 调用 Inno Setup 生成安装包

### 步骤 4: 验证输出

检查 `installer\installer_output\` 目录，应该有：
```
SuperStarOff-Installer-v1.1.0.exe
```

### 步骤 5: 测试安装

1. 运行新生成的安装包
2. 安装完成后，检查 `C:\Program Files\SuperStarOff\scripts\` 目录
3. 确认包含 `StarOff.jsx`（不是 `慧眼去星_DEV.jsx`）
4. 运行 `install_to_photoshop.bat` 安装到 Photoshop
5. 在 Photoshop 中测试脚本是否正常工作

## 修复内容说明

| 文件 | 修改 |
|------|------|
| `installer/build_windows.bat` | 添加了 `JSX_FILE` 变量定义 |
| `dist2/superstaroff/scripts/` | 删除 DEV 版本，添加正式版 StarOff.jsx |

## 如果遇到问题

### Inno Setup 找不到
- 确保安装了 Inno Setup 6
- 或将其添加到系统 PATH

### PyInstaller 报错
- 确保在正确的 Python 环境中
- 尝试 `pip install --upgrade pyinstaller`

---
*此文档创建于 2026-02-02，用于修复 Windows 安装后找不到 CLI 脚本的问题*
