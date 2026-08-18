#!/bin/bash
# SuperStarOff - macOS PKG 构建脚本
# 流程: PyInstaller 打包 → 深度签名 → 构建 PKG → 签名 → 公证 → 钉入票据
#
# 两种模式：
#   本地  ./installer/build_mac.sh
#         使用登录钥匙串中的证书，公证走 notarytool keychain-profile
#   CI    ./installer/build_mac.sh --version 1.1.3 --p12-app app.p12 \
#             --p12-installer installer.p12 --apple-id x@y.z --team-id XXXX
#         证书从 .p12 导入临时钥匙串，公证走 Apple ID + App 专用密码
#
# CI 模式所需环境变量：
#   APP_P12_PASSWORD        Application 证书 .p12 的密码
#   INSTALLER_P12_PASSWORD  Installer 证书 .p12 的密码
#   APPLE_APP_PASSWORD      Apple ID App 专用密码（公证用）
set -euo pipefail

# ============================================================
# 默认配置
# ============================================================
VERSION="1.1.3"
ARCH="$(uname -m)"
APP_BUNDLE_ID="com.jameszhengyu.superstaroff"
INSTALL_LOCATION="/usr/local/SuperStarOff"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

APP_SIGN_ID="Developer ID Application: James Zhen Yu (JWR6FDB52H)"
PKG_SIGN_ID="Developer ID Installer: James Zhen Yu (JWR6FDB52H)"
NOTARY_PROFILE="superstaroff-notary"

P12_APP=""
P12_INSTALLER=""
APPLE_ID=""
TEAM_ID=""
SKIP_VENV=0
NOTARIZE=1

# ============================================================
# 参数解析
# ============================================================
while [[ $# -gt 0 ]]; do
    case "$1" in
        --version)        VERSION="$2"; shift 2 ;;
        --arch)           ARCH="$2"; shift 2 ;;
        --p12-app)        P12_APP="$2"; shift 2 ;;
        --p12-installer)  P12_INSTALLER="$2"; shift 2 ;;
        --apple-id)       APPLE_ID="$2"; shift 2 ;;
        --team-id)        TEAM_ID="$2"; shift 2 ;;
        --skip-venv)      SKIP_VENV=1; shift ;;
        --no-notarize)    NOTARIZE=0; shift ;;
        -h|--help)
            sed -n '2,20p' "$0"; exit 0 ;;
        *)
            echo "[ERROR] 未知参数: $1" >&2; exit 1 ;;
    esac
done

DIST_DIR="$PROJECT_ROOT/dist/superstaroff"
BUILD_DIR="$PROJECT_ROOT/build/mac_pkg"
OUTPUT_DIR="$PROJECT_ROOT/installer_output"
PKG_FINAL="$OUTPUT_DIR/SuperStarOff-v$VERSION-$ARCH.pkg"
VENV_DIR="$PROJECT_ROOT/.venv_dist"

# 提供 .p12 即进入 CI 模式：证书导入临时钥匙串，用完即焚
CI_MODE=0
[ -n "$P12_APP" ] && CI_MODE=1

echo ""
echo "==================================================="
echo "  SuperStarOff macOS PKG 构建 v$VERSION ($ARCH)"
echo "  模式: $([ "$CI_MODE" = 1 ] && echo 'CI（.p12 临时钥匙串）' || echo '本地（登录钥匙串）')"
echo "==================================================="
echo ""

# ============================================================
# Step 1: 前提条件 / 证书准备
# ============================================================
echo "=== Step 1: 前提条件 ==="

if [ ! -f "$PROJECT_ROOT/superstaroff.spec" ]; then
    echo "[ERROR] 找不到 superstaroff.spec" >&2
    exit 1
fi

TEMP_KEYCHAIN=""
cleanup() {
    if [ -n "$TEMP_KEYCHAIN" ] && [ -f "$TEMP_KEYCHAIN" ]; then
        security delete-keychain "$TEMP_KEYCHAIN" 2>/dev/null || true
    fi
}
trap cleanup EXIT

