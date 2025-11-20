# 📸 教程截图添加指南

## 📍 截图占位符位置

网站中已经为使用教程添加了3个截图占位符区域，位于 **"使用教程"** 板块。

---

## 🎯 需要的截图

### 1. 安装教程截图

**文件名建议：** `tutorial-install.png` 或 `tutorial-install.jpg`

**内容要求：**
- 下载 .pkg 安装包的界面
- 双击运行安装程序的画面
- 安装向导的主要步骤
- 在 Photoshop 中验证插件安装成功

**推荐尺寸：** 1200x800 或更大（保持 3:2 比例）

---

### 2. Photoshop 使用截图

**文件名建议：** `tutorial-usage.png` 或 `tutorial-usage.jpg`

**内容要求：**
- 在 Photoshop 中打开图片
- 菜单路径：文件 → 脚本 → SuperStarOff
- 选择 Photoshop 版本的界面
- 处理进度的显示

**推荐尺寸：** 1200x800 或更大（保持 3:2 比例）

---

### 3. 结果查看截图

**文件名建议：** `tutorial-result.png` 或 `tutorial-result.jpg`

**内容要求：**
- 显示新生成的图层
- 原图和去星结果的对比
- 图层面板的截图
- 可选：使用图层蒙版调整的示例

**推荐尺寸：** 1200x800 或更大（保持 3:2 比例）

---

## 📁 如何添加截图

### 步骤 1：准备截图文件

1. 按照上述要求准备3张截图
2. 优化图片大小（建议每张 < 500KB）
3. 重命名为有意义的文件名

### 步骤 2：上传截图

将截图文件放入以下目录：

```
docs/images/
├── tutorial-install.png    # 安装教程
├── tutorial-usage.png      # 使用教程
└── tutorial-result.png     # 结果查看
```

### 步骤 3：编辑 HTML

打开 `docs/index.html`，找到 "使用教程截图" 部分（大约在第 435-510 行）。

#### 替换安装教程占位符

找到这段代码（第 449-453 行）：

```html
<div class="screenshot-placeholder" style="background: rgba(74, 144, 226, 0.05); border: 2px dashed var(--border-color); border-radius: var(--radius-md); padding: 4rem 2rem; text-align: center; margin-bottom: 1rem;">
    <i class="fas fa-image" style="font-size: 3rem; color: var(--text-muted); display: block; margin-bottom: 1rem;"></i>
    <p style="color: var(--text-secondary); margin: 0;">安装步骤截图</p>
    <p style="color: var(--text-muted); font-size: 0.9rem; margin-top: 0.5rem;">即将添加详细的安装过程截图</p>
</div>
```

替换为：

```html
<div style="margin-bottom: 1rem;">
    <img src="images/tutorial-install.png" alt="安装教程" style="width: 100%; border-radius: var(--radius-md); border: 1px solid var(--border-color);">
</div>
```

#### 替换 PS 使用教程占位符

找到这段代码（第 468-472 行）：

```html
<div class="screenshot-placeholder" style="background: rgba(74, 144, 226, 0.05); border: 2px dashed var(--border-color); border-radius: var(--radius-md); padding: 4rem 2rem; text-align: center; margin-bottom: 1rem;">
    <i class="fas fa-image" style="font-size: 3rem; color: var(--text-muted); display: block; margin-bottom: 1rem;"></i>
    <p style="color: var(--text-secondary); margin: 0;">PS 插件使用截图</p>
    <p style="color: var(--text-muted); font-size: 0.9rem; margin-top: 0.5rem;">即将添加在 Photoshop 中调用插件的截图</p>
</div>
```

替换为：

```html
<div style="margin-bottom: 1rem;">
    <img src="images/tutorial-usage.png" alt="Photoshop 使用教程" style="width: 100%; border-radius: var(--radius-md); border: 1px solid var(--border-color);">
</div>
```

#### 替换结果查看占位符

