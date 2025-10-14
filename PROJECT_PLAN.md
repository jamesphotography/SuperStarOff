# SuperStarOff 项目开发计划

## 项目概览

SuperStarOff 是基于 StarNet++ 神经网络的独立星点去除工具，可作为独立项目使用，也可集成到 SuperStarTrail 星轨叠加工具中。

**项目状态**: 🟢 Alpha 阶段 (可用但功能有限)

**最后更新**: 2025-10-13

---

## 开发阶段

### Phase 0: 基础设施 ✅ (已完成)

**目标**: 让 StarNet++ 在本地环境运行

**完成日期**: 2025-10-13

#### 已完成任务

- [x] 下载 StarNet++ 预训练模型 (401MB 权重文件)
- [x] 修复 Keras 3 兼容性问题
  - [x] 替换 `tf.concat` 为 `L.Concatenate`
  - [x] 替换 `tf.math.subtract` 为 `L.Subtract`
  - [x] 替换 `tf.nn.sigmoid` 为 `L.Activation`
  - [x] 替换 `tiff.imsave` 为 `tiff.imwrite`
- [x] 成功运行基础测试
- [x] 创建 SuperStarOff 独立项目结构
- [x] 迁移所有相关文件到子目录

#### 技术决策

1. **使用 TensorFlow 2.x + Keras 3** 而非 TensorFlow 1.x
   - 原因: TF 1.x 已停止维护，TF 2.x 是未来方向
   - 结果: 需要修复多个 Keras 3 兼容性问题

2. **使用 .h5 权重文件** 而非 .ckpt checkpoint
   - 原因: Git LFS 限制导致 .ckpt 无法下载
   - 结果: 使用 Dropbox 提供的 .h5 权重，配合 starnet_v1_TF2.py

3. **创建独立子项目** 而非直接集成
   - 原因: 便于独立开发和测试，保持代码模块化
   - 结果: 可作为独立工具使用或集成到其他项目

---

### Phase 1: 核心功能封装 🚧 (进行中)

**目标**: 创建易用的 Python API

**预计完成**: 2025-10-20

#### 计划任务

- [ ] 创建 `starnet_processor.py` 高级封装
  - [ ] 简化 API 调用
  - [ ] 自动处理路径和配置
  - [ ] 添加错误处理和日志
  - [ ] 支持进度回调
- [ ] 添加配置管理
  - [ ] 模型路径配置
  - [ ] 默认参数配置
  - [ ] 用户配置文件支持
- [ ] 完善示例代码
  - [ ] 单图处理示例
  - [ ] 批量处理示例
  - [ ] 参数调优示例

#### 技术要点

```python
# 目标 API 设计
from superstaroff import StarNetProcessor

processor = StarNetProcessor(mode='RGB')  # 自动加载模型
result = processor.process('input.tif', 'output.tif')
```

---

### Phase 2: 批量处理和 CLI 🔲 (未开始)

**目标**: 支持批量处理和命令行工具

**预计完成**: 2025-10-30

#### 计划任务

- [ ] 批量处理功能
  - [ ] 支持目录批量处理
  - [ ] 多线程/多进程加速
  - [ ] 进度显示和估时
  - [ ] 错误恢复机制
- [ ] 命令行工具
  - [ ] 参数解析 (argparse)
  - [ ] 彩色输出和进度条
  - [ ] 详细日志模式
- [ ] 性能优化
  - [ ] 模型推理加速
  - [ ] 内存优化
  - [ ] GPU 支持检测

#### CLI 设计草案

```bash
# 单文件处理
superstaroff process input.tif -o output.tif

# 批量处理
superstaroff batch /path/to/images/*.tif --output-dir ./results

# 查看模型信息
superstaroff info --model RGB
```

---

### Phase 3: 格式支持扩展 🔲 (未开始)

**目标**: 支持更多天文图像格式

**预计完成**: 2025-11-15

#### 计划任务

- [ ] FITS 格式支持
  - [ ] 使用 astropy.io.fits
  - [ ] 保留 FITS 头信息
  - [ ] 处理多层 FITS
- [ ] 常见格式支持
  - [ ] PNG (8/16 bit)
  - [ ] JPEG (仅用于预览)
  - [ ] 其他 RAW 格式
