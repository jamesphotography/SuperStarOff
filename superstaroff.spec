# -*- mode: python ; coding: utf-8 -*-
# PyInstaller spec file for SuperStarOff

import sys
from pathlib import Path

block_cipher = None

# 项目路径
PROJECT_ROOT = Path('/Users/jameszhenyu/PycharmProjects/SuperStarOff')

a = Analysis(
    [str(PROJECT_ROOT / 'src' / 'superstaroff_cli.py')],
    pathex=[str(PROJECT_ROOT / 'src')],
    binaries=[],
    datas=[
        # 包含模型文件
        (str(PROJECT_ROOT / 'models' / 'SuperStarOff2025.pt'), 'models'),
        # 包含核心模块
        (str(PROJECT_ROOT / 'src' / 'model_processor.py'), '.'),
        (str(PROJECT_ROOT / 'src' / 'core_utils.py'), '.'),
    ],
    hiddenimports=[
        'torch',
        'torchvision',
        'torchvision.transforms',
        'torchvision.transforms.functional',
        'numpy',
        'PIL',
        'PIL.Image',
        'tifffile',
        'cryptography',
        'model_processor',
        'core_utils',
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[
        'tkinter',
        'matplotlib',
        'scipy',
        'pandas',
        'IPython',
        'jupyter',
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
    name='superstaroff',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=False,
    console=True,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity='Developer ID Application: James Zhen Yu (JWR6FDB52H)',
    entitlements_file=None,
)

coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=False,
    upx_exclude=[],
    name='superstaroff',
)
