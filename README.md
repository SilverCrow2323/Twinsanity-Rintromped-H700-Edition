# Twinsanity Evolved / H700 MuOS port

Native port of Crash Twinsanity: the [twinsanity-reversed](https://github.com/Smartkin/twinsanity-reversed)
decompilation (`game/`) running on the NativeEE engine (`engine/`).
The game is compiled to wasm32 and lowered to C with wasm2c; its linear memory is the engine's 32 MB main memory; the
decompilation's own `include/platform/*.h` is the only seam. On the PS Vita the game's code is compiled natively for the
console's ARM processor instead, with the same seam and the 32 MB as a block of the program. No game data of any kind is in
this repository — you need your own disc image, which is read at run time.

**Player field guide:** [Open the visual installation and usage manual](site/index.html), with real launcher screenshots, setup steps, configuration notes, mod workflows and troubleshooting. The GitHub Pages workflow publishes the `site/` directory when Pages is configured for Actions.

## Player documentation — MuOS only

The player-facing scope of this project is the Allwinner H700 handheld running **MuOS**. Installation, package handling, configuration, controls, save data and troubleshooting instructions are maintained in the [MuOS Field Guide](site/index.html).

- **Target:** Allwinner H700 handheld with MuOS.
- **Package:** install only a release explicitly labelled for MuOS/H700, following its exact instructions.
- **Game data:** the project does not distribute Crash Twinsanity disc images or copyrighted game assets.
- **Status:** the H700 preflight package is diagnostic, not a playable game build. Hardware acceptance is required before a playable/stable claim.
- **Evidence:** every accepted release must identify the tested device model, MuOS version, package checksum and completed hardware tests.

The MuOS player guide intentionally excludes desktop and unrelated handheld usage instructions. The engineering sections below may still mention build-system implementation details where needed by contributors; they are not alternative player targets.

## Build

```sh
git clone <this repository> && cd TwinsanityEvolved   # engine/ and game/ are in the tree: nothing else to fetch
tools/fetch_toolchain.sh                 # pinned wasi-sdk 24.0 + wabt 1.0.42 + libclang (sha256 in tools/toolchain/PINS.sha256)
cmake -S . -B build -G Ninja && cmake --build build
build/twinsanityevolved --iso "/path/to/Crash Twinsanity (Europe).iso" --dry-run
build/twinsanityevolved --iso "...iso" --run-seconds 10 [--deterministic] [--hz 60] [--mc-dir DIR] [--no-sdl-input]
ctest --test-dir build -L nativeee        # the platform/nativeee unit tests (one per seam header)
build/twinsanityevolved --iso "...iso" --deterministic --no-sdl-input --play-pad fixtures/padlogs/hub_entry.padlog \
    --save-state /tmp/hub.ps2st@2380 --stop-at 2600    # a save state at boundary 2380; --load-state /tmp/hub.ps2st resumes it
build/twinsanityevolved --iso "...iso" --record-pad my.padlog     # record pad 0 (inputs only, and the run's disc speed: a replay keeps it -- a log without that line
                                                                  # was recorded at the console's pace; --pad-script FILE for authoring `hold` lines)
build/twinsanityevolved --iso "...iso" --deterministic --play-pad P --trace-bodies 1   # the physics bodies every boundary (TE_TRACE_BODIES_ALL=1)
tools/ci/savestate_roundtrip.sh --iso "...iso"      # the save-state gate: save in the hub, load, identical trace/frames/census
build/twinsanityevolved --iso "...iso" --deterministic --skip-movies --play-pad fixtures/padlogs/hub_entry.padlog --stop-at 4200 \
    --harness-out /tmp/leg      # the engine's hash streams: frames.fhash, audio.ahash, run.meta (+ state.trace, frames.pdesc)
python3 tools/oracle/diff.py --padlog fixtures/padlogs/hub_entry.padlog --out /tmp/oracle_diff \
    --attributions tools/oracle/attributions/hub_entry.tsv    # the check against the recompiled reference
tools/ci/build_all.sh --iso "/path/to/Crash Twinsanity (Europe).iso"    # all CI gates
tools/ci/judges.sh --iso "...iso"                                       # the regression judges on build/twinsanityevolved
```

Requires CMake ≥ 3.21, Ninja, Python 3, a host C/C++ compiler, SDL2 and FFmpeg (the engine's dependencies), and
`/usr/local/vitasdk` for the armv7 syntax lane (`--no-vita` skips it). License: MIT for this repository's code (`LICENSE`);
`engine/` carries its own (`engine/LICENSE`).

### The launcher

The launcher is the engine's Qt 6 application (`engine/app/launcher`) with this title's `launcher/title.json` and the
disc tables in `launcher/discs/` (the known retail dumps `redump.json`, cited from redump.org; file lists made by
`tools/discs/manifest.py`, labelled by provenance; names, sizes and hashes only). It
installs the finished game from the releases and never compiles anything.

```sh
cmake -S engine/app/launcher -B build-launcher -G Ninja -DCMAKE_PREFIX_PATH=/opt/homebrew/opt/qt@6
cmake --build build-launcher && QT_QPA_PLATFORM=offscreen ctest --test-dir build-launcher --output-on-failure
build-launcher/ps2r_launcher.app/Contents/MacOS/ps2r_launcher --manifest launcher/title.json
PS2R_SCREENS_OUT=docs/launcher/screenshots PS2R_SCREENS_MANIFEST=$PWD/launcher/title.json PS2R_SCREENS_ISO="$ISO" \
    PS2R_SCREENS_ISO2="<North American image>" PS2R_SCREENS_PACKS=$PWD/mods \
    QT_QPA_PLATFORM=offscreen build-launcher/test_launcher_screens          # every screen, as docs/launcher/screenshots/
python3 tools/judges/launcher_cold_judge.py --launcher-build build-launcher --game build/twinsanityevolved --iso "$ISO" --out /tmp/cold
python3 tools/judges/launcher_settings_judge.py --launcher-build build-launcher --out /tmp/settings
tools/ci/release_launcher.sh --qt /opt/homebrew/opt/qt@6                    # the signed .app and the .dmg
tools/ci/release_launcher_linux.sh --qt ~/Qt/6.8.3/gcc_64                   # Linux x86_64: the AppImage (linuxdeploy, pinned)
```

### Cutscenes

The census of the game's cutscenes and the check that a skip leaves what watching leaves (ids, token types, counts and names
are all they print of the disc's scripts):

```sh
python3 tools/cutscenes/census.py run --iso "$ISO" --out /tmp/census     # TE_CUTSCENE_CENSUS=1 over every chunk of the archive
python3 tools/cutscenes/census.py report --logs /tmp/census --json census.json   # every CutsceneStart site, its skip branch, its commands
python3 tools/cutscenes/show.py /tmp/census/levels_ice_hub_psycho.log 6421       # one graph by its states, bodies and commands
python3 tools/cutscenes/verify.py --iso "$ISO" --list LIST.json --out /tmp/verify # per cutscene: a watched and a skipped leg, compared
python3 tools/cutscenes/reach.py record --iso "$ISO" [--only NAME]                # the reach fixtures fixtures/padlogs/cutscenes/*.padlog
python3 tools/cutscenes/compare.py W.log S.log                                     # the verdict over two TE_CUTSCENE_STATE logs
python3 tools/cutscenes/skip_table.py --fixture fixtures/judges/cutscene_skip_pal.json --list   # the cutscenes CROSS does not skip, and why
python3 tools/judges/cutscene_skip_judge.py --bin build/twinsanityevolved --iso "$ISO" --out /tmp/csj [--mechanism]  # every reached cutscene
```

`TE_CUTSCENE_STATE=N` logs the state a cutscene leaves (the progress, the counters, the music's tracks per slot, the chunks'
flags, the player, every instance's place, flags and running behaviours) every N boundaries; `TE_CUTSCENE_START=NAME[:MESSAGE]@BOUNDARY` gives a loaded
director the behaviour its trigger starts (a test's way into a cutscene without walking to it). The game logs each skip
(`[te.cutscene] skip over after N frames ...` and the agents it drove), and each cutscene it will not skip (`[te.cutscene] the
cutscene of site N cannot be skipped: ...` as it starts, `[te.cutscene] not skipped: ...` at CROSS).

What "leaves the watched state" means is the fixture's rule (`compare.py --rule`, written by the judge from the fixture's
`rule` and the cutscene's `allow`). Exact: the progress, the counters, the chunks' flags, the music, the player's chunk and mode
(the low 16 bits of the character's state word; the high 16 are unused) and the judged instances' flags and behaviours.
Places: within the `floor`, 0.035 units: two watchings of one cutscene in play mode (no `--deterministic`) end the player up
to 0.0334 apart where the cutscene puts him down -- on the Vita, whose frames of two and three fields move an interpolation's
end; 0 on the desktop, where no frame lost a field; further where he ends falling, on a slope or on a board, which a cutscene
that needs it allows itself -- or within a `classes` bound (a wumpa fruit's 0.25 bob). Allowed per cutscene (`allow`:
an agent's name, what of it, the reason, optionally `within` a bound, `settles` by +N boundaries and `from` +N): what runs on
the world's time and is not the cutscene's outcome; the name `player` is the player's place (a level that starts on a slide)
and `music:SLOT` a music slot (a cutscene's speech track, which a skip does not play, ending after the watched cutscene).
Every difference the rule allows is printed with its size and its reason.

The reach fixtures (`fixtures/padlogs/cutscenes/cutscenes.json`, one entry per cutscene a test reaches: its chunk, the save's
point of the story, the autopilot's steps) are recorded by `tools/cutscenes/reach.py`: the steps run closed-loop with
`--record-pad`, and the recording is the fixture. Some cutscenes need play no test can do (a boss fight won, a route a long way
up a level, a vehicle steered through a chase): a test may then ask the game for a few things, which the game carries out with
its own code at the start of a frame of play (`Platform::System::NextTestRequest`; `game/testrequests.h`). They are test tools:
nothing is asked unless a plan or the knob below asks, and the PS2 never asks. The autopilot's plan steps:

- `teleport X Y Z [NAME]` -- the player (or the instance whose object is NAME) warped to (X, Y, Z) in its chunk's frame, as a
  script's PositionWarp warps one; a rider's vehicle starts again there;
- `message NAME ID [FROM]` -- the user message ID sent to NAME's instance from FROM's, as a script's SendUserMessage sends one;
- `counter N V [NAME]` -- the game counter N (0..999) set to V, or with NAME that instance's own counter N (0..3), as a script's
  SetCounter sets one;
- `hitpoints N [NAME]` -- the player's (or NAME's) hit points set to N (0..255), as a script's SetHitPoints sets a character's
  (2 is Aku Aku's first mask, 3 the shining one: the next mask picked up makes the character invincible);
- `until-graph NAME GRAPH [STATE] [MAX_FRAMES]` -- the plan waits until NAME's instance runs that behaviour graph (at that state).

Each request is logged as `[te.test] b BOUNDARY: SPEC`; `reach.py` writes a recording's as the entry's `test`, and the legs of
`verify.py` and the judge replay them with `TE_TEST_ACTIONS=SPEC@BOUNDARY;SPEC@BOUNDARY...` (each at the first boundary of play
from its boundary on). `TE_TRACE_MOVES=1` adds the probe's `[move]` lines: every boundary of a knee slide (its state, the time
into it, the facing's and the slide's yaw) and every change of the played character's hit points and invincibility, with the
last contact's kinds and damage.

Which cutscenes CROSS may skip is the table the game asks (`Platform::System::CutsceneSkippable`: for each graph a director's
runner runs as its cutscene starts, and at CROSS for each graph the cutscene's agents run;
`platform/nativeee/host/cutscene_skip.cpp`). The build makes the table of the judge's fixture
`fixtures/judges/cutscene_skip_pal.json` (`tools/cutscenes/skip_table.py`; `--list` prints the cutscenes that cannot be
skipped and why): each of the 51 cutscenes by its site and the graphs only it runs, its status (`pass`, or `refused` with the
reason), a skippable one's graphs its checked legs never ran (`unverified`: refused) and how a test reaches it.
`TE_CUTSCENE_SKIP_ALL=1` skips every cutscene without the table: what `tools/cutscenes/verify.py` measures by default
(`--with-table`: the game as it ships). `tools/judges/cutscene_skip_judge.py` (the judges' feature set) runs every cutscene of
the fixture a test reaches, four at a time: a skippable one must leave the watched state, play on and be shorter than watching
it; a refused one must play exactly as watched when CROSS is pressed. `--mechanism` also skips each refused one without the
table and names those whose skip now leaves the watched state (their status may become `pass`).

### Mods and the mod tool

`twinsanityevolved-modtool` is built with the game (`cmake --build build --target twinsanityevolved-modtool`); its library
`engine/app/host/mod_import` is the launcher's Mods page's too; `tools/judges/mods_import_judge.py` and `mods_overlay_judge.py` judge them on a disc.

### Languages

A language pack's text bank is made from a table of translations by `tools/text/translate.py` (any language written in
Windows-1256; the Arabic one is `tools/text/arabic.tsv` -> `mods/arabic/data/arabic.bank`: the game's 305 texts and the
port's own two row titles, TEXT LANGUAGE and SPEECH LANGUAGE, `port:000` / `port:001`), its glyphs by `tools/font`:

```sh
tools/text/translate.py --iso "$ISO" --language arabic --extract /tmp/arabic-batches   # the English, masked, in batches (outside the tree)
tools/text/translate.py --iso "$ISO" --language arabic --replies /tmp/arabic-answers   # the translations back (a person or an LLM)
tools/text/translate.py --iso "$ISO" --language arabic --fit                           # break the lines to fit the game's boxes
tools/text/translate.py --iso "$ISO" --language arabic --check                         # every text present, current and fitting
tools/text/translate.py --iso "$ISO" --language arabic                                 # the bank
tools/font/build_arabic_font.py                                                       # mods/arabic/data/arabic.font from the typeface
```

`tools/text/translate.py --help` lists the options (the prompts, the glossary, the translation endpoint).

### PS Vita

```sh
cmake --preset vita-release && cmake --build --preset vita-release      # VITASDK=/usr/local/vitasdk: build-vita-release/twinsanityevolved.vpk
cmake --preset vita-module-release && cmake --build --preset vita-module-release   # the wasm2c build, for an A/B
```

`vita-release` is the PS Vita package the release attaches: the game's code compiled natively for the console's ARM
processor by the SDK's GCC (`tools/te_cxx_arm.py`, `cmake/native_lane.cmake`; no wasm32 toolchain needed).
`vita-module-release` builds the game the way the computers do (wasm32, then wasm2c's C) into `build-vita-module/`.
The Vita3K recipe that compares the two builds picture for picture, and what differs between them, follow.

#### The two builds, picture for picture, in Vita3K

The recipe compares the draw lists of every picture (`TE_GFX_DRAWHASH=1`: one line per picture with a hash of every draw's
state, vertices, mesh parameters and skin palette in submission order), the played character every 30 boundaries
(`--trace-player 30`) and the game states (`--trace-state`). Vita3K's picture read-back is empty, which is why the draws are
hashed instead of the frames; its timing is not the console's, which a `--deterministic` run does not depend on.

1. Build both packages: `cmake --preset vita-release && cmake --build --preset vita-release`, and the same with
   `vita-module-release` (`build-vita-release/twinsanityevolved.vpk`, `build-vita-module/twinsanityevolved.vpk`).
2. The routes' memory cards, made on the computer (`build/` is the desktop build):

   ```sh
   TE_GFX_HEADLESS=1 TE_GFX_NO_DRAW=1 build/twinsanityevolved --iso "$ISO" --deterministic --no-sdl-input --no-audio \
       --skip-movies --play-pad fixtures/padlogs/hub_entry.padlog --mc-dir /tmp/mc_hub --stop-at 2700
   python3 tools/warp_save.py --card /tmp/mc_hub --chunk 'levels\school\rooftop\roof01' --out /tmp/mc_roof01 --place 0xFFFF
   python3 tools/warp_save.py --card /tmp/mc_hub --chunk 'levels\school\sch_hub\sch_hub' --out /tmp/mc_schhub --place 0xFFFF
   ```

3. Into Vita3K's `ux0:data/twinsanity/` (`~/Library/Application Support/Vita3K/Vita3K/fs/ux0/data/twinsanity/` on macOS):
   the disc image as `game.iso`, the pad logs `fixtures/padlogs/hub_entry.padlog`,
   `fixtures/padlogs/entries/school_rooftop_roof01.padlog` and `school_sch_hub_sch_hub.padlog`, and a FRESH copy of the
   route's card for every run (the game saves to it): an empty folder for the hub, `/tmp/mc_roof01` or `/tmp/mc_schhub`.
4. One run per build and route, `args.txt` (the hub's; the others name their pad log and card):

   ```
   --iso ux0:data/twinsanity/game.iso --mc-dir ux0:data/twinsanity/mc --config none --skip-movies --trace-state --no-kbm
   --deterministic --play-pad ux0:data/twinsanity/hub_entry.padlog --stop-at 4200 --trace-player 30 TE_GFX_DRAWHASH=1
   ```

   `tools/vita/vita3k_run.sh --vpk build-vita-release/twinsanityevolved.vpk --seconds 300` (`VITA3K=` names the emulator's
   binary: the arm64 build where there is one, see below), then keep
   `ux0:data/twinsanity/twinsanityevolved.log`; the same with `build-vita-module/twinsanityevolved.vpk`. A run ends with
   `--stop-at: exit 0` in the log (Vita3K then exits on its own teardown).
5. `tools/vita/lanes_compare.py module.log native.log`: the pictures both reached, identical or not, the first that differ;
   the probes and the game states, a line that differs only in an 8-digit hex word counted apart (the module prints a guest
   offset where the native build prints a pointer). `TE_GFX_DRAWHASH_AT=N` is not in the tree: a picture that differs is
   found draw by draw with a local listing of `SubmitBuckets`' hash parts.

What the two builds give: the same game states on every route, the same probes but the loading screen's (below), and every
picture identical but the user interface's turned and curved shapes (below).

**Vita3K does not keep the console's rounding exactly.** The game thread runs with FPSCR = round toward zero, flush to zero,
default NaN (the EE's arithmetic). The x86_64 Vita3K build (here under Rosetta 2) returned round-to-nearest results from the
host's sine under that FPSCR at start-up, and compared a denormal as above zero on one build and not on the other; the arm64
build applies an FPSCR change one JIT block late (a division right after `vmsr` rounded the previous way). Two runs of
different code can therefore differ in a last bit where the console would not, and the two emulators do not even agree on
the game's timeline (the arm64 build's clock matches the desktop's at the loading screen, the x86_64 build's does not). Use
the arm64 build where there is one, read a difference in a last bit as unproven, and settle it on the console: the same
recipe there (the log is `ux0:data/twinsanity/twinsanityevolved.log`), both packages, one route.

#### What differs between the two builds

- **Out-of-range float-to-integer casts** gave different answers until `tools/te_cxx_arm.py`'s rewrite R8: the module's code
  (clang for wasm32) guards every conversion -- INT_MIN for a float that does not fit an s32, 0 for a u32 -- where the
  Cortex-A9's VCVT saturates. The HUD's turned sprites read an uninitialised wobble base (`SpriteWidget::Construct` with an
  anchor never sets it; 1.6e34 for the lives head), so the head was turned by -2.8 degrees in the module and +2.8 natively in
  the first seconds of every level. `platform/nativeee/native/int_cast.h` gives the native game the module's answers (the
  PS2's CVT.W.S saturates as the Cortex-A9 does; the reference here is the module, the desktop's code).
- **Still differing in Vita3K**, the game states and the scenery identical: the title's and the menus' rings and the HUD's
  turned head at rest, each by one bit in a few vertices (the arm64 build: 160 of a ring's 4608 vertices, one unit in the last
  place), and the played character's place on the loading screen before the level's chunk exists, -0 natively where the
  module has +0. Whether either is the emulator's rounding or a real difference of the two compilers (each folds the
  constant float expressions it can see at build time to the nearest, while the game rounds toward zero at run time) only the
  console's own pair of logs can tell.

#### The native build's risks

- **The 32 MB block has no guard page.** It is the first 32 MB of the program's .bss (the retail data symbols at their
  addresses in it), with the program's own globals after it; the PS Vita has no page protection a program can set
  (`psp2/kernel/sysmem.h` has none), so the block cannot have an unmapped neighbour. A game access past the 32 MB corrupts
  those globals or faults. The module build is no safer on the console: its memory accesses are unchecked there
  (`TE_VITA_UNCHECKED_MEMORY`, since 2026-10-22), only the computers' module traps.
- **A NULL read faults.** In the module a game pointer is an offset into the 32 MB, so reading through NULL reads the
  block's first bytes and the game goes on; natively a game pointer is a pointer, and address 0 is unmapped. A latent read
  through NULL that the PS2 and the module tolerate ends the native game ("the application has crashed", a core dump).
- **Undefined C++ the two compilers answer differently**, besides the float casts above: a shift by 32 or more (wasm takes
  the count modulo 32, ARM's register shift gives 0), an integer division by zero (the module traps, the native division
  returns a value and the game goes on), an uninitialised local (a wasm local starts at 0; natively it is what the register
  or the stack held). Whether one of them is behind the loading screen's -0 above is not known.
- **Save states** exist on neither PS Vita build (`runner/te_savestate_null.cpp`: every save and load says "save states
  are not available on this target"), so none passes between the two; on the computers a state is tied to the build that
  wrote it (the CRC-32 of the program). The memory cards are the game's own saves: the two builds write the same bytes but for two
  words where the game stores two of its heap pointers (an offset into the 32 MB in the module, a pointer natively), and
  each loads a card the other wrote and plays on (Vita3K: LOAD GAME into the hub, both ways).
- **The GPU lock-up of v0.9.1.** A player's console ended v0.9.1's native package with "render gpu crash": the GPU stopped
  in the pixel phase of an alpha-tested draw of the frame target. The one console-only GPU difference was the fill census
  of the built-in diagnosis set (`TE_GFX_VITA_FILL`), out of the built-in arguments since (an `args.txt` token still turns
  it on); Vita3K does not count visibility, so it is not proven to be the trigger. The drawing code is the same in both
  builds, so the module build is exposed the same way.

### Windows

The Windows lane is its own preset family (nothing above changes): clang-cl + Ninja through
`cmake/windows-clang-cl.toolchain.cmake` (the engine's clang-cl shim, vcpkg for SDL2 / FFmpeg / the GL headers), the
pinned toolchain through `tools\fetch_toolchain.ps1`.

Prerequisites: Visual Studio 2022 (or its Build Tools) with "Desktop development with C++" and "C++ Clang tools for
Windows"; CMake 3.24 or newer; Python 3 on PATH as `python`; Git for Windows; and a bootstrapped vcpkg checkout that
contains the manifests' `builtin-baseline` commit (`git -C <vcpkg> fetch`, then `bootstrap-vcpkg.bat`). Open a
"Developer PowerShell for VS 2022" and set `VCPKG_ROOT` there: the developer shell sets its own `VCPKG_ROOT` (Visual
Studio's bundled vcpkg), which is too old for the pinned baseline. The first configure builds FFmpeg from source
(10-60 minutes; cached afterwards). The game needs a GPU driver with OpenGL 4.1 core (any current NVIDIA, AMD or Intel
driver; not a remote-desktop session).

```powershell
powershell -ExecutionPolicy Bypass -File tools\fetch_toolchain.ps1     # pinned wasi-sdk + wabt (sha256), native PowerShell
cmake --preset windows-clang-cl-release                                 # VCPKG_ROOT set; Developer PowerShell for VS 2022
cmake --build --preset windows-clang-cl-release -j 8
ctest --preset windows-clang-cl-release                                 # every nativeee test incl. the Win64 fiber arm
build-windows-release\twinsanityevolved.exe --iso "D:\Crash Twinsanity.iso"
.\tools\ci\release_dist.ps1 -SkipBuild                                # dist\windows-x64\ + the zip (the CI job's artifact)
```

## Release artifacts

`tools/ci/release_dist.sh` (macOS / Linux) and `tools/ci/release_dist.ps1` (Windows) build the shipped shape — the pinned
wasm32 toolchain, the engine's static LGPL FFmpeg and static SDL2 (`TE_DIST=ON`), the runner and the mod tool — and stage
`dist/<platform>/` (`twinsanityevolved`, `twinsanityevolved-modtool`, `mods/arabic`, BUILD-ID, README, LICENSE, third-party
notices + licence texts, `fixtures/padlogs/`) plus `dist/twinsanityevolved-<platform>.zip` + `.sha256`; the asset scan runs over
the folder and the staging refuses a GPL FFmpeg. `.github/workflows/release.yml` runs the same scripts on a `v*` tag
for macOS arm64 / x86_64, Linux x86_64 / aarch64 and Windows x64 (the Windows job runs the unit tests on Mesa's llvmpipe,
the runner having no GPU; a platform whose job fails is named as missing in the release's notes and the others are still
attached; `.github/workflows/windows.yml` is the Windows build lane on its own), the PS Vita's `.vpk` (the `vita` job, the `vita-release` preset: the program with the game's code compiled natively, the shipped shader cache and the LiveArea's pictures -- the bubble's icon, the start picture, the page's background and gate from `tools/vita/livearea/`, the game's cover and promotional art, which the asset scan exempts by name) and, through `.github/workflows/launcher.yml`, the launchers (`tools/ci/release_launcher.ps1` /
`.sh` / `_linux.sh`: the Windows zip, the macOS `.dmg`, the Linux AppImage). Its release job attaches every file with one
`SHA256SUMS` to the tag's one DRAFT release, whose notes are `RELEASE-NOTES.txt`; it is published by hand:

```sh
git tag vX.Y.Z && git push origin vX.Y.Z      # the workflow runs; the draft collects every file and SHA256SUMS
gh release edit vX.Y.Z --draft=false          # publish it once checked (the launcher installs published releases only)
```

Offline Linux: `docker build -f tools/ci/linux.Dockerfile -t te-linux . && docker run --rm -v "$PWD:/src"
-w /src te-linux tools/ci/release_dist.sh --jobs 3`. Development shape (Homebrew / apt packages, bundled into `lib/`, not
shippable): `tools/ci/release_dist.sh --system-deps`.

## Graphics diagnostics

The runner opens a window at `Platform::Graphics::StartRenderer` and presents the frame at the display's rate.
Environment knobs of `platform/nativeee/host/graphics.cpp`: `TE_GFX_HEADLESS=1` (hidden window), `TE_GFX_UNPACED=1` (no
vertical-blank pacing), `TE_GFX_DUMP_DIR=dir` + `TE_GFX_DUMP_EVERY=n` / `TE_GFX_DUMP_AT=k` (presented frames as PPM),
`TE_GFX_LOG=1`, `TE_GFX_SUMMARY_EVERY=n` (the counters line the judges read), `TE_GFX_DUMP_TEXTURES=dir`,
`TE_GFX_DIAG_MIP_TINT=1` (every texture's levels below the first given in magenta: the surfaces drawn from them show it),
`TE_GFX_VITA_LEVELS=authored|gpu|none` (the PS Vita: the levels below the first sampled from the PS2's own levels -- the
default, as on a computer -- from the GL library's levels made from level 0 on the GPU, as earlier releases did, or none),
`TE_GFX_VITA_KEEP_DEPTH=always` (the PS Vita: every frame's depth kept across ANY end of its GPU scene -- stored at each
scene's end, loaded at the next -- not only across a screen copy's, as by default; what the sky drawn after the opaque scene
needs should anything else end the frame's scene; `=0` keeps it across nothing), `TE_GFX_VITA_INSTANCE_INDICES=N` (the PS
Vita: no instanced draw of more than N indices -- a longer run of a repeated mesh drawn as several instanced draws in its
order; no plain draw asks for more than 49152; the log's `gxm draws refused` line names, a window at a time, the draws the
GPU library refused and the largest instanced draw), `TE_GFX_VITA_INSTANCING=skip` (the PS Vita, diagnosis: the instanced
draws not made -- the picture a GPU that drew none of them would show, to set beside a console's photo),
`TE_GFX_RENDER_THREAD=0/1` (the frame's GL work on a render thread — on by default in play mode with a window),
`TE_TICK_LOG_MS=ms` (the clock logs every tick slower than that with its phases: draw submit / present / pump / game;
`TE_TICK_LOG_CAP=n`: at most n such lines a census window, then only the ticks of twice `ms` or more and the window's
longest so far, the others counted by their profile's top section in the window's `[te.load] ... slow ticks not logged` line),
`TE_PICTURE_LOG_MS=ms` (the drawing thread logs every picture slower than that -- its wait for the GPU, its drawing, its
present call -- with the drawing thread's sections under `TE_PROF=1`; `TE_PICTURE_LOG_CAP=n` as for the ticks),
`TE_NO_QOS=1` (the game, render and pacer threads at the default QoS instead of interactive), `TE_GFX_DEPTH_Z32=1` (the GS
Z mapped to the window depth as z / 2^32, the mapping before the exact one — z / 2^24, one depth step per GS Z unit, as the
GS's Z32 test compares them; the old one resolved 128 units and let near-coplanar passes z-fight: for A/B). Diagnosis knobs of the scene
(`host/graphics_scene.cpp`, `host/math_vu0.cpp`): `TE_GFX_CULL_ALL_OUT=1` / `TE_GFX_CULL_ALL_IN=1` / `TE_GFX_CULL_BOXES_OUT=1`
(the culling's answers forced), `TE_GFX_NO_DRAW=1` (culling without the models' and skins' draws), `TE_GFX_SKIN_DUMP=DIR`
(every skin / blend-part packet the engine's SkinGeometry refuses), `TE_GFX_DIAG_TEXT=1` (every text call: quads, tfx, colour,
glyph size, string), `TE_PARTICLE_DIAG=1` / `TE_PARTICLE_NOCULL=1` (every ParticleBlockView answer logged / the block culling
off), `TE_GFX_PARTICLE_UNCLAMPED=0|2` (the particle emitter with its VU clamps for every block / both forms run for every
block and their packets compared, a line every 1024 blocks; by default an ARM processor leaves the clamps out of a block
whose floats are all finite: the same packets), `TE_GFX_SHADOW_DIAG=1` (the shadow composite without its stencil test),
`TE_GFX_NO_SHADOWS=1` (volumes counted, never
composited), `TE_GFX_DIAG_FLOORS=1` / `=paint` (each FBA model part's floors, the up-facing triangles its own model covers and
the draws' runs, and the instances kept whole for not standing upright / those floors painted flat magenta: the pixels that
take the shadow on a crate), `TE_GFX_NO_DECALS=1`, `TE_GFX_NO_PASSES=1` (a material's first shader only), `TE_MATH_STUB=collision,rays,joints`
(those maths stubbed), `TE_GFX_DIAG_PRESENT=N` / `TE_GFX_DIAG_FLAT=1` (one present's model draws logged with state, screen
box, colours and the material's shaders / painted by clip mode), with `TE_GFX_DIAG_PRESENT=N`: `TE_GFX_DIAG_VERTS=1` (every
vertex of that present's draws logged: bucket, screen position, GS Z, depth test / write) and `TE_GFX_DIAG_MARK_BUCKET=a,b`
(those buckets' draws painted opaque magenta, depth test and write kept: the pixels they win, for the exact depth test
over the logged vertices), `TE_GFX_SKY_DIAG=A[,B[,S]]` (pictures A..B, every S-th: each draw's place to the sky drawn after
the opaque scene -- a held layer, the depth reset, drawn before the sky, the draw the sky is drawn before and why, after it --
with its state, its kind and its depth extent in GS z: a mesh's bounds through its matrix, a skin's joints, a vertex
draw's vertices -- on the PS Vita also a mesh's range and the instancing plan's word for it: the first of a group of N drawn
as one instanced draw, or joined to one; and a line a picture: the draws the sky waited for and the smallest depth among them),
`TE_MATH_RAY=retail|legacy` (the fast ray casts by the
engine's `title::RayMath` — the retail VU0 program as values, the default — or the earlier slow-path form),
`TE_MATH_RAY_COMPARE=1` / `TE_MATH_RAY_MICRO=1` (the retail 0xAB8 micro on the engine's VU interpreter counted against /
answering every cast), `TE_PARTICLE_VIEW=legacy` (the earlier particle block view for A/B).
`tools/vita/readlog.py LOG` turns a PS Vita log (`ux0:data/twinsanity/twinsanityevolved.log`, the console's or Vita3K's)
into markdown tables, one row per census window -- the pace, the threads' milliseconds, the GPU, the draws, the seams, the
bursts' particles and sound, the textures, the disc -- and the slow ticks and pictures, one by one and by their profile's top
section.

`TE_GFX_GPU_LIFETIME=1` (off by default; nothing is recorded when off): every free, re-specification and CPU write of GPU
memory the GL backend makes -- textures, the pool's storage, the mesh buffers, the vertex ring's slices, on the PS Vita also
vitaGL's uniform ring, its garbage collector's frees and the shader programs' code -- checked against what the GPU may still be
reading. On the PS Vita the last use is vitaGL's own record of the texture or buffer and the GPU's progress the scene fence
vitaGL passes to every scene's end; storage in flight that vitaGL does not defer is logged as `[te.gfx.vita] GPU LIFETIME:
... UNPROTECTED`, and each summary window ends with a `GPU lifetime` line of the counts (in flight, deferred, UNPROTECTED).
On a computer the driver keeps what the GPU reads: the same events are counted with the presents the GPU had not finished.

At the high resolutions (the RESOLUTION row's 2x..4x): `TE_GFX_GPU_TIMERS=1|phases|breaks` (the GPU phase timer: after every pace line, the GPU's
milliseconds, the pixels drawn and the drawing thread's time per phase of a frame -- the clear, the sky, the opaque scene,
the blended draws, the shadow volumes and their composite, the screen copies, the HUD, the present, and the window's worst
frame with its phases; `1` cuts at every phase,
or only where the frame's render pass ends on a tile-based GPU such as Apple's; not free there: the hub at 4x on an Apple
M4 presents 56 frames a second with it, 60 without), `TE_GFX_EAGER_TEXTURES=0` (the textures decoded on the game thread at
their load and made with the game thread waiting for the drawing thread, as before, instead of decoded ahead on the builders
and made between pictures -- the default on every platform; `TE_LOAD_CENSUS=1` prints what each window loaded and waited
for), `TE_GFX_SKY_LAST=0|abN` (the sky's layers drawn first, as before,
instead of after the opaque scene / switched on and off every N presents), `TE_GFX_SHADOW_REGION=0|abN` (the shadow
passes over the whole frame, as before, instead of the volumes' tiles only / switched), `TE_GFX_PS2_FAST=0|abN` (every
draw with the full PS2 fragment program, as before, instead of its fast form -- the same source with the arms no draw of
the port turns on folded away, the same pixels, 2.4 times faster per pixel on an Apple M4 / switched),
`TE_GFX_SCALE_AB=N` (the internal scale switched between the setting and 1x every N presents), `TE_GFX_DUMP_TARGET=1` (the
dumps at the frame target's own size, 2048x2048 at 4x, instead of the presented picture). A burst of explosions is the particles' fill: a 4x frame draws
16 times the PS2's pixels for each particle quad, and the roof's detonator under its 24 TNT and nitro crates draws about
24 frames' worth of particle quads at its peak -- 100 million pixels a frame at 4x, of the PS2's full fragment program
(on an Apple M4 the blended draws then take 7-10 ms of the GPU's frame instead of about 2). `TE_GFX_PARTICLE_CENSUS=1` (a line
per census window: the particle blocks, their triangles and the frames' worth of pixels they cover, in Mpx at the scale),
`TE_GFX_PARTICLE_CULL=0|abN` (the particle triangles that draw nothing -- every fragment fails the alpha test and is
discarded -- drawn as before instead of left out / switched every N presents: the same picture),
`TE_GFX_PARTICLE_SCALE=title|abN` (the additive particles -- the fire, the glows -- drawn at the PS2's own resolution into a
picture of their own and added to the frame: 1/16 of their pixels at 4x, the particles as soft as on the PS2, and an edge
of the scene in front of them decided per PS2 pixel -- a stair step up to four pixels deep along a crate shard's edge over the
fire at 4x; off by default; `frame` = the default; abN switched every N presents).

Judges: `tools/ci/judges.sh --iso IMAGE` runs every regression judge (`tools/judges/*.py` with `fixtures/judges/*.json`:
skins, shadows, the shadow on a crate's top, particles, decals, dust, the crystals, Ice Climb's cave passes against the exact
GS depth test, the textures made ahead of their use (two cutscenes that read their next area: nothing decoded or waited for on
the game thread, the pictures the synchronous path's), the orb,
the ocean, the heap layout, the fill a 4x frame draws where the fog and the waterfall are, display, language, mods,
speedrun, infinite lives, the pause screen's gem row, fps counter, voice pitch, the loads at the device's speed; the mods folder's disc overlay, the mod importer and the game's Mods page; the Arabic
language pack; `--set launcher`: the launcher's cold install, its Settings and Mods pages and the no-codenames lint; `--set
discs`: the disc identity, the region-aware loader and, with `--ntsc-iso`, the North American boot) and
`tools/judges/run_graphics_judges.sh` (the self-test frames; the legal screen and
the title's world). `tools/judges/padlog_judge.py RUN_LOG --fixture fixtures/judges/hub_entry_pal.json` judges the hub pad
log's replay (to 4200, Playing held, no trap, the small pages not exhausted); `tools/judges/movie_judge.py` the boot movies;
`tools/judges/hub_fps_judge.py --bin BUILD/twinsanityevolved --iso IMAGE` the hub's render rate in play mode (render fps p50 ≥
55, no tick > 16.7 ms outside the load windows); `tools/judges/frame_rate_judge.py --bin BIN --iso IMAGE` the FRAME RATE row
per setting (the shown fps within 3 % of the setting, game_hz 60.0 ± 0.1, the real pictures' hashes identical across the
settings, zero displacement violations); `tools/judges/interpolation_quality_judge.py --bin BIN --iso IMAGE` the interpolated
frames at 120 (the half-way frame against the pixel mean of its two real neighbours, SSIM ≥ 0.95 on the hub, the intro
cutscene and a cavern run). The runner prints the game's heap at exit (`heap: pool … small pages used N
of M`); `tools/ci/build_all.sh` runs every gate (`TE_MIN_FREE_GB` lowers its 15 GB disk floor).
