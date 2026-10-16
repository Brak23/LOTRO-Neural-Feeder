# LOTRO Neural Feeder prototype

This is an unofficial, experimental profile and packaging layer for [DLSS5-Feeder](https://github.com/jlrouzies-fr/DLSS5-Feeder), based on upstream v1.19.0 (`3c09eabcd138a68d144b6cc396a23e6b493eea4d`). It targets a possible 64-bit D3D11 path for **The Lord of the Rings Online** (LOTRO). The actual LOTRO executable, renderer, depth buffer, motion vectors, and game compatibility have not been verified.

The feeder makes synthetic DLAA inputs from a frame, ReShade depth, and estimated motion vectors. A separate compatible neural consumer and a legitimately obtained NVIDIA runtime are required for a neural pass. This project does not ship them, does not assert that DLSS 5 ran in LOTRO, and does not include an installer or game files. An upstream standalone DLAA success is distinct from neural rendering.

## What this branch adds

- `lotro/scripts/Preflight-Lotro.ps1` inspects an explicitly supplied executable or bounded install candidates without launching a game. It reports executable PE bitness and SHA-256, OS/GPU information, and a **configuration hint**, if present, for the renderer. A configuration hint is not a runtime observation.
- `lotro/config/` contains only keys supported by upstream v1.19.0. Both templates start disabled. `enabled=0` is the upstream bypass; `mode=0` is inert.
- Package, integrity, diagnostic collection, and manifest-governed restoration scripts are in `lotro/scripts/`. No script installs into LOTRO. Restoration is preview-only unless explicitly invoked with `-Apply` and a future installation manifest.
- `lotro/COMPATIBILITY.md` and `lotro/TEST-PLAN.md` keep verified facts separate from pending tests.

## Current use

Run `Preflight-Lotro.ps1 -GameExe <actual path to executable>` from PowerShell to record the real executable identity. Read [compatibility](lotro/COMPATIBILITY.md) and the [test plan](lotro/TEST-PLAN.md) before any proposed integration. Do not copy the prototype into a live game installation until the game's client-modification permission question is resolved.

The first Windows build uses the official NVIDIA DLSS SDK **headers and import library** and official Khronos Vulkan headers at pinned revisions. These build dependencies are ignored by Git and absent from the ZIP. No modified NVIDIA neural runtime or upstream automatic installer was used.

This is not an NVIDIA, RenoDX, ReShade, or Standing Stone Games release. Preserve the upstream [MIT license](LICENSE), third-party notices, and each dependency's own terms. The package's `START-HERE.md` explains the offline artifact.
