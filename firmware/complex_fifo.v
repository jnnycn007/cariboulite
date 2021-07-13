module complex_fifo #(
	parameter ADDR_WIDTH = 8,
	parameter DATA_WIDTH = 16
)
(
	input wire 			            wr_rst_i,
	input wire 			            wr_clk_i,
	input wire 			            wr_en_i,
	input wire [2*DATA_WIDTH-1:0]	wr_data_i,

	input wire 			            rd_rst_i,
	input wire 			            rd_clk_i,
	input wire 			            rd_en_i,
	output reg [2*DATA_WIDTH-1:0]	rd_data_o,

	output reg 			full_o,
	output reg 			empty_o
);

reg [ADDR_WIDTH-1:0]	wr_addr;
reg [ADDR_WIDTH-1:0]	wr_addr_gray;
reg [ADDR_WIDTH-1:0]	wr_addr_gray_rd;
reg [ADDR_WIDTH-1:0]	wr_addr_gray_rd_r;
reg [ADDR_WIDTH-1:0]	rd_addr;
reg [ADDR_WIDTH-1:0]	rd_addr_gray;
reg [ADDR_WIDTH-1:0]	rd_addr_gray_wr;
reg [ADDR_WIDTH-1:0]	rd_addr_gray_wr_r;

function [ADDR_WIDTH-1:0] gray_conv;
input [ADDR_WIDTH-1:0] in;
begin
	gray_conv = {in[ADDR_WIDTH-1],
		     in[ADDR_WIDTH-2:0] ^ in[ADDR_WIDTH-1:1]};
end
endfunction

always @(posedge wr_clk_i) begin
	if (wr_rst_i) begin
		wr_addr <= 0;
		wr_addr_gray <= 0;
	end else if (wr_en_i) begin
		wr_addr <= wr_addr + 1'b1;
		wr_addr_gray <= gray_conv(wr_addr + 1'b1);
	end
end

// synchronize read address to write clock domain
always @(posedge wr_clk_i) begin
	rd_addr_gray_wr <= rd_addr_gray;
	rd_addr_gray_wr_r <= rd_addr_gray_wr;
end

always @(posedge wr_clk_i)
	if (wr_rst_i)
		full_o <= 0;
	else if (wr_en_i)
		full_o <= gray_conv(wr_addr + 2) == rd_addr_gray_wr_r;
	else
		full_o <= full_o & (gray_conv(wr_addr + 1'b1) == rd_addr_gray_wr_r);

always @(posedge rd_clk_i) begin
	if (rd_rst_i) begin
		rd_addr <= 0;
		rd_addr_gray <= 0;
	end else if (rd_en_i) begin
		rd_addr <= rd_addr + 1'b1;
		rd_addr_gray <= gray_conv(rd_addr + 1'b1);
	end
end

// synchronize write address to read clock domain
always @(posedge rd_clk_i) begin
	wr_addr_gray_rd <= wr_addr_gray;
	wr_addr_gray_rd_r <= wr_addr_gray_rd;
end

always @(posedge rd_clk_i)
	if (rd_rst_i)
		empty_o <= 1'b1;
	else if (rd_en_i)
		empty_o <= gray_conv(rd_addr + 1) == wr_addr_gray_rd_r;
	else
		empty_o <= empty_o & (gray_conv(rd_addr) == wr_addr_gray_rd_r);

// generate dual clocked memory
SB_RAM40_4K #(
  .INIT_0(256'h0000000000000000000000000000000000000000000000000000000000000000),
  .INIT_1(256'h0000000000000000000000000000000000000000000000000000000000000000),
  .INIT_2(256'h0000000000000000000000000000000000000000000000000000000000000000),
  .INIT_3(256'h0000000000000000000000000000000000000000000000000000000000000000),
  .INIT_4(256'h0000000000000000000000000000000000000000000000000000000000000000),
  .INIT_5(256'h0000000000000000000000000000000000000000000000000000000000000000),
  .INIT_6(256'h0000000000000000000000000000000000000000000000000000000000000000),
  .INIT_7(256'h0000000000000000000000000000000000000000000000000000000000000000),
  .INIT_8(256'h0000000000000000000000000000000000000000000000000000000000000000),
  .INIT_9(256'h0000000000000000000000000000000000000000000000000000000000000000),
  .INIT_A(256'h0000000000000000000000000000000000000000000000000000000000000000),
  .INIT_B(256'h0000000000000000000000000000000000000000000000000000000000000000),
  .INIT_C(256'h0000000000000000000000000000000000000000000000000000000000000000),
  .INIT_D(256'h0000000000000000000000000000000000000000000000000000000000000000),
  .INIT_E(256'h0000000000000000000000000000000000000000000000000000000000000000),
  .INIT_F(256'h0000000000000000000000000000000000000000000000000000000000000000),
  .WRITE_MODE(0),
  .READ_MODE(0)
) ram256x16_i_inst (
    .RDATA(rd_data_o[31:16]),
    .RADDR(rd_addr),
    .RCLK(rd_clk_i),
    .RCLKE(1'b1),    //<<
    .RE(rd_en_i),
    .WADDR(wr_addr),
    .WCLK (wr_clk_i),
    .WCLKE(1'b1),    //<<
    .WDATA(wr_data_i[31:16]),
    .WE(wr_en_i),
    .MASK(16'hFFFF) );

SB_RAM40_4K #(
  .INIT_0(256'h0000000000000000000000000000000000000000000000000000000000000000),
  .INIT_1(256'h0000000000000000000000000000000000000000000000000000000000000000),
  .INIT_2(256'h0000000000000000000000000000000000000000000000000000000000000000),
  .INIT_3(256'h0000000000000000000000000000000000000000000000000000000000000000),
  .INIT_4(256'h0000000000000000000000000000000000000000000000000000000000000000),
  .INIT_5(256'h0000000000000000000000000000000000000000000000000000000000000000),
  .INIT_6(256'h0000000000000000000000000000000000000000000000000000000000000000),
  .INIT_7(256'h0000000000000000000000000000000000000000000000000000000000000000),
  .INIT_8(256'h0000000000000000000000000000000000000000000000000000000000000000),
  .INIT_9(256'h0000000000000000000000000000000000000000000000000000000000000000),
  .INIT_A(256'h0000000000000000000000000000000000000000000000000000000000000000),
  .INIT_B(256'h0000000000000000000000000000000000000000000000000000000000000000),
  .INIT_C(256'h0000000000000000000000000000000000000000000000000000000000000000),
  .INIT_D(256'h0000000000000000000000000000000000000000000000000000000000000000),
  .INIT_E(256'h0000000000000000000000000000000000000000000000000000000000000000),
  .INIT_F(256'h0000000000000000000000000000000000000000000000000000000000000000),
  .WRITE_MODE(0),
  .READ_MODE(0)
) ram256x16_q_inst (
    .RDATA(rd_data_o[15:0]),
    .RADDR(rd_addr),
    .RCLK(rd_clk_i),
    .RCLKE(1'b1),    //<<
    .RE(rd_en_i),
    .WADDR(wr_addr),
    .WCLK (wr_clk_i),
    .WCLKE(1'b1),    //<<
    .WDATA(wr_data_i[15:0]),
    .WE(wr_en_i),
    .MASK(16'hFFFF) );

endmodule
