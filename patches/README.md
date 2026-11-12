# Patches

Each numbered patch modifies the vendored Butterscotch source in `upstream/` for MiaUI. They're applied in order by the `Dockerfile`:

| # | File | What it does |
|---|---|---|
| 001 | `001-rg35xx-fallback-mapping.patch` | Adds `createFallbackMappings()` — the shipped `gamecontrollerdb.txt` has no entry for the RG35XX pad, so a fallback mapping is created on boot. Face buttons are identity; the D-pad is remapped to the verified MiaUI indices (sdl 13–16). Button 12 is the system volume key and is never mapped. |
| 002 | `002-chunklog.patch` | Logs each `data.win` chunk as it's parsed (`logInfo`), so hangs in the loader are visible in `debug.log`. |
| 003 | `003-stage-markers.patch` | Prints `[stage]` markers to stderr at each engine init step (parse, VM create, platform init, renderer, audio). |
| 004 | `004-sdl-error.patch` | Includes `SDL_GetError()` in the SDL2 "Failed to initialize SDL" message. |
| 005 | `005-sdl1-error.patch` | Same as 004 but for the SDL1 backend (`sdl1.c`). |
| 006 | `006-fpslog.patch` | Per-frame phase timing — prints an `FPSLOG:` line every 300 frames via unbuffered `logError`, splitting the frame into input, simulation, and sleep phases. |
| 007 | `007-joyname-cache.patch` | **Performance fix.** Caches `SDL_JoystickName()` per slot. SDL 1.2's version opens the device and issues evdev ioctls on every call (~50 ms/frame on this pad), which was the root cause of a previous bug where the game was running at ~15 fps. |
| 008 | `008-exit-cursor.patch` | Select + Start held together quits cleanly; the fbcon stub cursor (which never moves and sits in a corner) is always hidden. |
| 009 | `009-am2r-string-placeholder.patch` | **AM2R text fix.** Backports Butterscotch `c1260061` "support placeholder substitution in string()" (issue #486) into the pinned tree's APIs: `string()` now substitutes `{n}` argument placeholders and `{{`/`}}` escapes. Without it, every AM2R formatted string renders as `[!]`. Adapted to the pinned tree: single-arg `RValue_toString` (malloc'd result, freed by the patch), no `REQUIRE_ARGC_AT_LEAST` macro, old-style argc check. |

Patches 001–008 are identical to the Undertale MiaUI port's set (the pipeline
is proven on-device; keeping them byte-identical keeps the two ports' builds
comparable).

## Upstream pin

Pinned at `92ed6b8c3766361a201a69d202bcde5873cdad7e` (`cobaltgit/Butterscotch`,
2026-08-24) — the same commit as the Undertale MiaUI port. This pin retains
the software renderer (`src/sw/`) and the SDL1 audio backend, which the newer
`ButterscotchRunner/Butterscotch` upstream (the active development repo) has
removed; that repo cannot software-render at all in its current state
(`--renderer software` is a hard error there, and `ENABLE_SW_RENDERER` is
referenced but un-definable). The one AM2R-critical change from newer
upstream — the string() placeholder fix — is backported as 009 instead.

## Applying

The `Dockerfile` resets `upstream/` to the pinned commit and applies `patches/*.patch` in filename order. Any mismatch fails the build hard.

To regenerate a patch against the pinned source: reset `upstream/` to the pin, apply the earlier-numbered patches in order, make the edit, and `git diff` it out (see the Undertale port's `tools/gen_patches.py` for the original generation flow).