找到这段代码（第 487-491 行）：

```html
<div class="screenshot-placeholder" style="background: rgba(74, 144, 226, 0.05); border: 2px dashed var(--border-color); border-radius: var(--radius-md); padding: 4rem 2rem; text-align: center; margin-bottom: 1rem;">
    <i class="fas fa-image" style="font-size: 3rem; color: var(--text-muted); display: block; margin-bottom: 1rem;"></i>
    <p style="color: var(--text-secondary); margin: 0;">处理结果截图</p>
    <p style="color: var(--text-muted); font-size: 0.9rem; margin-top: 0.5rem;">即将添加处理前后对比截图</p>
</div>
```

替换为：

```html
<div style="margin-bottom: 1rem;">
    <img src="images/tutorial-result.png" alt="处理结果" style="width: 100%; border-radius: var(--radius-md); border: 1px solid var(--border-color);">
</div>
```

### 步骤 4：提交更新

```bash
# 添加图片和更新的 HTML
git add docs/images/tutorial-*.png docs/index.html

# 提交
git commit -m "docs: 添加使用教程截图"

# 推送到 GitHub
git push origin master
```

---

## 🎨 截图优化建议

### 图片质量
- **分辨率：** 至少 1200x800
- **格式：** PNG（清晰度高）或 JPG（文件小）
- **大小：** 压缩后 < 500KB

### 内容要求
- **清晰可读：** 文字和菜单清晰可见
- **突出重点：** 可以添加箭头或标注
- **统一风格：** 使用相同的 Photoshop 主题
- **干净整洁：** 关闭不相关的窗口

### 推荐工具
- **截图：** macOS 自带截图（Cmd+Shift+4）
- **标注：** Skitch、Snagit
- **压缩：** TinyPNG、ImageOptim

---

## 📋 快速替换命令

准备好截图后，可以使用这个脚本快速替换：

```bash
# 1. 复制截图到 images 目录
cp ~/Desktop/tutorial-install.png docs/images/
cp ~/Desktop/tutorial-usage.png docs/images/
cp ~/Desktop/tutorial-result.png docs/images/

# 2. 编辑 HTML 文件（手动替换占位符）
# 使用你喜欢的编辑器打开 docs/index.html
# 按照上面的说明替换3处占位符

# 3. 提交更新
git add docs/images/tutorial-*.png docs/index.html
git commit -m "docs: 添加使用教程截图"
git push origin master
```

---

## ✅ 检查清单

添加截图后，确认：

- [ ] 3张截图都已添加到 `docs/images/` 目录
- [ ] 图片文件名正确
- [ ] HTML 中的3处占位符都已替换
- [ ] 图片在本地预览正常显示
- [ ] 图片大小合理（< 500KB）
- [ ] 代码已提交并推送到 GitHub
- [ ] 在线网站显示正常

---

## 🔄 未来更新

当需要更新截图时：

1. 替换 `docs/images/` 中的图片文件
2. 保持文件名不变
3. 提交并推送更新

不需要修改 HTML 代码，图片会自动更新。

---

## 💡 示例

完成后的效果：

```
使用教程
详细的图文教程，帮助你快速上手

┌─────────────────────────┐
│  📥 安装教程             │
│  [实际截图显示]          │
│  • 下载 .pkg 安装包      │
│  • 双击运行安装程序      │
│  ...                    │
└─────────────────────────┘

┌─────────────────────────┐
│  🎨 Photoshop 中使用     │
│  [实际截图显示]          │
│  • 在 PS 中打开图片      │
│  • 菜单：文件→脚本       │
│  ...                    │
└─────────────────────────┘

┌─────────────────────────┐
│  📊 结果查看             │
│  [实际截图显示]          │
│  • 查看新生成的图层      │
│  • 对比原图和去星结果    │
│  ...                    │
└─────────────────────────┘
```

---

如有问题，随时查看这个指南或联系开发者！📸
