# SuperStarOff 慧眼去星 — 构建与发布指南

日常发版走 GitHub Actions，无需本地构建。本地构建仅用于调试。

---

## 一、发布新版本

### 快速流程

```bash
# 1. 同步版本号（见下表）并更新 RELEASE_NOTES.md
# 2. 提交后打 tag 推送
git tag v1.1.4
git push origin v1.1.4
```

推送 tag 后，两个 workflow 自动构建三个平台的安装包，并创建 **prerelease**：

| 产物 | 平台 | 约耗时 |
|---|---|---|
| `SuperStarOff-v{版本}-arm64.pkg` | macOS Apple Silicon | ~12 分钟（含 Apple 公证） |
| `SuperStarOff-v{版本}-x86_64.pkg` | macOS Intel | ~12 分钟（含 Apple 公证） |
| `SuperStarOff-Installer-v{版本}.exe` | Windows x64 | ~7 分钟 |

三个包在打进安装器之前都会**实跑一次完整推理**（加载模型 → 分块处理 → 写出文件）。这一步拦下过「签名公证全部通过、双击却启动失败」的产物，不要移除。

### 版本号需要同步的位置

```
src/慧眼去星.jsx           第 6 行注释 + var VERSION
src/StarOff.jsx            同上
installer/SuperStarOff.iss #define MyAppVersion（CI 会用 /D 覆盖，本地构建用此默认值）
installer/build_mac.sh     VERSION=（CI 会用 --version 覆盖）
installer/build_windows.bat set "VERSION="
```

JSX 里的版本号会显示在插件对话框标题上，**必须手动改**，CI 不覆盖它。

### 发布后的收尾

1. **真机验证**（prerelease 阶段的意义所在）——CI 只验证了「产物能跑」，安装流程本身没被验证过。三个平台各装一次，装完在终端直接调用 CLI 确认：

   ```bash
   # macOS
   /usr/local/SuperStarOff/superstaroff input.tif out.tif --verbose

   # Windows（额外确认 config 写入了真实安装路径）
   "C:\Program Files\SuperStarOff\superstaroff.exe" input.tif out.tif --verbose
   type "C:\Program Files\SuperStarOff\superstaroff.config.json"
   ```

   这一步不需要 Photoshop。Photoshop 内的对话框、进度条、图层生成，在任一台装有 PS 的机器上验证即可——JSX 三平台共用同一份逻辑。

2. **上传网盘**，把链接更新到 `docs/index.html` 与 `README.md`（各平台三个渠道）。

3. **转正式版**：

   ```bash
   gh release edit v1.1.4 --prerelease=false --latest
   ```

4. 确认网站已部署（GitHub Pages 自动触发，约 1 分钟）：
   https://superstaroff.jamesphotography.com.au

### 只想构建不想发布

用 `workflow_dispatch` 手动触发，只产出 artifact，不创建任何 release：

```bash
gh workflow run build-macos.yml   -f version=1.1.4 -f arch=all   # 或 arm64 / x86_64
gh workflow run build-windows.yml -f version=1.1.4
gh run download <run-id>          # 下载产物
```

---

## 二、CI 配置

### Secrets（7 项，仓库级）

| 名称 | 内容 |
|---|---|
| `MACOS_CERTIFICATE` | Developer ID **Application** 证书 .p12 的 base64 |
| `MACOS_CERTIFICATE_PWD` | 导出该 .p12 时设置的密码 |
| `MACOS_INSTALLER_CERTIFICATE` | Developer ID **Installer** 证书 .p12 的 base64 |
| `MACOS_INSTALLER_CERTIFICATE_PWD` | 导出该 .p12 时设置的密码 |
| `APPLE_ID` | Apple ID 邮箱 |
| `APPLE_APP_PASSWORD` | App 专用密码（appleid.apple.com 生成，形如 xxxx-xxxx-xxxx-xxxx） |
| `MACOS_TEAM_ID` | `JWR6FDB52H` |

证书有效期五年（当前到 **2027-02-01**），到期后需重新从钥匙串导出 .p12 并更新前四项。

验证凭据是否可用（不构建、不提交公证）：

```bash
gh workflow run verify-signing-credentials.yml
```

### 模型文件

