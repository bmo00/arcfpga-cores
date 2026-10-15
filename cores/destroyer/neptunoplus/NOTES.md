# Porting notes — destroyer → neptUNO+

Imported from [`jlrh/cidelsa-fpga`](https://github.com/jlrh/cidelsa-fpga), commit `4103139c5a0fe46611805c743dca1cdac95a316f`.
Bridged following `doc/porting-a-native-core.md`'s checklist. **Status: bridged and lints clean
(verilator), not yet built with real Quartus (unavailable in this session) or tested on real
hardware.**

## Architecture notes (read before touching this core again)

- **No SDRAM at all.** The 8KB program ROM and 256B NVRAM in `hdl/rtl/cidelsa_machine.v` are both
  on-chip block RAM (`(* ramstyle = "M10K" *)`), loaded directly over `cidelsa_machine`'s own
  `ioctl_rom_we`/`ioctl_rom_addr`/`ioctl_rom_data` ports (no SDRAM controller anywhere in the
  design) — same situation as `mariobros`. `doc/porting-a-native-core.md`'s §2.2 SDRAM-clock golden
  rule is about never *duplicating* a core-owned PLL; there is no core-owned PLL here to duplicate
  either (`cidelsa_machine` only takes plain `clk`/`ce_cpu`/`ce_pix` inputs), so the bridge owning
  the *only* PLL in the design is not an exception to that rule.
- **Upstream is MiSTer-only — no MiST wrapper exists anywhere to clone.** `jlrh/cidelsa-fpga`'s only
  top (`hdl/mister/Destroyer.sv`, module `emu`) uses `hps_io.sv` + the Template_MiSTer `sys/`
  framework, both fundamentally different from MiST's `user_io`/`data_io` SPI protocol.
  `hdl/rtl/cidelsa_machine.v` itself is fully protocol-agnostic (plain `in0`/`in1`/`ef_ext`
  switches, plain `ioctl_rom_we`/`ioctl_rom_addr`/`ioctl_rom_data` download bus, no SPI/HPS ports at
  all), so `neptunoplus/destroyer_neptunoplus.sv` plays the role of a *brand new* MiST-style board
  wrapper, not an adaptation of an existing one — derived by reading the real `Destroyer.sv` at the
  pinned commit and transliterating its `hps_io`-based wiring to this repo's established
  `user_io`/`data_io`/`arcade_inputs`/`mist_dual_video`/`dac` convention.
- **PLL: device-family reimplementation, not a retune.** `hdl/mister/pll.v` instantiates
  `altera_pll` — Intel's fractional-PLL IP for Cyclone V/Arria 10-class devices, tuned for the
  upstream MiSTer board's `5CSEBA6U23I7` (DE10-Nano). NeptUNO+ is Cyclone IV GX, which has no
  `altera_pll` primitive at all. `neptunoplus/pll.v` is a same-named, same-port-list
  (`refclk`/`rst`/`outclk_0`/`locked`) reimplementation using the classic `altpll` megafunction
  instead. The ratio itself needed **no changes**: the pinned file already takes a 50MHz reference
  (MiSTer's `CLK_50M`) and multiplies to 30MHz (`clk0_multiply_by=3`, `clk0_divide_by=5`:
  50 * 3/5 = 30 exactly), and NeptUNO+'s `CLOCK_27[0]` is also a real 50MHz oscillator — same
  situation as `mariobros`'s own pll.v.
- **Real, validated 8-bit-true-color video.** `hdl/rtl/vis_palette.v` outputs genuine 8-bit R/G/B
  (not a packed 3-3-2 like `mariobros`), so `mist_dual_video` is instantiated with
  `COLOR_DEPTH(8)`/`OUT_COLOR_DEPTH(8)` and `r`/`g`/`b` wired straight through, no bit replication.
- **`cidelsa_machine` doesn't expose `hblank`/`vblank` separately, only `de`.** The upstream MiSTer
  wrapper recomputes them from `hcount`/`vcount` thresholds (`hcount>=30 && hcount<324`,
  `vcount>=10 && vcount<304`) — confirmed these are the *exact same* constants
  `hdl/rtl/vis_video_timing.v` itself uses internally (`HBLANK_END`/`HBLANK_START`/
  `VBLANK_END`/`VBLANK_START`) to compute its own `de` output, not independently invented numbers.
  Replicated verbatim in the adapter since `mist_dual_video` needs `HBlank`/`VBlank` as separate
  signals (`USE_BLANKS(1)`).
- **Vertical-cabinet game, no on-FPGA rotation.** Destroyer is a portrait/vertical-cabinet arcade
  game; the upstream MiSTer wrapper does a real per-pixel rotation via `screen_rotate` + a DDRAM
  framebuffer (`MISTER_FB=1`). This repo's SDRAM-less bridge convention has no equivalent —
  `mist_dual_video`'s own `rotate_screen` mode "needs SDRAM connection" per its own port comment, and
  this core has none. Video is passed through raw (`rotate_screen=2'b00`); the `Orientation` OSD
  option only rotates the on-screen menu box itself for a physically-rotated monitor, same as every
  other native bridge in this repo (`mariobros`).
- **Fractional (non-integer) pixel-clock enable, reused verbatim from upstream.** `ce_pix` (5.626MHz)
  and `ce_cpu` (447.375kHz, the CDP1802's real machine-cycle rate = 3.579MHz/8) are both generated
  from `clk_sys`=30MHz via the exact same phase-accumulator the upstream `Destroyer.sv` uses — these
  are the real Destroyer service-manual clocks (validated CPU-OUT-stream-identical-to-MAME upstream,
  per `hdl/README.md`/`hdl/mister/README.md`), not integer divisions of 30MHz. `mist_dual_video`'s
  own `ce_divider` parameter (used for its raw CSync-bypass pixel strobe, not the scandoubler's real
  path — the scandoubler samples `HSync`/`VSync` edges directly regardless of the exact pixel rate)
  can only express an integer ratio; set to `4'd4` (clk/5 ≈ 6MHz) as the closest integer
  approximation to 5.626MHz. This only affects the 15kHz CSync-bypass OSD overlay timing, not the
  scandoubled (31kHz VGA) path most users will actually run — flag if OSD-in-CSync-mode looks
  visually off on real hardware.
- **Two independent coin inputs, not arcade_inputs' merged coin logic.** `cidelsa_machine`'s
  `ef_ext[3]`/`ef_ext[2]` are Coin1/Coin2 as two separate EF lines (see its own header comment), each
  tied 1:1 to a specific controller's joystick bit7 in the upstream wrapper
  (`ef_ext = {joystick_0[7], joystick_1[7], 1'b0, 1'b0}`). `arcade_inputs`' own `COIN1`/`COIN2`
  params OR together *all* joysticks at the same bit index (so setting both to 7 would make
  `controls[4]`/`controls[5]` identical, collapsing the two coin slots into one) — wired
  `ef_ext[3]`/`ef_ext[2]` straight from `joystick_0[7]`/`joystick_1[7]` instead, matching upstream
  exactly (no keyboard fallback for coin, same as upstream). `arcade_inputs` (`COIN1(0)`, disabled)
  is used only for Fire/Left/Right/Start1/Start2, which do get keyboard fallback.
- **DIP switches wired via `"DIP;"`, not a hand-rolled `O`-line** — per
  `doc/porting-a-native-core.md` §2.5. `in1` (the CPU's own `INP2` DIP read, per
  `hdl/mister/Destroyer.sv`'s own comment: "el juego los lee por INP2 (=in1) DIRECTAMENTE") is wired
  straight to `status[23:16]`, no inversion — **confirmed** against
  `../mra/Destroyer (FF, Cidelsa, 1980).mra`, which landed after the initial bridging pass:
  `<switches default="0xd6" base="16">` (four `<dip>` entries — Difficulty/Bonus Life/Lives/Coinage —
  covering bits 0-7 of that base, i.e. `status[23:16]`, not `status[7:0]`). The bridge's own earlier
  `status[7:0]` wiring (written before this `.mra` existed, base assumed as `0`) was corrected to
  match once the real `.mra` confirmed `base="16"`.
- **Reset placed at `status[12]`, not `status[0]`** — deliberately, to stay clear of both the OSD
  options above (bits 8-11) and the DIP switches' real `status[23:16]` range. `mariobros`'s own
  bridge used `T0,Reset` sharing bit 0 with its own base-0 DIP switches (see its `NOTES.md`'s
  DIP-switches section) — not repeated here on purpose, though `mariobros`'s own overlap has not
  itself been confirmed as a real problem on hardware.
- **No hiscore/NVRAM persistence.** `cidelsa_machine`'s 256B NVRAM (`0x2000-0x20FF`) is plain BRAM
  with no external save/load port — unlike `mario_top`'s `hs_*` ports, there's nothing to wire even
  if this repo had a working `data_io`-based hiscore-save precedent yet (it doesn't, see
  `mariobros`'s own NOTES.md). Settings/scores reset every power cycle, same as most straight arcade
  ports in this repo.
- **No pause support.** `cidelsa_machine` exposes no `pause` input at all (unlike `mario_top`), so
  this bridge has no `pause` module instantiation and no "dim video after 10s" option.
- **`hdl/mister/Destroyer.sv`'s own `initial $readmemh("destryer_prog.hex", rom)` synthesis-time ROM
  init is removed via a patch, not worked around.** Two earlier attempts in this same session both
  failed against a real Quartus build:
  1. Assuming Quartus resolves a bare `$readmemh` filename against the project directory with no
     `SEARCH_PATH` needed (based on `hdl/mister/README.md`'s own "el .hex se busca relativo al
     directorio del proyecto" comment) and dropping a dummy placeholder `.hex` straight into
     `neptunoplus/`. Real build: `Error (10054): ... can't open Verilog Design File
     "destryer_prog.hex"`.
  2. Adding `set_global_assignment -name SEARCH_PATH .` to `destroyer_neptunoplus.qsf` on top of
     that placeholder (same mechanism `alpha68k_neptunoplus.qsf`'s own `SEARCH_PATH` lines use for a
     bare `` `include``). Same identical error, completely unchanged — the real giveaway that the
     placeholder file itself was never reaching the build at all, regardless of `SEARCH_PATH`.

  Root cause (found in `arcfpga-ui`'s own source, `src/lib/core-import/nativeWorkspace.ts`): the
  native build's throwaway workspace only stages `neptunoplus/` files matching
  `/\.(qpf|qsf|sdc|v|sv|vhd|qip)$/i` — `.hex` is filtered out entirely, so no `SEARCH_PATH` value
  could ever have found it. **Fixed properly** via
  `neptunoplus/patches/cidelsa_machine-no-synth-readmemh.patch`, which removes the vendored file's
  non-`SIM` `$readmemh` branch outright (the `` `ifdef SIM `` branch, used by `jtsim`, is untouched) —
  see that patch's own entry in `neptunoplus/patches/README.md` for the full reasoning. This is not
  a workaround for the staging-filter bug specifically: the synthesis-time init serves no purpose on
  this platform at all, since `rom` is always fully (re)written by `ioctl_rom_we` before the game
  actually runs, same as every other native/jtframe core here.

## Real-hardware findings (2026-09-03)

- **"Scanlines" rendered twice, second time in place of "Reset" — fixed: a stray `"-;"` sat
  immediately before `"DIP;"` in `CONF_STR`.** `doc/porting-a-native-core.md` §2.5 explicitly warns
  against this exact construct (real-hardware finding on `breakthru`, applied there as a direct
  instruction): a separator right before `"DIP;"` desyncs the OSD firmware's parser, and a
  downstream option renders mangled — matching the earlier `P1DIP;`/bit-collision duplication class
  §2.6 also documents. Missed when this adapter's `CONF_STR` was first written (an oversight, not a
  new finding) — this session's own real-hardware test is what actually surfaced it. Fixed by
  dropping that separator (`"DIP;"` now comes directly after `"Destroyer;;"`, with a `"-;"` only
  *after* it, per the established template).
- **Added "Swap Joysticks" (`status[13]`)**, following `cores/cclimber/hdl/rtl/CClimber_mist.sv`'s
  own `O6,Swap joysticks,Off,On;` → `arcade_inputs`' `.joyswap` port (a vendored MiST core already
  using the exact same `modules/mist-modules/arcade_inputs.v` this bridge does) and a locally-shared
  updated `mariobros` bridge (`OI,Swap Joystick,Off,On;` → `status[18]`, same `.joyswap` port) —
  confirms this is a common, established convention across MiST-sourced cores, not a novel addition.
  `arcade_inputs`' own `.joyswap` port already existed in this adapter's instantiation (previously
  hardwired `1'b0`) — only needed wiring, not a new dependency. Also swapped `ef_ext`'s
  `Coin1`/`Coin2` assignment by the same bit, since those bypass `arcade_inputs` entirely (wired
  directly from `joystick_0[7]`/`joystick_1[7]`, see "Architecture notes" above) — without this, a
  swapped controller's own Coin button would still credit the *other* logical player's coin slot.
  **Not yet re-tested on real hardware** (added in response to the OSD bug report above, in the same
  session).

## "-;before DIP" fix wasn't enough — DIP moved to just before Reset (2026-09-03)

The duplication persisted (last option before "Reset" still rendered twice) even after the fix
above. A working reference bridge for a different core (a locally-shared, independently-built
`mariobros` port) was compared directly: its own `.arc` places DIP-derived options at bits 10-17,
*after* every other declared option, with `"DIP;"` positioned last in `CONF_STR`, right before
`"Reset"` — not first, as this adapter (and `breakthru`/`mariobros`) originally had it. Reordered to
match: every other option now comes first, `"DIP;"` moved to just before the `J1`/`Reset` tail. Bit
assignments (`status[]` positions each option's own letter encodes) are unchanged — only the
string's own component order moved. **Not yet re-verified on real hardware.**

## OSD text was coarse/pixelated vs. a reference bridge — `BIG_OSD` was never set (2026-09-03)

Real-hardware report: this core's OSD menu text renders larger and blockier than a reference
`mariobros` bridge's own. Root cause: `modules/mist-modules/osd.v`'s `BIG_OSD` parameter (default
`1'b0`) picks between an 8-line-tall or 16-line-tall menu font within the *same* fixed 128px-tall
overlay (`OSD_HEIGHT`, `osd.v:41`) — `1'b0` fits fewer, taller/coarser rows; `1'b1` fits twice as
many, finer rows. This adapter's `mist_dual_video` instantiation never set it, defaulting to the
coarse `1'b0` mode. The reference bridge explicitly passes `.BIG_OSD(1'b1)` to its own `mist_video`
instantiation — and its result (confirmed fine/sharp text on real hardware) is the actual evidence
this is the correct setting for this platform's real OSD firmware, not just a guess: the firmware
that renders text into `osd_buffer` over SPI has one fixed row-layout convention, and `BIG_OSD` must
match it on the FPGA side for the two to agree. Added `.BIG_OSD(1'b1)` to this adapter's own
`mist_dual_video` instantiation. **Not yet re-verified on real hardware.**

## Sources

- **Ported from**: `jlrh/cidelsa-fpga` @ `4103139c5a0fe46611805c743dca1cdac95a316f` — see
  `cores.json`'s `external.repo`/`external.commit`.
- **MiST IO-protocol modules**: `modules/mist-modules/` (`user_io.v`/`data_io.v`/`arcade_inputs.v`/
  `mist_dual_video.v`/`dac.vhd`/`osd.v`/`cofi.sv`/`video_cleaner.v`/`rgb2ypbpr.v`/`scandoubler/`) —
  already pinned in this repo at `2dedb5a8171983b8fb3b04eb01aaf9be7a0a325a`, referenced as-is (no
  new vendoring needed).

## Lint

`verilator --lint-only --no-timing --top-module destroyer_neptunoplus`, mirroring `arcfpga-ui`'s own
`nativeLint.ts` methodology (force-compile `destroyer_neptunoplus.sv` as the design top, `-y` search
across `hdl/rtl/` (+ `hdl/rtl/cpu/`) + `modules/mist-modules/` (+ `scandoubler/`), force-include any
file needed only for a module-name-≠-filename lookup): **0 real errors**, only the one expected VHDL
lookup every other bridged core in this repo already documents:

- `Cannot find file containing module: 'dac'` — `dac.vhd` is a VHDL entity Verilator cannot parse;
  `nativeLint.ts` already suppresses exactly this class via its `vhdlModules`/`isSuppressedVhdlModule`
  check (filename-vs-module-name match, case-insensitive).
- The classic `altpll` megafunction `pll.v` instantiates resolves cleanly once
  `modules/jtframe/hdl/ver/altera_mf.v` (jtframe's own Verilator blackbox model for Altera
  megafunctions — the "altpll blackbox-model special case"
  `doc/porting-a-native-core.md` §2 references for `nativeLint.ts`) is force-included alongside
  `--no-timing` (that file needs an explicit timing-mode choice to lint at all under Verilator 5.x).

Only benign `WIDTHEXPAND`/`WIDTHTRUNC` warnings otherwise (mostly pre-existing in vendored
`hdl/rtl/*`/`modules/mist-modules/*`, not introduced here) plus the same `ioctl_addr` 25-vs-27-bit
`WIDTHEXPAND` and `!ioctl_index` (8-bit-to-1-bit) `WIDTHTRUNC` patterns `mariobros`'s own adapter
already has — established idiom in this repo, not a new issue.

## Remaining checklist (doc §6)

- [x] Identify candidate, record `external.repo`/`external.commit`, `framework: "native"` (already
      done at import time, before this session).
- [x] Identify upstream FPGA target (`target_fpgas: ["5CSEBA6U23I7"]` — MiSTer-only upstream, an
      explicit deviation from §1's "prefer MiST" guidance, same class of exception `mariobros`
      already established).
- [x] Read the upstream top-level module's I/O ports (`Destroyer.sv`'s `emu`, hps_io-based) and the
      protocol-agnostic game module (`cidelsa_machine.v`).
- [x] Identify the MiST IO-protocol module source (`modules/mist-modules/`, already pinned).
- [x] Write `neptunoplus/` (`.qpf`/`.qsf`/`.sdc` + adapter).
- [x] Zero bridge-owned *redundant* PLLs — the one PLL this bridge owns is the design's only PLL
      (`cidelsa_machine` has none), not a duplicate of a core-owned one.
- [x] Document deviations/approximations (this file).
- [x] Lint clean (see "Lint" above).
- [x] Remove the vendored synthesis-time `$readmemh` blocker —
      `neptunoplus/patches/cidelsa_machine-no-synth-readmemh.patch` (see "Architecture notes" above).
- [ ] Synthesize with Quartus and check fitter/timing reports — not done, no Quartus available in
      this session.
- [ ] Test on real NeptUNO+ hardware: boot, video, controls, sound, DIP switches, coin1/coin2
      independence.
- [x] Build/land a `.mra` for this core — `cores/destroyer/mra/Destroyer (FF, Cidelsa, 1980).mra`
      landed after the initial bridging pass; `<switches base="16">` confirmed and the adapter's
      `in1` wiring corrected to `status[23:16]` accordingly (see "Architecture notes" above).
- [ ] Update `cores.json`'s `releases.neptunoplus` once a real build lands in
      `cores/destroyer/releases/neptunoplus/`.
