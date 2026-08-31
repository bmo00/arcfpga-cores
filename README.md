# arcfpga-cores

FPGA reimplementations of coin-op arcade hardware, targeting **neptUNO+** alongside the other
platforms already supported by the frameworks these cores draw from (MiSTer, MiST, SiDi, SiDi128,
Pocket, NeptUNO). The project pursues two goals in parallel: collecting arcade cores already
written for other FPGA platforms and porting them to neptUNO+, and developing new, original cores
from scratch — including AI-assisted work, referred to in-house as "AI slop".

Cores are built one of two ways:

- **jtframe** — built from scratch, or ported from a MAME driver, on top of Jose Tejada's (jotego)
  [**JTFRAME**](https://github.com/jotego/jtframe) framework, the config-driven flow also used by
  [jotego/jtcores](https://github.com/jotego/jtcores).
- **native** — a vendored, already-working native MiST/MiSTer core from another author, bridged to
  neptUNO+ through a dedicated adapter layer instead of being rebuilt on JTFRAME.

> Not affiliated with or endorsed by jotego.

## Contents

- [`cores/`](cores/) — one arcade core per subdirectory: HDL, config, and its own README/doc. See
  [Cores](#cores) below for the current list, and [Directory layout](#directory-layout) for what's
  inside each one.
- [`modules/`](modules/) — shared HDL modules (CPUs, sound chips, etc.) used by the cores above,
  including [`modules/jtframe`](modules/jtframe) itself.

## Directory layout

This project is maintained across two sibling repos: a working `arcfpga-cores-develop` checkout,
and the public `arcfpga-cores` repo it publishes finished cores to. Build output has a different
shape in each:

- **`arcfpga-cores-develop`** — every core keeps a self-contained SOURCE pool,
  `cores/<core>/mra/` and `cores/<core>/arc/` (vendor-imported, MiSTer-imported, or
  jtframe-generated; never renamed in place), alongside `cores/<core>/releases/`: a git-tracked,
  disposable *published copy* of a selection from that pool (`releases/mra/`, `releases/arc/`), a
  dated `.rbf` per target (gitignored — committed only in the public `arcfpga-cores` repo), and
  `releases/rom/`, `releases/zip/` (real MAME ROM data staged locally for building, gitignored,
  never committed).
- **`arcfpga-cores`** (the public repo) — no separate source pool: `cores/<core>/releases/` is
  the only tier, with `mra/`/`arc/` renamed to the game's real MAME/HBMame set name and a dated
  `.rbf` per target, all git-tracked.

**jtframe core**:

```
cores/<core_name>/
  cfg/                  macros.def, mem.yaml, files.yaml, mame2mra.toml, mmr.yaml, msg
  hdl/                  core-specific Verilog/SystemVerilog
  sch/                  schematics reference material (when available)
  releases/
    mra/, arc/            git-tracked; renamed to the real MAME/HBMame set name
    mister/, neptunoplus/, ...   dated .rbf per target
  README.md
```

**native core** — `neptunoplus/` is the bridge: a flat folder holding its own Quartus project plus
adapter HDL, sibling of the vendored `hdl/`:

```
cores/<core_name>/
  hdl/                  vendored upstream HDL — never edit in place, patch instead
  neptunoplus/          neptUNO+ bridge (Quartus project + adapter HDL + patches/ + NOTES.md)
  releases/
    mra/, arc/            landed as-is from upstream (not generated — no mame2mra.toml)
    neptunoplus/           dated .rbf
  ATTRIBUTION.md
  README.md
```

## Cores

Cores are listed per FPGA target. Core names follow the release `.rbf` filename (without the
`_YYYYMMDD` date suffix). Only cores with a published release are shown, along with how many ROM
sets each core supports and the date of its latest release build — see
[doc/game_list.md](doc/game_list.md) for the full list of supported games, including every
alternate/clone set.

### MiSTer

| Core | Games | Description | Last update |
|---|---|---|---|
| [`jtcps3`](cores/cps3/README.md) | [17](doc/game_list.md#cps3) | Capcom, 1996–1999 — JOTEGO port | 2026-08-31 |
| [`jtrastan`](cores/rastan/README.md) | [19](doc/game_list.md#rastan) | Taito Corporation, 1987–1988 — JOTEGO port | 2026-08-21 |
| [`mystston`](cores/mystston/README.md) | [1](doc/game_list.md#mystston) | Technos Japan, 1984 | 2026-08-26 |

### NeptUNO+

| Core | Games | Description | Last update |
|---|---|---|---|
| [`aligator`](cores/aligator/) | [1](doc/game_list.md#aligator) | Gaelco, 1994 — jlrh port | 2026-08-26 |
| [`asterix`](cores/asterix/) | [1](doc/game_list.md#asterix) | Konami, 1992 — jlrh port | 2026-08-26 |
| [`bigkarnk`](cores/bigkarnk/) | [1](doc/game_list.md#bigkarnk) | Gaelco, 1991 — jlrh port | 2026-08-26 |
| [`biomtoy`](cores/biomtoy/) | [1](doc/game_list.md#biomtoy) | Gaelco, 1995 — jlrh port | 2026-08-26 |
| [`bucky`](cores/bucky/) | [1](doc/game_list.md#bucky) | Konami, 1992 | 2026-08-26 |
| [`empirecity`](cores/empirecity/) | [1](doc/game_list.md#empirecity) | Seibu Kaihatsu, 1986 — jlrh port | 2026-08-26 |
| [`glass`](cores/glass/) | [1](doc/game_list.md#glass) | Gaelco, 1993 — jlrh port | 2026-08-26 |
| [`jt1942`](cores/1942/README.md) | [3](doc/game_list.md#1942) | Capcom, 1984 — JOTEGO port | 2026-08-31 |
| [`jt1943`](cores/1943/README.md) | [3](doc/game_list.md#1943) | Capcom, 1987 — JOTEGO port | 2026-08-26 |
| [`jtajax`](cores/ajax/) | [1](doc/game_list.md#ajax) | Konami, 1987 — JOTEGO port | 2026-08-31 |
| [`jtaliens`](cores/aliens/README.md) | [5](doc/game_list.md#aliens) | Konami, 1988–1990 — JOTEGO port | 2026-08-31 |
| [`jtbiocom`](cores/biocom/README.md) | [1](doc/game_list.md#biocom) | Capcom, 1987 — JOTEGO port | 2026-08-31 |
| [`jtblkout`](cores/blkout/README.md) | [1](doc/game_list.md#blkout) | Technos Japan / California Dreams, 1989 — JOTEGO port | 2026-08-31 |
| [`jtbtiger`](cores/btiger/README.md) | [1](doc/game_list.md#btiger) | Capcom, 1987 — JOTEGO port | 2026-08-31 |
| [`jtbubl`](cores/bubl/README.md) | [2](doc/game_list.md#bubl) | Taito Corporation, 1986 — JOTEGO port | 2026-08-31 |
| [`jtcal50`](cores/cal50/) | [5](doc/game_list.md#cal50) | Jordan I.S. / Seta, 1988–1989 — JOTEGO port | 2026-08-31 |
| [`jtcastle`](cores/castle/README.md) | [1](doc/game_list.md#castle) | Konami, 1988 — JOTEGO port | 2026-08-31 |
| [`jtcircus`](cores/circus/) | [1](doc/game_list.md#circus) | Konami, 1984 — JOTEGO port | 2026-08-31 |
| [`jtcommnd`](cores/commnd/README.md) | [1](doc/game_list.md#commnd) | Capcom, 1985 — JOTEGO port | 2026-08-31 |
| [`jtcomsc`](cores/comsc/README.md) | [1](doc/game_list.md#comsc) | Konami, 1988 — JOTEGO port | 2026-08-31 |
| [`jtcontra`](cores/contra/README.md) | [1](doc/game_list.md#contra) | Konami, 1987 — JOTEGO port | 2026-08-31 |
| [`jtcop`](cores/cop/) | [2](doc/game_list.md#cop) | Data East Corporation, 1988–1989 — JOTEGO port | 2026-08-31 |
| [`jtcps1`](cores/cps1/README.md) | [33](doc/game_list.md#cps1) | Capcom, 1988–1996 — JOTEGO port | 2026-08-31 |
| [`jtcps15`](cores/cps15/README.md) | [19](doc/game_list.md#cps15) | Capcom, 1992–1994 — JOTEGO port | 2026-08-31 |
| [`jtcps2`](cores/cps2/README.md) | [320](doc/game_list.md#cps2) | Capcom, 1993–2004 — JOTEGO port | 2026-08-31 |
| [`jtcps3`](cores/cps3/README.md) | [17](doc/game_list.md#cps3) | Capcom, 1996–1999 — JOTEGO port | 2026-08-31 |
| [`jtdd`](cores/dd/README.md) | [1](doc/game_list.md#dd) | Technos Japan (Taito license), 1987 — JOTEGO port | 2026-08-31 |
| [`jtdd2`](cores/dd2/README.md) | [1](doc/game_list.md#dd2) | Technos Japan, 1988 — JOTEGO port | 2026-08-31 |
| [`jtddrbl`](cores/ddrbl/) | [1](doc/game_list.md#ddrbl) | Konami, 1986 — JOTEGO port | 2026-08-31 |
| [`jtexed`](cores/exed/README.md) | [1](doc/game_list.md#exed) | Capcom, 1985 — JOTEGO port | 2026-08-26 |
| [`jtflane`](cores/flane/README.md) | [1](doc/game_list.md#flane) | Konami, 1987 — JOTEGO port | 2026-08-31 |
| [`jtflstory`](cores/flstory/README.md) | [7](doc/game_list.md#flstory) | Taito, 1984–1986 — JOTEGO port | 2026-08-31 |
| [`jtfround`](cores/fround/README.md) | [1](doc/game_list.md#fround) | Konami, 1988 — JOTEGO port | 2026-08-31 |
| [`jtgae1`](cores/gae1/README.md) | [4](doc/game_list.md#gae1) | Gaelco, 1991–1995 — JOTEGO port | 2026-08-31 |
| [`jtgaiden`](cores/gaiden/README.md) | [3](doc/game_list.md#gaiden) | Tecmo, 1988–1991 — JOTEGO port | 2026-08-31 |
| [`jtgals`](cores/gals/README.md) | [1](doc/game_list.md#gals) | Kaneko, 1990 — JOTEGO port | 2026-08-31 |
| [`jtgng`](cores/gng/README.md) | [1](doc/game_list.md#gng) | Capcom, 1985 — JOTEGO port | 2026-08-26 |
| [`jtgrad3`](cores/grad3/README.md) | [1](doc/game_list.md#grad3) | Konami, 1989 — JOTEGO port | 2026-08-31 |
| [`jtgunsmk`](cores/gunsmk/README.md) | [1](doc/game_list.md#gunsmk) | Capcom, 1985 — JOTEGO port | 2026-08-26 |
| [`jtkarnov`](cores/karnov/) | [3](doc/game_list.md#karnov) | Data East Corporation, 1987–1988 — JOTEGO port | 2026-08-31 |
| [`jtkchamp`](cores/kchamp/README.md) | [2](doc/game_list.md#kchamp) | Data East USA, 1984 — JOTEGO port | 2026-08-31 |
| [`jtkicker`](cores/kicker/README.md) | [1](doc/game_list.md#kicker) | Konami, 1985 — JOTEGO port | 2026-08-31 |
| [`jtkiwi`](cores/kiwi/README.md) | [8](doc/game_list.md#kiwi) | Taito Corporation Japan, 1987–1989 — JOTEGO port | 2026-08-31 |
| [`jtkunio`](cores/kunio/README.md) | [1](doc/game_list.md#kunio) | Technos Japan (Taito America license), 1986 — JOTEGO port | 2026-08-31 |
| [`jtlabrun`](cores/labrun/README.md) | [1](doc/game_list.md#labrun) | Konami, 1987 — JOTEGO port | 2026-08-31 |
| [`jtmidres`](cores/midres/) | [1](doc/game_list.md#midres) | Data East Corporation, 1989 — JOTEGO port | 2026-08-31 |
| [`jtmikie`](cores/mikie/README.md) | [1](doc/game_list.md#mikie) | Konami, 1984 — JOTEGO port | 2026-08-31 |
| [`jtmx5k`](cores/mx5k/README.md) | [1](doc/game_list.md#mx5k) | Konami, 1987 — JOTEGO port | 2026-08-31 |
| [`jtninja`](cores/ninja/README.md) | [2](doc/game_list.md#ninja) | Data East Corporation, 1987–1988 — JOTEGO port | 2026-08-21 |
| [`jtoutrun`](cores/outrun/README.md) | [2](doc/game_list.md#outrun) | Sega, 1986–1989 — JOTEGO port | 2026-08-31 |
| [`jtpaclan`](cores/paclan/) | [1](doc/game_list.md#paclan) | Namco, 1984 — JOTEGO port | 2026-08-31 |
| [`jtpang`](cores/pang/README.md) | [13](doc/game_list.md#pang) | Capcom, 1988–1991 — JOTEGO port | 2026-08-31 |
| [`jtparoda`](cores/paroda/) | [2](doc/game_list.md#paroda) | Konami, 1990 — JOTEGO port | 2026-08-31 |
| [`jtpinpon`](cores/pinpon/README.md) | [1](doc/game_list.md#pinpon) | Konami, 1985 — JOTEGO port | 2026-08-31 |
| [`jtpktgal`](cores/pktgal/README.md) | [1](doc/game_list.md#pktgal) | Data East Corporation, 1987 — JOTEGO port | 2026-08-31 |
| [`jtprmr`](cores/prmr/README.md) | [1](doc/game_list.md#prmr) | Konami, 1993 — JOTEGO port | 2026-08-31 |
| [`jtrastan`](cores/rastan/README.md) | [19](doc/game_list.md#rastan) | Taito Corporation, 1987–1988 — JOTEGO port | 2026-08-31 |
| [`jtriders`](cores/riders/README.md) | [4](doc/game_list.md#riders) | Konami, 1990–1991 — JOTEGO port | 2026-08-31 |
| [`jtroadf`](cores/roadf/README.md) | [2](doc/game_list.md#roadf) | Konami, 1984 — JOTEGO port | 2026-08-26 |
| [`jtroc`](cores/roc/README.md) | [1](doc/game_list.md#roc) | Konami, 1983 — JOTEGO port | 2026-08-31 |
| [`jtrumble`](cores/rumble/README.md) | [1](doc/game_list.md#rumble) | Capcom, 1986 — JOTEGO port | 2026-08-26 |
| [`jtrungun`](cores/rungun/) | [1](doc/game_list.md#rungun) | Konami, 1993 — JOTEGO port | 2026-08-31 |
| [`jts16`](cores/s16/README.md) | [19](doc/game_list.md#s16) | Sega, 1985–1988 — JOTEGO port | 2026-08-31 |
| [`jts16b`](cores/s16b/README.md) | [38](doc/game_list.md#s16b) | Sega, 1986–2008 — JOTEGO port | 2026-08-31 |
| [`jts18`](cores/s18/README.md) | [11](doc/game_list.md#s18) | Sega, 1989–2021 — JOTEGO port | 2026-08-31 |
| [`jtsarms`](cores/sarms/README.md) | [1](doc/game_list.md#sarms) | Capcom, 1986 — JOTEGO port | 2026-08-26 |
| [`jtsbaskt`](cores/sbaskt/README.md) | [1](doc/game_list.md#sbaskt) | Konami, 1984 — JOTEGO port | 2026-08-31 |
| [`jtsectnz`](cores/sectnz/README.md) | [2](doc/game_list.md#sectnz) | Capcom, 1985–1986 — JOTEGO port | 2026-08-31 |
| [`jtsf`](cores/sf/README.md) | [1](doc/game_list.md#sf) | Capcom, 1987 — JOTEGO port | 2026-08-31 |
| [`jtshanon`](cores/shanon/README.md) | [1](doc/game_list.md#shanon) | Sega, 1987 — JOTEGO port | 2026-08-31 |
| [`jtshouse`](cores/shouse/README.md) | [19](doc/game_list.md#shouse) | Namco, 1987–1991 — JOTEGO port | 2026-08-31 |
| [`jtsimson`](cores/simson/README.md) | [3](doc/game_list.md#simson) | Konami, 1991 — JOTEGO port | 2026-08-31 |
| [`jtslyspy`](cores/slyspy/) | [2](doc/game_list.md#slyspy) | Data East Corporation, 1989–1990 — JOTEGO port | 2026-08-31 |
| [`jttaitox`](cores/taitox/README.md) | [10](doc/game_list.md#taitox) | East Technology, 1988–1992 — JOTEGO port | 2026-08-31 |
| [`jtthundr`](cores/thundr/) | [8](doc/game_list.md#thundr) | Namco, 1985–1987 — JOTEGO port | 2026-08-31 |
| [`jttmnt`](cores/tmnt/README.md) | [4](doc/game_list.md#tmnt) | Konami, 1989–1991 — JOTEGO port | 2026-08-31 |
| [`jttoki`](cores/toki/README.md) | [2](doc/game_list.md#toki) | TAD Corporation, 1988–1989 — JOTEGO port | 2026-08-31 |
| [`jttora`](cores/tora/README.md) | [2](doc/game_list.md#tora) | Capcom, 1987–1988 — JOTEGO port | 2026-08-31 |
| [`jttrack`](cores/track/README.md) | [1](doc/game_list.md#track) | Konami, 1983 — JOTEGO port | 2026-08-31 |
| [`jttrojan`](cores/trojan/README.md) | [2](doc/game_list.md#trojan) | Capcom, 1986–1987 — JOTEGO port | 2026-08-26 |
| [`jttwin16`](cores/twin16/README.md) | [4](doc/game_list.md#twin16) | Konami, 1987–1989 — JOTEGO port | 2026-08-31 |
| [`jtvigil`](cores/vigil/README.md) | [1](doc/game_list.md#vigil) | Irem, 1988 — JOTEGO port | 2026-08-31 |
| [`jtvlfied`](cores/vlfied/README.md) | [6](doc/game_list.md#vlfied) | Taito America Corporation, 1989 — JOTEGO port | 2026-08-31 |
| [`jtwc`](cores/wc/README.md) | [2](doc/game_list.md#wc) | Tehkan, 1985 — JOTEGO port | 2026-08-31 |
| [`jtwwfss`](cores/wwfss/README.md) | [1](doc/game_list.md#wwfss) | Technos Japan, 1989 — JOTEGO port | 2026-08-31 |
| [`jtxmen`](cores/xmen/) | [1](doc/game_list.md#xmen) | Konami, 1992 — JOTEGO port | 2026-08-31 |
| [`jtyiear`](cores/yiear/README.md) | [1](doc/game_list.md#yiear) | Konami, 1985 — JOTEGO port | 2026-08-31 |
| [`mariobros`](cores/mariobros/README.md) | [1](doc/game_list.md#mariobros) | Nintendo, 1983 | 2026-08-26 |
| [`momoko`](cores/momoko/) | [1](doc/game_list.md#momoko) | Jaleco, 1986 | 2026-08-28 |
| [`moomesa`](cores/moomesa/) | [2](doc/game_list.md#moomesa) | Konami, 1992 — jlrh port | 2026-08-26 |
| [`mystston`](cores/mystston/README.md) | [1](doc/game_list.md#mystston) | Technos Japan, 1984 | 2026-08-26 |
| [`opwolf`](cores/opwolf/) | [1](doc/game_list.md#opwolf) | Taito, 1987 — jlrh port | 2026-08-26 |
| [`splash`](cores/splash/) | [1](doc/game_list.md#splash) | Gaelco / OMK Software, 1992 | 2026-08-28 |
| [`squash`](cores/squash/) | [1](doc/game_list.md#squash) | Gaelco, 1992 — jlrh port | 2026-08-26 |
| [`ssriders`](cores/ssriders/) | [1](doc/game_list.md#ssriders) | Konami, 1991 — jlrh port | 2026-08-26 |
| [`thoop`](cores/thoop/) | [1](doc/game_list.md#thoop) | Gaelco, 1992 — jlrh port | 2026-08-26 |
| [`thoop2`](cores/thoop2/) | [1](doc/game_list.md#thoop2) | Gaelco, 1994 — jlrh port | 2026-08-26 |
| [`wrally`](cores/wrally/) | [1](doc/game_list.md#wrally) | Gaelco, 1993 — jlrh port | 2026-08-26 |
| [`wrally2`](cores/wrally2/) | [1](doc/game_list.md#wrally2) | Gaelco, 1995 — jlrh port | 2026-08-26 |

*This table is updated as cores are added — see each core's own README for build/hardware notes.*

## Building

The two kinds of core described above build differently: **jtframe** cores go through JTFRAME's
own CLI pipeline end to end; **native** cores skip that pipeline entirely and compile as a
standalone Quartus project. See [doc/building.md](doc/building.md) for the full lint / simulate /
`.mra`-`.arc` generation / synthesize pipeline for each, including the exact commands and Docker
images used at every step.

A `.mra` is metadata only — it contains no game data. See
[doc/generating-rom-files.md](doc/generating-rom-files.md) for how to merge your own legally
obtained MAME ROM dump with a `.mra` into the `.rom` a core actually loads.

## Credits

- [Jose Tejada (jotego)](https://github.com/jotego) —
  [JTFRAME](https://github.com/jotego/jtframe) and
  [jtcores](https://github.com/jotego/jtcores), the framework and core collection this project
  builds on (80 ported cores, 22 shared modules in this repo).
- [somhi](https://github.com/somhi) — reference work on JTFRAME-based neptUNO+ targets, used
  alongside other public sources when building this project's own neptUNO+ target.
- [gyurco](https://github.com/gyurco) — 2 ported cores in this collection and 1 shared module
  under `modules/`.
- [javi-ivaj](https://github.com/javi-ivaj) — 2 ported cores in this collection.
- [jlrh](https://github.com/jlrh) — 14 ported cores in this collection.
- [jtfpga](https://github.com/jtfpga) — 1 shared module under `modules/`.
- [meathax](https://github.com/meathax) — 1 ported core in this collection.
- [mist-devel](https://github.com/mist-devel) — 2 shared modules under `modules/`.
- [MiSTer-devel](https://github.com/MiSTer-devel) — 2 ported cores in this collection.
- The MiSTer/MiST/SiDi open-source FPGA arcade community.
