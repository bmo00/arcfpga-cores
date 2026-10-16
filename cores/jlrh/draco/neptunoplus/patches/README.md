# Patches — draco / neptunoplus

## `draco_machine-no-synth-readmemh.patch`

Removes the `` `else `` branch of `hdl/rtl/draco_machine.v`'s ROM-init block — the synthesis-time
`initial $readmemh("draco_prog.hex", rom)` — keeping only the `` `ifdef SIM `` branch used by testbenches.

**Why**: identical to `cores/destroyer/neptunoplus/patches/cidelsa_machine-no-synth-readmemh.patch`
(same upstream repo, `jlrh/cidelsa-fpga`, same ROM-init idiom). This repo never commits ROM data, so
`draco_prog.hex` never exists and Quartus fails with `Error (10054): can't open Verilog Design File`; a
placeholder `.hex` would not be staged anyway (arcfpga-ui only stages
`neptunoplus/*.{qpf,qsf,sdc,v,sv,vhd,qip}`). The real ROM always arrives at runtime over
`ioctl_rom_we`, and the CPU is held in reset until that download finishes (`rom_loaded` in
`neptunoplus/draco_neptunoplus.sv`), so leaving `rom` uninitialised at power-up is harmless.

Applied by arcfpga-ui with `patch -p0 --fuzz=0` onto the staged workspace (headers are relative to
`cores/draco/`). Pinned base: `jlrh/cidelsa-fpga` commit `8e65f3a460e5d436293fafb702bcd89db4c64722`.

## `draco_machine-sync-rom-read.patch`

Makes `hdl/rtl/draco_machine.v`'s reads of `rom` (16KB program ROM) and `dram` (1KB work RAM)
registered (`always @(posedge clk)`) instead of combinational, behind the same `` `ifdef MEM_ASYNC ``
switch `altair_machine.v` and `cidelsa_machine.v` already use.

**Why**: upstream reads both arrays asynchronously and tags them `ramstyle = "MLAB"` — fine on
MiSTer's Cyclone V, which has MLAB (LUT-RAM with async read). Cyclone IV GX (NeptUNO+) has no MLAB
and its M9K blocks only support synchronous reads, so Quartus 13.1 reports "uninferred due to
asynchronous read logic" and builds them out of registers: 174,083 registers against 149,760
available — `Error (170011) ... Can't fit design in device`. Registering the read is the exact
pattern the same upstream author uses for Altair/Destroyer (their MiSTer builds never define
`MEM_ASYNC`, so they already run this way), with the same CDP1802 core: the CPU only samples
`data_in` on `ce_cpu` (554kHz), dozens of `clk` cycles after the address settles, so the one-cycle
read latency is invisible to it.
