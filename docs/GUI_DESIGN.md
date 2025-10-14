# SuperStarOff GUI 设计文档

**版本**: v1.0
**日期**: 2025-10-13
**状态**: 设计阶段

---

## 1. 项目概述

### 1.1 目标
创建一个**独立的桌面 GUI 应用**，用于星空摄影图像的星点去除处理。

### 1.2 核心功能
- 打开和预览星空图像
- 调整处理参数 (stride)
- 实时处理进度显示
- 去星前后对比预览
- 同步放大和移动对比
- 智能保存文件命名

### 1.3 目标用户
- 星空摄影爱好者
- 天文摄影师
- 需要批量处理星空图像的用户

---

## 2. 技术栈

### 2.1 GUI 框架选型

#### 方案对比

| 框架 | 优点 | 缺点 | 评分 |
|------|------|------|------|
| **PyQt6** | 功能强大、跨平台、外观现代 | 学习曲线陡、包体积大 | ⭐⭐⭐⭐⭐ |
| Tkinter | 内置、轻量、简单 | 外观陈旧、功能有限 | ⭐⭐⭐ |
| wxPython | 原生外观、功能丰富 | 文档不如 PyQt | ⭐⭐⭐⭐ |

**选择**: **PyQt6** - 功能完善，适合专业图像处理应用

### 2.2 核心依赖

```python
# GUI 框架
PyQt6>=6.6.0              # 主 GUI 框架
PyQt6-Qt6>=6.6.0          # Qt6 库

# 图像处理（已有）
tensorflow>=2.20.0        # 深度学习模型
keras>=3.11.0             # 高级 API
numpy>=1.26.0             # 数值计算
Pillow>=11.0.0            # 图像加载
tifffile>=2024.0.0        # TIFF 处理

# 工具库
qtawesome>=1.3.0          # 图标库
qdarkstyle>=3.2.0         # 暗色主题（可选）
```

---

## 3. 界面设计

### 3.1 主窗口布局

```
┌─────────────────────────────────────────────────────────────┐
│ SuperStarOff - 星点去除工具                       [_][□][×] │
├─────────────────────────────────────────────────────────────┤
│ [打开图像] [批量处理] [设置] [关于]                          │
├──────────────────────┬──────────────────────────────────────┤
│                      │                                      │
│   📂 图像信息        │   ⚙️ 处理参数                        │
│   ─────────          │   ─────────                          │
│   文件名: [...]      │   Stride:  ○128  ●256  ○384         │
│   尺寸: 8256×5504    │   Mode: ●RGB  ○Greyscale            │
│   格式: 16-bit TIFF  │   Window: 512 (快速预览)             │
│   大小: 128.5 MB     │                                      │
│                      │   [开始处理]                          │
│                      │                                      │
│                      │   ⏱️ 处理状态                         │
│                      │   ─────────                          │
│                      │   进度: ████████░░ 78%               │
│                      │   已用时间: 00:45                     │
│                      │   预计剩余: 00:12                     │
│                      │   当前: 处理分块 45/58                │
│                      │                                      │
└──────────────────────┴──────────────────────────────────────┘
│                                                             │
│   ┌────────────────────────┬────────────────────────┐      │
│   │  🌌 原图（带星点）      │  ✨ 去星后             │      │
│   │  ┌──────────────────┐  │  ┌──────────────────┐  │      │
│   │  │                  │  │  │                  │  │      │
│   │  │   [图像预览]     │  │  │   [图像预览]     │  │      │
│   │  │                  │  │  │                  │  │      │
│   │  │                  │  │  │                  │  │      │
│   │  └──────────────────┘  │  └──────────────────┘  │      │
│   │  🔍 100%  ⬅️➡️⬆️⬇️      │  🔍 100%  ⬅️➡️⬆️⬇️      │      │
│   │  [🔗 同步移动]          │                        │      │
│   └────────────────────────┴────────────────────────┘      │
│                                                             │
│   [💾 保存结果] [📁 另存为...] [🔄 重新处理]                │
│                                                             │
│   输出路径: /path/to/image_starless_stride256.tif           │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 区域划分

#### 顶部工具栏
- **打开图像**: 文件选择对话框
- **批量处理**: 多文件/文件夹选择
- **设置**: 默认参数、输出路径配置
- **关于**: 版本信息、使用说明

#### 左侧信息面板
- **图像信息区**: 显示当前图像元数据
- **参数控制区**: Stride、Mode、Window 调整
- **处理状态区**: 进度条、计时器、状态信息

#### 中间预览区域
- **原图预览窗口** (左)
- **去星后预览窗口** (右)
- **同步控制**: 缩放、平移同步
- **对比模式**: 分屏/滑动对比

#### 底部操作栏
- **保存按钮**: 自动命名保存
- **另存为按钮**: 自定义路径
- **重新处理**: 更改参数重新处理

---

## 4. 功能详细设计

### 4.1 图像加载

#### 支持格式
- ✅ TIFF (8-bit, 16-bit)
- ✅ PNG (8-bit, 16-bit)
- ✅ JPEG (仅用于预览)
- 🔲 FITS (Phase 2)

#### 加载流程
```
用户操作 → 打开图像
    ↓
