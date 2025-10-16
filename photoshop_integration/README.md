# 慧眼去星 - Photoshop 集成

将星点去除功能集成到 Adobe Photoshop 中，处理结果自动作为新图层添加。

## 功能特点

- ✅ 在 Photoshop 中一键去除星点
- ✅ 处理结果自动作为新图层，方便对比和调整
- ✅ 支持快捷键调用
- ✅ 保持原图层不变
- ✅ 支持 TIF/TIFF/PNG/JPG 格式

## 安装步骤

### 1. 准备 Python 环境

确保已安装所需的 Python 库：

```bash
cd /Users/jameszhenyu/PycharmProjects/SuperStarOff
pip install torch torchvision tifffile pillow numpy
```

### 2. 测试 CLI 工具

```bash
# 测试 CLI 工具是否正常工作
python photoshop_integration/superstaroff_cli.py --help
```

### 3. 配置 Photoshop 脚本

**方法A: 直接运行（推荐用于测试）**

1. 在 Photoshop 中打开图片
2. 选择 `文件 > 脚本 > 浏览...`
3. 选择 `SuperStarOff_PS.jsx`

**方法B: 安装到 Photoshop（推荐用于日常使用）**

1. 找到 Photoshop 的脚本目录：
   - macOS: `/Applications/Adobe Photoshop 2024/Presets/Scripts/`
   - Windows: `C:\Program Files\Adobe\Adobe Photoshop 2024\Presets\Scripts\`

2. 将 `SuperStarOff_PS.jsx` 复制到该目录

3. 重启 Photoshop

4. 现在可以从菜单运行：`文件 > 脚本 > SuperStarOff_PS`

**方法C: 设置快捷键（最方便）**

1. 将脚本安装到 Photoshop（参考方法B）
2. 在 Photoshop 中：`编辑 > 键盘快捷键...`
3. 展开 `文件 > 脚本`
4. 找到 `SuperStarOff_PS`
5. 设置快捷键（例如：`Cmd+Shift+S` 或 `F12`）

## 使用方法

### 基本使用

1. 在 Photoshop 中打开星空图片
2. 运行脚本（快捷键或菜单）
3. 等待处理完成（进度会在后台显示）
4. 新的去星图层会自动出现在图层面板顶部

### 调整参数

如需调整处理参数，编辑 `SuperStarOff_PS.jsx` 的配置区域：

```javascript
// ============== 配置区域 ==============
var PYTHON_CLI_PATH = "/Users/jameszhenyu/PycharmProjects/SuperStarOff/photoshop_integration/superstaroff_cli.py";
var PYTHON_INTERPRETER = "python3";
var STRIDE = 256;  // 可选: 128, 256, 384, 512
var DEVICE = "auto";  // 可选: auto, cpu, mps
// ======================================
```

参数说明：
- `STRIDE`: 处理步长
  - `128`: 最高质量，最慢
  - `256`: 平衡（推荐）
  - `384`: 较快
  - `512`: 最快，质量稍低

- `DEVICE`: 计算设备
  - `auto`: 自动选择（推荐）
  - `mps`: 使用 Apple Silicon GPU
  - `cpu`: 仅使用 CPU

## 工作流程示例

### 基础工作流程

```
1. 打开原图
2. 按快捷键运行脚本
3. 等待处理（30秒-2分钟，取决于图片大小）
4. 新图层自动创建
5. 调整新图层不透明度进行对比
6. 如需要可以添加蒙版做局部调整
```

### 高级工作流程

```
1. 打开原图
2. 运行去星脚本 → 得到 "图层_starless"
3. 调整 "图层_starless" 不透明度到 100%
4. 如果某些区域去星过度：
   - 添加黑色蒙版
   - 用白色画笔涂抹需要去星的区域
5. 如果某些区域保留了星点：
   - 可以再次运行脚本，使用更小的 stride
