# Supported platforms

Choose the package that explicitly matches your system. CPU architecture alone does not prove that the graphics driver, display stack or input path is compatible.

## 🧩 Current release targets

| Platform | Architecture / package | Notes |
|---|---|---|
| Windows | x64 | Desktop build |
| macOS | Apple silicon arm64 | Desktop build |
| macOS | x86_64 | Desktop build |
| Linux | x86_64 | Desktop build |
| Linux | AArch64 | Linux build; not an H700 compatibility promise |
| PlayStation Vita | Native Vita package / VPK | Separate native console target |

The launcher is published for Windows, macOS and Linux desktop systems. Always check the actual release asset and its notes.

## 🎮 H700 handhelds

<blockquote>
<strong>Hardware graphics preflight: PASS.</strong> One physical muOS Andromeda H700 device created an EGL 1.4 display, a GLES 3.2 context and an SDL window through the mali video driver.

<strong>Game compatibility: not yet validated.</strong> The real NativeEE renderer and gameplay are still being ported.
</blockquote>

The H700 requires a dedicated GLES and firmware path. Do not install a desktop AArch64 archive expecting it to work as a handheld build.

See [H700 port status](H700-port-status) for the tested device profile and outstanding milestones.

## 🖼️ Graphics requirements

The current desktop release notes specify OpenGL 4.1. The H700's Mali-G31 uses OpenGL ES 3.2; these APIs are not interchangeable. A dedicated renderer port and device testing are required.

## How to check a release

1. Match the operating system and CPU architecture.
2. Read the documented graphics requirements.
3. Check the release notes and package contents.
4. For handheld targets, look for device-specific validation rather than only a successful cross-compile.
