# SuperStarOff - 统一架构设计

## 整体架构

```
┌─────────────────────────────────────────────────────────────┐
│              SuperStarOff PKG 安装包                         │
│                                                              │
│  一次安装，提供两种使用方式：                                 │
└─────────────────────────────────────────────────────────────┘
                            │
            ┌───────────────┴───────────────┐
            │                               │
            ▼                               ▼
┌───────────────────────┐       ┌───────────────────────┐
│  Photoshop 插件 (JSX) │       │   独立 GUI 应用 (.app) │
│                       │       │                       │
│  • 在 PS 中调用       │       │  • 独立运行           │
│  • 处理当前图层       │       │  • 拖拽处理           │
│  • 生成三个图层       │       │  • 批量处理           │
└───────────┬───────────┘       └───────────┬───────────┘
            │                               │
            └───────────────┬───────────────┘
                            │
                            ▼
            ┌───────────────────────────────┐
            │   共享核心组件                 │
            │   /usr/local/SuperStarOff/    │
            │                               │
            │  • Python 虚拟环境 (.venv)    │
            │  • AI 模型 (models/)          │
            │  • 核心代码 (src/)            │
            │  • CLI 工具                   │
            └───────────────────────────────┘
```

## 文件结构

### 安装后的目录布局

```
/Applications/
├── SuperStarOff.app/                    # GUI 应用
│   └── Contents/
│       └── MacOS/
│           └── SuperStarOff             # 指向共享的 Python 环境
│
└── Adobe Photoshop 2025/
    └── Presets/
        └── Scripts/
            └── SuperStarOff.jsx         # Photoshop 脚本

/usr/local/SuperStarOff/                 # 共享核心目录
├── .venv/                               # Python 虚拟环境
│   ├── bin/
│   │   └── python                       # Python 解释器
│   └── lib/
│       └── python3.x/
│           └── site-packages/           # PyTorch, numpy 等依赖
│
├── src/                                 # 源代码
│   ├── starnet_v2_pytorch.py           # 核心处理逻辑
│   ├── model_crypto.py                 # 模型加密/解密
│   └── app.py                          # GUI 应用代码
│
├── models/                              # AI 模型文件
│   └── SuperStarOff2025.pt             # 加密的模型文件 (~100MB)
│
├── superstaroff_cli.py                  # 命令行接口
└── requirements.txt                     # 依赖列表
```

## 数据流程

### Photoshop 插件工作流程

```
用户在 PS 中选择图层
         │
         ▼
SuperStarOff.jsx 被调用
         │
         ├─→ 1. 导出图层为 TIFF
         │      └─→ /tmp/SuperStarOff/input_xxx.tif
         │
         ├─→ 2. 调用 Python CLI
         │      └─→ /usr/local/SuperStarOff/.venv/bin/python \
         │          /usr/local/SuperStarOff/superstaroff_cli.py \
         │          input.tif output.tif --stride 256 --device auto
         │
         ├─→ 3. Python 处理
         │      ├─→ 加载模型：models/SuperStarOff2025.pt
         │      ├─→ 解密模型（如果加密）
         │      ├─→ 去除星点
         │      └─→ 输出结果：output.tif
         │
         ├─→ 4. 导入结果为新图层
         │      └─→ 图层名：去星
         │
         ├─→ 5. 设置混合模式
         │      └─→ 去星图层 → Difference
         │
         ├─→ 6. 盖印可见图层
         │      └─→ 创建星点图层
         │
         └─→ 7. 最终调整
                ├─→ 星点：Linear Dodge (Add)，隐藏
                └─→ 去星：Normal
```

### GUI 应用工作流程

