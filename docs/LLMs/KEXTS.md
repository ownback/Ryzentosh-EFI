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
   release zip below) into the same relative path. A kext that a change has just added (AirportMtkWlan, E-WiFi #9) isn't
   on the known-good until that change is promoted, so take it from its release zip.
4. From the directory that holds `OC/`, run `shasum -a 256 -c <repo>/EFI/BINARIES.sha256`. Every line must say `OK`.
5. Put `kernel-patches.json` two levels above `OC/` (or pass `--kernel-patches`), and hand that `OC/` to the Root Orchestrator.
   At staging, `tools/efi-stage` inserts the private SMBIOS identity (SystemProductName, SystemSerialNumber, MLB, SystemUUID,
   ROM) from `.private/smbios.json` and the pinned AMD_Vanilla kernel patches.

A Ryzentosh component replaces a legacy binary only through its own tested release, one EFI change at a time
(ROADMAP E4/E5).

## Kexts (load order = `Kernel/Add` order)

| # | Kext | Version | Source (release zip SHA-256) | License | In git | Why it is loaded | Replaced by |
|---|---|---|---|---|---|---|---|
| 0 | Lilu | 1.7.2 | [acidanthera/Lilu 1.7.2](https://github.com/acidanthera/Lilu/releases/tag/1.7.2) (`53967d7dcfaab01023a33df2e969a89522f13d6654a6a56ac4711b62dabf3ab8`) | BSD-3-Clause | no | Patch engine. Every kext here except AppleMCEReporterDisabler, AirportMtkWlan, USBToolBox/UTBMap, VermilionBoot and RyzentoshSSE links against it | Stays while any Lilu plugin is loaded. Each Ryzentosh kext avoids depending on it |
| 1 | VirtualSMC | 1.3.8 | [acidanthera/VirtualSMC 1.3.8](https://github.com/acidanthera/VirtualSMC/releases/tag/1.3.8) (`2e29a8aaf91b4eb0bcdf5913ed17e70f5cf76531122acd4132eff7813a54de8b`) | BSD-3-Clause | no | A Mac has an SMC; this board has none. macOS needs the SMC keys to boot | No replacement planned (emulating absent hardware). Ryzentosh-CPU owns the CPU sensor keys |
| 2 | NVMeFix | 1.1.3 | [acidanthera/NVMeFix 1.1.3](https://github.com/acidanthera/NVMeFix/releases/tag/1.1.3) (`e1d5657ab7ac31f69771708f7b80bf218ab9aa0b8e4c4fe6ff943983037e3dfb`) | BSD-3-Clause (LICENSE.txt) | no | APST/power management for the non-Apple NVMe (Phison E26, `1987:5026`) | Ryzentosh-PLATFORM (NVMe power) |
| 3 | RestrictEvents | 1.1.6 | [acidanthera/RestrictEvents 1.1.6](https://github.com/acidanthera/RestrictEvents/releases/tag/1.1.6) (`98170dfae195ddd28b5d95e3f040125a13ca783bcb9bd1e5b8c588e217b14ee6`) | BSD-3-Clause | no | MacPro7,1 memory and PCI slot warnings off (the board has no Mac Pro memory/PCI topology) | Decided with the SMBIOS model (ADR-0003). Ryzentosh-PLATFORM |
| 4 | AppleMCEReporterDisabler | 1.2 (codeless) | acidanthera, [bugtracker#424](https://github.com/acidanthera/bugtracker/issues/424#issuecomment-535624313) (listed in OpenCorePkg `Docs/Kexts.md`) | none stated | no | AppleMCEReporter panics on AMD CPUs with MacPro7,1 | Decided with ADR-0003 (SMBIOS). Ryzentosh-CPU |
| 5 | AirportMtkWlan | 2.3.3 (AWDL beta) | [Arxusion/AirportMtkWlan v2.3.3-awdl-beta1](https://github.com/Arxusion/AirportMtkWlan/releases/tag/v2.3.3-awdl-beta1) (prerelease), asset `AirportMtkWlan-Tahoe-AWDL-Beta-v2.3.3.zip` (`2b744247fb69b2253823eafb14c3a4cb1ccd68b353ed95a6d9d2493dd151aa4d`, the GitHub asset digest) | GPL-3.0 | no (GPL, kept out of this BSD repo) | Native AirPort Wi-Fi (IO80211Family/IOSkywalkFamily) plus beta AWDL (`awdl0`) for the RZ616 / MT7922. `IOPCIMatch` includes `0x061614c3` (`14c3:0616`, subsys `105b:e0cd`). Tahoe build only (`MinKernel 25.0.0`, `MaxKernel 25.99.99`, per its README). Needs `Kernel/Quirks/DisableIoMapper = true` (already set). Only Apple dependencies, no Lilu. Replaced MtkWirelessWifi 1.1.1 in E-WiFi (#9). Identify it by bundle ID `com.flxxxxddd.AirportMtkWlan`: MtkWirelessWifi also publishes an IOClass named `AirportMtkWlan` | Ryzentosh-WIRELESS |
| 6 | USBToolBox | 1.2.0 | [USBToolBox/kext 1.2.0](https://github.com/USBToolBox/kext/releases/tag/1.2.0) (`c315a3a5acfd496dd97d0d19b4fbd1d487103d2fd541c5651583d4c9cebcfe07`) | **no license** in the repo | no | USB map engine; applies UTBMap's ports (macOS limits each controller to 15 ports) | Ryzentosh-PLATFORM (USB). Until then the map stays as data |
| 7 | UTBMap | 1.0 (codeless) | Vermilion `efi/` (study clone `ownback/vermilion-xtx`), generated 2026-11-22 for this board | MIT (SPDX in its `#comment`) | **yes** | The B650E-I USB map: chipset XH00 (8 of its 17 ports kept), CPU XHC0/XHC1 (4 each), XHC2 (1). Front-panel headers and the AURA LED port are left out | Ryzentosh-PLATFORM (USB) |
| 8 | SMCProcessorAMD | 1.0.1 | [macos86/SMCProcessorAMD 1.0.1](https://github.com/macos86/SMCProcessorAMD/releases/tag/1.0.1) (`2622e54c69b38a5e491edd2c9532d98a01a3d3ba23316adaed28af8f4efa8638`) | BSD-3-Clause | no | CPU temperature, package power and clocks as VirtualSMC keys (read-only) | Ryzentosh-CPU (SMC CPU sensors) |
| 9 | BlueToolFixup | 2.7.2 | [acidanthera/BrcmPatchRAM 2.7.2](https://github.com/acidanthera/BrcmPatchRAM/releases/tag/2.7.2) (`e1c1c55347526d031a8ae2fdd1f52efa3019161e497fb38e1cfa809752f8af21`) | GPL-2.0 | no | bluetoothd patches for a non-Apple Bluetooth controller (needed by MtkWirelessBT) | Ryzentosh-WIRELESS (Bluetooth) |
| 10 | MtkWirelessBT | 1.1.1 | [Dino-VN/MtkWireless v1.1.1](https://github.com/Dino-VN/MtkWireless/releases/tag/v1.1.1) (`c9bbc2ed3ad4ab55fa785e620e4b61e1ef767486e067cb5914644b94683cb2fd`) | GPL-3.0-only (bundle copyright; ships google-libsbc LICENSE/NOTICE) | no | Bluetooth firmware loader for USB `0489:e0e2`. It works independently of MtkWirelessWifi (MtkWireless README: "two kexts that work independently"), so it stays after E-WiFi. AirportMtkWlan's release leaves Bluetooth untouched | Ryzentosh-WIRELESS |
| 11 | AMFIPass | 1.4.1 | [dortania/OpenCore-Legacy-Patcher @ d7a3d94f](https://github.com/dortania/OpenCore-Legacy-Patcher/blob/d7a3d94f67bee5bc26b68f042372fb6a847f9b02/payloads/Kexts/Acidanthera/AMFIPass-v1.4.1-RELEASE.zip) payload (`07b266145906db41f4b13a7938fbb173ea28888cc1fa65f84417f8820adc961e`) | closed source, "All rights reserved" | no | Relaxes AMFI (the `amfi=0x80` effect) so Vermilion's ad-hoc signed Metal plugin and accelerator load. **A defect under the parity rule** | Removed in E4 (gated by ADR-0004 and G-Switchover) |
| 12 | VermilionBoot | 1.0.0 | Legacy Vermilion build (archived) | Vermilion: MIT / nullarc MIT-or-GPL-2.0 parts. Legacy: the owner doesn't carry Vermilion's dGPU stack forward, so it is never committed | no | GPU bring-up kext for the live display stack; its debug selectors are used by the `phxboot` LaunchDaemon (needs `phxdebug=1`) | Ryzentosh-dGPU, at G-Switchover (E5) |
| 13 | VermilionTrust | 1.0.4 | Legacy Vermilion build (archived) | as #12 | no | AMFI library validation with an allow-list of Vermilion's cdhashes (needs Lilu) | Removed in E4 |
| 14 | VermilionAudio | 1.7.3 | Legacy Vermilion build (archived) | as #12 | no | Lets AppleGFXHDA accept the RX 7900's HDMI/DP audio function `1002:ab30` (needs Lilu; inert until the daemon adds the ab30 personality) | Ryzentosh-dGPU (DP/HDMI audio), at G-Switchover (E5) |
| 15 | RyzentoshSSE | 0.1.0 | Legacy `ownback/ryzentosh-sse` (repo deleted by the owner; `backups-local/legacy-vermilion/ryzentosh-sse-all-refs.bundle` is the only copy) | none published | no | Publishes an AppleSSE service that answers "not supported", like a Mac without a T2, so `passd` stops retrying | Ryzentosh-PLATFORM (SSE/T2 question, ADR-0003), E5 |

## OpenCore, drivers and tools

| File | Version | Source | License | In git | Why |
|---|---|---|---|---|---|
| `OpenCore.efi` | 1.0.8 RELEASE | [OpenCorePkg 1.0.8](https://github.com/acidanthera/OpenCorePkg/releases/tag/1.0.8) (`2011e8b7216ecb2645d97ea710df965947edd406846e92050b9bc4190be6d27b`) | BSD-3-Clause | no | The boot loader. `ocvalidate` must be the 1.0.8 build |
| `Drivers/OpenRuntime.efi` | 1.0.8 | same zip | BSD-3-Clause | no | Memory-map and NVRAM runtime services that the Booter quirks need |
| `Drivers/HfsPlus.efi` | OcBinaryData `640e7e92` | [acidanthera/OcBinaryData](https://github.com/acidanthera/OcBinaryData/blob/640e7e9240938f2529e725351e1e1150dc3569db/Drivers/HfsPlus.efi) (`a55b5fff36578864ba6792c4c6369c71f6f35b61dd5a853ddf8583cd36c31d8f`) | **Apple proprietary**: never redistributed | no | Reads the HFS+ installer and recovery volumes, as a Mac's firmware does |
| `Tools/OpenShell.efi` | 1.0.8 | OpenCorePkg 1.0.8 zip | BSD-3-Clause | no | UEFI shell in the picker (auxiliary entry) |
| `ACPI/SSDT-CPUR-B650EI.aml` | 2026-11-19 | `acpi/SSDT-CPUR-B650EI.dsl` (from Vermilion `efi/acpi`) | MIT | **yes** (+ source) | Legacy `Processor ()` objects for the 24 threads. The firmware declares only ACPI0007 devices, and without these macOS stalls at boot. Darwin-only `_STA` |
| `ACPI/SSDT-EC-USBX-B650EI.aml` | 2026-11-18 | `acpi/SSDT-EC-USBX-B650EI.dsl` (from Vermilion `efi/acpi`) | MIT | **yes** (+ source) | Hides the real EC0 from macOS, adds the `EC` device macOS expects, USB port power (USBX). Darwin-only |

The `.aml` files in git are the live bytes. Recompiling `acpi/*.dsl` with iasl 20260930 gives identical tables apart from
the checksum and the compiler-revision header bytes (offsets 9 and 32–35).

## Boot-args (`NVRAM/Add/7C436110-…/boot-args`)

| Boot-arg | Read by | What it does | Status |
|---|---|---|---|
| `-v` | boot.efi / xnu | Verbose boot | Kept while developing. Removed for a stable release |
| `keepsyms=1` | xnu | Symbolicated panic backtraces | Kept while developing |
| `debug=0x100` | xnu | 0x100 itself is obsolete (`DB_LOG_PI_SCRN`, `osfmk/kern/debug.h:587`). But on x86 **any** non-zero `debug` sets `panicDebugging` when kernel debugging isn't restricted (`osfmk/kern/debug.c:443-453`). SIP `0x0A03` includes `CSR_ALLOW_UNTRUSTED_KEXTS`, which counts as debugger-allowed (x86 `csr_check`, `bsd/kern/kern_csr.c:323`). With `panicDebugging`, xnu doesn't reboot after a panic (`debug.c:1699`): the panic stays on screen. A real Mac reboots and keeps the panic log in NVRAM. Here `Booter/Quirks/DisableVariableWrite = true` probably stops that log from persisting, so the on-screen panic is today's only reliable evidence | **Kept** until panic-log persistence is proven: Ryzentosh-EFI#6 (Orchestrator decision 2026-11-27) |
| `pci=0x8000000` | IOPCIFamily (`PE_parse_boot_argn("pci")`, `IOPCIBridge.cpp:847`) | `kIOPCIConfiguratorDefaultETF` (`IOKit/pci/IOPCIConfigurator.h:190`): IOPCIBridge keeps the firmware's extended-tag settings instead of enabling 8/10-bit tags (`IOPCIBridge.cpp:4013`). MtkWireless and Vermilion both record that macOS must not enable 10-bit tags behind the chipset root port where the RZ616 sits. Works together with the `probeBusGated` "Disable 10 bit tags" kernel patch | Kept. Ryzentosh-PLATFORM decides whether a device-scoped fix replaces it |
| ~~`amtk_awdl_offchan=0`~~ | MtkWirelessWifi only | AWDL channel policy of MtkWirelessWifi (AWDL stays on the AP channel while associated; Dino-VN/MtkWireless `docs/WIFI.md`). AirportMtkWlan 2.3.3 doesn't read it: the string isn't in its binary, which reads `amtk_awdl_ht/ndp/rate/standalone`, `amtk_pmf/he/syspm/autoreset/knobs` and `-mtk*` flags. There is no equivalent knob, so nothing is renamed | **Removed** in E-WiFi (#9): inert once MtkWirelessWifi is gone |
| `ipc_control_port_options=0` | xnu (`osfmk/ipc/ipc_policy.c:84`) | Turns off the default control-port hardening (immovable/pinned task control ports, `ICP_OPTIONS_IMMOVABLE_1P_HARD`, `PINNED_1P_HARD`, `PINNED_3P_SOFT`). Part of the AMFIPass setup that Vermilion's accelerator was approved with. **A security defect under the parity rule** | Kept until E4, removed together with AMFIPass |
| `phxdebug=1` | VermilionBoot (`PE_parse_boot_argn("phxdebug")`) | Opens VermilionBoot's root-only debug selectors 100–113 (SMU, PSP ring, MMIO write, queue adoption, claim). The live `phxboot` bring-up (`navi31_up.sh` → `mesboot`) runs through them; without it the daily system has no accelerated GPU | Kept. Removed together with `phxboot` and VermilionBoot at G-Switchover/E4 |

xnu and IOPCIFamily line numbers refer to the tags xnu-12377.121.6 and IOPCIFamily-726.100.6 of Apple's open source, which may
differ slightly from the 25G241 binaries. ADR numbers refer to the control plane's `.agents/decisions/`.

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
