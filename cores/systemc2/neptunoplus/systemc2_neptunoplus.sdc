# systemc2_neptunoplus.sdc — timing constraints for the NeptUNO+ bridge
# Common structure shared by every NeptUNO+ bridge in this repo — see
# doc/porting-a-native-core.md §7 ("Shared .qpf/.qsf/.sdc template").
# SDRAM_CLK is generated inside ../hdl/rtl/sdram.sv by its own altddio_out register, clocked from
# c1 below (clk_ram) — a plain DDIO output register, not a PLL of its own (see
# neptunoplus/patches/README.md). The adapter's own PLL (pll.v, retuned from c2_system's own
# upstream pll.v — see that file's header) is the only PLL in the design.

# ---- Clocks ----
create_clock -name {CLOCK_27} -period 20.000 [get_ports {CLOCK_27[0]}]
create_clock -name {SPI_SCK}  -period 41.666 -waveform { 20.8 41.666 } [get_ports {SPI_SCK}]

# ---- PLL clock derivation ----
derive_pll_clocks -create_base_clocks

# ---- PLL clock names ----
# clk[0]=53.693175MHz (clk_sys: user_io/data_io/68000/VDP/sound), clk[1]=107.38635MHz (clk_ram:
# SDRAM controller clock + SDRAM_CLK source) — both from the single `pll` instance in
# systemc2_neptunoplus, see pll.v's own header comment.
set sys_clk   "pll|altpll_component|auto_generated|pll1|clk[0]"
set sdram_clk "pll|altpll_component|auto_generated|pll1|clk[1]"

# A real, explicit generated clock on the SDRAM_CLK pin itself (sourced from clk[1], the same
# internal clock that drives it — see sdram.sv's own altddio_out register), not just a raw
# reference to the internal clk[1] node. Same technique modules/jtframe/target/neptunoplus's own
# neptunoplus.sdc uses for every jtframe-built SDRAM-backed core on this exact board (there sourced
# from its own pll's `clk[0]`, whichever output that target's PLL uses for the SDRAM clock) — this
# correctly accounts for the pin's own real clock-network/pad latency from clk[1], which a plain
# `-clock [get_clocks $sdram_clk]` reference on the SDRAM_DQ constraints below would not.
create_generated_clock -name SDRAM_CLK -source [get_pins {pll|altpll_component|auto_generated|pll1|clk[1]}] -divide_by 1 [get_ports SDRAM_CLK]

derive_clock_uncertainty

# ---- SPI / IO-controller input delays ----
set_input_delay -add_delay -clock_fall -clock [get_clocks {CLOCK_27}] 1.000 [get_ports {CLOCK_27[0]}]
set_input_delay -add_delay -clock_fall -clock [get_clocks {SPI_SCK}]  1.000 [get_ports {CONF_DATA0}]
set_input_delay -add_delay -clock_fall -clock [get_clocks {SPI_SCK}]  1.000 [get_ports {SPI_DI}]
set_input_delay -add_delay -clock_fall -clock [get_clocks {SPI_SCK}]  1.000 [get_ports {SPI_SCK}]
set_input_delay -add_delay -clock_fall -clock [get_clocks {SPI_SCK}]  1.000 [get_ports {SPI_SS2}]
set_input_delay -add_delay -clock_fall -clock [get_clocks {SPI_SCK}]  1.000 [get_ports {SPI_SS3}]
set_input_delay -add_delay -clock_fall -clock [get_clocks {SPI_SCK}]  1.000 [get_ports {SPI_SS4}]

