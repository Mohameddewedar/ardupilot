# GuidancePilotF429: downloaded power datasheets

Researched on 2026-11-05 with AI assistance for
[GuidancePilotF429: settle exact wiring and power plan](https://github.com/Mohameddewedar/ardupilot/issues/10).
This follows the [original carrier photos](https://github.com/Mohameddewedar/ardupilot/issues/9#issuecomment-6631004377).
No wiring or powered measurement was performed. Component limits below are
operating limits, not instructions to apply that voltage to an unidentified
carrier input.

## Power result

**Recommended carrier inputs:** regulated external 3.3 V to IMU 1 VCC and
GPS 5 VCC; regulated external 5 V to replacement HW-125 SD 5 VCC. Both supply
returns join Discovery GND and carrier grounds; Discovery retains separate
USB power. The old ten-contact Micro SD Board V1.02 is retired. See the
[current wiring guide](../../libraries/AP_HAL_ChibiOS/hwdef/GuidancePilotF429/expansion-wiring.md)
and [HW-125 research](guidance-f429-hw125-reader.md).

The earlier blanket 3.3 V policy has been withdrawn. The IMU/GPS recommendation
limits input voltage to a range compatible with their chip/module supplies;
it avoids applying 5 V to carriers whose input protection/regulator ratings
have not been established. An onboard LDO can still reduce their internal
rail enough to prevent operation. Measure the actual rails against their
operating limits before accepting the assembly; no successful powered result
or verified carrier rating is claimed.

| Part | Published supply requirement | Meaning for this assembly |
| --- | --- | --- |
| MPU9250 chip | VDD 2.4–3.6 V; VDDIO 1.71 V through VDD | Nominal 3.3 V can supply both chip rails. A carrier regulator can require a higher VCC input. |
| MPU6500 chip | VDD and VDDIO 1.71–3.45 V in the detailed DC table | Nominal 3.3 V fits the table; include regulator tolerance and transients. |
| u-blox NEO-7N reference module | VCC 2.7–3.6 V; normal digital input range 0–VCC | Nominal 3.3 V fits the module specification. Use 3.3 V at GPS MINI VCC as the conservative input recommendation; validate its downstream rail. |
| Conventional microSD card | Supply 2.7–3.6 V; 3.3 V nominal | This is the card's internal rail, not the replacement HW-125 VCC input. The carrier regulator supplies it. |
| Replacement HW-125 carrier | Indexed supplier input 4.5–5 V; onboard regulator and buffer | Recommend regulated external 5 V at its VCC header only, then verify its internal nominal 3.3 V rail. See the separate HW-125 note for source applicability and tolerances. |
| Possible RT9193-33 regulator | 3.3 V output variant; family VIN operating range 2.5–5.5 V, subject to output headroom and thermal limits | A verified carrier using this part can accept a higher input such as 5 V and supply a 3.3 V chip rail. This does not identify the actual fitted regulator. |

The 5 V reader recommendation applies to the carrier's regulator input,
not the bare card or SPI signals. The 3.3 V recommendations for IMU/GPS do
not establish their internal LDO outputs; those remain a bring-up measurement.

## Evidence from each datasheet

### IMU chips and comparison carrier

[TDK MPU9250 product specification rev 1.1](https://www.invensense.tdk.com/en-us/download-resource/ps-mpu-9250a-01-mpu-9250-datasheet),
section 3.4.1, Table 3, printed page 11, gives the MPU9250 ranges above.
Section 4.23, printed page 28, also requires VDDIO not to exceed VDD during
power-up or operation. VDDIO sets the signal reference; a regulator on VCC
does not make the sensor signals 5 V tolerant.

[TDK MPU6500 product specification rev 1.3](https://www.invensense.tdk.com/en-us/download-resource/ps-mpu-6500a-01-mpu-6500-datasheet),
section 3.3.1, Table 3, printed page 9, specifies 1.71–3.45 V for both rails.
Its overview on page 5 instead says 1.71–3.6 V. Use the tighter table limit
until TDK clarifies that discrepancy. The page 16 absolute maximum of 4 V
is a stress limit and must not replace the operating limit. The SPI input
thresholds on page 10 refer to VDDIO.

[Haoyu's GY-9250 product page](https://www.hotmcu.com/9dof-imu-module-with-mpu9250-p-172.html?cPath=8)
specifies a **3–5 V carrier supply**. Its linked
[carrier schematic](https://www.haoyuelectronics.com/Attachment/GY-9250/9250-sch.jpg)
shows header VCC feeding a 3.3 V LDO, whose output supplies the chip rails.
The published carrier photos have the same ten-contact sequence and a similar
component layout, but different `MPU-92/65` silkscreen. This is a useful
comparison, not a proven manufacturer/revision match to the user's board.
The schematic does not give the regulator part number, so its input range
cannot be transferred to every GY-labelled board.

### GPS receiver and GPS MINI carrier

[u-blox NEO-7 datasheet UBX-13003830 R07](https://content.u-blox.com/sites/default/files/products/documents/NEO-7_DataSheet_(UBX-13003830).pdf)
lists type NEO-7N-0-002 in its applicability table. Table 8, printed page 16,
gives 2.7–3.6 V VCC and digital input limits of 0–VCC. Table 9, page 17,
lists 67 mA for receiver supply dimensioning; carrier and antenna loads need
separate allowance. Backup supply V_BCKP is 1.4–3.6 V and is not interchangeable
with the main input. The downloaded
[MAX-7/NEO-7 hardware integration manual R10](https://content.u-blox.com/sites/default/files/products/documents/MAX7-NEO7_HardwareIntegrationManual_%28UBX-13003704%29.pdf)
covers the supply and antenna circuits.

The actual photo's receiver can says `WAAAX` and `waaaxAG`, alongside
`NEO-7N-0-002`; it does not show the u-blox branding used in this datasheet.
No primary electrical specification for that specific WAAAX module or the
GPS MINI V1.0 carrier was established. The u-blox limits are therefore a
reference for the named type, not proof of the photographed module's origin
or electrical equivalence. No authenticity conclusion is made from a photo.

### SD supply

The SD Association's [Physical Layer Simplified Specification v6.00](https://academy.cba.mit.edu/classes/networking_communications/SD/SD.pdf),
section 3.2, printed page 5, gives the conventional 2.7–3.6 V supply range.
This is an SD Association-authored 2017 reference downloaded from an MIT
teaching-site mirror, not a claim to have downloaded the latest specification
from the Association. [Kingston's SDCIT2 datasheet](https://www.kingston.com/datasheets/sdcit2_en.pdf)
independently lists 3.3 V. That card is a reference example, not the user's
unidentified card. Low-voltage signaling modes do not justify supplying this
SPI assembly or the HW-125 VCC input with 1.8 V.

The original Micro SD Board V1.02 had ten contacts and two 3.3V labels.
It has been replaced by the photographed six-contact HW-125 with a regulator
marked `1117` and U1 marked `74LVC125`. Both sides of the replacement are
available. The [HW-125 note](guidance-f429-hw125-reader.md) records the input
recommendation, evidence limits and MISO buffer behavior. Card write-current
peaks and actual loaded rails remain unmeasured.

## IMU/GPS regulator evidence and the 3.3 V recommendation

Magnified views of the user's IMU and GPS photos show five-pin regulator-like
packages, with markings that appear consistent with a `DE` prefix. The full
marking is not established well enough to identify either fitted part.
The manufacturer-authored
[Richtek marking guide MI-090424, page C-30](https://www.recomb-omsk.ru/published/SC/html/scripts/doc/Richtek_Marking_Code.pdf)
maps `DE=` to RT9193-33GB and `DE-` to RT9193-33PB. This archived manufacturer
document was downloaded from a mirror; the current datasheet directs users
to Richtek for marking information.

The official [RT9193 datasheet DS9193-18](https://www.richtek.com/assets/product_file/RT9193/DS9193-18.pdf),
pages 2–3, gives SOT-23-5 pins 1 VIN, 2 GND, 3 EN, 4 BP, 5 VOUT. Recommended
VIN is 2.5–5.5 V. Its 6 V absolute maximum is not an operating target.
At 300 mA, dropout is 220 mV typical and 300 mV maximum under the stated
test conditions. Thus a 3.3 V regulator cannot be assumed to produce a
regulated 3.3 V output from a 3.3 V input. This remains relevant to the selected
3.3 V carrier input: measure the actual downstream supply and check its
operating range rather than assuming that a nominal 3.3 V LDO produces 3.3 V.
The regulator's wider input range is background evidence, not a selected
alternative supply for this assembly.

The smallest remaining physical check is specific:

1. Read the complete regulator marking and check its package pin orientation.
2. With all power removed, confirm carrier VCC reaches regulator VIN, GND
   reaches regulator GND, and regulator VOUT reaches the component supply.
   Check for a regulator bypass link or direct connection to VCC.
3. With the recommended 3.3 V input, check the actual output against
   the fitted chip's operating range with signals disconnected before
   connecting it to the Discovery. Include the actual loaded STM32 rail in
   the later logic-compatibility check.

These checks validate operation during bring-up; no loaded measurements
have been performed. If the recommended input does not produce valid chip rails,
stop the powered test and revise the power plan using the actual carrier
circuit. Do not substitute 5 V based on the regulator comparison alone.

## Download archive and validation

Actual downloaded PDFs are retained in the ignored local archive at
`.local/guidance-f429/expansion/datasheets/`, relative to the repository root. Its
`manifest.json` and `manifest.md` record source URLs, filenames, sizes,
page counts and SHA-256 hashes. The companion `guidance-f429-datasheets.zip`
contains eleven PDFs, supplier comparison schematic/photos, both research
notes and the manifest. Third-party PDFs are retained locally, not
added to the source repository or reposted to GitHub. The board's
[development layout](../../libraries/AP_HAL_ChibiOS/hwdef/GuidancePilotF429/development.md)
documents the retention and Git policy.

Older TDK PDF links redirected to HTML or returned access errors. The actual
rev 1.3/rev 1.1 files were retrieved through TDK's current public download
resource metadata and its linked CDN. The MPU9250 official file matches the
Mikroe mirror byte for byte. Validation included PDF signatures, `pdfinfo`,
text extraction, hashes and visual inspection of the IMU, GPS and regulator
voltage tables. No compilation, upload, power connection or voltage
measurement is claimed.
