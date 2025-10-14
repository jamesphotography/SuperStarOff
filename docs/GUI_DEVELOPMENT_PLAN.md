# SuperStarOff GUI 开发计划

**版本**: v1.0
**创建日期**: 2025-10-13
**预计完成**: 2025-11-17 (5周)

---

## 📋 开发里程碑

| 阶段 | 周期 | 完成日期 | 状态 |
|------|------|---------|------|
| **Phase 1: MVP** | 2周 | 2025-10-27 | 🔲 未开始 |
| **Phase 2: 增强体验** | 1周 | 2025-11-03 | 🔲 未开始 |
| **Phase 3: 高级功能** | 1周 | 2025-11-10 | 🔲 未开始 |
| **Phase 4: 优化发布** | 1周 | 2025-11-17 | 🔲 未开始 |

**总计**: 5 周

---

## Phase 1: MVP (最小可行产品) - 2周

**目标**: 实现基础功能，能完成一张图像的去星处理

**完成日期**: 2025-10-27

### Week 1: 基础框架 (2025-10-13 ~ 2025-10-20)

#### Day 1-2: 项目搭建
- [x] 创建 GUI 项目结构
- [ ] 安装 PyQt6 环境
- [ ] 创建主窗口基础框架
- [ ] 测试 PyQt6 运行环境

**任务清单**:
```bash
# 创建目录结构
mkdir -p src/gui
mkdir -p resources/icons
mkdir -p resources/styles

# 创建文件
touch src/gui/__init__.py
touch src/gui/main_window.py
touch src/gui/image_viewer.py
touch src/gui/parameter_panel.py
touch src/gui/progress_widget.py
touch src/gui/worker_thread.py
touch src/gui/utils.py
touch src/app.py

# 安装依赖
pip install -r requirements_gui.txt
```

**验收标准**:
- ✅ 空白主窗口可以运行
- ✅ 窗口标题、尺寸正确
- ✅ 窗口可以正常关闭

#### Day 3-4: 图像加载和预览
- [ ] 实现文件打开对话框
- [ ] 实现图像加载功能
- [ ] 实现图像预览显示（左侧窗口）
- [ ] 显示图像信息（尺寸、格式、大小）

**核心代码**:
```python
# src/gui/image_viewer.py
class ImageViewer(QLabel):
    def __init__(self):
        super().__init__()
        self.image = None
        self.scaled_image = None

    def load_image(self, path):
        self.image = QPixmap(path)
        self.fit_to_window()

    def fit_to_window(self):
        if self.image:
            scaled = self.image.scaled(
                self.size(),
                Qt.AspectRatioMode.KeepAspectRatio,
                Qt.TransformationMode.SmoothTransformation
            )
            self.setPixmap(scaled)
```

**验收标准**:
- ✅ 点击"打开图像"弹出文件选择对话框
- ✅ 选择 TIFF 文件后正确显示预览
- ✅ 图像信息显示准确
- ✅ 图像按比例适应窗口

#### Day 5-6: 参数控制面板
- [ ] 创建参数控制面板 UI
- [ ] 实现 Stride 单选按钮 (128/256/384)
- [ ] 实现 Mode 单选按钮 (RGB/Greyscale)
- [ ] 显示处理参数说明
- [ ] 添加"开始处理"按钮

**核心代码**:
```python
# src/gui/parameter_panel.py
class ParameterPanel(QWidget):
    start_processing = pyqtSignal(dict)  # 参数字典信号

    def __init__(self):
        super().__init__()
        self.stride = 256
        self.mode = 'RGB'
        self.init_ui()

    def init_ui(self):
        layout = QVBoxLayout()

        # Stride 选择
        stride_group = QGroupBox("Stride 步长")
        stride_layout = QVBoxLayout()

        self.stride_128 = QRadioButton("128 - 快速处理")
        self.stride_256 = QRadioButton("256 - 平衡模式 ⭐")
        self.stride_384 = QRadioButton("384 - 高质量")
        self.stride_256.setChecked(True)

        stride_layout.addWidget(self.stride_128)
        stride_layout.addWidget(self.stride_256)
        stride_layout.addWidget(self.stride_384)
        stride_group.setLayout(stride_layout)

        # 开始处理按钮
        self.start_button = QPushButton("开始处理")
        self.start_button.clicked.connect(self.on_start_clicked)

        layout.addWidget(stride_group)
        layout.addWidget(self.start_button)
        self.setLayout(layout)

    def on_start_clicked(self):
        params = {
            'stride': self.stride,
            'mode': self.mode
        }
        self.start_processing.emit(params)
```

