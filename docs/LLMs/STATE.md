# STATE: Ryzentosh-EFI

Updated: 2026-11-27 by the Project Lead for #4 and #9 (claude-opus-5-5 / high).

## Phase
E-WiFi (#9): AirportMtkWlan 2.3.3 (AWDL beta) replaces MtkWirelessWifi 1.1.1. Branch `feat/9-airportmtkwlan`; the
Orchestrator stages it, and the owner tests on the next reboot.

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

## In flight
- **E-WiFi (#9):** the PR is open, and the candidate is at `temp/ewifi-candidate/EFI/OC` (recipe beside it).
  - The `efi-stage` dry run on 2026-11-27 20:31 shows `kernel patches: 25 … (4 edits) + 1 own` and `Kernel/Patch`
    identical to live; ocvalidate reports only E3.
  - Tree diff: +AirportMtkWlan, −MtkWirelessWifi, `~config.plist`.
  - Config diff: `Kernel/Add[5]` swapped, `amtk_awdl_offchan=0` dropped (only MtkWirelessWifi read it).
  - Staged by the Orchestrator 2026-11-27 20:33 from head 3192937. The baseline (MtkWirelessWifi) is in control-plane
    `logs-local/ewifi/`: 94.5/42.5 Mbps, RPM 418, ch 52 80 MHz 802.11ax.
  - Review (claude-fable-5-2): CHANGES-REQUESTED on the test plan only, with no boot blocker. Fixed in the PR: a step-0
    baseline on the old driver before the reboot, "worse than baseline" means abort, any panic while loaded aborts, ping during AWDL, risk high, v2.3.2 fallback.
  - Next: the owner's step-0 baseline (as a PR comment), then the reboot test, then the soak (≥ 24 h including one overnight sleep,
    3 cold + 3 warm boots with boot reports) before merge and USB promotion.
- E1 (#4): merged as 351b169.

## Blockers
None. (The KDK 25G241 would let RB-0003a's open items trace the kext code paths.)

## Follow-ups (not in this PR)
- After E-WiFi: evaluate bumping MtkWirelessBT 1.1.1 → Dino-VN/MtkWireless v1.1.3 (2026-11-25), as its own EFI change (Orchestrator).
- `config.plist` top-level `#comment` with an SPDX line (changes the loaded file, so it needs its own change).
- CI privacy scan: check `ROM` too, and drop `|| true` on the plist lint (`.github/workflows/ci.yml`).
- The skill symlinks (`.agents/skills/ryzentosh`, `.claude/skills/ryzentosh`, `.claude/agents`) are relative and break
  in worktrees outside `~/Projects/Ryzentosh/` (control-plane `link-shared.sh`).
