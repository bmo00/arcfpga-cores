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

All FSM state `localparam`s in this core use a single `S_` prefix (`mystston_obj.v`,
`mystston_scroll.v`, `mystston_video.v`'s foreground-tile fetcher) — an earlier version of
`mystston_video.v` used `F_` for that FSM alone; unified to `S_` for consistency across the core.

## CPU: jt65c02

The core uses **`jt65c02`** (from `modules/jt680x`), **not** a transistor-netlist 6502 model.

Consequences for anyone touching `mystston_main.v` or `jtmystston_game.v`:

- `jt65c02` has **no `rdy` pin**. Wait states while the ROM SDRAM bus is busy are handled by
  `cfg/mem.yaml`'s `gate: [maincpu]` mechanism, which pauses `cen_cpu` while
  `maincpu_cs & ~maincpu_ok` — not by a manual ready/wait signal.
- `jt65c02`'s `cen` must run at **4x** the real bus rate: `cfg/mem.yaml` declares `freq: 6000000`
  for `cen_cpu`, not the literal 1.5MHz real CPU rate.
- `irq` is level-sensitive and **active-high**: `assign irq = irq_pending & dip_pause;`.
- `nmi` is **edge-sensitive and active-high**: `assign nmi = ~coin[0] | ~coin[1];` — matches the
  real hardware's coin-insert NMI line found on the schematic (see
  [HARDWARE.md](HARDWARE.md#cpu)).
- `dip_pause` gates the IRQ line directly and must **not** be inverted: it is `1` during normal
  operation and `0` while paused (jtframe convention).

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

## Screen rotation (`dip_flip`)

This core doesn't define `JTFRAME_OSD_FLIP`, so `jtframe_common_ports.inc` declares `dip_flip` as
an **output** on the game module (not an input driven by jtframe_dip.v from the OSD) — the game is
expected to drive it itself, and leaving it unconnected leaves it floating (decoupling MiSTer's
screen-rotation direction from anything meaningful). `jtframe_dip.v` XORs it into that direction:
`rotate <= {dip_flip ^ dipflip_xor, ...}`.

`dip_flip` is **not** tied to this game's own cabinet-flip state (`mystston_main.v`'s `flip`,
which mirrors bg/fg/sprites for the picture itself) — the two are independent concepts, and tying
them together cancels out: `flip=1` rotates the picture content 180° *and* flips the rotation
direction 180°, netting zero visible change when the Flip Screen DIP is toggled. mystston is a
fixed vertical cabinet with no separate cocktail monitor mount to account for, so `dip_flip` is a
plain constant — cabinet-flip is handled entirely inside the core, independent of it.

The constant is `assign dip_flip = 1'b1;`. This core's `dipflip_xor` (from `core_mod`, see the
bitácora below) is `1`, matching its real `ROT270` MAME orientation — `rotate[1] = dip_flip ^
dipflip_xor` needs to come out `0` to match how a `ROT90` core like `1942` behaves with its own
OSD "Rotate screen: Yes" default (confirmed directly on real MiSTer hardware: `dip_flip=1'b0` gave
`rotate[1]=1`, rotating 90° the wrong way — readable only by tilting the screen 90° left).

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
later bank's start offset assumes it.

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

## Implementation log

Issues found and fixed during bring-up of this core. Kept here instead of in the HDL so the
source stays readable; each entry is symptom → cause → fix.

**CPU / clocking**
- Palette colors flashed randomly on real MiSTer hardware. `cen_cpu` was generated at the literal
  1.5MHz real bus rate instead of the 4x rate `jt65c02` requires, so the CPU advanced twice per
  intended step and changed the SDRAM address mid-request, corrupting multi-byte reads. Fixed by
  declaring `cen_cpu` at 6MHz in `cfg/mem.yaml`.
- Same double-stepping symptom reappeared when `u_main`/`u_sound` were clocked from plain `clk`
  while still consuming the `clk24`-domain `cen_cpu`/`cen_ay` enables (each enable pulse then
  lasted two `clk` cycles). Fixed by clocking both submodules from `clk24`.
- Interrupt-driven sound dispatch stayed silent until the OSD pause key was pressed once. Cause:
  `dip_pause` was inverted when gating `irq`; `dip_pause` is `1` during normal operation, so the
  inversion blocked IRQs whenever the game was *not* paused, i.e. always at boot.

**Inputs**
- Movement was erratic (up/down never moved, left/right caught only sometimes). Cause:
  `joystick1`/`joystick2` were inverted assuming an active-high interface, when `coin`/`cab_1p`/
  `joystick` are all active-low (idle=1, pressed=0) at this port.
- "Up" presses registered as "down" and vice versa. Cause: `joystick[3:0]` is ordered
  up/down/left/right, but MAME's IN0/IN1 expect the down/up bits swapped relative to that; an
  earlier version copied them straight across.