- [ ] 格式转换工具
  - [ ] 统一内部表示
  - [ ] 自动格式检测
  - [ ] 格式转换功能

---

### Phase 4: GUI 开发 🔲 (未开始)

**目标**: 创建独立的 GUI 应用

**预计完成**: 2025-12-01

#### 计划任务

- [ ] 基础 GUI 框架 (PyQt6)
  - [ ] 图像预览
  - [ ] 参数调节
  - [ ] 进度显示
- [ ] 高级功能
  - [ ] 对比视图 (原图/去星图)
  - [ ] 批量处理队列
  - [ ] 预设管理
- [ ] 打包发布
  - [ ] PyInstaller 打包
  - [ ] macOS .app 包
  - [ ] Windows .exe

---

### Phase 5: SuperStarTrail 集成 🔲 (未开始)

**目标**: 集成到 SuperStarTrail 主项目

**预计完成**: 2025-12-15

#### 计划任务

- [ ] API 集成
  - [ ] 在 SuperStarTrail 中调用 SuperStarOff
  - [ ] 统一日志和错误处理
  - [ ] 共享配置系统
- [ ] GUI 集成
  - [ ] 在 SuperStarTrail 主窗口添加"去除星点"功能
  - [ ] 工作流集成 (叠加后去星)
  - [ ] 参数同步
- [ ] 测试和优化
  - [ ] 端到端测试
  - [ ] 性能优化
  - [ ] 用户反馈收集

---

## 技术债务和已知问题

### 当前问题

1. **性能**: 大图像处理较慢 (8256×5504 需要 ~2 分钟)
   - 可能的优化: 模型量化、TensorRT 加速、分块并行处理

2. **内存占用**: 模型加载占用 ~1GB 内存
   - 可能的优化: 模型剪枝、共享内存模式

3. **依赖版本**: LeakyReLU 的 `alpha` 参数警告
   - 需要更新到 `negative_slope` 参数

### 技术债务

1. 代码注释和文档不足
2. 缺少单元测试
3. 缺少 API 文档
4. 缺少使用指南

---

## 里程碑

| 里程碑 | 预计日期 | 状态 | 说明 |
|--------|---------|------|------|
| M0: 基础运行 | 2025-10-13 | ✅ 完成 | StarNet++ 成功在本地运行 |
| M1: API 封装 | 2025-10-20 | 🚧 进行中 | 创建易用的 Python API |
| M2: CLI 工具 | 2025-10-30 | 🔲 未开始 | 命令行工具和批量处理 |
| M3: 格式支持 | 2025-11-15 | 🔲 未开始 | FITS 和其他格式支持 |
| M4: GUI 应用 | 2025-12-01 | 🔲 未开始 | 独立 GUI 应用 |
| M5: 主项目集成 | 2025-12-15 | 🔲 未开始 | 集成到 SuperStarTrail |

---

## 贡献指南

### 开发环境设置

```bash
# 克隆项目
git clone <repo>
cd SuperStarTrail/SuperStarOff

# 创建虚拟环境
python -m venv .venv
source .venv/bin/activate

# 安装依赖
pip install -r requirements.txt

# 运行测试
cd examples
python test_basic.py
```

### 代码规范

- Python 代码遵循 PEP 8
- 使用 Black 格式化
- 使用 type hints
- 添加 docstring

### 提交规范

- feat: 新功能
- fix: 修复
- docs: 文档
- refactor: 重构
- test: 测试
- chore: 其他

---

## 资源和参考

### 相关项目

- [StarNet++](https://github.com/nekitmm/starnet) - 原始项目
- [SuperStarTrail](../) - 星轨叠加主项目

### 技术文档

- TensorFlow 2.x 文档
- Keras 3 API 文档
- TIFF 格式规范
- FITS 格式规范

### 论文和资源

- StarNet 论文: [待补充]
- U-Net 架构论文
- GAN 和图像去噪相关论文

---

## 更新日志

### 2025-10-13 - v0.1.0-alpha

- ✅ 创建 SuperStarOff 独立子项目
- ✅ 成功运行 StarNet++ TensorFlow 2.x 版本
- ✅ 修复所有 Keras 3 兼容性问题
- ✅ 迁移模型权重和测试代码
- ✅ 创建项目文档和开发计划

---

**下一步**: 开始 Phase 1 - 核心功能封装
