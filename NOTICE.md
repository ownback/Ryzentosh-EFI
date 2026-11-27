# Notices

Ryzentosh-EFI, Copyright (c) 2026 ownback and the Ryzentosh contributors. Licensed under BSD-3-Clause.

Third-party material (see PROVENANCE.md):

- `acpi/*.dsl`, `EFI/OC/ACPI/*.aml`, `EFI/OC/Kexts/UTBMap.kext` and parts of `EFI/OC/config.plist`: Copyright (c) 2026
  Vermilion contributors, MIT License (`LICENSES/MIT-Vermilion.txt`).
- `EFI/OC/config.plist` structure and defaults: OpenCorePkg, Copyright (c) The HermitCrabs Lab, Download-Fritz, savvas,
  vit9696 and others (full list in the license file), BSD-3-Clause (`LICENSES/BSD-3-Clause-OpenCorePkg.txt`).
- The AMD_Vanilla kernel patches (AMD-OSX/AMD_Vanilla; authors algrey, Goldfish64, XLNC, Shaneee, Zormeister, CaseySJ,
  Visual) are **not included**. AMD_Vanilla publishes no license, so `kernel-patches.json` only pins them by commit and hash.
- The AGDP `board-id → board-ix` patch in `config.plist` uses the method credited to Pike R. Alpha.
- Only board configuration (SSDTs, USB map, generated config) comes from Vermilion. Nothing from its dGPU stack is
  included.
