# Porting status

| Area | Status | Notes |
|---|---|---|
| Upstream fork baseline | Ready | Original source tree preserved on main |
| H700 project branch | Ready | Isolated on h700/porting |
| EGL/GLES probe | Built | Host test and AArch64 cross-build pass |
| muOS Andromeda launcher | Packaged | Application Runner layout and ZIP integrity verified |
| Device inventory | Packaged | CPU serial line redacted |
| Upstream GL API inventory | Added | Python tool; manual GLES classification still required |
| AArch64 ABI | Verified | ELF64 AArch64, GLIBC_2.17 maximum |
| Diagnostic .muxapp | Published | GitHub Actions artifact available |
| Physical H700 run | Pending | Device report not yet collected |
| SDL window / EGL presentation | Pending | Current probe uses a pbuffer, not the game window |
| GLES renderer | Not started | Desktop GL 4.1 / GLSL 4.10 assumptions need adaptation |
| Game runtime on H700 | Not available | No playable build yet |

## Latest verified build

- CI run: [43301695175](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions/runs/43301695175)
- Artifact: `twinsanity-rintromped-h700-preflight`
- Package: `Twinsanity-Rintromped-H700-Preflight.muxapp`
- AArch64 executable: `tw-rintromped-h700-probe`
- ELF: 64-bit AArch64, dynamic loader `/lib/ld-linux-aarch64.so.1`
- Maximum required GLIBC symbol: `GLIBC_2.17`
- SHA-256 of the extracted `.muxapp`: `5426cbaea51c246fd976d98f8743fda9c3c08396d18b67ae408d6a51221c2828`

## Verified upstream constraints

- Desktop Linux requests an OpenGL 4.1 core context.
- The common GL backend uses desktop APIs including mapped buffers and sync objects.
- The Vita implementation uses vitaGL/GXM-specific code and is not the H700 GLES backend.
- H700 target work must use EGL + OpenGL ES and verify extensions on the device.

## Next sequence

1. Install and run the diagnostic package on muOS Andromeda.
2. Retrieve both reports from `MUOS/application/TwinsanityRintromped/logs/`.
3. Build a dedicated SDL + EGL window/present test using the firmware's actual video backend.
4. Classify all GL calls, constants and shader features against the reported GLES version/extensions.
5. Add tested GLES adapters or renderer changes, then bring up the smallest engine scene before full gameplay.
