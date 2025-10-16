# -*- mode: python ; coding: utf-8 -*-
from PyInstaller.utils.hooks import collect_dynamic_libs, collect_submodules

block_cipher = None

# 收集所有需要的数据文件
datas = [
    ('models/SuperStarOff2025.pt', 'models'),
    ('resources/styles/dark_theme.qss', 'resources/styles'),
    ('resources/icons/icon.jpg', 'resources/icons'),
    ('resources/icons/icon.icns', 'resources/icons'),
    ('resources/icons/icon.png', 'resources/icons'),
    ('examples/海豚星云-Sh2-308-S-4天数据.jpg', 'examples'),
    ('examples/海豚星云-Sh2-308-S-4天数据_starless_stride256.jpg', 'examples'),
]

# 收集imagecodecs的所有二进制文件
imagecodecs_binaries = collect_dynamic_libs('imagecodecs')

# 收集所有需要的隐藏导入
hiddenimports = [
    'PyQt6.QtCore',
    'PyQt6.QtGui',
    'PyQt6.QtWidgets',
    'torch',
    'torchvision',
    'numpy',
    'PIL',
    'PIL.Image',
    'PIL.ImageFile',
    'tifffile',
    'imagecodecs',
    'imagecodecs._shared',
    'imagecodecs._imcd',
    'cryptography',
    'cryptography.fernet',
    'cryptography.hazmat',
    'cryptography.hazmat.primitives',
    'cryptography.hazmat.primitives.kdf',
    'cryptography.hazmat.primitives.kdf.pbkdf2',
    'cryptography.hazmat.backends',
]

# 添加imagecodecs的所有子模块
hiddenimports += collect_submodules('imagecodecs')

a = Analysis(
    ['src/app.py'],
    pathex=[],
    binaries=imagecodecs_binaries,
    datas=datas,
    hiddenimports=hiddenimports,
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[
        'matplotlib',
        'IPython',
        'jupyter',
        'notebook',
    ],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name='SuperStarOff',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon='resources/icons/icon.icns',
)

coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=True,
    upx_exclude=[],
    name='SuperStarOff',
)

app = BUNDLE(
    coll,
    name='慧眼去星V1.app',
    icon='resources/icons/icon.icns',
    bundle_identifier='com.superstaroff.app',
    info_plist={
        'NSPrincipalClass': 'NSApplication',
        'NSHighResolutionCapable': 'True',
        'CFBundleName': '慧眼去星V1',
        'CFBundleDisplayName': '慧眼去星V1',
        'CFBundleShortVersionString': '1.0',
        'CFBundleVersion': '1.0.0',
        'CFBundleIdentifier': 'com.superstaroff.app',
        'LSMinimumSystemVersion': '11.0',
        'NSRequiresAquaSystemAppearance': False,
    },
)
