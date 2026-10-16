# cfg/macros.def divergence from upstream: GAMETOP

`cores/momoko` is vendored from `javi-ivaj/momoko120-fpga` (see `cores.json`'s
`external.repo`/`external.commit`). This core's own `cfg/macros.def` is freely edited in place
here (unlike `modules/jtframe`, which stays a clean checkout patched only via a core's own
`patches/` dir when it needs a framework-level change — see `cores/bucky/patches/README.md` for
that other case) — this file documents *why* our copy no longer matches upstream byte-for-byte.

**Upstream's `CORENAME=MOMOKO` doesn't carry the `jt` prefix** (this repo's convention for
"core no oficial" / unofficial cores — see `cores/tantr`, `cores/opwolf`, `cores/moomesa`,
`cores/ssriders`, `cores/pspikes`, `cores/empirecity` for the same pattern). `jtframe`'s own
`GAMETOP` macro defaults to `<CORENAME>_game_sdram` lowercased when unset and `mem.yaml` triggers
`JTFRAME_MEMGEN` (`macros.go`'s `make_gametop_macro`) — for momoko that resolves to
`momoko_game_sdram`. But `jtframe mem`'s own generator (`mem.go`'s `get_path`, prefix branch)
always writes the memory-derived top wrapper as `jt<core>_game_sdram.v` using the core's directory
name (`momoko`), regardless of what `CORENAME` says — so the real generated file/module is
`jtmomoko_game_sdram`, never `momoko_game_sdram`.

Without an explicit `GAMETOP` override, `jtframe_game_instance.v`'s `` `GAMETOP `` macro expands to
the wrong (nonexistent) module name for the `u_game` instance. This only surfaces at synthesis
time, once `JTFRAME_MEMGEN` is live (i.e. once `mem.yaml` exists and gets built for a real target):

```
Error (12006): Node instance "u_game" instantiates undefined entity "momoko_game_sdram"
File: modules/jtframe/hdl/inc/jtframe_game_instance.v Line: 224
```

**Fix:** add `GAMETOP=jtmomoko_game_sdram` right after `CORENAME=MOMOKO` in `cfg/macros.def`,
matching every other unofficial-name core listed above (see `macros-def-gametop-vs-upstream.diff`
for the exact one-line change; same fix applied to `cores/splash` — see that core's own
`patches/README.md`).

Pinned base: `javi-ivaj/momoko120-fpga` commit `69b3e9e4f97b29cfdbd676ecaee0056728d44aa7`.