**验收标准**:
- ✅ 参数面板正确显示
- ✅ Stride 单选按钮工作正常
- ✅ Mode 单选按钮工作正常
- ✅ 点击"开始处理"触发信号

#### Day 7: 集成测试
- [ ] 集成所有组件到主窗口
- [ ] 测试图像加载流程
- [ ] 测试参数调整功能
- [ ] 修复 bug

**验收标准**:
- ✅ 完整流程可运行
- ✅ 界面布局正确
- ✅ 无明显 bug

### Week 2: 处理功能 (2025-10-21 ~ 2025-10-27)

#### Day 8-9: 后台处理线程
- [ ] 创建 StarNetWorker 线程类
- [ ] 实现模型加载
- [ ] 实现图像处理
- [ ] 实现进度信号发送

**核心代码**:
```python
# src/gui/worker_thread.py
class StarNetWorker(QThread):
    progress_updated = pyqtSignal(int, str)  # 百分比, 状态文本
    processing_completed = pyqtSignal(str)  # 输出文件路径
    error_occurred = pyqtSignal(str)  # 错误信息

    def __init__(self, input_path, output_path, params):
        super().__init__()
        self.input_path = input_path
        self.output_path = output_path
        self.params = params
        self._cancelled = False

    def run(self):
        try:
            import sys
            sys.path.insert(0, '../src')
            from starnet_v1_TF2 import StarNet

            # 加载模型
            self.progress_updated.emit(5, "加载模型...")
            starnet = StarNet(
                mode=self.params['mode'],
                window_size=512,
                stride=self.params['stride']
            )
            starnet.load_model(weights='../models/weights')

            # 处理图像
            self.progress_updated.emit(10, "开始处理...")
            starnet.transform(self.input_path, self.output_path)

            # 完成
            self.progress_updated.emit(100, "处理完成!")
            self.processing_completed.emit(self.output_path)

        except Exception as e:
            self.error_occurred.emit(str(e))
```

**验收标准**:
- ✅ 线程可以正常启动
- ✅ 模型加载成功
- ✅ 图像处理成功
- ✅ 进度信号正确发送

#### Day 10-11: 进度显示
- [ ] 创建进度显示组件
- [ ] 实现进度条
- [ ] 实现计时器（已用时间）
- [ ] 实现状态文本显示
- [ ] 连接线程信号到 UI

**核心代码**:
```python
# src/gui/progress_widget.py
class ProgressWidget(QWidget):
    def __init__(self):
        super().__init__()
        self.start_time = None
        self.timer = QTimer()
        self.timer.timeout.connect(self.update_time)
        self.init_ui()

    def init_ui(self):
        layout = QVBoxLayout()

        # 进度条
        self.progress_bar = QProgressBar()
        self.progress_bar.setRange(0, 100)

        # 状态标签
        self.status_label = QLabel("准备就绪")

        # 时间标签
        self.time_label = QLabel("用时: 00:00")

        layout.addWidget(QLabel("处理状态:"))
        layout.addWidget(self.progress_bar)
        layout.addWidget(self.status_label)
        layout.addWidget(self.time_label)

        self.setLayout(layout)

    def start_processing(self):
        self.start_time = time.time()
        self.timer.start(1000)  # 每秒更新
        self.progress_bar.setValue(0)

    def update_progress(self, value, status):
        self.progress_bar.setValue(value)
        self.status_label.setText(status)

    def update_time(self):
        if self.start_time:
            elapsed = int(time.time() - self.start_time)
            minutes = elapsed // 60
            seconds = elapsed % 60
            self.time_label.setText(f"用时: {minutes:02d}:{seconds:02d}")

    def finish_processing(self):
        self.timer.stop()
        self.progress_bar.setValue(100)
```

**验收标准**:
- ✅ 进度条正确显示
- ✅ 计时器准确计时
- ✅ 状态文本实时更新
- ✅ 处理完成后停止计时

#### Day 12-13: 结果预览和保存
- [ ] 实现右侧结果预览窗口
- [ ] 处理完成后自动显示结果
- [ ] 实现保存功能
- [ ] 实现自动文件命名

**核心代码**:
```python
# src/gui/utils.py
def generate_output_filename(input_path, stride, mode):
    """生成输出文件名"""
    from pathlib import Path

    path = Path(input_path)
    stem = path.stem
    ext = path.suffix
    parent = path.parent

    output_name = f"{stem}_starless_stride{stride}_{mode}{ext}"
    return str(parent / output_name)

# 在主窗口中
def on_processing_completed(self, output_path):
    # 加载结果图像
    self.right_viewer.load_image(output_path)

    # 显示成功消息
    QMessageBox.information(
        self,
        "处理完成",
        f"图像已成功处理!\n\n输出文件:\n{output_path}"
    )
```

