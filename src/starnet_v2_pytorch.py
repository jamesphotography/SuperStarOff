#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
StarNet V2 - PyTorch Implementation

Uses TorchScript model for star removal
"""

import torch
import numpy as np
import tifffile as tiff
from PIL import Image
from pathlib import Path
import copy


class StarNetV2:
    """StarNet V2 using PyTorch TorchScript model"""
    
    def __init__(self, model_path=None, device='cpu', window_size=512, stride=256):
        """
        Initialize StarNet V2

        Args:
            model_path: Path to StarNet2_weights.pt file
            device: 'cpu', 'cuda', or 'mps' (for Apple Silicon)
            window_size: Model input size (fixed at 512 for V2)
            stride: Stride for tiling (default 256)
        """
        self.device = self._get_device(device)
        self.window_size = window_size  # Fixed at 512 for this model
        self.stride = stride

        # Default model path - try encrypted file first
        if model_path is None:
            current_dir = Path(__file__).parent
            encrypted_path = current_dir.parent / "models" / "SuperStarOff2025.pt"
            fallback_path = current_dir.parent / "models" / "StarNet2_weights.pt"

            # Prefer encrypted model
            if encrypted_path.exists():
                model_path = encrypted_path
                self.is_encrypted = True
            else:
                model_path = fallback_path
                self.is_encrypted = False
        else:
            # User specified path - check if it's encrypted by name
            model_path = Path(model_path)
            self.is_encrypted = "SuperStarOff2025" in str(model_path)

        self.model_path = Path(model_path)
        self.model = None
        
    def _get_device(self, device_preference):
        """Determine best available device"""
        if device_preference == 'auto':
            # Auto-select: MPS > CUDA > CPU
            if torch.backends.mps.is_available():
                print("Auto-selected MPS (Apple Silicon GPU)")
                return torch.device('mps')
            elif torch.cuda.is_available():
                print("Auto-selected CUDA (NVIDIA GPU)")
                return torch.device('cuda')
            else:
                print("Auto-selected CPU")
                return torch.device('cpu')
        elif device_preference == 'cuda' and torch.cuda.is_available():
            return torch.device('cuda')
        elif device_preference == 'mps' and torch.backends.mps.is_available():
            return torch.device('mps')
        else:
            return torch.device('cpu')
    
    def load_model(self):
        """Load TorchScript model (with decryption support)"""
        if not self.model_path.exists():
            raise FileNotFoundError(f"Model file not found: {self.model_path}")

        print(f"Loading model from {self.model_path.name}")

        if self.is_encrypted:
            # Load encrypted model
            print("Decrypting model...")
            try:
                from model_crypto import ModelCrypto

                # Decrypt to memory
                buffer = ModelCrypto.decrypt_to_memory(str(self.model_path))

                if buffer is None:
                    raise RuntimeError("Failed to decrypt model file")

                # Load model from memory buffer
                self.model = torch.jit.load(buffer, map_location=self.device)
                print("Model decrypted and loaded successfully")

            except ImportError as e:
                raise RuntimeError(f"Encryption module not available: {e}")
            except Exception as e:
                raise RuntimeError(f"Failed to load encrypted model: {e}")
        else:
            # Load unencrypted model
            self.model = torch.jit.load(str(self.model_path), map_location=self.device)

        self.model.eval()
        print(f"Model ready on {self.device}")
        
    def preprocess_image(self, image):
        """
        Preprocess image for model input
        
        Args:
            image: numpy array (H, W, C) with values in [0, 1]
        
        Returns:
            torch tensor (1, C, H, W)
        """
        # Convert to torch tensor and add batch dimension
        # Model expects: (batch, channels, height, width)
        tensor = torch.from_numpy(image).float()
        
        # Rearrange from (H, W, C) to (C, H, W)
        tensor = tensor.permute(2, 0, 1)
        
        # Add batch dimension
        tensor = tensor.unsqueeze(0)
        
        # Move to device
        tensor = tensor.to(self.device)
        
        return tensor
    
    def postprocess_output(self, output):
        """
        Postprocess model output
        
        Args:
            output: torch tensor (1, C, H, W)
        
        Returns:
            numpy array (H, W, C) with values in [0, 1]
        """
        # Remove batch dimension
        output = output.squeeze(0)
        
        # Move to CPU and convert to numpy
        output = output.cpu().detach().numpy()
        
        # Rearrange from (C, H, W) to (H, W, C)
        output = np.transpose(output, (1, 2, 0))
        
        # Clip to [0, 1]
        output = np.clip(output, 0, 1)
        
        return output
    
    def predict(self, image):
        """
        Run inference on image
        
        Args:
            image: numpy array (H, W, C) with values in [0, 1]
        
        Returns:
            starless image: numpy array (H, W, C) with values in [0, 1]
        """
        if self.model is None:
            self.load_model()
        
        # Preprocess
        input_tensor = self.preprocess_image(image)
        
        # Inference
        with torch.no_grad():
            output_tensor = self.model(input_tensor)
        
        # Postprocess
        output_image = self.postprocess_output(output_tensor)
        
        return output_image
    
    def transform(self, input_path, output_path, stride=None):
        """
        Transform image: remove stars using tiling

        Args:
            input_path: Input image file path
            output_path: Output image file path
            stride: Override default stride (optional)
        """
        if stride is not None:
            self.stride = stride

        # Load model if not already loaded
        if self.model is None:
            self.load_model()

        # Read image based on file format
        print(f"Loading image from {input_path}")
        input_path_lower = str(input_path).lower()

        if input_path_lower.endswith(('.tif', '.tiff')):
            # Load TIFF using tifffile
            data = tiff.imread(input_path)

            # Handle multi-layer TIFF
            if len(data.shape) > 3:
                print(f"TIFF has {data.shape[0]} layers, using first layer")
                data = data[0]
        else:
            # Load PNG/JPEG using PIL
            pil_image = Image.open(input_path)
            data = np.array(pil_image)

        # Determine input dtype
        input_dtype = data.dtype
        print(f"Input dtype: {input_dtype}, shape: {data.shape}")

        # Normalize to [0, 1]
        if input_dtype == np.uint16:
            image = (data / 65535.0).astype(np.float32)
        elif input_dtype == np.uint8:
            image = (data / 255.0).astype(np.float32)
        else:
            raise ValueError(f'Unknown image dtype: {input_dtype}')

        # Handle grayscale images
        if len(image.shape) == 2:
            image = np.stack([image] * 3, axis=-1)
            was_grayscale = True
        else:
            was_grayscale = False

        # Remove alpha channel if present
        if image.shape[2] == 4:
            print("Input image has 4 channels. Removing alpha channel")
            image = image[:, :, :3]

        # Process with tiling
        print(f"Processing with tiling (window={self.window_size}, stride={self.stride})...")
        starless = self._process_with_tiling(image)

        # Convert back to grayscale if input was grayscale
        if was_grayscale:
            starless = starless[:, :, 0]

        # Denormalize back to original dtype
        if input_dtype == np.uint8:
            output_data = (starless * 255).astype(np.uint8)
        else:
            output_data = (starless * 65535).astype(np.uint16)

        # Save result based on output format
        print(f"Saving result to {output_path}")
        output_path_lower = str(output_path).lower()

        if output_path_lower.endswith(('.tif', '.tiff')):
            # Save as TIFF
            tiff.imwrite(output_path, output_data)
        else:
            # Save as PNG/JPEG using PIL
            output_image = Image.fromarray(output_data)
            output_image.save(output_path)

        print("Done!")

    def _process_with_tiling(self, image):
        """Process large image with sliding window tiling"""
        h, w, c = image.shape
        offset = (self.window_size - self.stride) // 2

        # Calculate number of tiles
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

        # Process tiles
        print(f"Processing {ith}x{itw} = {ith*itw} tiles...")
        for i in range(ith):
            for j in range(itw):
                x = self.stride * i
                y = self.stride * j

                # Extract tile
                tile = padded[x:x+self.window_size, y:y+self.window_size, :]

                # Process tile
                tile_result = self.predict(tile)

                # Extract center region (avoid edge artifacts)
                tile_center = tile_result[offset:offset+self.stride, offset:offset+self.stride, :]

                # Write to output
                output[x+offset:self.stride*(i+1)+offset, y+offset:self.stride*(j+1)+offset, :] = tile_center

                if (i * itw + j + 1) % 10 == 0:
                    print(f"  Processed {i*itw+j+1}/{ith*itw} tiles")

        # Remove padding
        output = np.clip(output, 0, 1)
        output = output[offset:-(offset+dh), offset:-(offset+dw), :]

        return output


def test_starnet_v2():
    """Test function"""
    starnet = StarNetV2()
    starnet.load_model()
    
    # Test with dummy image
    test_img = np.random.rand(512, 512, 3).astype(np.float32)
    result = starnet.predict(test_img)
    
    print(f"Input shape: {test_img.shape}")
    print(f"Output shape: {result.shape}")
    print("Test passed!")


if __name__ == "__main__":
    test_starnet_v2()
