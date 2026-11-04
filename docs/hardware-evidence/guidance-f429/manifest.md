# GuidancePilotF429 hardware photo evidence

The user supplied these five original JPEG files on 2026-11-04 for
[GuidancePilotF429: identify breakout variants and mounting orientation](https://github.com/Mohameddewedar/ardupilot/issues/9),
under the parent map
[GuidancePilotF429: integrate external IMU, GPS and microSD for bench use](https://github.com/Mohameddewedar/ardupilot/issues/6).
Electrical requirements are tracked separately in
[GuidancePilotF429: establish sensor and storage electrical requirements](https://github.com/Mohameddewedar/ardupilot/issues/8).

The original filenames and image bytes are preserved. These files have not
been cropped, rotated, resized, recompressed or otherwise edited. SHA-256
values below identify the uploaded originals; sizes are in bytes.

| Original file | View | Size | SHA-256 |
| --- | --- | ---: | --- |
| [IMG_20261104_142304.jpg](IMG_20261104_142304.jpg) | microSD carrier, socket side | 6248149 | `eb817a0ef01fcdb2de073aeed68b838ff87523cdac4cb1cc397983ba1bec978e` |
| [IMG_20261104_142427.jpg](IMG_20261104_142427.jpg) | IMU carrier, component side | 6048322 | `e51305cac6fd58d0cd88dd95bc7bb560ab2d23a0aa399d9abe6b6049e56c9028` |
| [IMG_20261104_142456.jpg](IMG_20261104_142456.jpg) | IMU carrier, reverse side | 6183375 | `5d902b7854e910bbc5016f03d309ddbaff243a4d2e75b849a4b4f9a83cb42af2` |
| [IMG_20261104_142539.jpg](IMG_20261104_142539.jpg) | GPS carrier, receiver-module side | 5526286 | `73812c0d3a6e98a719d9f48475495104b67b1ec846188297aa5fa456963d1cef` |
| [IMG_20261104_142603.jpg](IMG_20261104_142603.jpg) | GPS carrier, reverse/component side | 6271636 | `53445db8b51d58a338fef972bbaf4f876d9c5d4f5af55bd8ddad6843df73d140` |

Visible photo evidence:

- The microSD carrier shows `Micro SD Board V1.02`, separate SPI/SDIO
  signal labels and `3.3V` supply labels. Only its socket side is supplied.
- The IMU component side shows `MPU-9250/6500` and an axis symbol. Its
  reverse side shows both `GY-6500` and `GY-9250`, with interface labels
  including `SCL/SCLK`, `SDA/SDI`, `AD0/SDO` and `NCS`.
- The GPS receiver-module label reads `NEO-7N-0-002`; the carrier shows
  `V1.0` on that side. The reverse side shows `GPS MINI` and header labels
  `PPS RXD TXD GND VCC`, plus SMA and IPEX antenna connectors.

The photos do not establish hidden circuitry, carrier regulator identity
or supported input voltage, measured rail voltage, IMU WHOAMI or compass
identity, signal-level compatibility, continuity, or final mounting
orientation relative to the Discovery board. Shared IMU carrier labels do
not select MPU6500 versus MPU9250. An axis symbol alone does not select an
ArduPilot rotation. These remaining checks keep the identity and mounting
ticket open. No powered test, wiring approval or firmware validation is
claimed by this evidence upload.

The user provided the photos and authorized publication to the related
issue. File preservation, visual captions, manifest preparation and upload
were AI-assisted.
