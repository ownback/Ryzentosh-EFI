# STATE: Ryzentosh-EFI

Updated: 2026-11-27 by the Project Lead for #4, #9 and #12 (claude-opus-5-5 / high).

## Phase
E-WiFi2 (#12): MtkWireless 1.1.1 → 1.1.3 (Wi-Fi + BT). Branch `feat/12-mtkwireless-1.1.3`. Binaries only; `config.plist`
is unchanged. The owner reboots to test when they choose.

## Done
- **E1 (#4):** the live `EFI/OC` is imported as dotfiles.
  - `config.plist` has identity placeholders and no AMD_Vanilla patches; `kernel-patches.json` pins them and
    `tools/efi-stage` injects them.
  - The SSDTs (+ `.dsl`) and the UTBMap USB map are in git. The 36 binaries are pinned in `EFI/BINARIES.sha256`, and
    `docs/LLMs/KEXTS.md` covers every one of them plus the boot-args. All boot-args are kept (`debug=0x100` until #6).
  - **Accepted without a test boot** (owner rule "Test reboots": reboot only when boot-relevant bytes change). The
    Orchestrator staged with `--apply` on 2026-11-27 20:17 onto the internal `EFI/OC`.
    - The staged `config.plist` sha256 equals the previous live one; `Kernel/Patch` is identical to live; 36/36 binaries match.
    - The only tree difference restored `MtkWirelessBT.kext/Contents/Resources/google-libsbc-LICENSE.txt`, which the live
      tree had lost to a FAT fsck.
    - The USB known-good is boot-tested: boot-20261127-201549 is clean.
- **RB-0003a/b (#1, #2, PR #8):** findings are in `docs/LLMs/re/`.

## Key findings to act on
- **The live root node has `board-ix` and no `board-id`.** By OpenCore's source the AGDP patch can't apply (AGDP is in the SystemKC), so what renames the property is open. The existing RELEASE log shows no failure for patch 25, which argues against "no-op". The patch is treated as load-bearing until E-AGDP (one confounded observation). X86PlatformPlugin runs with the `Placeholder` profile. **Restoring `board-id` risks AppleIntelMCEReporter loading on AMD** (by its matching dictionaries, AppleMCEReporterDisabler doesn't block it). E1 is a byte-identical round trip with patch 25 untouched. E-AGDP (step 0 + step 1, RB-0003a §1) runs after E1 is promoted.
- Nothing publishes a T2 device. Orchestrator decisions (2026-11-27): RyzentoshSSE is a workaround (a stand-in under Apple's class name), to be replaced under ownback/Ryzentosh-PLATFORM#4 and then removed in its own EFI PR. VirtualSMC is allowed if every key is backed by real hardware state or absent. E1 leaves the AGDP patch untouched; the test boots are queued as E-AGDP after E1.

## End-state layout (owner decision 2026-11-27; docs only, nothing that boots changed)
- One Ryzentosh repo ships one kext, named after the repo. `Kexts/` ends up as Lilu, VirtualSMC, RyzentoshCPU,
  RyzentoshPlatform, RyzentoshWireless and RyzentoshGPU. The mapping per file is the KEXTS.md "Replaced by" column.
  - Ryzentosh-dGPU is renamed Ryzentosh-GPU (RyzentoshGPU.kext: RX 7900 XTX + Raphael iGPU); Ryzentosh-iGPU is archived.
  - Ryzentosh-AIR is merged into Ryzentosh-WIRELESS and archived (RyzentoshWireless.kext: Wi-Fi, BT, AWDL/Continuity and
    the bluetoothd patch, the one named essential workaround; GPL-3.0-only).
  - RyzentoshCPU absorbs AppleMCEReporterDisabler and the Hypervisor backend; RyzentoshPlatform absorbs NVMeFix, the USB
    map and RestrictEvents' jobs.
- The SSDTs come from Ryzentosh-ACPI (MIT, one SSDT per purpose). `EFI/OC/ACPI/*.aml` is byte-identical to the v0.1.0
  release assets (da5bf6ea…, f651e3f7…; the Orchestrator hashed the live ESP too). `acpi/*.dsl` stays as a reference copy.
- The Root Orchestrator files issues only in ownback/Ryzentosh. Issues, comments and PR notes in this repo are the
  Lead's job.

## In flight
- **E-WiFi2 (#12):** the candidate is at `temp/ewifi2-candidate/EFI/OC` (recipe beside it). Four files change, the
  MtkWirelessWifi/MtkWirelessBT executables and Info.plists; the libsbc license texts are unchanged.
  - The Info.plists are unchanged apart from the version, so the `Kernel/Add` entries stay. `amtk_awdl_offchan=0` stays:
    1.1.3 still reads it, and `idle_gap` is moot with it.
  - Test: the PR #10 structure with the step-0 baseline from #10, plus Bluetooth and a 30-min ping hold. Anything worse
    than the baseline means roll back.
  - PR #13. Review (claude-fable-5-2/medium): APPROVE; its should-fixes are applied (numeric dropout and reset-loop
    criteria, BT controller check). Known limit: the AP is on DFS ch 52, so with `offchan=0` AWDL likely has no usable window.
  - Test request sent to the Orchestrator; the owner reboots when they choose.

## E-WiFi (#9): tried and rejected, 2026-11-27
- AirportMtkWlan 2.3.3 (Arxusion v2.3.3-awdl-beta1, Tahoe AWDL beta) in place of MtkWirelessWifi 1.1.1; draft PR #10 is
  kept for reference.
- Boot `boot-20261127-210900` (internal) was clean. Compared with the step-0 baseline on the old driver:
  - Universal Clipboard Mac → iPhone was lost.
  - Uplink 42.5 → 36.3 Mbps, responsiveness 418 → 245 RPM, Tx rate 867 → 432 Mbps.
  - Everything else was the same.
- By the PR's rule (worse than baseline → no merge), the Orchestrator rolled back to E1 at once. `EFI/OC.bad` holds the
  failed tree. Details: KEXTS.md "Tried and rejected".

## Blockers
None. (The KDK 25G241 would let RB-0003a's open items trace the kext code paths.)

## Follow-ups (not in this PR)
- `config.plist` top-level `#comment` with an SPDX line (changes the loaded file, so it needs its own change).
- CI privacy scan: check `ROM` too, and drop `|| true` on the plist lint (`.github/workflows/ci.yml`).
- The skill symlinks (`.agents/skills/ryzentosh`, `.claude/skills/ryzentosh`, `.claude/agents`) are relative and break
  in worktrees outside `~/Projects/Ryzentosh/` (control-plane `link-shared.sh`).