- Coin insert did nothing after the first credit. Cause: the NMI line was built from
  `coin[0]|coin[1]` assuming an active-high `coin[]`; since both slots idle at 1, that OR was
  permanently stuck high from power-on, so `jt65c02` only ever saw one spurious edge at boot. Fixed
  by inverting `coin[]` before the NMI OR (matches jt65c02's edge-sensitive, active-high `nmi`).

**Video**
- BG, FG, and sprites were uniformly displaced by about 9 pixels relative to
  MAME (perceived as horizontal because the cabinet is `ROT270`). Cause:
  `target_line_full` rebased MAME's absolute visible raster range `8..247`
  to `0..239` before all three renderers performed their tile/sprite lookup.
  MAME's tilemaps instead draw in the full 256-line screen coordinate space;
  with flip enabled, it mirrors around 255, not 239. Fixed by preparing
  `vrender-1` (the physical line being displayed), retaining only `8..247`,
  and using `255-target_line` for flipped BG/FG lookup. A fresh Verilator
  build moved the final rotated frame by exactly 9 pixels; its high-score-box
  edge now lands at x=18, the same coordinate as a freshly captured MAME
  reference frame.
- **[empirical, pending hardware re-confirmation]** On real MiSTer hardware (post
  the displacement fix above), a couple of fixed horizontal raster lines near
  the top of the screen flicker — visible on the title screen (base of the
  "MYSTERIOUS" logo lettering and the brick tiles on those same lines) — but
  never on the sprite layer, confirmed by moving the player sprite over the
  affected lines with no effect on it. Suspected cause: `bg_videoram_shadow`/
  `fg_videoram_shadow` (`mystston_scroll.v`/`mystston_video.v`) are written by
  a plain `always @(posedge clk) if (cpu_videoram_we) ... <= ...` snoop off
  the CPU bus and read back combinationally-addressed-but-clocked by each
  layer's own tile fetcher, on the same clock domain, with no dual-port
  memory and no explicit handling for the CPU writing the exact address a
  fetch is reading on the same edge — a case that can plausibly happen given
  mystston's own scanline-interrupt handler (every 16 lines) writes videoram
  fairly often. Read-during-write collision behavior for inferred BRAM isn't
  guaranteed to match between Verilator (where this was never observed) and
  Quartus, which would explain why sprites (much less frequently written,
  smaller RAM, lower collision odds) don't show it while bg/fg do. Fixed by
  adding explicit forwarding (`code_lo_rd`/`code_hi_rd`,
  `fg_code_lo_rd`/`fg_code_hi_rd`): compare the CPU's write address against
  the fetcher's read address every cycle and bypass the array with the
  incoming write data on a match, removing the dependency on the memory's own
  collision behavior entirely. Verified as a pixel-exact no-op in simulation
  (expected, since Verilator's own semantics weren't the problem); **not yet
  confirmed to fix the actual flicker on real hardware**.
- On MiSTer/HDMI the picture was rotated 180° from correct with the Flip Screen DIP at its normal
  Off default, only looking right with the DIP set to On (the opposite of MAME). Two independent
  causes, found and fixed in sequence:
  1. `jtmystston_game.v` never drove jtframe's `dip_flip` output (needed because this core doesn't
     define `JTFRAME_OSD_FLIP`), leaving it floating and decoupling MiSTer's screen-rotation
     direction from anything meaningful.
  2. The real fix for the rotation *direction* itself lives outside this core, in the MRA-generation
     tooling: the synthesized `custom.xml` hardcoded `rotate="90"` for every vertical-cabinet game,
     when mystston is actually `ROT270` per its real MAME driver (`GAME(...,ROT270,...)` in
     `mystston.cpp`) — the board-spec metadata this tooling worked from only ever recorded
     "vertical"/"horizontal" orientation, losing the 90-vs-270 distinction entirely. That wrong
     `rotate="90"` silently overwrote the real `mame.xml`'s correct `rotate="270"` once jtframe
     merges the two (`mame.xml` then `custom.xml`, last one wins for a given machine name), leaving
     `COREMOD_XORFLIP` unset in the generated `.mra`'s `core_mod` byte. Fixed by reading the precise
     rotation degree straight from the real MAME XML instead of guessing it from the orientation
     string. `core_mod` is loaded by MiSTer from the `.mra` at runtime, not synthesized into the
     `.rbf`, so this needed a fresh MRA Build + ROM Prep, not a Quartus rebuild.
  - A first attempt at fix #1 (`assign dip_flip = flip;`, mirroring `cores/1942/hdl/jt1942_game.v`'s
    `assign dip_flip = ... ^ flip;`) turned out to be wrong on its own: `rotate[1] = dip_flip ^
    dipflip_xor` changes MiSTer's rotation direction by 180° when `dip_flip` toggles, and this
    game's own `flip` *also* mirrors the picture content by 180° when it toggles — tying the two
    together makes them cancel exactly (180°+180°=360°), so the Flip Screen DIP had *zero* visible
    effect on any layer once fix #2 corrected the base rotation direction. `dip_flip` and cabinet
    flip are independent concepts; mystston is a fixed vertical cabinet (no separate cocktail
    monitor mount), so `dip_flip` became a plain constant, decoupled from cabinet flip entirely.
  - The constant's own value needed one more correction after real-hardware testing:
    `assign dip_flip = 1'b0;` gave `rotate[1] = 0^1 = 1` (`dipflip_xor=1` from fix #2's real
    `ROT270`) — MiSTer rotated the picture 90° the wrong way, only readable by tilting the screen
    90° left, unlike `1942` (a real, working `ROT90` core) which displays correctly with its OSD's
    default "Rotate screen: Yes". Fixed by `assign dip_flip = 1'b1;` instead, giving
    `rotate[1] = 1^1 = 0` — the direction that actually matches `1942`'s own working behavior.
