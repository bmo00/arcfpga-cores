# Attribution — marblemadness2

A **native** (non-jtframe) core — see `arcfpga-cores-develop/doc/porting-a-native-core.md`. The
game logic under `hdl/` is not jtframe HDL: it's copied verbatim from an existing, working MiST
core, with only a NeptUNO+-specific adapter (`neptunoplus/`) written new for this repo.

- **Game hardware**: TODO — describe the CPU(s)/sound chip(s)/custom ICs.
- **Ported from**: [`kandowontu/MarbleMadness2_MiSTer`](https://github.com/kandowontu/MarbleMadness2_MiSTer), commit `13dc3a239a929f04a1f91a131bded1c4c87f2536`.
  Reused here per `external.repo`/`external.commit` in `cores.json`.
- **NeptUNO+ adapter** (`neptunoplus/`): TODO once the Bridge agent (or a manual port,
  following doc/porting-a-native-core.md §6) has run — see `neptunoplus/NOTES.md` for what was
  reused vs. written new.

**Status**: imported, not yet bridged/synthesized — see `neptunoplus/NOTES.md`.

## License

TODO — confirm the upstream repo's own license is GPL-3.0-compatible (this project's own
requirement) before doing any further work on this core.
