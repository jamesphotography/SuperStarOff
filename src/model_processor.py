#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
SuperStarOff - Star Removal Core Module
Using PyTorch TorchScript

Supports:
- 16-bit / 8-bit TIFF, PNG, JPG
- Apple Silicon MPS / NVIDIA CUDA / CPU
- ICC color profile preservation
- Windows / macOS / Linux cross-platform
"""

import os
import sys
import torch
import numpy as np
import tifffile as tiff
from PIL import Image
from pathlib import Path
import copy


class StarRemover:
    """Star Removal Processor - Core Class"""

    def __init__(self, model_path=None, device='auto', stride=256, window_size=512):
        """
        Initialize

        Args:
            model_path: Model file path (auto-find by default)
            device: 'auto', 'cpu', 'mps' or 'cuda'
            stride: Processing stride (default 256)
            window_size: Window size (default 512, fixed)
        """
        self.device = self._get_device(device)
        self.window_size = window_size
        self.stride = stride
        self.model_path = self._find_model(model_path)
        self.model = None

    def _get_install_directories(self):
        """Get platform-specific installation directories"""
        dirs = []

        if sys.platform == "win32":
            # Windows installation directories
            program_files = os.environ.get("PROGRAMFILES", "C:\\Program Files")
            program_files_x86 = os.environ.get("PROGRAMFILES(X86)", "C:\\Program Files (x86)")
            local_appdata = os.environ.get("LOCALAPPDATA", "")

            dirs.append(Path(program_files_x86) / "SuperStarOff")
            dirs.append(Path(program_files) / "SuperStarOff")
            if local_appdata:
                dirs.append(Path(local_appdata) / "SuperStarOff")
            dirs.append(Path("C:\\SuperStarOff"))
        elif sys.platform == "darwin":
            # macOS installation directories
            dirs.append(Path("/usr/local/SuperStarOff"))
            dirs.append(Path.home() / "Library" / "Application Support" / "SuperStarOff")
        else:
            # Linux installation directories
            dirs.append(Path("/usr/local/SuperStarOff"))
            dirs.append(Path.home() / ".local" / "share" / "SuperStarOff")

        return dirs

    def _find_model(self, model_path):
        """Find model file"""
        if model_path is not None:
            path = Path(model_path)
            if path.exists():
                return path
            raise FileNotFoundError(f"Model file not found: {model_path}")

        # Auto-find model
        if getattr(sys, 'frozen', False):
            # PyInstaller packaged
            base_path = Path(sys._MEIPASS)
            model_file = base_path / "models" / "SuperStarOff2025.pt"
            if model_file.exists():
                return model_file

        # Development environment
        current_dir = Path(__file__).parent

        # Try multiple path structures
        possible_bases = [
            current_dir.parent,  # src/../models
            current_dir,  # src/models (unlikely)
        ]

        # Add platform-specific installation directories
        possible_bases.extend(self._get_install_directories())

        for base in possible_bases:
            model_file = base / "models" / "SuperStarOff2025.pt"
            if model_file.exists():
                return model_file

        # Default path (for error message)
        default_path = current_dir.parent / "models" / "SuperStarOff2025.pt"
        raise FileNotFoundError(f"Model file not found: {default_path}")

    def _get_device(self, device_preference):
        """Select best compute device"""
        if device_preference == 'auto':
            if torch.backends.mps.is_available():
                print("Using Apple Silicon GPU (MPS)")
                return torch.device('mps')
            elif torch.cuda.is_available():
                print("Using NVIDIA GPU (CUDA)")
                return torch.device('cuda')
            else:
                print("Using CPU")
                return torch.device('cpu')
        elif device_preference == 'cuda' and torch.cuda.is_available():
            return torch.device('cuda')
        elif device_preference == 'mps' and torch.backends.mps.is_available():
            return torch.device('mps')
        else:
            return torch.device('cpu')

    def load_model(self):
        """Load model (supports encrypted models)"""
        if not self.model_path.exists():
            raise FileNotFoundError(f"Model file not found: {self.model_path}")

        print(f"Loading model: {self.model_path.name}")

        # Try decryption loading
        try:
            from core_utils import ModelCrypto

            print("Decrypting model...")
            buffer = ModelCrypto.decrypt_to_memory(str(self.model_path))

            if buffer is None:
                raise RuntimeError("Model decryption failed")

            self.model = torch.jit.load(buffer, map_location=self.device)
            print("Model loaded successfully")

        except ImportError:
            # No encryption module, try direct loading (for unencrypted models)
            print("Warning: Encryption module not available, trying direct load")
            self.model = torch.jit.load(str(self.model_path), map_location=self.device)
        except Exception as e:
            raise RuntimeError(f"Model loading failed: {e}")

        self.model.eval()
        print(f"Model ready (device: {self.device})")

    def predict(self, image):
        """
        Process single image tile

        Args:
            image: numpy array (H, W, C), range [0, 1]

        Returns:
            Starless image: numpy array (H, W, C), range [0, 1]
        """
        if self.model is None:
            self.load_model()

        # Convert to tensor: (H, W, C) -> (1, C, H, W)
        tensor = torch.from_numpy(image).float()
        tensor = tensor.permute(2, 0, 1).unsqueeze(0).to(self.device)

        # Inference
        with torch.no_grad():
            output = self.model(tensor)

        # Convert back to numpy: (1, C, H, W) -> (H, W, C)
        output = output.squeeze(0).cpu().detach().numpy()
        output = np.transpose(output, (1, 2, 0))
        output = np.clip(output, 0, 1)

        return output

    def transform(self, input_path, output_path, stride=None):
        """
        Process image file

        Args:
            input_path: Input image path
            output_path: Output image path
            stride: Processing stride (optional, overrides default)
        """
        if stride is not None:
            self.stride = stride

        if self.model is None:
            self.load_model()

        # Load image
        image, input_dtype, color_profile, was_grayscale = self._load_image(input_path)

        # Tiled processing
        print(f"Processing (window={self.window_size}, stride={self.stride})...")
        starless = self._process_with_tiling(image)

        # Restore grayscale
        if was_grayscale:
            starless = starless[:, :, 0]

        # Save result
        self._save_image(output_path, starless, input_dtype, color_profile)
        print("Done!")

    def _load_image(self, input_path):
        """Load image, returns (image, dtype, color_profile, was_grayscale)"""
        print(f"Loading image: {input_path}")
        input_path_lower = str(input_path).lower()
        color_profile = None

        if input_path_lower.endswith(('.tif', '.tiff')):
            data = tiff.imread(input_path)

            # Handle multi-layer TIFF
            if len(data.shape) > 3:
                print(f"TIFF has {data.shape[0]} layers, using first layer")
                data = data[0]

            # Extract ICC profile
            try:
                pil_image = Image.open(input_path)
                color_profile = pil_image.info.get('icc_profile')
                if color_profile:
                    print(f"Detected embedded ICC color profile ({len(color_profile)} bytes)")
            except:
                pass
        else:
            pil_image = Image.open(input_path)
            color_profile = pil_image.info.get('icc_profile')
            if color_profile:
                print(f"Detected embedded ICC color profile ({len(color_profile)} bytes)")
            data = np.array(pil_image)

        input_dtype = data.dtype
        print(f"Input format: {input_dtype}, size: {data.shape}")

        # Normalize to [0, 1]
        if input_dtype == np.uint16:
            image = (data / 65535.0).astype(np.float32)
        elif input_dtype == np.uint8:
            image = (data / 255.0).astype(np.float32)
        else:
            raise ValueError(f'Unsupported image format: {input_dtype}')

        # Handle grayscale
        was_grayscale = False
        if len(image.shape) == 2:
            image = np.stack([image] * 3, axis=-1)
            was_grayscale = True

        # Remove alpha channel
        if image.shape[2] == 4:
            print("Removing alpha channel")
            image = image[:, :, :3]

        return image, input_dtype, color_profile, was_grayscale

    def _save_image(self, output_path, starless, input_dtype, color_profile):
        """Save processed image"""
        print(f"Saving result: {output_path}")
        output_path_lower = str(output_path).lower()

        # Denormalize
        if input_dtype == np.uint8:
            output_data = (starless * 255).astype(np.uint8)
        else:
            output_data = (starless * 65535).astype(np.uint16)

        if output_path_lower.endswith(('.tif', '.tiff')):
            if input_dtype == np.uint16:
                # 16-bit TIFF using tifffile
                tiff.imwrite(output_path, output_data, photometric='rgb')
                # Try to embed ICC profile
                if color_profile:
                    print("Embedding original ICC color profile")
                    try:
                        img = Image.open(output_path)
                        img.save(output_path, 'TIFF', icc_profile=color_profile, compression='none')
                    except:
                        pass
            else:
                # 8-bit TIFF
                output_image = Image.fromarray(output_data)
                if color_profile:
                    print("Embedding original ICC color profile")
                    output_image.save(output_path, 'TIFF', icc_profile=color_profile, compression='none')
                else:
                    tiff.imwrite(output_path, output_data)
        else:
            # PNG/JPEG
            output_image = Image.fromarray(output_data)
            if color_profile:
                print("Embedding original ICC color profile")
                output_image.save(output_path, icc_profile=color_profile)
            else:
                output_image.save(output_path)

    def _process_with_tiling(self, image):
        """Process large image using sliding window"""
        h, w, c = image.shape
        offset = (self.window_size - self.stride) // 2

        # Calculate tile count
        ith = int(h / self.stride) + 1
        itw = int(w / self.stride) + 1

        # Pad image
        dh = ith * self.stride - h
        dw = itw * self.stride - w

        padded = np.concatenate((image, image[(h - dh):, :, :]), axis=0)
        padded = np.concatenate((padded, padded[:, (w - dw):, :]), axis=1)

        h_pad, w_pad, _ = padded.shape
        padded = np.concatenate((padded, padded[(h_pad - offset):, :, :]), axis=0)
        padded = np.concatenate((padded[:offset, :, :], padded), axis=0)
        padded = np.concatenate((padded, padded[:, (w_pad - offset):, :]), axis=1)
        padded = np.concatenate((padded[:, :offset, :], padded), axis=1)

        # Initialize output
        output = copy.deepcopy(padded)

        # Process each tile
        total_tiles = ith * itw
        print(f"Total {ith}x{itw} = {total_tiles} tiles...")

        for i in range(ith):
            for j in range(itw):
                x = self.stride * i
                y = self.stride * j

                # Extract tile
                tile = padded[x:x + self.window_size, y:y + self.window_size, :]

                # Process tile
                tile_result = self.predict(tile)

                # Extract center region (avoid edge artifacts)
                tile_center = tile_result[offset:offset + self.stride, offset:offset + self.stride, :]

                # Write to output
                output[x + offset:self.stride * (i + 1) + offset, y + offset:self.stride * (
                            j + 1) + offset, :] = tile_center

                current = i * itw + j + 1
                if current % 10 == 0:
                    print(f"  Processed {current}/{total_tiles} tiles")

        # Remove padding
        output = np.clip(output, 0, 1)
        output = output[offset:-(offset + dh), offset:-(offset + dw), :]

        return output


# Backward compatible aliases
StarNetV2 = StarRemover
SuperStarOff = StarRemover


def test():
    """Test function"""
    processor = StarRemover()
    processor.load_model()

    # Test random image
    test_img = np.random.rand(512, 512, 3).astype(np.float32)
    result = processor.predict(test_img)

    print(f"Input size: {test_img.shape}")
    print(f"Output size: {result.shape}")
    print("Test passed!")


if __name__ == "__main__":
    test()