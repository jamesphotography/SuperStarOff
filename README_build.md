# SuperStarOff 慧眼去星 - 构建指南

## Windows 构建

### 前提条件
1. Python 3.10+ 已安装
2. 项目虚拟环境已创建并激活
3. 所有依赖已安装

### 安装 PyInstaller
```powershell
pip install pyinstaller
```

### 构建选项

#### 构建 CLI 命令行工具
这将创建供 Photoshop 调用的 `superstaroff.exe`：

```powershell
cd C:\Users\<你的用户名>\PycharmProjects\SuperStarOff
pyinstaller superstaroff_windows.spec
```

输出位置: `dist\superstaroff\superstaroff.exe`

### 完整安装流程

1. **构建 CLI 工具**（供 Photoshop 使用）:
   ```powershell
   pyinstaller superstaroff_windows.spec
   ```

2. **安装到 Program Files**:
   ```powershell
   # 以管理员身份运行 PowerShell
   mkdir "C:\Program Files\SuperStarOff"
   mkdir "C:\Program Files\SuperStarOff\models"
   mkdir "C:\Program Files\SuperStarOff\scripts"
   
   # 复制文件
   xcopy /E /I dist\superstaroff\* "C:\Program Files\SuperStarOff\"
   copy scripts\慧眼去星.jsx "C:\Program Files\SuperStarOff\scripts\"
   ```

3. **安装 Photoshop 脚本**:
   将 `慧眼去星.jsx` 复制到:
   ```
   C:\Program Files\Adobe\Adobe Photoshop 2024\Presets\Scripts\
   ```
   (根据你的 Photoshop 版本调整路径)

4. **重启 Photoshop**

5. **使用**:
   在 Photoshop 中: 文件 > 脚本 > 慧眼去星

---

## macOS 构建

### 构建命令
```bash
cd /path/to/SuperStarOff
pyinstaller superstaroff.spec
```

### 安装
```bash
sudo mkdir -p /usr/local/SuperStarOff/models
sudo mkdir -p /usr/local/SuperStarOff/scripts

sudo cp -r dist/superstaroff/* /usr/local/SuperStarOff/
sudo cp scripts/StarOff.jsx /usr/local/SuperStarOff/scripts/
```

---

## 文件结构

```
SuperStarOff/
├── src/
│   ├── core_utils.py           # 加密解密模块
│   ├── model_processor.py      # AI 模型处理核心
│   ├── superstaroff_cli.py     # 命令行接口
│   ├── 慧眼去星.jsx            # Photoshop 生产脚本（中文版）
│   └── 慧眼去星_DEV.jsx        # Photoshop 开发脚本
├── models/
│   └── SuperStarOff2025.pt     # AI 模型文件
├── installer/
│   ├── SuperStarOff.iss        # Inno Setup 安装包脚本
│   ├── build_windows.bat       # Windows 一键构建脚本
│   ├── install_to_photoshop.bat   # 手动安装插件脚本
│   └── uninstall_from_photoshop.bat  # 卸载插件脚本
├── superstaroff.spec           # macOS PyInstaller 打包配置
├── superstaroff_windows.spec   # Windows PyInstaller 打包配置
└── README_build.md             # 本文件
```

---

## 安装后的目录结构

### Windows
```
C:\Program Files\SuperStarOff\
├── superstaroff.exe            # 命令行工具
├── models/
│   └── SuperStarOff2025.pt     # AI 模型
├── scripts/
│   └── 慧眼去星.jsx            # Photoshop 脚本
└── [其他依赖文件...]
```

### macOS
```
/usr/local/SuperStarOff/
├── superstaroff                # 命令行工具
├── models/
│   └── SuperStarOff2025.pt     # AI 模型
├── scripts/
│   └── 慧眼去星.jsx            # Photoshop 脚本
└── [其他依赖文件...]
```

---

## 故障排除

### Windows: EXE 双击后立即关闭
- 这是正常行为，如果你运行的是 CLI 版本
- CLI 工具需要参数，应该从命令行或 Photoshop 调用
- 如果你想要安装界面，请使用 `superstaroff_windows.spec` 构建

### Windows: 权限错误
- 安装到 Program Files 需要管理员权限
- 右键点击 PowerShell > "以管理员身份运行"

### Photoshop: 找不到 SuperStarOff
- 检查安装路径是否正确
- 确保 `superstaroff.exe` 在 `C:\Program Files\SuperStarOff\`
- 检查 JSX 脚本中的 `INSTALL_DIR` 设置

### 模型加载失败
- 确保 `SuperStarOff2025.pt` 在 `models` 文件夹中
- 检查模型文件是否完整（未损坏）