模型 **不随仓库 checkout 拉取**。它托管在 `model-assets-2025` 这个 prerelease 中，CI 用 `gh release download` 获取。

原因：模型 176MB，走 Git LFS 时每次构建消耗同等带宽，免费额度一个月只够五六次构建。

更换模型时，更新该 release 的资产即可，无需改动 workflow。

---

## 三、已知陷阱

以下每一条都实际踩过，改动相关代码前请先读。

### 通用

- **`torch.distributed` 必须用 `collect_submodules` 整包收集。** 在 `hiddenimports` 里逐条列出 `torch.distributed.rpc` 之类是不够的，PyInstaller 收不全，产物启动时报 `ModuleNotFoundError`——而 `torch/nn/__init__.py` 在 import 阶段就会走到这条链，即启动即失败。
- **Python 锁定 3.11。** 上限来自 `numpy<2.0`（1.x 最后一系列 1.26 只提供到 cp312 的 wheel）；Intel 版还要求 `torch 2.2.2` 与 `cryptography<49`，两者的 macOS x86_64 wheel 也止于 cp311/cp312。用 3.13 会导致 Intel 构建整条断掉。

### macOS

- **Intel 版必须锁 `torch==2.2.2` 与 `cryptography<49`。** PyTorch 自 2.3 起不再发布 macOS x86_64 wheel，cryptography 自 49 起同样如此。不锁版本 pip 会退化为源码编译，编译产物的扩展模块 PyInstaller 收集不到，表现为运行时 `Encryption module not available` 而无法解密模型。
- **PKG 签名用 `rcodesign`，不要用 `productsign`。** 后者在无头 runner 上取 Installer 私钥会被钥匙串阻塞——实测被 300 秒超时打断，且这是在 `set-key-partition-list` 已正确设置的前提下。脚本保留了 productsign 作为本地回退，但 CI 路径不要走它。
- **切勿定义 `RCODESIGN_` 前缀的环境变量。** rcodesign 从该前缀读取自身配置，`RCODESIGN_VERSION` 会被解析成 profile 的 `version` 键并因 `UnknownField` 直接中止。workflow 里那个变量因此叫 `RC_VERSION`。
- **临时钥匙串必须加入 user 域搜索列表**（`security list-keychains -d user -s`），否则 codesign 报 `The specified item could not be found in the keychain.`，即便 `find-identity` 能在该钥匙串里找到证书。`--keychain` 只缩小查询范围，不添加搜索路径。
- **两张证书都要在 `set-key-partition-list` 之前导入**，否则其私钥拿不到非交互访问授权，签名时会卡在密码弹窗上（无头环境即永久挂起）。
- **签名顺序自内向外，且全部启用 hardened runtime。** 先签普通 Mach-O（跳过 framework 内部），再对 `.framework` 整体签名，最后签主可执行文件。单独签 framework 内的文件会使其 bundle 签名失效，公证会判 `signature is invalid`。按扩展名筛选也不行——`torch/bin/protoc`、`torch_shm_manager`、`Python` 都没有后缀，须按 `file` 输出的 Mach-O 魔数判断。
- **PKG payload 用 `ditto` 复制，不要用 `cp`。** Python.framework 的签名依赖符号链接与扩展属性，`cp` 复制后公证会判定 `_internal/Python` 与 `Python.framework/Python` 签名无效。
- 公证被判 `Invalid` 时，`notarytool submit` 只报状态。用 `notarytool log <submission-id>` 拉取 Apple 的逐项检查结果——它会明确指出哪个文件、什么原因。`build_mac.sh` 已在失败时自动拉取。

### Windows

- **Inno Setup 的 Pascal Script 没有 `StringReplace`。** 那是 Delphi SysUtils 的函数，用了会在编译期报 `Unknown identifier` 并中止。就地替换用 `StringChangeEx`。此坑曾导致 Windows 安装包连续三个版本编译不出来。
- **不要在 CI 里调用 `installer/build_windows.bat`。** 它内含多处 `pause`，会永久阻塞 job。workflow 里以 pwsh 复刻了它的文件复制步骤。
- **CLI 的 stdout 在重定向下必须强制 UTF-8。** JSX 以 `> logFile 2>&1` 调用 CLI，此时 Python 改用系统 locale 编码（cp936/cp1252），输出中文即抛 `UnicodeEncodeError` 并终止进程，日志停在半截。`superstaroff_cli.py` 启动时已做 `reconfigure(encoding="utf-8")`。`chcp 65001` 只影响控制台，对重定向无效。

