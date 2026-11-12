![H700 graphics port](h700/assets/hero.svg)

# H700 renderer audit

## Purpose

Record the source-level gaps between the upstream desktop renderer and the H700 GLES 3.2 environment, and keep every compatibility decision tied to an evidence level.

## ✅ Physical graphics evidence

The tested muOS 2606.0 H700 device reports:

| Layer | Result |
|---|---|
| EGL | 1.4 · ARM |
| GPU | Mali-G31 · Bifrost r20p0 |
| GLES | 3.2 |
| GLSL | ES 3.20 |
| SDL video backend | mali |
| Window presentation | Six visible colour-frame swaps |

This confirms the firmware graphics stack. It does not confirm NativeEE renderer compatibility or gameplay.

## Source-level desktop assumptions

| Area | Upstream implementation | H700 consequence |
|---|---|---|
| Build | Non-Vita Linux uses OpenGL::GL | Explicit PS2R_GLES profile and GLESv2 link path required |
| Header | GL/glcorearb.h | Select GLES3/gl32.h only for H700 profile |
| Context | SDL requests OpenGL 4.1 core | SDL must request ES 3.2 |
| Shader source | GLSL 410 core | Convert to GLSL ES 320 with precision declarations |
| Interpolation | noperspective on PS2 S/T/Q varying | Remove only on audited v_texcoord path; verify output |
| Uniform API | glProgramUniform* | Bind target program, use glUniform*, restore |
| Depth API | glClearDepth | Use glClearDepthf |
| Texture dimensions | glGetTexLevelParameteriv | Derive mip dimensions from surface descriptor |
| FBO state | glDrawBuffer | Use GLES glDrawBuffers |
| Buffer mapping | GL_MAP_UNSYNCHRONIZED_BIT | Omit unsupported desktop flag |

## Architecture changes in the H700 branch

- PS2R_GLES is explicitly selected by the root application and forwarded to the NativeEE ExternalProject.
- The root and engine CMake projects share GLES include and library paths.
- NativeEE selects GLES3/gl32.h and SDL ES context attributes only in the H700 profile.
- The root application links the imported GLESv2 target instead of finding desktop OpenGL.
- The shader adapter rewrites the audited GLSL source profile and inserts highp defaults.
- Uniform writes use a temporary program bind on GLES.
- The desktop-only timer query census is disabled in the initial GLES profile.

## Compatibility decisions that still need validation

Read the living [API compatibility matrix](h700/compatibility-matrix.md) for the full classification. Important remaining areas include FBO formats, mip-chain readback, stencil-only targets, sampler behavior, buffer synchronization, texture formats, shader variants and frame capture comparison.

## Build evidence boundaries

| Evidence | What it proves |
|---|---|
| Source guard | Expected shader conversion rules remain present |
| Header compile | Selected renderer units compile against GLES headers |
| Link test | Required target symbols resolve against the real sysroot |
| Device API test | Actual Mali driver accepts the operations |
| Image comparison | Renderer output matches a known reference |
| Gameplay test | The real game reaches and runs a scene |

No stronger claim should be made than the highest evidence level actually achieved.

## References

- [GLSL ES 3.20 specification](https://registry.khronos.org/OpenGL/specs/es/3.2/GLSL_ES_Specification_3.20.html)
- [ARM Mali-G31](https://support.arm.com/compute-ip/mali-g31)
- [Allwinner H700 brief](https://www.allwinnertech.com/uploads/pdf/2021070513595227.pdf)
- [Detailed GLES compatibility matrix](h700/compatibility-matrix.md)