if [ "$CI_MODE" = 1 ]; then
    : "${APP_P12_PASSWORD:?需要设置 APP_P12_PASSWORD}"
    : "${INSTALLER_P12_PASSWORD:?需要设置 INSTALLER_P12_PASSWORD}"
    [ -f "$P12_APP" ] || { echo "[ERROR] 找不到 $P12_APP" >&2; exit 1; }
    [ -f "$P12_INSTALLER" ] || { echo "[ERROR] 找不到 $P12_INSTALLER" >&2; exit 1; }

    TEMP_KEYCHAIN="$(mktemp -d)/build.keychain-db"
    KC_PW="$(uuidgen)"

    security create-keychain -p "$KC_PW" "$TEMP_KEYCHAIN"
    security set-keychain-settings -lut 21600 "$TEMP_KEYCHAIN"

    # 必须把临时钥匙串加入 user 域搜索列表：Security framework 不会主动搜索任意
    # 钥匙串，codesign 的 --keychain 只缩小查询范围而不添加搜索路径。少了这一步，
    # 即便 find-identity 能在该钥匙串中找到证书，codesign 仍会报
    # "The specified item could not be found in the keychain."
    EXISTING_KC="$(security list-keychains -d user | sed -E 's/^[[:space:]]*"//; s/"$//')"
    # shellcheck disable=SC2086
    security list-keychains -d user -s "$TEMP_KEYCHAIN" $EXISTING_KC

    security unlock-keychain -p "$KC_PW" "$TEMP_KEYCHAIN"

    # 两张证书都必须在 set-key-partition-list 之前导入，否则其私钥拿不到
    # 非交互访问授权，签名时会卡在密码弹窗上（无头环境即为永久挂起）
    security import "$P12_APP" -k "$TEMP_KEYCHAIN" -P "$APP_P12_PASSWORD" -T /usr/bin/codesign
    security import "$P12_INSTALLER" -k "$TEMP_KEYCHAIN" -P "$INSTALLER_P12_PASSWORD" -T /usr/bin/productsign

    security set-key-partition-list -S apple-tool:,apple: -s -k "$KC_PW" "$TEMP_KEYCHAIN" >/dev/null

    echo "[OK] 证书已导入临时钥匙串"
    security find-identity -v "$TEMP_KEYCHAIN" | grep "Developer ID" || true
else
    if ! security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
        echo "[ERROR] 未找到 Developer ID Application 证书" >&2
        exit 1
    fi
    if ! security find-identity -v | grep -q "Developer ID Installer"; then
        echo "[ERROR] 未找到 Developer ID Installer 证书" >&2
        exit 1
    fi
    echo "[OK] 登录钥匙串中证书齐全"
fi
echo ""

# ============================================================
# Step 2: 打包虚拟环境
# ============================================================
echo "=== Step 2: 打包环境 ==="

if [ "$SKIP_VENV" = 1 ]; then
    PYINSTALLER="$(command -v pyinstaller)"
    echo "[OK] 使用当前环境的 pyinstaller: $PYINSTALLER"
else
    if [ ! -f "$VENV_DIR/bin/python" ]; then
        echo "创建干净的虚拟环境: $VENV_DIR"
        python3 -m venv "$VENV_DIR"
        "$VENV_DIR/bin/pip" install --upgrade pip -q
        echo "安装依赖（首次较慢，约 3-5 分钟）..."
        "$VENV_DIR/bin/pip" install \
            torch \
            "numpy>=1.24.0,<2.0" \
            Pillow tifffile imagecodecs \
            cryptography \
            pyinstaller -q
        echo "[OK] 虚拟环境准备完成"
    else
        echo "[OK] 已有虚拟环境，跳过安装"
    fi
    PYINSTALLER="$VENV_DIR/bin/pyinstaller"
fi
echo ""

# ============================================================
# Step 3: PyInstaller 打包
# ============================================================
echo "=== Step 3: PyInstaller 打包 ==="

