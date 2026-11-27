/*
 * SPDX-License-Identifier: MIT
 * Copyright (c) 2026 Vermilion contributors (see LICENSES/MIT-Vermilion.txt, PROVENANCE.md)
 *
 * SSDT-EC-USBX for the ASUS ROG STRIX B650E-I (BIOS 4005), macOS only.
 *
 * - The board's real embedded controller is \_SB.PCI0.SBRG.EC0 (PNP0C09, no _STA in the DSDT). macOS's
 *   AppleACPIEC must not drive a desktop EC, so EC0 gets a _STA that hides it from macOS only.
 * - macOS expects a device named EC: a fake one (no hardware behind it) is added for macOS only.
 * - USBX gives macOS the USB port power limits (values from Apple's desktop Macs).
 *
 * Other operating systems see no change: every method checks _OSI ("Darwin").
 * Derived from the board's own DSDT (Dortania's SSDT-EC-USBX method), 2026-11-18.
 */
DefinitionBlock ("", "SSDT", 2, "VRMLN", "ECUSBX", 0x00001000)
{
    External (_SB_.PCI0.SBRG, DeviceObj)
    External (_SB_.PCI0.SBRG.EC0_, DeviceObj)

    Scope (\_SB.PCI0.SBRG.EC0)
    {
        Method (_STA, 0, NotSerialized)
        {
            If (_OSI ("Darwin"))
            {
                Return (Zero)
            }
            Else
            {
                Return (0x0F)
            }
        }
    }

    Scope (\_SB.PCI0.SBRG)
    {
        Device (EC)
        {
            Name (_HID, "ACID0001")
            Method (_STA, 0, NotSerialized)
            {
                If (_OSI ("Darwin"))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }
        }
    }

    Scope (\_SB)
    {
        Device (USBX)
        {
            Name (_ADR, Zero)
            Method (_DSM, 4, NotSerialized)
            {
                If ((Arg2 == Zero))
                {
                    Return (Buffer (One)
                    {
                         0x03
                    })
                }

                Return (Package (0x08)
                {
                    "kUSBSleepPowerSupply",
                    0x13EC,
                    "kUSBSleepPortCurrentLimit",
                    0x0834,
                    "kUSBWakePowerSupply",
                    0x13EC,
                    "kUSBWakePortCurrentLimit",
                    0x0834
                })
            }

            Method (_STA, 0, NotSerialized)
            {
                If (_OSI ("Darwin"))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }
        }
    }
}