**验收标准**:
- ✅ 处理完成后右侧显示结果
- ✅ 文件自动命名正确
- ✅ 文件保存成功
- ✅ 弹窗提示用户

#### Day 14: Phase 1 集成测试
- [ ] 完整流程测试
- [ ] 测试各种图像尺寸
- [ ] 测试各种参数组合
- [ ] 修复所有 bug
- [ ] 优化用户体验

**测试用例**:
1. 小图像 (1000×1000)
2. 中图像 (4000×4000)
3. 大图像 (8000×8000)
4. RGB 图像
5. 灰度图像
6. 各种 Stride 值

**验收标准**:
- ✅ 所有测试用例通过
- ✅ 界面流畅无卡顿
- ✅ 无明显 bug
- ✅ 可以独立运行

---

## Phase 2: 增强体验 - 1周

**目标**: 改善用户体验，添加常用功能

**完成日期**: 2025-11-03

### Week 3: 用户体验优化 (2025-10-28 ~ 2025-11-03)

#### Day 15-16: 同步缩放和平移
- [ ] 实现图像缩放功能
- [ ] 实现图像平移功能
- [ ] 实现双窗口同步
- [ ] 添加缩放控制按钮

**核心功能**:
```python
class SyncImageViewer(QScrollArea):
    def __init__(self):
        super().__init__()
        self.zoom_level = 1.0
        self.sync_enabled = True

    def wheelEvent(self, event):
        # 滚轮缩放
        if event.angleDelta().y() > 0:
            self.zoom_in()
        else:
            self.zoom_out()

    def zoom_in(self):
        self.zoom_level *= 1.2
        self.update_zoom()
        if self.sync_enabled and self.partner:
            self.partner.set_zoom(self.zoom_level)

    def update_zoom(self):
        if self.image:
            size = self.image.size() * self.zoom_level
            scaled = self.image.scaled(size)
            self.image_label.setPixmap(scaled)
```

**验收标准**:
- ✅ 滚轮缩放工作正常
- ✅ 双窗口同步缩放
- ✅ 双窗口同步平移
- ✅ 同步开关可切换

#### Day 17: 拖放文件支持
- [ ] 实现拖放文件功能
- [ ] 验证文件格式
- [ ] 自动加载拖放的文件

**核心代码**:
```python
class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setAcceptDrops(True)

    def dragEnterEvent(self, event):
        if event.mimeData().hasUrls():
            event.acceptProposedAction()

    def dropEvent(self, event):
        files = [u.toLocalFile() for u in event.mimeData().urls()]
        if files:
            self.load_image(files[0])
```

**验收标准**:
- ✅ 拖放文件到窗口可自动加载
- ✅ 不支持格式显示错误提示
- ✅ 多文件拖放提示选择

#### Day 18: 快捷键支持
- [ ] 实现所有快捷键
- [ ] 添加快捷键提示
- [ ] 创建快捷键帮助文档

**快捷键列表**:
```python
SHORTCUTS = {
    'Ctrl+O': '打开图像',
    'Ctrl+S': '保存结果',
    'Ctrl+R': '重新处理',
    'Space': '开始处理',
    '+': '放大',
    '-': '缩小',
    '0': '适应窗口',
    '1': '100% 显示',
    'Esc': '取消处理',
}
```

**验收标准**:
- ✅ 所有快捷键工作正常
- ✅ 快捷键不冲突
- ✅ 有快捷键帮助菜单

#### Day 19: 错误处理和提示
- [ ] 完善所有错误提示
- [ ] 添加错误恢复机制
- [ ] 添加日志记录

**错误类型**:
1. 文件不存在
2. 格式不支持
3. 文件损坏
4. 内存不足
5. 模型加载失败
6. 处理中断

**验收标准**:
- ✅ 所有错误都有清晰提示
- ✅ 错误不导致程序崩溃
- ✅ 日志正确记录

#### Day 20: 取消处理功能
- [ ] 添加"取消"按钮
- [ ] 实现处理中断机制
- [ ] 资源清理和恢复

**核心代码**:
```python
class StarNetWorker(QThread):
    def __init__(self):
        super().__init__()
        self._cancelled = False

    def cancel(self):
        self._cancelled = True

    def run(self):
        for i in range(total):
            if self._cancelled:
                return  # 退出处理
            # 处理...
```

