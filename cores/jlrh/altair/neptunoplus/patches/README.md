# Patches — altair / neptunoplus

## `altair_machine-no-synth-readmemh.patch`

Removes the `` `else `` branch of `hdl/rtl/altair_machine.v`'s ROM-init block — the synthesis-time
`initial $readmemh("altair_prog.hex", rom)` — keeping only the `` `ifdef SIM `` branch used by testbenches.

**Why**: identical to `cores/destroyer/neptunoplus/patches/cidelsa_machine-no-synth-readmemh.patch`
(same upstream repo, `jlrh/cidelsa-fpga`, same ROM-init idiom). This repo never commits ROM data, so
`altair_prog.hex` never exists and Quartus fails with `Error (10054): can't open Verilog Design File`; a
placeholder `.hex` would not be staged anyway (arcfpga-ui only stages
`neptunoplus/*.{qpf,qsf,sdc,v,sv,vhd,qip}`). The real ROM always arrives at runtime over
`ioctl_rom_we`, and the CPU is held in reset until that download finishes (`rom_loaded` in
`neptunoplus/altair_neptunoplus.sv`), so leaving `rom` uninitialised at power-up is harmless.

Applied by arcfpga-ui with `patch -p0 --fuzz=0` onto the staged workspace (headers are relative to
`cores/altair/`). Pinned base: `jlrh/cidelsa-fpga` commit `8e65f3a460e5d436293fafb702bcd89db4c64722`.
