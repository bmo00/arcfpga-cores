# Porting notes — systemc2 → neptUNO+

Imported from [`Mezzow/Arcade-SystemC2_MiSTer`](https://github.com/Mezzow/Arcade-SystemC2_MiSTer), commit `36a01d4d08cc54d5ea8d6e4f9438c1df4568dfeb`.
Bridged following `doc/porting-a-native-core.md`'s checklist. **Status: bridged, lints clean
(Verilator). Two real-hardware bugs found and fixed across three flash attempts (2026-09-03/04) —
see "Real hardware findings" below: (1) a genuine `.sdc` timing-closure gap (fixed, verified via a
local Quartus rebuild, then confirmed via `arcfpga-ui`'s own pipeline: zero
`Timing requirements not met`, positive setup/hold on all 3 corners); (2) with timing now clean, an
inverted HSync/VSync polarity feeding `mist_dual_video`'s scandoubler (fixed, not yet re-flashed/
re-tested). Controls confirmed working on hardware after fix (1); video/audio still pending
re-test after fix (2).**

## Real hardware findings (2026-09-03)

First real Quartus 13.1 build (`arcfpga-ui`'s own build log,
`.workspace/systemc2/build-logs/neptunoplus.log`) compiled successfully and produced
`releases/neptunoplus/systemc2_20260903.rbf`, which was flashed to real NeptUNO+ hardware.
Symptoms reported: video visible but drifting/moving on a CRT (suggesting an unstable frame
timing, not simply a wrong frequency), no audio, and unreliable controls.

**Root cause identified from the build log**: TimeQuest reported `Critical Warning (332148):
Timing requirements not met` on **all three PVT corners**, with genuinely large negative slack on
*both* setup and hold — e.g. slow 1200mV 85C: worst-case setup slack **-2.105 ns** (TNS -33 to
-281 ns across the two PLL clock domains), worst-case **hold** slack **-0.306 ns**. A design that
fails hold timing (not just setup) can behave incorrectly regardless of temperature/voltage
margin — this is not a marginal, "probably fine" violation.

For comparison, the two cores on this platform that **are** confirmed working on real hardware
(`mariobros`, `breakthru`) both show **positive** setup and hold slack in their own build logs
(e.g. breakthru: +1.6/+0.25 ns worst case). `craterraider` (never yet hardware-tested) fails setup
only, hold stays positive. `systemc2` was the only one of the four failing *both* — consistent
with it being the one that actually misbehaves on real hardware.

**The actual bug**: this bridge's own `.sdc` was missing a multicycle-path exception the *upstream
MiSTer top's own `Arcade-SystemC2.sdc`* (at the repo root, **not** vendored into `hdl/` — this
bridge's early port work only ever read `hdl/rtl/`, so this file was missed entirely the first
time around) declares:

```tcl
# The SDRAM read data is registered on clk_ram and consumed on clk_sys by the
# MBUS state machine, which cannot look at it until at least the next clk_sys
# edge.  Inherited from Genesis_MiSTer with the instance names updated for the
# C-2 hierarchy: the module there is `system`, here it is `c2`.
set_multicycle_path -from {emu|sdram|dout*} -to {emu|c2|data*} -setup 2
set_multicycle_path -from {emu|sdram|dout*} -to {emu|c2|data*} -hold 1
```

Without it, TimeQuest analyzed the `sdram|dout*` (clk_ram, 107.38635MHz) → `c2|data` (clk_sys,
53.693175MHz) cross-domain path as single-cycle — the design was never meant to close timing on
that basis, and the large TNS values above are consistent with a whole 16-bit-wide bus's worth of
paths failing by roughly this amount.

