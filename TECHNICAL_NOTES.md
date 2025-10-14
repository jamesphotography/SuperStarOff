# SuperStarOff 技术笔记

本文档记录了 SuperStarOff 开发过程中的技术细节、问题解决和重要决策。

---

## StarNet++ 本地运行 - 完整问题解决记录

### 问题概览

StarNet++ 原始代码基于 TensorFlow 1.x 编写（2018年），需要适配到现代 TensorFlow 2.x + Keras 3 环境。

### 遇到的问题和解决方案

#### 1. scipy.misc.toimage 已废弃

**问题**:
```python
from scipy.misc import toimage  # scipy 1.3+ 中已移除
```

**错误信息**:
```
ImportError: cannot import name 'toimage' from 'scipy.misc'
```

**解决方案**:
```python
# starnet_utils.py 第17行
# from scipy.misc import toimage  # 注释掉，该函数未被使用
```

**原因**: `scipy.misc.toimage` 在 scipy 1.3.0 中被废弃，应使用 `PIL.Image.fromarray()`。但检查代码后发现 starnet_utils.py 中导入后从未使用，因此直接注释掉。

---

#### 2. TensorFlow 2.x 兼容性 - placeholder 和 Session

**问题**:
```python
X = tf.placeholder(...)  # TF 2.x 不再支持
with tf.Session() as sess:  # TF 2.x 使用 eager execution
```

**错误信息**:
```
AttributeError: module 'tensorflow' has no attribute 'placeholder'
```

**解决方案**:

我们发现 StarNet++ 仓库中有 TensorFlow 2.x 版本: `starnet_v1_TF2.py`

使用该版本而非尝试修复旧版 `transform.py`。

**技术决策**: 使用 TF 2.x 原生 API 而非兼容模式，代码更清晰且性能更好。

---

#### 3. Keras 3 兼容性 - tf.concat 在 Functional API 中不可用

**问题**:
```python
# 在 Keras Functional API 中
input = L.Input(...)
concatenated = tf.concat([layers[-1], layers[6]], axis=3)  # ❌ 错误
```

**错误信息**:
```
ValueError: A KerasTensor cannot be used as input to a TensorFlow function.
You should wrap `tf_fn` in a layer.
```

**原因**: Keras 3 中，Functional API 使用符号张量 (KerasTensor)，不能直接传递给 TensorFlow 函数。必须使用 Keras 层。

**解决方案**:
```python
# ✅ 正确做法
concatenated = L.Concatenate(axis=3)([layers[-1], layers[6]])
```

**修复位置**: `starnet_v1_TF2.py` 生成器函数中的 6 处 concat 操作

**修复命令**:
```bash
sed -i '' 's/concatenated = tf\.concat(\[layers\[-1\], layers\[\([0-9]\)\]\], axis = 3)/concatenated = L.Concatenate(axis = 3)([layers[-1], layers[\1]])/g' starnet_v1_TF2.py
```

---

#### 4. Keras 3 兼容性 - tf.math.subtract

**问题**:
```python
output = tf.math.subtract(input, rectified)  # ❌ 不能在 Functional API 中使用
```

**解决方案**:
```python
output = L.Subtract()([input, rectified])  # ✅ 使用 Keras Subtract 层
```

**修复位置**: `starnet_v1_TF2.py:486`

---

#### 5. Keras 3 兼容性 - tf.nn.sigmoid

**问题**:
```python
sigmoid = tf.nn.sigmoid(dense)  # ❌ 不能在 Functional API 中使用
```

**解决方案**:
```python
sigmoid = L.Activation('sigmoid')(dense)  # ✅ 使用 Keras Activation 层
```

**修复位置**: `starnet_v1_TF2.py:551`

---

#### 6. tifffile API 变更

**问题**:
```python
tiff.imsave(filename, data)  # 旧 API
```

**错误信息**:
```
AttributeError: module 'tifffile' has no attribute 'imsave'
```

**原因**: 新版 tifffile 将 `imsave` 重命名为 `imwrite`

**解决方案**:
```python
tiff.imwrite(filename, data)  # 新 API
```

**修复命令**:
```bash
sed -i '' 's/tiff\.imsave/tiff.imwrite/g' starnet_v1_TF2.py
```

---

#### 7. Git LFS 模型下载问题

**问题**: GitHub 仓库中的 `model.ckpt.data-00000-of-00001` 只有 134 字节（Git LFS 指针文件）

**错误信息**:
```
TensorBundle at ./model.ckpt shard 0 (128 bytes): Checksum does not match
```

**原因**: Git LFS 存储限制，大文件（674MB）未被下载

**解决方案**:

1. **尝试的方法** (失败):
   ```bash
   git lfs install
   git lfs pull
   git lfs checkout model.ckpt.data-00000-of-00001
   ```

2. **最终方案** (成功):
   - 使用 StarNet++ README 中提供的 Dropbox 链接
   - 下载 `starnet_weights2.zip` (401MB)
   - 解压获得 `.h5` 格式权重文件
   - 使用 `starnet_v1_TF2.py` 加载 `.h5` 权重

**技术决策**: 使用 Keras 格式 (.h5) 权重而非 TensorFlow checkpoint (.ckpt)，因为：
- Dropbox 提供的是 .h5 格式
- .h5 格式更现代，兼容性更好
- starnet_v1_TF2.py 原生支持 .h5

---

### 依赖版本

成功运行的环境配置：

```
Python: 3.12
TensorFlow: 2.20.0
tf-keras: 2.20.1
Keras: 3.11.3
numpy: 1.26.4
tifffile: 2024.x
Pillow: 11.3.0
matplotlib: 3.10.7
IPython: 9.6.0
```

