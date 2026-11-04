# GuidancePilotF429 on STM32F429I-DISC1

This definition targets the stock MB1075 STM32F429I-DISC1 Discovery board,
with its 8 MHz crystal and STM32F429ZIT6. It uses the existing 168 MHz CPU /
48 MHz USB clock profile. A board modified to use the ST-LINK clock output
requires a separate clock configuration.

## Bench scope

The stock board has a gyro, but no accelerometer, barometer or compass.
L3GD20 is fitted on earlier revisions; revision E uses I3G4250D. The existing
LSM9DS0 inertial driver requires an accelerometer as well as a gyro, so this
configuration deliberately declares no complete IMU. It does not generate
substitute sensor data or bypass the inertial startup checks.

ArduPlane is expected to enter its MAVLink-accessible configuration-error
loop with `INS: unable to initialise driver`. This is a transport and storage
bring-up configuration. Normal ArduPlane initialization and flight operation
require additional supported sensors and a reviewed wiring definition.
There are no PWM outputs configured. The LCD and external SDRAM are unused.

## Connections

| Interface | Connection |
| --- | --- |
| SERIAL0 | CN6 micro-AB USB, PB14/PB15, OTG_HS internal full-speed PHY |
| SERIAL1 | USART1 PA9/PA10, connected to the CN1 ST-LINK VCP on stock DISC1 |
| SWD | Onboard ST-LINK, PA13/PA14 |
| Gyro SPI | SPI5 PF7/PF8/PF9, chip select PC1 |
| LCD chip select | PC2 held high to deselect the LCD on shared SPI5 |
| LEDs | PG13 green, PG14 red, active high |

Keep CN1 connected for debugging; CN6 requires its own data cable to test
native target USB. The USB VBUS supply switch PC4 stays high (disabled) for
device operation. The bootloader uses USART1 at 57600 baud; the default
SERIAL1 application link also uses MAVLink at 57600 baud.

## Flash layout

| Address | Use |
| --- | --- |
| 0x08000000 | Bootloader, fits sector 0 (16 KiB) |
| 0x08004000 | Parameter journal sector 1 |
| 0x08008000 | Parameter journal sector 2 |
| 0x0800C000 | Reserved sector 3 |
| 0x08010000 | ArduPlane application |

Parameter capacity is 15360 bytes. Both the bootloader load offset and the
application reserve are 64 KiB. The previous 16 KiB application offset is
incompatible: rebuild and install both images together. Board ID 5656 is
retained for this development target.

## Pin labels

Use the generator's canonical labels `OTG_HS_DM` / `OTG_HS_DP` and
`JTMS-SWDIO` / `JTCK-SWCLK`. The corresponding F429 alternate-function
entries are AF12 for USB and AF0 for SWD. Labels beginning `USB_OTG_` or
`SYS_JT` are not recognized as alternate functions by this generator and
silently leave these pins as inputs. Check the generated pin modes as well
as whether compilation succeeds.

## Build and validation

From the repository root, with the ARM toolchain and Python dependencies
available:

```sh
python3 Tools/scripts/build_bootloaders.py GuidancePilotF429
./waf configure --board GuidancePilotF429 --no-submodule-update
./waf plane
```

The application build embeds `Tools/bootloaders/GuidancePilotF429_bl.bin`;
regenerate that file before building the application. Back up existing flash
before programming. The generated `arduplane_with_bl.hex` includes both
images; a raw `arduplane.bin` starts at 0x08010000.

Bench checks should include programming/readback verification, bootloader
board identity, MAVLink version and disarmed status, the expected INS error,
SPI gyro WHOAMI, parameter persistence across resets, repeated startup, and
a timed observation of diagnostic-loop stability. A successful diagnostic
check does not establish normal vehicle initialization or sensor health.

Hardware references and driver constraints are recorded in the
[AI-assisted Discovery research note](https://github.com/Mohameddewedar/ardupilot/blob/research/guidance-f429-discovery/docs/research/guidance-f429-discovery.md).