**Attempt 1 (2026-09-03) — wrong hierarchy prefix, zero effect**: naively rewrote the upstream
pattern by swapping `emu` for this adapter's own top-level name (`systemc2_neptunoplus|sdram|dout*`
/ `systemc2_neptunoplus|c2|data*`). Rebuilding reproduced the *exact same* failing slack numbers,
and the new build log showed why: `Warning (332174): Ignored filter ... could not be matched with
a clock or keeper or register or port or pin or cell or partition` for both patterns — the whole
constraint was silently dropped. Root cause: in the *upstream* MiSTer project, `emu` is a real
child instance of the framework's own top-level wrapper (`sys_top`), not the design root — so its
`.sdc` correctly includes it as a hierarchy level. In *this* bridge, `systemc2_neptunoplus` **is**
the Quartus root itself, and TimeQuest does not prefix node paths with the root entity's own name
(confirmed against this same design's own successfully-resolving PLL clock names, e.g.
`pll|altpll_component|...`, and against Quartus's own "Synthesized away node ..." messages
elsewhere in the log, which start directly at `c2_system:c2|...` with no outer prefix at all).
**Lesson**: after touching an `.sdc`, grep the new build log for `Ignored`, not just
`Error`/`Critical Warning` — a dropped constraint fails silently and produces identical timing
results to not having written it at all.

**Attempt 2 (2026-09-03) — right hierarchy, still no measurable improvement**: fixed to
`{sdram|dout*}` / `{c2|data*}` (no top-level prefix). Rebuild showed **zero** `Ignored` warnings
this time (constraint accepted), but the worst-case setup/hold slack numbers were essentially
unchanged from before the fix existed (-2.116/-0.306 ns vs. the original -2.105/-0.306 ns on the
slow 85°C corner) — this constraint, while a real and necessary correctness fix in its own right
(the cross-domain relationship it describes is genuinely true), was **not** the dominant
contributor to the reported failures. Something else in the design is the actual worst path.

**Attempt 3 — FX68K's own author-documented worst-case path**: `../hdl/rtl/FX68K/fx68k.txt`'s own
"Timing analysis" section states plainly: "Microcode access is one of the slowest paths on the
core," and gives the exact Altera/Intel multicycle constraints for it (`Ir[*]` →
`microAddr[*]`/`nanoAddr[*]`). Added — a real, necessary fix (see "Resolution" below), but on its
own again left the worst-case numbers barely changed, confirming (again) that guessing one path at
a time from documentation, without seeing the actual failing paths, wasn't converging.

**Turning point — reproduced the build locally instead of guessing further.** `arcfpga-ui`'s own
`nativeBridgeBuilder.ts` deletes its staged Quartus workspace (`output_files/`, all detailed `.rpt`s)
immediately after every build, in a `finally` block — only the final `.rbf` and the captured
`stdout` (`neptunoplus.log`) survive, and that log only has TimeQuest's own summary tables (worst
slack per corner), never the actual failing register names. Since `raetro/quartus:13.1` was already
pulled locally and `docker` was available in this session, the fix from here on was: stage a copy
of `hdl/` (with `neptunoplus/patches/` applied) + `neptunoplus/` + `modules/mist-modules/` exactly
as `nativeWorkspace.ts` does, run the same `quartus_sh --flow compile` Docker command by hand, and
then — the actual unlock — run a second, throwaway `quartus_sta -t script.tcl` pass with
`report_timing -setup/-hold -npaths 10 -detail full_path` to print the *real* worst paths by exact
register name, something `--flow compile`'s default output never shows. This turned six rounds of
"change one thing, hope, rebuild, get an ambiguous answer" into six rounds of "see the exact
failing register, fix exactly that, confirm the report is empty of criticals" — worth remembering
for any future core on this platform that doesn't close timing cleanly on the first or second guess.

**Resolution (2026-09-03) — every real failing path found and fixed, verified locally in the exact
build image the real pipeline uses:**

