#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
SuperStarOff CLI - Command Line Interface for Photoshop Integration

Usage:
    python superstaroff_cli.py input.tif output.tif --stride 256 --device auto
"""

import sys
import argparse
from pathlib import Path

# Windows 下 stdout 一旦被重定向（JSX 即以 > logFile 调用本程序），Python 会改用
# 系统 locale 编码（cp936/cp1252），输出中文即抛 UnicodeEncodeError 并令进程退出，
# 日志随之停在半截。chcp 65001 只影响控制台，对重定向无效，故在此强制 UTF-8。
if sys.platform == "win32":
    for _stream in (sys.stdout, sys.stderr):
        try:
            _stream.reconfigure(encoding="utf-8", errors="replace")
        except (AttributeError, ValueError):
            pass

# Import core module
from model_processor import StarRemover as SuperStarOff


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
    parser.add_argument('--progress-file', type=str, default=None,
                        help='进度文件路径，供 Photoshop 插件轮询使用')

    args = parser.parse_args()

    # 校验输入文件
    input_path = Path(args.input)
    if not input_path.exists():
        print(f"错误: 输入文件不存在: {input_path}", file=sys.stderr)
        sys.exit(1)

    # 校验输出目录
    output_path = Path(args.output)
    output_dir = output_path.parent
    if not output_dir.exists():
        print(f"错误: 输出目录不存在: {output_dir}", file=sys.stderr)
        sys.exit(1)

    try:
        if args.verbose:
            print(f"SuperStarOff - 命令行版本")
            print(f"输入: {input_path}")
            print(f"输出: {output_path}")
            print(f"步长: {args.stride}")
            print(f"设备: {args.device}")
            print("-" * 60)

        # 初始化模型
        print("正在初始化模型...")
        processor = SuperStarOff(
            stride=args.stride,
            device=args.device,
            progress_file=args.progress_file
        )

        # 处理图像
        print("正在处理图像...")
        processor.transform(
            input_path=str(input_path),
            output_path=str(output_path),
            stride=args.stride
        )

        print(f"完成！处理成功。")
        print(f"结果已保存至: {output_path}")

        sys.exit(0)

    except FileNotFoundError as e:
        print(f"错误: {e}", file=sys.stderr)
        print("\n请确保模型文件存在:", file=sys.stderr)
        print("  models/SuperStarOff2025.pt", file=sys.stderr)
        _write_error_progress(args.progress_file, str(e))
        sys.exit(1)

    except RuntimeError as e:
        error_msg = str(e)
        if "OpenSSL" in error_msg or "legacy" in error_msg:
            print("错误: OpenSSL 加密模块加载失败", file=sys.stderr)
            print("\n解决方案:", file=sys.stderr)
            print("1. 使用未加密的模型文件", file=sys.stderr)
            print("2. 或设置环境变量:", file=sys.stderr)
            print("   export CRYPTOGRAPHY_OPENSSL_NO_LEGACY=1", file=sys.stderr)
        else:
            print(f"运行时错误: {error_msg}", file=sys.stderr)
        _write_error_progress(args.progress_file, error_msg)
        sys.exit(1)

    except Exception as e:
        print(f"错误: {e}", file=sys.stderr)
        if args.verbose:
            import traceback
            traceback.print_exc()
        _write_error_progress(args.progress_file, str(e))
        sys.exit(1)


def _write_error_progress(progress_file, message):
    """向进度文件写入错误状态，让 JSX 能感知失败。"""
    if not progress_file:
        return
    import json
    try:
        with open(progress_file, 'w', encoding='utf-8') as f:
            json.dump({"phase": "error", "current": 0, "total": 100,
                       "message": message}, f)
    except Exception:
        pass


if __name__ == "__main__":
    main()