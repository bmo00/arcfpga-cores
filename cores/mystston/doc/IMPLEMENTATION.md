# Mysterious Stones — FPGA Implementation Notes

How the real hardware (see [HARDWARE.md](HARDWARE.md), [MEMORY_MAP.md](MEMORY_MAP.md)) maps onto
this JTFRAME-based core. Source: `cfg/macros.def`, `cfg/mem.yaml`, `cfg/files.yaml`, and the HDL
itself.

## Core structure

| File | Description |
|------|--------------|
| `hdl/jtmystston_game.v` | Top-level: wires CPU, sound, video subsystems to the JTFRAME interface |
| `hdl/mystston_main.v` | 6502 memory map, address decode, I/O, interrupts |
| `hdl/mystston_sound.v` | Dual AY8910 interface, BC1/BDIR select-latch emulation |
| `hdl/mystston_video.v` | Video pipeline: BG tilemap, sprites, FG text layer, timing |
| `hdl/mystston_colmix.v` | Palette RAM + PROM mix, priority mux, DAC output |
| `hdl/mystston_obj.v` | Sprite decoder and compositor |
| `hdl/mystston_scroll.v` | Background scroll register and page select |

## CPU: jt65c02

The core uses **`jt65c02`** (from `modules/jt680x` — the same CPU jotego's own `kunio` core uses
for *Renegade*), **not** a transistor-netlist 6502 model that never got past the reset-vector
fetch in simulation for this core.

Consequences for anyone touching `mystston_main.v` or `jtmystston_game.v`:

- `jt65c02` has **no `rdy` pin**. Wait states while the ROM SDRAM bus is busy are handled by
  `cfg/mem.yaml`'s `gate: [maincpu]` mechanism, which pauses `cen_cpu` while
  `maincpu_cs & ~maincpu_ok` — not by a manual ready/wait signal.
- `jt65c02`'s `cen` must run at **4x** the real bus rate: `cfg/mem.yaml` declares `freq: 6000000`
  for `cen_cpu`, not the literal 1.5MHz real CPU rate. Running it at 1.5MHz previously caused a
  real, hardware-observed bug — the CPU advanced twice per intended step, corrupting multi-byte
  SDRAM reads mid-request (seen as flashing palette colors on real MiSTer hardware).
- `irq` is level-sensitive and **active-high** (no inversion needed, unlike the old CPU module's
  wiring): `assign irq = irq_pending & dip_pause;`.
- `nmi` is **edge-sensitive and active-high**: `assign nmi = ~coin[0] | ~coin[1];` — matches the
  real hardware's coin-insert NMI line found on the schematic (see
  [HARDWARE.md](HARDWARE.md#cpu)).
- `dip_pause` gates the IRQ line directly and must **not** be inverted: it is `1` during normal
  operation and `0` while paused (jtframe convention, confirmed against every other jtcores core
  that gates an IRQ with it). Inverting it blocks IRQs whenever the game is *not* paused — i.e.
  always at boot — which is what silenced this core's interrupt-driven sound dispatch until pause
  was pressed once, before this was fixed.

## Clocks

Declared in `cfg/mem.yaml`'s `clocks: clk24` domain:

| Enable | Freq | Notes |
|---|---|---|
| `cen_cpu` | 6MHz | 4x the real 1.5MHz CPU rate, per `jt65c02`'s own requirement. Gated by `[maincpu]`. |
| `cen_ay` | 1.5MHz | Real AY8910 rate — independent of `cen_cpu`, since `jt65c02` (unlike the old CPU module) doesn't need an internal /2 division exposed. |

`pxl_cen`/`pxl2_cen` are **not** declared in `mem.yaml` — `JTFRAME_PXLCLK=6` in `cfg/macros.def`
already makes JTFRAME generate and wire them in as game-module inputs on its own. Declaring them
again in `mem.yaml` produces a duplicate-pin-connection Verilator error in the generated
`jtmystston_game_sdram.v` wrapper.

All CPU/sound submodules (`u_main`, `u_sound`) run on `clk24`, matching the domain `cen_cpu`/
`cen_ay` are declared under — running them on plain `clk` while consuming a `clk24`-domain enable
makes each enable pulse last two `clk` cycles, with the same CPU-double-stepping consequence
described above.

## SDRAM / BRAM layout

| Bank | Bus | Width | Content | Start (`macros.def`) |
|---|---|---|---|---|
| 0 | `maincpu` | 8-bit | Program ROM (`$4000`-`$FFFF`, padded to the full `$10000` CPU space) | — |
| 1 | `gfx1` | 16-bit | `fgtiles_sprites` graphics ROM (48KB), shared by the FG tilemap and sprite layer | `JTFRAME_BA1_START=0x10000` |
| 2 | `gfx2` | 16-bit | `bgtiles` graphics ROM (48KB) | `JTFRAME_BA2_START=0x1c000` |
| BRAM | `proms` | 8-bit | Color PROM (32B) — too small for its own SDRAM bank; routed through `jtframe_prom` with a plain 1-cycle-latency read, no cs/ok handshake | `JTFRAME_PROM_START=0x28000` |
| BRAM | `workram`/`videoram`/`spriteram`/`paletteram` | 8-bit | CPU-side work/video/sprite/palette RAM | — |

Bank 0's program-ROM slot is padded out to the **full** `$10000`-byte CPU address space (not just
the `$C000` bytes of real ROM content) — `mame2mra.toml`'s ROM merge does this padding, and every
later bank's start offset assumes it. Getting this wrong previously put every later bank `$4000`
bytes too early, silently reading CPU high addresses (including the reset vector at `$FFFC`) out
of `gfx1`'s tile data instead of the real program ROM.

