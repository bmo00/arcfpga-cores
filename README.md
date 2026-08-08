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
`_YYYYMMDD` date suffix). Only cores with a published release are shown, along with how many ROM
sets each core supports and the date of its latest release build — see
[doc/game_list.md](doc/game_list.md) for the full list of supported games, including every
alternate/clone set.

### MiSTer

| Core | Games | Description | Last update |
|---|---|---|---|
| [`jtrastan`](cores/rastan/README.md) | [4](doc/game_list.md#rastan) | Taito Corporation, 1987–1988 — JOTEGO port | 2026-08-08 |
| [`jtriders`](cores/riders/README.md) | [4](doc/game_list.md#riders) | Konami, 1990–1991 — JOTEGO port | 2026-08-08 |
| [`mystston`](cores/mystston/README.md) | [1](doc/game_list.md#mystston) | Technos Japan, 1984 | 2026-08-08 |

### NeptUNO+

| Core | Games | Description | Last update |
|---|---|---|---|
| [`aligator`](cores/aligator/) | [1](doc/game_list.md#aligator) | Gaelco, 1994 — jlrh port | 2026-08-08 |
| [`asterix`](cores/asterix/) | [1](doc/game_list.md#asterix) | Konami, 1992 — jlrh port | 2026-08-08 |
| [`bigkarnk`](cores/bigkarnk/) | [1](doc/game_list.md#bigkarnk) | Gaelco, 1991 — jlrh port | 2026-08-08 |
| [`biomtoy`](cores/biomtoy/) | [1](doc/game_list.md#biomtoy) | Gaelco / Zeus, 1995 — jlrh port | 2026-08-08 |
| [`empirecity`](cores/empirecity/) | [1](doc/game_list.md#empirecity) | Seibu Kaihatsu, 1986 — jlrh port | 2026-08-08 |
| [`glass`](cores/glass/) | [1](doc/game_list.md#glass) | OMK / Gaelco, 1994 — jlrh port | 2026-08-08 |
| [`jt1942`](cores/1942/README.md) | [3](doc/game_list.md#1942) | Capcom, 1984 — JOTEGO port | 2026-08-08 |
| [`jt1943`](cores/1943/README.md) | [3](doc/game_list.md#1943) | Capcom, 1987 — JOTEGO port | 2026-08-08 |
| [`jtajax`](cores/ajax/) | [1](doc/game_list.md#ajax) | Konami, 1987 — JOTEGO port | 2026-08-08 |
| [`jtaliens`](cores/aliens/README.md) | [5](doc/game_list.md#aliens) | Konami, 1988–1990 — JOTEGO port | 2026-08-08 |
| [`jtbiocom`](cores/biocom/README.md) | [1](doc/game_list.md#biocom) | Capcom, 1987 — JOTEGO port | 2026-08-08 |
| [`jtbtiger`](cores/btiger/README.md) | [1](doc/game_list.md#btiger) | Capcom, 1987 — JOTEGO port | 2026-08-08 |
| [`jtbubl`](cores/bubl/README.md) | [2](doc/game_list.md#bubl) | Taito Corporation, 1986 — JOTEGO port | 2026-08-08 |
| [`jtcastle`](cores/castle/README.md) | [1](doc/game_list.md#castle) | Konami, 1988 — JOTEGO port | 2026-08-08 |
| [`jtcircus`](cores/circus/) | [1](doc/game_list.md#circus) | Konami, 1984 — JOTEGO port | 2026-08-08 |
| [`jtcommnd`](cores/commnd/README.md) | [1](doc/game_list.md#commnd) | Capcom, 1985 — JOTEGO port | 2026-08-08 |
| [`jtcomsc`](cores/comsc/README.md) | [1](doc/game_list.md#comsc) | Konami, 1988 — JOTEGO port | 2026-08-08 |
| [`jtcontra`](cores/contra/README.md) | [1](doc/game_list.md#contra) | Konami, 1987 — JOTEGO port | 2026-08-08 |
| [`jtcop`](cores/cop/) | [2](doc/game_list.md#cop) | Data East Corporation, 1988–1989 — JOTEGO port | 2026-08-08 |
| [`jtcps1`](cores/cps1/README.md) | [33](doc/game_list.md#cps1) | Capcom, 1988–1996 — JOTEGO port | 2026-08-08 |
| [`jtcps15`](cores/cps15/README.md) | [6](doc/game_list.md#cps15) | Capcom, 1992–1994 — JOTEGO port | 2026-08-08 |
| [`jtcps2`](cores/cps2/README.md) | [44](doc/game_list.md#cps2) | Capcom, 1993–2004 — JOTEGO port | 2026-08-08 |
| [`jtdd`](cores/dd/README.md) | [1](doc/game_list.md#dd) | Technos Japan (Taito license), 1987 — JOTEGO port | 2026-08-08 |
| [`jtdd2`](cores/dd2/README.md) | [1](doc/game_list.md#dd2) | Technos Japan, 1988 — JOTEGO port | 2026-08-08 |
| [`jtddrbl`](cores/ddrbl/) | [1](doc/game_list.md#ddrbl) | Konami, 1986 — JOTEGO port | 2026-08-08 |
| [`jtexed`](cores/exed/README.md) | [1](doc/game_list.md#exed) | Capcom, 1985 — JOTEGO port | 2026-08-08 |
| [`jtflane`](cores/flane/README.md) | [1](doc/game_list.md#flane) | Konami, 1987 — JOTEGO port | 2026-08-08 |
| [`jtflstory`](cores/flstory/README.md) | [7](doc/game_list.md#flstory) | Taito, 1984–1986 — JOTEGO port | 2026-08-08 |
| [`jtfround`](cores/fround/README.md) | [1](doc/game_list.md#fround) | Konami, 1988 — JOTEGO port | 2026-08-08 |
| [`jtgaiden`](cores/gaiden/README.md) | [3](doc/game_list.md#gaiden) | Tecmo, 1988–1991 — JOTEGO port | 2026-08-08 |
| [`jtgng`](cores/gng/README.md) | [1](doc/game_list.md#gng) | Capcom, 1985 — JOTEGO port | 2026-08-08 |
| [`jtgunsmk`](cores/gunsmk/README.md) | [1](doc/game_list.md#gunsmk) | Capcom, 1985 — JOTEGO port | 2026-08-08 |
| [`jtkarnov`](cores/karnov/) | [3](doc/game_list.md#karnov) | Data East Corporation, 1987–1988 — JOTEGO port | 2026-08-08 |
| [`jtkchamp`](cores/kchamp/README.md) | [2](doc/game_list.md#kchamp) | Data East USA, 1984 — JOTEGO port | 2026-08-08 |
| [`jtkicker`](cores/kicker/README.md) | [1](doc/game_list.md#kicker) | Konami, 1985 — JOTEGO port | 2026-08-08 |
| [`jtkiwi`](cores/kiwi/README.md) | [7](doc/game_list.md#kiwi) | Taito Corporation Japan, 1987–1989 — JOTEGO port | 2026-08-08 |
| [`jtkunio`](cores/kunio/README.md) | [1](doc/game_list.md#kunio) | Technos Japan (Taito America license), 1986 — JOTEGO port | 2026-08-08 |
| [`jtlabrun`](cores/labrun/README.md) | [1](doc/game_list.md#labrun) | Konami, 1987 — JOTEGO port | 2026-08-08 |
| [`jtmidres`](cores/midres/) | [1](doc/game_list.md#midres) | Data East Corporation, 1989 — JOTEGO port | 2026-08-08 |
| [`jtmikie`](cores/mikie/README.md) | [1](doc/game_list.md#mikie) | Konami, 1984 — JOTEGO port | 2026-08-08 |
| [`jtmx5k`](cores/mx5k/README.md) | [1](doc/game_list.md#mx5k) | Konami, 1987 — JOTEGO port | 2026-08-08 |
| [`jtninja`](cores/ninja/README.md) | [2](doc/game_list.md#ninja) | Data East Corporation, 1987–1988 — JOTEGO port | 2026-08-08 |
| [`jtoutrun`](cores/outrun/README.md) | [2](doc/game_list.md#outrun) | Sega, 1986–1989 — JOTEGO port | 2026-08-08 |
| [`jtpaclan`](cores/paclan/) | [1](doc/game_list.md#paclan) | Namco, 1984 — JOTEGO port | 2026-08-08 |
| [`jtpang`](cores/pang/README.md) | [13](doc/game_list.md#pang) | Capcom, 1988–1991 — JOTEGO port | 2026-08-08 |
| [`jtparoda`](cores/paroda/) | [2](doc/game_list.md#paroda) | Konami, 1990 — JOTEGO port | 2026-08-08 |
| [`jtpinpon`](cores/pinpon/README.md) | [1](doc/game_list.md#pinpon) | Konami, 1985 — JOTEGO port | 2026-08-08 |
| [`jtrastan`](cores/rastan/README.md) | [4](doc/game_list.md#rastan) | Taito Corporation, 1987–1988 — JOTEGO port | 2026-08-08 |
| [`jtriders`](cores/riders/README.md) | [4](doc/game_list.md#riders) | Konami, 1990–1991 — JOTEGO port | 2026-08-08 |
| [`jtroadf`](cores/roadf/README.md) | [2](doc/game_list.md#roadf) | Konami, 1984 — JOTEGO port | 2026-08-08 |
| [`jtroc`](cores/roc/README.md) | [1](doc/game_list.md#roc) | Konami, 1983 — JOTEGO port | 2026-08-08 |
| [`jtrumble`](cores/rumble/README.md) | [1](doc/game_list.md#rumble) | Capcom, 1986 — JOTEGO port | 2026-08-08 |
| [`jts16`](cores/s16/README.md) | [19](doc/game_list.md#s16) | Sega, 1985–1988 — JOTEGO port | 2026-08-08 |
| [`jts16b`](cores/s16b/README.md) | [38](doc/game_list.md#s16b) | Sega, 1986–2008 — JOTEGO port | 2026-08-08 |
| [`jts18`](cores/s18/README.md) | [11](doc/game_list.md#s18) | Sega, 1989–2021 — JOTEGO port | 2026-08-08 |
| [`jtsarms`](cores/sarms/README.md) | [1](doc/game_list.md#sarms) | Capcom, 1986 — JOTEGO port | 2026-08-08 |
| [`jtsbaskt`](cores/sbaskt/README.md) | [1](doc/game_list.md#sbaskt) | Konami, 1984 — JOTEGO port | 2026-08-08 |
| [`jtsectnz`](cores/sectnz/README.md) | [2](doc/game_list.md#sectnz) | Capcom, 1985–1986 — JOTEGO port | 2026-08-08 |
| [`jtsf`](cores/sf/README.md) | [1](doc/game_list.md#sf) | Capcom, 1987 — JOTEGO port | 2026-08-08 |
| [`jtshanon`](cores/shanon/README.md) | [1](doc/game_list.md#shanon) | Sega, 1987 — JOTEGO port | 2026-08-08 |
| [`jtshouse`](cores/shouse/README.md) | [19](doc/game_list.md#shouse) | Namco, 1987–1991 — JOTEGO port | 2026-08-08 |
| [`jtsimson`](cores/simson/README.md) | [3](doc/game_list.md#simson) | Konami, 1991 — JOTEGO port | 2026-08-08 |
| [`jtslyspy`](cores/slyspy/) | [2](doc/game_list.md#slyspy) | Data East Corporation, 1989–1990 — JOTEGO port | 2026-08-08 |
| [`jtthundr`](cores/thundr/) | [8](doc/game_list.md#thundr) | Namco, 1985–1987 — JOTEGO port | 2026-08-08 |
| [`jttmnt`](cores/tmnt/README.md) | [4](doc/game_list.md#tmnt) | Konami, 1989–1991 — JOTEGO port | 2026-08-08 |
| [`jttoki`](cores/toki/README.md) | [2](doc/game_list.md#toki) | TAD Corporation, 1988–1989 — JOTEGO port | 2026-08-08 |
| [`jttora`](cores/tora/README.md) | [2](doc/game_list.md#tora) | Capcom, 1987–1988 — JOTEGO port | 2026-08-08 |
| [`jttrack`](cores/track/README.md) | [1](doc/game_list.md#track) | Konami, 1983 — JOTEGO port | 2026-08-08 |
| [`jttrojan`](cores/trojan/README.md) | [2](doc/game_list.md#trojan) | Capcom, 1986–1987 — JOTEGO port | 2026-08-08 |
| [`jttwin16`](cores/twin16/README.md) | [4](doc/game_list.md#twin16) | Konami, 1987–1989 — JOTEGO port | 2026-08-08 |
| [`jtvigil`](cores/vigil/README.md) | [1](doc/game_list.md#vigil) | Irem, 1988 — JOTEGO port | 2026-08-08 |
| [`jtwc`](cores/wc/README.md) | [2](doc/game_list.md#wc) | Tehkan, 1985 — JOTEGO port | 2026-08-08 |
| [`jtwwfss`](cores/wwfss/README.md) | [1](doc/game_list.md#wwfss) | Technos Japan, 1989 — JOTEGO port | 2026-08-08 |
| [`jtyiear`](cores/yiear/README.md) | [1](doc/game_list.md#yiear) | Konami, 1985 — JOTEGO port | 2026-08-08 |
| [`moomesa`](cores/moomesa/) | [2](doc/game_list.md#moomesa) | Konami, 1992 — jlrh port | 2026-08-08 |
| [`mystston`](cores/mystston/README.md) | [1](doc/game_list.md#mystston) | Technos Japan, 1984 | 2026-08-08 |
| [`opwolf`](cores/opwolf/) | [1](doc/game_list.md#opwolf) | Taito, 1987 — jlrh port | 2026-08-08 |
| [`squash`](cores/squash/) | [1](doc/game_list.md#squash) | Gaelco, 1992 — jlrh port | 2026-08-08 |
| [`thoop`](cores/thoop/) | [1](doc/game_list.md#thoop) | Gaelco, 1992 — jlrh port | 2026-08-08 |
| [`thoop2`](cores/thoop2/) | [1](doc/game_list.md#thoop2) | Gaelco, 1994 — jlrh port | 2026-08-08 |
| [`wrally`](cores/wrally/) | [1](doc/game_list.md#wrally) | Gaelco, 1993 — jlrh port | 2026-08-08 |
| [`wrally2`](cores/wrally2/) | [1](doc/game_list.md#wrally2) | Gaelco, 1995 — jlrh port | 2026-08-08 |

*This table is updated as cores are added — see each core's own README for build/hardware notes.*

## Building

Cores follow [jotego/jtcores](https://github.com/jotego/jtcores)' own JTFRAME conventions and
tooling (`jtframe`, `jtutil`, `jtsim`, `jtcore`) — just with an added neptUNO+ target. Every step
below can run as a plain command against a local toolchain, or in Docker to avoid installing one;
only synthesis (Quartus) *requires* Docker, since Quartus itself isn't something these images can
legally redistribute for local install.

All commands below were verified end to end against `1942`/`mystston` in this checkout. Two
environment gotchas apply throughout, both worth knowing before running any of them:

- **A space anywhere in the repo's own path (e.g. `.../SSD 2TB/...`) breaks jotego's native shell
  tooling** (`setprj.sh`, the `bin/jtframe` wrapper, etc. — they don't quote `$JTROOT`/`$JTFRAME`
  internally, so a path containing a space splits into multiple words and every `[ -e $BIN ]`-style
  test breaks). This alone is a strong argument for Docker over local commands here: bind-mounting
  to a fixed no-space container path (`/build`) sidesteps it entirely.
- **Docker containers must run as the host UID/GID** (`--user "$(id -u):$(id -g)"`) — without it,
  the bind-mounted repo comes up root-owned inside the container, git refuses to touch it
  ("dubious ownership"), and `jtframe` (which shells out to `git` for commit-hash macros) panics.

### Prerequisites: compiling `jtframe` / `jtutil`

`jtframe` (drives `.mra` generation, target file generation, etc.) and `jtutil` (macro/config
plumbing `jtcore` shells out to) are Go CLIs built from source, once, before anything else —
**`CGO_ENABLED=0` is required, not optional**: a normally-linked binary pulls in the host's glibc,
which is newer than what `jotego/jtcore13`'s older base image ships (confirmed directly: a
non-static build fails inside that image with `version 'GLIBC_2.34' not found`; `jotego/simulator`
happens to tolerate it, `jotego/jtcore13` does not — don't rely on that inconsistency, always build
static):

```sh
cd modules/jtframe/src/jtframe && CGO_ENABLED=0 go build .
cd modules/jtframe/src/jtutil  && CGO_ENABLED=0 go build .
```

Rebuild them (same command) whenever `modules/jtframe` is updated — both `bin/jtframe`/`bin/jtutil`
themselves and this project's own tooling check `.go` mtimes against the binary and rebuild
automatically, but a stale manually-built binary won't self-detect that.

### 1. Lint

Don't hand-roll a `verilator` invocation — a core's real macro set (`JTFRAME_MEMGEN`, per-target
clock timing, etc.) and its generated `mem_ports.inc`/`jtframe_game_ports.inc` includes only exist
once JTFRAME's own environment is initialized, so `lint-one.sh` (which does that via `jtframe
cfgstr`/`jtframe mem` before invoking Verilator) is the only supported entry point:

```sh
source modules/jtframe/bin/setprj.sh   # sets JTROOT/JTFRAME/CORES/MODULES/JTBIN + PATH
lint-one.sh <core>
```

Needs a local `verilator` install. **Docker** (no local Verilator needed) — same script, run
inside `jotego/simulator` with the whole repo bind-mounted so `setprj.sh` resolves paths correctly:

```sh
docker run --rm --entrypoint bash --user "$(id -u):$(id -g)" \
  -v "$PWD":/build -w /build \
  jotego/simulator -c 'source /build/modules/jtframe/bin/setprj.sh && lint-one.sh <core>'
```

`jotego/simulator` is jotego's own CI image — Verilator + Icarus Verilog on top of
`jotego/jtcore-base` (see JTFRAME's [`devops/linter.df`](modules/jtframe/devops/linter.df)).

### 2. Simulate (`jtsim`)

Same environment requirement as lint, plus `jtsim` must be run from inside the specific ROM set's
own `ver/<setname>/` folder (not the core's root), and needs the real MAME ROM at
`$JTROOT/rom/<setname>.rom` — it fails cleanly with a clear error if that ROM isn't present, which
is expected (ROMs are copyrighted, never bundled in this repo):

```sh
source modules/jtframe/bin/setprj.sh
cd $CORES/<core>/ver/<setname>
jtsim -mister   # or -neptunoplus, -mist, ...
```

**Docker**, same pattern as lint:

```sh
docker run --rm --entrypoint bash --user "$(id -u):$(id -g)" \
  -v "$PWD":/build -w /build \
  jotego/simulator -c 'source /build/modules/jtframe/bin/setprj.sh && cd $CORES/<core>/ver/<setname> && jtsim -mister'
```

### 3. Generate `.mra` / `.arc` from `cfg/mame2mra.toml`

`.mra` comes straight from the `jtframe` binary built above, reading each core's
`cfg/mame2mra.toml` (plus MAME's XML database for the referenced driver/sets). `--skipROM` skips
packing the actual MAME ROM data (needs real ROM zips under `$JTROOT/rom/`, same as `jtsim` above)
and just emits the `.mra` XML — drop it once you do have the ROMs available:

```sh
source modules/jtframe/bin/setprj.sh
jtframe mra <core> --verbose --skipROM
```

Same via Docker (`jotego/simulator`, same `--user`/bind-mount pattern as lint/simulate above).
Output lands in `$JTROOT/release/mra/` (jotego's own default — note this project's *own* published
releases live in `releases/mra/`, plural, one level up in naming; nothing copies between the two
automatically, this is only the raw tool's own output location).

`.arc` (the MiST-family equivalent) is then derived from that `.mra` by
[mist-devel/mra-tools-c](https://github.com/mist-devel/mra-tools-c)'s own `mra` CLI — the same
tool jotego's own release process uses (see JTFRAME's `bin/jtbin2sd`). Build it once from the
`modules/mra-tools-c` submodule:

```sh
cd modules/mra-tools-c && make -j
```

then, per ROM set:

```sh
modules/mra-tools-c/mra -z <romset>.zip -O releases/arc -A -s -a "<display name>" <core>.mra
```

### 4. Synthesize

FPGA image (`.rbf`) synthesis runs Quartus inside jotego's own per-platform Docker images —
Quartus isn't installed locally at all:

| Target | Image |
|---|---|
| MiSTer | `jotego/jtcore24` |
| MiST / SiDi / neptUNO+ | `jotego/jtcore13` |
| Pocket | `jotego/jtcore20` |

```sh
docker run --rm --entrypoint "" --user "$(id -u):$(id -g)" \
  -v "$PWD/modules":/jtcores:ro \
  -v /path/to/build:/build \
  -v "$PWD/cores/<core>/cfg":/core_cfg:ro \
  -v "$PWD/cores/<core>/hdl":/core_hdl:ro \
  jotego/jtcore13 bash -c '
    mkdir -p /build/modules /build/cores/<core>/cfg /build/cores/<core>/hdl
    cp -rp /jtcores/. /build/modules/
    cp -r /core_cfg/. /build/cores/<core>/cfg/
    cp -r /core_hdl/. /build/cores/<core>/hdl/
    cd /build && git init -q && git -c user.email=a@a -c user.name=a commit --allow-empty -q -m x
    export JTROOT=/build JTFRAME=/build/modules/jtframe CORES=/build/cores MODULES=/build/modules
    export PATH=$PATH:/build/modules/jtframe/bin
    jtcore <core> -neptunoplus --nolinter
  '
```

Output lands in `/build/release/<target>/`. A core with a `syn/` override needs the matching
`-v ...cores/<core>/syn:/core_syn:ro` mount too, copied into `/build/cores/<core>/syn/` before
`jtcore` runs — same idea as the `hdl` mount above.

## Credits

- [Jose Tejada (jotego)](https://github.com/jotego) — [JTFRAME](https://github.com/jotego/jtframe)
  and [jtcores](https://github.com/jotego/jtcores), the framework and core collection this project
  builds on.
- [somhi](https://github.com/somhi) — reference work on JTFRAME-based neptUNO+ targets, used
  alongside other public sources when building this project's own neptUNO+ target.
- [jlrh](https://github.com/jlrh) — core development.
- The MiSTer/MiST/SiDi open-source FPGA arcade community.
