# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/). Release stages: research → alpha → beta → stable.

## [Unreleased]
- Docs: end-state layout (owner decision 2026-11-27). KEXTS.md "Replaced by" names the end-state kexts (RyzentoshCPU, RyzentoshPlatform, RyzentoshWireless, RyzentoshGPU; Lilu and VirtualSMC stay; AMFIPass, VermilionTrust and RyzentoshSSE are removed). The SSDTs are sourced from Ryzentosh-ACPI v0.1.0 (byte-identical). No boot-relevant file changes.
- E-WiFi (#9): AirportMtkWlan 2.3.3 (AWDL beta) tried and rejected. It was worse than MtkWirelessWifi 1.1.1 on Universal Clipboard Mac→iPhone, uplink and responsiveness. The live config is unchanged (E1); see KEXTS.md "Tried and rejected".
- E1 (#4): the live EFI/OC imported as dotfiles (identity placeholders, SSDT sources, USB map, `EFI/BINARIES.sha256`, `docs/LLMs/KEXTS.md`).
- E1 (#4): the AMD_Vanilla kernel patches (no upstream license) are pinned in `kernel-patches.json` and injected at staging, not committed.
- E1 (#4): every boot-arg is kept and justified in KEXTS.md. `debug=0x100` stays until panic-log persistence is proven (#6).
- Research: RB-0003a (25G241 board-id/model branching) and RB-0003b (T2 services, three-class table) findings in `docs/LLMs/re/` (#1, #2).
- Repository created from the Ryzentosh skeleton (2026-11-27).
