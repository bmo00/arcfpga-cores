# Attribution — mariobros

A **native** (non-jtframe) core — see `arcfpga-cores-develop/doc/porting-a-native-core.md`. The
game logic under `hdl/` is copied verbatim from an existing, working core, with a NeptUNO+-specific
adapter (`neptunoplus/`) written new for this repo.

- **Game hardware**: Nintendo Mario Bros. — main CPU is a T80-compatible Z80 core (`mario_main.v`'s
  `T80pa`), sound CPU is an M58715 (an 8039/T48-family MCU, `m58715ip.v` over `t48_core`), digital +
  analog sound channels mixed in `mario_sound_mixer.v`. All ROM/RAM is on-chip block RAM (no
  SDRAM) — a first for this repo's native-core ports; see "Architecture notes" in `neptunoplus/NOTES.md`.
- **Ported from**: [`MiSTer-devel/Arcade-MarioBros_MiSTer`](https://github.com/MiSTer-devel/Arcade-MarioBros_MiSTer)
  (originally by gaz68), commit `a934eecfb83a18f68b14c52380f3bfda153dcc99`. Reused here per
  `external.repo`/`external.commit` in `cores.json`. Also the source of `hdl/rtl/dpram.vhd`, vendored
  from that same commit's repo root (not `rtl/`) after the initial import missed it — see
  `neptunoplus/NOTES.md`.
- **MiST IO-protocol modules** (referenced from `modules/mist-modules/`: `user_io.v`, `data_io.v`,
  `arcade_inputs.v`, `mist_dual_video.v`, `dac.vhd`, `osd.v`, `cofi.sv`, `video_cleaner.v`,
  `rgb2ypbpr.v`, `scandoubler/`): this core is MiSTer-only upstream (no MiST wrapper exists to
  clone), so `neptunoplus/mariobros_neptunoplus.sv` is a *new* MiST-style board wrapper —
  see `neptunoplus/NOTES.md` for the signal-by-signal mapping derived from the real upstream
  `Arcade-MarioBros.sv` (hps_io) wrapper, read at the pinned commit.
- **NeptUNO+ adapter** (`neptunoplus/`): written new for this repo —
  `neptunoplus/mariobros_neptunoplus.sv` + a bridge-local `hdl/pll.v` (Cyclone IV `altpll`
  reimplementation of the pinned, Cyclone-V-only `altera_pll`-based `hdl/rtl/pll.v` — see that file's
  own header comment). See `neptunoplus/NOTES.md` for the full writeup, including what was intentionally
  left out (hiscore.dat autosave).
- **Genuine bug found in vendored HDL, fixed via `neptunoplus/patches/`** (never edited in place):
  - `mario_top-duplicate-i_anlg_vol.patch` — `mario_top.v`'s own `mario_sound` instantiation
    connects `.I_ANLG_VOL()` twice (once with the real signal, once empty); Verilator (and likely
    Quartus) treats this as a hard duplicate-pin-connection error.

**Status**: bridged, lints clean (`verilator --lint-only`, matching `arcfpga-ui`'s own native lint
methodology — see `neptunoplus/NOTES.md` for the one known, narrow tooling-artifact exception). Not yet
synthesized with real Quartus (unavailable in this session) or tested on real hardware.

## License

TODO — confirm the upstream repo's own license is GPL-3.0-compatible (this project's own
requirement) before doing any further work on this core.
