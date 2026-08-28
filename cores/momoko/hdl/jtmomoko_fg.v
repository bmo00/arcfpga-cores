/* Capa FG: tilemap de 4 paginas en ROM (fgmap+fggfx), 2bpp, scroll lineal.
     my = (vline + fg_scrolly + 272) mod 512, mx = h + fg_scrollx + 7 (mod 256)
     radr = {fg_sel[1:0], my[8:3], mx[7:3]} */
module jtmomoko_fg(
    input             rst,
    input             clk,
    input             hs,
    input             pxl_cen,
    input      [ 8:0] vrender,
    input      [ 8:0] vdump,
    input      [ 8:0] hdump,
    input             flip,
    input      [ 7:0] fg_scrollx, fg_scrolly,
    input      [ 1:0] fg_sel,

    output reg [13:0] fgmap_addr,
    input      [ 7:0] fgmap_data,
    output reg [12:0] fggfx_addr,
    input      [ 7:0] fggfx_data,

    output reg [ 1:0] pxl
);

// H7: FG nunca aparecio activo (fg_sel/scrollx/scrolly=0, "mask" segun
// registro pero region en blanco) en ninguna de las escenas estaticas
// alcanzables con el guion comun (coin 600-607/start 660-667) sin mover
// el joystick -- ver task-7-report.md. No se pudo barrer (dx,dy) con datos
// propios. Se aplica por analogia el offset (dx,dy)=(+1,-1) hallado de forma
// nitida e identica en BG y texto. jtmomoko_fg.v tiene la MISMA estructura
// que jtmomoko_bg.v (HOFF/VOFF se suman al fetch de origen mx0/my, "wa" resta
// 'fine'), asi que sigue la MISMA regla verificada alli (no la ingenua
// "-=dx/-=dy"; ver jtmomoko_bg.v y task-7-report.md): HOFF += dx, VOFF += dy.
localparam [7:0] FG_HOFF = 8'sd1;
localparam [8:0] FG_VOFF = -9'sd1;

// line buffer ping-pong 2x256x2: solo se escriben 248 de las 256 posiciones
// por linea (31 tiles x 8px); el hueco cae siempre en 240..255, en el
// blanking (HB_START=240), nunca visible
reg  [1:0] buf0[0:255], buf1[0:255];
reg        wrline;

reg  [3:0] st;
reg  [5:0] tcnt;
reg  [8:0] my;
reg  [7:0] mx0;
reg  [4:0] mcol;
reg  [2:0] fine;
reg  [7:0] gL, gR;
reg  [7:0] wa;
reg  [2:0] sx;
// constante de flip provisional: verificar en H7 (el texto necesitó 223, ver jtmomoko_text)
wire [8:0] vline = flip ? 9'd215-vrender : vrender;

reg [1:0] pen_r;
always @* case( {sx[2], sx[1:0]} )
    3'b000: pen_r = { gL[3], gL[7] };
    3'b001: pen_r = { gL[2], gL[6] };
    3'b010: pen_r = { gL[1], gL[5] };
    3'b011: pen_r = { gL[0], gL[4] };
    3'b100: pen_r = { gR[3], gR[7] };
    3'b101: pen_r = { gR[2], gR[6] };
    3'b110: pen_r = { gR[1], gR[5] };
    3'b111: pen_r = { gR[0], gR[4] };
endcase

always @(posedge clk) begin
    if( rst ) begin
        st <= 4'd15;
    end else begin
        case( st )
            4'd15: ;
            4'd0: begin
                fgmap_addr <= { 1'b0, fg_sel, my[8:3], mcol };  // 1+2+6+5=14
                st <= 4'd1;
            end
            4'd1: st <= 4'd2;
            4'd2: begin
                fggfx_addr <= { 2'b00, fgmap_data, my[2:0] };   // code*8+dy
                st <= 4'd3;
            end
            4'd3: begin
                fggfx_addr <= fggfx_addr + 13'h800;
                st <= 4'd4;
            end
            4'd4: begin
                gL <= fggfx_data;
                st <= 4'd5;
            end
            4'd5: begin
                gR <= fggfx_data;
                // H5 x=0: igual que BG (ver jtmomoko_bg.v): tile extra a la
                // izquierda + wa-8 para que la fuente de x=0 (mx0-1) caiga en
                // buf[255]. buf[A]=mx0+A, columnas 1..239 intactas.
                wa <= { tcnt[4:0], 3'd0 } - { 5'd0, fine } - 8'd8;
                sx <= 3'd0;
                st <= 4'd6;
            end
            4'd6: begin
                if( wrline ) buf1[ flip ? 8'd239-wa : wa ] <= pen_r;
                else         buf0[ flip ? 8'd239-wa : wa ] <= pen_r;
                wa <= wa + 8'd1;
                sx <= sx + 3'd1;
                if( sx==3'd7 ) begin
                    tcnt <= tcnt + 6'd1;
                    mcol <= mcol + 5'd1;
                    st   <= tcnt==6'd31 ? 4'd15 : 4'd0;  // H5 x=0: 32 tiles (0..31)
                end
            end
            default: st <= 4'd15;
        endcase
        if( hs ) begin
            wrline <= vrender[0];
            my     <= vline + {1'd0,fg_scrolly} + 9'd272 + FG_VOFF;
            mx0    <= fg_scrollx + 8'd7 + FG_HOFF;
            st     <= 4'd7;
        end
        if( st==4'd7 ) begin
            mcol <= mx0[7:3] - 5'd1;   // H5 x=0: empieza un tile a la izquierda
            fine <= mx0[2:0];
            tcnt <= 6'd0;
            st   <= 4'd0;
        end
    end
end

// H5 x=0: ver jtmomoko_bg.v -- misma correccion de lectura en el wrap H 383->0
// (col 0 lee buf[255] en vez de buf[127]).
wire [7:0] rd_addr = (hdump==9'd383) ? 8'd255 : hdump[7:0];
always @(posedge clk) if( pxl_cen )
    pxl <= vdump[0] ? buf1[rd_addr] : buf0[rd_addr];

endmodule