验证文件格式 → 支持？
    ↓ 是
显示图像信息 → 左侧信息面板
    ↓
生成缩略图 → 左侧预览窗口
    ↓
启用处理按钮
```

#### 拖放支持
- 拖放文件到窗口 → 自动加载
- 拖放多个文件 → 批量处理模式

### 4.2 参数控制

#### Stride 选择
```python
STRIDE_OPTIONS = {
    128: "快速处理（可能有拼接痕迹）",
    256: "平衡模式（推荐）⭐",
    384: "高质量（处理较慢）"
}
```

- **单选按钮**: 128 / 256 / 384
- **默认值**: 256
- **说明提示**: 鼠标悬停显示说明

#### Mode 选择
```python
MODE_OPTIONS = {
    'RGB': "彩色图像",
    'Greyscale': "灰度图像"
}
```

- **自动检测**: 根据图像通道数自动选择
- **手动切换**: 单选按钮
- **警告提示**: 模式不匹配时提示用户

#### Window Size
- **固定值**: 512 (快速预览)
- **显示说明**: "模型窗口大小，固定为 512"

### 4.3 处理流程

#### 状态机设计
```
空闲 (Idle)
    ↓ 用户点击"开始处理"
准备中 (Preparing)
    ↓ 加载模型
处理中 (Processing)
    ↓ 逐块处理
完成 (Completed)
    ↓ 显示结果
```

#### 进度跟踪
```python
class ProcessingProgress:
    total_tiles: int        # 总分块数
    processed_tiles: int    # 已处理分块
    start_time: float       # 开始时间
    elapsed_time: str       # 已用时间 "00:45"
    estimated_remaining: str  # 预计剩余 "00:12"
    percentage: int         # 百分比 0-100
    current_status: str     # "处理分块 45/58"
```

#### 后台处理
- **QThread**: 在独立线程中运行 StarNet
- **信号更新**: 使用 Qt 信号更新 UI
- **取消支持**: 允许用户中途取消

```python
# 伪代码
class StarNetWorker(QThread):
    progress_updated = pyqtSignal(int, str)  # 进度、状态文本
    processing_completed = pyqtSignal(np.ndarray)  # 结果图像
    error_occurred = pyqtSignal(str)  # 错误信息

    def run(self):
        try:
            # 加载模型
            self.progress_updated.emit(5, "加载模型...")

            # 处理图像（分块）
            for i, tile in enumerate(tiles):
                if self.is_cancelled:
                    return
                process_tile(tile)
                progress = int((i+1) / total * 95) + 5
                self.progress_updated.emit(progress, f"处理分块 {i+1}/{total}")

            # 完成
            self.processing_completed.emit(result)
        except Exception as e:
            self.error_occurred.emit(str(e))
