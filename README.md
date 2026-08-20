# 慧眼去星 SuperStarOff

## 下载

最新版本 **v1.1.3** — [全部版本](https://github.com/jamesphotography/SuperStarOff/releases)

### macOS (v1.1.3)

请按芯片类型选择（点击左上角  → 关于本机，查看「芯片」一栏）：

- **Apple Silicon (M1/M2/M3/M4)**: [SuperStarOff-v1.1.3-arm64.pkg](https://github.com/jamesphotography/SuperStarOff/releases/download/v1.1.3/SuperStarOff-v1.1.3-arm64.pkg)
- **Intel**: [SuperStarOff-v1.1.3-x86_64.pkg](https://github.com/jamesphotography/SuperStarOff/releases/download/v1.1.3/SuperStarOff-v1.1.3-x86_64.pkg)

### Windows X64 (v1.1.3)

- **GitHub 直接下载**: [SuperStarOff-Installer-v1.1.3.exe](https://github.com/jamesphotography/SuperStarOff/releases/download/v1.1.3/SuperStarOff-Installer-v1.1.3.exe)

---

基于深度学习的天文图像星点去除工具

## 项目简介

慧眼去星 (SuperStarOff) 是一个专业的星点去除工具，采用深度学习技术，专门用于从天文图像中移除星点，保留背景星云和深空天体。

### 主要功能

- ✅ 使用先进的深度学习模型 (2025v1) 去除星点
- ✅ 支持 RGB 和灰度图像
- ✅ 支持 8-bit 和 16-bit TIFF 格式
- ✅ 基于 PyTorch 实现，支持 MPS（Apple Silicon GPU）加速
- ✅ 以 Photoshop 脚本（JSX）形式提供操作界面，Python 端为命令行工具
- 🚧 计划支持批量处理
- 🚧 计划集成到 SuperStarTrail 星轨叠加工具

## 项目结构

```
SuperStarOff/
├── README.md              # 项目说明
├── README_build.md        # 构建指南
├── RELEASE_NOTES.md       # 版本发布记录
├── requirements.txt       # Python 依赖
├── superstaroff.spec              # PyInstaller 配置（macOS）
├── superstaroff_windows.spec      # PyInstaller 配置（Windows）
├── models/                # 预训练模型权重
│   └── SuperStarOff2025.pt       (168MB) - 加密模型权重
├── src/                   # 源代码
│   ├── superstaroff_cli.py       # 命令行入口（PyInstaller 打包目标）
│   ├── model_processor.py        # 深度学习模型实现（StarRemover）
│   ├── core_utils.py             # 模型加解密（ModelCrypto）
│   ├── 慧眼去星.jsx               # Photoshop 脚本（中文版，含对话框 UI）
│   └── StarOff.jsx                # Photoshop 脚本（英文版）
├── installer/             # 安装包构建脚本
└── docs/                  # 文档与项目主页
```

## 快速开始

### 1. 环境要求

- Python 3.11（numpy 1.x 约束上限为 3.12，实际构建与测试环境为 3.11）
- PyTorch 2.0+
- 其他依赖见 `requirements.txt`

### 2. 安装依赖

```bash
cd SuperStarOff
pip install -r requirements.txt
```

### 3. 运行命令行工具

```bash
python src/superstaroff_cli.py input.tif output.tif --verbose
```

本项目没有独立的桌面 GUI，操作界面由 Photoshop 脚本提供（见下）。

## 使用方法

### Photoshop 插件使用（面向最终用户）

安装后在 Photoshop 中：**文件 > 脚本 > 慧眼去星**

1. 选中要处理的图层
2. 在弹出的对话框中点击「开始处理」
3. AI 自动分离星点与背景，生成「去星」与「星点」两个图层
4. 首次运行需加载模型，请耐心等待

对话框界面由 `src/慧眼去星.jsx` 用 ExtendScript ScriptUI 绘制，内部调用打包好的 CLI 完成计算。

### 命令行使用（面向开发/批处理）

```bash
python src/superstaroff_cli.py input.tif output.tif --stride 256 --device auto
```

也可直接调用处理类：

```python
import sys
sys.path.insert(0, 'src')
from model_processor import StarRemover

processor = StarRemover(stride=256, device='auto')  # 'mps' / 'cpu' / 'cuda'
processor.transform('input.tif', 'output_starless.tif', stride=256)
```

### 参数说明

- **device**: 'mps'（Apple Silicon GPU）、'cpu' 或 'cuda'（NVIDIA GPU）
- **stride**: 256（推荐）- 滑动步长，越小质量越好但速度越慢
  - 选项：128, 256, 384, 512

## 技术细节

### 模型架构

慧眼去星 2025v1 使用优化的 CNN 架构：

- **模型格式**: PyTorch TorchScript (.pt) - 加密存储
- **模型大小**: 168MB（包含加密层）
- **输入尺寸**: 512×512 窗口（使用分块处理大图）
- **支持设备**: CPU、Apple MPS、NVIDIA CUDA

### MPS 加速

在 Apple Silicon (M1/M2/M3) Mac 上，使用 MPS 可以获得显著的性能提升：

```python
# 自动选择最佳设备
processor = StarRemover(device='auto')  # 会自动使用 MPS
```

## 性能

在 MacBook Pro (Apple Silicon) 上的处理时间：

| 图像大小 | Window Size | Stride | 处理时间 |
|---------|-------------|--------|---------|
| 1048×712 | 512 | 256 | ~5 秒 |
| 8256×5504 | 512 | 256 | ~2 分钟 |

## 开发进度

详见 `RELEASE_NOTES.md`

## 未来计划

- [x] ~~Photoshop 插件界面~~ ✅
- [x] ~~支持 MPS 加速~~ ✅
- [x] ~~创建命令行工具~~ ✅
- [ ] 添加批量处理支持
- [ ] 集成到 SuperStarTrail
- [ ] 支持更多图像格式 (FITS)
- [ ] 模型量化优化

## 许可证

本项目采用开源许可证。

## 致谢

- 感谢所有深度学习和天文图像处理领域的研究者
- SuperStarTrail 项目
