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

# Import core module
from model_processor import StarRemover as SuperStarOff


def main():
    parser = argparse.ArgumentParser(
        description='SuperStarOff - Star Removal Tool (Photoshop Integration)',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s input.tif output.tif
  %(prog)s input.tif output.tif --stride 256 --device auto
  %(prog)s input.jpg output.jpg --stride 512 --device cpu
        """
    )

    parser.add_argument('input', type=str,
                        help='Input image path (supports TIF/TIFF/PNG/JPG)')
    parser.add_argument('output', type=str,
                        help='Output image path')
    parser.add_argument('--stride', type=int, default=256,
                        choices=[128, 256, 384, 512],
                        help='Processing stride (default: 256, smaller = higher quality but slower)')
    parser.add_argument('--device', type=str, default='auto',
                        choices=['auto', 'cpu', 'mps', 'cuda'],
                        help='Compute device (default: auto)')
    parser.add_argument('--verbose', '-v', action='store_true',
                        help='Show detailed information')

    args = parser.parse_args()

    # Validate input file
    input_path = Path(args.input)
    if not input_path.exists():
        print(f"Error: Input file does not exist: {input_path}", file=sys.stderr)
        sys.exit(1)

    # Validate output directory
    output_path = Path(args.output)
    output_dir = output_path.parent
    if not output_dir.exists():
        print(f"Error: Output directory does not exist: {output_dir}", file=sys.stderr)
        sys.exit(1)

    try:
        if args.verbose:
            print(f"SuperStarOff - CLI Version")
            print(f"Input: {input_path}")
            print(f"Output: {output_path}")
            print(f"Stride: {args.stride}")
            print(f"Device: {args.device}")
            print("-" * 60)

        # Initialize SuperStarOff
        print("Initializing model...")
        processor = SuperStarOff(stride=args.stride, device=args.device)

        # Process image
        print("Processing image...")
        processor.transform(
            input_path=str(input_path),
            output_path=str(output_path),
            stride=args.stride
        )

        print(f"Done! Processing complete.")
        print(f"Result saved to: {output_path}")

        sys.exit(0)

    except FileNotFoundError as e:
        print(f"Error: {e}", file=sys.stderr)
        print("\nPlease ensure model file exists:", file=sys.stderr)
        print("  models/SuperStarOff2025.pt", file=sys.stderr)
        sys.exit(1)

    except RuntimeError as e:
        error_msg = str(e)
        if "OpenSSL" in error_msg or "legacy" in error_msg:
            print("Error: OpenSSL encryption module failed to load", file=sys.stderr)
            print("\nSolutions:", file=sys.stderr)
            print("1. Use unencrypted model file", file=sys.stderr)
            print("2. Or set environment variable:", file=sys.stderr)
            print("   export CRYPTOGRAPHY_OPENSSL_NO_LEGACY=1", file=sys.stderr)
        else:
            print(f"Runtime error: {error_msg}", file=sys.stderr)
        sys.exit(1)

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        if args.verbose:
            import traceback
            traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()