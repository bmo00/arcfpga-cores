/* Momoko 120% - CPU principal Z80 5 MHz
   Mapa (momoko.cpp:432-455):
   0000-BFFF ROM | C000-CFFF wram | D000-D0FF oram (tabla sprites en D064+)
   D400 R:IN0 | D402 R:IN1 W:flip | D404 W:watchdog | D406 R:DSW0 W:sndlatch
   D407 R:DSW1 | D800-DBFF paleta | DC00-02 regs FG | E000-E3FF vram texto
   E800-01 regs texto | F000-FFFF R:ventana bg_map / W:regs BG */
module jtmomoko_main(
    input               rst,
    input               clk,
    input               cen_main,
    input               LVBL,

    // ROM por SDRAM
    output       [15:0] main_addr,
    output              main_cs,
    input        [ 7:0] main_data,
    input               main_ok,

    // BRAMs (din comun = cpu_dout)
    output       [ 7:0] cpu_dout,
    output       [11:0] wram_addr,
    output              wram_we,
    input        [ 7:0] wram_data,
    output       [ 9:0] vram_cpu_addr,
    output              vram_cpu_we,
    input        [ 7:0] vram_cpu_data,
    output       [ 9:0] pal_cpu_addr,
    output              pal_cpu_we,
    input        [ 7:0] pal_cpu_data,
    output       [ 7:0] oram_cpu_addr,
    output              oram_cpu_we,
    input        [ 7:0] oram_cpu_data,
    output reg   [ 3:0] vregs_cpu_addr,
    output reg          vregs_cpu_we,
    // ventana de lectura sobre bg_map (servida via jtmomoko_bgmap_mux)
    output       [16:0] bgwin_addr,
    output              bgwin_rd,
    input        [ 7:0] bgwin_data,

    // entradas
    input        [15:0] dipsw,
    input        [ 5:0] joystick1,
    input        [ 5:0] joystick2,
    input        [ 1:0] cab_1p,      // start
    input        [ 1:0] coin,
    input               dip_pause,

    output reg   [ 7:0] snd_latch
);

wire [15:0] A;
wire [ 7:0] cpu_din, dout;
wire        m1_n, mreq_n, iorq_n, rd_n, wr_n, rfsh_n, int_n;
reg  [ 4:0] bg_bank;
reg         LVBL_l;

wire mem_acc = ~mreq_n & rfsh_n;
wire mem_wr  = mem_acc & ~wr_n;

// chip selects
wire rom_cs   = mem_acc  && A[15:14]!=2'b11;                  // 0000-BFFF
wire wram_cs  = mem_acc  && A[15:12]==4'hC;                   // C000-CFFF
wire oram_cs  = mem_acc  && A[15:8]==8'hD0;                   // D000-D0FF
wire io_cs    = mem_acc  && A[15:8]==8'hD4;                   // D400-D4FF (decode parcial, pagina completa)
wire pal_cs   = mem_acc  && A[15:10]==6'b1101_10;             // D800-DBFF
wire fgr_cs   = mem_acc  && A[15:8]==8'hDC;                   // DC00-DC02 (decode parcial, pagina completa)
wire vram_cs  = mem_acc  && A[15:10]==6'b1110_00;             // E000-E3FF
wire txr_cs   = mem_acc  && A[15:8]==8'hE8;                   // E800-E801 (decode parcial, pagina completa)
wire bgwin_cs = mem_acc  && A[15:12]==4'hF;                   // F000-FFFF

assign main_addr     = A;
assign main_cs       = rom_cs;
assign cpu_dout      = dout;
assign wram_addr     = A[11:0];
assign wram_we       = wram_cs & mem_wr;
assign vram_cpu_addr = A[9:0];
assign vram_cpu_we   = vram_cs & mem_wr;
assign pal_cpu_addr  = A[9:0];
assign pal_cpu_we    = pal_cs  & mem_wr;
assign oram_cpu_addr = A[7:0];
assign oram_cpu_we   = oram_cs & mem_wr;
assign bgwin_addr    = { bg_bank, A[11:0] };
assign bgwin_rd      = bgwin_cs & ~rd_n;

// registro de banco con efecto inmediato (la CPU lee la ventana justo despues)
// mismo alcance de decode que el vregs encoder: SOLO F004
always @(posedge clk) begin
    if( rst ) bg_bank <= 5'd0;
    else if( mem_wr && bgwin_cs && A[11:3]==9'd0 && A[2:0]==3'd4 ) bg_bank <= dout[4:0];
end