1. **Setup, `SDRAM_DQ[*]` (physical pin) → `sdram:sdram|dout[*]`** (worst: -2.105ns): the actual
   dominant failure the whole time — not the `dout`→`data` path Attempt 1/2 targeted, which is one
   hop *downstream* of this. `modules/jtframe/target/neptunoplus/syn/neptunoplus.sdc` (never
   consulted until now — only the upstream game's own, irrelevant, Cyclone-V-specific
   `Arcade-SystemC2.sdc` had been checked) has the identical exception for every jtframe-built
   SDRAM-backed core on this exact board. Fixed with a proper `create_generated_clock -name
   SDRAM_CLK` (sourced from `clk[1]`, matching jtframe's own technique — this bridge had been
   referencing the raw internal `clk[1]` node directly for the SDRAM input/output delays instead,
   which doesn't model the pin's own real clock-to-out latency) plus
   `set_multicycle_path -setup -end -from {SDRAM_DQ[*]} -to {sdram:sdram|dout[*]} 2`, and
   re-derived the `-max`/`-min` input/output delay numbers to jtframe's own real, validated values
   (6/3 and 1.5/-0.8ns) instead of the unvalidated 6.6/3.5 guess carried over from `craterraider`.
2. **Setup, `sdram:sdram|dout[*]` → *three* separate clk_sys-domain captures**, found one at a time
   by repeating the local-build-then-report_timing cycle: `c2_system:c2|data[*]` (Attempt 2),
   `c2_system:c2|NO_DATA[*]` (a second register `c2_system.sv` also latches `ROM_DATA` into,
   `NO_DATA <= ROM_DATA;` — invisible to a `data*` wildcard), and
   `c2_system:c2|jt7759:pcm|jt7759_data:u_data|fifo[*]` (a *third* hop, through this adapter's own
   `pcm_data` combinational mux into the uPD7759's internal sample FIFO). Rather than keep adding
   named destinations as more turned up, relaxed the whole bus at the source instead:
   `set_multicycle_path -from {sdram|dout*} -setup 2` with no `-to` filter — every consumer of a
   registered SDRAM read data bus has the same real latency tolerance regardless of which register
   ends up holding it.
3. **Setup, `sdram:sdram|ack0/ack1/ack2` → their respective clk_sys consumers**
   (`c2_romload:romload|rptr[*]`/`fifo_rtl_0_bypass[*]`, `c2`, and this adapter's own top-level
   `pcm_sdr_req`): the same toggle-handshake req/ack crossing pattern the `dout` fix already needed,
   for the three SDRAM ports' own acknowledge signals — also relaxed at the source, no `-to` filter.
4. **Hold, `SDRAM_CLK` (generated clock) ↔ `clk[1]` (internal PLL clock), both directions**: once
   every setup violation above was fixed, the *entire* remaining `Timing requirements not met` on
   all three corners was one category: `sdram:sdram|SDRAM_DQ[n]~en` (the fast output-enable
   register for the bidirectional `SDRAM_DQ` tri-state buffer) → `SDRAM_DQ[n]` itself, worst
   -0.394ns, driven by a real ~3ns clock-skew difference between `clk[1]` reaching that fast
   register directly vs. reaching the `SDRAM_CLK` pin through its own DDIO register + pad.
   jtframe's own neptunoplus.sdc has the *input*-direction version of this clock-level exception
   (`-from SDRAM_CLK -to clk[1]`, needed for the `SDRAM_DQ`→`dout` setup fix's own hold
   counterpart); the *output*-direction mirror (`-from clk[1] -to SDRAM_CLK`) needed for this
   specific `~en`→pin path is this adapter's own addition, not copied from any precedent.

**Verified**: with all four fixes in place, a local `quartus_sh --flow compile` in
`raetro/quartus:13.1` (the exact image `arcfpga-ui` uses) shows **zero** `Critical Warning (332148):
Timing requirements not met` and **positive** worst-case setup *and* hold slack on all three PVT
corners (slow 85°C: +2.624/+0.247ns; slow 0°C: +3.084/+0.258ns; fast 0°C: +5.111/+0.083ns). **Not
yet re-flashed to real hardware** — the symptoms described (drifting video, no audio, unreliable
controls) should now be gone, but that's still a hypothesis until confirmed on the real board with
a build produced by `arcfpga-ui`'s own pipeline (not this session's local reproduction).

