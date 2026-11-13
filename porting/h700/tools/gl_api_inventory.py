#!/usr/bin/env python3
"""Inventory desktop GL calls/constants for manual H700 GLES classification."""
from __future__ import annotations
import argparse
import collections
import json
import re
from pathlib import Path

CALL_RE = re.compile(r"\b(gl[A-Z][A-Za-z0-9_]*)\s*\(")
CONST_RE = re.compile(r"\b(GL_[A-Z0-9_]+)\b")
VERSION_RE = re.compile(r"#\s*version\s+([0-9]+)(?:\s+([A-Za-z_]+))?")
DEFAULT_DIRS = (
    "engine/engine/render/backends/gl",
    "engine/engine/platform/sdl",
    "engine/engine/platform/host",
    "engine/engine/platform/ps2e",
    "engine/app/host",
)

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("upstream", type=Path)
    parser.add_argument("--json", type=Path, default=None)
    parser.add_argument("--markdown", type=Path, default=None)
    args = parser.parse_args()
    root = args.upstream.resolve()
    calls: dict[str, list[str]] = collections.defaultdict(list)
    constants: dict[str, list[str]] = collections.defaultdict(list)
    shaders: list[dict[str, str | int]] = []
    scanned: list[str] = []
    for rel_dir in DEFAULT_DIRS:
        directory = root / rel_dir
        if not directory.is_dir():
            raise SystemExit(f"missing expected source directory: {directory}")
        for path in sorted(directory.rglob("*")):
            if not path.is_file() or path.suffix.lower() not in {".c", ".cc", ".cpp", ".h", ".hpp", ".glsl", ".vert", ".frag"}:
                continue
            rel = path.relative_to(root).as_posix()
            try:
                source = path.read_text(encoding="utf-8", errors="replace")
            except OSError as exc:
                print(f"warning: cannot read {rel}: {exc}")
                continue
            scanned.append(rel)
            for line_no, line in enumerate(source.splitlines(), 1):
                for name in set(CALL_RE.findall(line)):
                    calls[name].append(f"{rel}:{line_no}")
                for name in set(CONST_RE.findall(line)):
                    constants[name].append(f"{rel}:{line_no}")
                for match in VERSION_RE.finditer(line):
                    shaders.append({"file": rel, "line": line_no, "version": int(match.group(1)),
                                    "profile": match.group(2) or "unspecified"})
    report = {
        "source_root": str(root),
        "scanned_files": scanned,
        "gl_calls": {k: sorted(v) for k, v in sorted(calls.items())},
        "gl_constants": {k: sorted(v) for k, v in sorted(constants.items())},
        "shader_versions": shaders,
        "warning": "Inventory only. Classify every item against the target GLES specification and device report.",
    }
    if args.json:
        args.json.parent.mkdir(parents=True, exist_ok=True)
        args.json.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    lines = [
        "# Upstream GL API inventory", "",
        f"Source: {root}",
        f"Files scanned: {len(scanned)}",
        f"GL function names: {len(calls)}",
        f"GL constants: {len(constants)}", "",
        "This is a raw source inventory, not a GLES compatibility verdict.", "",
        "## GL function calls", "",
    ]
    for name, sites in sorted(calls.items()):
        lines.append(f"- {name} — {len(sites)} site(s): " + ", ".join(sites[:8]))
    lines += ["", "## GL constants", ""]
    for name, sites in sorted(constants.items()):
        lines.append(f"- {name} — {len(sites)} site(s): " + ", ".join(sites[:5]))
    lines += ["", "## Shader version directives", ""]
    for item in shaders:
        lines.append(f"- {item['file']}:{item['line']} — version {item['version']} {item['profile']}")
    markdown = "\n".join(lines) + "\n"
    if args.markdown:
        args.markdown.parent.mkdir(parents=True, exist_ok=True)
        args.markdown.write_text(markdown, encoding="utf-8")
    else:
        print(markdown)
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
