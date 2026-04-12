# SuperStarOff Windows 版本问题排查指南

> 编写日期: 2025-02-07
> 适用版本: v1.1.0
> 目标读者: Windows 环境开发/测试人员

---

## 一、问题描述

用户在 Photoshop 中运行「慧眼去星」脚本时，出现以下错误：

```
错误: 找不到 SuperStarOff 程序

请确保已正确安装 SuperStarOff:
C:\Program Files\SuperStarOff\superstaroff.exe

请运行安装程序或检查安装路径。
```

---

## 二、问题根因分析

经代码审查，发现存在 **路径不一致** 的问题：

### 2.1 各组件预期路径对比

| 组件 | 预期路径 | 说明 |
|------|----------|------|
| JSX 脚本默认值 | `C:\Program Files (x86)\SuperStarOff` | 硬编码的 fallback 路径 |
| Inno Setup 安装 | `C:\Program Files\SuperStarOff` | 使用 `{autopf}` 自动选择 |
| Python 搜索顺序 | `%PROGRAMFILES(X86)%` 优先 | 先搜 x86 再搜 64 位目录 |

### 2.2 核心问题

1. **Inno Setup 使用 `{autopf}`** (`installer/SuperStarOff.iss` 第 26 行)：在 64 位系统上会安装到 `C:\Program Files\SuperStarOff`
2. **JSX 脚本默认路径是 `C:\Program Files (x86)\SuperStarOff`** (`src/慧眼去星.jsx` 第 28 行和第 49 行)：两者不匹配
3. **config.json 传递机制可能失效**：虽然 Inno Setup 会复制 config.json 到 Photoshop Scripts 目录（第 188-190 行），但以下情况会导致失效：
   - 复制过程因权限问题失败
   - 用户使用 ZIP 便携版而非安装程序
   - 安装时未检测到 Photoshop，用户选择了"稍后手动安装"

---

## 三、问题排查步骤

请 Jordan 按以下步骤在 Windows 测试机上逐一排查：

### 3.1 检查实际安装位置

打开 Windows 资源管理器，依次检查以下目录是否存在：

```
□ C:\Program Files\SuperStarOff\superstaroff.exe
□ C:\Program Files (x86)\SuperStarOff\superstaroff.exe
□ C:\SuperStarOff\superstaroff.exe
```

**记录**：实际安装在哪个目录？ ___________________________

### 3.2 检查 config.json 文件

在安装目录中查找 config.json 文件，检查其内容：

```
路径: [安装目录]\config.json
```

预期内容格式：
```json
{
    "version": "1.1.0",
    "installDir": "C:\\Program Files\\SuperStarOff"
}
```

**检查项**：
- [ ] config.json 文件是否存在？
- [ ] installDir 的值是否指向正确的安装目录？
- [ ] 路径中的反斜杠是否正确转义（双反斜杠 `\\`）？

### 3.3 检查 Photoshop 脚本目录

找到 Photoshop 的脚本目录：

```
C:\Program Files\Adobe\Adobe Photoshop [版本年份]\Presets\Scripts\
```

**检查项**：
- [ ] 「慧眼去星.jsx」文件是否存在？
- [ ] 同目录下是否有 config.json 文件？（这是关键！）

**重要**：JSX 脚本会优先从**自身所在目录**读取 config.json，如果没有才会去默认安装路径找。

### 3.4 验证 superstaroff.exe 可以独立运行

打开 CMD 或 PowerShell，进入安装目录，运行：

```cmd
cd "C:\Program Files\SuperStarOff"
.\superstaroff.exe --help
```

**预期输出**：
```
usage: superstaroff [-h] [--stride {128,256,384,512}]
                    [--device {auto,cpu,mps,cuda}] [--verbose]
                    input output
...
```

**检查项**：
- [ ] 能正常显示帮助信息？
- [ ] 如果报错，错误信息是什么？ ___________________________

### 3.5 检查 JSX 脚本中的路径逻辑

用文本编辑器打开 Photoshop Scripts 目录中的「慧眼去星.jsx」，找到第 25-35 行左右的 `getInstallDir()` 函数：

```javascript
function getInstallDir() {
    var configPaths = [
        File($.fileName).parent.fsName + PATH_SEP + "config.json",
        IS_WINDOWS
            ? "C:\\Program Files (x86)\\SuperStarOff\\config.json"
            : "/usr/local/SuperStarOff/config.json"
    ];
    // ...
}
```

