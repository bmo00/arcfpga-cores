# Attribution — systemc2

A **native** (non-jtframe) core — see `arcfpga-cores-develop/doc/porting-a-native-core.md`. The
game logic under `hdl/` is not jtframe HDL: it's copied verbatim from an existing, working
MiSTer-only core, with a NeptUNO+-specific adapter (`neptunoplus/`) written new for this repo
(there was no MiST wrapper to clone — see `neptunoplus/NOTES.md`).

- **Game hardware**: Sega System C / System C-2, a 68000-based arcade platform derived from the
  Mega Drive/Genesis (`hdl/rtl/c2_system.sv` explicitly replaces Genesis_MiSTer's own
  `rtl/system.sv`, reusing its 315-5313 VDP + 68000/VDP bus arbitration). 68000 CPU (FX68K), Sega
  315-5313 VDP (video, VRAM, background PSG), YM3438 FM (`jt12`), uPD7759 ADPCM sample player
  (`jt7759`, System C-2 boards only), external 2048-word CRAM addressed partly by the C-2
  protection chip (`c2_palette.sv`) instead of the VDP's own internal CRAM, and the 315-5296 I/O
  chip (`c2_io.sv`).
- **Ported from**: [`Mezzow/Arcade-SystemC2_MiSTer`](https://github.com/Mezzow/Arcade-SystemC2_MiSTer), commit `36a01d4d08cc54d5ea8d6e4f9438c1df4568dfeb`.
  Reused here per `external.repo`/`external.commit` in `cores.json`. Bundles jotego's own `jt12`
  (YM3438)/`jt7759` (uPD7759)/`jt89` (SN76489-compatible PSG) and dmakslinux/plusto's FX68K, all
  vendored per-core directly under `hdl/rtl/` as originally imported (see `neptunoplus/NOTES.md`
  for why these are referenced from their pinned per-core copies rather than this repo's own
  `modules/jt12`/`modules/fx68k`).
- **NeptUNO+ adapter** (`neptunoplus/`): new MiST-style board wrapper (`user_io`/`data_io`/
  `mist_dual_video`/`dac` from `modules/mist-modules/`), a real 3-port SDRAM controller retained
  from the vendored `hdl/rtl/sdram.sv`, and a retuned classic-`altpll` replacement for the
  vendored `hdl/rtl/pll.v` (a Cyclone-V-only `altera_pll`) — see `neptunoplus/NOTES.md` for the
  full account, including the one vendored-HDL bug fixed via `neptunoplus/patches/` (a hardcoded
  `Cyclone V` device-family string on `sdram.sv`'s `SDRAM_CLK`-generating DDIO register).

**Status**: bridged; two real-hardware bugs found and fixed across three flash attempts
(2026-09-03/04) — a `.sdc` timing-closure gap (fixed and confirmed via a real rebuild: controls now
work reliably) and an inverted HSync/VSync polarity feeding the scandoubler (fixed, not yet
re-flashed). Video/audio still pending a hardware re-test. See `neptunoplus/NOTES.md`'s "Real
hardware findings" section.

## License

Upstream `hdl/LICENSE` is GNU GPL v3 — GPL-3.0-compatible with this project's own requirement.
