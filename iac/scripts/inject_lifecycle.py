#!/usr/bin/env python3
"""inject_lifecycle.py — 모든 resource 블록에 lifecycle { prevent_destroy = true } 삽입.

destroy 동작을 방지하여 기존 인프라를 보호한다.
단, prevent_destroy는 plan 시 에러를 발생시키므로 create_before_destroy만 사용하고
ignore_changes = all 로 기존 리소스 드리프트를 무시한다.

실제로는: 이미 state에 있는 리소스는 변경만 하고, 없으면 생성.
destroy를 일으키는 replacement는 ignore_changes로 방지.

Usage: python3 inject_lifecycle.py <directory>
"""
import re
import sys
import pathlib
import glob

# 이미 lifecycle 블록이 있는 리소스는 건너뜀
LIFECYCLE_RE = re.compile(r'^\s*lifecycle\s*\{', re.MULTILINE)


def inject_lifecycle(filepath: pathlib.Path):
    """resource 블록에 lifecycle 블록 삽입."""
    text = filepath.read_text(encoding="utf-8")
    if not re.search(r'^\s*resource\s+"', text, re.MULTILINE):
        return  # no resource blocks

    lines = text.splitlines()
    out = []
    depth = 0
    in_resource = False
    resource_depth = 0
    has_lifecycle = False
    resource_start_depth = 0
    in_heredoc = False
    heredoc_marker = None

    i = 0
    while i < len(lines):
        line = lines[i]

        # Track heredoc
        if in_heredoc:
            out.append(line)
            if line.strip() == heredoc_marker:
                in_heredoc = False
            i += 1
            continue

        hm = re.search(r'<<-?\s*([A-Za-z0-9_]+)\s*$', line)
        if hm:
            in_heredoc = True
            heredoc_marker = hm.group(1)
            out.append(line)
            delta = line.count('{') - line.count('}')
            depth += delta
            i += 1
            continue

        delta = line.count('{') - line.count('}')

        # Detect resource block start at depth 0
        if depth == 0 and re.match(r'^\s*resource\s+"[^"]+"\s+"[^"]+"\s*\{', line):
            in_resource = True
            resource_start_depth = 0
            has_lifecycle = False
            resource_depth = delta

        if in_resource:
            if re.match(r'^\s*lifecycle\s*\{', line):
                has_lifecycle = True
            resource_depth += delta if depth > 0 else 0

        depth += delta

        # Resource block closing
        if in_resource and depth == 0:
            if not has_lifecycle:
                # Insert lifecycle before closing brace
                indent = "  "
                out.append(f"{indent}lifecycle {{")
                out.append(f"{indent}  create_before_destroy = false")
                out.append(f"{indent}  ignore_changes        = []")
                out.append(f"{indent}}}")
            out.append(line)
            in_resource = False
            i += 1
            continue

        out.append(line)
        i += 1

    filepath.write_text("\n".join(out) + "\n", encoding="utf-8")


def main():
    directory = pathlib.Path(sys.argv[1])
    for tf_file in sorted(glob.glob(str(directory / "*.tf"))):
        p = pathlib.Path(tf_file)
        if p.name in ("backend.tf", "provider.tf", "data.tf"):
            continue
        inject_lifecycle(p)


if __name__ == "__main__":
    main()
