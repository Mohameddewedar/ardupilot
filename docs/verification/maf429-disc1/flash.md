# Original MAF429 flash and restoration test

Date: 2026-11-06. AI-assisted execution following the user's explicit request
to flash the original image and add the result to the report.

## Result

**The original MAF429 bootloader/application pair was successfully programmed,
verified and run on the connected STM32F429I-DISC1.** Native USB enumerated
as MAF429 and carried application MAVLink identifying source `73097f11` and
board ID 1101. The application then remained in a barometer configuration
error loop. This confirms limited boot/USB compatibility of the original
F427-profile firmware on this F429; it does not demonstrate a functional
sensor-equipped autopilot.

The full original GuidancePilotF429 flash backup was then restored and verified
byte-for-byte before execution. Native USB returned as GuidancePilotF429.
The development branch and its source/build configuration were not changed.
Only the reports on `verification/maf429-disc1` are updated.

## Physical scope and inputs

The user confirmed that the external IMU, GPS and SD modules were disconnected,
including signal leads, with only the Discovery board's ST-Link and native USB
cables connected. This removes the previously identified external PE5 MISO /
relay-output conflict. Soldered Discovery LCD/SDRAM circuits were not modified.
No external sensor was moved onto the MAF429 SPI1 bus for this test.

The same original bootloader and ArduPlane BINs from [the build record](build.md)
were used without rebuilding, patching, changing board IDs, disabling sensor
requirements or suppressing safety checks. Their source is verification commit
`73097f11a7e5897c220d67262d0a68127decc4ee`.

| Item | Value |
| --- | --- |
| Fresh pre-flash backup | 2,097,152 bytes; SHA-256 `706a23334610428a4ab4094f53bedf0b74e7743f423a1becd8de705ab930afa3` |
| Backup validation | Bootloader sector and 1,315,580-byte application at 0x08010000 match the previously retained GuidancePilotF429 image. |
| MAF429 application address | 0x08004000 |
| Combined test image | 1,324,860 bytes; SHA-256 `f2ebc952460d086dd94645da3dd8258a7fbe2330492aa0227005167cdef993e7` |
| Composition | Original 15,756-byte loader at offset 0, 628 bytes of 0xFF padding, original 1,308,476-byte application at offset 0x4000. |
| Programming verification | OpenOCD verification passed; an independent SWD download of all 1,324,860 image bytes matched byte-for-byte. |
| Restoration verification | All 2,097,152 flash bytes matched the fresh backup; SHA-256 `706a23334610428a4ab4094f53bedf0b74e7743f423a1becd8de705ab930afa3`. |

Restoration verification was performed with the CPU halted, before the restored
firmware was allowed to run. It includes the parameter/diagnostic regions that
the 16 KiB MAF429 application layout overwrote. Subsequent autonomous firmware
statistics writes may change a later complete-flash hash.

## Debugger access and commands

OpenOCD 0.12.0 with `interface/stlink-dap.cfg` / `dapdirect_swd` works on this
STLINK V2J46M32. The earlier `interface/stlink.cfg` / `hla_swd` failure in
[the initial baseline](bench.md) was not a conclusive failure of the board.
The fresh SWD backup session read:

```text
DBGMCU_IDCODE=0x20016419
FLASH_KIB=0x800
CPUID=0x410fc241
```

The reported flash size is 2 MiB. Device ID 0x419 is shared across the relevant
F42x/F43x family; it alone does not distinguish F427 from F429. The physical
Discovery board identity provides that context. ST-Link reported approximately
2.86 V target voltage; this was not an independent supply measurement.

All command paths below are repository-relative. Artifacts are retained under
`.local/guidance-f429/maf429-verification/flash-test-20261106/`. The common
OpenOCD setup was:

```tcl
gdb_port disabled
tcl_port disabled
telnet_port disabled
source [find interface/stlink-dap.cfg]
source [find target/stm32f4x.cfg]
reset_config srst_only srst_nogate connect_assert_srst
init
```

The backup added `reset halt`, `dump_image` of 0x200000 bytes from 0x08000000,
`verify_image` of that backup, then `reset run` and `shutdown`. Input checks
required the complete file and matching known bootloader/application regions
before any erase or programming.

Programming used `reset init`, then:

