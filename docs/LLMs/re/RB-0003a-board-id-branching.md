<!-- SPDX-License-Identifier: BSD-3-Clause -->

# RB-0003a: Where 25G241 branches on model / board-id

Brief: control plane `docs/Research/briefs/RB-0003a-board-id-branching.md` (ADR-0003, question 1). Issue: ownback/Ryzentosh-EFI#1.
Date: 2026-11-27. Build: macOS 26.7.1 **25G241**, x86_64. Method: read-only (plist reads with `plistlib`, byte searches of the
kernel collections and the x86_64h dyld shared cache attributed to images through `kmutil inspect` and the cache `.map`, `ioreg`,
`kmutil showloaded`, `pmset`). No boot-config change, no ESP write, no Apple code or disassembly in this repo.
Author: Project Lead, claude-opus-5-5/high.

**Labels.** **verified** = read directly from the named file on 25G241 or observed on the live system. **inferred** = follows from
what was read (strings next to each other, naming, matching rules), not traced through code or tested.

**Citation format.** `plist:<path>#<key path>`; `KC:<Boot|System>KernelExtensions.kc` + fileset entry + file offset of the
`board-id` string; `DSC:<image>@<VM address>` in `dyld_shared_cache_x86_64h*` of 25G241; `live:` for an observation on this machine.
Board-ids are public model constants (cross-checked against `repositories/OpenCorePkg/AppleModels/DataBase`, BSD-3-Clause).

## 0. The Tahoe Intel models and their board-ids

