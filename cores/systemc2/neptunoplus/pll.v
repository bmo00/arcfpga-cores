// pll.v — NeptUNO+-specific replacement of Arcade-SystemC2's own system PLL
//
// NOT a vendored/pinned copy of ../hdl/rtl/pll.v (that file stays pristine at external.commit,
// per doc/porting-a-native-core.md §2.1). The pinned file is a thin wrapper around
// ../hdl/rtl/pll/pll_0002.v, an `altera_pll` instance (Intel's fractional-N PLL IP, Cyclone
// V/Arria 10-class only) generated for the upstream board's `5CEBA2F17A7`, with two outputs:
//
//   outclk_0 = 53.693175 MHz  (clk0_multiply_by=8 + a 32-bit fractional part, clk0_divide_by=8)
//   outclk_1 = 107.38635  MHz (exactly 2x outclk_0), clk1_phase_shift = -60 degrees of its own
//              period, clk1_divide_by=4
// both from a 50 MHz reference — plus a `reconfig_to_pll`/`reconfig_from_pll` pair and a
// `pll_cfg` reconfiguration IP the vendored top-level (Arcade-SystemC2.sv) drives with a sequence
// that provably never fires (its own state machine starts at 0 and only advances `if (state)`,
// which is always false — see that file's own header comment: "Left instantiated because the
// .qip expects it; simply never triggered"). This bridge's own adapter does not clone that dead
// reconfiguration path at all, so this replacement carries no reconfig ports.
//
// NeptUNO+ has no `altera_pll` primitive (different silicon generation) — this is a same-named,
// same-ratio reimplementation using the classic `altpll` megafunction Cyclone IV GX actually has,
// same technique as cores/craterraider/neptunoplus/pll_mist.v or cores/mariobros/neptunoplus/pll.v.
//
// NeptUNO+'s CLOCK_27[0] is a real 50 MHz oscillator (same as MiSTer's CLK_50M the upstream design
// already assumes — see jtframe_neptunoplus_top.sv's own "27MHz for MiST, 50MHz for Neptuno"
// comment), so no reference-frequency conversion is needed, only a device-family swap plus
// re-deriving integer multiply/divide ratios for the same two output frequencies (classic altpll
// has no fractional-N mode, so the wizard's own frac_multiply_factor can't be reused directly):
//
//   c0 (clk_sys,  53.693175 MHz): 50 * 189/176 = 53.693181818... MHz  (0.013 ppm off nominal)
//   c1 (clk_ram, 107.38635  MHz): 50 * 189/88  = 107.386363636... MHz (exactly 2x c0, as required)
//
// clk1_phase_shift keeps the upstream -60 degree (of c1's own period) offset: period(c1) =
// 1/107,386,363.636 Hz = 9312.157 ps; -60/360 * 9312.157 = -1552.03 ps, rounded to the nearest ps.
// This offset matters for real hardware (it is not merely a trace-delay tweak on SDRAM_CLK, which
// is generated separately inside ../hdl/rtl/sdram.sv by its own DDIO register clocked from c1) —
// it is how the upstream design keeps clk_ram's rising edges phase-locked to clk_sys for the
// 68000/VDP/SDRAM-controller bus-arbitration state machines that assume a fixed clk_ram-per-clk_sys
// relationship. Unverified on real Quartus/hardware — flag if the core boots but shows RAM
// corruption or bus-arbitration glitches, the classic symptom of this being wrong (see
// doc/porting-a-native-core.md §2.2).

// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module pll (
	input  wire areset,
	input  wire inclk0,
	output wire c0,
	output wire c1,
	output wire locked
);

	wire [4:0] sub_wire0;
	wire sub_wire2;
	assign c0 = sub_wire0[0];
	assign c1 = sub_wire0[1];
	assign locked = sub_wire2;

	altpll altpll_component (
				.areset (areset),
				.inclk ({1'b0, inclk0}),
				.clk (sub_wire0),
				.locked (sub_wire2),
				.activeclock (),
				.clkbad (),
				.clkena ({6{1'b1}}),
				.clkloss (),
				.clkswitch (1'b0),
				.configupdate (1'b0),
				.enable0 (),
				.enable1 (),
				.extclk (),
				.extclkena ({4{1'b1}}),
				.fbin (1'b1),
				.fbmimicbidir (),
				.fbout (),
				.fref (),
				.icdrclk (),
				.pfdena (1'b1),
				.phasecounterselect ({4{1'b1}}),
				.phasedone (),
				.phasestep (1'b1),
				.phaseupdown (1'b1),
				.pllena (1'b1),
				.scanaclr (1'b0),
				.scanclk (1'b0),
				.scanclkena (1'b1),
				.scandata (1'b0),
				.scandataout (),
				.scandone (),
				.scanread (1'b0),
				.scanwrite (1'b0),
				.sclkout0 (),
				.sclkout1 (),
				.vcooverrange (),
				.vcounderrange ());
	defparam
		altpll_component.bandwidth_type = "AUTO",
		altpll_component.clk0_divide_by = 176,
		altpll_component.clk0_duty_cycle = 50,
		altpll_component.clk0_multiply_by = 189,
		altpll_component.clk0_phase_shift = "0",
		altpll_component.clk1_divide_by = 88,
		altpll_component.clk1_duty_cycle = 50,
		altpll_component.clk1_multiply_by = 189,
		altpll_component.clk1_phase_shift = "-1552",
		altpll_component.compensate_clock = "CLK0",
		altpll_component.inclk0_input_frequency = 20000,
		altpll_component.intended_device_family = "Cyclone IV GX",
		altpll_component.lpm_hint = "CBX_MODULE_PREFIX=pll",
		altpll_component.lpm_type = "altpll",
		altpll_component.operation_mode = "NORMAL",
		altpll_component.pll_type = "AUTO",
		altpll_component.port_activeclock = "PORT_UNUSED",
		altpll_component.port_areset = "PORT_USED",
		altpll_component.port_clkbad0 = "PORT_UNUSED",
		altpll_component.port_clkbad1 = "PORT_UNUSED",
		altpll_component.port_clkloss = "PORT_UNUSED",
		altpll_component.port_clkswitch = "PORT_UNUSED",
		altpll_component.port_configupdate = "PORT_UNUSED",
		altpll_component.port_fbin = "PORT_UNUSED",
		altpll_component.port_inclk0 = "PORT_USED",
		altpll_component.port_inclk1 = "PORT_UNUSED",
		altpll_component.port_locked = "PORT_USED",
		altpll_component.port_pfdena = "PORT_UNUSED",
		altpll_component.port_phasecounterselect = "PORT_UNUSED",
		altpll_component.port_phasedone = "PORT_UNUSED",
		altpll_component.port_phasestep = "PORT_UNUSED",
		altpll_component.port_phaseupdown = "PORT_UNUSED",
		altpll_component.port_pllena = "PORT_UNUSED",
		altpll_component.port_scanaclr = "PORT_UNUSED",
		altpll_component.port_scanclk = "PORT_UNUSED",
		altpll_component.port_scanclkena = "PORT_UNUSED",
		altpll_component.port_scandata = "PORT_UNUSED",
		altpll_component.port_scandataout = "PORT_UNUSED",
		altpll_component.port_scandone = "PORT_UNUSED",
		altpll_component.port_scanread = "PORT_UNUSED",
		altpll_component.port_scanwrite = "PORT_UNUSED",
		altpll_component.port_clk0 = "PORT_USED",
		altpll_component.port_clk1 = "PORT_USED",
		altpll_component.port_clk2 = "PORT_UNUSED",
		altpll_component.port_clk3 = "PORT_UNUSED",
		altpll_component.port_clk4 = "PORT_UNUSED",
		altpll_component.port_clk5 = "PORT_UNUSED",
		altpll_component.port_clkena0 = "PORT_UNUSED",
		altpll_component.port_clkena1 = "PORT_UNUSED",
		altpll_component.port_clkena2 = "PORT_UNUSED",
		altpll_component.port_clkena3 = "PORT_UNUSED",
		altpll_component.port_clkena4 = "PORT_UNUSED",
		altpll_component.port_clkena5 = "PORT_UNUSED",
		altpll_component.port_extclk0 = "PORT_UNUSED",
		altpll_component.port_extclk1 = "PORT_UNUSED",
		altpll_component.port_extclk2 = "PORT_UNUSED",
		altpll_component.port_extclk3 = "PORT_UNUSED",
		altpll_component.self_reset_on_loss_lock = "OFF",
		altpll_component.width_clock = 5;

endmodule
