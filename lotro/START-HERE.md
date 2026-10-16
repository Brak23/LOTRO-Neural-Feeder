# LOTRO DLSS5 prototype v0.1.0

This ZIP is an **unofficial, uninstalled test artifact**. It was compiled from DLSS5-Feeder v1.19.0 plus LOTRO-specific preflight, configuration, documentation, and packaging. It has not run inside LOTRO. No NVIDIA neural runtime, neural consumer, ReShade installer, or game file is included.

1. Run `scripts\Verify-LotroPackage.ps1 -ZipPath <path to this ZIP>` to check every packaged file against `package-manifest.json`.
2. Run `scripts\Preflight-Lotro.ps1 -GameExe <actual LOTRO executable path>` to record the selected client's hash, bitness, and available renderer configuration hint. It does not start the game.
3. Read `COMPATIBILITY.md` and `TEST-PLAN.md`. Keep the package separate from the game installation while game-side permission and runtime provenance remain unresolved.

`bin\dlss5-feed.addon64` is the compiled ReShade add-on, not a standalone game mod. `diagnostics\dlss5-feed-host64.exe` is an upstream helper for a later *separate* backend test and is not needed for the proposed x64 D3D11 game path. Neither binary should be launched or injected into LOTRO from this package.

The normal-rendering bypass is upstream's `enabled=0`; both supplied configuration templates use it. No interface isolation, neural rendering, performance improvement, or LOTRO compatibility is claimed.
