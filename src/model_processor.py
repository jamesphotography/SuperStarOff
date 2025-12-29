#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
SuperStarOff - 星点去除核心模块
Star Removal Core Module using PyTorch TorchScript

支持:
- 16-bit / 8-bit TIFF, PNG, JPG
- Apple Silicon MPS / NVIDIA CUDA / CPU
- ICC 色彩配置文件保留
"""

import sys
import torch
import numpy as np
import tifffile as tiff
from PIL import Image
from pathlib import Path
import copy


class StarRemover:
    """星点去除处理器 - 核心类"""

    def __init__(self, model_path=None, device='auto', stride=256, window_size=512):
        """
        初始化

        Args:
            model_path: 模型文件路径（默认自动查找）
            device: 'auto', 'cpu', 'mps' 或 'cuda'
            stride: 处理步长（默认 256）
            window_size: 窗口大小（默认 512，固定值）
        """
        self.device = self._get_device(device)
        self.window_size = window_size
        self.stride = stride
        self.model_path = self._find_model(model_path)
        self.model = None

    def _find_model(self, model_path):
        """查找模型文件"""
        if model_path is not None:
            path = Path(model_path)
            if path.exists():
                return path
            raise FileNotFoundError(f"模型文件未找到: {model_path}")

        # 自动查找模型
        if getattr(sys, 'frozen', False):
            # PyInstaller 打包后
            base_path = Path(sys._MEIPASS)
        else:
            # 开发环境
            current_dir = Path(__file__).parent

            # 尝试多种路径结构
            possible_bases = [
                current_dir.parent,                    # src/../models
                current_dir,                           # src/models (不太可能)
                Path("/usr/local/SuperStarOff"),       # 安装目录
            ]

            for base in possible_bases:
                model_file = base / "models" / "SuperStarOff2025.pt"
                if model_file.exists():
                    return model_file

            # 默认路径
            base_path = current_dir.parent

        model_file = base_path / "models" / "SuperStarOff2025.pt"
        if not model_file.exists():
            raise FileNotFoundError(f"模型文件未找到: {model_file}")
        return model_file

    def _get_device(self, device_preference):
        """选择最佳计算设备"""
        if device_preference == 'auto':
            if torch.backends.mps.is_available():
                print("使用 Apple Silicon GPU (MPS)")
                return torch.device('mps')
            elif torch.cuda.is_available():
                print("使用 NVIDIA GPU (CUDA)")
                return torch.device('cuda')
            else:
                print("使用 CPU")
                return torch.device('cpu')
        elif device_preference == 'cuda' and torch.cuda.is_available():
            return torch.device('cuda')
        elif device_preference == 'mps' and torch.backends.mps.is_available():
            return torch.device('mps')
        else:
            return torch.device('cpu')

    def load_model(self):
        """加载模型（支持加密模型）"""
        if not self.model_path.exists():
            raise FileNotFoundError(f"模型文件未找到: {self.model_path}")

        print(f"正在加载模型: {self.model_path.name}")

        # 尝试解密加载
        try:
            from core_utils import ModelCrypto

            print("正在解密模型...")
            buffer = ModelCrypto.decrypt_to_memory(str(self.model_path))

            if buffer is None:
                raise RuntimeError("模型解密失败")

            self.model = torch.jit.load(buffer, map_location=self.device)
            print("模型加载成功")

        except ImportError:
            # 没有加密模块，尝试直接加载（用于未加密模型）
            print("警告: 加密模块不可用，尝试直接加载模型")
            self.model = torch.jit.load(str(self.model_path), map_location=self.device)
        except Exception as e:
            raise RuntimeError(f"模型加载失败: {e}")

        self.model.eval()
        print(f"模型已就绪 (设备: {self.device})")

    def predict(self, image):
        """
        处理单个图像块

        Args:
            image: numpy 数组 (H, W, C)，值域 [0, 1]

        Returns:
            去星后的图片: numpy 数组 (H, W, C)，值域 [0, 1]
        """
        if self.model is None:
            self.load_model()

        # 转换为 tensor: (H, W, C) -> (1, C, H, W)
        tensor = torch.from_numpy(image).float()
        tensor = tensor.permute(2, 0, 1).unsqueeze(0).to(self.device)

        # 推理
        with torch.no_grad():
            output = self.model(tensor)

        # 转换回 numpy: (1, C, H, W) -> (H, W, C)
        output = output.squeeze(0).cpu().detach().numpy()
        output = np.transpose(output, (1, 2, 0))
        output = np.clip(output, 0, 1)

        return output

    def transform(self, input_path, output_path, stride=None):
        """
        处理图片文件

        Args:
            input_path: 输入图片路径
            output_path: 输出图片路径
            stride: 处理步长（可选，覆盖默认值）
        """
        if stride is not None:
            self.stride = stride

        if self.model is None:
            self.load_model()

        # 读取图片
        image, input_dtype, color_profile, was_grayscale = self._load_image(input_path)

        # 分块处理
        print(f"正在处理 (窗口={self.window_size}, 步长={self.stride})...")
        starless = self._process_with_tiling(image)

        # 恢复灰度图
        if was_grayscale:
            starless = starless[:, :, 0]

        # 保存结果
        self._save_image(output_path, starless, input_dtype, color_profile)
        print("完成!")

    def _load_image(self, input_path):
        """加载图片，返回 (image, dtype, color_profile, was_grayscale)"""
        print(f"正在加载图片: {input_path}")
        input_path_lower = str(input_path).lower()
        color_profile = None

        if input_path_lower.endswith(('.tif', '.tiff')):
            data = tiff.imread(input_path)

            # 处理多层 TIFF
            if len(data.shape) > 3:
                print(f"TIFF 有 {data.shape[0]} 层，使用第一层")
                data = data[0]

            # 提取 ICC profile
            try:
                pil_image = Image.open(input_path)
                color_profile = pil_image.info.get('icc_profile')
                if color_profile:
                    print(f"检测到嵌入的ICC色彩配置文件 ({len(color_profile)} bytes)")
            except:
                pass
        else:
            pil_image = Image.open(input_path)
            color_profile = pil_image.info.get('icc_profile')
            if color_profile:
                print(f"检测到嵌入的ICC色彩配置文件 ({len(color_profile)} bytes)")
            data = np.array(pil_image)

        input_dtype = data.dtype
        print(f"输入格式: {input_dtype}, 尺寸: {data.shape}")

        # 归一化到 [0, 1]
        if input_dtype == np.uint16:
            image = (data / 65535.0).astype(np.float32)
        elif input_dtype == np.uint8:
            image = (data / 255.0).astype(np.float32)
        else:
            raise ValueError(f'不支持的图片格式: {input_dtype}')

        # 处理灰度图
        was_grayscale = False
        if len(image.shape) == 2:
            image = np.stack([image] * 3, axis=-1)
            was_grayscale = True

        # 移除 alpha 通道
        if image.shape[2] == 4:
            print("移除 alpha 通道")
            image = image[:, :, :3]

        return image, input_dtype, color_profile, was_grayscale

    def _save_image(self, output_path, starless, input_dtype, color_profile):
        """保存处理后的图片"""
        print(f"正在保存结果: {output_path}")
        output_path_lower = str(output_path).lower()

        # 反归一化
        if input_dtype == np.uint8:
            output_data = (starless * 255).astype(np.uint8)
        else:
            output_data = (starless * 65535).astype(np.uint16)

        if output_path_lower.endswith(('.tif', '.tiff')):
            if input_dtype == np.uint16:
                # 16-bit TIFF 使用 tifffile 保存
                tiff.imwrite(output_path, output_data, photometric='rgb')
                # 尝试嵌入 ICC profile
                if color_profile:
                    print("嵌入原始ICC色彩配置文件")
                    try:
                        img = Image.open(output_path)
                        img.save(output_path, 'TIFF', icc_profile=color_profile, compression='none')
                    except:
                        pass
            else:
                # 8-bit TIFF
                output_image = Image.fromarray(output_data)
                if color_profile:
                    print("嵌入原始ICC色彩配置文件")
                    output_image.save(output_path, 'TIFF', icc_profile=color_profile, compression='none')
                else:
                    tiff.imwrite(output_path, output_data)
        else:
            # PNG/JPEG
            output_image = Image.fromarray(output_data)
            if color_profile:
                print("嵌入原始ICC色彩配置文件")
                output_image.save(output_path, icc_profile=color_profile)
            else:
                output_image.save(output_path)

    def _process_with_tiling(self, image):
        """使用滑动窗口分块处理大图"""
        h, w, c = image.shape
        offset = (self.window_size - self.stride) // 2

        # 计算分块数量
        ith = int(h / self.stride) + 1
        itw = int(w / self.stride) + 1

        # 填充图片
        dh = ith * self.stride - h
        dw = itw * self.stride - w

        padded = np.concatenate((image, image[(h - dh):, :, :]), axis=0)
        padded = np.concatenate((padded, padded[:, (w - dw):, :]), axis=1)

        h_pad, w_pad, _ = padded.shape
        padded = np.concatenate((padded, padded[(h_pad - offset):, :, :]), axis=0)
        padded = np.concatenate((padded[:offset, :, :], padded), axis=0)
        padded = np.concatenate((padded, padded[:, (w_pad - offset):, :]), axis=1)
        padded = np.concatenate((padded[:, :offset, :], padded), axis=1)

        # 初始化输出
        output = copy.deepcopy(padded)

        # 处理每个分块
        total_tiles = ith * itw
        print(f"共 {ith}x{itw} = {total_tiles} 个分块...")

        for i in range(ith):
            for j in range(itw):
                x = self.stride * i
                y = self.stride * j

                # 提取分块
                tile = padded[x:x+self.window_size, y:y+self.window_size, :]

                # 处理分块
                tile_result = self.predict(tile)

                # 提取中心区域（避免边缘伪影）
                tile_center = tile_result[offset:offset+self.stride, offset:offset+self.stride, :]

                # 写入输出
                output[x+offset:self.stride*(i+1)+offset, y+offset:self.stride*(j+1)+offset, :] = tile_center

                current = i * itw + j + 1
                if current % 10 == 0:
                    print(f"  已处理 {current}/{total_tiles} 个分块")

        # 移除填充
        output = np.clip(output, 0, 1)
        output = output[offset:-(offset+dh), offset:-(offset+dw), :]

        return output


# 向后兼容的别名
StarNetV2 = StarRemover
SuperStarOff = StarRemover


def test():
    """测试函数"""
    processor = StarRemover()
    processor.load_model()

    # 测试随机图像
    test_img = np.random.rand(512, 512, 3).astype(np.float32)
    result = processor.predict(test_img)

    print(f"输入尺寸: {test_img.shape}")
    print(f"输出尺寸: {result.shape}")
    print("测试通过!")


if __name__ == "__main__":
    test()
