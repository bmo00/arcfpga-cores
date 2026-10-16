# Attribution — destroyer

A **native** (non-jtframe) core — see `arcfpga-cores-develop/doc/porting-a-native-core.md`. The
game logic under `hdl/` is not jtframe HDL: it's copied verbatim from an existing, working MiST
core, with only a NeptUNO+-specific adapter (`neptunoplus/`) written new for this repo.

- **Game hardware**: Cidelsa "Video System-1" — an RCA CDP1802 (COSMAC) CPU with CDP1869/1870
  video (integrated tone+noise sound) — all on-chip block RAM, no SDRAM.
- **Ported from**: [`jlrh/cidelsa-fpga`](https://github.com/jlrh/cidelsa-fpga), commit `4103139c5a0fe46611805c743dca1cdac95a316f`.
  Reused here per `external.repo`/`external.commit` in `cores.json`.
- **NeptUNO+ adapter** (`neptunoplus/`): bridged following doc/porting-a-native-core.md §6 — a
  brand-new MiST-style board wrapper (the upstream repo is MiSTer-only, `hps_io`-based, no MiST
  wrapper to clone from), transliterating the upstream `Destroyer.sv`'s wiring to this repo's
  `user_io`/`data_io`/`arcade_inputs`/`mist_dual_video`/`dac` convention. See `neptunoplus/NOTES.md`
  for what was reused vs. written new, and what's still unverified/pending.

**Status**: bridged and lints clean (verilator); not yet built with real Quartus or tested on real
hardware — see `neptunoplus/NOTES.md`.

## License

GPL-3.0 (`hdl/LICENSE`) — GPL-3.0-compatible with this project's own requirement.
