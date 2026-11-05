# GuidancePilotF429 expansion wiring: bench only

This is a signal wiring plan for the STM32F429I-DISC1 MB1075, the photographed
IMU carrier, Micro SD Board V1.02 and GPS MINI V1.0 NEO-7N-0-002. Use the
[signal schematic](expansion-wiring.svg) alongside this guide. **IMU VCC and
GPS VCC are HOLD: unassigned. Do not connect either to a supply yet.** The SD
supply is a candidate only, subject to the checks below. No powered results are
claimed. Complete the unpowered wiring inspection and obtain human assembly
confirmation before compilation, upload or powered testing.

P1 and P2 are the Discovery expansion headers; CN3 and CN4 are not expansion
headers. Locate P1 and P2 by their PCB designations and pin-1 marks, not by
counting one edge. Retain stock SB22–SB25 OFF: in particular SB25 connects the PD2 branch
to LCD IM0 if closed. See ST's [UM1670](https://www.st.com/resource/en/user_manual/um1670-discovery-kit-with-stm32f429zi-mcu-stmicroelectronics.pdf),
[MB1075 C01](https://www.st.com/resource/en/schematic_pack/mb1075-f429i-c01_schematic.pdf)
and [E01 schematics](https://www.st.com/resource/en/schematic_pack/mb1075-f429i-e01_schematic.pdf).
Verify the actual board revision and bridges.

## Contacts and signal connections

Numbers on the carriers are **local positional aids, not manufacturer pin
numbers**. IMU: component face up, header left, count top to bottom. SD: socket
face up, header left, count top to bottom. GPS: battery/component face up,
header bottom, count left to right. The [original photos and manifest](https://github.com/Mohameddewedar/ardupilot/blob/21b58170b5adfb7547b71440f103bf97c3bd56cf/docs/hardware-evidence/guidance-f429/manifest.md)
record the evidence. The IMU back prints both GY6500 and GY9250; the fitted die
and compass are unconfirmed. The SD back has not been photographed.

| Discovery contact | Signal | Carrier contact |
| --- | --- | --- |
| P1-15 PE2 | SPI4 SCK | IMU 3 SCL/SCLK |
| P1-11 PE6 | SPI4 MOSI | IMU 4 SDA/SDI |
| P1-14 PE5 | SPI4 MISO | IMU 7 AD0/SDO |
| P1-16 PE3 | IMU CS | IMU 9 NCS |
| P2-6 PF7 | SPI5 SCK | SD 7 CLK/CLK |
| P2-8 PF9 | SPI5 MOSI | SD 6 MOSI/CMD |
| P2-5 PF8 | SPI5 MISO | SD 8 MISO/D0 |
| P1-13 PE4 | SD CS | SD 5 CS/D3 |
| P1-43 PC12 | UART5 TX | GPS 2 RXD |
| P1-40 PD2 | UART5 RX | GPS 3 TXD |
| P1-63 or 64 | GND | IMU 2 GND; SD 3 GND; GPS 4 GND; external supply return |

Connect IMU 10 FSYNC to GND **only after unpowered continuity checks establish
that the carrier does not drive it**; the unused chip input requires ground per
the [MPU9250](https://invensense.tdk.com/wp-content/uploads/2015/02/PS-MPU-9250A-01-v1.1.pdf)
and [MPU6500](https://invensense.tdk.com/wp-content/uploads/2020/06/PS-MPU-6500A-01-v1.3.pdf)
specifications. IMU 5 EDA, 6 ECL and 8 INT are unconnected; the driver polls.
AD0 is SDO in SPI mode: do not strap it as an I2C address. SD 4 NC/D2, 9 NC/D1
and 10 CD are unused; CD is a switch, not CS. Leave SD 2, the second 3.3V
contact, externally unconnected pending continuity checks. GPS 1 PPS is unused.

SPI4 carries the external IMU. SPI5 carries SD and the onboard gyro and LCD
connections. The hwdef declares no active onboard gyro sampling backend;
after GPIO setup, verify onboard gyro CS PC1 and LCD CS PC2 are both inactive
high. Verify reset-time CS levels and electrical compatibility, including
whether deselected devices release MISO. Inspect existing pulls before adding
pullups. These conditions have not been electrically validated.

Keeping SD on SPI5 avoids coupling its write-busy bus lock to the IMU on SPI4.
The [SPI SD hooks](../../sdcard.cpp) take the device semaphore on `spiSelect`.
In the pinned [ChibiOS MMC sequential-write path](https://github.com/ArduPilot/ChibiOS/blob/d103983f4362e5506bcf7062ccacf345fc0c0859/os/hal/src/hal_mmc_spi.c),
the write can hold it while `mmc_wait_idle` waits up to the
[1000 ms idle timeout](../common/halconf.h). The Invensense driver resets/discards FIFO samples when
more than 32 accumulate. Sharing that lock could therefore lose samples. Separate
bus locks do not eliminate scheduling or electrical risks; monitor IMU FIFO and
errors under SD logging load during later testing.

## Power remains unresolved

SD 1 (labelled 3.3V) is a **candidate** for a regulated external `EXT_3V3`
supply sized for the actual card's write-current peaks, with its return joined
to common GND. Never tie `EXT_3V3` to the Discovery P2-1/2 3V rail or parallel
regulators. The Discovery retains its existing USB supply; do not assume the
modules fit within the board's less-than-100 mA external application budget.
IMU 1 VCC and GPS 5 VCC remain unassigned until their carrier regulators and
power paths are identified. Do not guess their VIN voltage or bypass regulators.
Prior approximately 2.86 V ST-LINK and 2.92 V estimated VDDA readings and USB
issues remain unresolved under load.

Evidence still needed:

- Readable regulator top codes or matching carrier schematics; SD back photo
  and card make/model.
- Unpowered continuity from each carrier VCC to regulator IN and regulator
  OUT to chip rail; check FSYNC, SD power contacts, pulls and MISO paths.
- Intended external supply current rating, including card write peaks.
- After assembly confirmation, actual loaded rails and signal logic compatibility.

For context only, bare MPU9250 VDD is 2.4–3.6 V and VDDIO 1.71 V to VDD;
MPU6500's detailed DC table says 1.71–3.45 V for VDD and VDDIO, while its
overview says 3.6 V. Bare NEO-7N VCC is 2.7–3.6 V and logic inputs 0–VCC;
its supply sizing is 67 mA plus carrier and antenna demand. Conventional SD
is 2.7–3.6 V. These are chip/card limits, not carrier VIN ratings. Sources:
TDK specifications above, [u-blox NEO-7 datasheet](https://content.u-blox.com/sites/default/files/products/documents/NEO-7_DataSheet_(UBX-13003830).pdf)
and [ST AN5595](https://www.st.com/resource/en/application_note/an5595-spc58xexspc58xgx-multimedia-card-via-spi-interface-stmicroelectronics.pdf).

## Firmware and future checks

The independently implemented hwdef assigns SPI4 IMU MODE3 at 1 MHz setup
and up to 4 MHz reads; SPI5 SD MODE0 at 400 kHz initialization and up to 4 MHz
operation. These are requested ceilings; actual prescalers can be lower.
`HAL_OS_FATFS_IO` is 1. The common Invensense probe reads WHOAMI register
0x75: 0x70 identifies MPU6500 and 0x71 MPU9250; no compass is configured in
the baseline. See the [driver](../../../AP_InertialSensor/AP_InertialSensor_Invensense.cpp)
and [register definitions](../../../AP_InertialSensor/AP_InertialSensor_Invensense_registers.h).

For `ROTATION_NONE`, the driver maps native (Y, X, -Z) to vehicle axes. The
intended mounting is native +Y forward, +X right, +Z up. Verify package pin 1,
physical chip axes and final signs; carrier silkscreen alone does not prove
orientation. UART5 is SERIAL2 for GPS. After a future upload, read and check
`SERIAL2_PROTOCOL=5` and `SERIAL2_BAUD=230` (230400 baud): stored parameters
can override defaults. Do not reset all parameters. The u-blox driver scans
rates and requests binary output; connect both UART directions. See
[GPS source](../../../AP_GPS/AP_GPS.cpp) and [u-blox setup](../../../AP_GPS/AP_GPS_UBLOX.h).

After human assembly confirmation and power-path resolution, check rails and
logic levels, sensor identification and orientation, GPS configuration, and SD
operation, including IMU FIFO/errors under SD logging load. These modules provide
no barometer; retain truthful errors and arming checks. This guide establishes
neither normal estimator operation nor flight readiness.

This documentation was prepared with AI assistance. Photo inspection, source
comparison and static document checks are the scope of this documentation work;
no compilation, flashing, wiring or powered hardware test was performed here.
