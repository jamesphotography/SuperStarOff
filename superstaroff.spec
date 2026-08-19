# -*- mode: python ; coding: utf-8 -*-
from PyInstaller.utils.hooks import collect_submodules
# PyInstaller spec file for SuperStarOff

import os
import sys
from pathlib import Path

block_cipher = None

# 项目路径：始终基于当前 spec 文件所在目录，避免写死本机路径
PROJECT_ROOT = Path(globals().get("SPEC", "superstaroff.spec")).resolve().parent

# 本地打包默认不要求签名；如需签名，可在命令前设置环境变量：
# export SUPERSTAROFF_CODESIGN_IDENTITY="Developer ID Application: ..."
CODESIGN_IDENTITY = os.environ.get("SUPERSTAROFF_CODESIGN_IDENTITY") or None

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
        'numpy',
        'PIL',
        'PIL.Image',
        'tifffile',
        'cryptography',
        'imagecodecs',
        'model_processor',
        'core_utils',
        # torch._library.infer_schema (2.2+) 需要 distributed_c10d
        'torch.distributed.distributed_c10d',
        # torch/_jit_internal.py → rpc → server_process_global_profiler
        # → torch.autograd.gradcheck → torch.testing 整条依赖链
        'torch.distributed.rpc',
        'torch.distributed.rpc.server_process_global_profiler',
        'torch.autograd.gradcheck',
        'torch.testing',
        'torch.testing._comparison',
    # 逐个列出 hiddenimports 不足以让 PyInstaller 收全 torch.distributed：
    # 打包产物运行时仍报 No module named 'torch.distributed.rpc'。
    # torch/nn/__init__.py 在 import 阶段即会走到这条链，缺失即启动失败。
    ] + collect_submodules('torch.distributed'),
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[
        # UI / notebook
        'tkinter',
        'IPython',
        'jupyter',
        'notebook',
        # 数据分析（不需要）
        'matplotlib',
        'scipy',
        'pandas',
        'sklearn',
        'sklearn',
        'pyarrow',
        'polars',
        'numba',
        'llvmlite',
        'altair',
        'streamlit',
        # 深度学习框架（仅用 torch，排除其余）
        'tensorflow',
        'tensorflow_core',
        'tf2onnx',
        'onnxruntime',
        'onnx',
        'transformers',
        'diffusers',
        'timm',
        'tokenizers',
        'accelerate',
        'peft',
        # torchvision：源码未使用，排除
        'torchvision',
        # 不再裁剪 torch 内部分布式/编译子模块。
        # PyTorch 2.6 在 import torch 期间会动态走到这些模块；
        # 精确排除会导致干净安装包在启动阶段出现“补一个缺一个”的缺模块错误。
        # 计算机视觉（不需要）
        'cv2',
        # Google / Cloud API（不需要）
        'googleapiclient',
        'google',
        'grpc',
        'googleapis_common_protos',
        # 音视频（不需要）
        'librosa',
        'soundfile',
        'h5py',
        'lxml',
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
    codesign_identity=CODESIGN_IDENTITY,
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
