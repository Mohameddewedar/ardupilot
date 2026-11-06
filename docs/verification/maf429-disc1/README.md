# MAF429 archive verification on STM32F429I-DISC1

Date: 2026-11-06. AI-assisted investigation and documentation.

The original MAF429 definitions **build, flash and boot on STM32F429I-DISC1**.
The unchanged application communicates over native USB as MAF429, then enters
`Config Error: Baro: unable to initialise driver` on the bare board. This proves
limited boot/communications, not successful vehicle initialization or sensor
operation. The definitions do not describe the GuidancePilotF429 expansion
correctly. The user disconnected that expansion before the flash test.

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
change, parameter-set command, or submodule change was introduced.

## What was established

| Question | Finding |
| --- | --- |
| Does the original bootloader build? | Yes; 15,756 bytes, 628 bytes spare in its 16 KiB region. |
| Does the original ArduPlane application build? | Yes; Waf reports 1,308,464 flash bytes used. Raw BIN is 1,308,476 bytes. |
| Does selecting F427 categorically prevent F429 operation? | No. The original F427-profile image boots on this F429 and sends MAVLink over USB. This does not validate all peripherals. |
| Is USB fundamentally on the wrong pins? | No. Native USB enumerated as MAF429 and carried application MAVLink. |
| Does it support the currently wired expansion? | No. It expects ICM20948/BMP388 on SPI1; the retained wiring uses MPU9250 on SPI4, GPS on UART5 and SD on SPI5. |
| Are all declared serial ports exposed? | No. The last `SERIAL_ORDER` leaves only USB and USART1. |
| Does its parameter storage persist writes? | No. `HAL_USE_EMPTY_STORAGE` selects a backend that returns zeros and discards writes. |
| Was original MAF429 firmware flashed? | Yes, after the user disconnected the external modules. All 1,324,860 bytes of the combined bootloader/application image matched SWD readback. |
| Was the connected board examined? | Yes: initial GuidancePilotF429 baseline, then MAF429 native USB, 876 parameters and 46 disarmed heartbeats. Native ST-Link DAP succeeded where the legacy driver had failed. |
| Was GuidancePilotF429 restored? | Yes. All 2 MiB matched the fresh backup before execution. After reassembly/reset, both USB links returned 906 parameters and disarmed heartbeats; final IMU IDs matched the baseline. Existing pre-arm errors remain. |

“Worked” therefore needs qualification: booting and communicating in a
configuration-error loop does not establish functional sensors, persistent
parameters, usable RC/GPS, safe outputs or a working autopilot. This dated test
proves present execution of the recorded images; it does not establish when or
whether the archive worked historically, or under which older firmware revision.

## Reports

- [Build commands, outcomes and hashes](build.md)
- [Generated configuration and software compatibility](compatibility.md)
- [Official hardware documentation research](hardware.md)
- [Initial connected-board observations and limitations](bench.md)
- [Original-image flash, runtime results and restoration](flash.md)

The tracker map is
[MAF429: verify archived hwdef on STM32F429I-DISC1](https://github.com/Mohameddewedar/ardupilot/issues/14).
Its child investigations contain the decision record. Reports on this branch
are the portable evidence; full flash/parameter dumps and build products remain
under ignored `.local/guidance-f429/maf429-verification/` because they contain
device configuration or are generated artifacts.
