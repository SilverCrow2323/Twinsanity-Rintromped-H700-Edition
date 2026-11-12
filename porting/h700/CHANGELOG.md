# Changelog

## 0.2.1-dev

- Added an EGL/OpenGL ES preflight executable for H700 firmware runtimes.
- Added a muOS Andromeda Application Runner launcher and device inventory script.
- Added AArch64 cross-build, GLIBC inspection, diagnostic muxapp packaging and host-side safety tests.
- Added an upstream GL API inventory and ABI/release inspection helpers.
- Added a CI workflow that successfully builds and uploads the first AArch64 diagnostic `.muxapp`.
- Verified the diagnostic ELF as AArch64 with GLIBC_2.17 maximum and verified the nested muOS archive layout.
- Renderer porting, physical-device validation and gameplay remain pending.