```

### 4.4 图像预览

#### 双窗口预览
- **左窗口**: 原图（带星点）
- **右窗口**: 去星后（处理完成后显示）

#### 同步功能
```python
class SyncImageViewer:
    sync_enabled: bool = True  # 同步开关

    def on_left_zoom(zoom_level):
        if sync_enabled:
            right_viewer.set_zoom(zoom_level)

    def on_left_pan(x, y):
        if sync_enabled:
            right_viewer.set_position(x, y)
```

#### 缩放控制
- **滚轮缩放**: 鼠标滚轮放大/缩小
- **缩放按钮**: 25% / 50% / 100% / 200% / 适应窗口
- **数值显示**: 当前缩放比例 "150%"

#### 平移控制
- **拖动平移**: 鼠标拖动移动图像
- **方向键**: ⬅️➡️⬆️⬇️ 微调位置
- **鼠标位置**: 实时显示像素坐标和 RGB 值

#### 对比模式（高级功能）
- **分屏对比**: 左右分屏显示
- **滑动对比**: 拖动滑块对比
- **闪烁对比**: 快速切换显示

### 4.5 文件保存

#### 自动命名规则
```python
def generate_output_filename(input_path, stride, mode):
    """
    示例:
    输入: /path/to/NGC7000_Ha.tif
    输出: /path/to/NGC7000_Ha_starless_stride256_RGB.tif
    """
    stem = Path(input_path).stem
    ext = Path(input_path).suffix
    parent = Path(input_path).parent

    output_name = f"{stem}_starless_stride{stride}_{mode}{ext}"
    return parent / output_name
```

#### 保存选项
- **默认保存**: 点击"保存结果" → 自动命名保存到源文件旁边
- **另存为**: 点击"另存为..." → 文件选择对话框
- **覆盖确认**: 文件已存在时弹窗确认
- **格式保持**: 保持原图像位深度和格式

#### 保存前预览
```
┌────────────────────────────────┐
│  保存确认                       │
├────────────────────────────────┤
│  输出路径:                      │
│  /path/to/NGC7000_Ha_starless_ │
│  stride256_RGB.tif             │
│                                │
│  格式: 16-bit TIFF             │
│  大小: 约 128.5 MB             │
│                                │
│  ⚠️ 文件已存在，是否覆盖?       │
│                                │
│  [取消]  [重命名]  [覆盖]       │
└────────────────────────────────┘
```

---

## 5. 用户交互流程

### 5.1 标准工作流

```
1. 打开图像
   ↓
   [用户] 点击"打开图像"或拖放文件
   ↓
   [系统] 加载图像，显示预览和信息

2. 调整参数（可选）
   ↓
   [用户] 选择 Stride (128/256/384)
   ↓
   [系统] 更新参数显示

3. 开始处理
   ↓
   [用户] 点击"开始处理"
   ↓
   [系统] 后台处理，显示进度
   ↓
   [系统] 处理完成，显示去星后图像

4. 预览对比
   ↓
   [用户] 缩放、平移、对比预览
   ↓
   [系统] 同步两个预览窗口

5. 保存结果
   ↓
   [用户] 点击"保存结果"
   ↓
   [系统] 自动命名保存
   ↓
   完成!
