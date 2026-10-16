# cores/cps3 divergence from upstream

`cores/cps3` is vendored from `jotego/jtcores` (see `cores.json`'s `external.repo`/`external.commit`).

## `gfxdma-addr-vs-upstream.diff`

**Bug:** `jtcps3_game.v`'s `gfxdma_addr` (the shared read address the character/tile DMA,
`jtcps3_chardma.v`, uses to fetch its compressed source data for *both* `jtcps3_obj.v` sprites and
`jtcps3_scr.v` backgrounds) computed the physical SDRAM byte where SIMM3 starts as a hardcoded
`16MiB` (`25'h0400000`, a word address), with an extra `+4MiB` jump once past a fixed `48MiB`
threshold meant to skip a gap before SIMM2.

That map assumes bios+SIMM1 are padded out to a full 16MiB, and that SIMM3/4/5 are each padded to a
full 16MiB slot regardless of a given set's real SIMM sizes. Neither assumption holds: decoding the
actual generated `.mra` header for `redearthn` (region-offset table, 64kB units) gives
`0x0008 / 0x0088 / 0x0188 / 0x0288 / 0x02C8 / 0x02C8`, i.e. real physical boundaries of
`0x080000` (bios end / SIMM1 start), `0x880000` (SIMM1 end / SIMM3 start, = **8.5MiB**, not 16MiB),
`0x1880000` (SIMM3 end / SIMM4 start), `0x2880000` (SIMM4 end / SIMM5 start), `0x2C80000` (SIMM5
end — SIMM2/SIMM6 both zero-length for this set). Every region is packed immediately after the
previous one with **no padding**, and this table is bios+SIMM1+SIMM3+SIMM4-invariant across every
set (those four are the same size for every supported game — only SIMM5/SIMM2/SIMM6 vary). This
`.mra` is the single artifact shared by every target (`jtframe mem cps3 -t mister -l` and
`jtframe mem cps3 -t neptunoplus -l` both leave it byte-identical), so the mismatch isn't
neptunoplus-specific — it exists in the shared HDL, currently just unreleased to MiSTer (`cores.json`
pins MiSTer to an older commit than the one behind the current neptunoplus release).

**Symptom:** since `gfxdma_addr` always reads ~7.5MiB past the real start of SIMM3, `chardma`
decodes garbage/misaligned data for every set — reported on real neptUNO+ hardware as missing
sprites and backgrounds (HUD/text survives because it comes from a separate BRAM layer, not this
DMA path) on both `sfiiin` and `redearthn`, i.e. independent of whether SIMM2 is populated.

**Fix:** compute `gfxdma_addr` from the real, tightly-packed base (`0x220000` in word units =
`0x880000` bytes = 8.5MiB) with a plain contiguous offset and no jump, since `gfxdma_user5_addr`
already represents the tightly-packed SIMM3+4+5+2+6 concatenation the `.mra` builder produces.

**Verification status:** confirmed against the real, currently-shipping `.mra` header bytes (see
above) and the current `mem.yaml`/generated `jtframe_cache_mux` bank layout (`bank0`=cpuba0 16MiB,
`bank1`=pcm 16MiB, `bank2`=tiles_wr/tiles 8MiB, `bank3`=simm2 8MiB — none of which this fix
overlaps). **Not yet run through `jtsim`/hardware** — this session's environment couldn't run the
Docker-based `jotego/simulator` sim flow this repo's `README.md` documents (only tried a bypass,
which hit its own unrelated space-in-path script issue). Run the regression for at least
`redearthn`/`sfiiin`/`jojon` before shipping, and please also flag this upstream to jotego —
`jtcps3_game.v` is shared code, so if the analysis above is right, MiSTer's *next* build (whenever
it picks up a commit past `ece51257...`, the one `cores.json` currently pins) will hit the same bug.

**Still won't fit in 64MB even with this fix (unrelated to the bug above — genuine capacity, not
addressing):** bios(0.5)+SIMM1(8)+SIMM3(16)+SIMM4(16) = 40.5MiB is fixed for every set; adding a
set's real SIMM5/SIMM2/SIMM6:
- `redearthn`, `redearthnr1`, `sfiiin`, `sfiiina` (SIMM5=4, no SIMM2/6): 44.5MiB — fits.
- `jojon`, `jojonr1`, `jojonr2` (SIMM5=4, SIMM2=8): 52.5MiB — fits.
- `jojoban` family, `sfiii2n` (SIMM5=16, SIMM2=8): **64.5MiB — 0.5MiB over** a 64MB chip.
- `sfiii3n` family (SIMM5=16, SIMM2=8, SIMM6=16): 80.5MiB — far over.

So this patch alone does not make `jojoban`/`sfiii2n`/`sfiii3n` playable on neptUNO+; those need
either reclaiming ~0.5MiB+ of `bank0`'s otherwise-idle tail (16MiB reserved for `cpuba0`, only
~9.5MiB actually used) or shrinking the `tiles` decode buffer, neither of which this patch attempts.
Recommend excluding those sets from the neptunoplus MRA/release selection until that's done.

Pinned base: `jotego/jtcores` commit `d6df1b8a7e23a68624ffd3c71e0734b7b1e16d77` (`cores.json`'s
`external.commit` for this core's `neptunoplus`/`mra`/`arc` releases at the time this was written).

## `macros-def-neptunoplus-vs-upstream.diff`

Upstream's `cfg/macros.def` only defines a `[mister]` section carrying `JTFRAME_SDRAM_XL` (the
dual-chip SDRAM_XL controller MiSTer's 128MB SDRAM supports). neptUNO+ only has a single 64MB
SDRAM chip and has no dual-chip SDRAM_XL implementation, so it needs its own `[neptunoplus]`
section instead, carrying `JTFRAME_LF_SDRAM_BUFFER` (chip 1 on this target is a single-purpose
line-buffer SDRAM, not a general-purpose ROM/RAM chip — see `mem-yaml-neptunoplus-vs-upstream.diff`
below for what that implies for the SDRAM map) and `JTFRAME_SDRAM_LARGE` (the single-64MB-chip
cache-lane layout).

**Fix:** add a `[neptunoplus]` section with `JTFRAME_LF_SDRAM_BUFFER`/`JTFRAME_SDRAM_LARGE`, and
move `JTFRAME_SDRAM_XL` out of the global macro block into its own `[mister]` section (see the
diff for the exact change).

## `mem-yaml-neptunoplus-vs-upstream.diff`

Follows directly from the `[neptunoplus]` macros above: since neptUNO+ has no dual-chip SDRAM_XL
implementation, chip 1 there is a single-purpose line-buffer SDRAM
(`JTFRAME_LF_SDRAM_BUFFER`), not a general-purpose ROM/RAM chip — so the `tiles_wr`/`simm2`/`tiles`
cache-lanes' upstream `at:` placement (`chip: 1`) doesn't exist on this target. Their own
neptunoplus variant instead stays on chip 0, in the two banks (2–3) that `cpuba0` (bank 0) and
`pcm` (bank 1) leave free — this only fits ROM sets small enough for a single 64MB chip
(`JTFRAME_SDRAM_LARGE`); bigger sets still need the real dual-chip work upstream has.

**Fix:** duplicate each of the three cache-lanes into an `unless: [ NEPTUNOPLUS ]` variant (kept
byte-identical to upstream's `at:` placement) and a `when: [ NEPTUNOPLUS ]` variant (`at: { bank: 2
| 3, length: 8MB }`, no `chip:`, i.e. chip 0) — see the diff for the exact placement per lane.
