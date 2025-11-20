#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
SuperStarOff CLI - Command Line Interface for Photoshop Integration
慧眼去星命令行工具 - Photoshop集成版本

使用方法:
    python superstaroff_cli.py input.tif output.tif --stride 256 --device auto
"""

import sys
import argparse
from pathlib import Path

# 添加当前脚本所在目录到Python路径，确保可以找到superstaroff_core模块
sys.path.insert(0, str(Path(__file__).parent))

# 直接导入同目录下的核心模块
from superstaroff_core import SuperStarOff


def main():
    parser = argparse.ArgumentParser(
        description='SuperStarOff - 星点去除工具 (Photoshop集成版)',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  %(prog)s input.tif output.tif
  %(prog)s input.tif output.tif --stride 256 --device auto
  %(prog)s input.jpg output.jpg --stride 512 --device cpu
        """
    )

    parser.add_argument('input', type=str,
                        help='输入图片路径 (支持 TIF/TIFF/PNG/JPG)')
    parser.add_argument('output', type=str,
                        help='输出图片路径')
    parser.add_argument('--stride', type=int, default=256,
                        choices=[128, 256, 384, 512],
                        help='处理步长 (默认: 256, 越小质量越高但速度越慢)')
    parser.add_argument('--device', type=str, default='auto',
                        choices=['auto', 'cpu', 'mps', 'cuda'],
                        help='计算设备 (默认: auto 自动选择)')
    parser.add_argument('--verbose', '-v', action='store_true',
                        help='显示详细信息')

    args = parser.parse_args()

    # 验证输入文件
    input_path = Path(args.input)
    if not input_path.exists():
        print(f"错误: 输入文件不存在: {input_path}", file=sys.stderr)
        sys.exit(1)

    # 验证输出目录
    output_path = Path(args.output)
    output_dir = output_path.parent
    if not output_dir.exists():
        print(f"错误: 输出目录不存在: {output_dir}", file=sys.stderr)
        sys.exit(1)

    try:
        if args.verbose:
            print(f"慧眼去星 SuperStarOff - CLI版本")
            print(f"输入: {input_path}")
            print(f"输出: {output_path}")
            print(f"步长: {args.stride}")
            print(f"设备: {args.device}")
            print("-" * 60)

        # 初始化 SuperStarOff
        print("正在初始化模型...")
        processor = SuperStarOff(stride=args.stride, device=args.device)

        # 处理图片
        print("正在处理图片...")
        processor.transform(
            input_path=str(input_path),
            output_path=str(output_path),
            stride=args.stride
        )

        print(f"✓ 处理完成!")
        print(f"结果已保存到: {output_path}")

        sys.exit(0)

    except FileNotFoundError as e:
        print(f"错误: {e}", file=sys.stderr)
        print("\n请确保模型文件存在:", file=sys.stderr)
        print("  models/SuperStarOff2025.pt", file=sys.stderr)
        sys.exit(1)

    except RuntimeError as e:
        error_msg = str(e)
        if "OpenSSL" in error_msg or "legacy" in error_msg:
            print("错误: OpenSSL加密模块加载失败", file=sys.stderr)
            print("\n解决方案:", file=sys.stderr)
            print("1. 使用未加密的模型文件", file=sys.stderr)
            print("2. 或设置环境变量:", file=sys.stderr)
            print("   export CRYPTOGRAPHY_OPENSSL_NO_LEGACY=1", file=sys.stderr)
        else:
            print(f"运行时错误: {error_msg}", file=sys.stderr)
        sys.exit(1)

    except Exception as e:
        print(f"错误: {e}", file=sys.stderr)
        if args.verbose:
            import traceback
            traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
