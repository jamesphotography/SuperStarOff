# 慧眼去星 SuperStarOff

基于深度学习的天文图像星点去除工具

## 项目简介

慧眼去星 (SuperStarOff) 是一个专业的星点去除工具，采用深度学习技术，专门用于从天文图像中移除星点，保留背景星云和深空天体。

### 主要功能

- ✅ 使用先进的深度学习模型 (2025v1) 去除星点
- ✅ 支持 RGB 和灰度图像
- ✅ 支持 8-bit 和 16-bit TIFF 格式
- ✅ 基于 PyTorch 实现，支持 MPS（Apple Silicon GPU）加速
- ✅ 现代化的 PyQt6 图形界面
- 🚧 计划支持批量处理
- 🚧 计划集成到 SuperStarTrail 星轨叠加工具

## 项目结构

```
SuperStarOff/
├── README.md              # 项目说明
├── PROJECT_PLAN.md        # 开发计划和进度
├── TECHNICAL_NOTES.md     # 技术笔记
├── requirements.txt       # Python 依赖
├── models/                # 预训练模型权重
│   └── SuperStarOff2025.pt       (168MB) - 加密模型权重
├── src/                   # 源代码
│   ├── model_processor.py        # 深度学习模型实现
│   ├── app.py                    # GUI 应用入口
│   └── gui/                      # GUI 相关代码
│       ├── main_window.py        # 主窗口
│       ├── image_viewer.py       # 图像查看器
│       └── logger.py             # 日志系统
├── examples/              # 示例和测试
│   └── 海豚星云-Sh2-308-S-4天数据.jpg  # 示例图片
├── resources/             # 资源文件
│   ├── icons/             # 应用图标
│   └── styles/            # 样式表
└── docs/                  # 文档
    ├── GUI_DESIGN.md      # GUI 设计文档
    └── USER_GUIDE.md      # 使用指南
```

## 快速开始

### 1. 环境要求

- Python 3.12+
- PyTorch 2.0+
- PyQt6（用于 GUI）
- 其他依赖见 `requirements.txt`

### 2. 安装依赖

```bash
cd SuperStarOff
pip install -r requirements.txt
```

### 3. 启动 GUI 应用

```bash
python src/app.py
```

这将启动图形界面，您可以直接拖放图片进行处理。

## 使用方法

### GUI 使用

1. 启动应用：`python src/app.py`
2. 拖放图片到窗口，或点击"打开图片"
3. 选择处理参数（步长、设备）
4. 点击"去除星点"按钮
5. 等待处理完成，查看对比结果
6. 保存处理后的图片

### 命令行使用

```python
import sys
sys.path.insert(0, 'src')
from model_processor import StarNetV2

# 初始化处理器
processor = StarNetV2(device='mps', stride=256)  # 或 'cpu'
processor.load_model()

# 处理图像
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
processor = StarNetV2(device='auto')  # 会自动使用 MPS
```

## 性能

在 MacBook Pro (Apple Silicon) 上的处理时间：

| 图像大小 | Window Size | Stride | 处理时间 |
|---------|-------------|--------|---------|
| 1048×712 | 512 | 256 | ~5 秒 |
| 8256×5504 | 512 | 256 | ~2 分钟 |

## 开发进度

详见 `PROJECT_PLAN.md`

## 未来计划

- [x] ~~创建 GUI 界面~~ ✅
- [x] ~~支持 MPS 加速~~ ✅
- [ ] 添加批量处理支持
- [ ] 创建命令行工具
- [ ] 集成到 SuperStarTrail
- [ ] 支持更多图像格式 (FITS)
- [ ] 模型量化优化

## 许可证

本项目采用开源许可证。

## 致谢

- 感谢所有深度学习和天文图像处理领域的研究者
- SuperStarTrail 项目