**验收标准**:
- ✅ 点击取消立即停止处理
- ✅ 资源正确释放
- ✅ UI 恢复到就绪状态

#### Day 21: Phase 2 测试
- [ ] 完整测试所有新功能
- [ ] 性能测试
- [ ] 用户体验测试
- [ ] 修复 bug

---

## Phase 3: 高级功能 - 1周

**目标**: 添加专业功能，提升工具竞争力

**完成日期**: 2025-11-10

### Week 4: 高级功能开发 (2025-11-04 ~ 2025-11-10)

#### Day 22-23: 批量处理模式
- [ ] 创建批量处理对话框
- [ ] 文件列表管理
- [ ] 批量参数设置
- [ ] 批量处理进度

**核心功能**:
```python
class BatchProcessDialog(QDialog):
    def __init__(self):
        super().__init__()
        self.file_list = []
        self.init_ui()

    def add_files(self):
        files, _ = QFileDialog.getOpenFileNames(
            self, "选择图像文件", "",
            "图像文件 (*.tif *.tiff *.png)"
        )
        self.file_list.extend(files)
        self.update_file_list()

    def start_batch_processing(self):
        for i, file in enumerate(self.file_list):
            # 处理每个文件
            self.update_progress(i+1, len(self.file_list))
```

**验收标准**:
- ✅ 可以添加多个文件
- ✅ 批量处理正常工作
- ✅ 总进度正确显示
- ✅ 错误不中断批量处理

#### Day 24: 参数预设
- [ ] 创建预设管理器
- [ ] 保存/加载预设
- [ ] 快速切换预设

**预设配置**:
```python
PRESETS = {
    "快速预览": {
        "stride": 128,
        "mode": "RGB",
        "description": "快速处理，适合预览"
    },
    "标准质量": {
        "stride": 256,
        "mode": "RGB",
        "description": "平衡模式，推荐使用"
    },
    "最高质量": {
        "stride": 384,
        "mode": "RGB",
        "description": "高质量处理，较慢"
    }
}
```

**验收标准**:
- ✅ 预设可以保存
- ✅ 预设可以加载
- ✅ 预设可以删除
- ✅ 有默认预设

#### Day 25: 对比模式
- [ ] 实现滑动对比
- [ ] 实现闪烁对比
- [ ] 实现分屏对比

**验收标准**:
- ✅ 三种对比模式都可用
- ✅ 对比流畅无卡顿
- ✅ 可以随时切换模式

#### Day 26-27: 处理历史记录
- [ ] 记录处理历史
- [ ] 历史记录查看
- [ ] 快速重新处理
- [ ] 历史记录管理

**数据结构**:
```python
history_item = {
    "timestamp": "2025-10-13 14:32:15",
    "input_file": "/path/to/input.tif",
    "output_file": "/path/to/output.tif",
    "parameters": {"stride": 256, "mode": "RGB"},
    "processing_time": 125.3,  # 秒
    "status": "success"
}
```

**验收标准**:
- ✅ 自动记录历史
- ✅ 历史记录持久化
- ✅ 可以查看历史详情
- ✅ 可以重新处理

#### Day 28: Phase 3 测试
- [ ] 测试所有高级功能
- [ ] 性能测试
- [ ] 修复 bug

---

## Phase 4: 优化和发布 - 1周

**目标**: 优化性能，打包发布

**完成日期**: 2025-11-17

### Week 5: 优化和发布 (2025-11-11 ~ 2025-11-17)

#### Day 29-30: 性能优化
- [ ] 启动速度优化
- [ ] 内存占用优化
- [ ] 处理速度优化
- [ ] UI 响应优化

**优化项**:
1. 延迟加载模型（首次使用时加载）
2. 图像缩略图缓存
3. 进度更新频率控制
4. 内存及时释放

**验收标准**:
- ✅ 启动时间 < 3秒
- ✅ 内存占用 < 4GB
- ✅ UI 响应 < 100ms

#### Day 31-32: 打包测试
- [ ] 配置 PyInstaller
- [ ] 打包 macOS 应用
- [ ] 打包 Windows 应用
- [ ] 测试打包后的应用

**打包脚本**:
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

**验收标准**:
- ✅ 打包成功
- ✅ 独立应用可运行
- ✅ 模型文件正确包含
- ✅ 应用大小合理 (< 1GB)

#### Day 33: 文档编写
- [ ] 用户手册
- [ ] 快速开始指南
- [ ] FAQ
- [ ] 视频教程脚本

