# Adding the AMD kernel patches yourself

macOS runs on an AMD Ryzen only with the community **AMD_Vanilla** kernel patches (CPUID and core topology, the
GenuineIntel checks, PAT/MTRR, and two IOPCIFamily fixes for AM5). AMD-OSX/AMD_Vanilla publishes no license, so this
repo doesn't ship them. `config.plist` holds only our own patch (the AGDP `board-id` one). Add the AMD patches before you
boot.

Pinned version (see `kernel-patches.json`): commit `eaf52ef292abf4ebec899df6d48626569ba50cc6`, `patches.plist`, SHA-256
`4bc820109b3d020c3c547fa23c49e0098e4f4a2c625ed6184dd54e390e84e1ab`.

1. Download `patches.plist` at that commit:
   `curl -LO https://raw.githubusercontent.com/AMD-OSX/AMD_Vanilla/eaf52ef292abf4ebec899df6d48626569ba50cc6/patches.plist`
   and check it with `shasum -a 256 patches.plist`.
2. Set your core count. In the first four entries (the `algrey | Force cpuid_cores_per_package` ones), the second byte
   of `Replace` is the number of **physical cores** of your CPU in hex. On the reference Ryzen 9 7900X3D it is `0C`
   (12 cores), so for example `B8000000 0000` becomes `B80C0000 0000`. The `kernel-patches.json` edits record exactly
   that (byte 1 of `Replace` in entries 0–3).
3. Copy the 25 entries of `Kernel/Patch` from `patches.plist` into `EFI/OC/config.plist` → `Kernel/Patch`, **in front of**
   the entry that is already there. Use ProperTree or a plist editor and keep their order.
4. Check with `ocvalidate` from OpenCore 1.0.8. It should report only `ResizeAppleGpuBars` (a known item).

On the reference machine, `tools/efi-stage` does steps 1–3 from a local clone at the pinned commit and refuses a
`config.plist` that already contains these patches.
