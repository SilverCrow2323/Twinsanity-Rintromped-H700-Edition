# Device profile

<blockquote>
<strong>Source: physical device reports supplied on 12 November 2026.</strong>
Values below describe one tested muOS H700 unit, not every handheld sold with an H700 SoC.
</blockquote>

## System

| Property | Observed value |
|---|---|
| OS | MustardOS / muOS 2606.0 (Andromeda) |
| Build ID | db2a3bd0 |
| Kernel | Linux 4.9.170 |
| Device-tree model | sun50iw9 |
| CPU architecture | AArch64 |
| CPU cores | 4 |
| CPU part | 0xd03 (Cortex-A53 family) |
| Memory | approximately 1 GB |
| Framebuffer mode | 640×480p-59 |

## Graphics stack

| Layer | Device result |
|---|---|
| EGL | 1.4 |
| EGL vendor | ARM |
| EGL runtime | Bifrost r20p0-01rel0 |
| GPU | Mali-G31 |
| OpenGL ES | 3.2 |
| GLSL ES | 3.20 |
| SDL2 video driver | mali |
| SDL window | Created |
| Buffer presentation | Six colour frames swapped successfully |

## Reported limits

| Limit | Value |
|---|---:|
| Maximum texture size | 8192 |
| Maximum vertex attributes | 16 |
| Maximum fragment texture image units | 16 |
| GPU frequency at collection time | 816 MHz |

GPU frequency is a runtime measurement and must not be treated as a fixed clock guarantee.

## Useful extensions observed

The device advertised, among others:

- Buffer streaming: GL_OES_mapbuffer, GL_EXT_buffer_storage
- Vertex arrays: GL_OES_vertex_array_object
- Texture storage: GL_EXT_texture_storage
- Render targets: GL_EXT_color_buffer_float, GL_EXT_color_buffer_half_float
- Timer measurements: GL_EXT_disjoint_timer_query
- Texture compression: ASTC LDR / HDR families
- Base-vertex drawing: GL_EXT_draw_elements_base_vertex

An advertised extension is only a capability lead. Each function, format and synchronization rule still needs to be checked against the actual GLES specification and the driver.

## What the tests prove

<details>
<summary>✓ EGL / GLES pbuffer probe</summary>

The diagnostic process loaded the system EGL and GLES libraries, initialized EGL, created an ES 3.2 context and read the renderer, API version, shader language version, selected limits and extension list.

</details>

<details>
<summary>✓ SDL / GLES visible-window probe</summary>

SDL selected the mali video driver, created a window and an ES 3.2 context, then swapped six solid-colour frames. The user confirmed visible panel changes.

</details>

<details>
<summary>Not covered by these tests</summary>

The diagnostic does not compile the full engine renderer, execute the game's shader set, create NativeEE render targets, load the disc image or enter gameplay. Those are separate milestones.

</details>

## Reproduce the evidence

Install the diagnostic package using the [muOS installation guide](install.md). Retrieve the reports from:

~~~text
MUOS/application/TwinsanityRintromped/logs/
├── muos-device-report.txt
├── egl-gles-report.txt
└── sdl-window-report.txt
~~~

When comparing another handheld, retain the complete EGL/GLES extension list and the SDL video driver line. Those two details materially affect the backend decision.