关键点：
- 必须安装 `tf_keras` 包以支持 legacy Keras
- 必须设置环境变量 `TF_USE_LEGACY_KERAS=1` (仅在使用 TF 1.x 兼容模式时)
- 实际使用 `starnet_v1_TF2.py` 时不需要 legacy 模式

---

### 模型文件说明

#### 权重文件

下载的 `starnet_weights2.zip` 包含：

```
weights_G_RGB.h5           (208MB)  - RGB 模式生成器权重
weights_D_RGB.h5           (6.8MB)  - RGB 模式判别器权重
weights_G_Greyscale.h5     (208MB)  - 灰度模式生成器权重
weights_D_Greyscale.h5     (6.8MB)  - 灰度模式判别器权重
history_RGB.pkl            (4.7MB)  - RGB 训练历史
history_Greyscale.pkl      (4.7MB)  - 灰度训练历史
```

#### 模型架构

**生成器 (Generator) - U-Net 风格**:
- 编码器: 8 层卷积 + BatchNorm + LeakyReLU (下采样)
- 解码器: 8 层转置卷积 + BatchNorm + ReLU (上采样)
- 跳跃连接: 连接对应的编码器和解码器层
- 输出: `input - residual` (减法残差学习)

**判别器 (Discriminator)**:
- 9 层卷积网络
- 用于训练时的对抗学习
- 推理时不使用

**总参数量**: ~50M (生成器)

---

### 性能基准

在 MacBook Pro (Apple Silicon M1/M2) 上测试：

| 图像尺寸 | Window Size | Stride | CPU 时间 | 备注 |
|---------|-------------|--------|---------|------|
| 1048×712 | 512 | 256 | ~5秒 | 测试图像 |
| 8256×5504 | 512 | 256 | ~2分钟 | 全幅单反 |

**参数说明**:
- **window_size**: 512 是模型训练时的输入大小，不建议改变
- **stride**: 256 表示每次移动 256 像素
  - 更小的 stride (如 128) = 更高质量，更慢速度，更多重叠
  - 更大的 stride (如 384) = 更低质量，更快速度

---

### 图像处理流程

1. **读取输入**:
   ```python
   data = tiff.imread(input_file)
   image = (data / 255.0).astype('float32')  # 归一化到 [0, 1]
   ```

2. **填充图像**:
   ```python
   # 确保图像可以被 stride 整除
   # 在边缘添加镜像填充
   offset = (window_size - stride) // 2
   ```

3. **滑动窗口处理**:
   ```python
   for i in range(num_tiles_h):
       for j in range(num_tiles_w):
           tile = image[x:x+window_size, y:y+window_size, :]
           tile = (tile * 2 - 1)  # 归一化到 [-1, 1]
           processed = model(tile)
           output[...] = processed
   ```

4. **后处理**:
   ```python
   output = np.clip(output, 0, 1)
   output = (output * 255 * 255).astype('uint16')  # 转回 16-bit
   tiff.imwrite(output_file, output)
   ```

---

### 调试技巧

#### 1. 打印张量形状

```python
# 在生成器函数中添加调试输出
print(f"Layer {i} shape: {layers[-1].shape}")
```

#### 2. 检查模型加载

```python
# 验证权重加载成功
print(f"Generator weights: {len(starnet.G.weights)}")
print(f"First layer shape: {starnet.G.weights[0].shape}")
```

#### 3. 可视化中间结果

```python
from matplotlib import pyplot as plt

# 可视化某一层的输出
intermediate_model = K.Model(inputs=starnet.G.input,
                            outputs=starnet.G.layers[10].output)
intermediate_output = intermediate_model(test_image)
plt.imshow(intermediate_output[0, :, :, 0])
plt.show()
```

---

### 常见问题 FAQ

#### Q: 为什么输出图像比输入小？

A: 检查 `stride` 和边缘填充。边缘的 `offset` 像素会被裁剪掉。

#### Q: 处理很慢怎么办？

A:
1. 增大 `stride` (牺牲质量换速度)
2. 使用 GPU (需要 `tensorflow-metal` on macOS)
3. 考虑模型量化

#### Q: 出现内存不足错误？

A:
1. 减小 `window_size` (但需要重新训练模型)
2. 增大 `stride` (减少重叠区域)
3. 分块处理大图像

#### Q: RGB 和 Greyscale 模型有什么区别？

A:
- RGB: 3通道输入输出，适合彩色天文图像
- Greyscale: 1通道输入输出，适合单色 CCD 图像
- 两个模型独立训练，参数不同

---

### 后续优化方向

#### 1. 模型加速

- **TensorRT 优化**: 将模型转换为 TensorRT 引擎
- **模型量化**: INT8 量化减少内存和提升速度
- **模型剪枝**: 移除不重要的权重

#### 2. 内存优化

- **流式处理**: 不一次性加载整个图像
- **梯度检查点**: 训练时减少内存占用

#### 3. 功能增强

- **自适应 stride**: 根据图像内容自动选择最佳 stride
- **多尺度融合**: 结合不同 window_size 的结果
- **后处理优化**: 去除伪影和边缘效应

---

### 参考资源

#### 代码仓库

- StarNet++ 原始仓库: https://github.com/nekitmm/starnet
- TensorFlow 文档: https://www.tensorflow.org/
- Keras 文档: https://keras.io/

#### 相关论文

- U-Net: Convolutional Networks for Biomedical Image Segmentation
- pix2pix: Image-to-Image Translation with Conditional Adversarial Networks

#### 工具和库

- TensorFlow: 深度学习框架
- Keras: 高级神经网络 API
- tifffile: TIFF 图像读写
- Pillow: Python 图像库
- NumPy: 数值计算库

---

**最后更新**: 2025-10-13

**维护者**: SuperStarOff Team