cd "$PROJECT_ROOT"
export SUPERSTAROFF_CODESIGN_IDENTITY="$APP_SIGN_ID"
"$PYINSTALLER" superstaroff.spec --noconfirm

if [ ! -f "$DIST_DIR/superstaroff" ]; then
    echo "[ERROR] PyInstaller 打包失败，找不到可执行文件" >&2
    exit 1
fi

BUILT_ARCH="$(lipo -archs "$DIST_DIR/superstaroff" 2>/dev/null || echo unknown)"
echo "[OK] 打包完成，产物架构: $BUILT_ARCH"
if [ "$BUILT_ARCH" != "$ARCH" ]; then
    echo "[WARN] 产物架构 ($BUILT_ARCH) 与声明架构 ($ARCH) 不一致"
fi
echo ""

# ============================================================
# Step 4: 深度签名
# ============================================================
echo "=== Step 4: 深度签名二进制文件 ==="

find "$DIST_DIR" -type f \( -name "*.so" -o -name "*.dylib" \) | while read -r f; do
    codesign --force --sign "$APP_SIGN_ID" --timestamp "$f" 2>/dev/null || true
done

codesign --force --sign "$APP_SIGN_ID" --timestamp \
    --options runtime "$DIST_DIR/superstaroff"

echo "[OK] 签名完成"
echo ""

# ============================================================
# Step 5: 编译并签名 安装到Photoshop.app
# ============================================================
echo "=== Step 5: 编译 安装到Photoshop.app ==="

APPLESCRIPT_SRC="$SCRIPT_DIR/macos/安装到Photoshop.applescript"
APPLET_OUT="$SCRIPT_DIR/macos/安装到Photoshop.app"

rm -rf "$APPLET_OUT"
osacompile -o "$APPLET_OUT" "$APPLESCRIPT_SRC"

[ -d "$APPLET_OUT" ] || { echo "[ERROR] AppleScript 编译失败" >&2; exit 1; }

codesign --force --sign "$APP_SIGN_ID" --timestamp \
    --options runtime "$APPLET_OUT"

echo "[OK] 编译并签名完成"
echo ""

# ============================================================
# Step 6: 准备 PKG Payload
# ============================================================
echo "=== Step 6: 准备 PKG Payload ==="

PAYLOAD_DIR="$BUILD_DIR/payload$INSTALL_LOCATION"
rm -rf "$BUILD_DIR"
mkdir -p "$PAYLOAD_DIR" "$OUTPUT_DIR"

cp -r "$DIST_DIR/." "$PAYLOAD_DIR/"
cp "$PROJECT_ROOT/src/慧眼去星.jsx" "$PAYLOAD_DIR/慧眼去星.jsx"
cp -r "$APPLET_OUT" "$PAYLOAD_DIR/安装到Photoshop.app"

echo "[OK] Payload 准备完成"
echo ""

# ============================================================
# Step 7: 构建 PKG
# ============================================================
echo "=== Step 7: 构建 PKG ==="

SCRIPTS_DIR="$SCRIPT_DIR/macos/scripts"
chmod +x "$SCRIPTS_DIR/preinstall" "$SCRIPTS_DIR/postinstall"

COMPONENT_PKG="$BUILD_DIR/component.pkg"
# 组件包不签名：Apple 只要求最终分发包携带 Developer ID Installer 签名，
# 中间产物签名对 CI 无益，反而多一次钥匙串取私钥的机会
pkgbuild \
    --root "$BUILD_DIR/payload" \
    --scripts "$SCRIPTS_DIR" \
    --identifier "$APP_BUNDLE_ID" \
    --version "$VERSION" \
    --install-location "/" \
    "$COMPONENT_PKG"

rm -f "$PKG_FINAL"
productbuild --package "$COMPONENT_PKG" "$PKG_FINAL"

echo "[OK] PKG 生成: $PKG_FINAL"
echo ""

