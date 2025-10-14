#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Model Encryption Script
用于加密模型权重文件
"""

import sys
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent / "src"))

from model_crypto import ModelCrypto


def main():
    """加密模型文件"""

    # 文件路径
    project_root = Path(__file__).parent
    input_file = project_root / "models" / "StarNet2_weights.pt"
    output_file = project_root / "models" / "SuperStarOff2025.pt"

    # 检查输入文件是否存在
    if not input_file.exists():
        print(f"❌ 错误: 找不到输入文件: {input_file}")
        sys.exit(1)

    print("=" * 60)
    print("慧眼去星 - 模型文件加密工具")
    print("=" * 60)
    print(f"\n输入文件: {input_file}")
    print(f"输出文件: {output_file}")
    print()

    # 确认加密
    response = input("确认加密? (yes/no): ")
    if response.lower() != "yes":
        print("已取消")
        sys.exit(0)

    # 执行加密
    print("\n开始加密...")
    if ModelCrypto.encrypt_file(str(input_file), str(output_file)):
        print("\n" + "=" * 60)
        print("✓ 加密成功!")
        print("=" * 60)
        print(f"\n加密文件已保存: {output_file}")
        print(f"\n提示:")
        print(f"  1. 加密文件: {output_file.name}")
        print(f"  2. 原始文件: {input_file.name} (可以删除或备份)")
        print(f"  3. 应用将自动使用加密文件")
        print()
    else:
        print("\n❌ 加密失败!")
        sys.exit(1)


if __name__ == "__main__":
    main()
