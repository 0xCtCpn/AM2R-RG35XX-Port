# AM2R (Another Metroid 2 Remake) - MiaUI (RG35XX) Port

AM2R 1.1 on the Anbernic RG35XX running MiaUI, using the open-source Butterscotch GameMaker runner.

Needs the original (Non-H700) RG35XX with MiaUI v2.0.0, the release zip, and your own AM2R 1.1 files.

## Overview

This repo builds AM2R for the Anbernic RG35XX running MiaUI. It cross-compiles the open-source Butterscotch runner (a GameMaker: Studio engine reimplementation) for the handheld's ARM CPU, patches it for MiaUI's layout and controls, and packages everything into a ready-to-copy `.pak` folder.

The build is fully reproducible from source via Docker: run `build.bat` and the binaries land in `out/`. You need to provide your own copy of AM2R — it is not included in the repo or the release.

The build is WAD 14-only (AM2R 1.1 is a GameMaker: Studio 1.4 / WAD 14 game) and pinned to upstream `0c94bfb` (2026-11-11), which includes the string-interpolation fix (Butterscotch issue #486) — without it, every AM2R text string renders as `[!]`.

## Install

0. Prepare your AM2R_MiaUI-release-v1.0.zip and your AM2R 1.1 files
1. Extract the zip into PORTS/
2. Copy all of your AM2R 1.1 files (AM2R.exe, data.win) into /PORTS/AM2R.pak/
3. Safely eject, boot, go to PORTS -> AM2R
4. Wait for load (lazy loading makes it longer than Undertale's)
5. Thats all, you should be booted in the game now so enjoy!

## SD folder structure

```
Ports/
  AM2R.pak/               # MiaUI pak folder name
    launch.sh
    butterscotch
    libSDL-1.2.so.0
    gamecontrollerdb.txt
    # Your AM2R 1.1 game files (AM2R.exe, data.win)
```

## Controls

The RG35XX pad maps to AM2R's default keyboard controls: D-pad = arrow keys (movement), face buttons = Z/X/C (shoot / missiles / beam lock), Start = Enter (pause). Select + Start held together quits the game cleanly.

## Build from source

Only needed if you change the engine or want fresh binaries

Prerequisites (Windows):

- Hardware Virtualization enabled in BIOS
- WSL 2 (Windows Subsystem for Linux 2)
- Docker Desktop (configured to use the WSL 2 engine)

Steps:

1. Open this folder and double-click `build.bat`
2. Wait for it to finish - success ends with `=== Built ===` plus a listing of `out/`
3. Fresh binaries land in `out/`: `butterscotch`, `libSDL-1.2.so.0`, `gamecontrollerdb.txt`

What the build does (`Dockerfile`):

* Starts from `debian:bookworm`, installs compilers and build tools
* Cross-compiles alsa-lib for ARM (glibc) **first** - SDL 1.2's configure silently drops its ALSA driver without it, which surfaces on-device as "No available audio device". The cross-built libasound is only used at link time and is deliberately **not** shipped (see below)
* Cross-compiles SDL 1.2.15 with the fbcon video driver (`--enable-video-fbcon`, `--enable-alsa`) and hard-fails if the ALSA bootstrap string is missing
* Resets the vendored `upstream/` to the pinned commit (`0c94bfb`), applies `patches/*.patch` (fails hard on any mismatch), then builds Butterscotch with `PLATFORM=cli BACKEND=sdl1 AUDIO_BACKEND=sdl1`, WAD 14-only, no GL renderers
* Prints checks at the end: the binary's `INTERP` (want `/lib/ld-linux-armhf.so.3`) and its `NEEDED` libraries

To install your own build: copy `out/*` + `launch.sh` to SD `ROMS/Ports/AM2R.pak/`, then copy your AM2R files into the same folder.

## No bundled libasound (on purpose)

The Undertale MiaUI port's v1.0.0 release shipped a bundled `libasound.so.2` (alsa-lib 1.2.12) which shadowed the system `/usr/lib/libasound.so.2` (1.2.10) via `LD_LIBRARY_PATH` and killed all audio ("No available audio device"). This port never ships one, and its `launch.sh` moves any stale copy aside on first run. AM2R's music plays through the system ALSA stack.

## Debugging

If crashing open `ROMS/Ports/AM2R.pak/debug.log` and check/submit the error. The build includes `[stage]` init markers, per-chunk loader logs, and `FPSLOG:` per-300-frame phase timing lines to make hangs and slowdowns attributable.

Performance note: AM2R is heavier than Undertale (bigger rooms, more instances). The launcher pins all cores to the 1.49 GHz performance governor, and the runner runs with `--lazy-rooms --lazy-textures --lazy-audio --load-type load-per-chunk` (required — the device has 256 MB RAM and AM2R 1.1's data.win is several times Undertale's).

## Credits

Thanks to:

* [ButterscotchRunner](https://github.com/ButterscotchRunner/Butterscotch) — Butterscotch GameMaker runner (AGPLv3, pinned at `0c94bfb`, vendored under `upstream/`)
* DoctorM64 and the AM2R community team — AM2R
* DSkywalk for [MiaUI](https://github.com/miaui-cfw/MiaUI-GPU-RG35XX)
* libsdl and ALSA upstreams for the bundled dependencies
* Nintendo — Metroid II: Return of Samus (AM2R is a non-commercial fan remake)

## License

GPLv3 and AGPLv3 - the vendored Butterscotch upstream is AGPLv3 (see `upstream/LICENSE`). MiaUI-port attribution in `NOTICE.MiaUI`; upstream credits in `upstream/README.md`. Corresponding source for release binaries is this repo + `Dockerfile`/`build.bat` build instructions.