# ---- SDRAM timing (referenced to the SDRAM_CLK generated clock above) ----
# tAC/tOH and tDS/tDH values match modules/jtframe/target/neptunoplus's own neptunoplus.sdc exactly
# (the real, hardware-validated numbers for this board's actual SDRAM chip) — this bridge's earlier
# numbers (6.6/3.5) were an unvalidated guess carried over from craterraider_neptunoplus.sdc's own
# (80MHz-clocked, different core) values.
set_input_delay -clock SDRAM_CLK -max 6 [get_ports SDRAM_DQ[*]]
set_input_delay -clock SDRAM_CLK -min 3 [get_ports SDRAM_DQ[*]]
set_output_delay -clock SDRAM_CLK -max 1.5 [get_ports {SDRAM_A[*] SDRAM_BA[*] SDRAM_CKE SDRAM_DQMH SDRAM_DQML SDRAM_DQ[*] SDRAM_nCAS SDRAM_nCS SDRAM_nRAS SDRAM_nWE}]
set_output_delay -clock SDRAM_CLK -min -0.8 [get_ports {SDRAM_A[*] SDRAM_BA[*] SDRAM_CKE SDRAM_DQMH SDRAM_DQML SDRAM_DQ[*] SDRAM_nCAS SDRAM_nCS SDRAM_nRAS SDRAM_nWE}]

# ---- Other output delays (LED/AUDIO/VGA) ----
set_output_delay -add_delay -clock [get_clocks {SPI_SCK}] 1.000 [get_ports {SPI_DO}]
set_output_delay -add_delay -clock [get_clocks $sys_clk]  1.000 [get_ports {AUDIO_L}]
set_output_delay -add_delay -clock [get_clocks $sys_clk]  1.000 [get_ports {AUDIO_R}]
set_output_delay -add_delay -clock [get_clocks $sys_clk]  1.000 [get_ports {LED}]
set_output_delay -add_delay -clock [get_clocks $sys_clk]  1.000 [get_ports {VGA_*}]

# ---- Clock groups ----
set_clock_groups -asynchronous -group [get_clocks {SPI_SCK}] -group [get_clocks {pll|altpll_component|auto_generated|pll1|clk[*]}]

# ---- Multicycle paths ----
set_multicycle_path -to {VGA_*[*]} -setup 2
set_multicycle_path -to {VGA_*[*]} -hold 1

# Every exception below was found empirically on 2026-09-03 by reproducing this exact build in
# `raetro/quartus:13.1` locally and running `report_timing -setup/-hold -npaths 10 -detail
# full_path` after each fix — see NOTES.md's "Real hardware findings" -> "Resolution" for the full
# story (six rounds of build+report, in order) and the on-hardware symptoms the missing set caused
# (drifting video, no audio, unreliable controls). Verified together: zero
# `Timing requirements not met`, positive setup and hold slack on all three PVT corners.

# 1. SDRAM read data capture (physical pin -> controller register), the single dominant failure
# (worst: -2.105ns) — analyzed as single-cycle (9.312ns) by default, which the real tAC/tOH input
# delay above cannot fit within at this core's 107.38635MHz clk_ram. Same exception
# modules/jtframe/target/neptunoplus/syn/neptunoplus.sdc uses for every jtframe-built SDRAM-backed
# core on this board (`SDRAM_DQ[*] -> jtframe_sdram64:u_sdram|dout[*]`) — this bridge's own
# `sdram.sv` instance is named `sdram`, giving `sdram:sdram|dout[*]` here. Matches the controller's
# own CAS_LATENCY=2 design intent, not an arbitrary relaxation.
set_multicycle_path -setup -end -from [get_keepers {SDRAM_DQ[*]}] -to [get_keepers {sdram:sdram|dout[*]}] 2

# Hold-side companion, both directions of the SDRAM_CLK<->clk[1] clock *relationship* (not a single
# register pair): jtframe's own precedent only has the input direction (SDRAM_CLK launching,
# clk[1] latching — the hold counterpart of exception 1 above); the output direction (clk[1]
# launching, SDRAM_CLK latching) was this bridge's own addition, needed for
# `sdram:sdram|SDRAM_DQ[n]~en -> SDRAM_DQ[n]` (the fast output-enable register driving the
# bidirectional SDRAM_DQ tri-state buffer) — once every setup violation below was fixed, this was
# the entire remaining `Timing requirements not met` on all three corners (worst -0.394ns, driven
# by a real ~3ns clock-skew difference between clk[1] reaching this fast register directly vs.
# reaching the SDRAM_CLK pin through its own DDIO register + pad).
set_multicycle_path -hold -end -from [get_clocks {SDRAM_CLK}] -to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] 2
set_multicycle_path -hold -end -from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -to [get_clocks {SDRAM_CLK}] 2