**注意第 28 行的硬编码路径**：`C:\\Program Files (x86)\\SuperStarOff`

这就是问题所在——如果脚本目录没有 config.json，就会 fallback 到这个 x86 路径。

---

## 四、解决方案

根据排查结果，选择对应的解决方案：

### 方案 A：手动复制 config.json（临时修复）

将安装目录中的 config.json 复制到 Photoshop Scripts 目录：

```cmd
copy "C:\Program Files\SuperStarOff\config.json" ^
     "C:\Program Files\Adobe\Adobe Photoshop 2024\Presets\Scripts\"
```

### 方案 B：修改 JSX 默认路径（代码修复，推荐）

修改 `src/慧眼去星.jsx` 和 `src/StarOff.jsx` 中的默认路径：

**文件**: `src/慧眼去星.jsx`

**修改 1** - 第 27-29 行，备选配置文件路径：

```diff
        IS_WINDOWS
-           ? "C:\\Program Files (x86)\\SuperStarOff\\config.json"
+           ? "C:\\Program Files\\SuperStarOff\\config.json"
            : "/usr/local/SuperStarOff/config.json"
```

**修改 2** - 第 47-50 行，fallback 目录：

```diff
    return IS_WINDOWS
-       ? "C:\\Program Files (x86)\\SuperStarOff"
+       ? "C:\\Program Files\\SuperStarOff"
        : "/usr/local/SuperStarOff";
```

**文件**: `src/StarOff.jsx`（英文版，同样修改）

应用相同的修改。

> **注意**：修改后需要重新打包安装程序并测试。

### 方案 C：修改 Inno Setup 安装脚本（推荐）

修改 `installer/SuperStarOff.iss`，在安装完成时自动复制 config.json 到 Photoshop Scripts 目录。

**相关代码位置**: `installer/SuperStarOff.iss` 第 160-200 行的 `CurStepChanged` 过程

需要在复制 JSX 文件的同时，也复制 config.json：

```pascal
// 现有代码 - 复制 JSX
SourceFile := AppPath + '\scripts\慧眼去星.jsx';
DestFile := PhotoshopPaths[I] + '\慧眼去星.jsx';
FileCopy(SourceFile, DestFile, False);

// 新增代码 - 同时复制 config.json
ConfigDest := PhotoshopPaths[I] + '\config.json';
FileCopy(ConfigFile, ConfigDest, False);
```

### 方案 D：增加多路径搜索（更健壮的修复）

修改 `src/慧眼去星.jsx` 中的 `getInstallDir()` 函数，同时搜索多个可能的安装位置：

```javascript
function getInstallDir() {
    var configPaths = [
        // 优先从脚本同目录读取
        File($.fileName).parent.fsName + PATH_SEP + "config.json"
    ];

    // Windows 多路径搜索
    if (IS_WINDOWS) {
        configPaths.push("C:\\Program Files\\SuperStarOff\\config.json");
        configPaths.push("C:\\Program Files (x86)\\SuperStarOff\\config.json");
    } else {
        configPaths.push("/usr/local/SuperStarOff/config.json");
        configPaths.push("/Applications/SuperStarOff/config.json");
    }

    // ... 后续代码不变 ...
}
```

---

## 五、Inno Setup 安装脚本当前状态检查

请检查 `installer/SuperStarOff.iss` 第 160-200 行，确认：

1. `CurStepChanged` 过程是否在 `ssPostInstall` 阶段复制了 config.json？
2. 复制目标是否包括 Photoshop Scripts 目录？

**当前代码逻辑**（需要验证）：
```pascal
procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    // 生成 config.json 到安装目录
    ConfigFile := AppPath + '\config.json';
    // ...

    // 复制 JSX 到 Photoshop
    for I := 0 to PhotoshopCount - 1 do
    begin
      // 是否也复制了 config.json？需要确认
    end;
  end;
end;
```

---

## 六、完整测试流程

修复后，请执行以下完整测试：

### 6.1 全新安装测试

1. 卸载现有版本（控制面板 > 程序和功能）
2. 删除残留目录：
   - `C:\Program Files\SuperStarOff`
   - `C:\Program Files (x86)\SuperStarOff`
