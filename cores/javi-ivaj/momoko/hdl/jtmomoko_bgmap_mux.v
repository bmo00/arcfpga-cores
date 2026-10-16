module jtmomoko_bgmap_mux(
    input             rst,
    input             clk,
    // puerto unico de la BRAM bgmap
    output     [16:0] bgmap_addr,
    input      [ 7:0] bgmap_data,
    // lado fetcher BG
    input      [16:0] fet_addr,
    output            fet_stall,
    output     [ 7:0] fet_data,
    // lado CPU (ventana F000, lectura por niveles)
    input      [16:0] bgwin_addr,
    input             bgwin_rd,
    output reg [ 7:0] bgwin_data
);

reg [16:0] cpu_addr_l;
reg [ 1:0] ph;          // 0 reposo, 2 direccion puesta, 1 captura
reg        rd_l;
wire       cpu_start = bgwin_rd && !rd_l;

assign fet_stall  = ph!=2'd0 || cpu_start;
assign fet_data   = bgmap_data;
assign bgmap_addr = ph!=2'd0 ? cpu_addr_l : fet_addr;

always @(posedge clk) begin
    if( rst ) begin
        ph <= 2'd0; rd_l <= 1'b0;
    end else begin
        rd_l <= bgwin_rd;
        case( ph )
            2'd0: if( cpu_start ) begin cpu_addr_l <= bgwin_addr; ph <= 2'd2; end
            2'd2: ph <= 2'd1;
            2'd1: begin bgwin_data <= bgmap_data; ph <= 2'd0; end
            default: ph <= 2'd0;
        endcase
    end
end

endmodule