```

### 5.2 快捷键设计

| 快捷键 | 功能 |
|--------|------|
| `Ctrl+O` | 打开图像 |
| `Ctrl+S` | 保存结果 |
| `Ctrl+Shift+S` | 另存为 |
| `Ctrl+R` | 重新处理 |
| `Space` | 开始/暂停处理 |
| `+` / `-` | 缩放 |
| `0` | 适应窗口 |
| `1` | 100% 显示 |
| `Ctrl+D` | 开关同步移动 |
| `Esc` | 取消处理 |
| `F11` | 全屏模式 |

### 5.3 错误处理

#### 常见错误情况

1. **文件格式不支持**
   ```
   ⚠️ 不支持的文件格式

   文件: example.psd

   支持的格式: TIFF, PNG, JPEG

   [确定]
   ```

2. **文件损坏**
   ```
   ❌ 文件加载失败

   无法读取图像: corrupt.tif

   错误: 文件可能已损坏

   [确定]
   ```

3. **内存不足**
   ```
   ⚠️ 内存不足

   图像尺寸: 16000×12000 (太大)

   建议:
   - 使用较大的 stride 值
   - 缩小图像尺寸
   - 关闭其他程序

   [取消]  [继续尝试]
   ```

4. **模型加载失败**
   ```
   ❌ 模型加载失败

   找不到权重文件:
   /path/to/weights_G_RGB.h5

   请检查模型文件是否存在

   [重新下载]  [选择路径]  [取消]
   ```

5. **处理中断**
   ```
   ⚠️ 处理已取消

   是否保存部分结果?

   [放弃]  [保存部分结果]
   ```

---

## 6. 性能优化

### 6.1 加载优化

#### 大图像处理
```python
# 生成缩略图用于预览
PREVIEW_MAX_SIZE = (1024, 1024)

def load_image_for_preview(path):
    """快速加载缩略图用于预览"""
    img = Image.open(path)
    img.thumbnail(PREVIEW_MAX_SIZE, Image.LANCZOS)
    return img

def load_image_for_processing(path):
    """加载完整图像用于处理"""
    return tiff.imread(path)
```

#### 延迟加载
- 预览窗口显示缩略图
- 仅在处理时加载完整图像
- 减少内存占用

### 6.2 处理优化

#### 进度回调
```python
# 在 starnet_v1_TF2.py 中添加回调
def transform(self, in_name, out_name, progress_callback=None):
    """
    progress_callback(current, total, message)
    """
    for i in range(ith):
        for j in range(itw):
            # 处理分块...

            if progress_callback:
                current = i * itw + j + 1
                total = ith * itw
                progress_callback(current, total, f"处理分块 {current}/{total}")
```

#### 取消支持
```python
class StarNet:
    def __init__(self):
        self._cancelled = False

    def cancel_processing(self):
        self._cancelled = True

    def transform(self, ...):
        for i in range(ith):
            if self._cancelled:
                raise ProcessingCancelledException()
            # 处理...
```

### 6.3 内存优化

#### 分块处理
- 已有分块机制 (window_size + stride)
- 避免一次性加载所有数据到 GPU

#### 图像释放
```python
def on_new_image_loaded():
    # 释放旧图像内存
    if self.previous_image is not None:
        del self.previous_image
        gc.collect()

    # 加载新图像
    self.current_image = load_image(path)
