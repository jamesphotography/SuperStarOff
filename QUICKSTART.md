# SuperStarOff 快速开始指南

## 5 分钟快速上手

### 第一步：检查环境

确保你已经安装了 Python 3.12+：

```bash
python --version
# 应该显示 Python 3.12.x
```

### 第二步：安装依赖

```bash
cd SuperStarOff
pip install -r requirements.txt
```

这将安装：
- TensorFlow 2.20+
- Keras 3.x
- 图像处理库 (Pillow, tifffile)
- 其他必要依赖

**注意**: 安装可能需要 5-10 分钟，取决于网速。

### 第三步：运行测试

```bash
cd examples
python test_basic.py
```

你应该看到：

```
============================================================
SuperStarOff 基础测试
============================================================

1. 导入 StarNet++ 模块...
   ✅ StarNet 导入成功

2. 检查测试图像...
   ✅ 测试图像存在: rgb_test5.tif

3. 检查权重文件...
   ✅ weights_G_RGB.h5
   ✅ weights_D_RGB.h5
   ✅ weights_G_Greyscale.h5
   ✅ weights_D_Greyscale.h5

4. 初始化 StarNet++ 模型...
   ✅ StarNet 实例创建成功
   ✅ 权重加载成功

5. 运行星点去除...
   注意：首次运行可能需要 1-2 分钟...
   ✅ 转换成功！

📁 输出文件: /path/to/examples/rgb_test5_starless.tif

============================================================
✅ SuperStarOff 测试成功！
============================================================
```

### 第四步：查看结果

打开 `examples/rgb_test5_starless.tif` 对比原图效果。

---

## 基础使用

### Python 代码示例

```python
import sys
sys.path.insert(0, '../src')
from starnet_v1_TF2 import StarNet

# 1. 初始化 StarNet++
starnet = StarNet(
    mode='RGB',          # 'RGB' 或 'Greyscale'
    window_size=512,     # 处理窗口大小 (推荐 512)
    stride=256           # 滑动步长 (推荐 256)
)

# 2. 加载预训练模型
starnet.load_model(weights='../models/weights')

# 3. 处理图像
starnet.transform(
    'input_image.tif',         # 输入图像路径
    'output_starless.tif'      # 输出图像路径
)

print("星点去除完成！")
```

### 参数说明

**mode**:
- `'RGB'`: 彩色图像 (3通道)
- `'Greyscale'`: 灰度图像 (1通道)

**window_size**:
- 推荐值: `512`
- 不建议修改 (模型训练时的固定大小)

**stride**:
- 推荐值: `256`
- 更小的 stride → 更高质量，更慢速度
  - `128`: 高质量，慢 4x
  - `256`: 平衡 (推荐)
  - `384`: 快速，质量略低

---

## 支持的图像格式

### 当前支持

- ✅ TIFF (.tif, .tiff)
  - 8-bit RGB
  - 16-bit RGB
  - 8-bit 灰度
  - 16-bit 灰度

### 即将支持

- 🚧 FITS (.fits) - 天文标准格式
- 🚧 PNG (.png) - 8/16-bit
- 🚧 JPEG (.jpg) - 仅用于预览

---

## 性能参考

| 图像大小 | CPU 型号 | 处理时间 |
|---------|---------|---------|
| 1048×712 | Apple M1 | ~5 秒 |
| 8256×5504 | Apple M1 | ~2 分钟 |
| 1048×712 | Intel i7 | ~15 秒 |
| 8256×5504 | Intel i7 | ~5 分钟 |

*测试配置: window_size=512, stride=256, CPU 模式*

---

## 常见问题

### Q: 为什么处理这么慢？

A: StarNet++ 使用深度神经网络，计算量较大。可以尝试：

1. **增大 stride** (牺牲质量换速度):
   ```python
   starnet = StarNet(mode='RGB', stride=384)  # 快 2x
   ```

2. **启用 GPU 加速** (macOS):
   ```bash
   pip install tensorflow-metal
   ```

3. **批量处理时使用多进程** (待开发功能)

### Q: 输出图像有伪影或边缘效应？

A: 这是滑动窗口处理的正常现象。可以尝试：

1. 减小 stride (增加重叠):
   ```python
   starnet = StarNet(mode='RGB', stride=128)
   ```

2. 增加图像边缘填充 (代码层面优化，待开发)

### Q: 某些星点没有被完全去除？

A: 可能的原因：

1. **星点太亮**: StarNet++ 对极亮星点效果有限
2. **图像质量**: 噪声过多影响识别
3. **模型限制**: StarNet++ 主要针对中小型星点

建议：
- 预处理图像降噪
- 调整曝光避免过曝
- 对极亮星点手动后处理

### Q: 如何处理批量图像？

A: 目前需要编写循环代码：

```python
from pathlib import Path

# 初始化模型（只需一次）
starnet = StarNet(mode='RGB')
starnet.load_model(weights='../models/weights')

# 批量处理
input_dir = Path('input_images')
output_dir = Path('output_images')
output_dir.mkdir(exist_ok=True)

for image_path in input_dir.glob('*.tif'):
    output_path = output_dir / f"{image_path.stem}_starless.tif"
    print(f"处理: {image_path.name}")
    starnet.transform(str(image_path), str(output_path))
    print(f"完成: {output_path.name}\n")
```

**注意**: 批量处理功能将在 Phase 2 开发完成。

---

## 下一步

1. **阅读完整文档**:
   - [README.md](README.md) - 项目概览
   - [PROJECT_PLAN.md](PROJECT_PLAN.md) - 开发路线图
   - [TECHNICAL_NOTES.md](TECHNICAL_NOTES.md) - 技术细节

2. **查看更多示例**:
   - `examples/` 目录中的示例代码

3. **参与开发**:
   - 查看 PROJECT_PLAN.md 了解待开发功能
   - 提交 Issue 或 Pull Request

4. **集成到你的项目**:
   - SuperStarOff 可作为独立模块使用
   - 参考 API 文档 (docs/API.md, 待编写)

---

## 获取帮助

- 📖 文档: 查看 `docs/` 目录
- 🐛 问题: 提交 GitHub Issue
- 💬 讨论: GitHub Discussions
- 📧 邮件: [联系方式待补充]

---

**Happy Star Removing! 🌟✨**