- "El teclado no funciona" — if this means an actual USB keyboard (not the joystick/control panel):
  this bridge has **no keyboard-to-joystick translation at all** (documented limitation, see
  "Architecture notes" below — no `arcade_inputs` instance). This is expected behavior, not a bug;
  only a DB9/USB gamepad through the RP2040 relay is supported. If it means the physical
  joystick/buttons instead, that was much more likely a symptom of the timing failures above.
- The `.sdc`'s SDRAM `-max`/`-min` values are now the same ones `modules/jtframe/target/neptunoplus`
  uses for every jtframe-built core on this board (§1 above) — a real, validated number for the
  actual physical chip, not a guess, so this is no longer an open item.

**Confirmed via a real rebuild through `arcfpga-ui`'s own pipeline (2026-09-04) and re-flash**: the
timing fix above is real — `neptunoplus.log` from that rebuild shows the same clean numbers as the
local reproduction, and **controls now work reliably** on real hardware (previously "unreliable" —
consistent with the hold-time violations being a real cause of that specific symptom). Video and
audio, however, were still broken, and reported differently from before: **recognizable game
graphics** (sprites/colors/text, confirmed correct — not noise, ruling out a ROM/protection-loading
bug), but **rolling/spinning rapidly**, "like a CRT that's lost vertical hold" — and still silent,
across every game tested. Since this is a *different kind* of wrong (a real, stable, reproducible
signal — not the timing-driven instability from before) and happens identically on every game, it
pointed at the shared video glue itself, not at anything game-specific or clock-instability-related.

**Root cause 2, found 2026-09-04 by reading `../hdl/rtl/vdp.vhd`'s own sync-generation code
directly**: its `HS`/`VS` outputs are **active-low** (`FF_HS<='1'`/`FF_VS<='1'` at reset/idle,
driven `<='0'` only during the actual sync pulse — the same Genesis/MiSTer-VDP convention the
vendored top's own MiSTer `video_mixer` instantiation consumes directly, uninverted, since MiSTer's
`video_mixer` expects that same polarity). `mist_dual_video`'s own scandoubler
(`modules/mist-modules/scandoubler/scandoubler_framing.v`) expects **active-high** sync inputs
instead — confirmed by cross-checking `mariobros_neptunoplus.sv`, which explicitly inverts its own
core's active-low `hsync_n`/`vsync_n` before feeding `mist_dual_video` (`.HSync(~hsync_n)`) for
exactly this reason, while `breakthru_neptunoplus.sv` passes its own core's `HSync`/`VSync` straight
through *because that specific upstream core's own sync outputs are already active-high* — the
correct choice is core-specific, not a fixed rule, and has to be checked against each vendored
core's own sync-generation code rather than assumed from another bridge's own choice. This
adapter's own first version copied the vendored top's *MiSTer*-facing (uninverted) convention
directly into the *MiST*-facing `mist_dual_video` call, missing that the two consumers expect
opposite polarities for the exact same active-low VDP signal.

**Why clean Quartus timing didn't catch this**: TimeQuest analyzes electrical timing relationships
(does data arrive and stay stable relative to a clock edge) — it has no concept of a signal's
*semantic* meaning, so a synchronous, stable, but inverted signal is completely invisible to it.
`scandoubler_framing.v`'s own internal state machine (`if(hsD && !hs_in) begin ... end`) looks for
the falling edge of what it assumes is an active-high pulse to anchor every line-length and frame-
timing calculation it derives; fed the opposite edge, every one of those derived values is
systematically wrong, in a way that's *stable and repeatable* (not marginal/intermittent like the
setup/hold violations from Root cause 1) — matching the qualitatively different symptom reported
after Root cause 1 was fixed (a real, resolvable picture with wrong sync framing, vs. the earlier
unstable/drifting picture from failing timing).

