# GuidancePilotF429: Discovery expansion interface candidates

Research for
[GuidancePilotF429: establish conflict-free Discovery expansion interfaces](https://github.com/Mohameddewedar/ardupilot/issues/7),
under
[GuidancePilotF429: integrate external IMU, GPS and microSD for bench use](https://github.com/Mohameddewedar/ardupilot/issues/6).
Researched 2026-11-04 with AI assistance against source baseline
`7a7939c2f533e22b88e0deca42c81d6590daa146`. Documentation only; no firmware,
build, upload, target access, or electrical test was performed.

## Decision supported by the evidence

An unmodified MB1075 Discovery has a candidate route for an external MPU9250/6500
and SPI microSD sharing **SPI4**, plus **UART5** for a u-blox GPS. Separate GPIO
chip selects avoid selecting both SPI slaves together. This route leaves the
stock display, touch controller, SDRAM, gyro, USB, SWD, and ST-LINK VCP wiring
available. This is a board-side allocation, not a connection schematic for
unidentified carriers or proof of acceptable IMU/logging timing.

### Correct connector names

The two 64-pin expansion headers are **P1 and P2**, in both the C01 and E01
schematics and UM1670. **CN3 is the 8-pin ACP/I2C accessory connector; CN4 is the
ST-LINK/DISCOVERY SWD jumper block.** A request for “CN3/CN4 expansion pins” must
therefore be corrected before wiring. Use the PCB reference designator and pin-1
mark; connector numbering is not a count along one edge of the board.
[UM1670 Rev 6 §7.3.4, §7.14 and Table 7](https://www.st.com/resource/en/user_manual/um1670-discovery-kit-with-stm32f429zi-mcu-stmicroelectronics.pdf#page=24),
[C01 sheets 1, 2 and 6](https://www.st.com/resource/en/schematic_pack/mb1075-f429i-c01_schematic.pdf),
[E01 sheets 2, 7 and 8](https://www.st.com/resource/en/schematic_pack/mb1075-f429i-e01_schematic.pdf#page=2).

## Candidate allocation

Directions below are relative to the STM32. All listed signal mappings agree in
C01 and E01. The MCU alternate functions also exist in the repository's
[STM32F429 table](../../libraries/AP_HAL_ChibiOS/hwdef/scripts/STM32F429xx.py).

| Proposed role | MCU pad | MCU LQFP144 pin | Header contact | Configuration |
| --- | --- | --- | --- | --- |
| Shared SPI clock, output | PE2 | 1 | P1-15 | SPI4_SCK, AF5 |
| Shared SPI data from slaves, input | PE5 | 4 | P1-14 | SPI4_MISO, AF5 |
| Shared SPI data to slaves, output | PE6 | 5 | P1-11 | SPI4_MOSI, AF5 |
| MPU chip select, output | PE3 | 2 | P1-16 | GPIO CS, inactive HIGH |
| microSD chip select, output | PE4 | 3 | P1-13 | GPIO CS, inactive HIGH |
| GPS configuration data, output | PC12 | 113 | P1-43 | UART5_TX, AF8; goes to GPS RX |
| GPS received data, input | PD2 | 116 | P1-40 | UART5_RX, AF8; receives GPS TX |
| Optional spare for MPU interrupt | PC8 | 98 | P1-55 | GPIO input if required by later design |

Header/board allocation:
[C01 sheet 1 and MCU sheet 5](https://www.st.com/resource/en/schematic_pack/mb1075-f429i-c01_schematic.pdf#page=1),
[E01 sheets 2–3](https://www.st.com/resource/en/schematic_pack/mb1075-f429i-e01_schematic.pdf#page=2).
Pin numbers/AF selection:
[DS9405 Rev 14 Tables 10 and 12, pp. 53–54, 67–68, 77–79](https://www.st.com/resource/en/datasheet/stm32f429zi.pdf#page=79).

PE2–PE6, PC12, and PC8 have no onboard peripheral load in the examined
schematics. PD2 also has the reserved **SB25** branch toward LCD mode strap
**IM0**; it is usable here only with SB25 **OFF**, its documented stock state.
Leave the reserved SB22–SB25 bridges OFF. UM1670 Table 7 independently marks
these candidate pins as free I/O in the stock configuration. In particular,
PE3 and PE4 run to P1 and the MCU rather than another onboard driver or chip
select. PE4's possible MCU function `LCD_B0` is not an actual connection to this
board's LCD; likewise PE5/PE6's alternate LCD functions do not make them occupied.
Use PE4 as a software-controlled GPIO CS rather than assuming the controller's
hardware NSS will select two independent slaves. The PE3/PE4 assignments may be
swapped when the carrier layout is known.
[UM1670 Tables 6–7, pp. 23–28](https://www.st.com/resource/en/user_manual/um1670-discovery-kit-with-stm32f429zi-mcu-stmicroelectronics.pdf#page=23),
[C01 circuit sheets](https://www.st.com/resource/en/schematic_pack/mb1075-f429i-c01_schematic.pdf),
[E01 circuit sheets](https://www.st.com/resource/en/schematic_pack/mb1075-f429i-e01_schematic.pdf).

Ground is available at **P1-63/P1-64** and **P2-11/P2-29/P2-63**. The board's
rail labelled **3V** is on **P2-1/P2-2**; **5V** is on **P1-1/P1-2**. These are
reference contacts, not an approved module-power assignment. UM1670 limits
external application consumption from the board supply outputs to below 100 mA.
Resolve the GPS, SD write-current peaks, carrier regulators, logic levels, and
power sequencing before deciding whether those outputs can supply any module.
[UM1670 §7.4 and Table 7 p. 30](https://www.st.com/resource/en/user_manual/um1670-discovery-kit-with-stm32f429zi-mcu-stmicroelectronics.pdf#page=30),
[E01 sheet 2](https://www.st.com/resource/en/schematic_pack/mb1075-f429i-e01_schematic.pdf#page=2).

## Preserve the stock circuits

These are reasons to reject attractive alternative pinouts, rather than
instructions to disconnect the stock devices:

| Candidate/use | Existing board connection or conflict |
| --- | --- |
| USB PB14/PB15 | Target USB D−/D+; retain PB12 ID, PB13 VBUS, PC4 power-switch control, PC5 overcurrent |
| PA13/PA14; PA9/PA10 | SWD; USART1 to ST-LINK VCP through SB11/SB15 |
| USART2 PD5/PD6 | PD5 at P1-37 is free; PD6 at P1-36 also reaches LCD B2, so the pair is unsuitable |
| USART6 PC6/PC7 | LCD HSYNC/G6; alternate PG14 TX carries the red LED, although PG9 RX is free |
| USART3 PD8/PD9; PB10/PB11; PC10/PC11 | SDRAM data; LCD G4/G5; LCD R2 on PC10 |
| SPI1 PA5/PA6/PA7 or PB3/PB4/PB5 | PA6 LCD, PA7 touch reset; PB3 SWO and PB5 SDRAM clock enable |
| SPI4 PE12/PE13/PE14 | SDRAM data; use PE2/PE5/PE6 instead |
| SPI5 PF7/PF8/PF9 | Stock gyro; clock/data also used by LCD, with PC1 gyro CS and PC2 LCD CS |
| SPI3 using PC12 | PC12 would be SPI3_MOSI instead of the selected UART5_TX; cannot use both functions simultaneously |
| SDIO PC8–PC12/PD2 | LCD/touch conflicts and overlap with selected GPS UART; no stock SD socket |

Derived from the actual nets in
[C01 MCU/peripheral sheets](https://www.st.com/resource/en/schematic_pack/mb1075-f429i-c01_schematic.pdf),
[E01 MCU/peripheral sheets](https://www.st.com/resource/en/schematic_pack/mb1075-f429i-e01_schematic.pdf),
and alternate functions in the
[local MCU table](../../libraries/AP_HAL_ChibiOS/hwdef/scripts/STM32F429xx.py).
Disabling a peripheral driver in software does not remove these PCB connections.

## Shared SPI4: software support and conditions

The source has an SPI SD path: `sdcard_init()` obtains the SPI device named
`sdcard`, selects its low/high speed, and uses hooks for bus acquisition, CS,
and semaphore ownership. `SPIDevice::acquire_bus()` applies the selected device's
CS pad, mode, and speed before starting the peripheral. This supports separate
MPU and SD device definitions on one SPI bus; it does not validate this proposed
board integration.
[sdcard.cpp](../../libraries/AP_HAL_ChibiOS/sdcard.cpp),
[SPIDevice.cpp](../../libraries/AP_HAL_ChibiOS/SPIDevice.cpp),
[SPIDevice.h](../../libraries/AP_HAL_ChibiOS/SPIDevice.h).

For a later implementation, define one SPI4 bus and two `SPIDEV` entries with
different GPIO CS lines and device IDs, including the exact name `sdcard`.
Use the real MPU model's probe and supported mode/rates; choose SD initialization
and operating rates independently. The generator recognizes `sdcard`, enables
the MMC SPI/FATFS path, and supports per-device speed/mode entries.
[hwdef generator](../../libraries/AP_HAL_ChibiOS/hwdef/scripts/chibios_hwdef.py),
[Invensense backend](../../libraries/AP_InertialSensor/AP_InertialSensor_Invensense.cpp).

Electrical and timing acceptance remains conditional:

- Both carriers must expose the required four-wire SPI signals and independent
  active-low CS. Confirm that their actual circuits release MISO when deselected;
  a carrier with a continuously driven level-shifter output cannot share this bus.
- Provide an inactive CS state through reset, before firmware controls the GPIOs;
  verify the carriers' existing pulls before adding components.
- Verify signal voltage, supply compatibility, wire length, grounding, and each
  carrier's speed limitations from its exact schematic/datasheet.
- Measure IMU sampling/FIFO behavior while SD writes and GPS traffic run. Bus
  locking prevents simultaneous software ownership, but does not prove that SD
  occupancy permits the required sensor service interval. If sharing fails this
  test, revisit the bus allocation or hardware; do not assume that spare MCU
  alternate functions imply another conflict-free stock-board bus.

These are design conditions, not measured results. The carrier-specific electrical
decision belongs to the companion module research and subsequent human assembly.

## Revision and evidence boundary

The selected board-side mapping is unchanged between **MB1075 C01** and **E01**.
C01 uses L3GD20, E01 I3G4250D; neither lies on the proposed SPI4 nets. Stock DISC1
VCP bridge settings preserve USART1. PB14/PB15 extension contacts depend on
SB27/SB26, respectively, and are excluded from this plan regardless of bridge
state. Record the user's actual `MB1075-F429-<revision>` marking and modifications
before treating these schematic revisions as a match.
[C01 schematic](https://www.st.com/resource/en/schematic_pack/mb1075-f429i-c01_schematic.pdf),
[E01 schematic](https://www.st.com/resource/en/schematic_pack/mb1075-f429i-e01_schematic.pdf),
[UM1670 Tables 6–7 and revision history](https://www.st.com/resource/en/user_manual/um1670-discovery-kit-with-stm32f429zi-mcu-stmicroelectronics.pdf#page=23).

Validation comprised comparison of the official schematic and manual text tables
and the checked-in MCU/ChibiOS source, plus `git diff --check`. PDF screenshot
requests returned image placeholders without image content in this environment;
direct official PDF downloads also failed. Visual pin-1/orientation verification
against the physical board remains required before assembly. No complete
carrier-to-board wiring diagram is claimed. Exact module identities, their
schematics, board revision, power budget, and shared-bus timing are still open.
