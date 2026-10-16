# Porting notes — mariobros → neptUNO+

Imported from [`MiSTer-devel/Arcade-MarioBros_MiSTer`](https://github.com/MiSTer-devel/Arcade-MarioBros_MiSTer), commit `a934eecfb83a18f68b14c52380f3bfda153dcc99`.
Bridged following `doc/porting-a-native-core.md`'s checklist. **Status: bridged and lints clean
(verilator), not yet built with real Quartus (unavailable in this session) or tested on real
hardware.**

## Architecture notes (read before touching this core again)

- **No SDRAM at all.** Every ROM/RAM in `hdl/` is on-chip block RAM, loaded directly over
  `mario_top`'s own `dn_addr`/`dn_data`/`dn_wr` ports (no SDRAM controller anywhere in the design).
  This is the first native core in this repo without one — `doc/porting-a-native-core.md`'s §2.2
  SDRAM-clock golden rule (and its whole "zero bridge PLLs" framing) is about never *duplicating* a
  core-owned PLL; there is no core-owned PLL here to duplicate, so the bridge owning the *only*
  PLL in the design is not an exception to that rule, just a design with one fewer PLL than usual.
- **Upstream is MiSTer-only — no MiST wrapper exists anywhere to clone.** Every other native core
  bridged so far (pacman/bankpanic/arkanoid/alpha68k/armedf) either vendors the upstream's own
  MiST board wrapper wholesale (pacman: `Pacman_MiST` inside `hdl/Pacman.sv`) or clones one closely.
  `MiSTer-devel/Arcade-MarioBros_MiSTer` has neither — its only top (`Arcade-MarioBros.sv`) uses
  `hps_io.sv`, a fundamentally different protocol. `hdl/rtl/mario_top.v` itself is fully
  protocol-agnostic (plain `dn_addr`/`dn_data`/`dn_wr`, plain switches, no SPI/HPS ports at all), so
  `neptunoplus/mariobros_neptunoplus.sv` plays the role of a *brand new* MiST-style board
  wrapper, not an adaptation of an existing one. It was derived by reading the real
  `Arcade-MarioBros.sv` at the pinned commit (cloned locally, not guessed from a directory listing)
  and transliterating its hps_io-based wiring to this repo's established
  `user_io`/`data_io`/`arcade_inputs`/`mist_dual_video`/`dac` convention (same modules
  pacman/bankpanic/arkanoid/alpha68k/armedf all already use from `modules/mist-modules/`).
- **PLL: device-family reimplementation, not a retune.** `hdl/rtl/pll.v` (+ `pll_0002.v`/`.qip`)
  instantiates `altera_pll` — Intel's fractional-PLL IP for Cyclone V/Arria 10-class devices, tuned
  for the upstream MiSTer board's `5CEBA2F17A7`. NeptUNO+ is Cyclone IV GX, which has no
  `altera_pll` primitive at all. `neptunoplus/pll.v` is a same-named, same-port-list
  (`refclk`/`rst`/`outclk_0`/`locked`) reimplementation using the classic `altpll` megafunction
  instead — same technique as every other core's own `pll.v`/`pll_mist.v`, just crossing a device
  family rather than retuning a reference frequency. The ratio itself needed **no changes at all**:
  the pinned file already takes a 50MHz reference (MiSTer's `CLK_50M`) and multiplies to 48MHz
  (`clk0_multiply_by=24`, `clk0_divide_by=25`), and NeptUNO+'s `CLOCK_27[0]` is also a real 50MHz
  oscillator — the one case so far where the upstream board and NeptUNO+ already agree on the
  reference frequency.
- **Missing vendored dependency, now fixed**: `mario_bram.v`/`mario_roms.v` both instantiate a
  generic `dpram` (VHDL entity, `clock_a`/`clock_b`/`enable_a`/`enable_b`/`wren_a`/`wren_b`/
  `address_a`/`b`/`data_a`/`b`/`q_a`/`b` ports) that was never vendored into `hdl/` — the original
  import only copied the upstream repo's `rtl/` directory, but `dpram.vhd` sits at that repo's own
  **root**, one level up from `rtl/`. Confirmed by cloning the pinned commit and finding it there;
  now vendored as `hdl/rtl/dpram.vhd` (byte-identical to the upstream root file, same commit — a
  completion of the original import, not a new dependency). Its own `intended_device_family =>
  "Cyclone V"` generic (baked into the upstream file's `altsyncram` instantiation) is a harmless
  mismatch, not a blocker — `cores/bankpanic/hdl/rtl/dpram.v` (megawizard-generated) carries the
  exact same string and bankpanic is an already-bridged, real core on this same NeptUNO+ target.
- **Genuine bug in vendored HDL, fixed via `neptunoplus/patches/mario_top-duplicate-i_anlg_vol.patch`**:
  `mario_top.v`'s own `mario_sound` instantiation connects `.I_ANLG_VOL()` twice — once with the
  real `I_ANLG_VOL` signal, then again immediately after with an empty reference. Verilator hard-errors
  on this (`Duplicate pin connection`); Quartus would very likely reject it too. Fixed by dropping
  the redundant empty connection, never by editing `hdl/` in place.
- **`hdl/rtl/dkong3_sub.v` and `hdl/rtl/hiscore.v` are vendored but genuinely unused** — nothing in
  `mario_top`'s own instantiation chain references `dkong3_sub` (dead code, likely a leftover from
  the shared Donkey-Kong-family codebase this core was originally forked from), and this bridge does
  not instantiate `hiscore` (see "What was intentionally left out" below). Neither is listed in
  `mariobros_neptunoplus.qsf`'s source-file list — omitted, not `EXCLUDE`d, since this repo's `.qsf`
  convention is an explicit per-file list, not a directory glob.

## What was intentionally left out — hiscore.dat autosave

`mario_top.v` still exposes `pause`/`hs_address`/`hs_data_in`/`hs_data_out`/`hs_write`/`hs_access`
ports (and `hdl/rtl/hiscore.v`/`pause.v` are vendored, since the upstream repo ships them), but this
bridge does **not** wire up hiscore.dat persistence:

- `hiscore.v`'s own "extract to dump buffer when the OSD menu opens" trigger needs an
  `OSD_STATUS`-equivalent signal. MiSTer's `hps_io.sv` provides one directly; this repo's
  `modules/mist-modules/user_io.v` (the real MiST-devel module, already used by every other bridged
  core here) has no equivalent output at all — confirmed by reading its full port list.
- No other native core bridged in this repo so far wires `hiscore.v` over MiST/`data_io`, so there
  was no local working precedent to follow (`data_io.v` does support the underlying
  `ioctl_upload`/`ioctl_download`/`ioctl_index` mechanism hiscore.v needs, so it's not fundamentally
  blocked — just not yet attempted anywhere in this repo).
- `pause.v` **is** wired (manual pause via joystick button 8, matching upstream's own
  `m_pause = joy_0[8]|joy_1[8]`, plus the "dim video after 10s" option) — that half of `pause.v`'s
  feature set doesn't need `OSD_STATUS` at all, only the "pause when OSD is open" option does
  (hardwired off here).
- `hs_access`/`hs_write` are tied to `1'b0` in the adapter — `mario_main.v`'s hiscore RAM arbitration
  simply never grants the hiscore controller bus access when this is low, so gameplay is completely
  unaffected; the only loss is that high scores don't persist across power cycles.

If a future session wants this, the real path is: find/derive an `OSD_STATUS`-equivalent (e.g. a
`SPI_SS3`-activity heuristic, or extend `user_io.v` itself — check upstream `mist-devel/mist-modules`
history first), then instantiate `hiscore.v` the same way `Arcade-MarioBros.sv` does, feeding it from
`data_io`'s `ioctl_*` bus.

## What was intentionally left out — DIP switches

`mario_top.v`'s `I_DIPSW` input is hardwired to `8'h00`, not wired to an OSD-configurable "DIP;"
CONF_STR line. This matches the **real, shipped** upstream behavior, not a shortcut: the real
`Arcade-MarioBros.sv` has every dip-related CONF_STR line (`O89,Lives`/`OAB,Coin/Credit`/
`OCD,Extra Life`/`OEF,Difficulty`) commented out, and this core's own `.mra` files carry no `<dip>`
entries at all — `sw[0]` never gets written in the real, currently-distributed MiSTer core either,
so it stays at Verilog's default (`0`). Wiring a "DIP;" OSD line here would be inventing a feature
path nothing upstream actually exercises.

## Lint

`verilator --lint-only`, mirroring `arcfpga-ui`'s own `nativeLint.ts` methodology (force-compile
`neptunoplus/mariobros_neptunoplus.sv` as the design top, `-y` search across `hdl/rtl/`
+ `modules/mist-modules/` + generic `modules/`, force-include any file needed only for a
module-name-≠-filename lookup): **0 real errors** once two things are accounted for, both matching
existing, established patterns in this repo's own lint tooling, not novel exceptions:

- `Cannot find file containing module: 'T80pa'/'t48_core'/'dac'/'dpram'` — all four are VHDL
  entities (`T80pa.vhd`/`t48_core.vhd`/`dac.vhd`/`dpram.vhd`) Verilator cannot parse; `nativeLint.ts`
  already suppresses exactly this class via its `vhdlModules`/`isSuppressedVhdlModule` check
  (filename-vs-module-name match, case-insensitive).
- **One known, narrow tooling-artifact exception, not yet hit by any other core**: resolving
  `mario_roms.v`'s differently-named wrapper modules (`MAIN_ROM`/`VID_ROM`/`OBJ_ROM`/`WAV_ROM`/
  `SUB_EXT_ROM`/`CLUT_PROM_512_8`/`ADEC_PROM` — same "filename ≠ module name" class as
  `rgb2ypbpr.v`/`arcade_inputs.v`, §2.3) requires force-including the whole file as an explicit
  compile unit (same mechanism `nativeLint.ts`'s own `findModuleFile` retry loop uses). That same
  file also defines the raw generic templates those wrappers instantiate (`DLROM`/`DLROMB`,
  `parameter AW`/`DW` with no default value) — force-compiling the *whole file* standalone makes
  Verilator also try to elaborate `DLROM`/`DLROMB` directly with no parameters bound, which is a
  real `%Error` (`Parameter without default value`) but not a real bug: every actual instantiation
  (e.g. `DLROM #(17,8) rom(...)`) binds them. Confirmed cosmetic by re-running with
  `--top-module mariobros_neptunoplus` (restricts elaboration to what's actually reachable from the
  real design root): that run has **zero** errors beyond the four expected VHDL lookups above.
  `nativeLint.ts` itself doesn't pass `--top-module`, so a future real run through the web app would
  likely see these same 2 lines — worth a small fix there (extend its hardcoded `extraLibFiles`
  special-casing, same treatment `mc8051.v`/`rgb2ypbpr.v`/`arcade_inputs.v` already get, or adopt
  `--top-module`) if/when this core is actually run through it, not attempted in this session since
  `arcfpga-ui` itself was out of scope for this HDL-focused change.

## Synthesis / hardware test

Not yet done — no Quartus install available in this session. Per
`doc/porting-a-native-core.md` §6: still needs a real Quartus 13.1 build (fitter/timing report
check) and a real-hardware flash (boot/video/controls/sound) before this core can be considered done.

## Sources

- **Ported from**: `MiSTer-devel/Arcade-MarioBros_MiSTer` @ `a934eecfb83a18f68b14c52380f3bfda153dcc99`
  — see `cores.json`'s `external.repo`/`external.commit`. Cloned locally at this commit to read the
  real `Arcade-MarioBros.sv`/`dpram.vhd` (not just a rendered directory listing).
- **MiST IO-protocol modules**: `modules/mist-modules/` (`user_io.v`/`data_io.v`/`arcade_inputs.v`/
  `mist_dual_video.v`/`dac.vhd`/`osd.v`/`cofi.sv`/`video_cleaner.v`/`rgb2ypbpr.v`/`scandoubler/`) —
  already pinned in this repo at `2dedb5a8171983b8fb3b04eb01aaf9be7a0a325a`, referenced as-is (no
  new vendoring needed).

## Remaining checklist (doc §6)

- [x] Identify candidate, record `external.repo`/`external.commit`, `framework: "native"`.
- [x] Identify upstream FPGA target (`target_fpgas: ["mister"]` — MiSTer-only upstream, an explicit
      deviation from §1's "prefer MiST" guidance, already accepted before this bridging session).
- [x] Read the upstream top-level module's I/O ports (`mario_top.v`, protocol-agnostic).
- [x] Identify the MiST IO-protocol module source (`modules/mist-modules/`, already pinned).
- [x] Write `neptunoplus/` (`.qpf`/`.qsf`/`.sdc` + adapter).
- [x] Zero bridge-owned *redundant* PLLs — the one PLL this bridge owns is the design's only PLL
      (mario_top has none), not a duplicate of a core-owned one.
- [x] Document deviations/approximations (this file).
- [x] Lint clean (see "Lint" above).
- [ ] Synthesize with Quartus 13.1 and check fitter/timing reports — not done, no Quartus available.
- [ ] Test on real NeptUNO+ hardware.
- [ ] Update `cores.json`'s `releases.neptunoplus` once a real build lands in `releases/neptunoplus/`.