**Fixed**: `systemc2_neptunoplus.sv`'s `mist_dual_video` instantiation now inverts both
(`.HSync(~hs)`, `.VSync(~vs)`) — `HBlank`/`VBlank` were left as direct pass-through (`vdp.vhd`'s own
`IN_VBL<='1'` at reset confirms active-high blanking already, matching what `mist_dual_video`
expects, so no inversion needed there). **Not yet re-verified on real hardware** — Verilator lint
stays at the same 11 expected blackbox errors (no new issues from this change), but functional video
correctness needs a real flash to confirm.

Audio was still silent through both hardware attempts so far, unchanged by either fix. No specific
root cause found yet by code review alone (the DAC's offset-binary conversion, `AUDIO_L`/`AUDIO_R`
routing inside `c2_system.sv`, and the reset chain all read correctly against the same references
used to validate the HS/VS fix) — worth re-testing after the HS/VS fix lands, since the earlier
"can't see the picture clearly" state may simply have made it hard to separately assess whether any
audio was present at all; if it's still silent once video is stable, that becomes its own,
cleaner investigation.

## Architecture notes

- **MiSTer-only upstream, no MiST wrapper to clone** — same situation as `mariobros` (see that
  core's own `NOTES.md` and doc §1): `Arcade-SystemC2.sv` uses `hps_io.sv`, a fundamentally
  different protocol from MiST's `user_io`/`data_io`. Unlike `mariobros`, though, the vendored
  game logic (`c2_system.sv`, `c2_romload.sv`, `sdram.sv`) is itself protocol-agnostic — the
  upstream top module is already close to a plain board-glue wrapper (SDRAM instantiation, PLL,
  ROM-stream demux, DIP-byte capture, input-bit assembly, video mixing) with hardly any real logic
  of its own beyond that glue. `systemc2_neptunoplus.sv` clones that glue almost line-for-line,
  swapping `hps_io` for `user_io`+`data_io` and MiSTer's `video_mixer`+`video_freak` for MiST's
  `mist_dual_video`.
- **First core on this platform combining a real SDRAM controller with an upstream-owned PLL** —
  `craterraider`/`spyhunter`/`journey`/`turbotag`/`mcr3` all have real SDRAM too, but none of them
  needed a *fractional-N-to-classic-altpll* family swap (their own gyurco-sourced `pll_mist.vhd`
  was already a classic `altpll`, just re-tuned for a 27→50MHz reference change). This core's own
  `hdl/rtl/pll.v` wraps `pll_0002.v`, a real Cyclone V/Arria 10-only `altera_pll` fractional-N IP —
  see `pll.v`'s own header comment for the full ratio derivation
  (`c0 = 50 * 189/176 = 53.693182MHz`, `c1 = 50 * 189/88 = 107.386364MHz`, both within ~0.15ppm of
  the upstream's own fractional-N-derived values, `c1`'s `-1552ps` phase shift preserving the
  upstream's own `-60°` relationship between the two outputs). **This phase relationship is
  unverified on real hardware** — it is not merely an SDRAM-chip trace-delay tweak (that's handled
  separately, inside `sdram.sv`'s own DDIO register), but is how the upstream design keeps
  `clk_ram`'s edges phase-locked to `clk_sys` for the 68000/VDP/SDRAM-arbitration state machines.
  If a real build boots but shows RAM corruption or bus-arbitration glitches, re-derive this first.
- **The vendored top's own PLL-reconfiguration sequence is provably dead code, and is not cloned
  at all**: `Arcade-SystemC2.sv` instantiates a `pll_cfg` reconfiguration IP and drives it with a
  `state`-machine sequence that reprograms the PLL for PAL timing — but `state` starts at 0 and
  only ever advances `if (state)`, which is always false, so the sequence never fires (matches
  that file's own comment: "Left instantiated because the .qip expects it; simply never
  triggered" — a C-2 board is NTSC-only, `segac2.cpp` never sets `is_pal(true)` for this driver).
  Since the sequence never fires, this bridge's own adapter has no `pll_cfg` instance and no
  `reconfig_to_pll`/`reconfig_from_pll` ports on its own `pll.v` replacement at all — nothing is
  lost by omitting it.
- **Real bug fixed via `neptunoplus/patches/`** (not in place, see `patches/README.md`):
  `sdram.sv`'s `SDRAM_CLK`-generating `altddio_out` instance hardcodes
  `.intended_device_family("Cyclone V")`, the upstream board's own family — a real mismatch
  against NeptUNO+'s Cyclone IV GX that Quartus would reject at synthesis. Fixed by retargeting the
  family string only; `altddio_out` itself is available on both families.
- **`mlab.vhd` (vendored, in `hdl/rtl/`) is genuinely dead weight, not referenced from the
  `.qsf`** — confirmed via `grep` (its own `mlab` entity is never instantiated anywhere in the
  vendored tree) and via Verilator lint (no missing-module error for it). `bram.vhd`, by contrast,
  **is** needed — its `dpram`/`dpram_dif` entities back `c2_system.sv`'s own work-RAM/video-RAM
  instances — and is listed in the `.qsf` despite not showing up in a naive grep for `bram\b`
  (the file name and the entity names it declares don't match).
- **CPU/sound IP referenced from its pinned per-core copy, not `modules/`** — same convention
  `mariobros_neptunoplus.qsf` already established for its own `T80`/`t48`: this upstream repo
  (unlike gyurco's `Mist_FPGA`) vendors its own private copies of `FX68K`/`jt12`/`jt7759`/`jt89`
  directly inside its own tree at the pinned commit, so the `.qsf` references those vendored
  copies (`../hdl/rtl/FX68K/hdl/*.sv`, `../hdl/rtl/jt12/jt12.qip`, etc.) rather than this repo's
  own `modules/fx68k` or `modules/jt12` (a possibly-different version, and the whole point of
  pinning `external.commit` is that `hdl/` matches it exactly).
- **`FX68K`'s own bare `$readmemb("microrom.mem", ...)`/`$readmemb("nanorom.mem", ...)` calls**
  (inside `../hdl/rtl/FX68K/hdl/fx68k.sv`) resolve relative to the Quartus *project* directory, not
  the including file's own directory — which would be `neptunoplus/`, not
  `../hdl/rtl/FX68K/hdl/` where the two `.mem` files actually live. Fixed the same way
  `alpha68k_neptunoplus.qsf` already fixes an analogous bare-`` `include``: a
  `set_global_assignment -name SEARCH_PATH ../hdl/rtl/FX68K/hdl` line, not by copying the `.mem`
  files anywhere.
- **No `arcade_inputs` instance** — unlike every other bridge in this repo so far, P1/P2/coin/
  start/service/test are read directly off fixed `joystick_0`/`joystick_1` bit positions (same
  convention `user_io.v` fills them with as `hps_io` does: bits 0-3 = right/left/up/down, 4.. =
  named `J1` buttons in `CONF_STR` order), copied verbatim from the vendored top's own comment
  block (bit layout sourced from `INPUT_PORTS_START(systemc_generic)` in MAME's `segac2.cpp`).
  `arcade_inputs` would only add USB-keyboard-to-joystick translation, which this bridge doesn't
  wire up — **documented limitation**: this core has no keyboard-input fallback on this platform
  (DB9/USB gamepad only).
- **`c2_romload`'s own `IOCTL_WAIT` output has no consumer** — MiST's `data_io.v` (unlike MiSTer's
  `hps_io.sv`) has no wait/backpressure input at all. Left connected to an otherwise-unused wire
  rather than tied off silently. Believed safe (the SDRAM controller's write-acknowledge latency,
  a handful of `clk_ram` cycles, is far shorter than one SPI byte period), but **genuinely
  unverified on real hardware** for this specific 3-port controller under worst-case
  refresh/PCM-read contention — `c2_romload`'s own `OVERFLOW` output (also unconnected) is the
  upstream author's own safety-net flag for exactly this failure mode; wire it to a debug LED if a
  real-hardware ROM-corruption report ever needs to confirm/rule this out.
- **`mist_dual_video`'s `ce_divider` is runtime-selected, not a fixed constant** — this one
  `.rbf` serves every game in the systemc2 family, and unlike most single-resolution native cores
  on this platform, different games in this family genuinely use different VDP dot-clock widths
  (`c2_system`'s own `RESOLUTION` output: 256px/"H32" mode at MCLK/10, 320px/"H40" mode at MCLK/8).
  `ce_divider` is wired from a runtime-latched copy of `RESOLUTION` (`res[0] ? 4'd7 : 4'd9`,
  latched once per VBlank, same "hold for the whole frame" technique the vendored top already
  uses for its own aspect-ratio latch) rather than a single build-time value.
- **DIP switches**: `"DIP;"` tag, not hand-rolled `O`-lines (doc §2.5). Every systemc2 `.mra`
  checked (`Puyo Puyo`, `Columns`, `Thunder Force AC`, `Bloxeed`) declares `<switches base="0">`,
  so `status[7:0]`/`status[15:8]` feed `DSW1`/`DSW2` directly, no extra offset — unlike
  `breakthru`'s own `base="16"` case.
- **"Aspect Ratio" (`status[17:16]`) is an unwired placeholder**, same as `mariobros`'s and
  `breakthru`'s own copy of this exact option: `mist_dual_video` has no ARX/ARY-style aspect
  control (that's a MiSTer/HDMI-scaler concept, `video_freak`, absent from this platform's
  analog-only video pipeline). Kept only for CONF_STR parity with every other bridge here.
- **"Scanlines" (`status[19:18]`), not "Scandoubler Fx"**: the vendored top's own MiSTer
  `CONF_STR` offers a 5-way `"Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%"` option feeding
  MiSTer's `video_mixer` (`hq2x`/`scandoubler` ports, not present on `mist_dual_video` at all —
  that pipeline only has a 2-bit `scanlines` input, no HQ2x mode). Rather than copy a 3-bit
  option whose top value would silently alias back to "None" once truncated to 2 bits (a
  pre-existing wart already visible in `mariobros_neptunoplus.sv`'s own `OAC`→`status[12:10]`→
  `scanlines[1:0]` wiring), this bridge exposes only the 4 options the hardware pipeline actually
  supports.
- **No save/NVRAM support** — work RAM keeps its `0xFF` fill at load, same as the vendored top's
  own "Save support is deferred" behaviour; `BRAM_*` ports tied off.

## Lint

`verilator --lint-only --top-module systemc2_neptunoplus` (with `-y` search paths for `hdl/rtl`,
`hdl/rtl/FX68K/hdl`, each `jt12`/`jt7759`/`jt89` subdirectory, and `modules/mist-modules` +
`scandoubler/`): **0 unexpected errors** — only the established suppressed class (Verilator cannot
parse VHDL or Altera megafunctions at all, regardless of search path): `altpll` (`pll.v`),
`altddio_out` (`sdram.sv`), `dac` (VHDL entity, hit twice, once per audio channel), `vdp`/`dpram`/
`dpram_dif` (VHDL entities in `vdp.vhd`/`bram.vhd`).

Two files needed explicit force-inclusion on the Verilator command line (invisible to `-y`'s
filename-based on-demand search, same class of gotcha doc §2.3 documents for
`arcade_inputs.v`/`rgb2ypbpr.v`): `../hdl/rtl/FX68K/hdl/uaddrPla.sv` declares both `uaddrPla` and a
second module, `pla_lined`, that `fx68k.sv` also instantiates; `../../../modules/mist-modules/rgb2ypbpr.v`'s
real module name is `RGBtoYPbPr` (a pre-existing, already-documented gotcha, not new here). Neither
needs any special handling in the real `.qsf` — Quartus compiles every listed file as a whole unit
regardless of filename-vs-module-name matching; this only affects an ad-hoc Verilator invocation.

Remaining `%Warning-WIDTH*` output is entirely pre-existing bit-width laxness inside vendored files
(`fx68kAlu.sv`, `jt12_acc.v`, `scandoubler_rotate.v`, `user_io.v`, `data_io.v`, etc.) or harmless,
convention-matching truncation in this bridge's own adapter (`status`/`ioctl_addr` declared
narrower than `user_io`/`data_io`'s own port widths, same as every other bridge on this platform;
`addr2`'s 23-vs-24-bit connection is copied verbatim from the vendored top's own expression) — none
of it is new or specific to this core.

## Remaining checklist (doc §6)

- [x] Identify candidate, record `external.repo`/`external.commit`, `framework: "native"` (done at
      import time).
- [x] Identify upstream FPGA target (`target_fpgas` already populated at import).
- [x] Read the upstream top-level module's I/O ports (`Arcade-SystemC2.sv`, cloned almost
      verbatim for its board-glue portions).
- [x] Identify the MiST IO-protocol module source (`modules/mist-modules/` — no MiST wrapper
      existed upstream to inherit a pinned commit from; used as pinned in this repo).
- [x] Write `neptunoplus/` (`.qpf`/`.qsf`/`.sdc` + adapter + retuned `pll.v`).
- [x] Wire `SDRAM_CLK`/`SDRAM_CKE` from the core's own SDRAM controller output, zero bridge-owned
      PLLs (§2.2) — the upstream `altera_pll` is retuned in place via a same-named `pll.v`.
- [x] Document deviations/approximations (this file).
- [x] Lint clean (see above).
- [x] Synthesize with Quartus 13.1 and check fitter/timing reports — done 2026-09-03. The *first*
      attempt's TimeQuest report showed real timing failures (both setup and hold); root-caused
      across six local-rebuild-and-`report_timing` cycles (see "Real hardware findings" → "Turning
      point"/"Resolution") down to five missing `.sdc` exceptions, all now fixed. **Verified
      locally** (`raetro/quartus:13.1`, the same image `arcfpga-ui` uses): zero
      `Timing requirements not met`, positive setup and hold slack on all three PVT corners. **Not
      yet reproduced through `arcfpga-ui`'s own pipeline** — do that before trusting a new `.rbf`,
      and diff its build log's `Worst-case setup/hold slack` lines against the ones recorded in
      "Resolution" above as a sanity check that the same fix applies unchanged there.
- [x] Test on real NeptUNO+ hardware — done 2026-09-03 with the *timing-broken* build: video
      visible but drifting, no audio, unreliable controls (see "Real hardware findings"). **Needs
      re-testing** once a rebuilt, timing-verified `.rbf` (from `arcfpga-ui`'s own pipeline, not
      this session's local reproduction) is flashed: boot, video (including a 256px-wide "H32"
      game, not just a 320px-wide one, to exercise the runtime `ce_divider` selection), controls,
      sound, DIP switches, Service Mode trigger.
- [x] `cores.json`'s `releases.neptunoplus` recorded 2026-09-03 (build succeeded) — update again
      (and add a `"tested": "yes"` field, matching `breakthru`'s own convention) once the
      timing-clean rebuild is confirmed working on real hardware.

## Sources

- **Ported from**: `Mezzow/Arcade-SystemC2_MiSTer` @ `36a01d4d08cc54d5ea8d6e4f9438c1df4568dfeb` —
  see `cores.json`'s `external.repo`/`external.commit`.
- **MiST IO-protocol modules**: `modules/mist-modules/` (pinned at
  `2dedb5a8171983b8fb3b04eb01aaf9be7a0a325a` per `modules.json`) — used here for the first time
  without an upstream MiST wrapper to have inherited the reference from; no separate pin to record.
- **CPU/sound IP**: vendored per-core directly under `hdl/rtl/FX68K/`, `hdl/rtl/jt12/`,
  `hdl/rtl/jt7759/`, `hdl/rtl/jt89/`, as originally imported at `external.commit` (not this repo's
  own `modules/fx68k`/`modules/jt12`/etc. — see "Architecture notes" above).
