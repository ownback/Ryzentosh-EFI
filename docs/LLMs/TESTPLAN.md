# TESTPLAN: Ryzentosh-EFI

| Parity target | Test | Host or device | Status |
|---|---|---|---|
| A real MacPro7,1 publishes `board-id` on `IOService:/` and X86PlatformPlugin loads `Mac-27AD2F918AE68F61.plist` (RB-0003a §1) | Step 0: OpenCore DEBUG log reaching the kernel patcher (patch 25 result). Step 1: one-shot candidate with only the AGDP patch disabled. **Abort if AppleIntelMCEReporter is loaded or the boot panics.** Record root `board-id`/`board-ix`, X86PlatformPlugin profile, `pmset -g cap`, AGDP instance, display | device (Orchestrator, one-shot) | proposed |
| No T2 service is emulated (ADR-0003, RB-0003b) | `ioreg -l`: no AppleSEPManager / AppleSEPIntelIOP / IOBufferCopyEngine / AppleEmbeddedOSSupportHost / BridgeAudio instances; `sysctl hw.target` empty unless a class-2 brief says otherwise | device (read-only, every boot report) | proposed |
