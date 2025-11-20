# SuperStarOff 官方网站

这是慧眼去星 SuperStarOff 的官方网站，使用 GitHub Pages 托管。

## 访问地址

- **自定义域名**: http://superstaroff.jamesphotography.com.au
- **GitHub Pages**: https://jamesphotography.github.io/SuperStarOff

## 网站结构

```
docs/
├── index.html          # 主页
├── css/
│   └── style.css       # 样式表
├── js/
│   └── main.js         # JavaScript 交互
├── images/             # 图片资源
│   ├── example-before.jpg
│   └── example-after.jpg
├── downloads/          # 下载文件（可选）
├── CNAME              # 自定义域名配置
└── README.md          # 本文件
```

## 如何添加下载链接

网站目前使用占位符作为下载链接。你需要更新以下内容：

### 1. 更新 HTML 文件中的下载链接

编辑 `docs/index.html`，找到下载按钮部分（大约在第 250-260 行）：

```html
<a href="#" class="btn btn-primary download-btn" data-source="google">
    <i class="fab fa-google-drive"></i> Google Drive
</a>
<a href="#" class="btn btn-primary download-btn" data-source="baidu">
    <i class="fas fa-cloud"></i> 百度网盘
</a>
```

将 `href="#"` 替换为实际的下载链接：

```html
<a href="https://drive.google.com/your-actual-link" class="btn btn-primary download-btn" data-source="google" target="_blank">
    <i class="fab fa-google-drive"></i> Google Drive
</a>
<a href="https://pan.baidu.com/your-actual-link" class="btn btn-primary download-btn" data-source="baidu" target="_blank">
    <i class="fas fa-cloud"></i> 百度网盘
</a>
```

### 2. 更新 JavaScript 中的下载提示

编辑 `docs/js/main.js`，找到下载按钮事件处理部分（大约在第 73-92 行），并根据需要更新提示信息或直接移除提示。

如果你已经有了下载链接，可以删除这部分代码，让下载按钮直接跳转。

### 3. 添加百度网盘提取码（如需要）

如果百度网盘需要提取码，可以在下载卡片中添加提示：

```html
<p class="download-note">
    <i class="fas fa-info-circle"></i>
    百度网盘提取码：<strong>xxxx</strong>
</p>
```

## 如何更新网站内容

### 添加新的示例图片

1. 将图片放入 `docs/images/` 目录
2. 在 `index.html` 的效果展示部分添加新的图片展示块

### 更新软件版本信息

编辑 `index.html`，找到以下部分并更新：

- 下载区域的版本号（搜索 `V1.0`）
- 性能数据（如果有新的性能测试结果）
- 功能特性（如果添加了新功能）

### 添加更新日志

在 FAQ 部分下方添加更新日志区域，或创建单独的更新日志页面。

## GitHub Pages 配置

### 启用 GitHub Pages

1. 进入仓库设置：https://github.com/jamesphotography/SuperStarOff/settings/pages
2. 在 "Source" 部分选择：
   - Branch: `feature/distribution-xml` (或你希望发布的分支)
   - Folder: `/docs`
3. 点击 "Save"

### 配置自定义域名

1. 确保 `docs/CNAME` 文件包含域名：`superstaroff.jamesphotography.com.au`
2. 在你的域名提供商处添加 DNS 记录：
   - 类型：CNAME
   - 名称：superstaroff
   - 值：jamesphotography.github.io
3. 等待 DNS 生效（可能需要几分钟到几小时）
4. 在 GitHub Pages 设置中启用 "Enforce HTTPS"

### DNS 配置示例

在你的域名提供商处（如 GoDaddy、Cloudflare 等）添加：

```
Type: CNAME
Name: superstaroff
Target: jamesphotography.github.io
TTL: 3600 (or Auto)
```

## 本地预览

在本地预览网站：

```bash
# 方法 1: 使用 Python 的简单 HTTP 服务器
cd docs
python3 -m http.server 8000

# 方法 2: 使用 Node.js 的 http-server
npm install -g http-server
cd docs
http-server -p 8000

# 然后在浏览器中访问: http://localhost:8000
```

## 网站特性

- ✅ 响应式设计，支持桌面和移动端
- ✅ 暗色主题，适合长时间浏览
- ✅ 平滑滚动和动画效果
- ✅ 返回顶部按钮
- ✅ 移动端导航菜单
- ✅ 图片对比展示
- ✅ SEO 优化
- ✅ 快速加载

## 维护建议

1. **定期更新版本信息**：当发布新版本时，及时更新网站内容
2. **添加使用案例**：收集用户的优秀作品并展示
3. **更新 FAQ**：根据用户反馈添加常见问题解答
4. **性能优化**：定期检查网站加载速度并优化图片大小
5. **监控流量**：使用 Google Analytics 或其他工具监控访问情况

## 需要注意的事项

1. 所有提交到 `docs/` 目录的更改都会自动部署到网站
2. GitHub Pages 更新可能需要几分钟时间
3. 自定义域名配置后，不要删除 `CNAME` 文件
4. 图片文件不要太大，建议压缩后再上传（推荐 < 500KB）

## 问题排查

### 网站无法访问

1. 检查 GitHub Pages 是否已启用
2. 确认分支和文件夹设置正确
3. 检查 CNAME 文件是否存在且内容正确
4. 验证 DNS 记录是否配置正确

### 自定义域名不工作

1. 使用 `dig` 或在线工具检查 DNS 是否生效：
   ```bash
   dig superstaroff.jamesphotography.com.au
   ```
2. 确认 DNS 记录指向正确的 GitHub Pages 地址
3. 清除浏览器缓存后重试

### 样式或脚本不加载

1. 检查文件路径是否正确
2. 确认文件已经提交到仓库
3. 清除浏览器缓存
4. 检查浏览器控制台的错误信息

## 联系方式

如有问题，请在 GitHub 仓库中提交 Issue：
https://github.com/jamesphotography/SuperStarOff/issues

---

最后更新：2025-11-20
