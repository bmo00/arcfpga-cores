# Patches — destroyer / neptunoplus

## `cidelsa_machine-no-synth-readmemh.patch`

Removes the `` `else `` branch of `hdl/rtl/cidelsa_machine.v`'s ROM-init block — the synthesis-time
`initial $readmemh("destryer_prog.hex", rom)` that runs whenever `` `SIM `` is not defined (i.e. on a
real Quartus build), keeping only the `` `ifdef SIM `` branch (`$readmemh("../../roms/destryer_prog.hex", ...)`,
used by `jtsim`/testbenches, unaffected by this patch).

**Why**: the vendored file's own synthesis path expects a real `destryer_prog.hex` (the 8KB program
ROM, 4×2KB parts per `../../mra/Destroyer (FF, Cidelsa, 1980).mra`) to exist on disk, found via
`../hdl/mister/files.qip`'s own `SEARCH_PATH ../roms` in the upstream MiSTer project. This repo
never commits ROM data (see the top-level `CLAUDE.md`), so that file will never exist here — a real
Quartus build fails outright (`Error (10054): ... can't open Verilog Design File "destryer_prog.hex"`)
without this patch. A first attempt at fixing this by committing a dummy placeholder `.hex` file
directly under `neptunoplus/` (plus a `SEARCH_PATH .` in the `.qsf`) did **not** work: `arcfpga-ui`'s
own `nativeWorkspace.ts` only stages `neptunoplus/` files matching
`/\.(qpf|qsf|sdc|v|sv|vhd|qip)$/i` into the throwaway build workspace — `.hex` is filtered out, so
the placeholder was never actually visible to the real Quartus build, regardless of `SEARCH_PATH`.

Removing the synthesis-time `$readmemh` outright is the correct fix, not a workaround for the
staging filter: `cidelsa_machine`'s `rom` array is always fully (re)written by
`ioctl_rom_we`/`ioctl_rom_addr`/`ioctl_rom_data` before the game actually runs (the NeptUNO+
bridge's own `data_io` + `.mra` ROM-download pipeline, same as every other native/jtframe core on
this platform) — the synthesis-time init was only ever useful for the upstream MiSTer flow's own
"drop your own ROM next to the project and compile" convenience, which this repo's runtime-download
convention doesn't need. Leaving `rom` uninitialized at power-up is harmless (BRAM contents before
the first ROM download are never read by anything a player would notice — attract mode doesn't start
until the CPU is out of reset, which itself is gated on `rom_loaded` in
`neptunoplus/destroyer_neptunoplus.sv`).
