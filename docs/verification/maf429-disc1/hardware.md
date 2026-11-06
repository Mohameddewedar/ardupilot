# MAF429 archive versus the STM32F429I-DISC1

Research for [MAF429: establish Discovery pin and MCU compatibility](https://github.com/Mohameddewedar/ardupilot/issues/15),
2026-11-06. AI-assisted source review; no hardware was connected, powered,
flashed, or measured by this research worker. This is a snapshot of research commit `676951ab8f` from the
**disposable, never-merged** branch `research/maf429-disc1-hardware`,
retained here to keep the verification evidence together.
The separate execution branch is `verification/maf429-disc1`.

## Finding

**The archive could plausibly have booted and exposed USB or USART1, but that
would not demonstrate a functioning autopilot.** Its MCU selection is a plausible
subset of the actual MCU, and its native USB pin pair is appropriate. Many other
assignments share soldered board circuits. Most decisively for the present
assembly, the archive describes different external sensors on different wires.
Do not infer historical execution, healthy sensors, persistent parameters, or
usable actuators from a successful build or USB enumeration.

The scope is the unchanged
[MAF429 application definition](../../../libraries/AP_HAL_ChibiOS/hwdef/MAF429/hwdef.dat)
and [bootloader definition](../../../libraries/AP_HAL_ChibiOS/hwdef/MAF429/hwdef-bl.dat)
at base commit `73097f11a7e5897c220d67262d0a68127decc4ee`.
Build and bench results are recorded separately by the verification work.

## MCU, clock, USB, and revision assumptions

ST's [DS9405, sections 2 and 3.34][DS] describes both F427 and F429, including
shared Cortex-M4, memory and peripheral architecture. The HS USB controller has
an internal **full-speed** PHY; 480-Mbit/s operation requires an external ULPI
PHY. PB14/PB15 are its DM/DP pins. Its full-speed clock requires 48 MHz.
An F427 software profile on F429 is therefore plausible for shared peripherals,
not proof of complete compatibility. The repo's
[F427 table](../../../libraries/AP_HAL_ChibiOS/hwdef/scripts/STM32F427xx.py) and
[F429 table](../../../libraries/AP_HAL_ChibiOS/hwdef/scripts/STM32F429xx.py)
both specify 192 KiB DMA-capable RAM, 64 KiB CCM and a 168-MHz expected clock.
The archive does not require an F429 LCD controller merely to execute.

**8 MHz is plausible, but the source matters.** [UM1670 section 7.12][UM]
describes ST-LINK MCO and external-crystal configurations. [C01 sheet 5][C]
shows the optional target oscillator; [E01 sheet 3][E] changes its assembly.
Confirm the actual revision, oscillator population and HSE/bypass settings;
`OSCILLATOR_HZ 8000000` alone does not identify which circuit supplies PH0.

[UM1670 sections 7.3.3, 7.13 and 8][UM] identifies the VCP connection as
USART1 PA9/PA10 through SB11/SB15, normally connected on DISC1. C01 upgrades
the ST-LINK MCU to support V2-B; old DISCO/V2 assumptions differ. The same
manual records E01's L3GD20-to-I3G4250D gyro change and touch-controller
assembly options. Read the board revision sticker and bridge population;
“Discovery” and PCB color are insufficient identification.

The [ST board product page][PRODUCT] supplies separate B01, C01, D02 and E01
schematics. The principal comparisons here use C01 and E01; D02's MCU sheet
also shows the reserved LCD mode branches. A vendor document's publication
date does not establish the revision of the user's board.

## Pin audit

“Free” means no competing populated board function is shown in the cited
schematic, not that external wiring has been checked. “Shared” identifies
physical connectivity, not automatically opposing output drivers. LCD RGB
pins are primarily panel inputs; SDRAM data is bidirectional. Those different
loads must not be described as equivalent contention.

The table's archive roles are from the two source files above. Board nets
are from [C01 MCU/LCD/peripheral sheets 5–7][C] and
[E01 MCU/SDRAM/USB/LCD/peripheral sheets 3–7][E], cross-checked against
[UM1670 table 7][UM].

| Pin | Archive role | Stock board net or function | Assessment/source |
| --- | --- | --- | --- |
| PA5 | SPI1 SCK | Free | Candidate [C] |
| PA6 | SPI1 MISO | LCD G2 | Shared input load [C] |
| PA7 | SPI1 MOSI | CN3 ACP_RST | Shared connector reset [C] |
| PB0 | PWM3 | LCD R3 | Shared [C] |
| PB1 | PWM4 | LCD R6 | Shared [C] |
| PB4 | PWM1 | Free; MCU JTAG-related pin | Candidate [C] |
| PB5 | PWM2 | SDRAM SDCKE1 | Shared [C] |
| PE0 | Safety input | SDRAM NBL0 | Shared [C] |
| PE2 | IMU CS | Free | Candidate [C] |
| PE3 | Barometer CS | Free | Candidate [C] |
| PE4 | Relay1 low | Free | Candidate [C] |
| PE5 | Relay2 low | Free | Candidate [C] |
| PE9 | Buzzer TIM1_CH1 | SDRAM D6 | Shared [E] |
| PE11 | PWM5 | SDRAM D8 | Shared [E] |
| PE13 | PWM6 | SDRAM D10 | Shared [E] |
| PE14 | PWM7 | SDRAM D11 | Shared [E] |
| PC0 | Battery current ADC | SDRAM SDNWE | Shared [E] |
| PC3 | Battery voltage ADC | Free | No battery divider shown [E] |
| PC6 | USART6 TX | LCD HSYNC | Shared [E] |
| PC7 | USART6 RX | LCD G6 | Shared [E] |
| PC9 | I2C3 SDA | CN3/touch I2C3 SDA | Shared bus [E] |
| PD5 | USART2 TX | Reserved LCD IM2 branch | Inspect mode bridge [D] |
| PD6 | USART2 RX | LCD B2 | Shared [E] |
| PD8 | USART3 TX | SDRAM D13 | Shared [E] |
| PD9 | USART3 RX | SDRAM D14 | Shared [E] |
| PA0 | First safety declaration | B1 USER button | Active-high button [C] |
| PA8 | I2C3 SCL | CN3/touch I2C3 SCL | Shared bus [E] |
| PA9 | USART1 TX | ST-LINK RX via SB11 | VCP conditional [UM] |
| PA10 | USART1 RX | ST-LINK TX via SB15 | VCP conditional [UM] |
| PB13 | VBUS commented out | CN6 VBUS sensing/indicator | Electrically attached [E] |
| PB14 | OTG2 DM | CN6 DM | Correct USB pair [E] |
| PB15 | OTG2 DP | CN6 DP | Correct USB pair [E] |

The [D02 MCU sheet][D] shows PD2's reserved IM0 branch as well. In the present
GuidancePilot wiring PD2 serves UART5 RX with SB25 kept open; PD5's IM2 branch
is a similar reason to inspect the actual assembly before calling it free.

### Consequences, separating inference from wiring facts

- The fixed connections do **not** prove that the CPU cannot boot. A firmware
  that never initializes FMC or LTDC may execute entirely from internal memory
  while leaving the corresponding board functions unused. That is an inference,
  not a validation of reset states, loading, signal quality or output safety.
- SPI1's PA6 MISO is also an LCD input; this is a load and display-function
  conflict, not proof that the panel drives against the sensor. PA7 can toggle
  reset on an attached CN3 expansion. Neither statement proves that an actual
  external ICM-20948/BMP388 pair was ever installed there.
- PWM, buzzer, UART and safety assignments on SDRAM/LCD nets require an explicit
  decision to abandon those board functions and validate inactive devices.
  Header accessibility does not electrically isolate soldered peripherals.
- PC3 has no stock battery-voltage divider; PC0 is a memory control signal.
  The archive's voltage/current scales do not establish a valid battery monitor.
  Avoid attaching battery voltage directly to ADC or extension contacts.
- Both safety declarations use the same label, first PA0 then PE0. Generated
  configuration and safety behavior must be checked; the USER button's presence
  does not prove the final safety input uses it.

## USB power switch and debug recovery

[C01 USB sheet 3][C] and [E01 USB sheet 5][E] connect PC4 through R72 (0 Ω)
to U8 EN, with R71 (10 kΩ) pulling EN to 3V. U8 is STMPS2141STR. Its
[datasheet table 1 and table 16][SWITCH] specifies active-low enable and a
2.0-V minimum high input. Thus a floating PC4 normally leaves the host-power
switch off; an explicit high disables it.

The verification worker's actual generated application configures PC4 as an
input with **no internal pull**. R71 therefore provides the inactive high level.
This source-based expectation is not a measurement; **omitting PC4 is not
sufficient evidence that the board sources VBUS**. Measure EN and connector VBUS
through reset/startup to establish actual behavior. Disabling VBUS sensing in
firmware likewise does not disconnect PB13 physically.

The archive bootloader names SWD PA13/PA14; its application does not. Whether
the application reconfigures those pins is a generated-code question. If it
does, ordinary debug attachment after startup can fail while connection under
reset remains a separate recovery route. That would not by itself prove a
permanent hardware failure or explain a missing sensor.

## Current wiring is a different configuration

The existing [GuidancePilot definition](../../../libraries/AP_HAL_ChibiOS/hwdef/GuidancePilotF429/hwdef.dat)
and [wiring record](../../../libraries/AP_HAL_ChibiOS/hwdef/GuidancePilotF429/expansion-wiring.md)
are the primary sources for the current intended assembly, not evidence of what
was historically attached to MAF429.

| Function | Archived MAF429 | Current GuidancePilotF429 |
| --- | --- | --- |
| MCU/board ID | F427 profile / 1101 | F429 profile / 5656 |
| External IMU | ICM-20948 SPI1 PA5/PA6/PA7, CS PE2 | MPU9250-family SPI4 PE2/PE5/PE6, CS PE3 |
| Barometer | BMP388 SPI1, CS PE3 | No confirmed external barometer |
| Compass | AK09916 via ICM-20948 | No confirmed compass |
| GPS pins | USART2 PD5/PD6 declaration | UART5 PC12/PD2; SB25 open |
| SD reader | No SD device | HW-125 SPI5 PF7/PF8/PF9, CS PE4 |
| Onboard SPI5 devices | Not explicitly deselected | Gyro CS PC1 and LCD CS PC2 held high |
| Final serial declaration | USB + USART1 | USB + USART1 + UART5 |
| Parameter storage | Empty storage | Flash parameter pages |

The current IMU declaration uses the `Invensense` backend. The archive uses
`Invensensev2`, `BMP388` and `AK09916:probe_ICM20948`; these are materially
different device/probe expectations. The expansion's exact chip identity and
mounting still require the identification evidence and readback recorded in the
current board work; this research did not read its WHO_AM_I registers.

TDK's [ICM-20948 DS-000189 revision 1.5, section 3.6][ICM] specifies a
7-MHz maximum SPI clock and 1.71–1.95-V VDDIO. A hypothetical GY-912 carrier
would need verified level conversion; the bare chip is not a 3.3-V I/O device.
The archive requests 4/8 MHz low/high speeds. That is not proof of actual
8-MHz SCK: [SPIDevice.cpp](../../../libraries/AP_HAL_ChibiOS/SPIDevice.cpp)
rounds down to supported divisors. At an 84-MHz APB2 clock, its algorithm
selects 2.625/5.25 MHz respectively, below 7 MHz. Verify the generated clocks
and measure SCK before declaring a timing violation or a validated interface.

Applying the archive to the currently wired assembly would make PE2 an IMU
chip-select instead of SPI4 clock, drive PE5 low instead of receiving SPI4 MISO,
and drive PE4 low as a relay instead of deselecting the SD card. PE3 would be a
barometer select on the wire presently used for IMU selection. Those are direct
configuration mismatches, including possible MCU-to-IMU output contention on
PE5 when the IMU drives MISO. USB enumeration would not resolve them.
The archive's later `SERIAL_ORDER OTG1 USART1` also supersedes the earlier
GPS/RC/telemetry list; listing USART2 pins is insufficient to expose a GPS port.

The [HW-125 research](../../research/guidance-f429-hw125-reader.md) separately records why
SPI5 has only one active slave in the current profile: its MISO buffer release
is unconfirmed. The stock gyro is gyro-only; neither schematic contains the
archive's external ICM-20948/BMP388 pair. [C01 peripheral sheet 6][C] names
L3GD20; [E01 peripheral sheet 7][E] names I3G4250D.

## What remains unproved

To settle historical “worked” versus “booted,” retain actual firmware hashes,
uploader/USB identity, sensor detections, parameter persistence and serial-port
readback from the same firmware and wiring. For physical compatibility, record
the MB1075 revision, component population/bridges, oscillator source, reset-state
CS and USB EN/VBUS measurements, and any actuator waveforms with loads isolated.
No such measurements were made for this report. A source audit cannot establish
healthy sensors, usable RC/GPS channels or safe output behavior.

[UM]: https://www.st.com/resource/en/user_manual/um1670-discovery-kit-with-stm32f429zi-mcu-stmicroelectronics.pdf
[C]: https://www.st.com/resource/en/schematic_pack/mb1075-f429i-c01_schematic.pdf
[D]: https://www.st.com/resource/en/schematic_pack/mb1075-f429i-d02_schematic.pdf
[E]: https://www.st.com/resource/en/schematic_pack/mb1075-f429i-e01_schematic.pdf
[DS]: https://www.st.com/resource/en/datasheet/stm32f429zi.pdf
[SWITCH]: https://www.st.com/resource/en/datasheet/stmps2141.pdf
[PRODUCT]: https://www.st.com/en/evaluation-tools/32f429idiscovery.html

[ICM]: https://product.tdk.com/system/files/dam/doc/product/sensor/mortion-inertial/imu/data_sheet/ds-000189-icm-20948-v1.5.pdf
