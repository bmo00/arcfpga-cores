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

| Core | Parents | Description | FPGA | Last update |
|---|---|---|---|---|
| [`mystston`](cores/mystston/README.md) | Mysterious Stones: Dr. John's Adventure (`mystston`) | Technos Japan, 1984 (board TA-0010) | MiSTer, NeptUNO+ | 2026-07-30 |

*This table is updated as cores are added — see each core's own README for build/hardware notes.*

## Credits

- [Jose Tejada (jotego)](https://github.com/jotego) — [JTFRAME](https://github.com/jotego/jtframe)
  and [jtcores](https://github.com/jotego/jtcores), the framework and core collection this project
  builds on.
- [somhi](https://github.com/somhi) — reference work on JTFRAME-based neptUNO+ targets, used
  alongside other public sources when building this project's own neptUNO+ target.
- The MiSTer/MiST/SiDi open-source FPGA arcade community.
