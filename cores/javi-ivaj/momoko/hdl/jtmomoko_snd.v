/* Momoko 120% - CPU de sonido Z80 2.5 MHz, 2x YM2203 (jt03)
   Mapa (momoko.cpp:457-465): 0000-7FFF ROM | 8000-87FF RAM
   A000-A001 YM#1 | C000-C001 YM#2 (IOA=snd_latch) | 9000/B000 escrituras
   ignoradas (decode parcial). Sin IRQ/NMI: el firmware sondea los timers
   del YM2203. */
module jtmomoko_snd(
    input             rst,
    input             clk,
    input             cen_snd,
    input             cen_fm,

    output     [14:0] snd_addr,
    output            snd_cs,
    input      [ 7:0] snd_data,
    input             snd_ok,

    input      [ 7:0] snd_latch,

    output signed [15:0] fm0, fm1,
    output     [ 9:0] psg0, psg1
);

wire [15:0] A;
wire [ 7:0] dout, ram_dout, fm0_dout, fm1_dout;
wire        m1_n, mreq_n, iorq_n, rd_n, wr_n, rfsh_n;

wire mem_acc = ~mreq_n & rfsh_n;
wire rom_cs  = mem_acc && !A[15];
wire ram_cs  = mem_acc && A[15:11]==5'b1000_0;
wire fm0_cs  = mem_acc && A[15:12]==4'hA;
wire fm1_cs  = mem_acc && A[15:12]==4'hC;

assign snd_addr = A[14:0];
assign snd_cs   = rom_cs;

wire [7:0] din = rom_cs ? snd_data :
                 ram_cs ? ram_dout :
                 fm0_cs ? fm0_dout :
                 fm1_cs ? fm1_dout : 8'hFF;

jtframe_sysz80 #(.RAM_AW(11)) u_cpu(
    .rst_n    ( ~rst      ),
    .clk      ( clk       ),
    .cen      ( cen_snd   ),
    .cpu_cen  (           ),
    .int_n    ( 1'b1      ),
    .nmi_n    ( 1'b1      ),
    .busrq_n  ( 1'b1      ),
    .m1_n     ( m1_n      ),
    .mreq_n   ( mreq_n    ),
    .iorq_n   ( iorq_n    ),
    .rd_n     ( rd_n      ),
    .wr_n     ( wr_n      ),
    .rfsh_n   ( rfsh_n    ),
    .halt_n   (           ),
    .busak_n  (           ),
    .A        ( A         ),
    .cpu_din  ( din       ),
    .cpu_dout ( dout      ),
    .ram_dout ( ram_dout  ),
    .ram_cs   ( ram_cs    ),
    .rom_cs   ( rom_cs    ),
    .rom_ok   ( snd_ok    )
);

jt03 u_fm0(
    .rst    ( rst       ),
    .clk    ( clk       ),
    .cen    ( cen_fm    ),
    .din    ( dout      ),
    .addr   ( A[0]      ),
    .cs_n   ( ~fm0_cs   ),
    .wr_n   ( wr_n      ),
    .psg_snd( psg0      ),
    .fm_snd ( fm0       ),
    .snd_sample(        ),
    .dout   ( fm0_dout  ),
    .irq_n  (           ),
    .IOA_in ( 8'd0      ),
    .IOB_in ( 8'd0      ),
    .IOA_out(           ),
    .IOB_out(           ),
    .IOA_oe (           ),
    .IOB_oe (           ),
    .psg_A  (           ),
    .psg_B  (           ),
    .psg_C  (           ),
    .snd    (           ),
    .debug_view(        )
);

jt03 u_fm1(
    .rst    ( rst       ),
    .clk    ( clk       ),
    .cen    ( cen_fm    ),
    .din    ( dout      ),
    .addr   ( A[0]      ),
    .cs_n   ( ~fm1_cs   ),
    .wr_n   ( wr_n      ),
    .psg_snd( psg1      ),
    .fm_snd ( fm1       ),
    .snd_sample(        ),
    .dout   ( fm1_dout  ),
    .irq_n  (           ),
    .IOA_in ( snd_latch ),  // la placa entrega el latch por el puerto A
    .IOB_in ( 8'd0      ),
    .IOA_out(           ),
    .IOB_out(           ),
    .IOA_oe (           ),
    .IOB_oe (           ),
    .psg_A  (           ),
    .psg_B  (           ),
    .psg_C  (           ),
    .snd    (           ),
    .debug_view(        )
);

`ifdef SIMULATION
integer rdcnt=0, wrcnt=0, fmcnt=0;
always @(posedge clk) if( cen_snd ) begin
    if( mem_acc && !rd_n && rdcnt<80 ) begin
        rdcnt <= rdcnt+1;
        $display("SND RD %04X = %02X%s", A, din, m1_n ? "" : " M1");
    end
    if( mem_acc && !wr_n && wrcnt<80 ) begin
        wrcnt <= wrcnt+1;
        $display("SND WR %04X <= %02X", A, dout);
    end
    if( mem_acc && !wr_n && (fm0_cs || fm1_cs) && fmcnt<80 ) begin
        fmcnt <= fmcnt+1;
        $display("SND FM%0d %s <= %02X", fm1_cs, A[0] ? "DATA" : "ADDR", dout);
    end
end
`endif

endmodule
