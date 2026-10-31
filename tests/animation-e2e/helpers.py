"""Shared Verification Helpers and Utilities for Animation E2E Testing.

Provides robust file integrity, GIF validation (zero external dependency pure-Python
binary decoder with Pillow fallback), JSON schema checking, and kinematic math tools.
"""

import hashlib
import json
import math
import os
import struct
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple, Union

try:
    from PIL import Image
    HAS_PIL = True
except ImportError:
    HAS_PIL = False


def compute_sha256(file_path: Union[str, Path]) -> str:
    """Compute SHA-256 checksum in uppercase hexadecimal."""
    hasher = hashlib.sha256()
    with open(file_path, "rb") as f:
        while chunk := f.read(65536):
            hasher.update(chunk)
    return hasher.hexdigest().upper()


def load_json(file_path: Union[str, Path]) -> Tuple[bool, Optional[Any], str]:
    """Safely load and parse JSON file. Returns (success, data, error_msg)."""
    p = Path(file_path)
    if not p.is_file():
        return False, None, f"File does not exist: {p}"
    try:
        with open(p, "r", encoding="utf-8") as f:
            data = json.load(f)
        return True, data, ""
    except Exception as e:
        return False, None, f"JSON parse error in {p.name}: {str(e)}"


def parse_gif_binary(file_path: Union[str, Path]) -> Dict[str, Any]:
    """Pure-Python binary GIF89a / GIF87a parser without third-party dependencies.

    Returns dict with keys: 'valid', 'width', 'height', 'frames', 'loop', 'error'.
    """
    res = {
        "valid": False,
        "width": 0,
        "height": 0,
        "frames": 0,
        "loop": None,
        "error": "",
    }
    p = Path(file_path)
    if not p.is_file():
        res["error"] = f"File not found: {p}"
        return res

    try:
        with open(p, "rb") as f:
            data = f.read()

        if len(data) < 13 or data[:6] not in (b"GIF87a", b"GIF89a"):
            res["error"] = "Invalid GIF header"
            return res

        w, h = struct.unpack("<HH", data[6:10])
        res["width"] = w
        res["height"] = h

        flags = data[10]
        idx = 13
        if flags & 0x80:  # Global Color Table
            gct_size = 3 * (1 << ((flags & 0x07) + 1))
            idx += gct_size

        frame_count = 0
        loop = None

        while idx < len(data):
            b = data[idx]
            if b == 0x3B:  # Trailer (end of GIF)
                break
            elif b == 0x21:  # Extension block
                if idx + 1 >= len(data):
                    break
                label = data[idx + 1]
                idx += 2
                blocks = []
                while idx < len(data) and data[idx] != 0:
                    bsize = data[idx]
                    blocks.append(data[idx + 1 : idx + 1 + bsize])
                    idx += 1 + bsize
                idx += 1  # Block terminator (0x00)

                # Check for Netscape 2.0 loop extension (Application Extension 0xFF)
                if label == 0xFF and len(blocks) >= 2:
                    if blocks[0].startswith(b"NETSCAPE2.0") or blocks[0].startswith(b"ANIMEXTS1.0"):
                        sub = blocks[1]
                        if len(sub) >= 3 and sub[0] == 1:
                            loop = struct.unpack("<H", sub[1:3])[0]
            elif b == 0x2C:  # Image Descriptor (frame)
                frame_count += 1
                idx += 9
                if idx >= len(data):
                    break
                local_flags = data[idx]
                idx += 1
                if local_flags & 0x80:  # Local Color Table
                    lct_size = 3 * (1 << ((local_flags & 0x07) + 1))
                    idx += lct_size
                idx += 1  # LZW minimum code size
                while idx < len(data) and data[idx] != 0:
                    idx += 1 + data[idx]
                idx += 1  # Sub-block terminator
            else:
                idx += 1

        res["frames"] = frame_count
        res["loop"] = loop
        res["valid"] = frame_count > 0 and w > 0 and h > 0
        return res
    except Exception as e:
        res["error"] = f"GIF binary parse exception: {str(e)}"
        return res


