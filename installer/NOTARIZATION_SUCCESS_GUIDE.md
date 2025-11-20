# SuperStarOff 公证成功指南

**最后更新**: 2025-11-14
**成功版本**: V11
**状态**: ✅ 公证通过

---

## 📦 成功的安装包信息

**文件**: `SuperStarOff-PS-Installer-v11-COMPLETE.pkg`
**大小**: 374M
**MD5**: `486085107ab45a4593dfe17476c1640d`
**公证 ID**: `8021be3e-2056-4f26-9f5d-46e315c780a4`
**公证状态**: ✅ Accepted
**构建时间**: 2025-11-14 18:18 CST

---

## 🎯 成功的关键原因

### 问题回顾

在此之前，有 **5 次连续的公证失败**（2025-11-14 的多次尝试），失败原因都是：
- Python Framework 主库签名无效
- 大量 `.dylib` 和 `.so` 文件未签名或签名失效
- 错误提示: "The signature of the binary is invalid"

### 根本原因

使用了 **错误的构建脚本** (`build_pkg_complete.sh`)，该脚本的问题：
1. 在安装依赖**之前**就签名了 Python Framework
2. 后续安装 PyTorch 等依赖时修改了 Framework 内容
3. 导致之前的签名失效

### 解决方案

使用 **正确的构建脚本** (`build_pkg_standalone.sh`)，关键技术点：

#### 1. **签名时机至关重要**

```bash
# ❌ 错误方式
codesign Python.framework     # 先签名
pip install pytorch            # 后安装依赖 → 签名失效

# ✅ 正确方式
pip install pytorch            # 先安装所有依赖
find -name "__pycache__" -delete  # 清理缓存
codesign Python.framework      # 最后统一签名
```

#### 2. **正确的签名顺序**（从内到外）

```bash
# 步骤 1: 签名所有 .so 扩展模块
find "$FRAMEWORK_DST/lib/python3.11/lib-dynload" -name "*.so" | \
    while read SO_FILE; do
        codesign --force --sign "$DEVELOPER_ID" \
            --options runtime --timestamp "$SO_FILE"
    done

# 步骤 2: 签名 site-packages 中的共享库
find "$FRAMEWORK_DST/lib/python3.11/site-packages" -name "*.dylib" | \
    while read DYLIB; do
        codesign --force --sign "$DEVELOPER_ID" \
            --options runtime --timestamp "$DYLIB"
    done

# 步骤 3: 签名 site-packages 中的 .so 文件
find "$FRAMEWORK_DST/lib/python3.11/site-packages" -name "*.so" | \
    while read SO_FILE; do
        codesign --force --sign "$DEVELOPER_ID" \
            --options runtime --timestamp "$SO_FILE"
    done

# 步骤 4: 签名 python.o
codesign --force --sign "$DEVELOPER_ID" \
    --options runtime --timestamp \
    "$FRAMEWORK_DST/lib/python3.11/config-3.11-darwin/python.o"

# 步骤 5: 签名 bin/python3.11
codesign --force --sign "$DEVELOPER_ID" \
    --options runtime --timestamp \
    "$FRAMEWORK_DST/bin/python3.11"

# 步骤 6: 签名 Python.app（如果有）
codesign --force --sign "$DEVELOPER_ID" \
    --options runtime --timestamp --deep \
    "$FRAMEWORK_DST/Resources/Python.app"

# 步骤 7: 签名 Python 主库（关键！）
# 注意：只签名 Python 主库文件，不要签名整个 Framework bundle
codesign --force --sign "$DEVELOPER_ID" \
    --options runtime --timestamp \
    "$FRAMEWORK_DST/Python"

# ❌ 错误：不要这样做
# codesign "$APP_DIR/Python.framework"  # 会破坏内部文件签名
```

#### 3. **关键区别**

| 项目 | ❌ 失败的方式 | ✅ 成功的方式 |
|------|--------------|--------------|
| 签名时机 | 依赖安装前 | 依赖安装后 |
| 签名对象 | 整个 Framework bundle | 只签名 Python 主库 |
| 签名顺序 | 随机或不完整 | 严格从内到外 |
| 清理缓存 | 可能在签名前 | 签名前清理 |