```tcl
flash write_image erase .local/guidance-f429/maf429-verification/flash-test-20261106/original-combined.bin 0x08000000 bin
verify_image .local/guidance-f429/maf429-verification/flash-test-20261106/original-combined.bin 0x08000000 bin
dump_image .local/guidance-f429/maf429-verification/flash-test-20261106/program-original-readback.bin 0x08000000 1324860
reset run
shutdown
```

Restoration used the same sequence with `preflash-swd.bin` as input and a
2,097,152-byte download into `restore-guidance-readback.bin`. Both command
scripts exited zero and reached program/verification/readback completion.
The host independently compared each download to its input byte-for-byte.
No uploader `--force` or firmware board-ID override was used. The debugger
programmed the recorded pair directly at their matching link addresses.

The host launched each config from the repository root with:

```sh
source .local/guidance-f429/env.sh
LD_LIBRARY_PATH="$GUIDANCE_OPENOCD_ROOT/usr/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
  "$GUIDANCE_OPENOCD_ROOT/usr/bin/openocd" \
  -f .local/guidance-f429/maf429-verification/flash-test-20261106/program-original.cfg
```

`backup-swd.cfg` and `restore-guidance.cfg` are the corresponding retained
backup/restoration configs. They reset and program real hardware; these commands
are an execution record, not instructions to repeat without the matching
images, recovery backup and disconnected external wiring.

## Original-image runtime

The 75.06-second host capture began before programming, so its beginning also
contains a small amount of old GuidancePilot traffic. The MAF429 result below
is filtered to the app connection after 51.644 seconds; it excludes those
pre-programming messages.

| Check | Observed result |
| --- | --- |
| USB identity | 1209:5741, manufacturer/product MAF429; same MCU USB serial identity. |
| Version | ArduPlane V4.7.2 (`73097f11`), ChibiOS `d103983f`, board MAF429. AUTOPILOT_VERSION board field decodes to 1101. |
| Programming-to-app sequence | First MAF429 enumeration at host capture +46.61 s, disconnect at +51.26 s, new connection +51.64 s, first app heartbeat +52.25 s. This is consistent with bootloader-to-app USB re-enumeration; the bootloader protocol itself was not queried. |
| App heartbeats | 46 over 22.21 s between first/last heartbeat; all disarmed. Maximum arrival gap 0.816 s. No subsequent disconnect observed in this short interval. |
| Parameters | 876 of 876 received. INS_ACC_ID, INS_GYR_ID and BARO1_DEVID were zero. No parameter writes or persistence experiment were performed. |
| Blocking startup error | `Config Error: Baro: unable to initialise driver`, repeated approximately every five seconds. |
| Initialization extent | `RCOut: Initialising` was reported. No original-image `ArduPilot Ready` or successful barometer/IMU initialization was observed. |
| ST-Link VCP | Passive 57600-baud capture yielded one byte and no decodable MAVLink frames. This does not qualify the VCP link or prove it is broken; no active VCP handshake was attempted. |

The missing barometer is expected on this bare board: the archive requests a
BMP388 on SPI1. `libraries/AP_Baro/AP_Baro.cpp` calls
`AP_BoardConfig::config_error("Baro: unable to initialise driver")` if no driver
is initialized without the allow-no-baro option. `AP_BoardConfig::throw_error()`
repeats the error and services GCS traffic, explaining how USB/MAVLink can work
while normal startup has failed. The archive's required ICM20948 was also
absent, but this test does not claim execution reached every subsequent sensor
probe or normal estimator setup.

## Post-restoration observation

The 100.04-second restoration capture includes old MAF429 traffic before the
debugger halted it. Filtering to the new GuidancePilotF429 USB connection at
+73.015 seconds yields five disarmed heartbeats and version `8ce5ad27`, board
ID 5656. The latest startup messages were `Ground start` and
`Beginning INS calibration. Do not move plane`. The aggregate capture's
parameter dictionary mixes two firmwares and is not used to claim a complete
restored parameter set.

A separate 30-second passive capture after restoration received no decodable
frames on native USB or VCP, while the modules remained disconnected. It sent
no GCS heartbeat because the harness waits for an initial application heartbeat.
This observation does not establish a healthy restored runtime or diagnose
why telemetry stopped. Full flash restoration and the initial restored
version/identity are separately verified above. Reassembly confirmation was requested before qualifying recovery against the
original sensor-equipped baseline. The resulting check is recorded next.