// codificador de escrituras al archivo de registros de video (BRAM vregs)
always @* begin
    vregs_cpu_we   = 1'b0;
    vregs_cpu_addr = 4'd0;
    if( mem_wr ) begin
        if( fgr_cs && A[1:0]!=2'b11 ) begin  // DC00-DC02
            vregs_cpu_we   = 1'b1;
            vregs_cpu_addr = { 2'b00, A[1:0] };
        end
        if( txr_cs && !A[1] ) begin          // E800-E801
            vregs_cpu_we   = 1'b1;
            vregs_cpu_addr = A[0] ? 4'd4 : 4'd3;
        end
        if( bgwin_cs && A[11:3]==9'd0 ) begin // F000-F007
            case( A[2:0] )
                3'd0: begin vregs_cpu_we=1'b1; vregs_cpu_addr=4'd5;  end
                3'd1: begin vregs_cpu_we=1'b1; vregs_cpu_addr=4'd6;  end
                3'd2: begin vregs_cpu_we=1'b1; vregs_cpu_addr=4'd7;  end
                3'd3: begin vregs_cpu_we=1'b1; vregs_cpu_addr=4'd8;  end
                3'd4: begin vregs_cpu_we=1'b1; vregs_cpu_addr=4'd9;  end
                3'd6: begin vregs_cpu_we=1'b1; vregs_cpu_addr=4'd10; end
                3'd7: begin vregs_cpu_we=1'b1; vregs_cpu_addr=4'd11; end
                default: ;                    // F005: sin uso
            endcase
        end
        if( io_cs && A[2:0]==3'd2 ) begin     // D402: flip
            vregs_cpu_we   = 1'b1;
            vregs_cpu_addr = 4'd12;
        end
    end
end

// latch de sonido (D406 W). D404 (watchdog) se ignora.
always @(posedge clk) begin
    if( rst ) snd_latch <= 8'd0;
    else if( mem_wr && io_cs && A[2:0]==3'd6 ) snd_latch <= dout;
end

// jtframe entrega joystick1/joystick2/cab_1p/coin YA activos a baja
// (reposo=1, pulsado=0; ver modules/jtframe/hdl/keyboard/jtframe_joysticks.v
// "game signals are active low" y doc/inputs.md). El Z80 lee IN0/DSW0
// tambien activos a baja (momoko.cpp IP_ACTIVE_LOW), asi que se pasan
// SIN invertir. Orden jtframe: joystick[3:0]={up,down,left,right} con
// bit0=right,1=left,2=down,3=up,4=b1,5=b2 -> IN0 bit0=up..bit6=start1.
wire [7:0] in0 = { cab_1p[1], cab_1p[0], joystick1[5:4],
                   joystick1[1], joystick1[0], joystick1[2], joystick1[3] };
wire [7:0] in1 = { 2'b11, joystick2[5:4],
                   joystick2[1], joystick2[0], joystick2[2], joystick2[3] };
wire [7:0] dsw0 = { coin[0], dipsw[6:0] };
wire [7:0] dsw1 = { 2'b11, dipsw[13:12], 2'b11, dipsw[9:8] };

reg [7:0] io_mux;
always @* begin
    case( A[2:0] )
        3'd0:    io_mux = in0;
        3'd2:    io_mux = in1;
        3'd6:    io_mux = dsw0;
        3'd7:    io_mux = dsw1;
        default: io_mux = 8'hFF;
    endcase
end

assign cpu_din = rom_cs   ? main_data     :
                 wram_cs  ? wram_data     :
                 oram_cs  ? oram_cpu_data :
                 io_cs    ? io_mux        :
                 pal_cs   ? pal_cpu_data  :
                 vram_cs  ? vram_cpu_data :
                 bgwin_cs ? bgwin_data    : 8'hFF;

// IRQ de vblank (irq0_line_hold): pulso al inicio del blanking,
// CLR_INT=1 lo mantiene hasta el ciclo INTA
always @(posedge clk) LVBL_l <= LVBL;
assign int_n = ~( LVBL_l & ~LVBL );

jtframe_sysz80 #(.RAM_AW(12), .CLR_INT(1)) u_cpu(
    .rst_n    ( ~rst        ),
    .clk      ( clk         ),
    .cen      ( cen_main & dip_pause ),  // dip_pause=1 en marcha (convencion jtframe)
    .cpu_cen  (             ),
    .int_n    ( int_n       ),
    .nmi_n    ( 1'b1        ),
    .busrq_n  ( 1'b1        ),
    .m1_n     ( m1_n        ),
    .mreq_n   ( mreq_n      ),
    .iorq_n   ( iorq_n      ),
    .rd_n     ( rd_n        ),
    .wr_n     ( wr_n        ),
    .rfsh_n   ( rfsh_n      ),
    .halt_n   (             ),
    .busak_n  (             ),
    .A        ( A           ),
    .cpu_din  ( cpu_din     ),
    .cpu_dout ( dout        ),
    .ram_dout (             ),
    .ram_cs   ( 1'b0        ),
    .rom_cs   ( rom_cs      ),
    .rom_ok   ( main_ok     )
);

`ifdef SIMULATION
integer rdcnt=0, wrcnt=0;
always @(posedge clk) if( cen_main ) begin
    if( mem_acc && !rd_n && rdcnt<120 ) begin
        rdcnt <= rdcnt+1;
        $display("MAIN RD %04X = %02X%s", A, cpu_din, m1_n ? "" : " M1");
    end
    if( mem_wr && wrcnt<80 ) begin
        wrcnt <= wrcnt+1;
        $display("MAIN WR %04X <= %02X", A, dout);
    end
    if( !m1_n && !iorq_n ) $display("MAIN INTA en vdump");
end
`endif

endmodule
