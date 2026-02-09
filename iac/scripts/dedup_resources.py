#!/usr/bin/env python3
"""Deduplicate Terraform resource/data blocks across multiple .tf files.

When multiple remediation files in the same category define identical
resource or data blocks (e.g. aws_iam_account_password_policy), this
script keeps only the first occurrence and removes duplicates.

Usage: python3 dedup_resources.py <directory>
"""
import re, sys, pathlib, glob


def extract_blocks(text):
    """Split HCL text into top-level blocks with their signatures."""
    blocks = []
    current_lines = []
    current_sig = None
    depth = 0
    in_heredoc = False
    heredoc_marker = None

    for line in text.splitlines():
        # Track heredoc boundaries
        if in_heredoc:
            current_lines.append(line)
            if line.strip() == heredoc_marker:
                in_heredoc = False
                heredoc_marker = None
            continue
        hm = re.search(r'<<-?\s*([A-Za-z0-9_]+)\s*$', line)
        if hm and depth > 0:
            in_heredoc = True
            heredoc_marker = hm.group(1)
            current_lines.append(line)
            continue

        if depth == 0:
            # Try to match a top-level block start
            m = re.match(
                r'^\s*(resource|data)\s+"([^"]+)"\s+"([^"]+)"\s*\{', line)
            if m:
                current_sig = (m.group(1), m.group(2), m.group(3))
                current_lines = [line]
                depth = line.count('{') - line.count('}')
                if depth <= 0:
                    blocks.append((current_sig, "\n".join(current_lines)))
                    current_sig = None
                    current_lines = []
                    depth = 0
                continue
            # Non-block line at depth 0 (comments, blank lines)
            blocks.append((None, line))
        else:
            current_lines.append(line)
            depth += line.count('{') - line.count('}')
            if depth <= 0:
                blocks.append((current_sig, "\n".join(current_lines)))
                current_sig = None
                current_lines = []
                depth = 0

    # Leftover lines
    if current_lines:
        blocks.append((current_sig, "\n".join(current_lines)))

    return blocks


def dedup_directory(directory):
    """Merge all .tf files in directory, dedup, write to merged.tf."""
    tf_files = sorted(glob.glob(str(directory / "*.tf")))
    seen_sigs = set()
    merged_blocks = []

    for tf_file in tf_files:
        p = pathlib.Path(tf_file)
        # Skip framework files we generate ourselves
        if p.name in ("backend.tf", "provider.tf", "data.tf"):
            continue
        text = p.read_text()
        blocks = extract_blocks(text)

        kept = []
        for sig, content in blocks:
            if sig is not None:
                if sig in seen_sigs:
                    continue  # duplicate — skip
                seen_sigs.add(sig)
            kept.append(content)

        # Rewrite the file without duplicates
        p.write_text("\n".join(kept) + "\n")


if __name__ == "__main__":
    dedup_directory(pathlib.Path(sys.argv[1]))
