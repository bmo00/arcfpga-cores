# Porting notes — marblemadness2 → neptUNO+

Imported from [`kandowontu/MarbleMadness2_MiSTer`](https://github.com/kandowontu/MarbleMadness2_MiSTer), commit `13dc3a239a929f04a1f91a131bded1c4c87f2536`.
Following `doc/porting-a-native-core.md`'s checklist. Nothing bridged yet — this file is a
skeleton for whoever (or whichever agent) writes `neptunoplus/` next.

## Sources

- **Ported from**: `kandowontu/MarbleMadness2_MiSTer` @ `13dc3a239a929f04a1f91a131bded1c4c87f2536` — see `cores.json`'s
  `external.repo`/`external.commit`.
- **MiST IO-protocol modules**: TODO — identify where `user_io`/`data_io`/`arcade_inputs`/
  `mist_video`/`dac` come from (commonly a `mist-devel/mist-modules` submodule) and pin the
  commit.

## TODO

- [ ] Read the upstream top-level module's I/O ports.
- [ ] Pick the `.qpf`/`.qsf`/`.sdc` base from the upstream repo's own closest MiST-like board
      target.
- [ ] Write the adapter in `neptunoplus/`.
- [ ] Synthesize with Quartus 13.1 (`raetro/quartus:13.1`) and check fitter/timing reports.
