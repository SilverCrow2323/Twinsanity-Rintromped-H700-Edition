#!/usr/bin/env python3
"""Source-level guards for the H700 GLES 3.2 build and shader contracts."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
SHADERS = ROOT / "engine/engine/render/backends/gl/gl_shader_sources.cpp"
ADAPTER = ROOT / "engine/engine/render/backends/gl/gl_shader_library.cpp"
TOP_CMAKE = ROOT / "CMakeLists.txt"
ENGINE_CMAKE = ROOT / "engine/CMakeLists.txt"
GL_DEPENDENCY = ROOT / "engine/cmake/OpenGlDependency.cmake"
SDL_CONTEXT = ROOT / "engine/engine/platform/sdl/gl_context.cpp"

RAW = re.compile(r'R"([A-Za-z0-9_]*)\((.*?)\)\1"', re.DOTALL)
VERSION = re.compile(r"^\s*#version\s+(\d+)\s+(\w+)\s*$", re.MULTILINE)
NOPERSPECTIVE = re.compile(r"\bnoperspective\s+(?:in|out)\s+vec3\s+(\w+)\s*;")


def require_tokens(path: Path, tokens: tuple[str, ...], label: str) -> None:
    source = path.read_text(encoding="utf-8")
    missing = [token for token in tokens if token not in source]
    if missing:
        raise SystemExit(f"FAIL: {label} missing required contract(s): " + ", ".join(missing))


def main() -> int:
    # The top-level runner and the NativeEE ExternalProject must select the
    # same GL header family. A correct engine-only define is not sufficient.
    require_tokens(TOP_CMAKE, (
        'option(PS2R_GLES ',
        "add_compile_definitions(PS2R_USE_GLES=1)",
        "list(APPEND TE_ENGINE_FORWARDED_ARGS -DPS2R_GLES=ON)",
    ), "top-level H700 CMake profile")
    require_tokens(ENGINE_CMAKE, (
        'option(PS2R_GLES ',
        "add_compile_definitions(PS2R_USE_GLES=1)",
    ), "NativeEE GLES CMake profile")
    require_tokens(GL_DEPENDENCY, (
        "find_path(PS2R_GLES_INCLUDE_DIR NAMES GLES3/gl32.h)",
        "find_library(PS2R_GLES_LIBRARY NAMES GLESv2)",
        "INTERFACE_LINK_LIBRARIES",
    ), "GLES dependency mapping")
    require_tokens(SDL_CONTEXT, (
        "SDL_GL_CONTEXT_PROFILE_ES",
        "GL_MAJOR_VERSION",
        "GL_MINOR_VERSION",
        "PS2R_HOST_GLES",
    ), "SDL ES context and version gate")

    shader_text = SHADERS.read_text(encoding="utf-8")
    adapter_text = ADAPTER.read_text(encoding="utf-8")
    # Shader library also owns the inline movie-YUV fragment shader. Audit it
    # alongside the larger central source catalogue so no embedded variant is missed.
    inline_sources = [m.group(2) for m in RAW.finditer(adapter_text)]
    sources = [m.group(2) for m in RAW.finditer(shader_text)] + inline_sources
    shader_sources = [s for s in sources if re.search(r"^\s*#version\s+410\s+core\s*$", s, re.MULTILINE)]
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

    print("PASS: top-level app and NativeEE both select the H700 GLES header profile")
    print("PASS: GLESv2 dependency and SDL ES 3.2 version gate are present")
    print(f"PASS: {converted} embedded GLSL source block(s) satisfy the H700 ES 3.20 conversion contract")
    print("PASS: only the audited v_texcoord noperspective declaration is permitted")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
