/*
 * SPDX-License-Identifier: MIT
 * Copyright (c) 2026 Vermilion contributors (see LICENSES/MIT-Vermilion.txt, PROVENANCE.md)
 *
 * SSDT-CPUR for the ASUS ROG STRIX B650E-I (BIOS 4005) + Ryzen 9 7900X3D, macOS only.
 *
 * The firmware declares the 24 CPU threads only as ACPI0007 Processor Devices (\_SB.PLTF.C000..C017 in SSDT
 * "CPUSSDT") and has no legacy Processor () objects. macOS finds CPUs through Processor () objects (AppleACPICPU),
 * so without this table it never brings the CPUs up and stalls after "CoreAnalyticsHub start completed" (Dortania
 * requires SSDT-CPUR for the same firmware style on B550/A520).
 *
 * One Processor () per ENABLED entry of the MADT, in MADT order, with ProcessorId = the MADT's ACPI Processor ID:
 * 0, 2, ..., 22 (cores) then 1, 3, ..., 23 (SMT siblings). The 8 disabled MADT entries (IDs 24..31) get none:
 * phantom CPUs make macOS stall too. Visible to macOS only (_OSI "Darwin").
 * Derived from this machine's MADT on 2026-11-19. A CPU with another thread count needs a new table.
 */
DefinitionBlock ("", "SSDT", 2, "VRMLN", "CPUR", 0x00001000)
{
    Scope (\_SB)
    {
        Processor (PR00, 0x00, 0x00000810, 0x06)
        {
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

        Processor (PR01, 0x02, 0x00000810, 0x06)
        {
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

        Processor (PR02, 0x04, 0x00000810, 0x06)
        {
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

        Processor (PR03, 0x06, 0x00000810, 0x06)
        {
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

        Processor (PR04, 0x08, 0x00000810, 0x06)
        {
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

        Processor (PR05, 0x0A, 0x00000810, 0x06)
        {
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

        Processor (PR06, 0x0C, 0x00000810, 0x06)
        {
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

        Processor (PR07, 0x0E, 0x00000810, 0x06)
        {
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

        Processor (PR08, 0x10, 0x00000810, 0x06)
        {
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

        Processor (PR09, 0x12, 0x00000810, 0x06)
        {
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

        Processor (PR0A, 0x14, 0x00000810, 0x06)
        {
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

        Processor (PR0B, 0x16, 0x00000810, 0x06)
        {
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

        Processor (PR0C, 0x01, 0x00000810, 0x06)
        {
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

        Processor (PR0D, 0x03, 0x00000810, 0x06)
        {
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

        Processor (PR0E, 0x05, 0x00000810, 0x06)
        {
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

        Processor (PR0F, 0x07, 0x00000810, 0x06)
        {
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

        Processor (PR10, 0x09, 0x00000810, 0x06)
        {
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

        Processor (PR11, 0x0B, 0x00000810, 0x06)
        {
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

        Processor (PR12, 0x0D, 0x00000810, 0x06)
        {
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

        Processor (PR13, 0x0F, 0x00000810, 0x06)
        {
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

        Processor (PR14, 0x11, 0x00000810, 0x06)
        {
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

        Processor (PR15, 0x13, 0x00000810, 0x06)
        {
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

        Processor (PR16, 0x15, 0x00000810, 0x06)
        {
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

        Processor (PR17, 0x17, 0x00000810, 0x06)
        {
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