# ============================================================
# Step 8: 签名 PKG
# ============================================================
echo "=== Step 8: 签名 PKG ==="

RCODESIGN="$(command -v rcodesign || true)"

# macOS 无 GNU timeout；用 perl alarm 做超时保护，避免 productsign 在无头
# 环境被钥匙串授权阻塞时把 CI 挂到 job 超时（曾有干等数小时的先例）
run_with_timeout() {
    local secs="$1"; shift
    perl -e 'alarm shift; exec @ARGV' "$secs" "$@"
}

sign_with_productsign() {
    local signed="$PKG_FINAL.signed"
    rm -f "$signed"
    local args=(--sign "$PKG_SIGN_ID")
    [ -n "$TEMP_KEYCHAIN" ] && args+=(--keychain "$TEMP_KEYCHAIN")
    run_with_timeout 300 productsign "${args[@]}" "$PKG_FINAL" "$signed"
    mv "$signed" "$PKG_FINAL"
}

if [ "$CI_MODE" = 1 ] && [ -n "$RCODESIGN" ]; then
    PW_FILE="$(mktemp)"
    printf '%s' "$INSTALLER_P12_PASSWORD" > "$PW_FILE"
    # --config-file /dev/null 意在短路默认配置加载；某些 runner 镜像上仍会读到
    # 一个含 version 键的 TOML 而报 UnknownField，故失败时收集诊断并回退
    if "$RCODESIGN" --config-file /dev/null sign \
         --p12-file "$P12_INSTALLER" --p12-password-file "$PW_FILE" "$PKG_FINAL"; then
        rm -f "$PW_FILE"
        echo "[OK] 已用 rcodesign 签名"
    else
        rm -f "$PW_FILE"
        echo "[WARN] rcodesign 签名失败，收集诊断信息："
        echo "--- HOME 下的 toml ---"
        find "$HOME" -maxdepth 4 -name "*.toml" 2>/dev/null | head -10 || true
        echo "--- 工作目录下的 toml ---"
        find . -maxdepth 3 -name "*.toml" 2>/dev/null | head -10 || true
        echo "--- XDG/CONFIG 环境变量 ---"
        env | grep -iE "^(XDG|.*CONFIG)" || echo "(无)"
        echo "[INFO] 回退到 productsign"
        sign_with_productsign
        echo "[OK] 已用 productsign 签名"
    fi
else
    sign_with_productsign
    echo "[OK] 已用 productsign 签名"
fi

pkgutil --check-signature "$PKG_FINAL" | head -5
echo ""

# ============================================================
# Step 9: 公证与钉票
# ============================================================
if [ "$NOTARIZE" = 1 ]; then
    echo "=== Step 9: 提交公证（约 2-5 分钟）==="

    if [ -n "$APPLE_ID" ]; then
        : "${APPLE_APP_PASSWORD:?需要设置 APPLE_APP_PASSWORD}"
        xcrun notarytool submit "$PKG_FINAL" \
            --apple-id "$APPLE_ID" \
            --password "$APPLE_APP_PASSWORD" \
            --team-id "$TEAM_ID" \
            --wait
    else
        xcrun notarytool submit "$PKG_FINAL" \
            --keychain-profile "$NOTARY_PROFILE" \
            --wait
    fi

    xcrun stapler staple "$PKG_FINAL"
    echo "[OK] 公证完成并已钉入票据"
    echo ""

    spctl --assess --type install "$PKG_FINAL" \
        && echo "[OK] Gatekeeper 验证通过" \
        || echo "[WARN] Gatekeeper 验证失败"
else
    echo "=== Step 9: 已跳过公证（--no-notarize）==="
fi
echo ""

# ============================================================
echo "==================================================="
echo "[SUCCESS] 构建完成!"
echo "==================================================="
echo "版本:   $VERSION"
echo "架构:   $BUILT_ARCH"
echo "文件:   $PKG_FINAL"
echo "大小:   $(du -sh "$PKG_FINAL" | cut -f1)"
echo ""
