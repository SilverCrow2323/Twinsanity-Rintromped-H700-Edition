#!/usr/bin/env python3
"""Validate repository documentation links, page structure and image alt text."""
from __future__ import annotations

import re
import sys
from pathlib import Path
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[1]
DOC_ROOTS = (ROOT / "docs", ROOT / "porting" / "h700" / "docs")
EXTRA_PAGES = (ROOT / "README.md", ROOT / "porting" / "h700" / "README.md")
LINK = re.compile(r"(?<!!)\[[^\]]+\]\(([^)]+)\)")
IMAGE = re.compile(r"!\[([^\]]*)\]\(([^)]+)\)")
errors: list[str] = []


def main() -> int:
    required = (
        ROOT / "docs" / "README.md",
        ROOT / "docs" / "STYLE_GUIDE.md",
        ROOT / "docs" / "H700_PORTING_PLAN.md",
        ROOT / "docs" / "H700_RENDERER_AUDIT.md",
        ROOT / "docs" / "h700" / "README.md",
        ROOT / "docs" / "h700" / "assets" / "hero.svg",
        ROOT / "docs" / "h700" / "compatibility-matrix.md",
    )
    for path in required:
        if not path.is_file():
            errors.append(f"required documentation asset/page is missing: {path.relative_to(ROOT)}")

    pages: list[Path] = list(EXTRA_PAGES)
    for root in DOC_ROOTS:
        if root.is_dir():
            pages.extend(sorted(root.rglob("*.md")))

    checked = 0
    for page in pages:
        if not page.is_file():
            errors.append(f"documentation page is missing: {page.relative_to(ROOT)}")
            continue
        checked += 1
        source = page.read_text(encoding="utf-8")
        h1 = re.findall(r"^#\s+\S", source, flags=re.MULTILINE)
        if len(h1) != 1:
            errors.append(f"{page.relative_to(ROOT)}: expected exactly one H1, found {len(h1)}")

        for alt, raw_target in IMAGE.findall(source):
            if not alt.strip():
                errors.append(f"{page.relative_to(ROOT)}: image is missing alternative text: {raw_target}")
        for raw_target in LINK.findall(source) + [item[1] for item in IMAGE.findall(source)]:
            target = raw_target.strip().split(maxsplit=1)[0].strip("<>")
            parsed = urlsplit(target)
            if parsed.scheme or parsed.netloc or target.startswith("#"):
                continue
            path_part = unquote(parsed.path)
            if not path_part:
                continue
            resolved = (page.parent / path_part).resolve()
            if not resolved.suffix:
                if resolved.is_dir():
                    resolved = resolved / "README.md"
                else:
                    resolved = resolved.with_suffix(".md")
            if not resolved.exists():
                errors.append(f"{page.relative_to(ROOT)}: broken local link or image {raw_target!r}")

    style = ROOT / "docs" / "STYLE_GUIDE.md"
    if style.is_file():
        style_text = style.read_text(encoding="utf-8")
        for token in ("MUST KNOW!!", "Optional", "Mermaid", "alternative text", "Evidence"):
            if token.lower() not in style_text.lower():
                errors.append(f"docs/STYLE_GUIDE.md: missing design rule {token!r}")

    if errors:
        print("Documentation validation failed:")
        for error in errors:
            print(f"- {error}")
        return 1
    print(f"Documentation validation passed: {checked} Markdown pages, required assets and local links checked.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
