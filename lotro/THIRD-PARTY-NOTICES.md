# Third-party notices

This package is based on DLSS5-Feeder v1.19.0 by Jean-Laurent Rouzies under the MIT license in `LICENSE`. The upstream root license also credits NIGos for portions derived from `dlss5-dx11-bridge`; its referenced `external/bridge-1.0.19/LICENSE` is not present in the v1.19.0 source tree. No bridge binary or source is bundled here.

- **MinHook** (Tsuda Kageyu; includes HDE components), BSD-2 style terms: `licenses/MinHook-LICENSE.txt`.
- **Dear ImGui** (Omar Cornut), MIT: `licenses/ImGui-LICENSE.txt`.
- **ReShade add-on headers** (Patrick Mours), SPDX `BSD-3-Clause OR MIT` in upstream headers. This package uses them under the MIT option. Copyright (c) 2021 Patrick Mours. The MIT grant and disclaimer in `LICENSE` apply to these header-derived portions, with this copyright notice.
- **NVIDIA DLSS/NGX SDK** headers and `nvsdk_ngx_d.lib` were used to compile the object code. The SDK itself and neural runtime DLLs are not bundled. The applicable license is reproduced in `licenses/NVIDIA-RTX-SDK-LICENSE.txt`; the pinned source is `NVIDIA/DLSS` at `374959484e79a640feaba44c93ac8cfb0a03f5b5`.

This software contains source code provided by NVIDIA Corporation.
- **Khronos Vulkan-Headers** were used as build headers and are not bundled. Pinned source: `KhronosGroup/Vulkan-Headers` at `c46850864f4661461b0f6cb9922c058ffea4915e`, files marked Apache-2.0 OR MIT.

The package does not include ReShade, a motion-vector provider, a neural consumer, `nvngx_dlss.dll`, `nvngx_dlssnr.dll`, LOTRO files, or any modified NVIDIA runtime. Distribution and use of separately obtained components remain subject to their own licenses and game terms.
