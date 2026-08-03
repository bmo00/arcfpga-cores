//============================================================================
//  mystston_sound — Sound subsystem for Mysterious Stones (Technos 1984)
//  Two AY-3-8910 driven through a shared BC1/BDIR bus (mystston.cpp's
//  ay8910_select_w): bits 4/5 = BC1/BDIR for chip 0, bits 6/7 = BC1/BDIR for
//  chip 1. jt49's real interface (modules/jt49/hdl/jt49.v — cfg/files.yaml's
//  bare `jt49:` key resolves here, not modules/jt12/jt49/) is a plain
//  decoded register-file bus (addr/cs_n/wr_n/din, no bc1/bdir pins at all),
//  so this module translates the BC1/BDIR protocol into that interface by
//  detecting BDIR's falling edge (the same trigger mystston.cpp's own
//  ay8910_select_w uses) and reading the OLD select-register value (the one
//  held right before this write) to see what BC1 was during the BDIR-high
//  phase: BC1=1 -> latch snd_latch into the address register, BC1=0 -> write
//  snd_latch to the already-latched address.
//  License: GPLv3
//============================================================================

module mystston_sound(
    input               clk,
    input               rst,
    input               cen_ay,             // 1.5 MHz AY clock enable

    // Control from main CPU (latched at 0x2030 / 0x2040)
    input       [7:0]   snd_latch,          // data for AY8910
    input       [7:0]   snd_sel,            // select register: BC1/BDIR pins
    input               snd_sel_we,         // pulse: snd_sel was written this cycle

    // Audio outputs (raw jt49 sums — mem.yaml's audio: section already
    // configures the framework's own mixer/rsum/gain for these two channels)
    output      [9:0]   ay1,
    output      [9:0]   ay2
);

    // One-cycle-delayed copy of snd_sel to detect BDIR falling edges and read
    // what BC1 was during the preceding BDIR-high phase, exactly like
    // mystston.cpp's ay8910_select_w compares *m_ay8910_select (old) to data
    // (new, i.e. today's snd_sel).
    reg [7:0] snd_sel_l;
    always @(posedge clk, posedge rst) begin
        if (rst) snd_sel_l <= 8'd0;
        else     snd_sel_l <= snd_sel;
    end

    // Gated by snd_sel_we (an explicit write-strobe from mystston_main.v's own
    // address decoder) rather than the snd_sel_l/snd_sel comparison alone, so
    // the detected edge is guaranteed to line up with a genuine register
    // write on this exact cycle.
    wire bdir0_fall = snd_sel_we & snd_sel_l[5] & ~snd_sel[5];
    wire bdir1_fall = snd_sel_we & snd_sel_l[7] & ~snd_sel[7];
    wire ay0_latch  = bdir0_fall &  snd_sel_l[4]; // BC1=1: latch address
    wire ay0_write  = bdir0_fall & ~snd_sel_l[4]; // BC1=0: write data
    wire ay1_latch  = bdir1_fall &  snd_sel_l[6];
    wire ay1c_write = bdir1_fall & ~snd_sel_l[6];

    reg [3:0] ay0_addr, ay1_addr;
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            ay0_addr <= 4'd0;
            ay1_addr <= 4'd0;
        end else begin
            if (ay0_latch) ay0_addr <= snd_latch[3:0];
            if (ay1_latch) ay1_addr <= snd_latch[3:0];
        end
    end

    //------------------------------------------------------------------
    // AY-3-8910 #1 (chip 0)
    //------------------------------------------------------------------
    /* verilator tracing_off */
    jt49 u_ay1(
        .rst_n      ( ~rst          ),
        .clk        ( clk           ),
        .clk_en     ( cen_ay        ),
        .addr       ( ay0_addr      ),
        .cs_n       ( 1'b0          ),
        .wr_n       ( ~ay0_write    ),
        .din        ( snd_latch     ),
        .sel        ( 1'b1          ), // full rate: cen_ay is already 1.5MHz (MASTER_CLOCK/8)
        .dout       (               ),
        .sound      ( ay1           ),
        .A          (               ),
        .B          (               ),
        .C          (               ),
        .sample     (               ),
        .IOA_in     ( 8'd0          ),
        .IOA_out    (               ),
        .IOA_oe     (               ),
        .IOB_in     ( 8'd0          ),
        .IOB_out    (               ),
        .IOB_oe     (               )
    );

    //------------------------------------------------------------------
    // AY-3-8910 #2 (chip 1)
    //------------------------------------------------------------------
    jt49 u_ay2(
        .rst_n      ( ~rst          ),
        .clk        ( clk           ),
        .clk_en     ( cen_ay        ),
        .addr       ( ay1_addr      ),
        .cs_n       ( 1'b0          ),
        .wr_n       ( ~ay1c_write   ),
        .din        ( snd_latch     ),
        .sel        ( 1'b1          ),
        .dout       (               ),
        .sound      ( ay2           ),
        .A          (               ),
        .B          (               ),
        .C          (               ),
        .sample     (               ),
        .IOA_in     ( 8'd0          ),
        .IOA_out    (               ),
        .IOA_oe     (               ),
        .IOB_in     ( 8'd0          ),
        .IOB_out    (               ),
        .IOB_oe     (               )
    );

endmodule
