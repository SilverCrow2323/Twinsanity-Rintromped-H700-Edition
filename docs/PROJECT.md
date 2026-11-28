# Project: TwinsanityEvolved — H700 handheld port

## Purpose
Maintain the multi-platform TwinsanityEvolved port and its platform-specific packaging, including a separate experimental Allwinner H700/muOS target, without regressing Windows, macOS, Linux desktop or the native PS Vita target.

## Users and use cases
- Players using a legally obtained game disc/image with a supported desktop, Vita or handheld build.
- Maintainers building the decompilation/engine, native packages and launcher.
- H700 testers collecting renderer, input, audio, storage and performance evidence.

## Scope and boundaries
In scope: game decompilation and engine code, desktop/Vita targets, Linux AArch64 build, H700 renderer/platform preflight, launcher, package verification and asset-safety gates.

Out of scope: redistributing game disc data, ROMs, saves or copyrighted assets; treating a Linux AArch64 compile as H700 compatibility; and treating emulator/CI evidence as a physical handheld test. The H700 port is a separate platform target and must not weaken existing desktop/Vita behavior.

## Targets
- Windows, macOS and Linux desktop.
- Native PS Vita package.
- Experimental muOS/H700 AArch64 target using the actual firmware's SDL/EGL/GLES path.
- Host-side unit/integration tests and physical-device qualification are separate.

## Architecture
- Engine/decompilation and platform-neutral game logic.
- Desktop renderer and native Vita backend.
- H700 preflight: EGL/GLES pbuffer, SDL context/swap, input/audio/storage probes.
- Launcher and platform package manifests.
- Asset scanner and no-game-data release guard.
- Test fixtures and replayable input/session evidence.

## Dependencies and provenance
Upstream engine/decompilation sources, SDL2, EGL/GLES, platform-specific audio/input APIs, VitaSDK and per-platform toolchains. Toolchain and binary inputs must be pinned; no game data is part of the repository's distributable payload.

## Safety and evidence policy
The asset scanner must reject disc images, PS2 executables, game archives, textures/audio/video and save files. Automated host checks are reported as automated. Only a dated physical H700 test record with device/firmware and logs can establish hardware behavior.

## Verified baseline
The repository contains extensive engine tests, desktop/Vita packaging, a Linux AArch64 archive and H700 diagnostic preflight executables. The H700 porting plan explicitly states that no physical H700 validation is recorded yet.
