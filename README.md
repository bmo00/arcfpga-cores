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
| [`jtcircus`](cores/circus/) | Circus Charlie (level select, set 1) (`circusc`) | Konami, 1984 — port of the official jotego core | 2026-08-04 |
| [`jtcommnd`](cores/commnd/README.md) | Commando (World) (`commando`) | Capcom, 1985 — port of the official jotego core | 2026-08-04 |
| [`jtcomsc`](cores/comsc/README.md) | Combat School (joystick) (`combatsc`) | Konami, 1988 — port of the official jotego core | 2026-08-04 |
| [`jtcontra`](cores/contra/README.md) | Contra (US - Asia, set 1) (`contra`) | Konami, 1987 — port of the official jotego core | 2026-08-04 |
| [`jtcop`](cores/cop/) | Hippodrome (US) (`hippodrm`)<br>Robocop (World, revision 4) (`robocop`) | Data East, 1988 — port of the official jotego core | 2026-08-04 |
| [`jtdd2`](cores/dd2/README.md) | Double Dragon II The Revenge (World) (`ddragon2`) | Technos Japan, 1989 — port of the official jotego core | 2026-08-04 |
| [`jtdd`](cores/dd/README.md) | Double Dragon (World set 1) (`ddragon`) | Technos Japan, 1987 — port of the official jotego core | 2026-08-04 |
| [`jtddrbl`](cores/ddrbl/) | Double Dribble (`ddribble`) | Konami, 1986 — port of the official jotego core | 2026-08-04 |
| [`jtexed`](cores/exed/README.md) | Exed Exes (`exedexes`) | Capcom, 1985 — port of the official jotego core | 2026-08-04 |
| [`jtflane`](cores/flane/README.md) | Fast Lane (`fastlane`) | Konami, 1987 — port of the official jotego core | 2026-08-04 |
| [`jtflstory`](cores/flstory/README.md) | Bronx (bootleg of Cycle Shooting) (`bronx`)<br>Cycle Shooting (`cyclshtg`)<br>N.Y. Captor (rev 2) (`nycaptor`)<br>Onna Sanshirou - Typhoon Gal (rev 1) (`onna34ro`)<br>Rumba Lumber (rev 1) (`rumba`)<br>The FairyLand Story (`flstory`)<br>Victorious Nine (`victnine`) | Taito, 1985 — port of the official jotego core | 2026-08-04 |
| [`jtfround`](cores/fround/README.md) | The Final Round (version M) (`fround`) | Konami, 1988 — port of the official jotego core | 2026-08-04 |
| [`jtgaiden`](cores/gaiden/README.md) | Raiga - Strato Fighter (US) (`stratif`)<br>Shadow Warriors (World, set 1) (`shadoww`)<br>Wild Fang - Tecmo Knight (World) (`wildfang`) | Tecmo, 1988 — port of the official jotego core | 2026-08-04 |
| [`jtgng`](cores/gng/README.md) | Ghosts'n Goblins (World set 1) (`gng`) | Capcom, 1985 — port of the official jotego core | 2026-08-04 |
| [`jtgunsmk`](cores/gunsmk/README.md) | Gun.Smoke (World, 1985-11-15) (`gunsmoke`) | Capcom, 1985 — port of the official jotego core | 2026-08-04 |
| [`jtkarnov`](cores/karnov/) | Atomic Runner Chelnov (World) (`chelnov`)<br>Karnov (US, rev 6) (`karnov`)<br>Wonder Planet (Japan) (`wndrplnt`) | Data East, 1987 — port of the official jotego core | 2026-08-04 |
| [`jtkchamp`](cores/kchamp/README.md) | Karate Champ Player Vs Player (US, set 1) (`kchampvs`)<br>Karate Champ (US) (`kchamp`) | Data East, 1984 — port of the official jotego core | 2026-08-04 |
| [`jtkicker`](cores/kicker/README.md) | Kicker (`kicker`) | Konami, 1985 — port of the official jotego core | 2026-08-04 |
| [`jtkunio`](cores/kunio/README.md) | Renegade (US) (`renegade`) | Technos Japan, 1986 — port of the official jotego core | 2026-08-04 |
| [`jtlabrun`](cores/labrun/README.md) | Trick Trap (World) (`tricktrap`) | Konami, 1986 — port of the official jotego core | 2026-08-04 |
| [`jtmidres`](cores/midres/) | Midnight Resistance (World, set 1) (`midres`) | Data East, 1989 — port of the official jotego core | 2026-08-04 |
| [`jtmikie`](cores/mikie/README.md) | Mikie (`mikie`) | Konami, 1984 — port of the official jotego core | 2026-08-04 |
| [`jtmx5k`](cores/mx5k/README.md) | MX5000 (version U) (`mx5000`) | Konami, 1987 — port of the official jotego core | 2026-08-04 |
| [`jtninja`](cores/ninja/README.md) | Bad Dudes vs. Dragonninja (US, revision 1) (`baddudes`)<br>Heavy Barrel (World) (`hbarrel`) | Data East, 1988 — port of the official jotego core | 2026-08-04 |
| [`jtpaclan`](cores/paclan/) | Pac-Land (World) (`pacland`) | Namco, 1984 — port of the official jotego core | 2026-08-04 |
| [`jtpang`](cores/pang/README.md) | Adventure Quiz 2 - Hatenax no Daibouken (Japan 900228) (`hatena`)<br>Block Block (World 911219 Joystick) (`block`)<br>Capcom World (Japan) (`cworld`)<br>Dokaben 2 (Japan) (`dokaben2`)<br>Dokaben (Japan) (`dokaben`)<br>Mahjong Gakuen 2 Gakuen-chou no Fukushuu (`mgakuen2`)<br>Mahjong Gakuen (`mgakuen`)<br>Pang (World) (`pang`)<br>Poker Ladies (`pkladies`)<br>Quiz Sangokushi (Japan) (`qsangoku`)<br>Quiz Tonosama no Yabou (Japan) (`qtono1`)<br>Super Marukin-Ban (Japan 911128) (`marukin`)<br>Super Pang (World 900914) (`spang`) | Mitchell, 1989 — port of the official jotego core | 2026-08-04 |
| [`jtparoda`](cores/paroda/) | Parodius Da! Shinwa kara Owarai e (World, set 1) (`parodius`)<br>Surprise Attack (World ver. K) (`suratk`) | Konami, 1988 — port of the official jotego core | 2026-08-04 |
| [`jtpinpon`](cores/pinpon/README.md) | Konami's Ping-Pong (`pingpong`) | Konami, 1985 — port of the official jotego core | 2026-08-04 |
| [`jtriders`](cores/riders/README.md) | Golfing Greats (World, version L) (`glfgreat`)<br>Lightning Fighters (World) (`lgtnfght`)<br>Sunset Riders (4 Players ver EAC) (`ssriders`)<br>Teenage Mutant Ninja Turtles Turtles in Time (4 Players ver UAA) (`tmnt2`) | Konami, 1991–1994 (TMNT2/GX hardware) — port of the official jotego core | 2026-07-31 |
| [`jtroadf`](cores/roadf/README.md) | Hyper Sports (`hyperspt`)<br>Road Fighter (set 1) (`roadf`) | Konami, 1984 — port of the official jotego core | 2026-08-04 |
| [`jtroc`](cores/roc/README.md) | Roc'n Rope (`rocnrope`) | Konami, 1983 — port of the official jotego core | 2026-08-04 |
| [`jtrumble`](cores/rumble/README.md) | The Speed Rumbler (set 1) (`srumbler`) | Capcom, 1986 — port of the official jotego core | 2026-08-04 |
| [`jtsbaskt`](cores/sbaskt/README.md) | Super Basketball (version I, encrypted) (`sbasketb`) | Konami, 1984 — port of the official jotego core | 2026-08-04 |
| [`jtsectnz`](cores/sectnz/README.md) | Legendary Wings (US, rev. C) (`lwings`)<br>Section Z (US) (`sectionz`) | Capcom, 1985 — port of the official jotego core | 2026-08-04 |
| [`jttora`](cores/tora/README.md) | F-1 Dream (set 1) (`f1dream`)<br>Tiger Road (US) (`tigeroad`) | Capcom, 1987 — port of the official jotego core | 2026-08-04 |
| [`jtyiear`](cores/yiear/README.md) | Yie Ar Kung-Fu (version I) (`yiear`) | Konami, 1985 — port of the official jotego core | 2026-08-04 |
| [`mystston`](cores/mystston/README.md) | Mysterious Stones Dr. John's Adventure (`mystston`) | Technos Japan, 1984 (board TA-0010) | 2026-08-03 |

*This table is updated as cores are added — see each core's own README for build/hardware notes.*

## Credits

- [Jose Tejada (jotego)](https://github.com/jotego) — [JTFRAME](https://github.com/jotego/jtframe)
  and [jtcores](https://github.com/jotego/jtcores), the framework and core collection this project
  builds on.
- [somhi](https://github.com/somhi) — reference work on JTFRAME-based neptUNO+ targets, used
  alongside other public sources when building this project's own neptUNO+ target.
- The MiSTer/MiST/SiDi open-source FPGA arcade community.
