# Porting status

| Area | Status | Notes |
|---|---|---|
| Upstream fork baseline | Ready | Original source tree preserved on main |
| H700 project branch | Ready | Isolated on h700/porting |
| EGL/GLES probe | Built | Host test and AArch64 cross-build |
| SDL window / GLES context / buffer swap probe | Built | Physical panel result still pending |
| muOS Andromeda launcher | Packaged | Application Runner layout and ZIP integrity checked |
| Device inventory | Packaged | CPU serial line redacted |
| Upstream GL API inventory | Added | Raw inventory only; manual GLES classification required |
| AArch64 ABI | Checked | ELF64 AArch64; GLIBC baseline checked for both probes |
| Diagnostic muxapp | CI artefact | Contains both probes; use latest successful branch workflow |
| Physical H700 run | Pending | Device reports not yet collected |
| Full GLES renderer | Not started | Desktop GL 4.1 / GLSL 4.10 assumptions need adaptation |
| Game runtime on H700 | Not available | No playable build yet |

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
- A successful pbuffer or SDL window probe is not a game renderer compatibility result.

## Next sequence

1. Run the package on muOS Andromeda and collect all three reports.
2. Record the actual SDL video driver and GLES vendor/renderer/version/extensions.
3. Classify the GL calls and shader features against the reported GLES implementation.
4. Prototype the minimum game-renderer shader path and compare captures against desktop output.
5. Add the remaining GLES adapters, then bring up the smallest engine scene before full gameplay.
