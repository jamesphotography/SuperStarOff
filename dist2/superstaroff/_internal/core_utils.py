#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Model Encryption/Decryption Module
用于保护模型文件的加密解密工具
"""

import os
import io
import sys
import hashlib
from pathlib import Path
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC


class ModelCrypto:
    """模型加密解密类"""

    # 使用项目特定的密钥派生参数
    # 这些参数混淆在代码中，不容易被识别
    _SALT = b'\x8a\x3f\x9e\x2d\x7b\x5c\x1a\x4e\xf6\x8d\x2c\x9a\x6b\x3f\x7e\x1d'
    _ITERATIONS = 100000

    @staticmethod
    def _derive_key(passphrase: str) -> bytes:
        """
        从密码短语派生加密密钥

        Args:
            passphrase: 密码短语

        Returns:
            派生的密钥
        """
        kdf = PBKDF2HMAC(
            algorithm=hashes.SHA256(),
            length=32,
            salt=ModelCrypto._SALT,
            iterations=ModelCrypto._ITERATIONS,
        )
        return kdf.derive(passphrase.encode())

    @staticmethod
    def _get_key() -> bytes:
        """
        获取加密密钥
        使用多个因子组合生成密钥，增加破解难度

        Returns:
            Fernet 密钥
        """
        import base64

        # 第1层：使用字节序列而非明文字符串（混淆）
        # 这些看起来像随机数据，实际是编码后的密钥因子
        _p1 = bytes([72, 117, 105, 89, 97, 110])  # 对应部分字符
        _p2 = bytes([81, 117, 88, 105, 110, 103])  # 对应部分字符
        _p3 = bytes([50, 48, 50, 53])  # 年份

        # 第2层：添加路径绑定因子
        # 使用平台无关的字符串确保跨平台兼容性
        # DO NOT CHANGE - 修改此值会导致加密模型无法解密
        _install_base = "SuperStarOff-2025"
        _path_factor = hashlib.md5(_install_base.encode()).digest()[:8]

        # 第3层：添加应用标识符（混淆在普通变量名中）
        _app_signature = bytes([68, 101, 101, 112, 83, 112, 97, 99, 101])  # 应用标识

        # 第4层：组合所有因子并多次哈希
        _raw = _p1 + _p2 + _p3 + _path_factor + _app_signature

        # 第5层：多轮哈希增加计算复杂度
        _digest = hashlib.sha256(_raw).digest()
        for _ in range(1000):  # 1000轮额外哈希
            _digest = hashlib.sha256(_digest).digest()

        # 第6层：使用最终digest作为passphrase派生密钥
        passphrase_hash = hashlib.sha256(_digest).hexdigest()
        key_material = ModelCrypto._derive_key(passphrase_hash)

        # 转换为 Fernet 密钥格式
        return base64.urlsafe_b64encode(key_material)

    @staticmethod
    def encrypt_file(input_path: str, output_path: str) -> bool:
        """
        加密文件

        Args:
            input_path: 输入文件路径
            output_path: 输出文件路径

        Returns:
            加密是否成功
        """
        try:
            print(f"正在加密文件: {input_path}")

            # 读取原始文件
            with open(input_path, 'rb') as f:
                data = f.read()

            print(f"文件大小: {len(data) / (1024*1024):.2f} MB")

            # 获取密钥并加密
            key = ModelCrypto._get_key()
            fernet = Fernet(key)

            print("正在加密...")
            encrypted_data = fernet.encrypt(data)

            # 写入加密文件
            with open(output_path, 'wb') as f:
                f.write(encrypted_data)

            print(f"加密完成: {output_path}")
            print(f"加密后大小: {len(encrypted_data) / (1024*1024):.2f} MB")

            return True

        except Exception as e:
            print(f"加密失败: {e}")
            return False

    @staticmethod
    def decrypt_file(input_path: str, output_path: str = None) -> bytes:
        """
        解密文件

        Args:
            input_path: 加密文件路径
            output_path: 输出文件路径（可选，如果为None则只返回数据不写入文件）

        Returns:
            解密后的数据（bytes），如果失败返回 None
        """
        try:
            # 读取加密文件
            with open(input_path, 'rb') as f:
                encrypted_data = f.read()

            # 获取密钥并解密
            key = ModelCrypto._get_key()
            fernet = Fernet(key)

            decrypted_data = fernet.decrypt(encrypted_data)

            # 如果指定了输出路径，则写入文件
            if output_path:
                with open(output_path, 'wb') as f:
                    f.write(decrypted_data)

            return decrypted_data

        except Exception as e:
            print(f"解密失败: {e}")
            return None

    @staticmethod
    def decrypt_to_memory(input_path: str) -> io.BytesIO:
        """
        解密文件到内存

        Args:
            input_path: 加密文件路径

        Returns:
            包含解密数据的 BytesIO 对象，如果失败返回 None
        """
        try:
            # 解密文件
            decrypted_data = ModelCrypto.decrypt_file(input_path)

            if decrypted_data is None:
                return None

            # 创建内存缓冲区
            buffer = io.BytesIO(decrypted_data)
            buffer.seek(0)  # 重置到开头

            return buffer

        except Exception as e:
            print(f"解密到内存失败: {e}")
            return None


def main():
    """测试加密解密功能"""

    if len(sys.argv) < 2:
        print("用法:")
        print("  加密: python core_utils.py encrypt <input_file> <output_file>")
        print("  解密: python core_utils.py decrypt <input_file> <output_file>")
        sys.exit(1)

    command = sys.argv[1]

    if command == "encrypt":
        if len(sys.argv) < 4:
            print("错误: 需要指定输入和输出文件")
            sys.exit(1)

        input_file = sys.argv[2]
        output_file = sys.argv[3]

        if ModelCrypto.encrypt_file(input_file, output_file):
            print("✓ 加密成功!")
        else:
            print("✗ 加密失败!")
            sys.exit(1)

    elif command == "decrypt":
        if len(sys.argv) < 4:
            print("错误: 需要指定输入和输出文件")
            sys.exit(1)

        input_file = sys.argv[2]
        output_file = sys.argv[3]

        if ModelCrypto.decrypt_file(input_file, output_file):
            print("✓ 解密成功!")
        else:
            print("✗ 解密失败!")
            sys.exit(1)

    else:
        print(f"未知命令: {command}")
        sys.exit(1)


if __name__ == "__main__":
    main()