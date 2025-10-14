#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Model Encryption/Decryption Module
用于保护模型文件的加密解密工具
"""

import os
import io
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
        # 组合多个因子生成密码短语
        # 这些因子分散在代码中，不易被识别
        factor1 = "HuiYanQuXing"  # 慧眼去星
        factor2 = "2025"
        factor3 = "DeepSpace"

        # 计算组合因子的哈希值
        combined = f"{factor1}{factor2}{factor3}"
        passphrase_hash = hashlib.sha256(combined.encode()).hexdigest()

        # 从哈希值派生密钥
        key_material = ModelCrypto._derive_key(passphrase_hash)

        # 转换为 Fernet 密钥格式
        import base64
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
    import sys

    if len(sys.argv) < 2:
        print("用法:")
        print("  加密: python model_crypto.py encrypt <input_file> <output_file>")
        print("  解密: python model_crypto.py decrypt <input_file> <output_file>")
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
