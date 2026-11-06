# MAF429 archive verification on STM32F429I-DISC1

Date: 2026-11-06. AI-assisted investigation and documentation.

The original MAF429 definitions **build successfully** on this repository
revision. Their clock, memory and USB choices make limited operation on an
STM32F429I-DISC1 plausible. This investigation does **not** establish that the
original firmware boots on hardware, and the definitions do not describe the
connected GuidancePilotF429 expansion correctly.

## Isolation

This is a disposable investigation on `verification/maf429-disc1`, forked from
`GuidancePilotF429` at `fe0b0e8f903ac983109340dffa8aa44c10380c5b`.
Do not merge or cherry-pick its commits into GuidancePilotF429, use it as a base
for future development, or open an upstream PR. Future GuidancePilotF429 work
continues from that original branch. The final working checkout is returned
to GuidancePilotF429; a separate retained verification worktree contains this
report and the imported hwdefs. This convention keeps development histories
separate; Git does not prohibit a human from deliberately merging them.

The imported files are in
[`libraries/AP_HAL_ChibiOS/hwdef/MAF429/`](../../../libraries/AP_HAL_ChibiOS/hwdef/MAF429/).
They remain byte-identical to the ZIP. No corrected hwdef, shared firmware
change, parameter change, or submodule change was introduced.

## What was established

| Question | Finding |
| --- | --- |
| Does the original bootloader build? | Yes; 15,756 bytes, 628 bytes spare in its 16 KiB region. |
| Does the original ArduPlane application build? | Yes; Waf reports 1,308,464 flash bytes used. Raw BIN is 1,308,476 bytes. |
| Does selecting F427 categorically prevent F429 operation? | No such conclusion follows. The profiles have the same RAM map, 168 MHz target and alternate functions used here. Runtime was not tested. |
| Is USB fundamentally on the wrong pins? | No: PB14/PB15 and the HS controller's internal FS PHY are appropriate. Enumeration of the original image remains untested. |
| Does it support the currently wired expansion? | No. It expects ICM20948/BMP388 on SPI1; the retained wiring uses MPU9250 on SPI4, GPS on UART5 and SD on SPI5. |
| Are all declared serial ports exposed? | No. The last `SERIAL_ORDER` leaves only USB and USART1. |
| Does its parameter storage persist writes? | No. `HAL_USE_EMPTY_STORAGE` selects a backend that returns zeros and discards writes. |
| Was original MAF429 firmware flashed? | No. A build does not resolve its pin and sensor mismatches. |
| Was the connected board examined? | Yes: disarmed telemetry, 906 parameters, UART diagnostics and full 2 MiB flash readback from the installed GuidancePilotF429 image. SWD identification failed. |

“Worked” therefore needs qualification: compiling, showing an LED, possibly
enumerating USB or starting a diagnostic loop would not establish functional
sensors, persistent parameters, usable RC/GPS, safe outputs or a working
autopilot. There is no evidence here proving that this archive was previously
flashed successfully, or identifying the historical firmware revision on
which it might have been used.

## Reports

- [Build commands, outcomes and hashes](build.md)
- [Generated configuration and software compatibility](compatibility.md)
- [Official hardware documentation research](hardware.md)
- [Connected-board observations and limitations](bench.md)

The tracker map is
[MAF429: verify archived hwdef on STM32F429I-DISC1](https://github.com/Mohameddewedar/ardupilot/issues/14).
Its child investigations contain the decision record. Reports on this branch
are the portable evidence; full flash/parameter dumps and build products remain
under ignored `.local/guidance-f429/maf429-verification/` because they contain
device configuration or are generated artifacts.
