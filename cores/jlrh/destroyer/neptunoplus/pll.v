// pll.v — NeptUNO+-specific replacement of cidelsa_machine's would-be system PLL
//
// This is NOT a vendored/pinned copy of ../hdl/mister/pll.v (that file stays pristine at
// external.commit, per doc/porting-a-native-core.md §2.1). The pinned file instantiates
// `altera_pll` — Intel's fractional-PLL IP for Cyclone V/Arria 10-class devices, generated for the
// upstream MiSTer board's `5CSEBA6U23I7` (DE10-Nano). NeptUNO+ is a Cyclone IV GX
// (`EP4CGX150DF27I7`), a different silicon generation with no `altera_pll` primitive at all — this
// is not a retune, it is a same-named, same-port-list reimplementation using the classic `altpll`
// megafunction Cyclone IV actually has, same technique as cores/mariobros/neptunoplus/pll.v.
//
// Ratio is unchanged from the pinned file: the upstream design already takes a 50 MHz reference
// (MiSTer's CLK_50M, not MiST's 27 MHz) and multiplies to 30 MHz (clk0_multiply_by=3,
// clk0_divide_by=5 below: 50MHz * 3/5 = 30MHz exactly, matching ../hdl/mister/pll.v's own
// "50->30 MHz" comment and ../hdl/mister/README.md's "PLL 50->30 MHz (clk_sys)" note). NeptUNO+'s
// CLOCK_27[0] is also a real 50 MHz oscillator (see jtframe_neptunoplus_top.sv's own "27MHz for
// MiST, 50MHz for Neptuno" comment), so — same as mariobros — this is a case where no retune
// arithmetic is needed at all, only the device family/IP primitive changes.
//
// Note: the pinned file's own header comment ("JERARQUÍA: módulo pll -> pll_inst (pll_core) ->
// altera_pll_i... OBLIGATORIA para... sys_top.sdc") documents a hierarchy requirement specific to
// MiSTer's own sys_top.sdc clock-group matching — this bridge writes its own
// destroyer_neptunoplus.sdc from scratch (doc/porting-a-native-core.md §7), so that constraint does
// not apply here; the flatter pll -> altpll_component hierarchy below (matching mariobros/pll.v) is
// sufficient.

// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module pll (
	input  wire refclk,
	input  wire rst,
	output wire outclk_0,
	output wire locked
);

	wire [4:0] sub_wire0;
	wire sub_wire2;
	assign outclk_0 = sub_wire0[0];
	assign locked = sub_wire2;

	altpll altpll_component (
				.areset (rst),
				.inclk ({1'b0, refclk}),
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
		altpll_component.clk0_divide_by = 5,
		altpll_component.clk0_duty_cycle = 50,
		altpll_component.clk0_multiply_by = 3,
		altpll_component.clk0_phase_shift = "0",
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
		altpll_component.port_clk1 = "PORT_UNUSED",
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
