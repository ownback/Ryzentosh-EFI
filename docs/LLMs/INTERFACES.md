# INTERFACES: Ryzentosh-EFI

External contracts: IOKit classes and properties, user-client selectors, plist keys, files installed, interfaces consumed from other Ryzentosh repos.

## Consumed by the control plane (`tools/efi-stage`)
- Input: an `OC/` directory with `OpenCore.efi` and `config.plist` (assembled per `EFI/README.md`).
- `config.plist` `PlatformInfo/Generic`: `SystemProductName`, `SystemSerialNumber`, `MLB`, `SystemUUID` and `ROM` are
  overwritten at staging from `.private/smbios.json`. The repo holds placeholders only.
- `kernel-patches.json` (repo root, i.e. `<candidate OC>/../../kernel-patches.json`, or `--kernel-patches`): `source`
  {url, commit, path, sha256}, `local` (the clone under the control plane), `edits` [{index, key, byte, value}]. efi-stage
  puts the pinned upstream `Kernel/Patch` entries, with those edits, before the committed ones, and refuses a config that
  already contains them.

## Consumed from other repos
- Kext binaries come from upstream releases or from Ryzentosh component releases, pinned in `EFI/BINARIES.sha256` and
  described in `docs/LLMs/KEXTS.md`. End state: one kext per Ryzentosh repo, named after it (RyzentoshCPU,
  RyzentoshPlatform, RyzentoshWireless, RyzentoshGPU), plus Lilu and VirtualSMC.
- ACPI tables come from Ryzentosh-ACPI releases (one SSDT per purpose); `EFI/OC/ACPI/*.aml` is v0.1.0.

## Boot-args other repos rely on
- `phxdebug=1` (legacy VermilionBoot + live `phxboot`), `amtk_awdl_offchan=0` (MtkWirelessWifi, owned by Ryzentosh-WIRELESS),
  `pci=0x8000000` (IOPCIFamily extended tags; RZ616 behind the chipset root port). See KEXTS.md.
