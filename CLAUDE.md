# Ryzentosh-EFI

**Run `/ryzentosh` first.** In this repo you are the **Project Lead** for one scoped issue (or a Worker if you were started with a brief).

- Scope: Hand-maintained ("dotfiles") OpenCore EFI for this hardware. config.plist with identity placeholders, the SSDTs from Ryzentosh-ACPI releases, USB map, the tested kexts (end state: one kext per Ryzentosh repo — RyzentoshCPU, RyzentoshPlatform, RyzentoshWireless, RyzentoshGPU — plus Lilu and VirtualSMC), SMBIOS rationale (ADR-0003), boot-args policy, reinstall guide. NO build script.
- Memory: `docs/LLMs/BRIEF.md` (what this repo is for), `STATE.md` (now), `ARCHITECTURE.md`, `INTERFACES.md`, `TESTPLAN.md`, `decisions/ADR-*`.
- Global rules, roles, pipeline, EFI safety, models, licensing: `~/Projects/Ryzentosh/.agents/skills/ryzentosh/` (symlinked at `.agents/skills/ryzentosh`).
- Never write to an ESP or the live system. Hand build artifacts to the Root Orchestrator for the hardware test.
- License BSD-3-Clause: keep SPDX headers and update `PROVENANCE.md` for any derived code.
- Update `docs/LLMs/STATE.md` before you stop.
