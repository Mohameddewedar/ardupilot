# GuidancePilotF429: stock STM32F429I-DISC1 bench constraints

Research for [GuidancePilotF429: establish stock Discovery wiring and viable sensor configuration](https://github.com/Mohameddewedar/ardupilot/issues/3), under [GuidancePilotF429: bring up stock STM32F429 Discovery with ArduPlane](https://github.com/Mohameddewedar/ardupilot/issues/2).

Researched 2026-11-04 with AI assistance. Source baseline: `18763c2f71a33facb013c73852ac6e160e70e11e` on `GuidancePilotF429`. This throwaway research branch contains documentation only; it is not an implementation or a firmware validation result.

## Finding

The user confirmed **STM32F429I-DISC1** during this investigation. Stock hardware cannot provide a complete ArduPlane sensor set. Correct clock, USB, storage, and pin definitions can support a meaningful bench test of enumeration, MAVLink identity, and an explicit missing-sensor configuration error. Normal ArduPlane initialization and estimator operation require additional real hardware or a separately agreed simulation effort. Do not describe an error-loop connection as normal vehicle startup.

### Identity and revision

ST distinguishes STM32F429I-DISC1 (replacement for STM32F429I-DISCO) from NUCLEO-F429ZI. The latter is a Nucleo-144 board, not this LCD/SDRAM Discovery design. [ST Discovery product page](https://www.st.com/en/evaluation-tools/32f429idiscovery.html), [ST Nucleo product page](https://www.st.com/en/evaluation-tools/nucleo-f429zi.html).

DISC1 uses **STM32F429ZIT6**, with 2 MiB flash, 192 KiB main SRAM plus 64 KiB CCM; the external SDRAM is separate. Record the board marking `MB1075-F429-<revision>`: B/C carry L3GD20; E replaces it with I3G4250D. The revision changes the gyro identity, not the absence of an accelerometer. [UM1670 Rev 6, product history and board revision history](https://www.st.com/resource/en/user_manual/um1670-discovery-kit-with-stm32f429zi-mcu-stmicroelectronics.pdf#page=32), [DS9405, device features](https://www.st.com/resource/en/datasheet/stm32f429zi.pdf).

Read-only Linux sysfs inspection during this session found `0483:3752`, product `STM32 STLink`, serial `066BFF353138524E43114242`. That identifies the connected debugger interface, not target firmware or a particular target PCB. No target USB enumeration, MCU debug read, or firmware execution was demonstrated by this research.

## Clock and two distinct USB connections

Use the **8 MHz crystal configuration** for an unmodified Discovery: ST's Discovery template selects `RCC_HSE_ON`, not `RCC_HSE_BYPASS`. The current hwdefs' unconditional `STM32_HSE_BYPASS` therefore need review. ArduPilot's F429 table expects 168 MHz; its common F4 configuration uses PLL M=8, N=336, P=2, Q=7 for 8 MHz HSE, yielding 168 MHz CPU and 48 MHz USB clocks. Retain that supported profile rather than importing the template's 180 MHz PLL settings. [ST Discovery template](https://github.com/STMicroelectronics/STM32CubeF4/blob/master/Projects/STM32F429I-Discovery/Templates/Src/main.c#L86), [local F429 MCU table](../../libraries/AP_HAL_ChibiOS/hwdef/scripts/STM32F429xx.py), [local F4 clock configuration](../../libraries/AP_HAL_ChibiOS/hwdef/common/stm32f47_mcuconf.h).

If the board was modified, verify the actual source: UM1670 describes crystal operation with SB18/19/20 OFF and X3/C20/C21/R56/R57 populated, or ST-LINK MCO operation at 8 MHz with SB18 ON, SB19/R56 OFF. Only the latter justifies bypass. Inspect solder bridges and X3 before selecting a non-stock clock configuration. [UM1670 §7.12](https://www.st.com/resource/en/user_manual/um1670-discovery-kit-with-stm32f429zi-mcu-stmicroelectronics.pdf#page=22).

- **CN1 mini-USB** belongs to ST-LINK. Its VCP reaches target **USART1 PA9 TX / PA10 RX**, through **SB11/SB15, ON by default on DISC1**. Stock DISC1 needs no added UART wires. DISCO's bridge defaults differ. PA13/PA14 are SWD; keep them available. [UM1670 §7.3.3 and Table 6](https://www.st.com/resource/en/user_manual/um1670-discovery-kit-with-stm32f429zi-mcu-stmicroelectronics.pdf#page=17).
- **CN6 micro-AB** belongs to the target's **OTG_HS controller using its internal full-speed PHY**: PB14 D−, PB15 D+, PB13 VBUS, PB12 ID. PC4 controls the active-low VBUS supply switch; keep it HIGH for device-only bench use. PC5 is overcurrent. The schematic's `OTG_FS_*` net names describe operating speed, not the OTG_FS controller on PA11/PA12. [MB1075 C01 schematic, MCU/USB sheets](https://www.st.com/resource/en/schematic_pack/mb1075-f429i-c01_schematic.pdf#page=5).

### USB generation implications

The tracked application uses OTG2 pins but `SERIAL_ORDER OTG1 UART4 UART7`, without the bootloader's alias/USB enables. In this generator, OTG2 alone enables `STM32_USB_USE_OTG2`, whereas the OTG1-pin branch emits `HAL_USE_USB` and `HAL_USE_SERIAL_USB`. The serial entry OTG1 selects SDU1; `serusbcfg1` can explicitly select USBD2 through `STM32_OTG2_IS_OTG1`. [Tracked hwdefs](../../libraries/AP_HAL_ChibiOS/hwdef/GuidancePilotF429), [generator, `write_mcu_config` and serial generation](../../libraries/AP_HAL_ChibiOS/hwdef/scripts/chibios_hwdef.py), [USB configuration, `serusbcfg1`](../../libraries/AP_HAL_ChibiOS/hwdef/common/usbcfg.c).

A minimal existing-code route is PB14/PB15 typed **OTG2**, `SERIAL_ORDER OTG1 USART1`, and these explicit defines in **both** application and bootloader: `HAL_USE_USB TRUE`, `HAL_USE_SERIAL_USB TRUE`, `STM32_OTG2_IS_OTG1 TRUE`. Keep USART1 pin declarations, PB13 VBUS input and PC4 HIGH. This is a source-supported configuration recommendation, not a completed build or USB test. Confirm generated headers select USBD2 and preserve 48 MHz before flashing. The F429 alternate-function table already has PB14/PB15 AF12, USART1 PA9/PA10 AF7, and SPI5 PF7/PF8/PF9 AF5; those particular entries need no invention. [F429 table](../../libraries/AP_HAL_ChibiOS/hwdef/scripts/STM32F429xx.py).

## Sensor inventory and actual drivers

Both **L3GD20** and **I3G4250D** measure three-axis angular rate and temperature; neither measures acceleration, magnetic field, or air pressure. There is no stock accelerometer, compass, or barometer in this board's documented inventory/schematic. LCD touch hardware is not an inertial sensor. [L3GD20 datasheet](https://www.st.com/resource/en/datasheet/l3gd20.pdf), [I3G4250D datasheet](https://www.st.com/resource/en/datasheet/i3g4250d.pdf), [MB1075 E01 schematic](https://www.st.com/resource/en/schematic_pack/mb1075-f429i-e01_schematic.pdf).

The stock gyro is on **SPI5: PF7 SCK, PF8 MISO, PF9 MOSI, PC1 chip select**, with interrupts PA1/PA2. SPI5 SCK/MOSI also reach the display controller; account for both chip selects if that bus is used later. The tracked SPI1 definitions and Pixhawk sensor-CS labels do not establish working sensor wiring. [MB1075 C01 MCU/peripheral sheets](https://www.st.com/resource/en/schematic_pack/mb1075-f429i-c01_schematic.pdf#page=5).

ArduPilot has an **LSM9DS0 backend** that supports an L3GD20 gyro **paired with an LSM303D accelerometer**. Its `probe()` requires both devices, `_hardware_init()` validates both WHOAMI registers, and `start()` registers both gyro and accel. It cannot represent the stock gyro alone. The `DEVTYPE_GYR_I3G4250D` enum is an identifier, not a working backend: there is no separate I3G4250D backend in this source tree. Do not instantiate LSM9DS0 with a fictional accel or assume I3G4250D is interchangeable solely from a matching register value. [LSM9DS0 backend](../../libraries/AP_InertialSensor/AP_InertialSensor_LSM9DS0.cpp), [backend device types](../../libraries/AP_InertialSensor/AP_InertialSensor_Backend.h).

The actual startup behavior is decisive:

1. `Plane::init_ardupilot()` calls `barometer.init()` before `startup_INS()`. Without a barometer, the default `AP_Baro::init()` enters `config_error("Baro: unable to initialise driver")`. Its existing `HAL_BARO_ALLOW_INIT_NO_BARO` guard permits omission, but does not create pressure data. [Plane startup](../../ArduPlane/system.cpp), [barometer initialization/calibration](../../libraries/AP_Baro/AP_Baro.cpp).
2. With that barometer guard deliberately enabled for diagnostics, missing INS backends enter `config_error("INS: unable to initialise driver")`. **`AP_INERTIALSENSOR_ALLOW_NO_SENSORS=1` is not a valid normal-startup workaround at this baseline**: it skips that config error, but `_start_backends()` then panics without a gyro and accel; `wait_for_sample()` also requires both data masks. [INS startup, detection, and sample loop](../../libraries/AP_InertialSensor/AP_InertialSensor.cpp).
3. `AP_BoardConfig::throw_error()` continuously services MAVLink receive/send and repeats the critical error every five seconds. Thus transport/identity and stable diagnostic reporting are useful stock-board acceptance criteria. The main vehicle startup has not completed. [BoardConfig error loop](../../libraries/AP_BoardConfig/AP_BoardConfig.cpp).

An external real supported six-axis IMU (for example one handled by the existing Invensense backend) and barometer would be a subsequent hardware-integration project. Compass requirements then depend on the intended estimator and vehicle setup. None is authorized as an assumed stock-board device here. [Existing Invensense implementation](../../libraries/AP_InertialSensor/AP_InertialSensor_Invensense.cpp).

## Remove inherited board assumptions

These are actual conflicts between the tracked hwdef and the stock circuit. Disable unused peripheral pin declarations as part of a minimal bench definition; do not actively drive attached devices as unrelated Pixhawk hardware.

| Tracked use | Stock Discovery connection |
| --- | --- |
| PA0 UART4 TX; PA1 RX; PA2 battery ADC | User button; gyro INT1; gyro INT2 |
| PA3/PA4 ADC; PA6 SPI1; PB0/PB1 GPIO | LCD signals |
| PA7 SPI1 MOSI; PA8 peripheral power | Touch reset; touch I2C3 clock |
| PA15 alarm | Touch interrupt |
| PB6 CAN2 TX; PC0 power-valid input | SDRAM SDNE1; SDRAM SDNWE |
| PB8/PB9 I2C1; PB10/PB11 I2C2 | LCD RGB signals |
| PB12 CAN2 RX; PC5 pressure ADC | USB ID; USB overcurrent |
| PC1 MAG CS; PC2 MPU CS | Actual gyro CS; actual LCD CS |
| PD0/PD1 CAN; PD8/PD9 USART3; PD10 FRAM CS | SDRAM data |
| PD11/PD12 USART3 flow control; PD13 PWM | LCD control |
| PE9/PE11/PE13/PE14 and PD14 PWM; PE7/PE8 UART7 | SDRAM data |
| PC8..PC12/PD2 SDIO | No stock microSD socket; several pins also have display/touch functions |

Derived by comparing the [tracked application definition](../../libraries/AP_HAL_ChibiOS/hwdef/GuidancePilotF429/hwdef.dat) with the [MB1075 E01 MCU and peripheral schematics](https://www.st.com/resource/en/schematic_pack/mb1075-f429i-e01_schematic.pdf#page=3). The board also has no Pixhawk sensor power rails, IOMCU, safety switch, FRAM, or power brick. Remove corresponding inherited feature/default claims rather than treating arbitrary GPIO labels or ADC scales as measurements. Preserve bootloader PG13 LED and SWD.

## Flash and parameter storage

STM32F429ZI flash spans **0x08000000–0x081FFFFF**. Each 1 MiB bank contains four 16 KiB sectors, one 64 KiB sector, then seven 128 KiB sectors; sector 12 starts at 0x08100000. Early sectors 0/1/2/3 begin at 0x08000000 / 0x08004000 / 0x08008000 / 0x0800C000. [RM0090 §3.4, Table 6](https://www.st.com/resource/en/reference_manual/rm0090-stm32f4xx-reference-manual-stmicroelectronics.pdf).

The tracked application defaults to a 16 KiB reserve; its bootloader explicitly loads at 16 KiB. Their 5656 APJ IDs agree, but the application defines storage size without a flash-storage sector or FRAM device, and declares a nonexistent SD card. Declaring capacity does not provide persistent storage. [Tracked definitions](../../libraries/AP_HAL_ChibiOS/hwdef/GuidancePilotF429), [ChibiOS storage backend selection](../../libraries/AP_HAL_ChibiOS/Storage.cpp).

A practical explicit layout for later implementation is bootloader sector 0 (must fit 16 KiB), parameter journal sectors 1+2 (32 KiB total), unused sector 3, application from **64 KiB / 0x08010000**. Set `STORAGE_FLASH_PAGE 1`, `HAL_STORAGE_SIZE 15360`, application `FLASH_RESERVE_START_KB 64`, bootloader `FLASH_BOOTLOADER_LOAD_KB 64` and bootloader reserve 0. The generator rejects storage overlap and limits storage in a 16 KiB sector to 15360 bytes. Rebuild both images and verify linked addresses, binary sizes, and parameter persistence after resets. This changes the old application entry address, so old bootloader binaries are not proof of compatibility. [Generator storage validation/linker generation](../../libraries/AP_HAL_ChibiOS/hwdef/scripts/chibios_hwdef.py), [flash journal initialization](../../libraries/AP_HAL_ChibiOS/Storage.cpp).

**Do not choose end-of-flash storage using this generator without further correction.** Its F4 2048 KiB `get_flash_pages_sizes()` list incorrectly continues 128 KiB sectors at index 12 instead of restarting with 16/16/16/16/64 KiB; it totals 2560 KiB. The runtime `flash.c` correctly repeats bank geometry. Early pages 1+2 avoid that disagreement. This is an independently found source inconsistency, not a tested fix. [Generator table](../../libraries/AP_HAL_ChibiOS/hwdef/scripts/chibios_hwdef.py), [runtime flash map](../../libraries/AP_HAL_ChibiOS/hwdef/common/flash.c).

## Evidence boundary and next decision

This research inspected primary ST documents and local source, read USB sysfs descriptors, and checked links/flash arithmetic. It did **not** install tools, build firmware, change hwdefs, flash, power-cycle, or observe runtime sensor/USB behavior. Existing generated build artifacts were not used as evidence.

Before upload, record the PCB revision and confirm that the board remains in its stock crystal/VCP configuration. A separate implementation/bench session can then validate corrected transport/storage definitions and the expected truthful sensor error. The human must decide whether that limited outcome satisfies this map's stock-board destination, or whether the destination must change to include real external sensors. Full normal ArduPlane startup on this stock board is not achievable merely by correcting hwdefs.
