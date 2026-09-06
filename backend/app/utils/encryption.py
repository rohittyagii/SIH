from __future__ import annotations
"""AES-256-GCM encryption for free-text notes and PII fields."""
import os
import base64
import hashlib

from cryptography.hazmat.primitives.ciphers.aead import AESGCM

from app.config import get_settings

settings = get_settings()


def _master_key() -> bytes:
    """Derive 32 raw bytes from the hex master key in config."""
    hex_key = settings.ENCRYPTION_MASTER_KEY
    # If it's a 64-char hex string, decode; otherwise use as UTF-8 and SHA-256 it
    try:
        if len(hex_key) == 64:
            return bytes.fromhex(hex_key)
    except ValueError:
        pass
    return hashlib.sha256(hex_key.encode()).digest()


def _user_key(user_id: str) -> bytes:
    """Derive a per-user 32-byte AES key from the master key + user_id."""
    master = _master_key()
    return hashlib.sha256(master + user_id.encode()).digest()


def encrypt_text(plaintext: str, user_id: str) -> bytes:
    """Encrypt a UTF-8 string with AES-256-GCM. Returns nonce+ciphertext."""
    if not plaintext:
        return b""
    key = _user_key(user_id)
    aesgcm = AESGCM(key)
    nonce = os.urandom(12)  # 96-bit nonce for GCM
    ciphertext = aesgcm.encrypt(nonce, plaintext.encode("utf-8"), None)
    return nonce + ciphertext


def decrypt_text(data: bytes, user_id: str) -> str:
    """Decrypt bytes produced by encrypt_text. Returns empty string on failure."""
    if not data:
        return ""
    key = _user_key(user_id)
    aesgcm = AESGCM(key)
    nonce, ciphertext = data[:12], data[12:]
    try:
        return aesgcm.decrypt(nonce, ciphertext, None).decode("utf-8")
    except Exception:
        return ""
