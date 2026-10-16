# Compatibility and limits

| Area | Evidence as of v0.1.0 | Status |
| --- | --- | --- |
| Upstream source | v1.19.0 tag, commit `3c09eabcd138a68d144b6cc396a23e6b493eea4d`, MIT | Verified |
| Windows compile | MSVC x64 add-on, host, x86 add-on, helper, layer, and spikes compile/link in isolated workspace | Verified; see package results |
| Standalone Vulkan present-order test | Passed on an RTX 5080 with system Vulkan loader | Verified only for this upstream test |
| LOTRO executable and bitness | Read-only preflight found current x86 and x64 PE candidates in a Steam library; backups were excluded. The launcher-selected process has not been observed. | Candidates verified; selection unverified |
| LOTRO renderer | Local preferences contain `GraphicsCore=D3D11`; this is a configuration hint, not a live observation | Runtime API unverified |
| LOTRO depth buffer and motion vectors | Requires permitted frame evidence | Unverified |
| Neural consumer / runtime | None supplied; exactly one compatible consumer and legitimate runtime would be required | Missing |
| Standalone neural backend | One isolated host `--test` attempt initialized NGX, then stopped before evaluation because SuperSampling was unavailable without a local DLSS runtime. No neural consumer or feature-18 model was present. | Unverified; no evaluations |
| LOTRO in-game result | No launch, injection, capture, or modification | Not tested |
| UI isolation | Upstream processes the UI with the scene; no LOTRO-specific mask exists | Unsupported |

The upstream README lists **The Lord of the Rings: War in the North – Legacy Edition**. That is another game and provides no LOTRO evidence. Estimated optical-flow motion vectors can ghost or flicker in fast motion. `work_resolution` below 100% reduces work extent on D3D11 but is not DLSS Super Resolution or a validated LOTRO quality mode.

Upstream [issue #47](https://github.com/jlrouzies-fr/DLSS5-Feeder/issues/47) includes NGX initialization failures in some in-process configurations, including an RTX 5080. The v1.19.0 release notes also discuss MSAA depth-selection diagnostics. These are reasons to log evidence before modifying rendering code, not predictions of LOTRO behavior.

Standing Stone Games' client-modification and third-party-tool terms need a permitted test path before game-side work. No package script installs a proxy DLL, changes anti-cheat/security settings, or edits LOTRO files.

The standalone host attempt caused NVIDIA's driver runtime to create its model cache under `C:\ProgramData\NVIDIA\NGX\models` and log an ACL update for that cache. No further backend attempt was made after observing this. The prior ACL was not recorded, so restoration was not attempted.
