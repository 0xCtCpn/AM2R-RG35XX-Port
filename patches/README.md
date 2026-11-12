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
| 010 | `010-am2r-overlay-read-guard.patch` | **Crash guard + diagnostics.** On-device, an overlay-FS text read hit `malloc(0x80000000)` (ftell returned `LONG_MAX`) and SIGABRT'd the game ~13 frames in (`overlay_file_system.c:156`). Both `overlayReadFileText` and `overlayReadFileBinary` now refuse sizes < 0 or > 256 MB, printing `AM2R diag: ... size=... path=...` (unbuffered stderr → `debug.log`) so the offending path is identifiable, and fail the read gracefully instead of aborting. **Root cause found via the diag line:** the game opens the path `./` (a *directory*) as a text file — on Linux `fopen` on a directory succeeds and `ftell` gives `LONG_MAX` (Windows refuses, so the original never saw this). The guard correctly fails the read. Separately, the `[!]`-everywhere text bug was **missing `lang/` on device** — AM2R 1.1 keeps dialogue in external `lang/english.ini` (like the music); the folder was never pushed. |
| 011 | `011-am2r-delta-clamp.patch` | **Fall-through-floor fix.** `runner->deltaTime` is handed to the game unclamped; on-device room/texture loads stall single frames up to 408 ms (FPSLOG `max=`), so any `delta_time`-driven movement tunnels through floors ("sometimes I fall into the map"). Clamps the reported delta to 100 ms; fixed-step scheduling is unaffected. |
| 012 | `012-am2r-conv-array-diag.patch` | **Diagnostic (temporary).** Logs `VM: [script] handleConv(convKey=..): converting ARRAY to string!` whenever a to-string conversion receives an array — the source of `<array:XXXXX>` leaking into the on-screen button prompts. `lang/english.ini` (pushed 2026-11-13) fixed the general `[!]` text; this targets the remaining prompt case. |
| 013 | `013-am2r-activate-grid-readd.patch` | **Collision fix.** `instance_activate_all/object/region` only flipped the `active` flag; the spatial collision grid never re-inserted a reactivated instance, so anything removed from the grid while inactive stayed **permanently collision-invisible** (collision queries iterate grid cells and skip `!active` — a grid-less instance is unreachable). Fixes "collision breaks after the pause menu". Also logs `AM2R diag: activate_* re-added grid-less instance ...` to prove the loss path. |

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
