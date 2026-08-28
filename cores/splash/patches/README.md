# cfg divergence from upstream

`cores/splash` is vendored from `javi-ivaj/splash-fpga` (see `cores.json`'s
`external.repo`/`external.commit`). This core's own `cfg/*` files are freely edited in place
here (unlike `modules/jtframe`, which stays a clean checkout patched only via a core's own
`patches/` dir when it needs a framework-level change — see `cores/bucky/patches/README.md` for
that other case) — this file documents *why* our copy no longer matches upstream byte-for-byte.

## `macros-def-gametop-vs-upstream.diff`

Same issue as `cores/momoko` (see that core's own `patches/README.md` for the full explanation):
upstream's `CORENAME=SPLASH` doesn't carry the `jt` prefix (this repo's convention for "core no
oficial" / unofficial cores — see `cores/tantr`, `cores/opwolf`, `cores/moomesa`, `cores/ssriders`,
`cores/pspikes`, `cores/empirecity`, `cores/momoko` for the same pattern). Without an explicit
`GAMETOP` override, `jtframe`'s default derivation (`macros.go`'s `make_gametop_macro`) resolves
`GAMETOP` to `splash_game_sdram`, but `jtframe mem`'s generator always writes the memory-derived
top wrapper as `jtsplash_game_sdram.v` (from the core's directory name, not `CORENAME`). At
synthesis time this fails the same way momoko did:

```
Error (12006): Node instance "u_game" instantiates undefined entity "splash_game_sdram"
File: modules/jtframe/hdl/inc/jtframe_game_instance.v Line: 224
```

Applied proactively here (splash has no `releases` entry in `cores.json` yet, so this had not been
hit in practice) to avoid the same failure the first time this core reaches synthesis.

**Fix:** add `GAMETOP=jtsplash_game_sdram` right after `CORENAME=SPLASH` in `cfg/macros.def`. See
this diff for the exact one-line change.

## `mame2mra-skip-vs-upstream.diff`

`jtframe mra splash` aborted with:

```
MRA Build: jtframe mra failed: While parsing region gfx: Unknown ROM length for ROM splash_10.i13 (CRC febb9893)
```

`cfg/mame2mra.toml`'s `[parse] mustbe.machines=["splash"]` pulls in every MAME machine whose
`cloneof` chases back to `splash` (`is_family`, `mame2mra.go`), not just the parent set. MAME's
`gaelco/splash.cpp` lists three such "clones" — `nsplashkr`, `nsplashkra` (New Splash, Korea) and
`paintlad` (Painted Lady, North America) — whose `gfx` ROMs are **not** `merge=` aliases of the
parent's: different filenames *and* different CRCs (genuinely redrawn/censored artwork for those
regional releases, not a simple revision). `cfg/mame2mra.toml`'s `[ROM] regions.gfx.parts` are
hardcoded to the World parent's four ROM CRCs, so the moment `jtframe mra`'s streaming XML walk
(document order, not alphabetical — `nsplashkr` sorts before `splash` itself in `doc/mame.xml`)
reaches one of these three, `find_rom` (`corerom.go`) can't match either name or CRC and the whole
run aborts fatally — before it ever reaches the real `splash` parent later in the file. The other
five family members (`splash10`/`11`/`12`, `splashkr`, `splashna`) *do* use `merge=` (identical gfx
data, just a maincpu program revision) and build fine once the three divergent ones are excluded.

**Fix:** add a `[parse.skip] setnames=[...]` block listing the three divergent setnames (same
mechanism `cores/rastan` and `cores/s16b` already use to drop incompatible-hardware bootlegs from
their own family). Verified locally: `jtframe mra splash -v` now reports `Total: 6 games` and
writes all six `.mra` files (`splash`, `splash10/11/12`, `splashkr`, `splashna`).

Pinned base: `javi-ivaj/splash-fpga` commit `0b5464142fb5cc73b2cb18689024bd43ee4abd10`.