| Model | board-id | Source |
|---|---|---|
| MacPro7,1 (Mac Pro 2019) | `Mac-27AD2F918AE68F61` | verified: `plist:/System/Library/CoreServices/PlatformSupport.plist#SupportedBoardIds`, AppleModels `MacPro/MP71.yaml` |
| iMac20,1 / iMac20,2 (iMac 27" 2020) | `Mac-CFF7D910A743CAAF` / `Mac-AF89B6D9451A490B` | verified: same plist, AppleModels `iMac/IM201.yaml`, `IM202.yaml` |
| MacBookPro16,1 / 16,4 (16" 2019) | `Mac-E1008331FDC96864` / `Mac-A61BADE1FDAD7B05` | verified: same plist, AppleModels |
| MacBookPro16,2 (13" 2020, four TB3) | `Mac-5F9802EFE386AA28` | verified: same plist, AppleModels |

`PlatformSupport.plist` (the list boot.efi and the installer check) also lists `Mac-112818653D3AABFC` (not in AppleModels) and
`VMM-x86_64`. So **an x86_64 VM, which has no T2, is a supported Tahoe platform** (verified). The models match Apple's Tahoe page
(https://support.apple.com/en-us/122867: MacBook Pro 16" 2019, MacBook Pro 13" 2020 four TB3 ports, iMac 27" 2020, Mac Pro 2019).

## 1. Live-system finding first: the root node has no `board-id`

| Fact | Label | Evidence |
|---|---|---|
| `IOService:/` (IOPlatformExpertDevice, `MacPro7,1`) has a property **`board-ix`** = `Mac-27AD2F918AE68F61` and **no `board-id`**. `ioreg -l` finds no `board-id` anywhere in the IOService plane. | verified | live: `ioreg -rd1 -c IOPlatformExpertDevice` (key list), `ioreg -l \| grep -c board-id` = 0 |
| `IODeviceTree:/efi/platform` still has `board-id` = `Mac-27AD2F918AE68F61`. | verified | live: `ioreg -p IODeviceTree -rd1 -n platform` |
| The live config has one kernel patch that writes `board-ix`: comment "Pike R. Alpha \| AGDP board-id -> board-ix (agdpmod=pikera without WhateverGreen) \| 26+", Identifier `com.apple.driver.AppleGraphicsDevicePolicy`, Find `board-id`, Replace `board-ix`, Count 0, Limit 0, MinKernel 25.0.0. No injected kext contains the string `board-ix`. | verified | live: internal ESP `EFI/OC/config.plist#Kernel/Patch` (read only); `strings` over `EFI/OC/Kexts/*` |
| AppleGraphicsDevicePolicy is a **SystemKC** fileset entry. The kexts that hold the `board-id` C-string in the **BootKC** are AppleACPIPlatform, AppleAHCIPort, AppleBusPowerController, AppleKeyStore, AppleMCP89RootPortPM and IOUSBHostFamily. AppleACPIPlatform's string sits next to `SystemSerialNumb`, `serial-number`, `IOPlatformSerialNumber` and a model/board-id table. | verified (membership, string placement) | `kmutil inspect --show-fileset-entries`; KC:Boot AppleACPIPlatform @0x13D1331 |
| By OpenCore's source, this patch **cannot apply to AGDP or to any other kext**. `Identifier` is resolved against the BootKC prelink info only, with no fallback (`OcAppleKernelLib/PrelinkedContext.c:1274-1277`: "Failed to pk find" → return), and the BootKC contains no `AppleGraphicsDevicePolicy` string at all. This assumes the ESP's OpenCore 1.0.8 behaves like the checked-out source. | verified (source, byte count), inferred (that 1.0.8 matches) | `repositories/OpenCorePkg/Library/OcAppleKernelLib/PrelinkedContext.c`; `grep -c AppleGraphicsDevicePolicy BootKernelExtensions.kc` = 0 |
| **What writes `board-ix` is unresolved.** Hypothesis A: OpenCore applies the patch to a BootKC string after all (for example AppleACPIPlatform's, which sits next to the serial-number publishing strings), contrary to the source reading above. Hypothesis B: the patch is a no-op and another component renames the property. No ESP kext and not `/Library/Extensions/VermilionAccel.kext` contains the string, so a runtime-built name would be needed. Hypothesis C: OpenCore 1.0.8 has a SystemKC path the checkout lacks, and the rename is a side effect of it. The OpenCore log on the ESP has 101 lines, stops before the kernel stage and has no patcher lines. | open | live: `opencore-2026-11-27-115226.txt`; `strings` over ESP kexts and VermilionAccel |
| AGDP is loaded with **no instance**, although Vermilion publishes an `AppleGraphicsDeviceControl` subclass (`PhxDeviceControl`, registered) that AGDP matches. So AGDP most likely matched and then failed in probe or start. A real Mac Pro has an AGDP instance. | verified (state), inferred (probe/start failure) | live: `ioreg -i -rn PhxDeviceControl` (class chain `AppleGraphicsDeviceControl:PhxDeviceControl`); `kmutil showloaded` |
| Prior bring-up notes on this machine: the installer GUI first came up after this patch was added. They say Navi cards hang on Tahoe without it. That is one confounded data point, but the patch is **load-bearing in practice**, whatever its mechanism. | verified (notes say so), not re-tested | `repositories/vermilion-xtx/.agents/findings/2026-11-18-first-boot-acpi.md` ("Eighth boot"), `docs/PROJECT_KNOWLEDGE.md` (study-only) |
| X86PlatformPlugin is attached with `IOPlatformPowerProfile = {Name = "Placeholder"}`, the personality default. It did **not** load `Resources/Mac-27AD2F918AE68F61.plist` (CPUFloor 1200, StandbyDelay 86400, ProximityWake 0, **DeepSleepCap false**, an IOPlatformSystemSleepPolicy blob, FrequencyVectors). The plugin reads `board-id` and loads `%s.plist`. | verified (state, plist) | live: `ioreg -rc X86PlatformPlugin`; KC:System X86PlatformPlugin @0x14D86395; `plist:…/X86PlatformPlugin.kext/Contents/Info.plist#IOKitPersonalities/*/IOPlatformPowerProfile` |
| There are two candidate causes for the placeholder, neither proven: the missing root `board-id`, or the plugin skipping the database read on an AMD CPU with `machdep.xcpm.mode = 0` (strings `isXcpmWorthy … getBoardID`, `probe - deemed XCPM worthy`). | inferred (both) | live: `sysctl machdep.xcpm.mode` = 0; KC:System X86PlatformPlugin @0x14D85F89 |
| `pmset -g cap` lists no `standby`, `powernap` or `autopoweroff`. Not compared with a real Mac Pro. The MacPro7,1 profile has `DeepSleepCap = false`, and `womp` depends on the NIC driver. | verified (here); no real-Mac reference | live: `pmset -g`, `pmset -g cap` |
| The live root has `target-type = "Mac"`. No 25G241 plist found keys on `target-type`. | verified (value), not searched in code | live: `ioreg -rd1 -c IOPlatformExpertDevice` |

**Consequence for the EFI (no recommendation yet).** The root `board-id` is missing, and MacPro7,1's model data reaches only the
consumers that read `/efi/platform`. Restoring it is **not** a simple "drop the patch". (a) The patch is load-bearing for the
display in practice (row above). (b) With `board-id` back on the root, `AppleIntelMCEInterruptController` matches
`IOPlatformExpertDevice` by `IOPropertyMatch board-id` (MacPro7,1 is in its list). AppleMCEReporterDisabler doesn't stop that:
its `AppleACPICPU` personality (score 1100) only outbids Apple's own ACPI CPU personality (score 1000). So **AppleIntelMCEReporter
could load on AMD and panic**. Today it is most likely kept out by the missing `board-id` (inferred). (c) AGDP would get a board-id
and might attach to `PhxDeviceControl`, which is a behaviour change.

Experiment, queued in ROADMAP as **E-AGDP** after E1 is promoted (E1 is a byte-identical round trip and leaves patch 25 alone). Each boot needs an owner F8 boot. **Step 0:** an OpenCore DEBUG log that reaches the kernel patcher, to
see whether patch 25 reports Not Found (expected under B/C) or success (A). **Step 1:** a candidate with only that patch disabled.

| Hypothesis | Expected after step 1 |
|---|---|
| A (the patch renames a BootKC string) | root `board-id` back; X86PP profile loads unless the XCPM cause holds; AGDP may attach; MCE risk |
| B (something else renames) | no change: `board-ix` stays; the patch was a no-op |
| C (OC SystemKC path) | root `board-id` back, AGDP reads `board-id` |

Pass/abort criteria: abort if `AppleIntelMCEReporter` is loaded (`kmutil showloaded`) or the boot panics. Otherwise record root
`board-id` / `board-ix`, the X86PlatformPlugin profile name, `pmset -g cap`, the AGDP instance, and whether the display comes up.

## 2. Inventory: every 25G241 branch on board-id / model found

Columns follow the brief. "MacPro7,1 value" is what a real Mac Pro gets. "Alternatives" lists the other Tahoe Intel models.
"Here today" is the live system, as far as it differs.

### 2.1 Graphics policy and power

| Component | Key | MacPro7,1 value | Alternatives | User-visible effect | Evidence |
|---|---|---|---|---|---|
| AppleGraphicsDevicePolicy (AGDP) | `IOKitPersonalities/AppleGraphicsDevicePolicy/ConfigMap/<board-id>`, fallback `Default` | **no entry** → `Default = {none}`: no policy, nothing unloaded | iMac20,1/20,2 → `Config3` (GFX0: EDID index 0, FeatureControl 12; IGPU unloaded). MacBookPro16,x: no entry (Default). | Inferred from the plist (the lookup code path wasn't traced): with no entry, AGDP falls back to `Default = {none}`, which imposes no display policy on MacPro7,1. iMac20 enforces its GFX0 policy. Whether AGDP then behaves well with a third-party GPU is a separate question (§1: today it has no instance). | verified (plist), inferred (fallback): `plist:/System/Library/Extensions/AppleGraphicsControl.kext/Contents/PlugIns/AppleGraphicsDevicePolicy.kext/Contents/Info.plist#IOKitPersonalities/AppleGraphicsDevicePolicy/{ConfigMap,Default,Config3}`; KC:System AGDP @0x13D531E6 (`ConfigMap`, `Default`, `board-id`, `none`, `unload`) |
| AGDP (live) | instance | — | — | No AGDP instance, although Vermilion's `PhxDeviceControl` (an `AppleGraphicsDeviceControl` subclass) is registered. So AGDP likely matched and failed in probe/start (§1). | verified (state): live `ioreg -rc AppleGraphicsDevicePolicy` empty, `ioreg -i -rn PhxDeviceControl`, kext loaded; inferred (failure point) |
| AppleGraphicsPowerManagement (AGPM) | `IOKitPersonalities/AGPM/Machines/<board-id>` | `SlotControl = 1`, per-device entries `Vendor1002Device{66a3,66a7,67df,6867,686d,686e,7310,7340,73a2,73ab,73e0}` (Vega II, Polaris, Vega, Navi 10/14/21/23): `AGDCEnabled 1`, `Heuristic ID -1`, `control-id 17`, power states 0–15. **No `744c` (Navi 31)** | iMac20,x: `GFX0` (AGDC, heuristic -1) + `IGPU` (heuristic 2). MacBookPro16,1/16,4: `GFX0` + `IGPU` with Boost tables. MacBookPro16,2: `IGPU` only. | AGPM drives GPU power states for listed devices. RX 7900 XTX is not listed under any model, so Ryzentosh-dGPU must own its power management (no SMBIOS gain). | verified: `plist:/System/Library/Extensions/AppleGraphicsPowerManagement.kext/Contents/Info.plist#IOKitPersonalities/AGPM/Machines/Mac-27AD2F918AE68F61`; KC:System AGPM @0x13DBE93C (`board-id`, `Machines`, `SlotControl`, "boardID doesn't exist") |
| AppleMuxControl2 | `ConfigMap/<board-id>` | no entry | MacBookPro16,1/16,4 → `Config3` (dual-GPU mux) | Laptop GPU switching only. | verified: `plist:…/AppleMuxControl2.kext/Contents/Info.plist#IOKitPersonalities/AppleMuxControl/ConfigMap` |
| AGDCBacklightControl | `ConfigMap/<board-id>` | no entry | MacBookPro16,1/16,4 → `true` | Internal panel backlight only. | verified: `plist:…/AGDCBacklightControl.kext/Contents/Info.plist#IOKitPersonalities/AGDCBL/ConfigMap` |
| AppleGPUWrangler, ApplePolicyControl, AppleMGPUPowerControl, AppleGFXHDA | `board-id` string read | not in plists | — | Read board-id in code, but no Tahoe board-id appears in their plists or C-strings. Effect not determined. | verified (string present): KC:System entries @0x13D0872D (GFXHDA), @0x13D39F29 (GPUWrangler), @0x13D9E226 (PolicyControl), @0x13D69ECC (MGPUPowerControl) |
| GPUInfo.framework (GPU ROM / PSF update) | board-id → `Type1/Type2/Type3` table | listed (with iMacPro1,1, iMac19,x, iMac20,x, MacBookPro15,3, MacBookPro16,1/16,4) | which board-id maps to which `TypeN` can't be read from the de-duplicated C-strings | Classifies the GPU firmware update path used with `psfupdater` (strings `nvram GPUROM`, `PSFU_STATUS`). On non-Apple GPUs, inferred to be a no-op. | verified (list): DSC:GPUInfo @0x7ff9145c2176..21e5; inferred (meaning); mapping open |

### 2.2 CPU power, sleep, platform

| Component | Key | MacPro7,1 value | Alternatives | User-visible effect | Evidence |
|---|---|---|---|---|---|
| X86PlatformPlugin | `Resources/<board-id>.plist` → `IOPlatformPowerProfile` | CPUFloor 1200, StandbyDelay / StandbyDelayHigh 86400, StandbyBatteryThreshold 50, NetworkTimerDelay 900, ProximityWake 0, ThresholdExtNonHID 2, IOPlatformSystemSleepPolicy, FrequencyVectors (Xeon W), pmspFile 12 | Each Tahoe model has its own `Mac-<id>.plist` (all six present) | Sleep/standby policy and the XCPM frequency vectors. On AMD, XCPM isn't used (DummyPowerManagement + SMCProcessorAMD), but the standby/sleep policy part still applies. **Here today: `Placeholder`** (section 1). | verified: `…/X86PlatformPlugin.kext/Contents/Resources/Mac-27AD2F918AE68F61.plist`; KC:System X86PP @0x14D86395, @0x14D85F89 (`isXcpmWorthy … getBoardID`, `unknown board-id doesn't begin with Mac-`) |
| AppleIntelMCEReporter | `IOPropertyMatch[].board-id` | **matches** (`Mac-27AD2F918AE68F61`, also MacPro6,1, iMacPro1,1) | others: no match | `AppleIntelMCEInterruptController` matches **`IOPlatformExpertDevice`** by `IOPropertyMatch board-id`. Then `AppleIntelMCEReporter` matches the `AppleIntelMCEInterruptNub` it publishes. Intel machine-check reporting on Xeon models; on AMD it is reported to panic. The live AppleMCEReporterDisabler doesn't compete with either personality (§1). Today the match most likely fails because the root has no `board-id`. **Risk: restoring `board-id` re-arms it.** | verified: `plist:/System/Library/Extensions/AppleIntelMCEReporter.kext/Contents/Info.plist#IOKitPersonalities` (both personalities); live: CPU nodes show `IOPersonalityPublisher = acidanthera.AppleMCEReporterDisabler`; inferred (current state, panic) |
| boot.efi / installer compatibility | `PlatformSupport.plist` `SupportedBoardIds`, `SupportedModelProperties` | listed | all six listed + `VMM-x86_64` | Decides whether Tahoe installs and boots without `-no_compat_check`. | verified: `plist:/System/Library/CoreServices/PlatformSupport.plist` |
| Slot / memory notifications | LaunchAgents `LimitLoadToHardware/model` | `com.apple.ExpansionSlotNotification` and `com.apple.MemorySlotNotification` load **only on MacPro7,1** (Expansion also on Mac14,8) | not loaded | Mac Pro–only "PCIe/memory configuration" alerts. RestrictEvents (`revblock=auto` → `pci`) blocks them here (see RB-0003b §4). | verified: `plist:/System/Library/LaunchAgents/com.apple.{ExpansionSlot,MemorySlot}Notification.plist#LimitLoadToHardware` |
| ExpansionSlotSupport.framework | `MacPro7,1` string | MacPro7,1 slot model | — | System Information / Settings PCI slot layout (Mac Pro chassis). | verified (string): DSC:ExpansionSlotSupport @0x7ffc0b5bf3e0; inferred (use) |
| AppleSystemInfo.framework | board-id from `IODeviceTree:/efi/platform` + `chassis-type` | `Mac-27AD2F918AE68F61` + "Rack Mount" → rack vs tower marketing name | — | About This Mac name/image. It reads `/efi/platform`, which still has board-id here (section 1). | verified (strings `IODeviceTree:/efi/platform`, `chassis-type`, `Rack Mount`): DSC:AppleSystemInfo @0x7ff81088dbfc |
| USB | AppleUSBHostPlatformProperties `IOKitPersonalities_x86_64/<model>-XHC1`; IOUSBHostFamily and AppleBusPowerController read `model`/`board-id` | **no MacPro7,1 entry** | iMac20,1/20,2: XHC1 port map | Port maps / power pools by model. MacPro7,1 relies on ACPI, and the live system uses USBToolBox + UTBMap, so there's nothing to gain from the model. | verified: `plist:…/IOUSBHostFamily.kext/Contents/PlugIns/AppleUSBHostPlatformProperties.kext/Contents/Info.plist`; KC:Boot IOUSBHostFamily @0x2D562A5, AppleBusPowerController @0x173018B |

### 2.3 Media: GVA / VideoToolbox / FairPlay

| Component | Key | MacPro7,1 value | Alternatives | User-visible effect | Evidence |
|---|---|---|---|---|---|
| AppleGVA (decode/encode policy) | `Info.plist#System Support/<board-id>` | `hwe true, hwe420 true, ke1 true, interlacedOff true, allowFrameReordering false` | iMac20,x: `facetimeDecode, forceOfflineRenderer, hwe, hweBGRA, ke1, pp 1`. MacBookPro16,1/16,4: `burstSize 4, facetimeDecode, hwe, hweBGRA, ke1, pp 2`. 16,2: adds `facetimeLPEnc`, `pp 3`. | Hardware encode on, plus the per-model feature flags VideoToolbox uses. | verified: `plist:/System/Library/PrivateFrameworks/AppleGVA.framework/Versions/A/Resources/Info.plist#System Support` |
| AppleGVA (accelerator choice) | board-id compiled into the code | MacPro7,1 is in a 3-entry list with iMacPro1,1 and MacPro6,1 (the models without an Intel iGPU), next to "force AMD for flow_id", `gvaForceAMDAVCDecode/Encode`, `gvaForceAMDHEVCDecode`, "invalid boardId" | others pick Intel (QuickSync) or the T2 path | Inferred: **MacPro7,1 routes decode/encode to the AMD accelerator.** That fits a Ryzentosh-dGPU VCN 4 VideoToolbox path (ADR-0003 question 2). Where GVA reads `board-id` wasn't traced. If it reads the root, it may fail today (§1). | verified (strings): DSC:AppleGVA @0x7ffa0c64887e..88a8; inferred (semantics) |
| AppleGVAHEVCEncoder.bundle | `System Support/<board-id>` | `vendor8bit = 1` | none of the others | Inferred from the key name: 8-bit HEVC encode goes to the GPU vendor encoder (AMD) on MacPro7,1 (iMacPro1,1 has it too). The others use Intel or the T2. | verified (value): `plist:/System/Library/Video/Plug-Ins/AppleGVAHEVCEncoder.bundle/Contents/Info.plist#System Support`; inferred (meaning) |
| AppleGVACore / AppleVPA | `System Support/<board-id>` | **no entry** | iMac20,x and MacBookPro16,x: `pp` (GVACore), `jpeg true` (VPA) | Intel-iGPU post-processing / JPEG. None on MacPro7,1 (no iGPU), so nothing is lost on Ryzen. | verified: `plist:…/AppleGVACore.framework/…/Info.plist`, `…/AppleVPA.framework/…/Info.plist` |
| MediaToolbox (FairPlay support, `fpsupport`) | `hw.model` against a compiled list | **in the list** | list = every T2 Mac: MacBookPro15,1–16,4, iMacPro1,1, iMac20,1/20,2, MacPro7,1, MacBookAir8,1/8,2/9,1, Macmini8,1 | Strings next to it: `HDR_iOSAppOnMac`, `ASDevices`, `hdr10plusenabled`, `…fpsupport.HDRBatonAvailable…`, `…fpsupport.4kBatonAvailable…`, `fpSupport_GetVideoRangeForCoreDisplayWithPreference`, `kern.hv_vmm_present`. Inferred: a model-level eligibility list for FairPlay 4K/HDR (or HDR) playback that equals the Intel T2 set. Polarity and use weren't traced, so "MacPro7,1 passes" is inferred too. | verified (list, neighbours): DSC:MediaToolbox @0x7ff81693bd42..bd9b; inferred (gate meaning, polarity). Netflix: UHD needs "Apple processor or Apple T2 Security chip" (https://help.netflix.com/en/node/55764) |

### 2.4 Audio

| Component | Key | MacPro7,1 value | Alternatives | User-visible effect | Evidence |
|---|---|---|---|---|---|
| AudioDSP voice processing | `vp_platform_info.plist#<board-id>` | `18160` | iMac20,x 20185; MacBookPro16,1 19152; 16,2 19214; 16,4 20215 | Picks the voice-processing (echo-cancel) platform tuning ID for FaceTime/Siri audio. | verified: `plist:/System/Library/Components/AudioDSP.component/Contents/Resources/Tunings/vp_platform_info.plist` |
| Built-in speaker/mic DSP tunings | `/System/Library/Audio/Tunings/<board-id>/{ADM,DSP}`, `DeviceDSPDatabase.plist#<board-id>` | **folder exists** (`ADM/config.plist`, built-in **speaker** graphs/strips; `DeviceDSPDatabase` has a `Built-in Speaker` entry). No mic strips. | all six have folders; mic strips for MacBookPro16,x and iMac20,1 | Tunes the Mac Pro's internal speaker, which on a real Mac Pro sits behind the T2 audio path. This machine has no such speaker, so nothing to gain or lose. | verified: directory listing; `plist:/System/Library/Audio/Tunings/DeviceDSPDatabase.plist` |
| AppleHDA / USB audio | `board-id` | — | — | No `board-id` C-string in an AppleHDA or AppleUSBAudio fileset entry (RB-0003a KC scan; AppleGFXHDA is the only audio hit). USB audio isn't model-gated. | verified (string absence) |

### 2.5 Continuity, Sidecar, AirPlay, Displays pane

| Component | Key | MacPro7,1 value | Alternatives | User-visible effect | Evidence |
|---|---|---|---|---|---|
| SidecarCore | compiled model **deny** list | not listed → eligible | no Tahoe model listed (list = iMac13–16, MacBook8,1, MacBookAir5–7, MacBookPro9–12,1, Macmini6–7, MacPro5,1/6,1) | Sidecar isn't gated by any Tahoe SMBIOS. What remains is hardware (Wi-Fi/BT/AWDL, Ryzentosh-AIR). | verified (list): DSC:SidecarCore @0x7ff90e22af10…; inferred (deny semantics) |
| UniversalControl | compiled model deny list | not listed | no Tahoe model (iMac16, MacBookAir7, MacBookPro11,4–12,1, Macmini7,1, MacPro6,1) | Same as Sidecar. | verified (list): DSC:UniversalControl @0x7ffe00b4466c… |
| AirPlaySupport (AirPlay to Mac) | compiled model lists | not listed | no Tahoe model (old Macs + iMac17–18, MacBookPro13–14, Macmini8,1) | Not SMBIOS-gated on Tahoe models. | verified (list): DSC:AirPlaySupport @0x7ff91631b934… |
| Continuity Camera / CMCapture | compiled model list | not listed | no Tahoe model | Apple: "Any Mac compatible with macOS Ventura 13 or later" (https://support.apple.com/en-us/102546). Not SMBIOS-gated. | verified (list): DSC:CMCapture @0x7ff905aba0ce…; Apple page |
| Sharing.framework | compiled model list | not listed | lists MacPro6,1 and Apple-silicon models only | No Tahoe Intel model gated. | verified (list): DSC:Sharing @0x7ff81919cd02… |
| Displays pane (MonitorPanel, CoreDisplay, IOPresentment, CoreBrightness) | compiled model lists | not listed | only MacBookPro10,2/11,1 (MonitorPanel), MacPro6,1 (CoreDisplay), two older board-ids (IOPresentment), iMac12,x (CoreBrightness) | **No Tahoe model in any Displays-pane list**, so HDR, refresh rates and reference modes aren't model-gated on 25G241. They follow the display (EDID/DisplayID) and the GPU driver. | verified (absence of Tahoe strings): dyld-cache scan for `<Model><n>,<n>` and `Mac-<16 hex>`; inferred (that no other mechanism gates them) |
| libMobileGestalt | compiled board-id list after the key names `supports-spatial-facetime` / `board-id` | **not listed** | lists MacBookPro16,1/16,2/16,3/16,4, iMac20,1/20,2, MacBookPro15,x, MacBookAir8,x/9,1. Not MacPro7,1, iMacPro1,1 or Macmini8,1. | Some MobileGestalt answer is true only on T2 Macs with a built-in camera/mic. **Which answer is unidentified** (MG keys are hashed). Candidates: a FaceTime/camera or "Hey Siri" capability. Choosing MacPro7,1 forgoes it, but this machine has no built-in camera or mic anyway. | verified (list): DSC:libMobileGestalt @0x7ff809198984..8a56; inferred (meaning) |

### 2.6 Other hits not analysed further

Board-id or model strings also appear in `/usr/libexec/airportd`, `/usr/sbin/bluetoothd`, `/usr/sbin/BlueTool`,
`/usr/sbin/WirelessRadioManagerd`, `/usr/libexec/psfupdater`, `/usr/sbin/systemstats`, `/usr/bin/powermetrics`, and in the
dyld-cache images ServerInformation (a model↔board-id table), ProductKit/ProductKitCore (marketing data), PowerlogCore and
PowerUI (old laptops), AVConference (MacBookPro16,1 camera resolution), SafariSharedUI, ScreenSharingKit, OSInstaller,
AudioVideoBridging and DVDPlayback (verified: grep/scan). The wireless daemons belong to RB-WIRELESS/AIR. The rest are either
marketing tables or lists without a Tahoe model. KC string hits in AppleAHCIPort, AppleMCP89RootPortPM,
AppleThunderboltEDMSource, ApplePlatformEnabler (DVD/ODS flags for old models) and AppleKeyStore (next to `chip-id`,
`unique-chip-id`, `boot-manifest-hash`) were not traced.

## 3. What this means for the model choice (input for RB-0003c)

1. Among the Tahoe models, only **MacPro7,1** has (a) no AGDP policy, (b) AGVA routing to the AMD accelerator and the HEVC vendor
   encoder, (c) no Intel-iGPU-only media flags that would be missing here, and (d) no internal-panel/mux/backlight configs.
   iMac20,x would bring AGDP `Config3` and an `IGPU` expectation. The MacBookPro16,x would bring mux and backlight configs plus
   battery and laptop power profiles. (verified data, inferred conclusion)
2. MacPro7,1 costs these model-gated items: the Mac Pro–only slot/memory UI (handled by RestrictEvents) and the unidentified
   MobileGestalt camera/mic capability (no such hardware here). (verified/inferred as above)
3. Nothing in the Displays pane, Sidecar, Universal Control, AirPlay to Mac or Continuity Camera is gated by a Tahoe model. Parity
   there depends on hardware drivers, not SMBIOS. (verified for the strings present)
4. RX 7900 XTX (`744c`) is in no AGPM table, so GPU power management can't come from SMBIOS on any model. (verified)
5. On this machine the MacPro7,1 choice is only half applied today: the root has no `board-id`. Restoring it has risks (MCE reporter,
   AGDP attaching) and needs the experiment in section 1 first. (verified state, inferred effects)

## 4. Open items

- Section 1 experiment = E-AGDP (Orchestrator, after E1). Read-only on this branch. Also: does AppleIntelMCEReporter still panic on AMD on 25G241?
- REA trace of where X86PlatformPlugin, AGPM and AppleGVA read `board-id` (`IOService:/` vs `/efi/platform`). The strings here
  don't settle it. The KDK 25G241 would help for the kexts.
- Identify the libMobileGestalt answer behind the board-id list.
- `platform-feature` on the live root node has non-zero upper 32 bits, while the AppleModels value for MacPro7,1 is `0x0`. Origin and
  effect unknown. Value withheld until it is shown not to be machine-derived.
- `CoreTypes.bundle/Contents/Info.plist` maps the models to device icons (`com.apple.device-model-code`), cosmetic only.
  `Mac-112818653D3AABFC` (in PlatformSupport) has an X86PlatformPlugin plist but no AGDP or GVA entry.
