# Connected STM32 bench observations

Date: 2026-11-06. AI-assisted execution. The firmware observed on hardware was
the **installed GuidancePilotF429**, never the archived MAF429 firmware.
All raw filenames below are relative to ignored
`.local/guidance-f429/maf429-verification/`.

## Access and preservation

USB enumeration found `1209:5741 GuidancePilotF429` and
`0483:3752 ST-LINK/V2.1`. An Arduino and another unrelated ACM device were
also present; the observation script selected the GuidancePilot USB identity
explicitly rather than assuming an ACM number. It opened the serial port with
exclusive access and closed it after testing.

The script requested MAVLink version information, telemetry streams, parameter
readback and MAVFTP downloads. It sent no parameter-set, arming, actuator,
upload, erase or reboot commands. Firmware can still update its own runtime
statistics: `STAT_RUNTIME` advanced between parameter snapshots.

The first capture successfully read all 2,097,152 bytes of `@SYS/flash.bin`.
Its SHA-256 is
`e5581f7f42e8c5b599de245892e3f7f4023738d2496ae804b7e00628ae0ebcd1`.
The complete current snapshot is retained as `installed-full-flash.bin`.
Against the previous retained 2026-11-05 snapshot:

- The first 16 KiB bootloader sector matched byte-for-byte.
- All 1,315,580 bytes of the installed application at `0x08010000` matched.
- Its application SHA-256 remains
  `87dbddc18a862ad49184364b2ac53179144c6a9b9e11af08df815f0aec08d2d7`.

The full flash hash is not expected to equal an old full flash hash when
parameter/statistics or diagnostic storage changes. The application/bootloader
comparisons above use the specific immutable regions, not that assumption.

## SWD attempt

The existing local OpenOCD 0.12.0 installation was used for identification:

```sh
source .local/guidance-f429/env.sh
LD_LIBRARY_PATH="$GUIDANCE_OPENOCD_ROOT/usr/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
  "$GUIDANCE_OPENOCD_ROOT/usr/bin/openocd" \
  -f interface/stlink.cfg -f target/stm32f4x.cfg \
  -c 'gdb_port disabled; tcl_port disabled; telnet_port disabled; init; mdw 0xE0042000 1; mdh 0x1FFF7A22 1; mdw 0xE000ED00 1; shutdown'
```

OpenOCD identified STLINK V2J46M32, reported target voltage 2.858207 V, and
exited 1 with `init mode failed (unable to connect to the target)`.
Initialization failed before the requested ID, flash-size and CPU register
reads; no register identity was obtained. No halt/reset/programming command was
requested, and no connection-under-reset retry was made. The voltage is an
ST-Link report, not a validated multimeter rail measurement. This failed
attempt does not establish an MCU or board failure. The log is
`board-identify-openocd.log`.

## MAVLink observations

The initial host capture lasted 41.15 seconds and observed 46 disarmed
heartbeats, including the flash download. Its maximum heartbeat arrival gap
was 1.019 seconds. A second capture completed successfully over 35.13 seconds,
with 36 disarmed heartbeats and a maximum gap of 1.001 seconds. Buffered
telemetry may precede a host capture; these durations are host observation
times, not accepted reboot-to-ready times.

| Item | Observed result |
| --- | --- |
| Version | ArduPlane V4.7.2, source banner `8ce5ad27`, ChibiOS `d103983f`, board identity GuidancePilotF429. |
| Parameters | 906 of 906 entries received in both snapshots. Same names and values except automatic `STAT_RUNTIME` advance from 10676 to 10800. No parameter persistence write test was performed. |
| IMU telemetry | Acceleration and gyro fields streamed; example z acceleration −807 mg, temperature 28.65 °C. This does not establish calibration, axes or sensor health. |
| GPS | Fix type 1, zero visible satellites; no navigation fix demonstrated. |
| Pressure | Zero absolute pressure in the received message. No working barometer demonstrated. |
| USB UART diagnostics | Both snapshots show FE/OE/NE counters zero for SERIAL0. |
| GPS UART5 diagnostics | Both snapshots show FE=1733, OE=0, NE=167. These are nonzero historical counters with no increase between these two snapshots. First RXDRP=1375, second RXDRP=0; RXDRP is an interval statistic, not a cumulative total to subtract. |
| Reboot evidence | Received SYSTEM_TIME values were nondecreasing. No unexpected restart was observed in the captures; cold startup was not tested. |

Retained status messages include:

```text
PreArm: 3D Accel calibration needed
PreArm: Compass 1 not healthy
PreArm: CrashDump data detected
PreArm: GPS 1: Bad fix
PreArm: Waiting for RC
```

The first capture also received `ArduPilot Ready`, no barometer and airspeed
initialization messages. Ready text does not cancel the pre-arm errors.
The origin and age of the crash dump were not determined; it was neither
cleared nor attributed to MAF429, which was not installed. This investigation
does not certify the installed GuidancePilotF429 image as healthy.

## Harness correction and evidence

The first script run completed its downloads and saved the summary/parameter
files, then exited 1 while serializing a MAVLink `bytearray` into the raw
message JSON. That was a host-script error, not an MCU exception. The failed
run's summary/log/parameters/UART file are preserved with the `first-installed-`
prefix. The complete flash download also survives that error.

The serializer was corrected to handle bytes, and serial closure was placed
in a nested `finally`. A second run with `--skip-flash` exited zero, preserving
raw `installed-messages.json` and `installed-observation.json`. Its parameter
snapshot is `installed-parameters.json`. `observe_installed.py` is retained
locally and passes Python compilation. Flake8 was unavailable in that local
environment; no Python source was added to the tracked firmware tree.

To repeat the same bounded capture on this workstation, with the board and
environment still connected:

```sh
source .local/guidance-f429/env.sh
python .local/guidance-f429/maf429-verification/observe_installed.py --skip-flash
```

Rerunning overwrites the script's standard output files; preserve them in a
new evidence directory first. The script defaults to a full flash readback
when `--skip-flash` is omitted.

## Why the archive was not flashed

The archive would drive existing PE5 IMU-MISO wiring as a low relay output,
use PE2 as chip select instead of the current SPI4 clock, and hold the current
SD chip-select PE4 low as another relay output. Its sensors, serial layout,
board identity and application offset also differ. A flash test on this wired
assembly would not be a valid test of the hypothetical original assembly.
The source/build evidence already establishes those mismatches.

No corrected firmware was substituted and then called an original-hwdef test.
Original-image USB enumeration, startup, sensor probing and parameter behavior
remain unmeasured. The [compatibility report](compatibility.md) explains what
source inspection establishes without that test. No arming, outputs, physical
rewiring, SD writes, calibration, flight or cold power-cycle testing occurred.
