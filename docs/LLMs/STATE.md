# STATE: Ryzentosh-EFI

Updated: 2026-11-27 by the Project Lead for #1/#2 (claude-opus-5-5/high), branch `research/1-smbios-t2`.

## Phase
Research (ADR-0003). E1 (#4) runs in a separate thread.

## Done (this branch)
- RB-0003a findings: `docs/LLMs/re/RB-0003a-board-id-branching.md`. An inventory of 25G241 board-id/model branches (AGDP, AGPM, X86PlatformPlugin, AppleIntelMCEReporter, AppleGVA/HEVC encoder, MediaToolbox FairPlay gate, audio DSP, USB, slot notifications, Sidecar/UC/AirPlay/Displays lists).
- RB-0003b findings: `docs/LLMs/re/RB-0003b-t2-features.md`. Per-T2-service table in the owner's three classes (real / presence-without-crypto / Apple-provisioned), plus the live kexts (RyzentoshSSE, RestrictEvents, AppleMCEReporterDisabler, VirtualSMC).

## Key findings to act on
- **The live root node has `board-ix` and no `board-id`.** By OpenCore's source the AGDP patch can't apply (AGDP is in the SystemKC), so what renames the property is open. The existing RELEASE log shows no failure for patch 25, which argues against "no-op". The patch is treated as load-bearing until E-AGDP (one confounded observation). X86PlatformPlugin runs with the `Placeholder` profile. **Restoring `board-id` risks AppleIntelMCEReporter loading on AMD** (by its matching dictionaries, AppleMCEReporterDisabler doesn't block it). E1 is a byte-identical round trip with patch 25 untouched. E-AGDP (step 0 + step 1, RB-0003a §1) runs after E1 is promoted.
- Nothing publishes a T2 device. Orchestrator decisions (2026-11-27): RyzentoshSSE is a workaround (a stand-in under Apple's class name), to be replaced under ownback/Ryzentosh-PLATFORM#4 and then removed in its own EFI PR. VirtualSMC is allowed if every key is backed by real hardware state or absent. E1 leaves the AGDP patch untouched; the test boots are queued as E-AGDP after E1.

## In flight
- Draft research PR https://github.com/ownback/Ryzentosh-EFI/pull/8 for #1 + #2. First review (claude-fable-5-2): 3 blocking + 13 should-fix, addressed. Second review of the revised text: approve with nits; its 5 should-fix items and nits are addressed.

## Next step
- PR #8 is ready. The Orchestrator squash-merges it, then this thread settles.
- RB-0003c (#3) gets its own thread. PLATFORM gets RB-0003e/f (PLATFORM#4 for SSE, the VirtualSMC key audit). E-AGDP is queued in the control-plane ROADMAP after E1.

## Blockers
None. (The KDK 25G241 would let RB-0003a's open items trace the kext code paths.)
