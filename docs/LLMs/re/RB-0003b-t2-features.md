<!-- SPDX-License-Identifier: BSD-3-Clause -->

# RB-0003b: T2-dependent features, and what each one becomes here

Brief: control plane `docs/Research/briefs/RB-0003b-t2-dependent-features.md` (ADR-0003, question 2). Issue: ownback/Ryzentosh-EFI#2.
Date: 2026-11-27. Build: macOS 26.7.1 **25G241**, x86_64, SMBIOS MacPro7,1, no T2. Read-only method: plists, kernel-collection
membership via `kmutil inspect`, dyld-cache strings, `ioreg`, `kmutil showloaded`, `log show`, crash-report listing, and Apple and
Netflix public pages. No boot-config change, no ESP write, no Apple code in this repo. Author: Project Lead, claude-opus-5-5/high.
Revised after an independent review (claude-fable-5-2).

**Policy used (owner decision 2026-11-27, relayed by the Root Orchestrator; it replaces ADR-0003's "absent cleanly, never faked").**
Each T2 service gets one class:

- **(1) Real**: can be provided for real by hardware or software here. Says by what and in which repo.
- **(2) Presence**: a T2-presence report macOS accepts **without any cryptographic identity**. Says which signal, its consumers, and
  what macOS then expects. This review reads (2) narrowly: a signal is admissible only if it is truthful and tied to a class-1 service
  that actually works.
- **(3) Crypto**: needs Apple-provisioned keys or attestation (Secure Enclave identity, FairPlay keys, Apple Pay, Touch ID pairing).
  **Not done.** Says how macOS behaves without it.

Labels and citations work as in RB-0003a: **verified** = read on 25G241 or observed live, **inferred** = follows from what was read.
`plist:` / `KC:` / `DSC:` / `live:` / URL.

## 1. Tahoe-supported Intel Macs and the T2 (question 1)

| Apple model (https://support.apple.com/en-us/122867) | Identifier | T2 (https://support.apple.com/en-us/103265) | Label |
|---|---|---|---|
| MacBook Pro (16-inch, 2019) | MacBookPro16,1 / 16,4 | yes ("MacBook Pro introduced in 2018 through 2020, excluding MacBook Pro (13-inch, M1, 2020)") | verified |
| MacBook Pro (13-inch, 2020, Four Thunderbolt 3 ports) | MacBookPro16,2 | yes (same line) | verified |
| iMac (Retina 5K, 27-inch, 2020) | iMac20,1 / 20,2 | yes (listed by name) | verified |
| Mac Pro (2019) | MacPro7,1 | yes ("Mac Pro introduced in 2019") | verified |

The identifiers match `PlatformSupport.plist` (RB-0003a §0). So **every Tahoe Intel SMBIOS claims a T2**, as ADR-0003 says
(verified). `PlatformSupport.plist` also lists `VMM-x86_64`, and OpenCore documents an `x86legacy` Secure Boot model for "Macs
without T2 chip and VMs" (OpenCorePkg `Docs/Configuration.tex`, `SecureBootModel`). So 25G241 supports a no-T2 x86_64 VM (verified).

**Limit of the VM comparison.** The VM matches this machine at the **kext-matching** level only: no T2 devices, so no T2 drivers
start. In user space it doesn't match. Here `kern.hv_vmm_present = 0` and `hw.model = MacPro7,1`, so daemons take their T2-Mac paths.
For example, libAppleSSE waits for an `AppleSSE` service that a real T2 Mac always has (§4). (verified: `sysctl`; inferred: VM
behaviour.) The VM also has its own FairPlay device (`AvpFairPlayDriver`, virtio, see row 15), so it isn't a FairPlay reference.

## 2. How T2 services reach macOS, and what matches here

KC membership was checked per kext with `kmutil inspect --show-fileset-entries` on both x86_64 collections (verified).

| Chain | Kexts (matching) | In a 25G241 x86_64 KC? | Here |
|---|---|---|---|
| SEP | `AppleSEPIntelIOP` on `IOPCIDevice` name `SEPM` → `AppleSEPIntelIOPNub` → `AppleSEPManager` → `AppleSEPDeviceService` endpoints; `AppleSSE_x86` on `AppleSEPManager` | AppleSEPManager, AppleSSE: **BootKC** | AppleSEPManager loaded as a dependency, **no instance**. No `SEPM` PCI function. |
| SEP endpoint drivers | AppleMesaSEPDriver (`sbio`), AppleSEPHDCPManager (`hdcp`), SEPHibernation (`hibe`), AppleTrustedAccessory (`stac`) | **No.** Plists only, in neither KC (`sep-endpoint,hdcp` / `,sbio` have no KC hits). | n/a. The **Intel T2 path for Touch ID and HDCP is unknown** on this build. |
| Buffer-copy engine (T2 ↔ host) | IOBufferCopyEngineFamily / IOBufferCopyController, AppleUSBVHCIBCE / AppleUSBVHCICommonBCE (USB over BCE) | **BootKC** | not started (no T2) |
| Media / audio over BCE | AppleAVEBridge (`IOBufferCopyEngine`), BridgeAudioCommunication (`IOBufferCopyEngine`), BridgeAudioController (`IOPCIDevice` `ADIO`) | **SystemKC** | not started |
| bridgeOS host | AppleEmbeddedOSSupportHost (ACPI `APP7777`); AppleUSBiBridge (Apple-vendor USB) | SystemKC; BootKC | not started; `system_profiler SPiBridgeDataType` prints nothing; `hw.target` empty |
| Keybags (IOResources) | AppleKeyStore, AppleFDEKeyStore, AppleCredentialManager | BootKC | **running**, as on any Mac |
| FairPlay kernel | FairPlayIOKit (IOResources) | **No** (neither KC) | Intel FairPlay presumably lives in user space (inferred) |
| VM FairPlay | AvpFairPlayDriver (`AppleVirtIOTransport`; transport on PCI `0x1a08106b`) | SystemKC | not started (no such device) |

(verified: the `IOKitPersonalities` of each kext's `plist:/System/Library/Extensions/<kext>.kext/Contents/Info.plist`; live `ioreg -l`,
`kmutil showloaded`, `system_profiler`, `sysctl`.)

**Logs.** No crash reports for passd, seserviced, nfcd, biometric, coreauth, bridge or FairPlay daemons in `/Library/Logs/DiagnosticReports`
or the user's. No `AppleSSE` / `SEP ` / `bridgeOS` / `iBridge` / `Secure Enclave` lines in `log show --last 30m` (verified, short window).
The independent reviewer found the same. Which T2 drivers stay absent is decided by hardware matching, not by board-id (verified for
the chains above). "Absent cleanly" in user space is inferred from that short log window only.

## 3. One row per T2 service (questions 2 and 3)

"Owner goal" covers question 3: FairPlay 4K/HDR, HEVC encode, Continuity Camera, Apple Pay on the web.

| # | T2 service on a real Mac | Class | Behaviour here today | Target (what we do) | Owner goal | Label | Evidence |
|---|---|---|---|---|---|---|---|
| 1 | **Secure boot, firmware stage**: the T2 Boot ROM verifies the UEFI firmware and serves it over eSPI | (3) for the T2 root of trust. (1) for an analogue: UEFI Secure Boot with the owner's keys | The PC firmware boots OpenCore unsigned. | Optional: UEFI Secure Boot with owner-enrolled keys (no Apple key). Repo: Ryzentosh-EFI. | — | verified (state), inferred (analogue) | https://support.apple.com/guide/security/secure-boot-for-intel-based-mac-sec5d0fab7c6/web ("performs a secure boot from its Boot ROM"); live `Misc/Security` |
| 2 | **Apple Secure Boot of boot.efi/kernel** (img4 manifests, security levels) | **(1) partial** via OpenCore `SecureBootModel` (MacPro7,1 = `j160`), and **(2)** in effect, because a valid model is itself a presence signal | Off: `SecureBootModel = Disabled`, `kern.secure_kernel = 0`, SIP custom (`0x0A03`), `DmgLoading Signed`. | Medium Security first (`j160`, no ApECID). Blockers: AMFIPass/VermilionTrust and custom SIP (ADR-0004). Unsigned AuxKC kexts such as `/Library/Extensions/VermilionAccel.kext` are blocked under Apple Secure Boot (OpenCore doc: "all unsigned kernel extensions … cannot be installed"). Also check OC-injected kexts and sealed-volume edits. Map the **consumers** of the model signal before turning it on. **ApECID / Full Security:** Apple's signing server personalises for an ECID. OpenCore documents deriving it from `SystemUUID`, so the value is **identity data** (`.private/`, never in the repo). Whether a self-chosen ECID fits "no forged identity" is for the owner, flagged here. Repo: Ryzentosh-EFI. | prerequisite for DRM paths (RB-0004d) | verified (state, docs), inferred (conflicts) | OpenCorePkg `Docs/Configuration.tex` (`SecureBootModel`: "j160 — MacPro7,1", "Starting with macOS 12 SecureBootModel must match the SMBIOS", "As with T2 Macs, all unsigned kernel extensions … cannot be installed"; `ApECID`: "the first 8 bytes of SystemUUID can be used"); live config, `sysctl`, `csrutil status` |
| 3 | **Secure Enclave identity** (UID/GID keys, attestation, anti-replay) | **(3)** | Absent: no `SEPM` PCI function, so no AppleSEPManager instance. | Not done. SEP-only features are unavailable. | — | verified | §2 |
| 4 | **Secure Storage Element** (`AppleSSE`; PassKit / NFC / seserviced) | **(3)** | An `AppleSSE` class is published by **RyzentoshSSE** (a workaround, §4). | Not done. How SSE "absence" should look is open (§4, §5.5). | Apple Pay | verified (live state) | live `ioreg` (`AppleSSE` instance from `org.ryzentosh.sse`) |
| 5 | **Touch ID** (Magic Keyboard with Touch ID; the SEP evaluates biometrics) | **(3)** | Absent. The endpoint drivers named in the plists are in no x86_64 KC, so the Intel-T2 mechanism is **unknown** on 25G241. | Not done. Password entry, as on a Mac without Touch ID. | — | verified (KC membership), unknown (Intel path) | §2; https://support.apple.com/guide/security/hardware-security-overview-secf020d1074/web |
| 6 | **Apple Pay** (Wallet keys in the SEP/SSE) | **(3)** | No SSE. Confirming on a nearby iPhone/Watch is **untested**. | Not done on-device. Apple: "Mac without Touch ID: Confirm the payment on your Bluetooth-connected iPhone or Apple Watch". Test after Ryzentosh-AIR. It may still need SSE. | **Apple Pay on the web: only via iPhone/Watch, unverified** | inferred | https://support.apple.com/en-us/102626 |
| 7 | **FileVault key wrapping in the SEP** | (3) for SEP wrapping. **(1)** for software FileVault (AppleFDEKeyStore + APFS encryption, the VM/pre-T2 path) | FileVault Off. AppleFDEKeyStore runs. | Optional software FileVault as a one-shot test (Orchestrator): enable, reboot, unlock in boot.efi. VirtualSMC's FileVault key handling is part of the test. Repo: Ryzentosh-EFI. | — | verified (state), inferred (path works) | https://support.apple.com/guide/security/volume-encryption-with-filevault-sec4c6dc1b6e/web ("all FileVault key handling occurs in the Secure Enclave"); `fdesetup status` |
| 8 | **SSD controller + inline AES** (the T2 drives the internal NAND) | **(1)** | Third-party NVMe through Apple's generic `IONVMeController` / `IONVMeBlockStorageDevice`, plus NVMeFix. No encryption at rest. | Native NVMe plus power management (NVMeFix, then Ryzentosh-PLATFORM). Data at rest: row 7. | — | verified | live `ioreg`; Apple Platform Security guide (AES engine in the DMA path) |
| 9 | **HEVC/H.264 encode** (T2 AVE via AppleAVEBridge over the buffer-copy engine) | **(1)** on VCN 4 | The T2 path is absent (no `IOBufferCopyEngine`). On MacPro7,1, AppleGVA has the board-id in a "force AMD" list and AppleGVAHEVCEncoder sets `vendor8bit = 1`. From that, **a real Mac Pro encodes 8-bit HEVC on the AMD GPU** (inferred). If GVA reads the root `board-id`, its lookup may fail today (RB-0003a §1). The VideoToolbox encoder list on the Vermilion stack wasn't measured. | A VideoToolbox/GVA vendor encoder on VCN 4 (Ryzentosh-dGPU, M4). | **HEVC encode: reachable for real** (inferred) | verified (plists, strings), inferred (routing) | `plist:/System/Library/Video/Plug-Ins/AppleGVAHEVCEncoder.bundle/Contents/Info.plist#System Support/Mac-27AD2F918AE68F61`; `plist:…/AppleAVEBridge.kext/…`; DSC:AppleGVA @0x7ffa0c64887e |
| 10 | **Audio controller** (T2 `ADIO` for built-in speaker and mics; mic disconnect on laptops) | **(1)** for audio. The mic disconnect is n/a (desktop) | No T2 audio. Apple's AppleUSBAudio (USB `0b05:1a5c`) and AppleGFXHDA (DP/HDMI on the 7900 XTX HDA function) are running. VermilionAudio also runs on IOResources, behaviour undetermined (study-only). | Native class drivers (Ryzentosh-PLATFORM; Ryzentosh-dGPU for HDA). A real Mac Pro has an internal speaker tuned by `Audio/Tunings/Mac-27AD2F918AE68F61/`; this machine has none. | — | verified | `plist:…/BridgeAudioController.kext/…`; live `ioreg`; https://support.apple.com/guide/security/hardware-microphone-disconnect-secbbd20b00b/web |
| 11 | **Camera ISP** (laptops/iMac) | n/a for MacPro7,1 (no camera) | — | Nothing. Continuity Camera isn't T2-gated ("Any Mac compatible with macOS Ventura 13 or later"). It needs Ryzentosh-AIR. | **Continuity Camera: reachable, not T2-bound** | verified (Apple page, RB-0003a list scan) | https://support.apple.com/en-us/102546 |
| 12 | **FairPlay key handling / HDCP** | **(3)** | The SEP HDCP endpoint driver is in no x86_64 KC, so the Intel-T2 HDCP path is unknown. MediaToolbox has a `hw.model` list equal to the Intel T2 set, next to the FairPlay 4K/HDR strings. Its polarity and use **weren't traced**, so whether MacPro7,1 "passes" it is inferred. | Not done; must not be forged. RB-0004d: find what a real Mac Pro needs at each step and meet what can be met for real (Apple Secure Boot row 2, AMFI intact via ADR-0004, HDCP from the GPU driver). **Stop condition:** a step that needs SEP-held keys means the feature is unavailable, the way it is on a Mac without that hardware. | **FairPlay 4K/HDR: open (RB-0004d).** Netflix UHD needs "an Apple processor or Apple T2 Security chip" | verified (list, KC), inferred (gate) | DSC:MediaToolbox @0x7ff81693bd42; https://help.netflix.com/en/node/55764 |
| 13 | **SMC** (inside the T2 on T2 Macs: "SmcVersion … Missing on T2 based Macs") | (1) for sensors/fans/power; **VirtualSMC emulates the SMC device** | VirtualSMC + SMCProcessorAMD serve AppleSMC. | Not a T2 identity, but an emulated device. Policy question (§5.7). Repo: Ryzentosh-PLATFORM / CPU. | — | verified | OpenCorePkg `Docs/Configuration.tex` (`SmcVersion`); live kext list |
| 14 | **bridgeOS presence signals**: NVRAM `BridgeOSHardwareModel` → IODT `bridge-model` → `hw.target`; `BridgeOSVersion` → "(iBridge: …)" suffix in the BIOS version | **Not done** by default. (2) only if a brief shows a consumer tied to a working class-1 service and the value is truthful | Absent: `hw.target` empty, no `bridge-model`, no BridgeOS variables. OpenCore defines the name but doesn't set it. | Known consumer: **SoftwareUpdateCoreSupport** (OpenCore doc), which picks update assets by bridge model. A bridge model invites bridgeOS firmware payloads that can't apply here (`run-efi-updater=No` and `BlacklistAppleUpdate=true` are set today). No class-1 service depends on it, so leave it off. | update delivery | verified (state, docs) | OpenCorePkg `Docs/Configuration.tex` ("…propagate to IODT bridge-model by EfiBoot. Read by hw.target sysctl, used by SoftwareUpdateCoreSupport"); `Include/Apple/Guid/AppleVariable.h:284`; live `sysctl hw.target` |
| 15 | **Device-level T2 surfaces**: SEP PCI `SEPM`, `IOBufferCopyEngine` / AppleUSBVHCIBCE, iBridge USB (Apple VID), ACPI `APP7777`, T2 audio PCI `ADIO`, and the VM FairPlay virtio device (PCI `0x1a08106b`) | **Emulation, never** | Absent. | **Never.** Each one starts an Apple driver that speaks a T2 (or VM-host) protocol and expects keys. | — | verified (matching) | §2 |

## 4. The live system today (question 4), in the same classes

| Component | What it does (behaviour only) | Class | Emulates a T2? | Label | Evidence |
|---|---|---|---|---|---|
| **RyzentoshSSE 0.1.0** (`org.ryzentosh.sse`) | Publishes an IOService **of Apple's class name `AppleSSE`** on `IOResources` (Apple's AppleSSE attaches to the SEP). Its user client answers Apple's client protocol on selector 0: the presence query (`'SSEc'`, command `0x1c`) gets "not supported", everything else an error. Per its archived findings, libAppleSSE then gives up at once (-17) instead of retrying for 30 s, which removes a cold-start delay in passd/Music. It refuses to start if an AppleSEPManager service exists. | Touches a **class-3** service. It is a **workaround** under the parity rule (SKILL §3.2): a non-Apple stand-in answering an Apple protocol to hide a delay | **Open, for the Orchestrator.** It claims no working SE and provides no keys. But it is a protocol-level stand-in under an Apple class name, which is what row 15's criterion describes. Needs a named feature flag and a tracking issue now. | verified: live instance, its Info.plist. Not re-verified: the -17/30 s behaviour and its README's "not loaded on hardware yet" (it is loaded now) | live `ioreg`, `kmutil showloaded`; `EFI/OC/Kexts/RyzentoshSSE.kext/Contents/Info.plist`; archived findings `2026-11-25-applesse-presence-query.md` (`backups-local/legacy-vermilion/ryzentosh-sse-all-refs.bundle`, MIT, study only) |
| **RestrictEvents 1.1.6** | No `revpatch`/`revblock`/`revcpu` set, so defaults apply. `revblock=auto` (= `pci`) blocks the MacPro7,1-only ExpansionSlot/MemorySlot notifications. `revpatch=auto` = memtab, pci, cpuname, "without memtab and pci … on real Macs". `revcpu` defaults to 1 on non-Intel. `sbvmm`/`asset` code is inactive. `kern.hv_vmm_present = 0`. | not T2: model-UI mitigation | **No.** The README mentions nothing T2/bridgeOS-related. | verified | https://github.com/acidanthera/RestrictEvents (README, release 1.1.6); live `nvram`, `sysctl` |
| **AppleMCEReporterDisabler 1.2** | Plist-only kext: an `AppleACPICPU` personality (`IONameMatch processor`, score 1100) that outbids Apple's own ACPI CPU personality (score 1000). All 24 CPU nodes show it as `IOPersonalityPublisher`. It does **not** compete with `AppleIntelMCEInterruptController` (matches `IOPlatformExpertDevice` by board-id) or `AppleIntelMCEReporter`. What keeps the reporter out today is most likely the missing root `board-id` (RB-0003a §1). | not T2 | No. | verified (plists, live), inferred (what blocks the reporter) | `EFI/OC/Kexts/AppleMCEReporterDisabler.kext/Contents/Info.plist`; `plist:/System/Library/Extensions/AppleIntelMCEReporter.kext/Contents/Info.plist` |
| **AGDP `board-id → board-ix` kernel patch** | Load-bearing for the display in practice. By OpenCore's source it can't apply. The root has `board-ix` for a reason not yet known (RB-0003a §1). | not T2 | No. | verified (state), open (mechanism) | RB-0003a §1 |
| **VirtualSMC** | Serves AppleSMC with an emulated SMC. On T2 Macs the SMC is inside the T2. | (1)-area, emulated device | Not a T2 identity; policy question. | verified | live kext list |
| **OpenCore PlatformInfo** | `SpoofVendor = true` (root `manufacturer` "Acidanthera", not "Apple Inc."), `SecureBootModel = Disabled`, no `BridgeOS*` variables, `run-efi-updater = No`. | — | No T2 presence is reported. | verified | live config (identity fields not read out), `ioreg` |
| AMFIPass, VermilionTrust | AMFI relaxation (ADR-0004). | not T2 | No. | verified (loaded) | control-plane STATE |
| VermilionBoot, VermilionAudio (ESP), **VermilionAccel 0.1.1** (`/Library/Extensions`, `org.vermilion.accel`, loaded) | GPU bring-up, audio, acceleration (study-only). No SEP/bridge/SSE/`board-i[dx]` strings (VermilionAccel checked by the reviewer). | not T2 | No (by strings). | inferred | `strings`; `kmutil showloaded` |
| `local.phxboot` LaunchDaemon | Powers up the GPU by script at boot (known workaround, control-plane STATE). | not T2 | No. | verified (STATE) | `/Library/LaunchDaemons/local.phxboot.plist` |

**Answer to "is anything emulating a T2?"** Nothing publishes a SEP, bridgeOS, iBridge, buffer-copy-engine or T2-audio device,
`hw.target` is empty, and every T2 driver chain stays unmatched by hardware (verified). **One component is a protocol-level stand-in
under an Apple class name: RyzentoshSSE.** It reports absence, not presence, and holds no keys. Whether that counts as emulation is
for the Orchestrator. It is a workaround either way and needs a flag and an issue. VirtualSMC is an emulated SMC, a separate policy
question. The board-id state (RB-0003a §1) means the model choice is only half applied.

## 5. Input for the Orchestrator's per-service briefs (RB-0003d onwards)

1. **Apple Secure Boot** (row 2): Medium Security (`j160`, no ApECID) after ADR-0004 removes AMFIPass/VermilionTrust and after the
   AuxKC kexts are signed or gone. Map the consumers of the model signal. ApECID only with the owner's explicit yes, value in `.private/`.
2. **HEVC/H.264 encode on VCN 4** (row 9): a VideoToolbox/GVA vendor-plugin interface study (Ryzentosh-dGPU M4). Confirm the AMD
   routing by trace, not by strings.
3. **bridgeOS presence** (row 14): default **not done**. A brief only if a class-1 service needs it: map the readers of `hw.target` /
   `bridge-model` / `BridgeOSVersion` and what each expects.
4. **FairPlay** (row 12): RB-0004d, with the stop condition above. Trace the MediaToolbox model list (polarity, use) first.
5. **SSE absence** (row 4, §4): choose between keeping RyzentoshSSE behind a named flag (issue now), and no `AppleSSE` service plus a
   fix of the 30 s wait where it originates.
6. **Software FileVault** (row 7): a one-shot test.
7. **Policy:** VirtualSMC as an emulated device. The AGDP patch / root `board-id` experiment (RB-0003a §1), including the MCE panic risk.

## 6. Not verified / limits

- No feature was exercised (no Apple Pay, FairPlay or FileVault attempts). "Today" comes from matching, registry state and a 30-minute log window.
- The Apple pages for Apple TV app 4K/HDR, "Hey Siri" and HEVC/T2 weren't reachable at the tried URLs. Rows 9 and 12 don't rely on them.
- AppleKeyStore's `board-id` string (next to `chip-id`, `unique-chip-id`, `boot-manifest-hash`) wasn't traced.
- How Touch ID and HDCP work on Intel T2 Macs in 25G241 is unknown: the endpoint drivers aren't in the x86_64 KCs.
