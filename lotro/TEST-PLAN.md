# Prototype acceptance plan

## Gate 1: baseline (offline)

- Record exact upstream SHA, pinned NGX SDK and Vulkan-Headers SHAs, compiler/SDK versions, and SHA-256 of build inputs and outputs.
- Compile and link the unchanged x64 add-on and all existing upstream CI targets. Preserve build logs.
- Run the existing `tests/test-vk-present-order.bat` on a disposable host with no game running. A pass concerns its present-order scenario only.

## Gate 2: LOTRO branch (offline)

- Rebuild all upstream targets and run new script checks on synthetic PE and disposable directories.
- Verify the preflight script handles missing, single, and ambiguous executable candidates; x86/x64 PE identification; and a preferences renderer hint without claiming a live renderer.
- Verify package generation refuses occupied destinations, ZIP verification reads every entry and rejects corruption or unsafe names, and restoration only previews a valid allowlisted manifest. Test `-Apply` only against disposable fixtures.
- Review branch diff against upstream and run CI on the branch. A green CI run establishes compilation and these offline tests, not game compatibility.

## Gate 3: standalone neural backend (later)

- Establish official or otherwise licensed provenance, versions, signatures, and hashes for exactly one neural consumer and the NVIDIA runtime. Do not use the upstream installer or modified 310.8.Lecram package.
- Only then run `dlss5-feed-host64.exe --test` outside the game and retain logs. `300/300` evaluations alone proves DLAA execution; require consumer and feature-18 evidence to claim a neural pass.

## Gate 4: LOTRO integration (pending permission and evidence)

- Confirm client terms and obtain a permitted game-side test path. Record real executable, API, bitness, and existing graphics modifications before any installation.
- Capture permitted evidence for selected color/depth resources, motion vectors, UI ordering, resets, shutdown, resolution 5120x1440, artifact behavior, and frame times. Keep `enabled=0` as immediate bypass.
- Implement a UI mask or shader-group selection only when captures identify stable resources. No shader hashes, offsets, or performance results are assumed.