**文档列表**:
1. `USER_GUIDE.md` - 用户手册
2. `QUICKSTART_GUI.md` - 快速开始
3. `FAQ.md` - 常见问题
4. `CHANGELOG.md` - 更新日志

**验收标准**:
- ✅ 所有文档完成
- ✅ 文档清晰易懂
- ✅ 有截图示例

#### Day 34: 发布准备
- [ ] 创建 GitHub Release
- [ ] 上传安装包
- [ ] 发布公告
- [ ] 社区推广

**发布清单**:
- [x] 源代码打包
- [ ] macOS .dmg 安装包
- [ ] Windows .exe 安装程序
- [ ] 用户文档
- [ ] 发布说明
- [ ] 演示视频

#### Day 35: Phase 4 验收
- [ ] 最终测试
- [ ] 发布检查
- [ ] 用户反馈收集

---

## 📊 开发进度跟踪

### 每日站会
- 回顾昨天完成内容
- 计划今天任务
- 讨论遇到的问题

### 每周回顾
- 总结本周进度
- 评估下周计划
- 调整开发策略

### 质量检查点
- Week 1 末: Phase 1 基础功能 review
- Week 2 末: Phase 1 完整测试
- Week 3 末: Phase 2 用户体验 review
- Week 4 末: Phase 3 高级功能 review
- Week 5 末: 最终发布 review

---

## 🔧 开发工具

### IDE
- **PyCharm** 或 **VSCode**
- PyQt6 插件
- Git 版本控制

### 调试工具
- Qt Designer (界面设计)
- Qt Creator (预览)
- Python Debugger

### 测试工具
- pytest
- pytest-qt
- Qt Test Framework

---

## 📦 交付物

### 代码交付
- [ ] 源代码（GitHub 仓库）
- [ ] 注释完整的代码
- [ ] 单元测试

### 应用交付
- [ ] macOS .dmg 安装包
- [ ] Windows .exe 安装程序
- [ ] Linux AppImage (可选)

### 文档交付
- [ ] 用户手册
- [ ] 开发文档
- [ ] API 文档
- [ ] 视频教程

---

## ⚠️ 风险管理

### 技术风险

| 风险 | 可能性 | 影响 | 缓解措施 |
|------|--------|------|---------|
| PyQt6 学习曲线陡 | 中 | 中 | 提前学习，参考示例代码 |
| 性能不达标 | 低 | 高 | 早期性能测试，及时优化 |
| 打包问题 | 中 | 中 | 多平台测试，提前验证 |
| 模型加载慢 | 低 | 低 | 延迟加载，显示加载进度 |

### 进度风险

| 风险 | 可能性 | 影响 | 缓解措施 |
|------|--------|------|---------|
| 功能开发超时 | 中 | 中 | 预留缓冲时间，优先核心功能 |
| Bug 修复耗时 | 中 | 低 | 持续测试，及时发现问题 |
| 文档编写不足 | 低 | 低 | 边开发边写文档 |

---

## ✅ 验收标准

### 功能完整性
- ✅ 所有 Phase 1-4 功能完成
- ✅ 所有测试用例通过
- ✅ 无严重 bug

### 性能指标
- ✅ 小图像 (1000×1000) < 10秒
- ✅ 中图像 (4000×4000) < 1分钟
- ✅ 大图像 (8000×8000) < 3分钟
- ✅ 内存占用 < 4GB
- ✅ 启动时间 < 3秒

### 用户体验
- ✅ 界面美观专业
- ✅ 操作直观简单
- ✅ 错误提示清晰
- ✅ 响应速度快

### 文档质量
- ✅ 用户手册完整
- ✅ API 文档齐全
- ✅ 代码注释充分
- ✅ 有视频教程

---

## 🎯 成功指标

### 短期目标 (1个月)
- [ ] 发布 v1.0 版本
- [ ] 获得 10+ 用户反馈
- [ ] GitHub Stars > 50

### 中期目标 (3个月)
- [ ] 用户数 > 100
- [ ] 处理图像 > 1000 张
- [ ] GitHub Stars > 200
- [ ] 社区贡献者 > 3

### 长期目标 (6个月)
- [ ] 用户数 > 500
- [ ] GitHub Stars > 500
- [ ] 集成到 SuperStarTrail
- [ ] 支持 Photoshop 插件

---

## 📞 联系方式

**项目负责人**: SuperStarOff Team
**邮箱**: [待补充]
**GitHub**: https://github.com/[待补充]/SuperStarOff

---

**文档版本**: v1.0
**创建日期**: 2025-10-13
**最后更新**: 2025-10-13
**状态**: 📋 计划阶段
