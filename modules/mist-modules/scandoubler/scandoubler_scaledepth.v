// Utility module for scaling the bit depth of a signal
// Factored out of the scandoubler by AMR, and adjusted to cope with 
// output bit depth being less than input depth

module scandoubler_scaledepth (
	input [IN_DEPTH-1:0] d,
	output wire [OUT_DEPTH-1:0] q
);	
parameter IN_DEPTH = 6;
parameter OUT_DEPTH = 6;

localparam m = OUT_DEPTH < IN_DEPTH ? 1 : OUT_DEPTH/IN_DEPTH;
localparam n = OUT_DEPTH < IN_DEPTH ? 0 : OUT_DEPTH%IN_DEPTH;
localparam o = OUT_DEPTH < IN_DEPTH ? OUT_DEPTH : IN_DEPTH; 

reg[OUT_DEPTH-1:0] scaled;

// n==0 whenever OUT_DEPTH is an exact multiple of IN_DEPTH (e.g. IN_DEPTH==OUT_DEPTH, the common
// "no scaling needed" case) — d[IN_DEPTH-1 -:n] is then a zero-width part-select. The original
// plain `if`/`else` here left both branches inside one always block, so Verilator still
// width-checks the untaken n==0 branch during elaboration regardless of the runtime condition
// (IEEE 1800 requires procedural if/else branches to elaborate together) and hard-errors on it
// even though it's never actually reached for that parameterization. `generate if` is elaborated
// at compile time instead, so only the live branch is ever type-checked. (arcfpga-cores-develop
// local fix — shared by every core that reuses modules/mist-modules/, see
// doc/porting-a-native-core.md's own note on this module.)
generate
if (m>0) begin : gen_m
	if (n>0) begin : gen_n
		always @(*) scaled = { {m{d[IN_DEPTH-1 -:o]}}, d[IN_DEPTH-1 -:n] };
	end else begin : gen_no_n
		always @(*) scaled = { {m{d[IN_DEPTH-1 -:o]}} };
	end
end
endgenerate

assign q=scaled;

endmodule

