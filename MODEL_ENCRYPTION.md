# 模型加密说明

## 概述

本项目使用了模型加密技术来保护 StarNet++ V2 模型权重文件。加密后的模型文件名为 `SuperStarOff2025.pt`，不容易被识别为 StarNet 模型。

## 加密详情

### 加密算法
- **加密库**: `cryptography` (Fernet 对称加密)
- **密钥派生**: PBKDF2HMAC with SHA256
- **迭代次数**: 100,000 次
- **Salt**: 项目特定的 16 字节随机盐值

### 密钥生成
密钥由多个因子组合生成，分散在代码中：
- 项目名称因子
- 年份因子
- 主题因子

这些因子通过哈希和密钥派生算法生成最终的加密密钥。

### 文件信息
- **原始文件**: `StarNet2_weights.pt` (126 MB)
- **加密文件**: `SuperStarOff2025.pt` (168 MB)
- **增长原因**: Base64 编码和加密元数据

## 使用方法

### 应用自动加载
应用启动时会自动：
1. 检测 `SuperStarOff2025.pt` 是否存在
2. 自动解密模型到内存
3. 加载到 PyTorch
4. 不会在磁盘上生成临时文件

### 手动加密模型
如果需要重新加密：

```bash
python encrypt_model.py
```

### 测试加密模型
验证加密模型能否正常工作：

```bash
python test_encrypted_model.py
```

## 安全特性

1. **内存解密**: 模型仅在内存中解密，不写入磁盘
2. **自动加载**: 应用自动检测并使用加密模型
3. **无原始文件**: 原始 StarNet2_weights.pt 已删除
4. **混淆命名**: 使用 SuperStarOff2025.pt 名称，不易识别来源

## 技术实现

### 核心文件

1. **`src/model_crypto.py`**
   - 加密/解密工具类
   - 密钥派生函数
   - 内存操作支持

2. **`src/starnet_v2_pytorch.py`**
   - 自动检测加密模型
   - 内存解密加载
   - 透明的加密支持

3. **`encrypt_model.py`**
   - 模型加密脚本
   - 交互式确认
   - 进度显示

### 加载流程

```python
# 初始化（自动检测加密文件）
starnet = StarNetV2(device='mps', stride=256)

# 加载模型（自动解密）
starnet.load_model()

# 正常使用
result = starnet.transform('input.tif', 'output.tif')
```

## 依赖项

```bash
pip install cryptography
```

已包含在项目依赖中。

## 注意事项

1. **不要提交加密密钥**: 密钥因子分散在代码中，不要单独提取
2. **备份原始文件**: 原始 StarNet2_weights.pt 已删除，确保有备份
3. **性能影响**: 首次加载时需要解密，约增加 2-3 秒启动时间
4. **内存使用**: 解密时需要额外约 200MB 内存

## 维护

### 更新加密密钥
如需更改加密密钥，修改 `src/model_crypto.py` 中的因子：

```python
factor1 = "HuiYanQuXing"  # 慧眼去星
factor2 = "2025"
factor3 = "DeepSpace"
```

修改后需要重新加密模型。

### 重新加密
1. 恢复原始 `StarNet2_weights.pt`
2. 运行 `python encrypt_model.py`
3. 删除原始文件

## 版本历史

- **v1.0 (2025-10-14)**: 初始加密实现
  - Fernet 对称加密
  - PBKDF2 密钥派生
  - 内存解密支持
  - 自动检测加载

---

**慧眼去星 SuperStarOff** - 模型加密保护系统
