# STATE: Ryzentosh-EFI

Updated: 2026-11-27 by the Project Lead for #1/#2 (claude-opus-5-5/high), branch `research/1-smbios-t2`.

## Phase
Research (ADR-0003). E1 (#4) runs in a separate thread.

## Done (this branch)
- RB-0003a findings: `docs/LLMs/re/RB-0003a-board-id-branching.md`. An inventory of 25G241 board-id/model branches (AGDP, AGPM, X86PlatformPlugin, AppleIntelMCEReporter, AppleGVA/HEVC encoder, MediaToolbox FairPlay gate, audio DSP, USB, slot notifications, Sidecar/UC/AirPlay/Displays lists).
- RB-0003b findings: `docs/LLMs/re/RB-0003b-t2-features.md`. Per-T2-service table in the owner's three classes (real / presence-without-crypto / Apple-provisioned), plus the live kexts (RyzentoshSSE, RestrictEvents, AppleMCEReporterDisabler, VirtualSMC).

## Key findings to act on
- **The live root node has `board-ix` and no `board-id`.** By OpenCore's source the AGDP patch can't apply (AGDP is in the SystemKC), so what renames the property is open. The patch is still load-bearing for the display in practice (prior notes). X86PlatformPlugin runs with the `Placeholder` profile. **Restoring `board-id` risks AppleIntelMCEReporter loading on AMD** (AppleMCEReporterDisabler doesn't block it). There's no E1 recommendation yet: run the two-step one-shot experiment in RB-0003a §1 first (Orchestrator).
- Nothing publishes a T2 device. Orchestrator decisions (2026-11-27): RyzentoshSSE is a workaround (a stand-in under Apple's class name), to be replaced under ownback/Ryzentosh-PLATFORM#4 and then removed in its own EFI PR. VirtualSMC is allowed if every key is backed by real hardware state or absent. E1 leaves the AGDP patch untouched; the test boots are queued as E-AGDP after E1.

## In flight
- Draft research PR https://github.com/ownback/Ryzentosh-EFI/pull/8 for #1 + #2. The independent review (claude-fable-5-2) found 3 blocking items and 13 should-fix items, all addressed in the docs.

## Next step
- Second review of the revised text (claude-fable-5-2), then mark PR #8 ready. The Orchestrator squash-merges it, then this thread settles. RB-0003c (#3) gets its own thread.
- The Orchestrator writes RB-0003c (model choice) and RB-0003d+ (per-service briefs) from these tables. One-shot test request: AGDP patch disabled.

## Blockers
None. (The KDK 25G241 would let RB-0003a's open items trace the kext code paths.)
