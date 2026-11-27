# EFI

Hand-maintained OpenCore 1.0.8 tree for the reference machine (no build script). Only redistributable text is in git:

| Path | What |
|---|---|
| `OC/config.plist` | The live config minus the AMD_Vanilla kernel patches, which are injected at staging (see `../kernel-patches.json`). SMBIOS identity is **placeholders** (`PlatformInfo/Generic`: SystemSerialNumber `PLACEHOLDER`, MLB `PLACEHOLDER-MLB`, SystemUUID all zeros, ROM empty) |
| `OC/ACPI/*.aml` | The two SSDTs as booted, byte-identical to the [Ryzentosh-ACPI v0.1.0](https://github.com/ownback/Ryzentosh-ACPI/releases/tag/v0.1.0) release assets. Sources: Ryzentosh-ACPI `src/` (a reference copy is in `../acpi/*.dsl`) |
| `OC/Kexts/UTBMap.kext` | Codeless USB map of the B650E-I |
| `BINARIES.sha256` | SHA-256 of every binary the tree needs that is not committed (paths relative to the folder that holds `OC/`) |
| `../kernel-patches.json` | Pin and edits for the AMD_Vanilla kernel patches, which aren't committed (no upstream license); see `docs/Humans/KERNEL-PATCHES.md` |

Where each binary comes from, its license, and why it is loaded: [`docs/LLMs/KEXTS.md`](../docs/LLMs/KEXTS.md).

To assemble a bootable tree: copy `OC/` out of git, add the binaries listed in `BINARIES.sha256` (from the USB
known-good or the pinned upstream releases), and check them with `shasum -a 256 -c BINARIES.sha256`. Add the AMD_Vanilla
kernel patches (`docs/Humans/KERNEL-PATCHES.md`; without them an AMD CPU doesn't boot macOS). Insert your own
SMBIOS identity (generate it with OpenCore's `macserial`). On the reference machine, the Root Orchestrator's
`tools/efi-stage` does that from a private file.

`ocvalidate` (1.0.8) must report nothing except `Booter/Quirks/ResizeAppleGpuBars` (tracked as E3).

The live tree also has an empty `OC/Resources/`. Git can't hold an empty folder, and OpenCore doesn't use it here
(`PickerMode` Builtin, no OpenCanopy, `AudioSupport` false), so it is left out on purpose. A `.gitkeep` would put a file
on the ESP that the live tree doesn't have.

`EFI/BOOT` is not here: on the internal ESP it belongs to Linux (Limine), and the USB known-good uses OpenCore
1.0.8's own `BOOTx64.efi`.