```

---

## 7. 扩展功能（未来）

### 7.1 批量处理模式

```
┌─────────────────────────────────┐
│  批量处理                        │
├─────────────────────────────────┤
│  文件列表:                       │
│  ☑ NGC7000_Ha.tif               │
│  ☑ NGC7000_OIII.tif             │
│  ☑ NGC7000_SII.tif              │
│  ☐ test_image.jpg (不支持)      │
│                                 │
│  共 3 个文件，总计 385 MB        │
│                                 │
│  参数: Stride 256, RGB          │
│                                 │
│  输出目录:                       │
│  /path/to/output/               │
│  [浏览...]                       │
│                                 │
│  [开始批量处理]                  │
│                                 │
│  总进度: ██████░░░░ 2/3 (67%)   │
│  当前: NGC7000_OIII.tif          │
└─────────────────────────────────┘
```

### 7.2 参数预设

```python
PRESETS = {
    "快速预览": {"stride": 128, "mode": "RGB"},
    "标准质量": {"stride": 256, "mode": "RGB"},
    "最高质量": {"stride": 384, "mode": "RGB"},
    "灰度图像": {"stride": 256, "mode": "Greyscale"}
}
```

### 7.3 历史记录

```
┌─────────────────────────────────┐
│  处理历史                        │
├─────────────────────────────────┤
│  2025-10-13 14:32               │
│  NGC7000_Ha.tif                 │
│  Stride: 256, RGB               │
│  用时: 02:15                     │
│  [重新处理] [打开结果]           │
│  ─────────────────────────      │
│  2025-10-13 13:45               │
│  M31_core.tif                   │
│  Stride: 384, RGB               │
│  用时: 05:42                     │
│  [重新处理] [打开结果]           │
└─────────────────────────────────┘
```

### 7.4 FITS 格式支持

- 读取 FITS 头信息
- 保留 WCS 坐标
- 支持多扩展 FITS
- 天文工具集成（DS9、PixInsight）

---

## 8. 开发优先级

### Phase 1: MVP (最小可行产品) - 2周
- [x] 基础窗口框架
- [x] 图像加载和预览
- [x] 参数控制（Stride）
- [x] 开始处理按钮
- [x] 进度条和计时器
- [x] 结果预览
- [x] 保存功能

### Phase 2: 增强体验 - 1周
- [ ] 同步缩放和平移
- [ ] 拖放文件支持
- [ ] 快捷键支持
- [ ] 错误处理和提示
- [ ] 取消处理功能

### Phase 3: 高级功能 - 1周
- [ ] 批量处理模式
- [ ] 参数预设
- [ ] 对比模式（滑动/闪烁）
- [ ] 处理历史记录

### Phase 4: 优化和发布 - 1周
- [ ] 性能优化
- [ ] 打包成独立应用（PyInstaller）
- [ ] 用户文档
- [ ] 发布和分发

---

## 9. 技术实现要点

### 9.1 项目结构

```
SuperStarOff/
├── src/
│   ├── starnet_v1_TF2.py          # 现有模型代码
│   ├── gui/                        # GUI 代码
│   │   ├── __init__.py
│   │   ├── main_window.py          # 主窗口
│   │   ├── image_viewer.py         # 图像预览组件
│   │   ├── parameter_panel.py      # 参数控制面板
│   │   ├── progress_widget.py      # 进度显示组件
│   │   ├── worker_thread.py        # 后台处理线程
│   │   └── utils.py                # 工具函数
│   └── app.py                      # 应用入口
├── resources/                      # 资源文件
│   ├── icons/                      # 图标
│   ├── styles/                     # 样式表
│   └── about.html                  # 关于页面
├── models/                         # 模型权重
├── examples/                       # 示例图像
└── docs/                           # 文档
```

### 9.2 关键代码模板

#### main_window.py
```python
from PyQt6.QtWidgets import QMainWindow, QWidget, QHBoxLayout
from PyQt6.QtCore import pyqtSlot

class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("SuperStarOff - 星点去除工具")
        self.resize(1400, 900)

        # 创建中央 widget
        central_widget = QWidget()
        self.setCentralWidget(central_widget)

        # 创建布局
        layout = QHBoxLayout()
        central_widget.setLayout(layout)

        # 添加组件
        self.left_panel = ParameterPanel()
        self.image_viewer = ImageViewer()

        layout.addWidget(self.left_panel, 1)
        layout.addWidget(self.image_viewer, 3)

        # 连接信号
        self.left_panel.start_processing.connect(self.on_start_processing)

    @pyqtSlot()
    def on_start_processing(self):
        # 启动处理线程...
        pass
```

#### worker_thread.py
```python
from PyQt6.QtCore import QThread, pyqtSignal
import numpy as np

