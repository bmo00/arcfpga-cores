# systemc2

Native (non-jtframe) core ported from [`Mezzow/Arcade-SystemC2_MiSTer`](https://github.com/Mezzow/Arcade-SystemC2_MiSTer).
See `ATTRIBUTION.md` for sourcing details and `neptunoplus/NOTES.md` for the NeptUNO+ port log.

**Status**: bridged; two real-hardware bugs found and fixed across three flash attempts
(2026-09-03/04) — a `.sdc` timing-closure gap (fixed and confirmed via a real rebuild: controls now
work reliably) and an inverted HSync/VSync polarity feeding the scandoubler (fixed, not yet
re-flashed). Video/audio still pending a hardware re-test. See `neptunoplus/NOTES.md`'s "Real
hardware findings" section before flashing again.
