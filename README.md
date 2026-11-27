# Ryzentosh-EFI

Hand-maintained ("dotfiles") OpenCore EFI for this hardware. config.plist with identity placeholders, the SSDTs from Ryzentosh-ACPI releases, USB map, the tested kexts (end state: one kext per Ryzentosh repo — RyzentoshCPU, RyzentoshPlatform, RyzentoshWireless, RyzentoshGPU — plus Lilu and VirtualSMC), SMBIOS rationale (ADR-0003), boot-args policy, reinstall guide. NO build script.

Part of [Ryzentosh](https://github.com/ownback/Ryzentosh): macOS Tahoe on an AMD PC, built to behave like a Mac Apple designed and
supports. Written by AI agents. Apple is not involved in this project.

**Status:** research. Nothing here is ready to install yet. See [docs/Humans](docs/Humans/) and the
[compatibility matrix](https://github.com/ownback/Ryzentosh/blob/main/docs/Hardware/COMPATIBILITY_MATRIX.md).

**Releases:** Tagged EFI tree after each promoted change, plus human steps for adding your own SMBIOS identity.

## Reference hardware
AMD Ryzen 9 7900X3D · Radeon RX 7900 XTX (XFX) · ASUS ROG STRIX B650E-I · macOS 26.7.1 (25G241) · OpenCore 1.0.8.

## Contributing
See [CONTRIBUTING.md](https://github.com/ownback/Ryzentosh/blob/main/CONTRIBUTING.md). AI agents: read [AGENTS.md](AGENTS.md).

License: BSD-3-Clause. Third-party code and its origins are listed in [PROVENANCE.md](PROVENANCE.md).
