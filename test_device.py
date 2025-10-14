#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Test Device Selection
测试设备选择
"""

import sys
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent / "src"))

from starnet_v2_pytorch import StarNetV2
import torch


def test_device():
    """测试设备选择"""

    print("=" * 60)
    print("设备检测")
    print("=" * 60)

    # 检查 MPS 可用性
    print(f"\nMPS 可用: {torch.backends.mps.is_available()}")
    print(f"CUDA 可用: {torch.cuda.is_available()}")

    # 测试不同设备设置
    print("\n" + "=" * 60)
    print("测试 device='auto'")
    print("=" * 60)
    starnet_auto = StarNetV2(device='auto', stride=256)
    print(f"选择的设备: {starnet_auto.device}")

    print("\n" + "=" * 60)
    print("测试 device='mps'")
    print("=" * 60)
    starnet_mps = StarNetV2(device='mps', stride=256)
    print(f"选择的设备: {starnet_mps.device}")

    print("\n" + "=" * 60)
    print("测试 device='cpu'")
    print("=" * 60)
    starnet_cpu = StarNetV2(device='cpu', stride=256)
    print(f"选择的设备: {starnet_cpu.device}")

    # 加载模型并检查
    print("\n" + "=" * 60)
    print("加载模型到 MPS")
    print("=" * 60)
    starnet_mps.load_model()

    print("\n模型设备信息:")
    print(f"  starnet_v2_pytorch 设备: {starnet_mps.device}")
    print(f"  模型是否加密: {starnet_mps.is_encrypted}")


if __name__ == "__main__":
    test_device()
