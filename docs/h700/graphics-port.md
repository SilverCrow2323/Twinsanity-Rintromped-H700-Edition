# Graphics port

## Why a separate backend profile?

The upstream Linux renderer asks SDL for a desktop OpenGL 4.1 core context and includes desktop GL headers. The H700 device exposes OpenGL ES 3.2 through EGL and SDL's mali video driver.

The H700 work therefore adds a **dedicated GLES build profile**. It does not replace the desktop dependency globally and does not reuse the Vita renderer path.

## Runtime path

~~~mermaid
flowchart TD
    A["SDL video subsystem"] --> B["SDL mali driver"]
    B --> C["EGL display and context"]
    C --> D["GLES 3.2 API"]
    D --> E["NativeEE GL backend · GLES compile profile"]
    E --> F["PS2 GS emulation surfaces"]
    F --> G["SDL_GL_SwapWindow"]
~~~

The lower three engine stages are the integration target. The physical device has confirmed the SDL, EGL and GLES layers only.

## Compatibility work introduced

| Desktop assumption | GLES adaptation | State |
|---|---|---|
| GL/glcorearb.h | GLES3/gl32.h selected by PS2R_USE_GLES | Added |
| OpenGL 4.1 core context | SDL ES 3.2 attributes | Added |
| GLSL 410 core | GLSL ES 320 plus default high precision | Added |
| noperspective on PS2 STQ varying | Remove only on v_texcoord; vertex path sets gl_Position.w = 1 | Added; visual equivalence still to verify |
| glProgramUniform* | Temporarily bind target program and use glUniform* | Added; correctness-first, not yet optimized |
| glClearDepth | glClearDepthf | Added |
| glGetTexLevelParameteriv | Derive mip dimensions from base dimensions and level | Added |
| glDrawBuffer(GL_NONE) | glDrawBuffers(1, { GL_NONE }) | Added |
| GL_MAP_UNSYNCHRONIZED_BIT | Omit for GLES; keep write + explicit-flush flags | Added |
| Desktop timer-query path | Disabled in initial GLES profile | Deliberate first-stage fallback |

## Shader conversion policy

The shared shader sources remain in their original desktop form. The H700 profile converts them at compile time:

1. Require the audited source directive #version 410 core.
2. Rewrite it to #version 320 es.
3. Insert highp float and int default precision declarations immediately after the version directive.
4. Remove noperspective only from the v_texcoord varying declaration.

Why is the last change narrow? The PS2 vertex shader constructs gl_Position with w = 1.0 in this path. Smooth interpolation therefore reduces to screen-linear interpolation for this varying. This is a source-level equivalence argument; capture comparisons on the actual game renderer remain mandatory.

No global shader substitution is permitted. New shader features must be checked for GLES 3.2 semantics before being added to the shared source.

## Current technical risks

<details>
<summary>Uniform update cost</summary>

GLES 3.2 does not provide the desktop glProgramUniform entry points as core API. The initial adapter switches the active program around uniform updates. This preserves the explicit-program semantics but may be expensive. A later optimization should batch updates while the intended program is bound and maintain strict state-cache coherence.

</details>

<details>
<summary>Buffer streaming and synchronization</summary>

The Mali driver advertises mapping and buffer-storage extensions. The first adapter uses GLES core mapping flags and removes the desktop-only unsynchronized flag. Correctness and frame pacing still need device measurements. The extension list alone is not a reason to enable a faster path.

</details>

<details>
<summary>Texture readback and framebuffer formats</summary>

The mip-tail synthesis path previously queried texture level dimensions through desktop GL. The GLES path now derives the dimensions from the surface description. FBO completeness, depth/stencil formats, readback alignment and texture filtering need integration tests with real game surfaces.

</details>

<details>
<summary>Timer queries</summary>

GL_EXT_disjoint_timer_query is present on the tested device, but its API names and disjoint-timer rules differ from the desktop timer path. The first GLES profile disables the desktop query implementation rather than risking invalid calls. A GLES-specific timing adapter can follow once rendering is stable.

</details>

## Acceptance criteria for the first renderer milestone

- All GL backend and SDL platform translation units compile against GLES 3.2 headers for AArch64.
- The H700 build requests an ES 3.2 context and verifies the returned API.
- All engine shader variants compile on the device.
- A deterministic test surface is drawn, read back and compared against a desktop reference.
- The first NativeEE-rendered frame is visible on the panel.
- No regression is introduced in desktop, Windows or Vita CI.

Passing the compile gate is not equivalent to passing the shader, image or gameplay tests.
