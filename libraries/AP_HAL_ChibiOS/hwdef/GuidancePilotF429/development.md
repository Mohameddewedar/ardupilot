# GuidancePilotF429 local development files

Run commands from the repository root. Keep task-owned downloads, tools,
worktrees and bench records inside `.local/guidance-f429/`. This directory
is ignored by an anchored rule in the root `.gitignore`.

## Files to review in Git

- Board `hwdef.dat` and `hwdef-bl.dat`, README, wiring Markdown and SVG.
- The source-backed power analysis in
  [docs/research/guidance-f429-power-datasheets.md](../../../../docs/research/guidance-f429-power-datasheets.md).
- This layout and the narrow ignore rules that keep generated material out
  of firmware changes.

The recommended inputs are 3.3 V for IMU/GPS and 5 V for the HW-125 reader;
actual loaded operation remains unverified. The [wiring guide](expansion-wiring.md)
defines the connections and remaining bench checks. Power nets are physical
connections; there is no firmware setting that establishes the external voltage.

## Local retention layout

All paths in this table are relative to `.local/guidance-f429/`.

| Directory | Purpose and retention |
| --- | --- |
| `inputs/photos/` | Original and replacement carrier photographs, moved from the download folder and hash-checked against the versioned evidence copies. |
| `expansion/datasheets/` | Manufacturer PDFs, source/hash manifests, supplier comparisons and the datasheet ZIP. Retain locally; cite the primary sources in the tracked research note. |
| `expansion/artifacts/` | Static validation, review transcripts, patches, rendering tools and generated previews. Retain as historical evidence, not firmware source. |
| `expansion/code/`, `expansion/docs/`, `expansion/review/` | Registered implementation/review worktrees. Their individual Git status remains available; the parent repository ignores these directories. |
| `expansion/evidence/` | Registered worktree of the separate hardware-photo evidence branch. Original photos and their hash manifest remain versioned on that branch. Keep large photographs out of the board firmware branch and use the existing immutable evidence links. |
| `expansion/discovery-images/`, `expansion/briefs/` | Downloaded reference images and task briefs. |
| `expansion/issue-cleanup/`, `expansion/path-cleanup/` | Private tracker snapshots and edit-recovery records. These can contain old local paths; they are not publishable issue text. |
| `bench/` | Original flash backup, readbacks, telemetry, measurements, build logs and the historical stock-board build directories. Retain the flash backup and provenance; these builds do not validate the expanded board. |
| `bringup-20261105/` | Expansion build/upload logs, full post-upload flash readback, parameter snapshots, raw telemetry and qualified results. Retain locally; flash and parameter dumps can contain device/user configuration. The SD socket was empty during this run. |
| `tooling/` | Downloaded compiler/debugger installation and Python environment. These are host dependencies, not vendored source or ArduPilot submodules. |
| `build/` | Fresh future application/bootloader outputs. Regenerate instead of relying on relocated historical Waf caches. |
| `delegation/` | Completed relay runs, ownership records and output claims. Shared service configuration stays in its standard host location; its configured state/output roots now point inside this workspace. |
| `scratch/` | Former temporary drafts and rendered comparisons. Recreate or delete these after review; they are not authoritative source. |
| `migration.json` | Private old-to-new location map and hashes of critical relocated artifacts. Preserve this with the historical records. |

`/.delegate/` is also ignored: its fleet/model choices are local execution
preferences, not portable firmware requirements. Ignoring it does not remove
already tracked files. The shared local `.git/info/exclude` also excludes
`/.delegate/` so linked worktrees based on older commits receive the same
protection. Do not use broad rules that hide board source, research
Markdown, or reproducible configuration needed by a maintainer.

Historical logs and completed relay records preserve the paths and assumptions
used when they were captured. Consult `migration.json` to locate moved files;
do not rewrite old observations into claims about the new configuration.
The task's original source directories were moved without leaving external
symlinks. The source photographs are retained in `inputs/photos/` and
the versioned copies remain in the evidence worktree. Shared installed skills
and service configuration stay in their standard host locations; these are
application settings, not task artifacts.

## Using the relocated tools

The ignored `env.sh` beside `migration.json` sets `GUIDANCE_VENV`,
`GUIDANCE_BUILD_ROOT`, `GUIDANCE_TOOLCHAIN` and `GUIDANCE_OPENOCD_ROOT`
from its own location. It adds the compiler and Python environment to PATH.

```sh
source .local/guidance-f429/env.sh
python --version
arm-none-eabi-gcc --version
LD_LIBRARY_PATH="$GUIDANCE_OPENOCD_ROOT/usr/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
  "$GUIDANCE_OPENOCD_ROOT/usr/bin/openocd" --version
```

After physical assembly confirmation, use fresh build output, for example:

```sh
./waf configure --board GuidancePilotF429 --no-submodule-update \
  --python "$GUIDANCE_VENV/bin/python" \
  --out "$GUIDANCE_BUILD_ROOT/plane"
./waf plane
```

Follow the board README when regenerating the matching bootloader. Do not
delete the original flash backup to reclaim build space. Do not run Waf with
sudo. Moving files and checking tool versions are not a firmware build,
upload or powered hardware test.

The background delegation service caches its registry at startup. Reload
that MCP server before the next relay job so it uses the relocated state
directory. Future briefs and output directories must be inside the local
layout above; keep host-specific paths out of published issues and commits.
