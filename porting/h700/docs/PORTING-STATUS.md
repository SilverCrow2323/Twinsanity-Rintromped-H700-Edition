# Porting status

| Area | Status | Notes |
|---|---|---|
| Upstream fork baseline | Ready | Original source tree preserved on main |
| H700 project branch | Ready | Isolated on h700/porting |
| EGL/GLES probe source | Added | Host compilation and report smoke test pass |
| muOS Andromeda launcher | Added | Checked against official Application Runner contract |
| Device inventory | Added | Redacts CPU serial line |
| Upstream GL API inventory | Added | Python tool; classifies nothing automatically |
| AArch64 build/package CI | Configured | Awaiting first GitHub Actions run |
| Physical H700 run | Pending | Device report not yet collected |
| SDL window / EGL presentation | Pending | The probe uses a small pbuffer, not the game window |
| GLES renderer | Not started | Desktop GL 4.1 / GLSL 4.10 assumptions need adaptation |
| Game runtime on H700 | Not available | No playable build |

## Verified upstream constraints

- Desktop Linux requests an OpenGL 4.1 core context.
- The common GL backend uses desktop APIs including mapped buffers and sync objects.
- The Vita implementation uses vitaGL/GXM-specific code and is not the H700 GLES backend.
- H700 target work must use EGL + OpenGL ES and verify extensions on the device.

## Next sequence

1. Run the diagnostic package on muOS Andromeda and retrieve both text reports.
2. Build a dedicated SDL + EGL window/present test using the firmware's actual video backend.
3. Run the GL API inventory against the exact pinned upstream checkout.
4. Classify all GL calls, constants and shader features against the reported GLES version/extensions.
5. Add tested GLES adapters or renderer changes, then bring up the smallest engine scene before full gameplay.
