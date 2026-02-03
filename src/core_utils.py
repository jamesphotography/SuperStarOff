#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Model Encryption/Decryption Module
For protecting model files
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
    """Model encryption/decryption class"""

    # Project-specific key derivation parameters
    # These parameters are obfuscated in code
    _SALT = b'\x8a\x3f\x9e\x2d\x7b\x5c\x1a\x4e\xf6\x8d\x2c\x9a\x6b\x3f\x7e\x1d'
    _ITERATIONS = 100000

    @staticmethod
    def _derive_key(passphrase: str) -> bytes:
        """
        Derive encryption key from passphrase

        Args:
            passphrase: Password phrase

        Returns:
            Derived key
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
        Get encryption key
        Uses multiple factors to generate key

        Returns:
            Fernet key
        """
        import base64

        # Layer 1: Use byte sequences instead of plaintext strings (obfuscation)
        _p1 = bytes([72, 117, 105, 89, 97, 110])
        _p2 = bytes([81, 117, 88, 105, 110, 103])
        _p3 = bytes([50, 48, 50, 53])  # Year

        # Layer 2: Add path binding factor
        # Use platform-independent string for cross-platform compatibility
        # DO NOT CHANGE - modifying this value will break encrypted models
        _install_base = "/usr/local/SuperStarOff"
        _path_factor = hashlib.md5(_install_base.encode()).digest()[:8]

        # Layer 3: Add application identifier
        _app_signature = bytes([68, 101, 101, 112, 83, 112, 97, 99, 101])

        # Layer 4: Combine all factors and hash multiple times
        _raw = _p1 + _p2 + _p3 + _path_factor + _app_signature

        # Layer 5: Multiple hash rounds to increase computational complexity
        _digest = hashlib.sha256(_raw).digest()
        for _ in range(1000):  # 1000 extra hash rounds
            _digest = hashlib.sha256(_digest).digest()

        # Layer 6: Use final digest as passphrase to derive key
        passphrase_hash = hashlib.sha256(_digest).hexdigest()
        key_material = ModelCrypto._derive_key(passphrase_hash)

        # Convert to Fernet key format
        return base64.urlsafe_b64encode(key_material)

    @staticmethod
    def encrypt_file(input_path: str, output_path: str) -> bool:
        """
        Encrypt file

        Args:
            input_path: Input file path
            output_path: Output file path

        Returns:
            Whether encryption succeeded
        """
        try:
            print(f"Encrypting file: {input_path}")

            # Read original file
            with open(input_path, 'rb') as f:
                data = f.read()

            print(f"File size: {len(data) / (1024*1024):.2f} MB")

            # Get key and encrypt
            key = ModelCrypto._get_key()
            fernet = Fernet(key)

            print("Encrypting...")
            encrypted_data = fernet.encrypt(data)

            # Write encrypted file
            with open(output_path, 'wb') as f:
                f.write(encrypted_data)

            print(f"Encryption complete: {output_path}")
            print(f"Encrypted size: {len(encrypted_data) / (1024*1024):.2f} MB")

            return True

        except Exception as e:
            print(f"Encryption failed: {e}")
            return False

    @staticmethod
    def decrypt_file(input_path: str, output_path: str = None) -> bytes:
        """
        Decrypt file

        Args:
            input_path: Encrypted file path
            output_path: Output file path (optional, if None only returns data)

        Returns:
            Decrypted data (bytes), or None if failed
        """
        try:
            # Read encrypted file
            with open(input_path, 'rb') as f:
                encrypted_data = f.read()

            # Get key and decrypt
            key = ModelCrypto._get_key()
            fernet = Fernet(key)

            decrypted_data = fernet.decrypt(encrypted_data)

            # If output path specified, write to file
            if output_path:
                with open(output_path, 'wb') as f:
                    f.write(decrypted_data)

            return decrypted_data

        except Exception as e:
            print(f"Decryption failed: {e}")
            return None

    @staticmethod
    def decrypt_to_memory(input_path: str) -> io.BytesIO:
        """
        Decrypt file to memory

        Args:
            input_path: Encrypted file path

        Returns:
            BytesIO object containing decrypted data, or None if failed
        """
        try:
            # Decrypt file
            decrypted_data = ModelCrypto.decrypt_file(input_path)

            if decrypted_data is None:
                return None

            # Create memory buffer
            buffer = io.BytesIO(decrypted_data)
            buffer.seek(0)  # Reset to beginning

            return buffer

        except Exception as e:
            print(f"Decryption to memory failed: {e}")
            return None


def main():
    """Test encryption/decryption functionality"""

    if len(sys.argv) < 2:
        print("Usage:")
        print("  Encrypt: python core_utils.py encrypt <input_file> <output_file>")
        print("  Decrypt: python core_utils.py decrypt <input_file> <output_file>")
        sys.exit(1)

    command = sys.argv[1]

    if command == "encrypt":
        if len(sys.argv) < 4:
            print("Error: Need to specify input and output files")
            sys.exit(1)

        input_file = sys.argv[2]
        output_file = sys.argv[3]

        if ModelCrypto.encrypt_file(input_file, output_file):
            print("Encryption successful!")
        else:
            print("Encryption failed!")
            sys.exit(1)

    elif command == "decrypt":
        if len(sys.argv) < 4:
            print("Error: Need to specify input and output files")
            sys.exit(1)

        input_file = sys.argv[2]
        output_file = sys.argv[3]

        if ModelCrypto.decrypt_file(input_file, output_file):
            print("Decryption successful!")
        else:
            print("Decryption failed!")
            sys.exit(1)

    else:
        print(f"Unknown command: {command}")
        sys.exit(1)


if __name__ == "__main__":
    main()