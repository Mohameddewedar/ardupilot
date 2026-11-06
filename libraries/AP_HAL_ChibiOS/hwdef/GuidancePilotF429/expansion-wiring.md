# GuidancePilotF429 expansion wiring: bench only

This is a bench wiring plan for the STM32F429I-DISC1 MB1075, the photographed
IMU carrier, replacement HW-125 Micro SD Card Adapter and GPS MINI V1.0
NEO-7N-0-002. Use the [wiring schematic](expansion-wiring.svg) alongside this
guide. **Recommended inputs: regulated external 3.3 V for IMU and GPS VCC,
regulated external 5 V for HW-125 VCC.** Every module contact below has a
connection or an explicit NC (leave disconnected) disposition. The user
confirmed connections on 2026-11-05; compilation, upload and bounded disarmed
observations are recorded in the [bench execution record](https://github.com/Mohameddewedar/ardupilot/issues/13)
and [board README](README.md#bench-verification-2026-11-05). Loaded rails
remain unmeasured, and the HW-125 socket was empty. For a new assembly,
complete unpowered wiring inspection before powered testing.

P1 and P2 are the Discovery expansion headers; CN3 and CN4 are not expansion
headers. Locate P1 and P2 by their PCB designations and pin-1 marks, not by
counting one edge. Retain stock SB22–SB25 OFF: in particular SB25 connects the PD2 branch
to LCD IM0 if closed. See ST's [UM1670](https://www.st.com/resource/en/user_manual/um1670-discovery-kit-with-stm32f429zi-mcu-stmicroelectronics.pdf),
[MB1075 C01](https://www.st.com/resource/en/schematic_pack/mb1075-f429i-c01_schematic.pdf)
and [E01 schematics](https://www.st.com/resource/en/schematic_pack/mb1075-f429i-e01_schematic.pdf).
Verify the actual board revision and bridges.

## Contacts and signal connections

Numbers on the carriers are **local positional aids, not manufacturer pin
numbers**. IMU: component face up, header left, count top to bottom. SD: use
the labelled back, with `Micro SD Card Adapter` readable and header left;
count top to bottom: CS, SCK, MOSI, MISO, VCC, GND. GPS: battery/component face up,
header bottom, count left to right. The [original photos and manifest](https://github.com/Mohameddewedar/ardupilot/blob/b5c0ccec1b5b52fa391a300ac36512c2e8d8d6ec/docs/hardware-evidence/guidance-f429/manifest.md)
record the evidence. The IMU back prints both GY6500 and GY9250; the fitted die
and compass are unconfirmed. The replacement SD front is marked `HW-125`;
both sides are photographed.
The former ten-contact Micro SD Board V1.02 and its contact numbers are retired.

| Module contact | Function/disposition | Discovery contact or supply |
| --- | --- | --- |
| IMU 1 VCC | Power input | Regulated external `EXT_3V3` |
| IMU 2 GND | Common ground | P1-63 or 64; external supply returns |
| IMU 3 SCL/SCLK | SPI4 SCK | P1-15 PE2 |
| IMU 4 SDA/SDI | SPI4 MOSI | P1-11 PE6 |
| IMU 5 EDA | NC — auxiliary I2C unused | Leave disconnected |
| IMU 6 ECL | NC — auxiliary I2C unused | Leave disconnected |
| IMU 7 AD0/SDO | SPI4 MISO | P1-14 PE5 |
| IMU 8 INT | NC — driver polls | Leave disconnected |
| IMU 9 NCS | IMU chip select | P1-16 PE3 |
| IMU 10 FSYNC | Unused synchronization input | Common GND |
| HW-125 SD 1 CS | SD chip select | P1-13 PE4 |
| HW-125 SD 2 SCK | SPI5 SCK | P2-6 PF7 |
| HW-125 SD 3 MOSI | SPI5 MOSI | P2-8 PF9 |
| HW-125 SD 4 MISO | SPI5 MISO | P2-5 PF8 |
| HW-125 SD 5 VCC | Regulator input | Regulated external `EXT_5V` |
| HW-125 SD 6 GND | Common ground | P1-63 or 64; external supply returns |
| GPS 1 PPS | NC — pulse-per-second output unused | Leave disconnected |
| GPS 2 RXD | Receives Discovery UART5 TX | P1-43 PC12 |
| GPS 3 TXD | Drives Discovery UART5 RX | P1-40 PD2 |
| GPS 4 GND | Common ground | P1-63 or 64; external supply returns |
| GPS 5 VCC | Power input | Regulated external `EXT_3V3` |

Both external supply returns join Discovery GND and all carrier grounds.
No Discovery power contact supplies the carriers. See the
[recommended power plan](#recommended-power-plan) and the
[HW-125 research note](../../../../docs/research/guidance-f429-hw125-reader.md).

Check FSYNC continuity before assembly to ensure the carrier does not drive
that contact; its assigned connection is GND, as required for the unused chip
input by the [MPU9250](https://invensense.tdk.com/wp-content/uploads/2015/02/PS-MPU-9250A-01-v1.1.pdf)
and [MPU6500](https://invensense.tdk.com/wp-content/uploads/2020/06/PS-MPU-6500A-01-v1.3.pdf)
specifications. AD0 is SDO in SPI mode: do not strap it as an I2C address.
NC is an intentional disposition, not an unresolved assignment. EDA/ECL,
INT and PPS have no function in this configuration and must not be tied to
power or ground. The new reader uses all six header contacts and exposes no
card-detect or SDIO D1/D2 contacts.

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

## Recommended power plan

The [power datasheet analysis](../../../../docs/research/guidance-f429-power-datasheets.md)
supports a conservative 3.3 V input recommendation for the IMU and GPS.
Their chip/module supply limits do not permit direct 5 V. Exact carrier
regulator identity is not established, so 5 V is not recommended at those
VCC contacts. A downstream LDO may reduce the internal rail; a safe input
voltage recommendation is not proof that either carrier will initialize.
The [HW-125 research](../../../../docs/research/guidance-f429-hw125-reader.md)
documents the new reader's regulator, buffer and 4.5–5 V carrier input
specification. The card and buffer operate from its internal nominal 3.3 V
rail; VCC is the regulator input. Do not connect this reader's VCC to
`EXT_3V3` expecting its regulator to maintain 3.3 V.

| Power source | Carrier contact |
| --- | --- |
| Regulated external `EXT_3V3` | IMU 1 VCC |
| Regulated external `EXT_3V3` | GPS 5 VCC |
| Regulated external `EXT_5V` | HW-125 SD 5 VCC |
| Both external supply returns and Discovery P1-63 or 64 | IMU 2 GND; SD 6 GND; GPS 4 GND |

Size the 3.3 V supply for the IMU and GPS/carrier/antenna demand. Size the 5 V
supply for the reader and actual card's write-current peaks. The HW-125
supplier lists up to 200 mA, so the plan does not rely on the Discovery's
less-than-100 mA external-load budget. Never connect either external positive
rail to the Discovery P2-1/2 3V rail, a Discovery 5V contact or another
regulator output. Discovery retains USB power. Share ground, not supply outputs.

The photographed HW-125 has a 1117-family regulator and 74LVC125 buffer.
Confirm VCC-to-regulator-input and regulator-output-to-card/buffer continuity
before power-up, then measure the internal rail before connecting signals.
Supplier documentation and visible markings do not prove hidden routing,
regulator authenticity or the loaded output voltage of this particular board.
Keep SPI at 3.3 V logic; 5 V is assigned only to the reader's VCC input.

A comparison reader schematic ties the MISO buffer enable active at all times.
The actual HW-125 enable wiring remains unverified. This definition uses SD as
the **only active SPI5 device**, holding the onboard gyro and LCD deselected;
it does not depend on the reader releasing MISO for another active device.
Verify inactive PC1/PC2 and reset/power-sequencing behavior. Before enabling
another SPI5 device, establish that MISO releases when SD CS is high or use
proper isolation/a separate bus. Do not enable another driver on SPI5 by
assuming that CS automatically disables this buffer.

For the unchanged IMU/GPS, verify the recommended 3.3 V input produces valid
loaded chip rails despite any LDO dropout, and check logic compatibility with
the actual Discovery supply. Earlier approximately 2.86 V ST-LINK and 2.92 V
estimated VDDA readings and USB issues remain unresolved under load.

Bring-up checks still needed:

- Regulator/buffer power and enable continuity, including HW-125 MISO behavior.
- Card make/model and supply-current peaks during writing.
- Unpowered wiring, polarity, FSYNC and chip-select checks.
- After assembly confirmation, loaded rails and signal logic compatibility.

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

After human assembly confirmation, check the IMU/GPS 3.3 V and reader 5 V
power arrangement, loaded rails and logic levels, sensor identification and
orientation, GPS configuration, and SD
operation, including IMU FIFO/errors under SD logging load. These modules provide
no barometer; retain truthful errors and arming checks. This guide establishes
neither normal estimator operation nor flight readiness.

This documentation was prepared with AI assistance. The dated bench record
distinguishes observed IMU/GPS communications from pending rail measurements,
calibration, orientation acceptance and inserted-card storage tests.
