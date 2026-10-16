#!/usr/bin/env python3
"""
Scan a directory tree for corrupt / unreadable images before feeding them
into VIAME training. Uses both PIL (fast structural check) and OpenCV
(the actual library VIAME's loader uses) since they can disagree on
what counts as "readable."

This version also captures C-level stderr output from OpenCV/libjpeg
(e.g. "Premature end of JPEG file", "Corrupt JPEG data") because
cv2.imread() often returns a valid (non-None) array even when the
underlying decode was incomplete -- the only signal you get is a
warning printed directly to stderr by the C library, which the
original version of this script silently ignored.

Usage:
    python3 check_images.py /path/to/image/root [--ext png,jpg]
"""
import sys
import os
import argparse
from pathlib import Path


def check_with_pil(path):
    try:
        from PIL import Image
        with Image.open(path) as img:
            img.verify()  # checks structure without full decode
        # verify() closes the file; reopen to force a full pixel decode too
        with Image.open(path) as img:
            img.load()
        return None
    except Exception as e:
        return f"PIL error: {e}"


def check_with_cv2(path):
    """
    Runs cv2.imread() while capturing C-level stderr, so libjpeg
    warnings like "Premature end of JPEG file" are caught even though
    they don't raise a Python exception and don't cause imread() to
    return None.
    """
    import cv2

    stderr_fd = sys.stderr.fileno()
    saved_stderr_fd = os.dup(stderr_fd)
    read_fd, write_fd = os.pipe()

    os.dup2(write_fd, stderr_fd)
    os.close(write_fd)

    try:
        img = cv2.imread(str(path))
    finally:
        sys.stderr.flush()
        os.dup2(saved_stderr_fd, stderr_fd)
        os.close(saved_stderr_fd)

    # Drain the pipe (non-blocking-ish: read whatever is buffered)
    os.set_blocking(read_fd, False)
    captured = b""
    try:
        while True:
            chunk = os.read(read_fd, 65536)
            if not chunk:
                break
            captured += chunk
    except BlockingIOError:
        pass
    os.close(read_fd)

    captured_text = captured.decode(errors="ignore")

    if img is None:
        return "cv2.imread returned None (unreadable / unsupported format)"

    warning_markers = (
        "Premature end",
        "Corrupt JPEG",
        "Invalid SOS parameters",
        "Unsupported marker type",
        "Warning:",
    )
    if any(marker in captured_text for marker in warning_markers):
        return f"cv2 warning (partial/corrupt decode): {captured_text.strip()}"

    return None


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("root", help="Directory to scan recursively")
    parser.add_argument("--ext", default="png,jpg,jpeg",
                         help="Comma-separated list of extensions to check")
    args = parser.parse_args()

    exts = tuple("." + e.strip().lower().lstrip(".") for e in args.ext.split(","))
    root = Path(args.root)
    files = [p for p in root.rglob("*") if p.suffix.lower() in exts and p.is_file()]
    print(f"Found {len(files)} image files under {root}")

    bad = []
    for i, path in enumerate(files):
        if i % 200 == 0:
            print(f"  ...checked {i}/{len(files)}", file=sys.stderr)
        pil_err = check_with_pil(path)
        cv2_err = check_with_cv2(path)
        if pil_err or cv2_err:
            bad.append((path, pil_err, cv2_err))

    print(f"\n{len(bad)} corrupt / unreadable file(s) found:\n")
    out_path = root / "corrupt_images.txt"
    with open(out_path, "w") as f:
        for path, pil_err, cv2_err in bad:
            line = f"{path}"
            print(f"  {line}")
            if pil_err:
                print(f"    PIL: {pil_err}")
            if cv2_err:
                print(f"    cv2: {cv2_err}")
            f.write(line + "\n")

    print(f"\nList of bad file paths written to: {out_path}")


if __name__ == "__main__":
    main()

