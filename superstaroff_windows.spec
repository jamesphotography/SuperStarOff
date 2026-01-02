# -*- mode: python ; coding: utf-8 -*-
# PyInstaller spec file for SuperStarOff (Windows)
# 慧眼去星 Windows 打包配置

import sys
from pathlib import Path

block_cipher = None

# Project path - UPDATE THIS to your Windows project location
PROJECT_ROOT = Path(r'C:\Users\jorda\PycharmProjects\SuperStarOff')

# ============================================================
# Analysis - 收集所有需要的文件和依赖
# ============================================================
a = Analysis(
    # 主入口点 - CLI 工具
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
        # PyTorch
        'torch',
        'torch._C',
        'torch.utils.data',
        'torchvision',
        'torchvision.transforms',
        'torchvision.transforms.functional',
        # 数据处理
        'numpy',
        'PIL',
        'PIL.Image',
        'tifffile',
        # 加密
        'cryptography',
        'cryptography.fernet',
        'cryptography.hazmat.primitives',
        'cryptography.hazmat.primitives.hashes',
        'cryptography.hazmat.primitives.kdf.pbkdf2',
        # 项目模块
        'model_processor',
        'core_utils',
    ],
    
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    
    excludes=[
        # 排除不需要的模块以减小文件大小
        'tkinter',
        'matplotlib',
        'scipy',
        'pandas',
        'IPython',
        'jupyter',
        'notebook',
        'pytest',
    ],
    
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

# ============================================================
# PYZ - 压缩 Python 字节码
# ============================================================
pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

# ============================================================
# EXE - 创建可执行文件
# ============================================================
exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name='superstaroff',  # 小写，与 Mac 版本一致
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=False,  # 禁用 UPX 压缩（可能导致问题）
    
    # 控制台应用程序（与 Mac 版本一致）
    console=True,
    
    disable_windowed_traceback=False,
    target_arch=None,
    
    # Windows 特定选项
    icon=None,  # 设置为 'resources/icon.ico' 如果有图标
    version=None,  # 设置为 'version_info.txt' 如果需要版本元数据
    uac_admin=False,  # CLI 工具不需要管理员权限
    uac_uiaccess=False,
)

# ============================================================
# COLLECT - 收集所有文件到发布目录
# ============================================================
coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=False,
    upx_exclude=[],
    name='superstaroff',  # 输出文件夹名称
)


# ============================================================
# 另外创建一个命令行版本（可选）
# ============================================================
# 如果你还需要一个纯命令行版本用于 Photoshop 调用
# 取消下面的注释

# a_cli = Analysis(
#     [str(PROJECT_ROOT / 'src' / 'superstaroff_cli.py')],
#     pathex=[str(PROJECT_ROOT / 'src')],
#     binaries=[],
#     datas=[
#         (str(PROJECT_ROOT / 'models' / 'SuperStarOff2025.pt'), 'models'),
#         (str(PROJECT_ROOT / 'src' / 'model_processor.py'), '.'),
#         (str(PROJECT_ROOT / 'src' / 'core_utils.py'), '.'),
#     ],
#     hiddenimports=[
#         'torch', 'torchvision', 'numpy', 'PIL', 'tifffile',
#         'cryptography', 'model_processor', 'core_utils',
#     ],
#     hookspath=[],
#     runtime_hooks=[],
#     excludes=['tkinter', 'matplotlib', 'scipy', 'pandas'],
#     cipher=block_cipher,
#     noarchive=False,
# )
# 
# pyz_cli = PYZ(a_cli.pure, a_cli.zipped_data, cipher=block_cipher)
# 
# exe_cli = EXE(
#     pyz_cli,
#     a_cli.scripts,
#     [],
#     exclude_binaries=True,
#     name='superstaroff',  # 命令行工具名称（小写）
#     debug=False,
#     strip=False,
#     upx=False,
#     console=True,  # True = 控制台应用程序
#     icon=None,
# )
# 
# coll_cli = COLLECT(
#     exe_cli,
#     a_cli.binaries,
#     a_cli.zipfiles,
#     a_cli.datas,
#     strip=False,
#     upx=False,
#     name='superstaroff_cli',
# )