## JTFRAME modules reused

From `cfg/files.yaml`:

| Module | Source | Function |
|---|---|---|
| `jt65c02` | `modules/jt680x` | Main CPU |
| `jt49` | `modules/jt49` | AY8910 sound synthesis (both PSGs) — note: resolves to `modules/jt49/hdl/jt49.v`, not `modules/jt12/jt49/`, per `files.yaml`'s bare `jt49:` key |
| `jtframe_vtimer` | jtframe (video) | Video timing generator |
| `jtframe_blank` | jtframe (video) | Blanking generator |
| `jtframe_ram` | jtframe (ram) | Work/video/sprite/palette RAM |
| `jtframe_prom` | jtframe (ram) | Color PROM BRAM |


## Build-time macros (`cfg/macros.def`)

| Macro | Value | Why |
|---|---|---|
| `GAMETOP` | `jtmystston_game_sdram` | Must be set explicitly: since `mem.yaml` is present, jtframe's auto-generated SDRAM wrapper hardcodes a `jt`-prefixed name that won't match the bare `CORENAME`-derived default. |
| `JTFRAME_WIDTH`/`HEIGHT` | 256 / 240 | Active video resolution |
| `JTFRAME_VERTICAL` | set | Cabinet is vertically mounted |
| `JTFRAME_PXLCLK` | 6 | 6MHz pixel clock (master/2) |
| `JTFRAME_BUTTONS` | 2 | Fire + Kick |

## Not modeled (by design)

These real-hardware facts have no FPGA-core equivalent and aren't expected to need one:

- NE555 power-on reset generator + manual reset button — jtframe's own reset generation is used
  instead (standard jtframe convention).
- The raw-CPU-bus test/ICE header (`CAD*`/`CDB*` nets) — factory debug connector, not part of
  normal game operation.
- Discrete coin-switch debounce (2SC1075 transistors + NE555 monostables) and control-line RC
  filtering — the FPGA core synchronizes and edge-detects these digitally instead.
- The exact resistor-ladder DAC transistor network — reproduced functionally (3-3-2 RGB) rather
  than transistor-for-transistor.

## Open / low-confidence areas

- **Layer priority / color-select PALs**: real hardware very likely decides sprite/background
  priority inside two PAL16R4 + one PAL10L8 chips (see [HARDWARE.md](HARDWARE.md#video)). Their
  fuse equations aren't dumped for the parent board, so the FPGA core's priority order
  (foreground > sprites > background, in `mystston_colmix.v`) was derived from MAME driver source
  and confirmed against hardware-monitor testing instead — it has not been, and likely cannot be,
  cross-checked against the real PALs' actual logic.
- **`myststonoi` (Itisa PCB) PAL dumps**: MAME's romset for this clone includes PAL equation dumps
  not used by any of the three sets' driver emulation (all three report `status: good` without
  them). Not modeled in this core; see [HISTORY.md](HISTORY.md#versions--romsets).