The user then confirmed restoration of the original IMU/GPS/SD wiring. A
commanded debugger reset was performed to repeat sensor discovery; the
35-second reassembly capture includes that commanded USB disconnect. It is
not evidence of an uncommanded restart.

After that reset, a separate 30-second final recovery capture completed with:

- Version `8ce5ad27`, board ID 5656 and GuidancePilotF429 identity on both
  native USB and ST-Link VCP at 57600 baud.
- All 906 parameters received independently on both links. Final accelerometer
  ID 1442082 and gyro ID 2359586 match the pre-test baseline.
- 31 native and 35 VCP heartbeats, all disarmed, with no observed link
  disconnect. VCP can include buffered earlier messages, so these counts are
  received frames, not an accepted steady-state output frequency.
- Inertial samples streamed; the GPS was detected and communicating. A GPS
  fix was not established. `ArduPilot Ready` was received over VCP.
- The calibration, unhealthy compass, bad GPS fix, crash-dump and missing RC
  pre-arm messages remained. No checks were disabled or crash dump cleared.

The intermediate reassembly parameter snapshot had different IMU IDs:
accelerometer 1245474 and gyro 2162978. Those encode backend type bytes
0x13/0x21, rather than the baseline/final 0x16/0x24. The Invensense driver uses
0x13/0x21 for more than one MPU variant, so this is not a standalone physical
chip identification. The final capture after reset returned the original IDs
on both links. The reason for the intermediate change was not established;
no raw WHO_AM_I register was read in this follow-up. This transient remains a
hardware/startup observation for further review, not a claimed healthy sensor
acceptance result.

The final parameter comparison retained the same 906 names. Runtime/boot
counters and gyro calibration values changed across startup; the exact
before/after values are retained in `final-recovery-result.json`. The test did
not send parameter-set commands. Firmware's startup calibration and sensor
registration can update parameters after an exact flash restoration; this
record does not claim every runtime parameter remained numerically constant.

| Parameter | Earlier baseline | Final recovery |
| --- | ---: | ---: |
| `INS_GYR1_CALTEMP` | 27.63915443 | 29.29207993 |
| `INS_GYROFFS_X` | -0.008613754995 | -0.009049954824 |
| `INS_GYROFFS_Y` | -0.05531559139 | -0.05581762269 |
| `INS_GYROFFS_Z` | 0.01120424271 | 0.01105355285 |
| `STAT_BOOTCNT` | 22 | 32 |
| `STAT_RUNTIME` | 10800 | 12044 |

No inserted-card mount/write, sensor calibration acceptance or flight test
was performed after reconnection.

## Harness failure and bounded claims

A fresh pre-flash MAVLink baseline attempt lost its serial connection and
exited 1 before completing parameters or a new MAVFTP backup. Its exception
and partial messages are retained. The cause was not established. The flash
operation was gated instead by the subsequent successful full SWD backup and
verification; no incomplete download was used for restoration.

`observe_ports.py` monitored native USB and ST-Link VCP, reopened native USB
across enumeration, saved raw bytes and parsed MAVLink, and requested version
and parameters only after an application heartbeat. The script passed Python
compilation and the completed original-image capture exited zero. No
parameter-set, arming, servo-command or SD-write messages were sent. Firmware
could initialize its declared GPIO/PWM/tone outputs; their waveforms were not
measured and no actuators were attached or exercised.

The positive result is original-image programming, native USB and diagnostic
execution. Sensor health, usable control outputs, persistent storage, normal
vehicle initialization, flight operation and long-term stability remain
unqualified. The [software findings](compatibility.md) and [physical pin audit](hardware.md)
continue to apply.

## Evidence

The ignored run directory retains `prepared-inputs.json`, `flash-inputs.json`,
`preflash-swd.bin`, `original-combined.bin`, both programming/readback configs
and logs, both readback BINs, `program-readback-result.json`,
`restore-readback-result.json`, USB descriptors, raw serial captures, parsed
messages, parameter snapshots and `maf429-result.json`. Complete flash and
parameter files remain private local artifacts. The Markdown report contains
the portable outcomes and hashes.