```
用户拖拽图片到应用
         │
         ▼
SuperStarOff.app 启动
         │
         ├─→ 1. 读取图片
         │      └─→ 支持 TIFF, JPG, PNG 等格式
         │
         ├─→ 2. 调用共享的处理代码
         │      └─→ /usr/local/SuperStarOff/src/starnet_v2_pytorch.py
         │
         ├─→ 3. 使用共享的模型和环境
         │      ├─→ 模型：/usr/local/SuperStarOff/models/SuperStarOff2025.pt
         │      └─→ 环境：/usr/local/SuperStarOff/.venv
         │
         └─→ 4. 输出结果
                ├─→ 去星图片
                ├─→ 星点图片（可选）
                └─→ 保存到用户指定位置
```

## 优势分析

### 1. 节省磁盘空间

**传统方案（分开安装）：**
```
GUI 应用内嵌：
  - Python 环境: 500MB
  - 模型文件: 100MB
  - 依赖库: 300MB
  小计: 900MB

Photoshop 插件：
  - Python 环境: 500MB
  - 模型文件: 100MB
  - 依赖库: 300MB
  小计: 900MB

总计: 1.8GB (重复安装)
```

**统一安装方案：**
```
共享安装：
  - Python 环境: 500MB
  - 模型文件: 100MB
  - 依赖库: 300MB
  - GUI 应用: 10MB
  - JSX 脚本: 50KB

总计: 910MB (节省约 50%)
```

### 2. 维护简便

- ✅ 只需更新一处，两种方式同步升级
- ✅ 模型文件只有一份，易于管理
- ✅ 依赖统一，减少兼容性问题

### 3. 用户体验

- ✅ 一次安装，获得两种使用方式
- ✅ 根据场景选择合适的工具
- ✅ 数据共享，配置统一

## PKG 安装包构建流程

```
1. 准备文件
   ├─→ 复制 SuperStarOff.jsx 到 payload
   ├─→ 复制核心文件到 payload
   └─→ 复制 GUI app 到 payload（如果存在）

2. 创建安装脚本 (postinstall)
   ├─→ 创建 Python 虚拟环境
   ├─→ 安装依赖（pip install -r requirements.txt）
   ├─→ 更新 JSX 脚本中的路径
   └─→ 配置 GUI 应用路径

3. 构建 PKG
   └─→ pkgbuild + productbuild

4. 签名（可选）
   ├─→ codesign 签名 .app
   ├─→ productsign 签名 .pkg
   └─→ notarytool 公证
```

## 兼容性

### 支持的系统版本
- macOS 10.15 (Catalina) 及以上
- 需要 Python 3.8 或更高版本
- Adobe Photoshop 2023, 2024, 2025

### 硬件要求
- CPU: Intel 或 Apple Silicon (M1/M2/M3)
- 内存: 至少 8GB（推荐 16GB）
- 磁盘空间: 至少 2GB 可用空间
- GPU: 支持 Apple Silicon GPU 加速（MPS）

## 更新策略

### 小版本更新（1.0.x → 1.0.y）
- 覆盖安装，保留用户配置
- 只更新核心代码和模型

### 大版本更新（1.x → 2.x）
- 建议先卸载旧版本
- 重新安装新版本

## 卸载流程

运行卸载脚本会完全删除：
1. Photoshop 脚本
2. GUI 应用
3. 共享核心文件
4. Python 虚拟环境

用户数据不会被删除（临时文件除外）

---

## 未来扩展

### 可能的扩展方式

1. **Lightroom 插件**
   - 同样使用共享的核心组件
   - 添加 Lightroom 脚本
   - 安装到 Lightroom 插件目录

2. **命令行工具**
   - 创建符号链接：/usr/local/bin/superstaroff
   - 在终端中直接调用

3. **批处理服务**
   - 监听文件夹
   - 自动处理新添加的图片
   - 后台运行

所有扩展都共享同一套核心代码和模型，维护成本低。

---

## 技术栈

- **核心处理**: PyTorch + StarNet V2
- **GUI 应用**: tkinter / Qt / Electron
- **Photoshop 集成**: ExtendScript (JSX)
- **打包工具**: pkgbuild, productbuild
- **加密**: 自定义模型加密方案
