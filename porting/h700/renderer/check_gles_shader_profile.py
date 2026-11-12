#!/usr/bin/env python3
"""Source-level guard for the H700 GLSL ES 3.20 conversion contract."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
SHADERS = ROOT / "engine/engine/render/backends/gl/gl_shader_sources.cpp"
ADAPTER = ROOT / "engine/engine/render/backends/gl/gl_shader_library.cpp"

RAW = re.compile(r'R"([A-Za-z0-9_]*)\((.*?)\)\1"', re.DOTALL)
VERSION = re.compile(r"^\s*#version\s+(\d+)\s+(\w+)\s*$", re.MULTILINE)
NOPERSPECTIVE = re.compile(r"\bnoperspective\s+(?:in|out)\s+vec3\s+(\w+)\s*;")

def main() -> int:
    shader_text = SHADERS.read_text(encoding="utf-8")
    adapter_text = ADAPTER.read_text(encoding="utf-8")
    sources = [m.group(2) for m in RAW.finditer(shader_text)]
    shader_sources = [s for s in sources if "#version" in s]
    if not shader_sources:
        raise SystemExit("FAIL: no raw GLSL shader sources found")

    converted = 0
    for index, source in enumerate(shader_sources, 1):
        versions = VERSION.findall(source)
        if not versions or any(v != ("410", "core") for v in versions):
            raise SystemExit(f"FAIL: shader {index} does not match the audited #version 410 core profile")
        names = NOPERSPECTIVE.findall(source)
        if any(name != "v_texcoord" for name in names):
            raise SystemExit(f"FAIL: shader {index} contains an unaudited noperspective varying: {names}")
        result = re.sub(r"#version\s+410\s+core", "#version 320 es", source)
        result = re.sub(r"\bnoperspective(?=\s+(?:in|out)\s+vec3\s+v_texcoord\b)", "", result)
        result = re.sub(r"(#version 320 es\s*\n)",
                        r"\1precision highp float;\nprecision highp int;\n", result, count=1)
        if "#version 320 es" not in result:
            raise SystemExit(f"FAIL: shader {index} was not converted to GLSL ES 3.20")
        if "precision highp float;" not in result or "precision highp int;" not in result:
            raise SystemExit(f"FAIL: shader {index} is missing GLES default precision")
        if NOPERSPECTIVE.search(result):
            raise SystemExit(f"FAIL: shader {index} retains the audited noperspective qualifier")
        converted += 1

    required_adapter_tokens = (
        "std::string GlesGlsl",
        '#version 320 es',
        "precision highp float;",
        "precision highp int;",
        "PS2R_HOST_GLES",
    )
    missing = [token for token in required_adapter_tokens if token not in adapter_text]
    if missing:
        raise SystemExit("FAIL: C++ GLES shader adapter missing: " + ", ".join(missing))

    print(f"PASS: {converted} GLSL source block(s) satisfy the H700 ES 3.20 conversion contract")
    print("PASS: only the audited v_texcoord noperspective declaration is permitted")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