- With the base rotation direction fixed (above), the cabinet's own **Flip Screen DIP** (unrelated
  to `dip_flip`/screen rotation) showed the opposite of MAME on real hardware: DIP Off displayed the
  180°-mirrored picture, DIP On displayed correctly — backwards. The DIP's own bit position (13),
  DSW1-vs-DSW0 byte order, and the `flip = video_control[7] ^ dsw1_bit5` XOR structure are all
  independently verified correct against MAME (matching `mystston.cpp`'s own formula exactly, and
  cross-checked via Lives/Coin A/B defaults decoding correctly from the same `dipsw` bus) — no root
  cause found for *why* this one bit arrives inverted relative to the MRA's declared value. Fixed
  empirically by inverting just this bit: `assign flip = video_control_r[7] ^ ~dipsw[13];`.
- On MiSTer with OSD "Rotate screen: Yes", the picture displayed as 4:3 landscape instead of a tall
  portrait frame (unlike `1942`, which stays portrait). Cause: `cfg/macros.def`'s `[mister]` section
  declared `JTFRAME_ARX=3`/`ARY=4` assuming those are the *final*, already-portrait values — but
  `jtframe_dip.v`'s own `hdmi_arx`/`hdmi_ary` logic swaps ARX and ARY internally once rotation is
  actually engaged (`swap_ar` is false while rotating, so the ternaries pick the other declared
  value). JTFRAME_ARX/ARY are meant to declare the *pre-rotation* (native/landscape) aspect; the
  framework does the portrait swap itself. Declaring already-swapped values got swapped a second
  time, landing back on landscape. Fixed by swapping the declaration: `JTFRAME_ARX=4`/`ARY=3`
  (matching `1942`'s own `ARX=5`/`ARY=4` pattern — declared "wide" values that become portrait
  once jtframe swaps them for the rotated display).
- With cabinet flip active, the BG and FG/text layers showed mirrored/garbled tiles while sprites
  displayed correctly. Cause: `mystston_video.v` (FG) and `mystston_scroll.v` (BG) reversed the
  horizontal read position *twice* under flip — once when picking which tile to fetch
  (`fg_eff_col`/`eff_col`, combined with the tilemap's own `TILEMAP_SCAN_COLS_FLIP_X` reversal, so
  the two cancelled out into the wrong tile) and again when picking which column within that tile
  to read (`fg_col_idx`/`col_idx`) — while the write position (`fg_dest_x`/`dest_x`) *also* carried
  its own, correct, single reversal. Three reversals instead of one. Fixed by making tile selection
  and within-tile column selection flip-independent, leaving the horizontal mirror entirely to the
  destination-write reversal — matching the single-reversal pattern `mystston_obj.v` already used
  for sprites (whose tile/`code` selection was never flip-dependent to begin with).
- Every color PROM entry displayed as the *previous* entry's color, with the last entry missing
  entirely. Cause: the PROM shadow-capture ramp assumed 1-cycle `proms_addr`→`proms_data` latency;
  the actual latency is 2 cycles here because `proms_addr` is itself a registered output. Fixed by
  indexing the shadow write `idx-2` and running the ramp two extra cycles to flush the last two
  in-flight reads.
- CPU high addresses (including the reset vector at `$FFFC`) silently read tile data instead of
  program ROM. Cause: SDRAM bank 1's start offset assumed the program-ROM bank was only its real
  `$C000` bytes, when `mame2mra.toml`'s ROM merge pads it to the full `$10000` CPU address space.
- Enabling manual H-Offset tuning inside this core's own raw sync timing (instead of leaving
  horizontal CRT centering to jtframe_resync/OSD) shifted the front/back-porch split away from
  spec and broke MiSTer's HDMI scaler lock, even though it looked fine on CRT.

**Sound**
- BC1/BDIR write detection previously relied only on comparing consecutive `snd_sel` values, with
  no guarantee the detected edge lined up with an actual register write that cycle. Fixed by
  gating on `snd_sel_we`, an explicit write-strobe from `mystston_main.v`'s address decoder.

**Build**
- An extra explicit `` `include "mem_ports.inc"`` in `jtmystston_game.v` duplicated the whole port
  list and broke elaboration — `jtframe_game_ports.inc` already includes it under
  `` `ifdef JTFRAME_MEMGEN``. Fixed by keeping a single include.
