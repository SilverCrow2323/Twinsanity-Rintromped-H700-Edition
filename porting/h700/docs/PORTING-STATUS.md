# Porting status

| Area | Status | Notes |
|---|---|---|
| Upstream fork baseline | Ready | Original source tree preserved |
| H700 project scaffold | In progress | Isolated on `h700/porting` |
| EGL/GLES inventory | Prepared | Must be run on the target device |
| AArch64 probe build | Pending | Cross-compiler + ABI verification |
| muOS diagnostic package | Scaffolded | Not a game build |
| SDL window / EGL presentation | Pending | Must test the firmware's actual display path |
| GLES renderer | Not started | Desktop GL 4.1 assumptions need systematic adaptation |
| Game runtime on H700 | Not available | No playable port yet |

## Critical upstream findings

- Desktop Linux requests an OpenGL 4.1 core context.
- The common GL backend uses desktop APIs such as buffer mapping and sync objects.
- The PS Vita implementation uses vitaGL/GXM-specific code; it is not the GLES implementation for H700.
- H700 target work must use EGL + OpenGL ES and verify extensions on the device, not assume support from GPU model alone.

## Next sequence

1. Run the preflight probe on muOS Andromeda and retrieve its report.
2. Build an SDL + EGL presentation test and confirm swap/present.
3. Inventory every GL entry point and shader feature used by the upstream renderer.
4. Add GLES equivalents or safe fallback paths.
5. Bring up the engine with the smallest possible scene before attempting full gameplay.
