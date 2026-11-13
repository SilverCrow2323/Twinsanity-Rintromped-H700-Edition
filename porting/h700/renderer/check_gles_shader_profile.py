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
SHADER_SMOKE = ROOT / "porting/h700/renderer/shader_smoke.cpp"
SHADER_CMAKE = ROOT / "porting/h700/renderer/CMakeLists.txt"
PACKAGE_SCRIPT = ROOT / "porting/h700/scripts/package-muxapp.sh"
LAUNCHER = ROOT / "porting/h700/muos/TwinsanityRintromped/mux_launch.sh"
WORKFLOW = ROOT / ".github/workflows/rintromped-h700.yml"
FULL_APP_TOOLCHAIN = ROOT / "porting/h700/toolchains/aarch64-linux-gnu.cmake"
FULL_APP_FFMPEG = ROOT / "porting/h700/scripts/build-ffmpeg-static.sh"
FULL_APP_PACKAGER = ROOT / "porting/h700/scripts/package-full-muxapp.sh"
FFMPEG_RECIPE = ROOT / "engine/tools/ci/ffmpeg_static.sh"
FETCH_TOOLCHAIN = ROOT / "tools/fetch_toolchain.sh"

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
        "FFmpeg::avcodec FFmpeg::swscale FFmpeg::avutil m pthread",
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

    # The device package must execute the actual NativeEE shader library, not
    # merely an EGL clear demo or a host-only compile target.
    require_tokens(SHADER_SMOKE, (
        "shaders.Build(uniforms)",
        "shaders.Ps2Program()",
        "shaders.ScanoutProgram()",
        "shaders.ScanoutDitherProgram()",
        "shaders.StencilStripProgram()",
        "shaders.StencilInvertProgram()",
        "shaders.ConstProgram()",
        "shaders.OpaqueMaskProgram()",
        "GLES 3.2",
    ), "NativeEE production shader smoke")
    require_tokens(SHADER_CMAKE, (
        "h700_gles_shader_smoke",
        "gl_shader_library.cpp",
        "gl_shader_sources.cpp",
        "gl_uniform_cache.cpp",
        "EGL_LIBRARY",
        "GLES_LIBRARY",
    ), "production shader smoke build target")
    require_tokens(PACKAGE_SCRIPT, (
        "tw-rintromped-h700-gles-shader-smoke",
        "TwinsanityRintromped/tw-rintromped-h700-gles-shader-smoke",
    ), "device package contents")
    require_tokens(LAUNCHER, (
        "tw-rintromped-h700-gles-shader-smoke",
        "gles-shader-report.txt",
        "SHADER_RC",
        "twinsanityevolved",
        "disc-image.txt",
        "game.iso",
        'SDL_VIDEODRIVER="${SDL_VIDEODRIVER:-mali}"',
        'exec "$APP_DIR/$GAME_BIN"',
    ), "device game/preflight launcher and ISO-preserving hand-off")
    require_tokens(WORKFLOW, (
        "dpkg --add-architecture arm64",
        "libegl1-mesa-dev:arm64",
        "libgles2-mesa-dev:arm64",
        "h700_gles_shader_smoke",
        "tw-rintromped-h700-gles-shader-smoke",
    ), "AArch64 production shader package gate")

    require_tokens(FULL_APP_TOOLCHAIN, (
        "set(CMAKE_SYSTEM_NAME Linux)",
        "set(CMAKE_SYSTEM_PROCESSOR aarch64)",
        "aarch64-linux-gnu-gcc",
        "aarch64-linux-gnu-g++",
        "CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY",
    ), "full application AArch64 toolchain")
    require_tokens(FULL_APP_FFMPEG, (
        "FFMPEG_JOBS",
        "ffmpeg-6.1.2.tar.xz",
        "3b624649725ecdc565c903ca6643d41f33bd49239922e45c9b1442c63dca4e38",
        "--enable-cross-compile",
        "--arch=aarch64",
        "--target-os=linux",
        "FFmpeg-COPYING.LGPLv2.1.txt",
        "FFmpeg-BUILD-CONFIGURATION.txt",
        "ff_mpeg2video_decoder",
        "FFmpeg-COPYING.LGPLv2.1.txt",
        "FFmpeg-BUILD-CONFIGURATION.txt",
    ), "pinned static LGPL FFmpeg AArch64 builder")
    require_tokens(FFMPEG_RECIPE, (
        "--disable-gpl",
        "--disable-nonfree",
        "--disable-version3",
        "--enable-decoder=mpeg2video",
        "--enable-decoder=mpeg1video",
        "--enable-parser=mpegvideo",
        "--enable-static",
        "--disable-shared",
    ), "shared minimal LGPL FFmpeg feature recipe")
    require_tokens(FULL_APP_PACKAGER, (
        "twinsanityevolved",
        "PK\\x03\\x04",
        "AArch64",
        "GLIBC_2.31",
        "libav(codec|util|swscale)",
        "licenses/FFmpeg-COPYING.LGPLv2.1.txt",
        "licenses/FFmpeg-BUILD-CONFIGURATION.txt",
        "game.iso",
        "disc-image.txt",
        'zip -X -qr "$TMP_ARCHIVE" TwinsanityRintromped',
        'mv -f "$TMP_ARCHIVE" "$OUT_ABS"',
    ), "full installable game muxapp packager")
    require_tokens(WORKFLOW, (
        "full-app-aarch64-link:",
        "tools/fetch_toolchain.sh",
        "FFMPEG_JOBS=2 bash porting/h700/scripts/build-ffmpeg-static.sh",
        "-DPS2R_GLES=ON",
        "-DFFMPEG_AVCODEC_LIBRARY=/src/build/h700-full-aarch64/third_party/ffmpeg/lib/libavcodec.a",
        "-DFFMPEG_AVUTIL_LIBRARY=/src/build/h700-full-aarch64/third_party/ffmpeg/lib/libavutil.a",
        "-DFFMPEG_SWSCALE_LIBRARY=/src/build/h700-full-aarch64/third_party/ffmpeg/lib/libswscale.a",
        "build/h700-full-aarch64 --target twinsanityevolved",
        "FFmpeg must be statically linked for muOS",
        "full-app-muxapp:",
        "twinsanity-rintromped-h700-full-runner",
        "twinsanity-rintromped-h700-full-muxapp",
        "package-full-muxapp.sh",
    ), "full application static-FFmpeg build and game muxapp gate")
    require_tokens(FETCH_TOOLCHAIN, (
        'WABT_FROM_SOURCE="${WABT_FROM_SOURCE:-0}"',
        'WABT_TGZ="wabt-${WABT_VERSION}.tar.xz"',
        'cmake --build "$DEST/wabt.tmp/build" --target wasm2c wasm-objdump wasm-validate',
    ), "pinned WABT source-build option")
    require_tokens(WORKFLOW, (
        "WABT_FROM_SOURCE=1 ./tools/fetch_toolchain.sh",
        "ninja-build g++",
    ), "Bullseye-native WABT build dependencies")
    workflow_lines = WORKFLOW.read_text(encoding="utf-8").splitlines()
    full_job_start = next(i for i, line in enumerate(workflow_lines)
                          if line.strip() == "full-app-aarch64-link:")
    malformed = [i + 1 for i, line in enumerate(workflow_lines[full_job_start:], full_job_start)
                 if re.search(r"\\{2,}$", line)]
    if malformed:
        raise SystemExit("FAIL: full-app workflow has doubled shell continuations on lines "
                         + ", ".join(map(str, malformed)))

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
    print("PASS: NativeEE production shader smoke cross-build, package and launcher wiring is present")
    print(f"PASS: {converted} embedded GLSL source block(s) satisfy the H700 ES 3.20 conversion contract")
    print("PASS: only the audited v_texcoord noperspective declaration is permitted")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
