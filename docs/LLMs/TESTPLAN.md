# TESTPLAN: Ryzentosh-EFI

| Parity target | Test | Host or device | Status |
|---|---|---|---|
| **E-AGDP** (after E1): a real MacPro7,1 presumably publishes `board-id` on `IOService:/` and loads `Mac-27AD2F918AE68F61.plist` (inferred; RB-0003a §1) | Step 0: OpenCore DEBUG log reaching the kernel patcher (patch 25 result). Step 1: one-shot candidate with only the AGDP patch disabled. **Abort if AppleIntelMCEReporter is loaded or the boot panics.** Record root `board-id`/`board-ix`, X86PlatformPlugin profile, `pmset -g cap`, AGDP instance, display | device (Orchestrator, one-shot) | proposed |
| No T2 service is emulated (ADR-0003, RB-0003b) | `ioreg -l`: no AppleSEPManager / AppleSEPIntelIOP / IOBufferCopyEngine / AppleEmbeddedOSSupportHost / BridgeAudio instances; no `SEPM`, `ADIO` or `APP7777` nodes; no PCI `0x1a08106b`; **no `AppleSSE` instance whose bundle isn't `com.apple.driver.AppleSSE`** (expected to fail until ownback/Ryzentosh-PLATFORM#4); `sysctl hw.target` empty (bridgeOS presence not reported) | device (read-only, every boot report) | proposed; fails today (RyzentoshSSE) |