def parse_gif(file_path: Union[str, Path]) -> Dict[str, Any]:
    """Parse animated GIF properties using PIL if available, falling back to binary parser.

    Ensures both frame count, dimensions, and loop properties are verified.
    """
    p = Path(file_path)
    if not p.is_file():
        return {
            "valid": False,
            "width": 0,
            "height": 0,
            "frames": 0,
            "loop": None,
            "error": f"File does not exist: {p}",
        }

    # Start with binary parser result
    bin_result = parse_gif_binary(p)

    if HAS_PIL:
        try:
            with Image.open(p) as img:
                pil_w, pil_h = img.size
                pil_frames = getattr(img, "n_frames", 1)
                pil_loop = img.info.get("loop", None)

                # Cross-verify: Prefer PIL for frame iteration, fallback to binary for loop
                return {
                    "valid": True,
                    "width": pil_w,
                    "height": pil_h,
                    "frames": pil_frames,
                    "loop": pil_loop if pil_loop is not None else bin_result.get("loop"),
                    "error": "",
                }
        except Exception as e:
            # If PIL fails on custom encoding, return binary result if valid
            if bin_result["valid"]:
                return bin_result
            return {
                "valid": False,
                "width": 0,
                "height": 0,
                "frames": 0,
                "loop": None,
                "error": f"PIL & Binary parse error: {str(e)}",
            }

    return bin_result


def find_matching_file(directory: Union[str, Path], patterns: List[str]) -> Optional[Path]:
    """Search for the first file matching any glob pattern in directory."""
    d = Path(directory)
    if not d.is_dir():
        return None
    for pattern in patterns:
        matches = list(d.glob(pattern))
        if matches:
            # Prefer exact or non-temporary matches
            for m in matches:
                if not m.name.endswith(".blend1") and not m.name.startswith("~"):
                    return m
            return matches[0]
    return None


def is_matrix_orthogonal(rot_matrix_9: List[float], tol: float = 0.05) -> bool:
    """Check if 9-element 3x3 rotation matrix is orthogonal: R * R^T = I and det(R) ≈ 1."""
    if len(rot_matrix_9) != 9:
        return False
    r = rot_matrix_9
    # R * R^T elements:
    row0_dot_row0 = r[0] * r[0] + r[1] * r[1] + r[2] * r[2]
    row1_dot_row1 = r[3] * r[3] + r[4] * r[4] + r[5] * r[5]
    row2_dot_row2 = r[6] * r[6] + r[7] * r[7] + r[8] * r[8]
    row0_dot_row1 = r[0] * r[3] + r[1] * r[4] + r[2] * r[5]
    row0_dot_row2 = r[0] * r[6] + r[1] * r[7] + r[2] * r[8]
    row1_dot_row2 = r[3] * r[6] + r[4] * r[7] + r[5] * r[8]

    if abs(row0_dot_row0 - 1.0) > tol or abs(row1_dot_row1 - 1.0) > tol or abs(row2_dot_row2 - 1.0) > tol:
        return False
    if abs(row0_dot_row1) > tol or abs(row0_dot_row2) > tol or abs(row1_dot_row2) > tol:
        return False

    # Determinant
    det = (
        r[0] * (r[4] * r[8] - r[5] * r[7])
        - r[1] * (r[3] * r[8] - r[5] * r[6])
        + r[2] * (r[3] * r[7] - r[4] * r[6])
    )
    return abs(det - 1.0) <= tol


def cframe_matrix_to_euler_deg(rot_matrix_9: List[float]) -> Tuple[float, float, float]:
    """Convert 9-element rotation matrix to Euler angles (pitch, yaw, roll) in degrees."""
    r = rot_matrix_9
    # Pitch (around X), Yaw (around Y), Roll (around Z)
    # Using ZYX or XYZ convention
    sy = math.sqrt(r[0] * r[0] + r[3] * r[3])
    singular = sy < 1e-6
    if not singular:
        x = math.atan2(r[7], r[8])
        y = math.atan2(-r[6], sy)
        z = math.atan2(r[3], r[0])
    else:
        x = math.atan2(-r[5], r[4])
        y = math.atan2(-r[6], sy)
        z = 0.0
    return math.degrees(x), math.degrees(y), math.degrees(z)
