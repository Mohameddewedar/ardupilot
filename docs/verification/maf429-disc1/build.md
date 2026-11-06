# MAF429 original build verification

Date: 2026-11-06. AI-assisted execution; no hwdef edits or compiler-warning
suppression were used. Source is the exact imported archive on commit
`73097f11a7e5897c220d67262d0a68127decc4ee`, based on
`fe0b0e8f903ac983109340dffa8aa44c10380c5b`.

## Inputs

The source ZIP is `MAF429.zip`, supplied from the user's Downloads directory.
It contains only a directory entry and the two hwdef files.

| Input | Bytes | SHA-256 |
| --- | ---: | --- |
| ZIP | 3097 | `6fb91367ecdc484681323f4b476b47762774b90253503f741b98a882b516ce9e` |
| `hwdef.dat` | 3911 | `897b14ccb5f162e1db8eeb8e0f95fac5ef745381555d6b29b4b006085ecf967d` |
| `hwdef-bl.dat` | 1519 | `dbe815dea1d7fa6a0c23f1841494f1544527b7bf64b2f6e55373d3c25095f735` |

A direct ZIP-entry comparison passed again after building. Extracted files
were preserved exactly, including original comments, whitespace and repeated
declarations. There are no experiment variants to confuse with the originals.

## Toolchain and commands

- GNU Arm Embedded GCC 10.2.1, 2020-q4-major.
- Python 3.14.4.
- ChibiOS `d103983f4362e5506bcf7062ccacf345fc0c0859`.
- Waf configuration enables `-Werror`; no submodule update or edit was made.

From the repository root, the existing ignored environment file locates the
host toolchain. `TEST_ROOT` below is task-owned build output. Preserve a
pre-existing `Tools/bootloaders/MAF429_bl.bin` if reproducing in another checkout;
none existed for this run.

```sh
source .local/guidance-f429/env.sh
TEST_ROOT="$PWD/.local/guidance-f429/maf429-verification"

./waf configure --board MAF429 --bootloader --no-submodule-update \
  --python "$GUIDANCE_VENV/bin/python" --out "$TEST_ROOT/build/original-bootloader"
./waf bootloader -j4

# Generated prerequisite for embedding; this is not copied from another board.
cp "$TEST_ROOT/build/original-bootloader/MAF429/bin/AP_Bootloader.bin" \
  Tools/bootloaders/MAF429_bl.bin

./waf configure --board MAF429 --no-submodule-update \
  --python "$GUIDANCE_VENV/bin/python" --out "$TEST_ROOT/build/original-plane"
./waf plane -j4
```

Before generating the prerequisite, the first application configure exited 1:

```text
Error: Bootloader (./Tools/bootloaders/MAF429_bl.bin) does not exist and AP_BOOTLOADER_FLASHING_ENABLED
Please run: Tools/scripts/build_bootloaders.py MAF429
```

This is an incomplete build-input set, not evidence that the hwdef syntax or
MCU profile cannot compile. Building the supplied bootloader and temporarily
placing its BIN at the expected path allowed the unmodified application
configure to pass. The temporary copy is removed after verification; the
original generated BIN and hashes remain under the ignored evidence directory.

## Measured results

Both configurations and both build commands subsequently exited zero.

| Target | Text | Data | BSS | Waf flash used | Free flash |
| --- | ---: | ---: | ---: | ---: | ---: |
| Bootloader | 15,680 | 76 | 12,392 | 15,756 | 628 |
| ArduPlane | 1,304,192 | 4,272 | 69,908 | 1,308,464 | 772,292 |

The Waf section-size total and the final padded BIN byte count are different
metrics; the BIN count below identifies the actual file tested.

The bootloader reserves 16 KiB and the app is linked at `0x08004000`.
The initial stack pointer is `0x20000600` for both; the reset vectors are
`0x080001e1` for the loader and `0x080052d5` for the application. Generated APJ
metadata reports board ID 1101, MCU STM32F427xx and USB `0x1209/0x5741`.
The app log includes `No APP_DESCRIPTOR found` but completes successfully.

## Image hashes

| Product | Bytes | SHA-256 |
| --- | ---: | --- |
| `AP_Bootloader.bin` | 15,756 | `835cf4d148366fd52bdfb37f68d254b011ba09e85f92adeb95eb325c6ffda340` |
| `arduplane.bin` | 1,308,476 | `feb27793602e0fa9d3b6ed21617f4f5893eddae29abb868a3aebfff9fe57b6e9` |
| `arduplane.apj` | 1,162,518 | `8b02751c31c349670f06f78a6ec441bd51bf21e9117d91d792324016c8bd826d` |
| `arduplane_with_bl.hex` | 3,643,716 | `b33779875a7e9de93887b3020e0fee237a457ccb588e4cc0ae1bb5022110df51` |

These identify this run, not an assertion of reproducible binary hashes across
commits or toolchains. No original MAF429 image was uploaded or run on the
connected board. [Bench evidence](bench.md) is explicitly for its installed
GuidancePilotF429 firmware.

## Retained evidence and test scope

Under `.local/guidance-f429/maf429-verification/`:

- `input-manifest.json`, `build-and-test-manifest.json` and `profile-comparison.json`.
- `configure-original-plane.log` (initial missing-input failure),
  `configure-original-bootloader.log`, `build-original-bootloader.log`,
  `configure-original-plane-with-bootloader.log`, `build-original-plane.log`.
- The two separate `build/original-*` output directories, including generated
  headers, linker scripts, binaries, ELF files and APJ metadata.

The appropriate firmware checks for these board-only imports were the actual
bootloader and target application builds plus generated GPIO/peripheral review.
No flight, actuator, SITL or C++ unit-test success is claimed. The configured
STM32 target does not support the repository's GTest unit-test build.
