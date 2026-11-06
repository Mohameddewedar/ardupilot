# MAF429 generated configuration and software compatibility

Date: 2026-11-06. AI-assisted source inspection. This describes the unchanged
archive at verification commit `73097f11a7e5897c220d67262d0a68127decc4ee`.
Paths below are relative to the repository root.

## Why compilation can succeed

Both definitions select `STM32F427xx`, although the Discovery board is an F429.
The repository's `libraries/AP_HAL_ChibiOS/hwdef/scripts/STM32F427xx.py` and
`STM32F429xx.py` have equal RAM maps (192 KiB main SRAM and 64 KiB CCM) and
equal expected clocks (168 MHz). All 29 alternate-function entries used across
the two MAF429 files agree between the tables, including USB AF12, USART1 AF7
and SWD AF0. ChibiOS also groups the F427/F429 together for many peripheral
capabilities in `modules/ChibiOS/os/hal/ports/STM32/STM32F4xx/stm32_registry.h`.

These facts explain why selecting F427 need not immediately break this subset
of F429 peripherals. They do not prove equivalent initialization or all
peripheral behavior. A corrected board definition should name its actual MCU.
The [hardware research](hardware.md) covers physical board compatibility.

## Confirmed findings

The generated header is retained locally as
`build/original-plane/MAF429/hwdef.h` under the evidence directory.
The generator accepted the repeated declarations; they are behavioral
problems rather than demonstrated compiler errors.

| Archive declaration | Generated or source-backed effect | Consequence |
| --- | --- | --- |
| Two `SERIAL_ORDER` lines | The final `OTG1 USART1` wins; `HAL_NUM_SERIAL_PORTS` is 2 and SERIAL2–9 use Empty UART drivers. | The comments promising GPS on USART2, RC on USART3 and telemetry on USART6 do not describe exposed ArduPilot serial ports. Some unused UART pins remain configured as alternate functions. |
| PA0 and then PE0 both named `SAFETY_IN` | `HAL_GPIO_PIN_SAFETY_IN` resolves to PE0. PA0 still receives its declared input/pull-up configuration. | The onboard PA0 pushbutton is not the safety input used by `RCOutput::safety_update()`. PE0 is also connected to SDRAM NBL0. |
| `HAL_USE_EMPTY_STORAGE 1` and size 16384 | `HAL_ChibiOS_Class.cpp` instantiates `Empty::Storage`; `libraries/AP_HAL_Empty/Storage.cpp` returns zeros on reads and ignores writes. | The size does not create a parameter store. There is no persistent storage backend here. This is stronger than merely losing changes on reboot: reads do not return previously written bytes. |
| `HAL_BATT_CURR_PIN 12`, PC0 as ADC1 | Generated analog inputs are channel/pin 10 for PC0 and 13 for PC3. | The current-monitor default does not name its declared PC0 input. No fitted battery/current circuit or scale calibration is established. PC0 is also SDRAM write-enable. |
| `APJ_BOARD_ID 1101` | Generated packages carry 1101; `Tools/AP_Bootloader/board_types.txt` already assigns 1101 to `AP_HW_mRoControlOne`. | This identifier is not unique to MAF429. It is also incompatible with installed GuidancePilotF429's 5656. Do not bypass uploader identity checks to test it. |
| App reserve 16 KiB; bootloader load 16 KiB | App vectors/link address start at 0x08004000; loader jumps there. | The pair is internally consistent and the built loader fits. Installed GuidancePilotF429 starts its app at 0x08010000. Mixing either loader with the other app layout will not work. |
| SWD pins declared only in the bootloader | Generated application PA13/PA14 modes are INPUT, rather than SWD AF0. | Ordinary SWD access can be lost after app GPIO initialization; recovery may require connection under reset. The failed live SWD probe was against GuidancePilotF429, so it does not verify this predicted MAF429 behavior. |
| ICM20948/BMP388 on SPI1, CS PE2/PE3 | Explicit Invensensev2 and BMP388 probes are generated. | The existing MPU9250 on SPI4 is not that IMU or bus. `Invensensev2::_check_whoami()` supports ICM20648/20649/20948, not MPU9250. A module marketing name is not proof of those silicon identities. |
| Compass `AK09916:probe_ICM20948 0` | The generator produces `AP_Compass_AK09916::probe_ICM20948(0, ROTATION_NONE)`. | This is valid generated syntax; it depends on a working compatible ICM20948 auxiliary bus. It cannot supply a compass when that IMU is absent. |
| PG13/PG14 GPIO LED macros | GPIOs are generated, but the archive does not enable `AP_NOTIFY_GPIO_LED_2_ENABLED`; its default in `AP_Notify_config.h` is zero. | GPIO declarations alone do not select the normal two-LED application notify backend. The bootloader's LED is a separate mechanism. |
| PE9 TIM1 alarm plus PE11/13/14 TIM1 PWM | Both alarm and output groups refer to `PWMD1`. `ChibiOS::Util::toneAlarm_init()` starts that driver and tone changes alter its period. | Independent buzzer and servo frequencies on that one timer are not established. Do not qualify the declared servo outputs from compilation. |
| `SPI_ORDER SPI1` | No `SPI_ORDER` handler exists in `chibios_hwdef.py`; the actual SPI bus list follows configured SPI pins. | This extra line is not evidence of a needed fix or an active ordering control. SPI1 does appear in the generated bus list. |

`STM32_ST_USE_TIMER 5` plus its repeated raw `define`, the repeated USB driver
define and the unusual compass declaration did not stop either measured build.
The build logs should take precedence over guesses that these are fatal syntax
errors. The app build prints `No APP_DESCRIPTOR found` and still exits zero;
this investigation does not count that line as a failed build.

## USB details

The generated SerialUSB configuration routes SDU1 to USBD2 when
`STM32_OTG2_IS_OTG1` is set; see
`libraries/AP_HAL_ChibiOS/hwdef/common/usbcfg.c`. PB14/PB15 receive alternate
function 12. This is the right controller/pin family for the board's native
micro-AB connection. PA11/PA12 are not required for this USB path.

PB13 VBUS sensing and PC4 power-switch control are omitted from the archive.
The generated PC4 is INPUT/FLOATING, not OUTPUT LOW or INPUT/PULLDOWN. The ST
schematic's external pull-up on the active-low switch enable matters; omission
alone does not prove that the board drives host VBUS. See [hardware.md](hardware.md)
for the circuit evidence. Actual switch level and original-image USB
enumeration were not measured.

## Separate disposition of possible corrections

No fixes were applied to the imported files. A future experiment would first
need an exact assembly/revision inventory, correct MCU and unique board
identity, an intentional nonvolatile storage/flash layout, one serial order,
one deliberate safety input, preserved SWD, compatible sensor probes, and a
pin allocation that accounts for attached LCD/SDRAM and existing external
wiring. USB control and timer ownership also need explicit review.

That would be a different definition, whose successful boot would not validate
the original archive. The existing GuidancePilotF429 implementation is retained
as the development line; creating or qualifying a replacement is beyond this
verification effort.
