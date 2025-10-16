# 慧眼去星 - UXP 插件

专业的 Photoshop UXP 插件，提供完整的用户界面和无缝集成体验。

## 功能特点

- 🎨 **原生UI面板**：美观的插件面板，完美融入Photoshop界面
- ⚡ **实时反馈**：处理进度实时显示
- 🎛️ **参数调整**：可视化调整stride和device参数
- 🖼️ **自动图层管理**：结果自动创建为新图层
- 🚀 **高性能**：支持Apple Silicon MPS加速

## 系统要求

- **Photoshop**: 2021 (v22.0) 或更高版本
- **macOS**: 11.0 Big Sur 或更高版本
- **Python**: 3.8+ 已安装
- **依赖库**: torch, torchvision, tifffile, pillow, numpy

## 安装方法

### 方法1: 开发者模式（推荐用于测试）

1. **启用UXP开发者模式**

   在Photoshop中:
   ```
   插件 > 开发 > UXP Developer Tool
   ```
   如果没有这个选项，需要先安装 [Adobe UXP Developer Tool](https://developer.adobe.com/photoshop/uxp/guides/devtool/)

2. **添加插件**

   在UXP Developer Tool中:
   - 点击 "Add Plugin"
   - 选择 `uxp_plugin/SuperStarOff/manifest.json`
   - 点击 "Load" 加载插件

3. **打开插件面板**

   在Photoshop中:
   ```
   插件 > 慧眼去星
   ```
   或
   ```
   窗口 > 插件 > 慧眼去星
   ```

### 方法2: 安装包安装（用于分发）

#### 创建安装包（需要证书）

```bash
# 安装UXP打包工具
npm install -g @adobe/uxp-plugin-packager

# 打包插件
cd uxp_plugin/SuperStarOff
uxp-plugin pack --input . --output ../../build/SuperStarOff.ccx
```

#### 安装插件包

1. 双击 `.ccx` 文件
2. 或在 Photoshop 中: `插件 > 安装插件`
3. 选择 `.ccx` 文件

## 使用方法

### 基本工作流程

1. **打开图片**
   - 在Photoshop中打开星空图片

2. **打开插件面板**
   - `插件 > 慧眼去星` 或 `窗口 > 插件 > 慧眼去星`

3. **调整参数**
   - **处理步长**: 256（推荐）或根据需要调整
   - **计算设备**: 自动选择（推荐）
   - **图层名称**: 自动命名或自定义

4. **开始处理**
   - 点击 "🌟 开始去除星点" 按钮
   - 等待处理完成（30秒-2分钟）

5. **查看结果**
   - 新图层自动出现在图层面板顶部
   - 可以调整不透明度进行对比

### 参数说明

#### 处理步长（Stride）

| 步长 | 质量 | 速度 | 适用场景 |
|-----|------|------|---------|
| 128 | 最高 | 最慢 | 关键作品、需要最佳质量 |
| 256 | 高 | 平衡 | **推荐**日常使用 |
| 384 | 中 | 快 | 快速预览 |
| 512 | 中 | 最快 | 大批量处理 |

#### 计算设备（Device）

- **自动选择**：推荐，自动使用最快的设备
- **Apple Silicon GPU (MPS)**：使用M1/M2芯片的GPU加速
- **仅CPU**：兼容模式，适用于老设备

### 高级技巧

#### 1. 局部调整

```
1. 去星后的图层 + 黑色蒙版
2. 用白色画笔涂抹需要去星的区域
3. 保留部分星点营造层次感
```

#### 2. 对比查看

```
1. 按住 Alt 键点击图层眼睛 = 单独显示该图层
2. 快速切换原图和去星图层进行对比
```

#### 3. 混合模式

```
尝试不同的混合模式:
- 正常: 标准去星
- 变亮: 保留暗部细节
- 线性减淡: 更柔和的效果
```

## 插件结构

```
uxp_plugin/SuperStarOff/
├── manifest.json       # 插件配置文件
├── index.html          # UI界面
├── index.js            # 业务逻辑
└── icons/              # 插件图标
    ├── icon_23.png
    ├── icon_23@2x.png
    ├── icon_48.png
    └── icon_48@2x.png
```

## 开发调试

### 启用控制台

在UXP Developer Tool中点击 "Debug" 按钮，可以看到:
- Console日志
- 错误信息
- 性能分析

### 调试技巧

```javascript
// 在 index.js 中添加日志
console.log("调试信息:", someVariable);

// 查看错误详情
try {
    // 你的代码
} catch (error) {
    console.error("详细错误:", error);
}
```

### 热重载

修改代码后:
1. 在UXP Developer Tool中点击 "Reload"
2. 或在Photoshop中重新打开插件面板

## 故障排除

### 问题1: 插件无法加载

**可能原因:**
- Photoshop版本过低（需要2021+）
- manifest.json 格式错误

**解决方案:**
1. 检查Photoshop版本: `帮助 > 系统信息`
2. 验证manifest.json格式
3. 查看UXP Developer Tool的错误信息

### 问题2: "Python处理失败"

**可能原因:**
- Python CLI工具路径不正确
- Python依赖库未安装
- 模型文件缺失

**解决方案:**

1. **检查Python路径**

   编辑 `index.js`:
   ```javascript
   const PYTHON_CLI_PATH = "/你的实际路径/superstaroff_cli.py";
   ```

2. **测试CLI工具**
   ```bash
   python3 photoshop_integration/superstaroff_cli.py --help
   ```

3. **安装依赖**
   ```bash
   pip install torch torchvision tifffile pillow numpy
   ```

### 问题3: 权限错误

**可能原因:**
- manifest.json中权限配置不足

**解决方案:**

确保manifest.json包含以下权限:
```json
"requiredPermissions": [
    {
      "type": "launchProcess",
      "toAccess": [
        { "app": "python3", "args": ["*"] }
      ]
    },
    {
      "type": "localFileSystem",
      "mode": "readWrite"
    }
]
```

### 问题4: 图层导入失败

**可能原因:**
- 临时文件权限问题
- 输出文件格式不支持

**解决方案:**

1. 检查临时文件目录权限
2. 确保Python CLI输出TIF格式
3. 查看Console日志获取详细错误

### 问题5: 处理很慢

**可能原因:**
- 使用CPU模式
- stride设置过小
- 图片分辨率过高

**解决方案:**

1. 选择 "Apple Silicon GPU (MPS)" 设备
2. 增大stride值（256 → 384 或 512）
3. 对超大图片先缩小处理

## 性能参考

在 Apple Silicon (M1/M2) 上的处理时间:

| 图片大小 | Stride 256 (MPS) | Stride 256 (CPU) |
|---------|-----------------|-----------------|
| 4K (4096x2160) | ~45秒 | ~2分钟 |
| 6K (6000x4000) | ~1.5分钟 | ~5分钟 |
| 8K (8192x5464) | ~3分钟 | ~10分钟 |

## 更新插件

1. 修改代码
2. 在UXP Developer Tool中点击 "Reload"
3. 或重新加载插件

## 打包分发

### 准备打包

1. **安装打包工具**
   ```bash
   npm install -g @adobe/uxp-plugin-packager
   ```

2. **生成签名证书**（可选，用于分发）
   ```bash
   uxp-sign create-certificate
   ```

### 打包插件

```bash
cd uxp_plugin/SuperStarOff

# 创建.ccx包
uxp-plugin pack \
    --input . \
    --output ../../build/SuperStarOff.ccx

# 如果有证书，签名打包
uxp-plugin pack \
    --input . \
    --output ../../build/SuperStarOff.ccx \
    --certificate /path/to/certificate.p12 \
    --password your-password
```

### 分发安装包

生成的 `.ccx` 文件可以:
1. 双击直接安装
2. 通过 `插件 > 安装插件` 菜单安装
3. 分发给其他用户

## 技术架构

### 工作流程

```
1. 用户点击按钮
   ↓
2. index.js 导出当前图层为TIF
   ↓
3. 调用 Python CLI 工具处理
   ↓
4. Python 返回处理结果
   ↓
5. index.js 导入结果为新图层
   ↓
6. 显示完成状态
```

### 关键API

- `app.activeDocument` - 获取当前文档
- `executeAsModal()` - 模态执行，支持撤销
- `layer.duplicate()` - 复制图层
- `doc.saveAs.tiff()` - 保存为TIFF
- `shell.openPath()` - 执行外部命令

## 进阶定制

### 自定义UI主题

修改 `index.html` 中的CSS:
```css
/* 自定义颜色 */
.btn-primary {
    background: #your-color;
}
```

### 添加新功能

在 `index.js` 中添加新的处理函数:
```javascript
async function myNewFeature() {
    await executeAsModal(async () => {
        // 你的代码
    }, { commandName: "我的新功能" });
}
```

## 常见问题

**Q: 支持批处理吗？**
A: 当前版本不支持批处理，但可以通过Photoshop的动作(Action)录制来实现简单的批处理。

**Q: 能否调整UI大小？**
A: 可以拖动面板边缘调整，尺寸限制在manifest.json中配置。

**Q: 如何更新插件？**
A: 删除旧版本，重新加载新版本即可。

**Q: 支持Windows吗？**
A: 插件本身跨平台，但Python CLI路径需要根据Windows系统调整。

**Q: 可以离线使用吗？**
A: 可以，不需要网络连接（除了首次安装依赖）。

## 技术支持

遇到问题请检查:
1. UXP Developer Tool的Console日志
2. Photoshop版本是否支持
3. Python环境是否正确配置
4. 模型文件是否存在

## 更新日志

### v1.0.0 (2025-10-15)
- ✨ 初始版本
- ✅ 基础UI面板
- ✅ 参数调整
- ✅ 进度显示
- ✅ 自动图层管理
- ✅ Apple Silicon支持

## 许可证

与 SuperStarOff 主项目相同

---

**开发者**: SuperStarOff Team
**版本**: 1.0.0
**平台**: Adobe Photoshop UXP