6. 合并图层或导出
```

## 故障排除

### 问题1: "请先在Photoshop中打开一张图片"

**解决方案**: 确保在 Photoshop 中已打开图片

### 问题2: "去星处理失败"

**可能原因和解决方案**:

1. **Python 路径错误**
   - 检查 `PYTHON_CLI_PATH` 是否正确
   - 在终端测试：`python3 photoshop_integration/superstaroff_cli.py --help`

2. **模型文件缺失**
   - 确保 `models/SuperStarOff2025.pt` 存在
   - 文件大小应约为 168MB

3. **依赖库未安装**
   ```bash
   pip install torch torchvision tifffile pillow numpy
   ```

### 问题3: 脚本在菜单中不显示

**解决方案**:
1. 确认文件已复制到正确的 Scripts 目录
2. 重启 Photoshop
3. 检查文件扩展名是 `.jsx` 不是 `.txt`

### 问题4: OpenSSL 错误

如果遇到 OpenSSL 相关错误，可以：

1. **使用未加密的模型**（如果有）
2. **设置环境变量**：
   ```bash
   export CRYPTOGRAPHY_OPENSSL_NO_LEGACY=1
   ```
3. **或者在脚本中添加环境变量**（编辑 `SuperStarOff_PS.jsx`）

## CLI 工具独立使用

如果只想用命令行处理图片：

```bash
# 基本用法
python photoshop_integration/superstaroff_cli.py input.tif output.tif

# 指定参数
python photoshop_integration/superstaroff_cli.py \
    input.tif output.tif \
    --stride 256 \
    --device auto \
    --verbose

# 批量处理（shell脚本示例）
for file in *.tif; do
    python photoshop_integration/superstaroff_cli.py \
        "$file" \
        "${file%.tif}_starless.tif" \
        --stride 256
done
```

## 性能参考

处理时间（Apple Silicon M1/M2）：

| 图片大小 | Stride 128 | Stride 256 | Stride 512 |
|---------|-----------|-----------|-----------|
| 4K (4096x2160) | ~2分钟 | ~1分钟 | ~30秒 |
| 6K (6000x4000) | ~5分钟 | ~2.5分钟 | ~1分钟 |
| 8K (8192x5464) | ~10分钟 | ~5分钟 | ~2.5分钟 |

## 技术细节

### 脚本工作原理

1. 导出当前 Photoshop 图层为临时 TIF 文件
2. 调用 Python CLI 工具处理
3. 将处理结果导入为新图层
4. 清理临时文件

### 文件结构

```
photoshop_integration/
├── SuperStarOff_PS.jsx      # Photoshop脚本
├── superstaroff_cli.py      # Python CLI工具
└── README.md                # 本文档
```

### 临时文件位置

- macOS: `/tmp/SuperStarOff/`
- Windows: `%TEMP%\SuperStarOff\`

临时文件会在处理完成后自动删除。

## 常见问题

**Q: 可以处理RAW格式吗？**
A: 不能直接处理RAW。请先在PS中打开RAW，转换为图层后再运行脚本。

**Q: 处理需要多长时间？**
A: 取决于图片大小和参数。一般4K图片用stride=256约需1-2分钟。

**Q: 会修改原图层吗？**
A: 不会。脚本会创建新图层，原图层保持不变。

**Q: 可以撤销吗？**
A: 可以。使用Photoshop的历史记录或Cmd+Z撤销。

**Q: 支持批处理吗？**
A: Photoshop脚本本身不支持批处理，但可以使用CLI工具配合shell脚本批处理。

## 更新日志

### v1.0 (2025-10-15)
- 初始版本
- 支持 Photoshop 集成
- 支持 TIF/PNG/JPG 格式
- 自动创建新图层

## 技术支持

如有问题，请检查：
1. Python环境是否正确配置
2. 模型文件是否存在
3. 依赖库是否完整安装
4. Photoshop版本（建议2020及以上）

## 许可证

与 SuperStarOff 主项目相同
