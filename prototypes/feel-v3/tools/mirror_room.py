#!/usr/bin/env python3
# PROTOTYPE - NOT FOR PRODUCTION
"""
Mirrors a room text file horizontally:
- In header (line 0): swaps left=<room> and right=<room>
- In all grid lines (line 1+): reverses characters, swapping '<' and '>'
"""

import sys
import os

def mirror_room_text(text: str) -> str:
    lines = text.replace('\r', '').split('\n')
    if not lines or not lines[0].strip():
        return text

    # Process header
    header_parts = lines[0].split(',')
    header_dict = {}
    other_parts = []
    left_val = None
    right_val = None

    for part in header_parts:
        part = part.strip()
        if not part:
            continue
        if '=' in part:
            k, v = part.split('=', 1)
            k = k.strip()
            v = v.strip()
            if k == 'left':
                left_val = v
            elif k == 'right':
                right_val = v
            else:
                other_parts.append(f"{k}={v}")
        else:
            other_parts.append(part)

    # Swap left and right
    new_header_parts = list(other_parts)
    if right_val is not None and right_val != "":
        new_header_parts.append(f"left={right_val}")
    if left_val is not None and left_val != "":
        new_header_parts.append(f"right={left_val}")

    out_lines = [",".join(new_header_parts)]

    # Mirror grid lines
    for line in lines[1:]:
        if not line:
            continue
        mirrored_chars = []
        for ch in reversed(line):
            if ch == '<':
                mirrored_chars.append('>')
            elif ch == '>':
                mirrored_chars.append('<')
            else:
                mirrored_chars.append(ch)
        out_lines.append("".join(mirrored_chars))

    return "\n".join(out_lines) + "\n"

def main():
    if len(sys.argv) > 1:
        in_path = sys.argv[1]
        out_path = sys.argv[2] if len(sys.argv) > 2 else None
        with open(in_path, 'r', encoding='utf-8') as f:
            content = f.read()
        res = mirror_room_text(content)
        if out_path:
            with open(out_path, 'w', encoding='utf-8') as f:
                f.write(res)
        else:
            sys.stdout.write(res)
    else:
        # Default behavior: mirror shaft.txt to shaft_shift.txt if found
        base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        shaft_path = os.path.join(base_dir, 'rooms', 'shaft.txt')
        out_path = os.path.join(base_dir, 'rooms', 'shaft_shift.txt')
        if os.path.exists(shaft_path):
            with open(shaft_path, 'r', encoding='utf-8') as f:
                content = f.read()
            res = mirror_room_text(content)
            with open(out_path, 'w', encoding='utf-8') as f:
                f.write(res)
            print(f"Mirrored {shaft_path} -> {out_path}")

if __name__ == '__main__':
    main()
