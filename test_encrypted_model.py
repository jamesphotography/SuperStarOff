#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Test Encrypted Model Loading
测试加密模型加载
"""

import sys
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent / "src"))

from model_processor import StarNetV2
import numpy as np


def test_encrypted_model():
    """测试加密模型加载和推理"""

    print("=" * 60)
    print("测试加密模型加载")
    print("=" * 60)

    try:
        # 初始化模型（会自动使用加密文件）
        print("\n1. 初始化模型...")
        starnet = StarNetV2(device='cpu', stride=256)

        print(f"   模型路径: {starnet.model_path}")
        print(f"   是否加密: {starnet.is_encrypted}")

        # 加载模型
        print("\n2. 加载模型...")
        starnet.load_model()

        print("   ✓ 模型加载成功!")

        # 测试推理
        print("\n3. 测试推理...")
        test_image = np.random.rand(512, 512, 3).astype(np.float32)
        result = starnet.predict(test_image)

        print(f"   输入形状: {test_image.shape}")
        print(f"   输出形状: {result.shape}")
        print(f"   输出范围: [{result.min():.3f}, {result.max():.3f}]")
        print("   ✓ 推理成功!")

        print("\n" + "=" * 60)
        print("✓ 所有测试通过!")
        print("=" * 60)

        return True

    except Exception as e:
        print(f"\n❌ 测试失败: {e}")
        import traceback
        traceback.print_exc()
        return False


if __name__ == "__main__":
    success = test_encrypted_model()
    sys.exit(0 if success else 1)