3. 运行新编译的安装程序
4. 安装完成后检查：
   - [ ] 安装目录中有 superstaroff.exe
   - [ ] 安装目录中有 config.json
   - [ ] Photoshop Scripts 目录中有 慧眼去星.jsx
   - [ ] Photoshop Scripts 目录中有 config.json（关键！）

### 6.2 功能测试

1. 启动 Photoshop
2. 打开一张测试图片
3. 菜单：文件 > 脚本 > 慧眼去星
4. 观察：
   - [ ] 是否弹出错误对话框？
   - [ ] 是否显示处理进度窗口？
   - [ ] 处理完成后是否自动导入结果？

---

## 七、相关文件清单

| 文件 | 路径 | 用途 |
|------|------|------|
| JSX 生产脚本 | `src/慧眼去星.jsx` | Photoshop 插件主脚本 |
| JSX 英文版 | `src/StarOff.jsx` | 英文版脚本 |
| Inno Setup 脚本 | `installer/SuperStarOff.iss` | Windows 安装程序定义 |
| 构建脚本 | `installer/build_windows.bat` | 自动化构建 |
| PyInstaller 配置 | `superstaroff_windows.spec` | 可执行文件打包配置 |
| 核心处理模块 | `src/model_processor.py` | 包含路径搜索逻辑 |

---

## 八、附录：路径搜索优先级

### JSX 脚本路径搜索顺序（getInstallDir 函数）

1. `[脚本所在目录]\config.json` （优先）
2. `C:\Program Files (x86)\SuperStarOff\config.json` （fallback）
3. 如果都找不到，返回 `C:\Program Files (x86)\SuperStarOff`

### Python 程序路径搜索顺序（_get_install_directories 方法）

1. `%PROGRAMFILES(X86)%\SuperStarOff`
2. `%PROGRAMFILES%\SuperStarOff`
3. `%LOCALAPPDATA%\SuperStarOff`
4. `C:\SuperStarOff`

---

## 九、联系方式

如有问题，请联系开发团队并提供：

1. 操作系统版本（Windows 10/11，32/64位）
2. Photoshop 版本
3. 完整错误截图
4. 以上排查步骤的检查结果

---

## 十、调试技巧

### 10.1 在 JSX 中添加调试输出

临时修改 `慧眼去星.jsx`，在 `getInstallDir()` 函数末尾添加调试弹窗：

```javascript
var INSTALL_DIR = getInstallDir();
// 调试：显示检测到的安装路径
alert("调试信息:\n安装路径: " + INSTALL_DIR + "\n可执行文件: " + INSTALL_DIR + PATH_SEP + EXEC_NAME);
```

这样可以直接看到脚本实际使用的路径。

### 10.2 检查 Photoshop 脚本目录内容

在 CMD 中执行：

```cmd
dir "C:\Program Files\Adobe\Adobe Photoshop 2024\Presets\Scripts\"
```

确认目录中同时存在：
- 慧眼去星.jsx
- config.json

### 10.3 验证 config.json 内容格式

用记事本打开 config.json，确认格式正确：

```json
{
    "version": "1.1.0",
    "installDir": "C:\\Program Files\\SuperStarOff"
}
```

**注意**：路径中的反斜杠可以是单个 `\` 或双个 `\\`，JSX 脚本都能处理。

### 10.4 手动测试可执行文件

```cmd
"C:\Program Files\SuperStarOff\superstaroff.exe" --help
```

如果报错缺少 DLL，说明 PyInstaller 打包不完整。

---

## 十一、常见错误及解决方案

| 错误现象 | 可能原因 | 解决方案 |
|----------|----------|----------|
| 找不到 SuperStarOff 程序 | 路径不匹配 | 检查 config.json，或应用方案 B/D |
| config.json 不存在 | 安装程序未复制 | 手动复制或重新安装 |
| superstaroff.exe 无法运行 | 缺少依赖 DLL | 重新用 PyInstaller 打包 |
| Photoshop 菜单无脚本 | JSX 未安装到 Scripts 目录 | 手动复制 JSX 文件 |
| 处理时闪退无输出 | 模型文件损坏或缺失 | 检查 models 目录 |

---

## 十二、版本历史

| 版本 | 日期 | 变更内容 |
|------|------|----------|
| v1.1.0 | 2025-02 | 添加中文支持，Windows 安装程序 |
| v1.0.0 | 2025-01 | 初始版本 |

---

*文档结束*
