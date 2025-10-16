#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
SuperStarOff Core - 星点去除核心模块
Simplified standalone module for Photoshop integration
"""

import torch
import numpy as np
import tifffile as tiff
from PIL import Image
from pathlib import Path
import copy


class SuperStarOff:
    """SuperStarOff 星点去除处理器"""

    def __init__(self, model_path=None, device='auto', stride=256):
        """
        初始化

        Args:
            model_path: 模型文件路径（默认自动查找）
            device: 'auto', 'cpu', 'mps' 或 'cuda'
            stride: 处理步长（默认 256）
        """
        self.device = self._get_device(device)
        self.window_size = 512  # 固定窗口大小
        self.stride = stride

        # 查找模型文件
        if model_path is None:
            import sys

            # 判断运行环境
            if getattr(sys, 'frozen', False):
                # 打包后的应用
                base_path = Path(sys._MEIPASS)
            else:
                # 开发环境或安装后
                current_dir = Path(__file__).parent

                # 尝试两种路径结构
                if (current_dir.parent / "models").exists():
                    # 开发环境: photoshop_integration/../models
                    base_path = current_dir.parent
                else:
                    # 安装后: /usr/local/SuperStarOff/
                    base_path = current_dir

            model_path = base_path / "models" / "SuperStarOff2025.pt"

            if not model_path.exists():
                raise FileNotFoundError(f"模型文件未找到: {model_path}")

        self.model_path = Path(model_path)
        self.model = None

    def _get_device(self, device_preference):
        """选择最佳计算设备"""
        if device_preference == 'auto':
            # 自动选择: MPS > CUDA > CPU
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
        """加载模型"""
        if not self.model_path.exists():
            raise FileNotFoundError(f"模型文件未找到: {self.model_path}")

        print(f"正在加载模型: {self.model_path.name}")

        # 尝试解密加载
        try:
            from model_crypto import ModelCrypto

            print("正在解密模型...")
            buffer = ModelCrypto.decrypt_to_memory(str(self.model_path))

            if buffer is None:
                raise RuntimeError("模型解密失败")

            self.model = torch.jit.load(buffer, map_location=self.device)
            print("模型加载成功")

        except ImportError:
            # 没有加密模块，尝试直接加载
            print("警告: 加密模块不可用，尝试直接加载模型")
            self.model = torch.jit.load(str(self.model_path), map_location=self.device)
        except Exception as e:
            raise RuntimeError(f"模型加载失败: {e}")

        self.model.eval()
        print(f"模型已就绪 (设备: {self.device})")

    def predict(self, image):
        """
        处理单张图片

        Args:
            image: numpy 数组 (H, W, C)，值域 [0, 1]

        Returns:
            去星后的图片: numpy 数组 (H, W, C)，值域 [0, 1]
        """
        if self.model is None:
            self.load_model()

        # 转换为 tensor
        tensor = torch.from_numpy(image).float()
        tensor = tensor.permute(2, 0, 1).unsqueeze(0).to(self.device)

        # 推理
        with torch.no_grad():
            output = self.model(tensor)

        # 转换回 numpy
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

        # 加载模型
        if self.model is None:
            self.load_model()

        # 读取图片
        print(f"正在加载图片: {input_path}")
        input_path_lower = str(input_path).lower()

        if input_path_lower.endswith(('.tif', '.tiff')):
            # TIFF 文件
            data = tiff.imread(input_path)

            # 处理多层 TIFF
            if len(data.shape) > 3:
                print(f"TIFF 有 {data.shape[0]} 层，使用第一层")
                data = data[0]
        else:
            # PNG/JPEG 文件
            pil_image = Image.open(input_path)
            data = np.array(pil_image)

        # 记录输入类型
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
        if len(image.shape) == 2:
            image = np.stack([image] * 3, axis=-1)
            was_grayscale = True
        else:
            was_grayscale = False

        # 移除 alpha 通道
        if image.shape[2] == 4:
            print("移除 alpha 通道")
            image = image[:, :, :3]

        # 分块处理
        print(f"正在处理 (窗口={self.window_size}, 步长={self.stride})...")
        starless = self._process_with_tiling(image)

        # 恢复灰度图
        if was_grayscale:
            starless = starless[:, :, 0]

        # 反归一化
        if input_dtype == np.uint8:
            output_data = (starless * 255).astype(np.uint8)
        else:
            output_data = (starless * 65535).astype(np.uint16)

        # 保存结果
        print(f"正在保存结果: {output_path}")
        output_path_lower = str(output_path).lower()

        if output_path_lower.endswith(('.tif', '.tiff')):
            tiff.imwrite(output_path, output_data)
        else:
            output_image = Image.fromarray(output_data)
            output_image.save(output_path)

        print("完成!")

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
        print(f"共 {ith}x{itw} = {ith*itw} 个分块...")
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

                if (i * itw + j + 1) % 10 == 0:
                    print(f"  已处理 {i*itw+j+1}/{ith*itw} 个分块")

        # 移除填充
        output = np.clip(output, 0, 1)
        output = output[offset:-(offset+dh), offset:-(offset+dw), :]

        return output