# 2. `sdram`'s registered `dout` bus (clk_ram) -> every clk_sys-domain register that ever captures
# it (`dout0`/`dout1`/`dout2` are all aliases of the same `dout` reg, per the vendored top's own
# `assign dout0 = dout;` etc.) — the same relationship the upstream MiSTer top's own
# Arcade-SystemC2.sdc documents (there for `emu|sdram|dout*` -> `emu|c2|data*`; `emu` is a child
# instance of the MiSTer framework's own top wrapper there, not the design root, unlike this
# bridge's own `systemc2_neptunoplus`, hence no top-level prefix here). Deliberately no `-to`
# filter: three separate consumers were found one at a time this way
# (`c2_system:c2|data[*]`, a second register also fed directly from ROM_DATA
# `c2_system:c2|NO_DATA[*]`, and a third hop through this adapter's own `pcm_data` mux into
# `c2_system:c2|jt7759:pcm|jt7759_data:u_data|fifo[*]`) — relaxing the whole bus at the source
# matches the controller's real design intent (nothing reads `dout` without first waiting for the
# matching `ack*` to toggle) better than an incomplete, ever-growing list of named destinations.
set_multicycle_path -from {sdram|dout*} -setup 2
set_multicycle_path -from {sdram|dout*} -hold 1

# 3. Same toggle-handshake pattern as `dout` above, for the SDRAM controller's own three
# acknowledge signals (`ack0`/`ack1`/`ack2` — consumed by `c2_romload`'s own download FIFO,
# `c2_system` directly, and this adapter's own top-level pcm glue respectively). No upstream .sdc
# exception either (same "Cyclone V doesn't need it" pattern as every exception here) — also
# relaxed with no `-to` filter, same reasoning as `dout*`.
set_multicycle_path -from {sdram|ack0} -setup 2
set_multicycle_path -from {sdram|ack0} -hold 1
set_multicycle_path -from {sdram|ack1} -setup 2
set_multicycle_path -from {sdram|ack1} -hold 1
set_multicycle_path -from {sdram|ack2} -setup 2
set_multicycle_path -from {sdram|ack2} -hold 1

# 4. FX68K's own author-documented worst-case path (`../hdl/rtl/FX68K/fx68k.txt`, "Timing
# analysis": "Microcode access is one of the slowest paths on the core"). `fx68k` is instantiated
# as `M68K` inside `c2_system` (`c2` here) -> `c2|M68K|...`. Syntax matches
# modules/jtframe/target/neptunoplus/syn/neptunoplus.sdc's own real, hardware-validated form
# exactly (no `-start` — jtframe's own comment there notes a real measured -0.630ns regression on
# `tantr` without this fix) rather than the generic `-start`-qualified form fx68k.txt's own doc
# comment shows (functionally equivalent here since Ir/microAddr/nanoAddr all share the single
# clk_sys domain, but matching the proven form reduces risk).
set_multicycle_path -from [get_keepers {c2|M68K|Ir[*]}] -to [get_keepers {c2|M68K|microAddr[*]}] -setup 2
set_multicycle_path -from [get_keepers {c2|M68K|Ir[*]}] -to [get_keepers {c2|M68K|microAddr[*]}] -hold 1
set_multicycle_path -from [get_keepers {c2|M68K|Ir[*]}] -to [get_keepers {c2|M68K|nanoAddr[*]}] -setup 2
set_multicycle_path -from [get_keepers {c2|M68K|Ir[*]}] -to [get_keepers {c2|M68K|nanoAddr[*]}] -hold 1

# ---- False paths (async relay signals) ----
set_false_path -from [get_ports {SD_MISO}]
set_false_path -from [get_ports {SD_SCK}]
set_false_path -from [get_ports {JOY_DATA}]
set_false_path -to   [get_ports {XJOY_DATA}]
set_false_path -to   [get_ports {JOY_CLK}]
set_false_path -to   [get_ports {JOY_LOAD}]
set_false_path -to   [get_ports {JOY_SELECT}]
