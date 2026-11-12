# Porting status

| Area | Status | Notes |
|---|---|---|
| Upstream fork baseline | Ready | Original source tree preserved on main |
| H700 project branch | Ready | Isolated on h700/porting |
| EGL/GLES probe | Device PASS | EGL 1.4; GLES 3.2 context on Mali-G31 |
| SDL window / GLES context / buffer swap probe | Device PASS | SDL video driver mali; six colour frames swapped successfully |
| muOS Andromeda launcher | Packaged | Application Runner layout and ZIP integrity checked |
| Device inventory | Collected | muOS 2606.0, sun50iw9, kernel 4.9.170, framebuffer 640×480 |
| Upstream GL API inventory | Added | Raw inventory only; manual GLES classification required |
| AArch64 ABI | Checked | ELF64 AArch64; GLIBC baseline checked for both probes |
| Diagnostic muxapp | CI artefact | Contains both probes; use latest successful branch workflow |
| Physical H700 graphics preflight | PASS | EGL, GLES 3.2, SDL window creation and presentation confirmed |
| Full GLES renderer | Not started | Desktop GL 4.1 / GLSL 4.10 assumptions need adaptation |
| Game runtime on H700 | Not available | No playable build yet |

## Confirmed device profile

- muOS 2606.0 Andromeda, build `db2a3bd0`.
- Allwinner `sun50iw9`, AArch64, four CPU cores.
- ARM Mali-G31, Bifrost `r20p0`, GPU frequency reported as 816 MHz at test time.
- EGL 1.4 / ARM vendor.
- OpenGL ES 3.2 / GLSL ES 3.20.
- SDL2 video backend: `mali`; SDL window, ES context and buffer swaps pass.
- Display mode: 640×480p-59.
- Approximately 1 GB RAM.

## Latest build

- Workflow: [H700 branch Actions runs](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions?query=branch%3Ah700%2Fporting)
- Artifact: twinsanity-rintromped-h700-preflight
- Package: Twinsanity-Rintromped-H700-Preflight.muxapp
- Probe binaries: tw-rintromped-h700-probe and tw-rintromped-h700-sdl-probe
- The workflow checks ELF64/AArch64 and the maximum GLIBC symbol for both binaries and verifies the nested archive layout.

## Renderer constraints

- Desktop Linux requests an OpenGL 4.1 core context.
- The shared GL backend uses desktop APIs including mapped buffers and sync objects.
- Shader source includes GLSL 4.10 and the noperspective qualifier; inspect semantics before converting to GLSL ES.
- The Vita implementation uses vitaGL/GXM-specific code and is not the H700 GLES backend.
- The hardware preflight proves SDL presentation, not game renderer compatibility.

## Next sequence

1. Add a dedicated H700 platform/build option and dependency path for SDL2 + EGL + GLESv2.
2. Prototype one minimal GLES shader, vertex/index buffer and framebuffer path on the Mali-G31.
3. Generate a complete GL call/constant/shader inventory and classify each item against GLES 3.2 and the reported extensions.
4. Convert the engine shader pipeline to GLSL ES with targeted fixes, not global string substitutions.
5. Bring up the smallest engine scene; only then proceed to game ISO loading, input/audio and performance work.
