# 快速安装指南

## 步骤1: 安装Adobe UXP Developer Tool

1. 下载并安装: https://developer.adobe.com/photoshop/uxp/guides/devtool/
2. 或直接下载: https://unified-plugin-install-service.s3.amazonaws.com/uxp-developer-tools/latest/darwin/UXPDeveloperTool.dmg

## 步骤2: 在Photoshop中启用开发者模式

1. 打开 **Photoshop**
2. 选择菜单: **插件 > 开发 > UXP Developer Tool**
3. UXP Developer Tool会自动打开

## 步骤3: 加载插件

在 **UXP Developer Tool** 中:

1. 点击 **"Add Plugin"** 按钮
2. 浏览到插件目录:
   ```
   /Users/jameszhenyu/PycharmProjects/SuperStarOff/uxp_plugin/SuperStarOff
   ```
3. 选择 **`manifest.json`** 文件
4. 点击 **"Load"** 加载插件

## 步骤4: 打开插件面板

在 **Photoshop** 中:

方法A（推荐）:
```
插件 > 慧眼去星
```

方法B:
```
窗口 > 插件 > 慧眼去星
```

## 步骤5: 开始使用！

1. 在Photoshop中打开一张星空图片
2. 在插件面板中点击 "🌟 开始去除星点"
3. 等待处理完成
4. 新图层自动出现！

## 配置Python路径（重要！）

如果遇到 "Python处理失败"，需要配置Python CLI路径:

1. 打开文件: `uxp_plugin/SuperStarOff/index.js`
2. 修改第6-7行:
   ```javascript
   const PYTHON_CLI_PATH = "/你的实际路径/photoshop_integration/superstaroff_cli.py";
   const PYTHON_INTERPRETER = "python3";
   ```
3. 保存文件
4. 在UXP Developer Tool中点击 **"Reload"**

## 测试Python CLI工具

在开始使用插件前，先测试CLI工具:

```bash
cd /Users/jameszhenyu/PycharmProjects/SuperStarOff
python3 photoshop_integration/superstaroff_cli.py --help
```

应该看到帮助信息，如果报错，请检查:
- Python是否安装
- 依赖库是否安装: `pip install torch torchvision tifffile pillow numpy`
- 模型文件是否存在: `models/SuperStarOff2025.pt`

## 故障排除

### 问题: "插件 > 开发 > UXP Developer Tool" 菜单不存在

**解决方案:**
1. 确认Photoshop版本 ≥ 2021 (v22.0)
2. 安装Adobe UXP Developer Tool
3. 重启Photoshop

### 问题: 插件加载失败

**解决方案:**
1. 检查manifest.json路径是否正确
2. 查看UXP Developer Tool的错误日志
3. 确认Photoshop版本支持

### 问题: Python处理失败

**解决方案:**
1. 配置正确的Python路径（见上方）
2. 测试Python CLI工具
3. 检查模型文件是否存在

## 视频教程

完整的安装和使用视频教程:
（待添加）

## 需要帮助？

如果以上步骤无法解决问题，请检查:
1. UXP Developer Tool的Console日志
2. Photoshop的Console日志（窗口 > 控制台）
3. Python CLI工具是否能独立运行

---

安装完成后，请参阅 [完整使用文档](README.md) 了解更多功能。
