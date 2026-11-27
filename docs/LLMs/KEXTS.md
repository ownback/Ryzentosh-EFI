# KEXTS: what is in EFI/OC, why, and what replaces it

The EFI tree (`EFI/OC`) was imported on 2026-11-27 from the live internal ESP (byte-identical to the USB known-good seeded
2026-11-26). Only text that we may redistribute is in git: `config.plist` (identity scrubbed, AMD_Vanilla kernel patches
left out; see the end of this file), the two SSDTs and the codeless USB map. **Every other file is a binary that is not committed.** Each one is pinned by SHA-256 in
[`EFI/BINARIES.sha256`](../../EFI/BINARIES.sha256), and the table below names its source.

Verification on 2026-11-27: every upstream binary below was compared with the file in its release zip (zip SHA-256
listed) and is **byte-identical**. "Legacy" binaries have no public upstream; they exist only in the known-good tree
and in the control plane's `backups-local/legacy-vermilion/` archive.

## How a complete tree is assembled (no build script)

1. Check out this repo at the commit under test.
2. Copy `EFI/OC` to a working directory (outside git, e.g. this repo's gitignored `temp/`).
3. Copy every file listed in `EFI/BINARIES.sha256` from the USB known-good `EFI/OC` (or, for upstream files, from the
   release zip below) into the same relative path.
4. From the directory that holds `OC/`, run `shasum -a 256 -c <repo>/EFI/BINARIES.sha256`. Every line must say `OK`.
5. Put `kernel-patches.json` two levels above `OC/` (or pass `--kernel-patches`), and hand that `OC/` to the Root Orchestrator.
   At staging, `tools/efi-stage` inserts the private SMBIOS identity (SystemProductName, SystemSerialNumber, MLB, SystemUUID,
   ROM) from `.private/smbios.json` and the pinned AMD_Vanilla kernel patches.

A Ryzentosh component replaces a legacy binary only through its own tested release, one EFI change at a time
(ROADMAP E4/E5).

**End state** (owner decision 2026-11-27; the control plane's `docs/Architecture/EFI-END-STATE.md`): one Ryzentosh repo
ships one kext, named after the repo. `Kexts/` then holds only Lilu, VirtualSMC, RyzentoshCPU, RyzentoshPlatform,
RyzentoshWireless and RyzentoshGPU. AMFIPass, VermilionTrust and RyzentoshSSE are removed without a replacement.
`ACPI/` comes from Ryzentosh-ACPI (one SSDT per purpose). The "Replaced by" column below follows that plan.

## Kexts (load order = `Kernel/Add` order)

| # | Kext | Version | Source (release zip SHA-256) | License | In git | Why it is loaded | Replaced by |
|---|---|---|---|---|---|---|---|
| 0 | Lilu | 1.7.2 | [acidanthera/Lilu 1.7.2](https://github.com/acidanthera/Lilu/releases/tag/1.7.2) (`53967d7dcfaab01023a33df2e969a89522f13d6654a6a56ac4711b62dabf3ab8`) | BSD-3-Clause | no | Patch engine. Every kext here except AppleMCEReporterDisabler, MtkWirelessWifi, USBToolBox/UTBMap, VermilionBoot and RyzentoshSSE links against it | **Stays** in the end state (VirtualSMC and RyzentoshWireless's bluetoothd patch need it) |
| 1 | VirtualSMC | 1.3.8 | [acidanthera/VirtualSMC 1.3.8](https://github.com/acidanthera/VirtualSMC/releases/tag/1.3.8) (`2e29a8aaf91b4eb0bcdf5913ed17e70f5cf76531122acd4132eff7813a54de8b`) | BSD-3-Clause | no | A Mac has an SMC; this board has none. macOS needs the SMC keys to boot | **Stays** in the end state (SMC; every key must be backed by real hardware state or absent, ADR-0003) |
| 2 | NVMeFix | 1.1.3 | [acidanthera/NVMeFix 1.1.3](https://github.com/acidanthera/NVMeFix/releases/tag/1.1.3) (`e1d5657ab7ac31f69771708f7b80bf218ab9aa0b8e4c4fe6ff943983037e3dfb`) | BSD-3-Clause (LICENSE.txt) | no | APST/power management for the non-Apple NVMe (Phison E26, `1987:5026`) | **RyzentoshPlatform** (Ryzentosh-PLATFORM: NVMe power management) |
| 3 | RestrictEvents | 1.1.6 | [acidanthera/RestrictEvents 1.1.6](https://github.com/acidanthera/RestrictEvents/releases/tag/1.1.6) (`98170dfae195ddd28b5d95e3f040125a13ca783bcb9bd1e5b8c588e217b14ee6`) | BSD-3-Clause | no | MacPro7,1 memory and PCI slot warnings off (the board has no Mac Pro memory/PCI topology) | **RyzentoshPlatform** (Ryzentosh-PLATFORM: its jobs, preferably as OpenCore config data such as PlatformInfo CustomMemory, not process patches; SMBIOS choice per ADR-0003) |
| 4 | AppleMCEReporterDisabler | 1.2 (codeless) | acidanthera, [bugtracker#424](https://github.com/acidanthera/bugtracker/issues/424#issuecomment-535624313) (listed in OpenCorePkg `Docs/Kexts.md`) | none stated | no | AppleMCEReporter panics on AMD CPUs with MacPro7,1 | **RyzentoshCPU** (Ryzentosh-CPU: the AppleMCEReporter-blocking personality) |
| 5 | MtkWirelessWifi | 1.1.3 | [Dino-VN/MtkWireless v1.1.3](https://github.com/Dino-VN/MtkWireless/releases/tag/v1.1.3) (`1e6a2403a58ea630521b77f9d054e67d9a078f6188d9d1eee532a78d0ddaf65b`, the GitHub asset digest) | GPL-2.0-only (vendors the SimpleMtkWlan HAL and OpenBSD net80211) | no (GPL, kept out of this BSD repo) | Wi-Fi of the RZ616 / MT7922 (`14c3:0616`, subsys `105b:e0cd`); Tahoe-only (`MinKernel 25.0.0`). 1.1.3 (E-WiFi2 #12) adds MT7922 deaf-RX / firmware-SER / WFDMA auto-recovery, on by default (`amtk_autoreset=0` disables it, 30 s cooldown), and publishes `MTKWiFi*` health counters in ioreg. Its Info.plist is unchanged apart from the version. AirportMtkWlan 2.3.3 was tried as a replacement and rejected (E-WiFi #9, see below) | **RyzentoshWireless** (Ryzentosh-WIRELESS, GPL-3.0-only; MtkWirelessWifi is study-only there, never copied) |
| 6 | USBToolBox | 1.2.0 | [USBToolBox/kext 1.2.0](https://github.com/USBToolBox/kext/releases/tag/1.2.0) (`c315a3a5acfd496dd97d0d19b4fbd1d487103d2fd541c5651583d4c9cebcfe07`) | **no license** in the repo | no | USB map engine; applies UTBMap's ports (macOS limits each controller to 15 ports) | **RyzentoshPlatform** (Ryzentosh-PLATFORM: the USB port map as personalities) |
| 7 | UTBMap | 1.0 (codeless) | Vermilion `efi/` (study clone `ownback/vermilion-xtx`), generated 2026-11-22 for this board | MIT (SPDX in its `#comment`) | **yes** | The B650E-I USB map: chipset XH00 (8 of its 17 ports kept), CPU XHC0/XHC1 (4 each), XHC2 (1). Front-panel headers and the AURA LED port are left out | **RyzentoshPlatform** (Ryzentosh-PLATFORM: the USB port map as personalities) |
| 8 | SMCProcessorAMD | 1.0.1 | [macos86/SMCProcessorAMD 1.0.1](https://github.com/macos86/SMCProcessorAMD/releases/tag/1.0.1) (`2622e54c69b38a5e491edd2c9532d98a01a3d3ba23316adaed28af8f4efa8638`) | BSD-3-Clause | no | CPU temperature, package power and clocks as VirtualSMC keys (read-only) | **RyzentoshCPU** (Ryzentosh-CPU: CPU sensors as VirtualSMC keys) |
| 9 | BlueToolFixup | 2.7.2 | [acidanthera/BrcmPatchRAM 2.7.2](https://github.com/acidanthera/BrcmPatchRAM/releases/tag/2.7.2) (`e1c1c55347526d031a8ae2fdd1f52efa3019161e497fb38e1cfa809752f8af21`) | GPL-2.0 | no | bluetoothd patches for a non-Apple Bluetooth controller (needed by MtkWirelessBT) | **RyzentoshWireless** (Ryzentosh-WIRELESS: the bluetoothd patch is folded in, the one documented essential workaround) |
| 10 | MtkWirelessBT | 1.1.3 | Dino-VN/MtkWireless v1.1.3 (same zip as #5) | GPL-3.0-only (bundle copyright; ships google-libsbc LICENSE/NOTICE) | no | Bluetooth firmware loader for USB `0489:e0e2`. Needs Lilu (≥ 1.2.0 per its Info.plist; we load 1.7.2) and BlueToolFixup before it, plus the two `bluetooth*` NVRAM keys (both present). 1.1.3's Info.plist is unchanged apart from the version | **RyzentoshWireless** (Ryzentosh-WIRELESS: Bluetooth in the same GPL-3.0-only kext) |
| 11 | AMFIPass | 1.4.1 | [dortania/OpenCore-Legacy-Patcher @ d7a3d94f](https://github.com/dortania/OpenCore-Legacy-Patcher/blob/d7a3d94f67bee5bc26b68f042372fb6a847f9b02/payloads/Kexts/Acidanthera/AMFIPass-v1.4.1-RELEASE.zip) payload (`07b266145906db41f4b13a7938fbb173ea28888cc1fa65f84417f8820adc961e`) | closed source, "All rights reserved" | no | Relaxes AMFI (the `amfi=0x80` effect) so Vermilion's ad-hoc signed Metal plugin and accelerator load. **A defect under the parity rule** | **Removed without a replacement** (workaround; E4, gated by ADR-0004 and G-Switchover) |
| 12 | VermilionBoot | 1.0.0 | Legacy Vermilion build (archived) | Vermilion: MIT / nullarc MIT-or-GPL-2.0 parts. Legacy: the owner doesn't carry Vermilion's dGPU stack forward, so it is never committed | no | GPU bring-up kext for the live display stack; its debug selectors are used by the `phxboot` LaunchDaemon (needs `phxdebug=1`) | **RyzentoshGPU** (Ryzentosh-GPU: one kext for the RX 7900 XTX and the Raphael iGPU), at G-Switchover (E5) |
| 13 | VermilionTrust | 1.0.4 | Legacy Vermilion build (archived) | as #12 | no | AMFI library validation with an allow-list of Vermilion's cdhashes (needs Lilu) | **Removed without a replacement** (workaround; E4) |
| 14 | VermilionAudio | 1.7.3 | Legacy Vermilion build (archived) | as #12 | no | Lets AppleGFXHDA accept the RX 7900's HDMI/DP audio function `1002:ab30` (needs Lilu; inert until the daemon adds the ab30 personality) | **RyzentoshGPU** (Ryzentosh-GPU: HDMI/DP audio), at G-Switchover (E5) |
| 15 | RyzentoshSSE | 0.1.0 | Legacy `ownback/ryzentosh-sse` (repo deleted by the owner; `backups-local/legacy-vermilion/ryzentosh-sse-all-refs.bundle` is the only copy) | none published | no | Publishes an AppleSSE service that answers "not supported", like a Mac without a T2, so `passd` stops retrying | **Removed without a replacement** (a stand-in under Apple's class name; ownback/Ryzentosh-PLATFORM#4 fixes the absence properly, E5) |

## OpenCore, drivers and tools

| File | Version | Source | License | In git | Why |
|---|---|---|---|---|---|
| `OpenCore.efi` | 1.0.8 RELEASE | [OpenCorePkg 1.0.8](https://github.com/acidanthera/OpenCorePkg/releases/tag/1.0.8) (`2011e8b7216ecb2645d97ea710df965947edd406846e92050b9bc4190be6d27b`) | BSD-3-Clause | no | The boot loader. `ocvalidate` must be the 1.0.8 build |
| `Drivers/OpenRuntime.efi` | 1.0.8 | same zip | BSD-3-Clause | no | Memory-map and NVRAM runtime services that the Booter quirks need |
| `Drivers/HfsPlus.efi` | OcBinaryData `640e7e92` | [acidanthera/OcBinaryData](https://github.com/acidanthera/OcBinaryData/blob/640e7e9240938f2529e725351e1e1150dc3569db/Drivers/HfsPlus.efi) (`a55b5fff36578864ba6792c4c6369c71f6f35b61dd5a853ddf8583cd36c31d8f`) | **Apple proprietary**: never redistributed | no | Reads the HFS+ installer and recovery volumes, as a Mac's firmware does |
| `Tools/OpenShell.efi` | 1.0.8 | OpenCorePkg 1.0.8 zip | BSD-3-Clause | no | UEFI shell in the picker (auxiliary entry) |
| `ACPI/SSDT-CPUR-B650EI.aml` | Ryzentosh-ACPI v0.1.0 | [ownback/Ryzentosh-ACPI v0.1.0](https://github.com/ownback/Ryzentosh-ACPI/releases/tag/v0.1.0) `aml/` (asset sha256 `da5bf6ea53b8ecc23ec20f102d217ebd2f4a1c4e095ed01ff658f7268df92db4`), source `src/SSDT-CPUR-B650EI.dsl` | MIT | **yes** (the release bytes) | Legacy `Processor ()` objects for the 24 threads. The firmware declares only ACPI0007 devices, and without these macOS stalls at boot. Darwin-only `_STA` |
| `ACPI/SSDT-EC-USBX-B650EI.aml` | Ryzentosh-ACPI v0.1.0 | [ownback/Ryzentosh-ACPI v0.1.0](https://github.com/ownback/Ryzentosh-ACPI/releases/tag/v0.1.0) `aml/` (asset sha256 `f651e3f745f2b6008ac57bbb565589b3828c6cc703c9eeed6d1c406c75897d96`), source `src/SSDT-EC-USBX-B650EI.dsl` | MIT | **yes** (the release bytes) | Hides the real EC0 from macOS, adds the `EC` device macOS expects, USB port power (USBX). Darwin-only |

The `.aml` files in git are the live bytes, byte-identical to the Ryzentosh-ACPI v0.1.0 release assets (the Orchestrator also
hashed the live ESP). Their sources and build now live in Ryzentosh-ACPI (`src/`, `tools/build.sh`), which took them from
this repo (originally Vermilion `efi/acpi`, MIT). `acpi/*.dsl` here is a byte-identical copy of Ryzentosh-ACPI `src/`,
kept for reference; Ryzentosh-ACPI is the source of truth. New or changed SSDTs arrive as a Ryzentosh-ACPI release, one
EFI change at a time.

## Boot-args (`NVRAM/Add/7C436110-…/boot-args`)

| Boot-arg | Read by | What it does | Status |
|---|---|---|---|
| `-v` | boot.efi / xnu | Verbose boot | Kept while developing. Removed for a stable release |
| `keepsyms=1` | xnu | Symbolicated panic backtraces | Kept while developing |
| `debug=0x100` | xnu | 0x100 itself is obsolete (`DB_LOG_PI_SCRN`, `osfmk/kern/debug.h:587`). But on x86 **any** non-zero `debug` sets `panicDebugging` when kernel debugging isn't restricted (`osfmk/kern/debug.c:443-453`). SIP `0x0A03` includes `CSR_ALLOW_UNTRUSTED_KEXTS`, which counts as debugger-allowed (x86 `csr_check`, `bsd/kern/kern_csr.c:323`). With `panicDebugging`, xnu doesn't reboot after a panic (`debug.c:1699`): the panic stays on screen. A real Mac reboots and keeps the panic log in NVRAM. Here `Booter/Quirks/DisableVariableWrite = true` probably stops that log from persisting, so the on-screen panic is today's only reliable evidence | **Kept** until panic-log persistence is proven: Ryzentosh-EFI#6 (Orchestrator decision 2026-11-27) |
| `pci=0x8000000` | IOPCIFamily (`PE_parse_boot_argn("pci")`, `IOPCIBridge.cpp:847`) | `kIOPCIConfiguratorDefaultETF` (`IOKit/pci/IOPCIConfigurator.h:190`): IOPCIBridge keeps the firmware's extended-tag settings instead of enabling 8/10-bit tags (`IOPCIBridge.cpp:4013`). MtkWireless and Vermilion both record that macOS must not enable 10-bit tags behind the chipset root port where the RZ616 sits. Works together with the `probeBusGated` "Disable 10 bit tags" kernel patch | Kept. Ryzentosh-PLATFORM decides whether a device-scoped fix replaces it |
| `amtk_awdl_offchan=0` | MtkWirelessWifi (still read in 1.1.3) | AWDL channel policy: AWDL stays on the AP channel while associated, with no PM handshake; "AirDrop to phones on other channels fails" (v1.1.3 `docs/WIFI.md`, same wording as 1.1.1). The driver's default leaves the channel with a PM handshake, and upstream notes disassociation without it. 1.1.3's new `amtk_awdl_idle_gap` (default 700 ms) only limits those off-channel visits, so it has no effect while this arg is set (`idleCapAllows()` passes on the AP channel). **Limit:** the driver never uses DFS/passive channels (52–144) for AWDL, and our AP is on ch 52, so with this arg AWDL likely has no usable window while associated ("discovery but no transfer"). That is a parity gap | Kept (E-WiFi2 #12 keeps every boot-arg identical). Testing the default off-channel mode with `idle_gap` is a separate experiment for Ryzentosh-WIRELESS |
| `ipc_control_port_options=0` | xnu (`osfmk/ipc/ipc_policy.c:84`) | Turns off the default control-port hardening (immovable/pinned task control ports, `ICP_OPTIONS_IMMOVABLE_1P_HARD`, `PINNED_1P_HARD`, `PINNED_3P_SOFT`). Part of the AMFIPass setup that Vermilion's accelerator was approved with. **A security defect under the parity rule** | Kept until E4, removed together with AMFIPass |
| `phxdebug=1` | VermilionBoot (`PE_parse_boot_argn("phxdebug")`) | Opens VermilionBoot's root-only debug selectors 100–113 (SMU, PSP ring, MMIO write, queue adoption, claim). The live `phxboot` bring-up (`navi31_up.sh` → `mesboot`) runs through them; without it the daily system has no accelerated GPU | Kept. Removed together with `phxboot` and VermilionBoot at G-Switchover/E4 |

xnu and IOPCIFamily line numbers refer to the tags xnu-12377.121.6 and IOPCIFamily-726.100.6 of Apple's open source, which may
differ slightly from the 25G241 binaries. ADR numbers refer to the control plane's `.agents/decisions/`.

## Tried and rejected

| Date | Change | Result | Why rejected | Reference |
|---|---|---|---|---|
| 2026-11-27 | E-WiFi (#9): `AirportMtkWlan` 2.3.3, Arxusion/AirportMtkWlan v2.3.3-awdl-beta1 Tahoe AWDL beta (asset sha256 `2b744247fb69b2253823eafb14c3a4cb1ccd68b353ed95a6d9d2493dd151aa4d`), in place of MtkWirelessWifi 1.1.1, with `amtk_awdl_offchan=0` dropped | Boot `boot-20261127-210900` (F8 → internal) was clean: no panic or crash, no OCAK link error, `com.flxxxxddd.AirportMtkWlan` loaded, `awdl0` up. Same as baseline: AirDrop (discovery both ways, no transfer; upstream #24's discovery loss didn't reproduce), Handoff, Bluetooth, AirPlay receive, downlink (95.7 vs 94.5 Mbps) | **Worse than the step-0 baseline:** Universal Clipboard Mac → iPhone lost (iPhone → Mac still works); uplink 42.5 → 36.3 Mbps (−15 %); responsiveness 418 → 245 RPM (−41 %); Tx rate 867 → 432 Mbps on the same ch 52 80 MHz 802.11ax link. Rolled back the same day (internal `EFI/OC` back to E1; the failed tree is kept as `EFI/OC.bad`) | Draft PR #10 (results: issuecomment-7227370725, baseline: issuecomment-7227118231) |

Next Wi-Fi candidate, when the Orchestrator asks: Dino-VN/MtkWireless v1.1.3 (Wi-Fi + Bluetooth, the same author as today's kexts).

## Other notable config entries (unchanged by the import)

- `csr-active-config` = `0x0A03` (SIP partly off, as the Vermilion stack needs). ADR-0004 and E4 own it.
- `Booter/Quirks/ResizeAppleGpuBars = 10`: ocvalidate warns it is unstable with sleep/wake. E3 owns it.
- `UEFI/Quirks/RequestBootVarRouting = true`: kept (ADR-0006 option B-manual). Turning it off needs its own owner approval.
- `Kernel/Patch`: the committed config holds **one** patch of our own: the AGDP `board-id → board-ix` string patch
  (`com.apple.driver.AppleGraphicsDevicePolicy`, 8 bytes, every occurrence, `MinKernel 25.0.0`; the method of
  WhateverGreen's `agdpmod=pikera`, credited to Pike R. Alpha). It is meant to make AGDP look up `board-ix` instead of
  `board-id`. **Effect unverified, possibly inert.** AGDP lives in the SystemKC, and OpenCore resolves a patch `Identifier`
  only in the BootKC. Yet the live `IOPlatformExpertDevice` has `board-ix` and no `board-id`, so something else does the
  rename. **Treat the `board-ix` state as load-bearing:** restoring `board-id` may re-arm AppleIntelMCEInterruptController,
  a panic risk on AMD. See RB-0003a §1 (Ryzentosh-EFI#8) and ROADMAP E-AGDP. The entry stays as imported until that
  work decides it.
- The **AMD_Vanilla** patch set (25 entries: CPUID/topology, the core count set to 12, PAT/MTRR, the GenuineIntel checks,
  CaseySJ's IOPCIFamily "Disable 10 bit tags" (enabled) and "AM5 hot-plug" (disabled)) is **not committed**: AMD-OSX/AMD_Vanilla
  publishes no license. [`kernel-patches.json`](../../kernel-patches.json) pins it (commit `eaf52ef2`, `patches.plist` sha256)
  and records the four core-count edits. The control plane's `tools/efi-stage` puts those 25 entries before ours at
  staging, which gives exactly the live `Kernel/Patch`. Manual path: [`docs/Humans/KERNEL-PATCHES.md`](../Humans/KERNEL-PATCHES.md).
  Ryzentosh-CPU owns reducing the AMD kernel patches.
