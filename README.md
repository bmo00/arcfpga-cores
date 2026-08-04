# arcfpga-cores

FPGA arcade cores built on Jose Tejada's (jotego) [**JTFRAME**](https://github.com/jotego/jtframe)
framework, with an added **neptUNO+** target alongside the targets JTFRAME already supports
(MiSTer, MiST, SiDi, SiDi128, Pocket, NeptUNO).

> Not affiliated with or endorsed by jotego.

## Contents

- [`cores/`](cores/) — one arcade core per subdirectory: HDL, config, and its own README/doc. See
  [Cores](#cores) below for the current list.
- [`modules/`](modules/) — shared HDL modules (CPUs, sound chips, etc.) used by the cores above,
  including [`modules/jtframe`](modules/jtframe) itself.
- [`releases/`](releases/) — built binaries per core: a dated `.rbf` per target, `.mra` files
  (MiSTer) and `.arc` files (MiST-family targets).

## Cores

Cores are listed per FPGA target. Core names follow the release `.rbf` filename (without the
`_YYYYMMDD` date suffix). Only cores with a published release are shown, along with the parents
(game ROMsets) each core supports and the date of its latest release build.

### MiSTer

| Core | Parents | Description | Last update |
|---|---|---|---|
| [`mystston`](cores/mystston/README.md) | Mysterious Stones: Dr. John's Adventure (`mystston`) | Technos Japan, 1984 (board TA-0010) | 2026-08-03 |
| [`jtriders`](cores/riders/README.md) | Golfing Greats (World, version L) (`glfgreat`)<br>Lightning Fighters (World) (`lgtnfght`)<br>Sunset Riders (4 Players ver EAC) (`ssriders`)<br>Teenage Mutant Ninja Turtles: Turtles in Time (4 Players ver UAA) (`tmnt2`) | Konami, 1991–1994 (TMNT2/GX hardware) — official jotego core, only synthesized | 2026-07-31 |

### NeptUNO+

| Core | Parents | Description | Last update |
|---|---|---|---|
| [`jt1942`](cores/1942/README.md) | 1942 (Revision B) (`1942`)<br>Pirate Ship Higemaru (`higemaru`)<br>Vulgus (set 1) (`vulgus`) | Capcom, 1984 — port of the official jotego core | 2026-08-03 |
| [`jt1943`](cores/1943/README.md) | 1943 Kai Midway Kaisen (Japan) (`1943kai`)<br>1943 The Battle of Midway (Euro) (`1943`)<br>1943 The Battle of Midway Mark II (US) (`1943mii`) | Capcom, 1987 — port of the official jotego core | 2026-08-04 |
| [`jtajax`](cores/ajax/) | Ajax (`ajax`) | Konami, 1987 — port of the official jotego core | 2026-08-04 |
| [`jtaliens`](cores/aliens/README.md) | Aliens (World set 1) (`aliens`)<br>Crime Fighters (World 2 players) (`crimfght`)<br>Gang Busters (set 1) (`gbusters`)<br>Super Contra (set 1) (`scontra`)<br>Thunder Cross (set 1) (`thunderx`) | Konami, 1990 — port of the official jotego core | 2026-08-04 |
| [`jtbiocom`](cores/biocom/README.md) | Bionic Commando (Euro) (`bionicc`) | Capcom, 1987 — port of the official jotego core | 2026-08-04 |
| [`jtbtiger`](cores/btiger/README.md) | Black Tiger (US) (`blktiger`) | Capcom, 1987 — port of the official jotego core | 2026-08-04 |
| [`jtbubl`](cores/bubl/README.md) | Bubble Bobble (Japan, Ver 0.1) (`bublbobl`)<br>Tokio - Scramble Formation (newer) (`tokio`) | Taito, 1986 — port of the official jotego core | 2026-08-04 |
| [`jtcastle`](cores/castle/README.md) | Haunted Castle (version M) (`hcastle`) | Konami, 1988 — port of the official jotego core | 2026-08-04 |
| [`jtcommnd`](cores/commnd/README.md) | Commando (World) (`commando`) | Capcom, 1985 — port of the official jotego core | 2026-08-04 |
| [`jtcomsc`](cores/comsc/README.md) | Combat School (joystick) (`combatsc`) | Konami, 1988 — port of the official jotego core | 2026-08-04 |
| [`jtcontra`](cores/contra/README.md) | Contra (US - Asia, set 1) (`contra`) | Konami, 1987 — port of the official jotego core | 2026-08-04 |
| [`jtflane`](cores/flane/README.md) | Fast Lane (`fastlane`) | Konami, 1987 — port of the official jotego core | 2026-08-04 |
| [`jtgng`](cores/gng/README.md) | Ghosts'n Goblins (World set 1) (`gng`) | Capcom, 1985 — port of the official jotego core | 2026-08-04 |
| [`jtkunio`](cores/kunio/README.md) | Renegade (US) (`renegade`) | Technos Japan, 1986 — port of the official jotego core | 2026-08-04 |
| [`jtlabrun`](cores/labrun/README.md) | Trick Trap (World) (`tricktrap`) | Konami, 1986 — port of the official jotego core | 2026-08-04 |
| [`jtmx5k`](cores/mx5k/README.md) | MX5000 (version U) (`mx5000`) | Konami, 1987 — port of the official jotego core | 2026-08-04 |
| [`mystston`](cores/mystston/README.md) | Mysterious Stones Dr. John's Adventure (`mystston`) | Technos Japan, 1984 (board TA-0010) | 2026-08-03 |
| [`jtriders`](cores/riders/README.md) | Golfing Greats (World, version L) (`glfgreat`)<br>Lightning Fighters (World) (`lgtnfght`)<br>Sunset Riders (4 Players ver EAC) (`ssriders`)<br>Teenage Mutant Ninja Turtles Turtles in Time (4 Players ver UAA) (`tmnt2`) | Konami, 1991–1994 (TMNT2/GX hardware) — port of the official jotego core | 2026-07-31 |
| [`jttora`](cores/tora/README.md) | F-1 Dream (set 1) (`f1dream`)<br>Tiger Road (US) (`tigeroad`) | Capcom, 1987 — port of the official jotego core | 2026-08-04 |

*This table is updated as cores are added — see each core's own README for build/hardware notes.*

## Credits

- [Jose Tejada (jotego)](https://github.com/jotego) — [JTFRAME](https://github.com/jotego/jtframe)
  and [jtcores](https://github.com/jotego/jtcores), the framework and core collection this project
  builds on.
- [somhi](https://github.com/somhi) — reference work on JTFRAME-based neptUNO+ targets, used
  alongside other public sources when building this project's own neptUNO+ target.
- The MiSTer/MiST/SiDi open-source FPGA arcade community.
