# H700 porting status

**Physical graphics preflight: PASS. NativeEE renderer integration: in progress. Playable port: not available.**

## Current status

| Area | Status | Evidence |
|---|---|---|
| Upstream baseline | Ready | Original baseline remains on main |
| H700 branch | Active | h700/porting |
| EGL / GLES | <strong>Device PASS</strong> | EGL 1.4, ES 3.2, Mali-G31 |
| SDL window / buffer swaps | <strong>Device PASS</strong> | mali backend; six visible colour frames |
| muOS diagnostic package | Packaged | AArch64 probes and corrected archive root |
| Device inventory | Collected | muOS 2606.0, sun50iw9, kernel 4.9.170 |
| Root CMake H700 profile | Added | PS2R_GLES forwarded to NativeEE ExternalProject |
| GLES header / dependency path | Added | GLES3/gl32.h and GLESv2 target |
| SDL context selection | Added | Requests ES 3.2 and rejects lower returned versions |
| Shader conversion adapter | Added | GLSL 410 core to ES 320, audited source guard |
| GLES API adapters | Added | Uniforms, depth clear, mip dimensions, draw buffers, map flags |
| Renderer compile gate | CI validation | AArch64 object compile against GLES and SDL headers |
| Production shader smoke | Added | Real GlShaderLibrary EGL/GLES test; Mesa CI bring-up |
| First NativeEE frame | Pending | Must pass compile, device shader and surface tests |
| Game runtime | Not available | No playable build yet |

## Device profile

- muOS 2606.0 Andromeda, build db2a3bd0.
- Allwinner sun50iw9, AArch64, four cores; approximately 1 GB RAM.
- ARM Mali-G31, Bifrost r20p0.
- EGL 1.4 / OpenGL ES 3.2 / GLSL ES 3.20.
- SDL2 video driver: mali.
- Framebuffer mode: 640×480p-59.
- The GPU frequency reported during collection was 816 MHz; it is not a guaranteed fixed clock.

## Latest CI lanes

- [H700 build workflow](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions/workflows/rintromped-h700.yml)
- [Wiki and documentation validation](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions/workflows/wiki-docs.yml)

The renderer job is a compile-only gate. A green job would prove that the selected translation units compile against GLES headers; it would not prove target linking, shader execution, image correctness or gameplay.

## Next gates

1. Complete the AArch64 GLES compile gate and fix every real source/API failure.
2. Configure and link NativeEE plus the application against the muOS target sysroot.
3. Run every production shader variant on the actual Mali driver.
4. Validate the GS render targets, depth/stencil attachments, texture paths and readback.
5. Present the first NativeEE-rendered frame.
6. Only then begin game boot, input/audio, disc streaming and performance work.

## Canonical documentation

- [Project documentation hub](../../../docs/h700/README.md)
- [Graphics port](../../../docs/h700/graphics-port.md)
- [GLES compatibility matrix](../../../docs/h700/compatibility-matrix.md)
- [Build guide](../../../docs/h700/building.md)
- [Porting roadmap](../../../docs/h700/roadmap.md)
