#!/usr/bin/env python3
"""Validate the tracked TwinsanityEvolved Wiki pages and internal links."""
from __future__ import annotations

import re
import sys
from pathlib import Path
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[1]
WIKI = ROOT / "wiki-source"
REQUIRED = {
    "Home.md",
    "Getting-started.md",
    "Supported-platforms.md",
    "H700-port-status.md",
    "Discs-and-game-data.md",
    "Mods.md",
    "Troubleshooting.md",
    "FAQ.md",
    "_Sidebar.md",
    "README.md",
}
LINK = re.compile(r"(?<!!)\[[^\]]+\]\(([^)]+)\)")
errors: list[str] = []


def check(condition: bool, message: str) -> None:
    if not condition:
        errors.append(message)


def main() -> int:
    check(WIKI.is_dir(), "wiki-source/ is missing")
    if not WIKI.is_dir():
        print("Wiki validation failed: wiki-source/ is missing", file=sys.stderr)
        return 1

    present = {path.name for path in WIKI.glob("*.md")}
    for name in sorted(REQUIRED - present):
        errors.append(f"required Wiki source file is missing: {name}")

    for page in sorted(WIKI.glob("*.md")):
        text = page.read_text(encoding="utf-8")
        for raw_target in LINK.findall(text):
            target = raw_target.strip().split(maxsplit=1)[0].strip("<>")
            if not target:
                continue
            parsed = urlsplit(target)
            if parsed.scheme or parsed.netloc or target.startswith("#"):
                continue
            path_part = unquote(parsed.path)
            if not path_part:
                continue

            candidate = Path(path_part)
            if not candidate.suffix:
                candidate = candidate.with_suffix(".md")
            resolved = (page.parent / candidate).resolve()
            try:
                resolved.relative_to(WIKI.resolve())
            except ValueError:
                # Relative links may intentionally point to repository docs or README files.
                resolved = (page.parent / candidate).resolve()
            if not resolved.exists():
                errors.append(f"{page.relative_to(ROOT)}: broken link target {raw_target!r}")

    docs_index_path = ROOT / "docs" / "README.md"
    docs_index = docs_index_path.read_text(encoding="utf-8") if docs_index_path.is_file() else ""
    check("wiki-source/" in docs_index and "/wiki" in docs_index,
          "docs/README.md must link to the tracked Wiki source and GitHub Wiki")
    style_guide = ROOT / "docs" / "STYLE_GUIDE.md"
    check(style_guide.is_file(), "docs/STYLE_GUIDE.md is missing")
    check("[documentation style guide]" in docs_index.lower(),
          "docs/README.md must link the repository-wide documentation style guide")
    h700 = (WIKI / "H700-port-status.md").read_text(encoding="utf-8").lower()
    check("unvalidated" in h700 and "openGL 4.1".lower() in h700,
          "H700 status must preserve the unvalidated/OpenGL 4.1 compatibility boundary")
    plan = ROOT / "docs" / "H700_PORTING_PLAN.md"
    check(plan.is_file(), "docs/H700_PORTING_PLAN.md is missing")
    audit = ROOT / "docs" / "H700_RENDERER_AUDIT.md"
    check(audit.is_file(), "docs/H700_RENDERER_AUDIT.md is missing")
    check("[the renderer audit](../docs/H700_RENDERER_AUDIT.md)" in (WIKI / "H700-port-status.md").read_text(encoding="utf-8"),
          "H700 Wiki page must link to the renderer audit")

    if errors:
        print("Wiki validation failed:")
        for error in errors:
            print(f"- {error}")
        return 1
    print(f"Wiki validation passed: {len(present)} tracked Markdown files checked.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