---

## 📋 完整构建流程

### 步骤 1: 使用正确的构建脚本

```bash
cd /Users/jameszhenyu/PycharmProjects/SuperStarOff/installer
./build_pkg_standalone.sh
```

**脚本位置**: `installer/build_pkg_standalone.sh`

**输出**: `installer/release_pkg/SuperStarOff-PS-Installer-v11-COMPLETE.pkg`

### 步骤 2: 验证签名

```bash
pkgutil --check-signature \
    installer/release_pkg/SuperStarOff-PS-Installer-v11-COMPLETE.pkg
```

**预期输出**:
```
Status: signed by a developer certificate issued by Apple for distribution
Signed with a trusted timestamp on: 2025-11-14 10:18:05 +0000
```

### 步骤 3: 提交公证

```bash
xcrun notarytool submit \
    installer/release_pkg/SuperStarOff-PS-Installer-v11-COMPLETE.pkg \
    --apple-id "jameszhen13@gmail.com" \
    --team-id "G2Z53BQNZ3" \
    --keychain-profile "notarytool-password" \
    --wait
```

**处理时间**: 约 10-20 分钟

**预期输出**:
```
Processing complete
  id: [submission-id]
  status: Accepted
```

### 步骤 4: 装订公证票据

```bash
xcrun stapler staple \
    installer/release_pkg/SuperStarOff-PS-Installer-v11-COMPLETE.pkg
```

**预期输出**:
```
The staple and validate action worked!
```

### 步骤 5: 验证最终包

```bash
# 验证签名和公证
pkgutil --check-signature \
    installer/release_pkg/SuperStarOff-PS-Installer-v11-COMPLETE.pkg

# 验证装订
xcrun stapler validate \
    installer/release_pkg/SuperStarOff-PS-Installer-v11-COMPLETE.pkg
```

**预期输出**:
```
Notarization: trusted by the Apple notary service
The validate action worked!
```

---

## 🔧 build_pkg_standalone.sh 关键代码

### 完整的签名流程（第 204-236 行）

```bash
# 最后签名整个 Python Framework（所有修改完成后）
echo "=== 最终签名 Python Framework ==="

# 签名所有可执行文件和库
echo "  签名 Framework 内的二进制文件..."

# 签名所有 .so 扩展模块
find "$FRAMEWORK_DST/lib/python3.11/lib-dynload" -name "*.so" -type f | \
    while read SO_FILE; do
        codesign --force --sign "$DEVELOPER_ID" \
            --options runtime --timestamp "$SO_FILE" 2>/dev/null || true
    done

# 签名 site-packages 中的依赖
find "$FRAMEWORK_DST/lib/python3.11/site-packages" \
    \( -name "*.dylib" -o -name "*.so" \) -type f | \
    while read LIB_FILE; do
        codesign --force --sign "$DEVELOPER_ID" \
            --options runtime --timestamp "$LIB_FILE" 2>/dev/null || true
    done

# 签名 python.o
if [ -f "$FRAMEWORK_DST/lib/python3.11/config-3.11-darwin/python.o" ]; then
    codesign --force --sign "$DEVELOPER_ID" \
        --options runtime --timestamp \
        "$FRAMEWORK_DST/lib/python3.11/config-3.11-darwin/python.o" \
        2>/dev/null || true
fi

# 签名 bin/python3.11
if [ -f "$FRAMEWORK_DST/bin/python3.11" ]; then
    codesign --force --sign "$DEVELOPER_ID" \
        --options runtime --timestamp \
        "$FRAMEWORK_DST/bin/python3.11" 2>/dev/null || true
fi

# 签名 Python.app（如果有）
if [ -d "$FRAMEWORK_DST/Resources/Python.app" ]; then
    codesign --force --sign "$DEVELOPER_ID" \
        --options runtime --timestamp --deep \
        "$FRAMEWORK_DST/Resources/Python.app" 2>/dev/null || true
fi

# 最后签名 Python 主库（不要签名整个bundle，会破坏内部文件签名）
codesign --force --sign "$DEVELOPER_ID" \
    --options runtime --timestamp \
    "$FRAMEWORK_DST/Python" 2>/dev/null && \
    echo "  ✓ Python 主库已签名"
```