### 安装脚本

- **`preinstall` / `postinstall` 以 root 运行**，日志须写入 `/var/log` 而非全局可写的 `/tmp`：攻击者可预先将目标路径建为符号链接，`tee -a` 会跟随并以 root 身份写入，造成任意文件破坏或提权。

---

## 四、本地构建（调试用）

### 环境

```bash
python3.11 -m venv .venv
.venv/bin/pip install -r requirements.txt pyinstaller
```

模型需自行放置到 `models/SuperStarOff2025.pt`（可从 `model-assets-2025` release 下载）。

### macOS

```bash
./installer/build_mac.sh                 # 完整流程：打包 → 签名 → PKG → 公证 → 钉票
./installer/build_mac.sh --no-notarize   # 跳过公证，快速验证打包
./installer/build_mac.sh --help
```

无参数运行时使用登录钥匙串中的证书，公证走 `notarytool` 的 keychain-profile（需事先 `notarytool store-credentials` 建立名为 `superstaroff-notary` 的 profile）。

产物架构跟随当前机器——`superstaroff.spec` 中 `target_arch=None`，且 PyTorch 无 universal2 wheel，**无法交叉编译**。Intel 包只能在 Intel 机器或 CI 的 `macos-15-intel` runner 上构建。

### Windows

```powershell
pyinstaller superstaroff_windows.spec --noconfirm
installer\build_windows.bat
```

需要 Inno Setup 6（https://jrsoftware.org/isinfo.php）。

---

## 五、安装后的目录结构

### macOS
```
/usr/local/SuperStarOff/
├── superstaroff                    # CLI
├── 慧眼去星.jsx
├── 安装到Photoshop.app             # 图形化插件安装工具
└── _internal/                      # PyInstaller 依赖
    └── models/SuperStarOff2025.pt
```

macOS 端**不生成** `superstaroff.config.json`：安装路径固定为 `/usr/local/SuperStarOff`，
JSX 找不到配置文件时会回退到该固定路径，因此无需配置。config 机制是 Windows 特有的
（安装目录可由用户选择），由 Inno Setup 的 `[Code]` 段在 `ssPostInstall` 时写入。

### Windows
```
C:\Program Files\SuperStarOff\
├── superstaroff.exe
├── superstaroff.config.json
├── scripts\
│   ├── 慧眼去星.jsx
│   ├── install_to_photoshop.bat
│   └── uninstall_from_photoshop.bat
└── _internal\
    └── models\SuperStarOff2025.pt
```

JSX 被复制到各 Photoshop 版本的 `Presets/Scripts/` 目录。Windows 上 `superstaroff.config.json`
也会复制一份到该目录——JSX 优先从自身所在目录读取配置来定位 CLI，读不到才回退到固定路径
（64 位 Program Files 优先，x86 次之）。

---

## 六、故障排除

### 插件报「Bad CPU type in executable」
Intel Mac 装了 arm64 版本。Rosetta 只能让 Apple Silicon 运行 x86_64，反向不存在。下载 `x86_64.pkg`。

### 插件卡住直到超时 / 日志文件为空
CLI 未能启动或中途崩溃。查看对话框提示的日志路径；macOS 上 JSX 会先写入日志头，因此日志文件必定存在，内容可用于诊断。

### Photoshop 找不到插件
确认 JSX 位于对应 Photoshop 版本的 `Presets/Scripts/` 下。Windows 还需确认
`superstaroff.config.json` 存在且 `installDir` 指向真实安装目录；macOS 无此文件，
走固定路径 `/usr/local/SuperStarOff`。

### 模型加载失败 / PytorchStreamReader failed
模型为加密存储，需要 `cryptography` 模块解密。若日志出现 `Encryption module not available`，说明打包时未收集到该模块（Intel 版常见，见「已知陷阱」）。

### CI 构建失败
先看失败步骤，再对照「已知陷阱」。公证失败时 `build_mac.sh` 会自动拉取 Apple 的逐项日志。
