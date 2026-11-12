# Patches

Each numbered patch modifies the vendored Butterscotch source in `upstream/` for MiaUI. They're applied in order by the `Dockerfile`:

| # | File | What it does |
|---|---|---|
| 001 | `001-rg35xx-fallback-mapping.patch` | Adds `createFallbackMappings()` — the shipped `gamecontrollerdb.txt` has no entry for the RG35XX pad, so a fallback mapping is created on boot. Face buttons are identity; the D-pad is remapped to the verified MiaUI indices (sdl 13–16). Button 12 is the system volume key and is never mapped. |
| 002 | `002-chunklog.patch` | Logs each `data.win` chunk as it's parsed (`logInfo`), so hangs in the loader are visible in `debug.log`. |
| 003 | `003-stage-markers.patch` | Prints `[stage]` markers to stderr at each engine init step (parse, VM create, platform init). |
| 005 | `005-sdl1-error.patch` | Includes `SDL_GetError()` in the SDL1 "Failed to initialize SDL" message. |
| 006 | `006-fpslog.patch` | Per-frame phase timing — prints an `FPSLOG:` line every 300 frames via unbuffered `logError`, splitting the frame into input, simulation, and sleep phases. |
| 007 | `007-joyname-cache.patch` | **Performance fix.** Caches `SDL_JoystickName()` per slot. SDL 1.2's version opens the device and issues evdev ioctls on every call (~50 ms/frame on this pad), which was the root cause of a previous bug where the game was running at ~15 fps. |
| 008 | `008-exit-cursor.patch` | Select + Start held together quits cleanly; the fbcon stub cursor (which never moves and sits in a corner) is always hidden. |

Note: there is no 004 — the Undertale port's `004-sdl-error.patch` patched the
SDL2 backend (`src/backends/sdl2.c`), which this port does not build
(`BACKEND=sdl1`). Its SDL1 counterpart is 005.

## Upstream pin

Pinned at `0c94bfb05e3cb4b8946a38f8085747035dd37f94` (ButterscotchRunner
upstream, 2026-11-11). This is newer than the Undertale port's pin (92ed6b8)
on purpose: GM:S string interpolation — which renders all AM2R text — was
implemented in `c1260061` (2026-11-01, Butterscotch issue #486). Patches 003
and 006 were regenerated against this newer tree; the rest apply unchanged.

## Applying

The `Dockerfile` resets `upstream/` to the pinned commit and applies `patches/*.patch` in filename order. Any mismatch fails the build hard.

To regenerate a patch against the pinned source: reset `upstream/` to the pin, apply the earlier-numbered patches in order, make the edit, and `git diff` it out (see the Undertale port's `tools/gen_patches.py` for the original generation flow).
