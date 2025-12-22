# Python 依赖问题解决方案

## 问题分析

当前问题：虚拟环境中的 Python 二进制文件虽然被复制了，但仍然动态链接到：
```
/Library/Frameworks/Python.framework/Versions/3.11/Python
```

这个 Framework 只存在于开发机器上，测试机器上没有。

## 解决方案选项

### 方案 1: 打包 Python Framework（推荐）⭐

将整个 Python.framework 打包到安装包中。

优点：
- ✅ 完全独立
- ✅ 用户无需安装任何东西
- ✅ 最佳用户体验

缺点：
- ❌ 包会更大（约 +50MB）
- ❌ 需要修改构建脚本

实现：
1. 复制 `/Library/Frameworks/Python.framework/Versions/3.11` 到包内
2. 将其安装到 `/usr/local/SuperStarOff/Python.framework`
3. 修改虚拟环境的动态链接路径（使用 `install_name_tool`）

### 方案 2: 使用 PyInstaller 打包 CLI

将 Python CLI 和所有依赖打包成单一可执行文件。

优点：
- ✅ 完全独立
- ✅ 单一二进制文件

缺点：
- ❌ PyTorch 等大型库难以打包
- ❌ 可能遇到动态加载问题
- ❌ 包会非常大（>500MB）

### 方案 3: 要求用户安装 Python 3.11

在安装时检测 Python，如果没有则提示安装。

优点：
- ✅ 包体积小
- ✅ 实现简单

缺点：
- ❌ 用户体验差
- ❌ 需要用户手动操作
- ❌ 可能有权限问题

### 方案 4: 使用 python-build-standalone

使用 Gregory Szorc 的独立 Python 构建。

优点：
- ✅ 完全独立
- ✅ 无外部依赖

缺点：
- ❌ 需要下载和集成第三方构建
- ❌ 可能有兼容性问题

## 推荐实现：方案 1（打包 Python Framework）

这是最佳平衡方案。
