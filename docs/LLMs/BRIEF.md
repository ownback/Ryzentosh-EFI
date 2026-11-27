# BRIEF: Ryzentosh-EFI

**Scope:** Hand-maintained ("dotfiles") OpenCore EFI for this hardware. config.plist with identity placeholders, the SSDTs from Ryzentosh-ACPI releases, USB map, the tested kexts (end state: one kext per Ryzentosh repo — RyzentoshCPU, RyzentoshPlatform, RyzentoshWireless, RyzentoshGPU — plus Lilu and VirtualSMC), SMBIOS rationale (ADR-0003), boot-args policy, reinstall guide. NO build script.

**Release artifact:** Tagged EFI tree after each promoted change, plus human steps for adding your own SMBIOS identity.

**Depends on:** the releases of Ryzentosh-ACPI (SSDTs), Ryzentosh-CPU, Ryzentosh-PLATFORM, Ryzentosh-WIRELESS and
Ryzentosh-GPU (one kext each), and the upstream releases listed in `docs/LLMs/KEXTS.md` until each is replaced.

**Issues:** the Root Orchestrator files issues only in ownback/Ryzentosh. Issues, comments and PR notes in this repo
are the Project Lead's job.

**Parity targets:** see the rows for this project in the control plane's COMPATIBILITY_MATRIX.md.

**Out of scope:** anything another Ryzentosh repo owns (see projects.yaml).
