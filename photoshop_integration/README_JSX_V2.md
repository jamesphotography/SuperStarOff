# SuperStarOff JSX V2.0 - 优化版

## 改进内容

### 🎯 核心优化

#### 1. **移除硬编码路径** ⭐⭐⭐⭐⭐
**问题**: 原版本硬编码了开发者的路径
```javascript
// ❌ 旧版本
var PYTHON_CLI_PATH = "/Users/jameszhenyu/PycharmProjects/SuperStarOff/...";
var PYTHON_INTERPRETER = "/Users/jameszhenyu/PycharmProjects/SuperStarOff/.venv/bin/python";
```

**解决方案**: 自动检测安装路径
```javascript
// ✅ 新版本
var installDir = detectInstallDir();  // 自动检测
```

检测优先级:
1. 环境变量 `$SUPERSTAROFF_INSTALL_DIR`
2. 标准安装路径：
   - `/usr/local/SuperStarOff` (PKG安装)
   - `~/Library/Application Support/SuperStarOff` (用户目录)
   - `/Applications/SuperStarOff`
3. 配置文件中保存的路径
4. 用户手动选择

---

#### 2. **实时进度显示** ⭐⭐⭐⭐⭐
**问题**: 原版本处理时Photoshop冻结，用户焦虑

**解决方案**: 可视化进度窗口
```
┌────────────────────────────────────┐
│ 慧眼去星 - 处理中                  │
├────────────────────────────────────┤
│ 正在处理图片（这需要1-2分钟）...   │
│ [████████░░░░░░░░] 56%            │
│ 进度: 56%                          │
│ 已用时间: 45秒 | 预计剩余: 35秒    │
│                                    │
│         [取消处理]                 │
└────────────────────────────────────┘
```

特性:
- ✅ 实时进度百分比
- ✅ 已用时间
- ✅ 预计剩余时间
- ✅ 可取消处理

---

#### 3. **参数配置UI** ⭐⭐⭐⭐
**问题**: 原版本参数硬编码，用户无法调整

**解决方案**: 启动时显示配置对话框
```
┌────────────────────────────────────┐
│ 慧眼去星 - 处理参数                │
├────────────────────────────────────┤
│ 处理质量:                          │
│ [⭐ 平衡 (stride=256, ~1分钟) 推荐▼]│
│                                    │
│ 计算设备:                          │
│ [自动 (推荐) ▼]                    │
│                                    │
│ ┌──────────────────────────────┐  │
│ │ 说明                          │  │
│ │ • 步长越小质量越高，但耗时长  │  │
│ │ • MPS可使用Apple Silicon加速  │  │
│ │ • 处理中请勿关闭Photoshop     │  │
│ └──────────────────────────────┘  │
│                                    │
│    [开始处理]     [取消]           │
└────────────────────────────────────┘
```

预设选项:
- ⚡ **快速**: stride=512, ~30秒
- ⭐ **平衡**: stride=256, ~1分钟 (推荐)
- 💎 **精细**: stride=128, ~2分钟

---

### 🛠 技术改进

#### 路径检测系统
```javascript
function detectInstallDir() {
    // 1. 检查环境变量
    var envDir = $.getenv("SUPERSTAROFF_INSTALL_DIR");

    // 2. 检查标准路径
    for (var i = 0; i < installPaths.length; i++) {
        if (validateInstallDir(path)) {
            return path;
        }
    }

    // 3. 从配置文件加载
    var savedDir = loadConfig("install_dir");

    // 4. 用户手动选择
    var selectedFolder = Folder.selectDialog("请选择安装目录");

    return path;
}
```

#### 配置持久化
```javascript
// 保存用户选择的路径，下次自动使用
saveConfig("install_dir", "/usr/local/SuperStarOff");

// 配置文件位置
~/Library/Preferences/com.superstaroff.config
```

#### 进度计算
```javascript
function updateProgress(win, percent, message, startTime) {
    // 更新进度条
    win.progressBar.value = percent;

    // 计算已用时间
    var elapsed = (new Date() - startTime) / 1000;

    // 估算剩余时间
    if (percent > 10) {
        var totalEstimated = elapsed / (percent / 100);
        var remaining = totalEstimated - elapsed;
    }
}
```

---

## 使用方法

### 安装

1. **方式一: 复制到Photoshop脚本目录**
```bash
cp SuperStarOff_PS_v2.jsx \
   "/Applications/Adobe Photoshop 2025/Presets/Scripts/SuperStarOff.jsx"
```

2. **方式二: 直接运行**
- 文件 > 脚本 > 浏览...
- 选择 `SuperStarOff_PS_v2.jsx`

### 首次运行

1. 打开一张星空图片
2. 运行脚本
3. 如果自动检测失败，会提示选择安装目录
4. 配置处理参数
5. 点击"开始处理"

### 后续运行

1. 脚本会记住安装路径
2. 直接显示参数配置对话框
3. 开始处理

---

## 与原版本对比

| 特性 | 原版本 | V2.0 |
|------|--------|------|
| 路径配置 | ❌ 硬编码 | ✅ 自动检测 |
| 进度显示 | ❌ 无 | ✅ 实时进度条 |
| 时间估算 | ❌ 无 | ✅ 剩余时间 |
| 取消功能 | ❌ 不可取消 | ✅ 随时取消 |
| 参数配置 | ❌ 需修改代码 | ✅ UI对话框 |
| 错误提示 | ⚠️ 技术性 | ✅ 用户友好 |
| 用户体验 | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |

---

## 兼容性

- ✅ macOS
- ✅ Windows (未测试)
- ✅ Photoshop CC 2019+
- ✅ Photoshop 2025

---

## 故障排查

### 问题1: 找不到安装目录
**症状**: 弹出"无法找到SuperStarOff安装目录"

**解决**:
1. 确保已安装SuperStarOff
2. 手动选择安装目录
3. 或设置环境变量:
```bash
export SUPERSTAROFF_INSTALL_DIR="/usr/local/SuperStarOff"
```

### 问题2: Python未找到
**症状**: "找不到Python解释器"

**解决**:
1. 确保安装目录中有`.venv/bin/python`
2. 或确保系统安装了Python 3:
```bash
which python3
```

### 问题3: 处理失败
**症状**: "处理失败"对话框

**解决**:
1. 查看ExtendScript工具包控制台获取详细错误
2. 检查日志文件: `/tmp/SuperStarOff/python_log_*.txt`
3. 确保模型文件存在: `{install_dir}/models/SuperStarOff2025.pt`

---

## 开发者信息

### 文件结构
```
SuperStarOff_PS_v2.jsx
├─ CONFIG                    # 全局配置
├─ main()                    # 主入口
├─ detectInstallDir()        # 路径检测
├─ showConfigDialog()        # 参数UI
├─ processWithProgress()     # 带进度处理
├─ createProgressWindow()    # 创建进度窗口
├─ updateProgress()          # 更新进度
└─ 工具函数 (export, import, cleanup...)
```

### 调试
启用调试日志:
```javascript
// ExtendScript工具包 > JavaScript控制台
$.writeln("调试信息");
```

---

## 下一步计划

- [ ] 添加批量处理支持
- [ ] 集成HTTP服务器状态检查
- [ ] 添加处理历史记录
- [ ] 支持自定义快捷键
- [ ] 多语言支持

---

## 贡献

欢迎提交Issue和Pull Request！

GitHub: https://github.com/jamesphotography/SuperStarOff

---

## 许可

与SuperStarOff主项目相同