class StarNetWorker(QThread):
    progress_updated = pyqtSignal(int, str)
    processing_completed = pyqtSignal(np.ndarray)
    error_occurred = pyqtSignal(str)

    def __init__(self, image_path, params):
        super().__init__()
        self.image_path = image_path
        self.params = params
        self._cancelled = False

    def run(self):
        try:
            from starnet_v1_TF2 import StarNet

            self.progress_updated.emit(5, "加载模型...")
            starnet = StarNet(mode=self.params['mode'],
                            stride=self.params['stride'])
            starnet.load_model(weights='../models/weights')

            self.progress_updated.emit(10, "开始处理...")
            # 处理图像...

            self.processing_completed.emit(result)
        except Exception as e:
            self.error_occurred.emit(str(e))
```

---

## 10. 测试计划

### 10.1 功能测试

| 功能 | 测试用例 | 预期结果 |
|------|---------|---------|
| 图像加载 | 加载 TIFF 文件 | 正确显示预览 |
| 图像加载 | 加载不支持格式 | 显示错误提示 |
| 参数调整 | 切换 Stride | 界面正确更新 |
| 开始处理 | 点击处理按钮 | 进度条正常显示 |
| 进度显示 | 处理过程中 | 进度准确，时间估算合理 |
| 取消处理 | 处理中点击取消 | 立即停止，资源释放 |
| 预览缩放 | 滚轮缩放 | 图像正确缩放 |
| 同步移动 | 拖动左侧图像 | 右侧同步移动 |
| 保存结果 | 点击保存 | 文件正确保存，命名符合规则 |

### 10.2 性能测试

| 测试项 | 测试数据 | 性能目标 |
|--------|---------|---------|
| 小图像 | 1000×1000 | < 10秒 |
| 中图像 | 4000×4000 | < 1分钟 |
| 大图像 | 8000×8000 | < 3分钟 |
| 超大图像 | 16000×16000 | < 10分钟 |
| 内存占用 | 任意图像 | < 4GB |

### 10.3 用户体验测试

- 界面响应速度（< 100ms）
- 错误提示清晰易懂
- 进度显示准确
- 快捷键工作正常
- 窗口大小调整正常

---

## 11. 部署和发布

### 11.1 打包方案

使用 **PyInstaller** 打包成独立应用

```bash
# macOS
pyinstaller --windowed \
            --name "SuperStarOff" \
            --icon resources/icon.icns \
            --add-data "models:models" \
            --add-data "resources:resources" \
            src/app.py

# Windows
pyinstaller --windowed \
            --name "SuperStarOff" \
            --icon resources/icon.ico \
            --add-data "models;models" \
            --add-data "resources;resources" \
            src/app.py
```

### 11.2 安装包

- **macOS**: .dmg 镜像 + .app 包
- **Windows**: .exe 安装程序（NSIS）
- **Linux**: AppImage

### 11.3 发布渠道

- GitHub Releases
- 官网下载
- 论坛分享（牧夫天文、无忌摄影）

---

## 12. 文档计划

### 12.1 用户文档

- **快速开始指南**: 5 分钟上手
- **用户手册**: 完整功能说明
- **FAQ**: 常见问题解答
- **视频教程**: 操作演示

### 12.2 开发文档

- **架构设计**: 本文档
- **API 文档**: 代码注释生成
- **贡献指南**: 如何参与开发

---

## 13. 总结

### 核心优势
✅ **易用性**: 直观的图形界面，无需命令行
✅ **专业性**: 专为星空摄影设计的功能
✅ **性能**: 后台处理，界面不卡顿
✅ **灵活性**: 可调参数，满足不同需求
✅ **可扩展**: 模块化设计，便于添加功能

### 开发周期
- **Phase 1 (MVP)**: 2 周
- **Phase 2 (增强)**: 1 周
- **Phase 3 (高级)**: 1 周
- **Phase 4 (发布)**: 1 周
- **总计**: **5 周**

### 下一步
1. 搭建基础 PyQt6 框架
2. 实现图像加载和预览
3. 集成 StarNet 处理功能
4. 添加进度显示和保存功能

---

**文档版本**: v1.0
**最后更新**: 2025-10-13
**维护者**: SuperStarOff Team
