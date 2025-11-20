# 🚀 网站部署 - 3分钟快速指南

## ✅ 准备就绪

网站已经完全配置好，包含真实的下载链接！

**Google Drive**: ✅ 已配置
**百度网盘**: ✅ 已配置（提取码：f3am）

---

## 第1步：提交到 GitHub（1分钟）

复制并运行以下命令：

```bash
git add docs/ WEBSITE_*.md DEPLOY_NOW.md preview_website.sh
git commit -m "feat: 添加官方网站并配置下载链接

- 完整的响应式网站设计
- Google Drive 和百度网盘下载
- 功能展示和使用指南
- 效果对比图
- 自定义域名支持
"
git push origin feature/distribution-xml
```

---

## 第2步：启用 GitHub Pages（30秒）

1. 点击这个链接：https://github.com/jamesphotography/SuperStarOff/settings/pages

2. 在 "Source" 部分：
   - Branch: 选择 `feature/distribution-xml`
   - Folder: 选择 `/docs`
   - 点击 **Save**

3. 完成！GitHub 会自动部署（等待1-3分钟）

临时访问地址：https://jamesphotography.github.io/SuperStarOff

---

## 第3步：配置域名（可选，5分钟）

### A. 添加 DNS 记录

登录你的域名服务商（管理 jamesphotography.com.au 的网站）：

```
记录类型: CNAME
主机记录: superstaroff
记录值: jamesphotography.github.io
TTL: 3600
```

### B. 等待生效

DNS 通常在 5-30 分钟内生效。检查命令：

```bash
dig superstaroff.jamesphotography.com.au
```

### C. 启用 HTTPS

DNS 生效后，回到 GitHub Pages 设置页面，勾选 "Enforce HTTPS"

---

## 🎯 最终网址

**临时网址**（立即可用）:
https://jamesphotography.github.io/SuperStarOff

**正式网址**（DNS 配置后）:
http://superstaroff.jamesphotography.com.au

---

## 🧪 本地测试

在提交前，先本地预览：

```bash
./preview_website.sh
# 访问 http://localhost:8000
```

---

## ✨ 完成后检查

- [ ] 网站可以访问
- [ ] Google Drive 下载链接正常
- [ ] 百度网盘链接正常
- [ ] 提取码显示正确（f3am）
- [ ] 图片正常加载
- [ ] 移动端显示正常

---

## 🆘 遇到问题？

### 网站显示 404

- 等待 1-3 分钟让 GitHub 部署完成
- 确认分支和文件夹选择正确
- 检查 docs/ 文件夹是否已推送

### 自定义域名不工作

- 检查 DNS 记录是否正确
- 等待 DNS 生效（最长 24 小时）
- 确认 docs/CNAME 文件存在

### 图片不显示

- 清除浏览器缓存
- 检查图片文件是否已推送
- 查看浏览器控制台错误信息

---

## 📚 详细文档

- **快速指南**: `WEBSITE_READY.md`
- **配置说明**: `WEBSITE_SETUP_GUIDE.md`
- **维护文档**: `docs/README.md`

---

**现在就开始部署吧！** 🚀
