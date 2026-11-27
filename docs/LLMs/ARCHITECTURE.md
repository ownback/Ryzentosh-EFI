# ARCHITECTURE: Ryzentosh-EFI

## Components
- `EFI/OC/config.plist`: the OpenCore config (hand-maintained, identity placeholders).
- `EFI/OC/ACPI/*.aml` + `acpi/*.dsl`: SSDT-CPUR (Processor objects) and SSDT-EC-USBX (EC hide, fake EC, USBX).
- `EFI/OC/Kexts/UTBMap.kext`: codeless USB map (needs USBToolBox).
- `EFI/BINARIES.sha256`: pins for every binary that isn't committed.
- `docs/LLMs/KEXTS.md`: per-file source, license, reason and replacement; the boot-args table.

## Entry points
None. The tree is copied to an ESP by the control plane's `tools/efi-stage` (Root Orchestrator only).

## Build targets
None by design (no build script). The SSDT sources compile with `iasl`.
