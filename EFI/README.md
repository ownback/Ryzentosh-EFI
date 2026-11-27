# EFI

Hand-maintained OpenCore tree (`EFI/OC`, `EFI/BOOT`) for the reference machine. `config.plist` holds **placeholders** for SMBIOS identity (PlatformInfo → Generic: SystemSerialNumber, MLB, SystemUUID, ROM). Generate your own with OpenCore's `macserial`, see docs/Humans/INSTALL.md. Kexts come from the Ryzentosh component releases and upstream releases listed in `docs/LLMs/KEXTS.md`.
