# GuidancePilotF429: six-pin HW-125 microSD carrier

AI-assisted research on 2026-11-05 supporting
[GuidancePilotF429: identify breakout variants and mounting orientation](https://github.com/Mohameddewedar/ardupilot/issues/9)
and the existing wiring work. No hardware was connected, powered or measured.
This note concerns the replacement six-pin carrier only. The previous ten-pin
Micro SD Board V1.02 and its labelled 3.3V contacts are a different assembly.

## Decision for the replacement

Plan for **regulated external 5 V at this carrier's VCC input, with 3.3 V SPI
signals and common ground**, subject to confirming that VCC feeds regulator
VIN and that its output supplies the card and logic at approximately 3.3 V.
The previous reader's direct-3.3V power plan is retired.
Do not apply 5 V to the SPI signals, card supply or Discovery 3.3V rail.

**Retain SPI5 for the present profile, where SD is its only actively selected
slave.** The onboard gyro and LCD are physically attached to that peripheral,
but the profile probes only the external SPI4 IMU and holds the onboard
devices' CS high. Verify those inactive levels through reset and operation.
An always-enabled SD MISO buffer can work in this restricted arrangement,
provided the other devices release their outputs while deselected.

The photos and model name do not establish whether this carrier releases MISO
when CS is high. A documented comparison board does not. Before enabling
another active SPI5 slave, resolve that routing: if SD drives MISO continuously,
use a verified carrier with correct release, or a separate, otherwise unused
SPI bus after a pin-allocation review. Moving it to the external IMU's SPI4
bus would retain the contention problem. Software chip selection alone cannot
disable a reader buffer whose enable is hardwired low.

## What the actual photographs establish

Inspected the user's original photographs with the image viewer:

- Back: `1793874191605.jpg`.
- Front: `1793874191660.jpg`.

The front has blue PCB, `HW-125` silkscreen, microSD socket on the left,
six-pin header on the right, a 14-pin U1 and a three-lead regulator with a
large tab. U1 reads **`74LVC125`**; the lower line appears to be **`HPEC514`**
but is not a reliable manufacturer identification. No `A` suffix is clearly
visible. The regulator reads **`1117`**, with a lower marking that appears
consistent with **`33`** followed by a production code (possibly `GN053`).
That supports an 1117-family 3.3V regulator hypothesis; it does not establish
AMS1117, LM1117, LD1117 or the actual manufacturer's electrical guarantees.
The four resistors are marked `332`, consistent with 3.3 kΩ; their routing
must not be inferred from that value alone.

With the **back facing the viewer and header on the left**, the labelled
contacts are, top to bottom:

| Local contact label | Printed signal | Proposed connection for present SPI5 profile |
| --- | --- | --- |
| SD 1 | CS | PE4, Discovery P1-13 |
| SD 2 | SCK | PF7 / SPI5_SCK, P2-6 |
| SD 3 | MOSI | PF9 / SPI5_MOSI, P2-8 |
| SD 4 | MISO | PF8 / SPI5_MISO, P2-5 |
| SD 5 | VCC | External regulated 5 V input; validate internal rail before signals |
| SD 6 | GND | Common external-supply and Discovery ground |

These SD numbers are local documentation labels, not claimed manufacturer
pin numbers. Front-side viewing mirrors the left/right arrangement; the
labelled back-side orientation is the reference. There is no separate 3.3V
or card-detect contact on this header. MCU assignments come from the existing
[wiring guide](../../libraries/AP_HAL_ChibiOS/hwdef/GuidancePilotF429/expansion-wiring.md)
and [hwdef](../../libraries/AP_HAL_ChibiOS/hwdef/GuidancePilotF429/hwdef.dat),
which now describe this replacement carrier.

## Primary sources and their applicability

### HW-125 product listing: input voltage evidence, incomplete revision match

Shenzhen Hongweiwei Electronics' own
[HW-125 product page](https://www.szhwmake.com/prod_view.aspx?FId=t3%3A74%3A3&Id=335&TypeId=74)
lists input voltage **4.5–5 V** and input current **0.2–200 mA**. Its
[product-category listing](https://www.szhwmake.com/products.aspx?FId=t3%3A10%3A3&TypeId=10&pageindex=22)
repeats these numbers. This is primary vendor evidence for a product sold
under the same model name, not proof of the user's board manufacturer,
revision, fitted silicon or hidden routing. The indexed text was accessible
through web search; direct page retrieval timed out or failed certificate
validation, so no vendor photos or full HTML were archived or compared.
Do not silently expand this source's upper limit to 5.5 V.

### Vendor schematic: a concrete example of the MISO problem

The [Sunrom 5066 module document](https://www.sunrom.com/download/481.pdf)
is a first-party comparison, downloaded and visually inspected. Page 1
shows VCC feeding a 3.3V regulator, with the regulated rail supplying card
VDD and buffer pin 14. Card DO goes through R4 to U1D pin 12; output pin 11
goes to header MISO. **Its active-low enable pin 13 is tied to GND.** Header
CS goes through a separate buffer and does not disable that MISO output.
Page 2 specifies 5 V VCC and 3.3–5 V interfacing. It names **74VHC125**,
whereas the actual photo reads **74LVC125**. Its schematic/layout resemblance
is useful evidence of a possible circuit, not a circuit match to this HW-125.

### Logic reference: a buffer only tristates when its enable permits it

[TI SN74LVC125A datasheet SCAS290T](https://www.ti.com/lit/ds/symlink/sn74lvc125a.pdf),
pages 3, 5 and 9, gives the following **comparison-part** facts:

- Operating VCC is 1.65–3.6 V in the recommended operating table; a 5 V
  tolerant input does not mean a 5 V supply is valid.
- At VCC 2.7–3.6 V, VIH is at least 2.0 V and VIL at most 0.8 V;
  inputs accept up to 5.5 V, outputs operate between ground and VCC.
- Each channel has a separate active-low output enable. Enable low drives
  the input state; enable high makes the output high impedance.
- Standard 14-pin layout: VCC 14, GND 7; enables 1/4/10/13;
  respective input/output pairs 2→3, 5→6, 9→8, 12→11.

These explain why 3.3V host logic can suit a 3.3V-powered LVC buffer, subject
to the actual fitted part and wiring. They do not identify U1 as a TI part.
The functional implication is that card deselection alone cannot prove
carrier MISO release: an enabled push-pull buffer can drive its shared output
even when its card-side input is floating. A series resistor does not create
high impedance at that output.

### Regulator reference: 3.3 V into an 1117 is not regulated 3.3 V out

[TI LM1117 datasheet SNOS412Q](https://www.ti.com/lit/ds/symlink/lm1117.pdf)
is a manufacturer-authored comparison, not identification of the fitted part.
Page 6 gives LM1117 dropout maxima at 25°C of 1.1 V at 100 mA, 1.15 V at
500 mA and 1.2 V at 800 mA; temperature-range maxima are higher. Its fixed
3.3V output table uses VIN 4.75–10 V for the stated regulation conditions.
Thus a 3.3V input offers no regulation headroom for a 3.3V 1117 output.
Do not treat the 1.1 V dropout figure as a constant subtraction predicting
the actual carrier rail under every load. The output must be checked with
the actual card and supply; startup/no-load success does not prove write-load
margin. The table's wider input range is not a carrier input specification.

## Concrete remaining checks and power plan

1. With all supplies removed, identify the regulator package orientation and
   confirm SD VCC reaches VIN, GND reaches regulator ground, and VOUT reaches
   card VDD and U1 pin 14. Check for a bypass or direct VCC route. Do not
   assume a generic 1117 pinout before establishing the fitted device.
2. Use a separate regulated 5V-class external supply for this carrier input,
   accounting for its actual tolerance and wire drop. To stay within both
   the indexed vendor range and the LM1117 comparison's regulation test
   range, a controlled bench target around 4.9 V with 4.8–5.0 V measured at
   the carrier is a conservative bring-up choice. Verify the regulator/card
   rail near 3.3 V before connecting MCU signals. Use source capacity beyond
   the vendor's 200 mA figure and verify the actual card's load behavior;
   that figure is not a measured maximum for the user's card.
3. Map header MISO to U1's output and card DO to its input. Find that channel's
   enable. If the usual fourth channel is used, inspect pin 13; do not assume
   the channel number. A ground connection implies continuously enabled
   output. A connection to CS could permit release; verify its behavior
   including reset and power sequencing. Direct card-to-header MISO is
   another possible circuit requiring its own verification.
4. Establish MISO high impedance with CS high before enabling another active
   slave on the same bus. A static
   high voltage is insufficient evidence because an actively driven high
   looks the same on a meter. Appropriate controlled weak-pull measurements
   or instrumented bus tests can distinguish release; avoid driving one
   output against another as a test. Keep reset-time CS defined high.
5. Retain the SPI5 mapping above for the current SD-only active use after
   validating logic levels and the gyro/LCD's inactive CS states. If another
   SPI5 device will be actively used and the reader buffer remains enabled,
   the simplest robust options are a suitable replacement carrier or a
   separate SPI peripheral without another active slave MISO. An engineer
   can instead redesign gating around CS, but this note does not authorize
   a trace-cut modification.

The recommended IMU/GPS inputs remain 3.3 V; their actual internal rails
require validation. This note recommends 5 V specifically for HW-125 VCC. External 5 V for SD must not be joined to the
Discovery USB 5V rail without a separately established power-path plan.

## Local evidence retained and validation

Downloaded source PDFs and rendered/extracted inspection artifacts are in
`.local/guidance-f429/expansion/datasheets/hw125/`, inside the workspace.
`manifest.json` records original URLs, sizes, PDF page counts and SHA-256
hashes. The Sunrom schematic and TI electrical tables were inspected;
downloaded PDF signatures/page counts were checked. Direct AMS1117 and ST
LD1117 downloads were attempted but failed; no downloaded copy of either
is claimed. The usable TI LM1117 reference is explicitly a comparison.

Validation is documentary and visual only. No board continuity, operating
voltages, MISO release, compile, flash or SD write test was performed. There
is no exact HW-125 schematic match in the established evidence.