---

## 🚨 常见错误和避免方法

### 错误 1: Python Framework 签名无效

**错误信息**:
```
The signature of the binary is invalid.
path: Python.framework/Versions/3.11/Python
```

**原因**: 在安装依赖前签名了 Framework，后续安装修改了内容

**解决**: 使用 `build_pkg_standalone.sh`，在所有依赖安装完成后再签名

### 错误 2: 大量 .dylib 和 .so 未签名

**错误信息**:
```
The binary is not signed with a valid Developer ID certificate.
path: site-packages/cv2/.dylibs/libopencv_core.4.10.0.dylib
```

**原因**: 没有签名 site-packages 中的依赖库

**解决**: 在签名流程中添加对 site-packages 的遍历签名

### 错误 3: python.o 未签名

**错误信息**:
```
The binary is not signed.
path: lib/python3.11/config-3.11-darwin/python.o
```

**原因**: 遗漏了 python.o 的签名

**解决**: 明确签名 python.o 文件

---

## 📊 公证历史对比

### ❌ 失败的尝试（2025-11-14）

| Submission ID | 时间 | 状态 | 原因 |
|--------------|------|------|------|
| 687a4fdd... | 09:08 | Invalid | Python 签名无效 |
| 47374e96... | 08:18 | Invalid | Python 签名无效 |
| d1e12305... | 06:07 | Invalid | Python 签名无效 |
| e1be661a... | 01:40 | Invalid | Python 签名无效 |
| e916416a... | 00:52 | Invalid | Python 签名无效 |

### ✅ 成功的公证

| Submission ID | 时间 | 状态 | 使用脚本 |
|--------------|------|------|---------|
| 8021be3e... | 2025-11-14 10:18 | **Accepted** | `build_pkg_standalone.sh` |
| 60d15017... | 2025-11-13 05:35 | **Accepted** | `build_pkg_standalone.sh` |

---

## 🎓 经验总结

### 必须遵守的原则

1. **签名时机**: 永远在所有文件修改完成后再签名
2. **签名顺序**: 严格从内到外（扩展 → 库 → 二进制 → Framework）
3. **签名对象**: 只签名 Python 主库文件，不签名整个 bundle
4. **清理缓存**: 签名前清理所有 `__pycache__` 和 `.pyc` 文件
5. **使用正确的脚本**: `build_pkg_standalone.sh`，不要使用 `build_pkg_complete.sh`

### 下次构建检查清单

- [ ] 使用 `build_pkg_standalone.sh` 脚本
- [ ] 确认所有依赖已安装到 site-packages
- [ ] 确认清理了所有缓存文件
- [ ] 确认签名顺序正确（从内到外）
- [ ] 验证包签名正确
- [ ] 提交公证并等待结果
- [ ] 装订公证票据
- [ ] 验证最终包

---

## 🔗 相关文档

- **构建脚本**: `installer/build_pkg_standalone.sh`
- **公证脚本**: `installer/release_pkg/notarize.sh`
- **成功报告**: `installer/release_pkg/NOTARIZATION_SUCCESS.md`
- **技术笔记**: `installer/release_pkg/TECHNICAL_NOTES.txt`

---

## 📞 Apple Developer 信息

- **Apple ID**: jameszhen13@gmail.com
- **Team ID**: G2Z53BQNZ3
- **Developer ID Installer**: James Zhen Yu (JWR6FDB52H)
- **Keychain Profile**: notarytool-password

---

## 🎉 最终检查

构建完成后，运行以下命令确认一切正常：

```bash
# 1. 检查签名
pkgutil --check-signature [包文件路径]

# 2. 检查公证
spctl -a -vv -t install [包文件路径]

# 3. 检查装订
xcrun stapler validate [包文件路径]

# 4. 获取包信息
ls -lh [包文件路径]
md5 [包文件路径]
```

---

**下次打包时，直接参考此文档，使用 `build_pkg_standalone.sh` 即可成功！**
