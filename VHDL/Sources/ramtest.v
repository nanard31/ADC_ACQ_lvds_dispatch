//------------------------------------------------------------------------
// ramtest.v
//
// This sample uses the Xilinx MIG DDR3 controller and HDL to move data
// from the PC to the DDR3 and vice-versa. Based on MIG generated example_top.v.
//
// Host Interface registers:
// WireIn 0x00
//     0 - DDR3 read enable (0=disabled, 1=enabled)
//     1 - DDR3 write enable (0=disabled, 1=enabled)
//     2 - Reset
//
// PipeIn 0x80 - DDR3 write port (U11, DDR2)
// PipeOut 0xA0 - DDR3 read port (U11, DDR2)
//
// This sample is included for reference only.  No guarantees, either
// expressed or implied, are to be drawn.
//------------------------------------------------------------------------
// tabstop 3
// Copyright (c) 2005-2016 Opal Kelly Incorporated
// $Rev$ $Date$
//------------------------------------------------------------------------
`timescale 1ns/1ps

module ramtest (
	input  wire [4:0]   okUH,
	output wire [2:0]   okHU,
	inout  wire [31:0]  okUHU,
	inout  wire         okAA,

	input  wire         sys_clk_p,
	input  wire         sys_clk_n,
	
	output wire [7:0]   led,
	
	inout  wire [31:0]  ddr3_dq,
	output wire [14:0]  ddr3_addr,
	output wire [2 :0]  ddr3_ba,
	output wire [0 :0]  ddr3_ck_p,
	output wire [0 :0]  ddr3_ck_n,
	output wire [0 :0]  ddr3_cke,
	output wire         ddr3_cas_n,
	output wire         ddr3_ras_n,
	output wire         ddr3_we_n,
	output wire [0 :0]  ddr3_odt,
	output wire [3 :0]  ddr3_dm,
	inout  wire [3 :0]  ddr3_dqs_p,
	inout  wire [3 :0]  ddr3_dqs_n,
	output wire         ddr3_reset_n,
	
	output wire [4 :0]  o_ADC_CNV_n,
    output wire [4 :0]  o_ADC_SCK_n,
    output wire [4 :0]  o_ADC_SCK_p,
	
    input  wire [9 :0]  i_ADC_SDO_p,
    input  wire [9 :0]  i_ADC_SDO_n
	
	//input  wire        	sys_rst              // for simulation
	
	);

// OK RAMTest Parameters
localparam BLOCK_SIZE = 128; // 512 bytes / 4 bytes per word, 
localparam FIFO_SIZE = 1023; // note that Xilinx does not allow use of the full 1024 words
localparam BUFFER_HEADROOM = 20; // headroom for the FIFO count to account for latency

// Capability bitfield, used to indicate features supported by this bitfile:
// [0] - Supports passing calibration status through FrontPanel
localparam CAPABILITY = 16'h0001;


wire          init_calib_complete;
reg           sys_rst;			// comment for simulation

wire [29 :0]  app_addr;
wire [2  :0]  app_cmd;
wire          app_en;
wire          app_rdy;
wire [255:0]  app_rd_data;
wire          app_rd_data_end;
wire          app_rd_data_valid;
wire [255:0]  app_wdf_data;
wire                       app_wdf_end;
wire [31 :0]  app_wdf_mask;
wire          app_wdf_rdy;
wire          app_wdf_wren;

wire          clk;
wire          rst;

// Front Panel

// Target interface bus:
wire         okClk;
wire [112:0] okHE;
wire [64:0]  okEH;

wire [31:0]  ep00wire;
wire [31:0]  samples_count;
wire [31:0]  ep40trigger;
wire [31:0]  ep60trigger;

wire         pipe_in_read;
wire [255:0] pipe_in_data;
wire [6:0]   pipe_in_rd_count;
wire [9:0]   pipe_in_wr_count;
wire         pipe_in_valid;
wire         pipe_in_full;
wire         pipe_in_empty;
reg          pipe_in_ready;

wire         pipe_out_write;
wire [255:0] pipe_out_data;
wire [9:0]   pipe_out_rd_count;
wire [6:0]   pipe_out_wr_count;
wire         pipe_out_full;
wire         pipe_out_empty;
reg          pipe_out_ready;

// Pipe Fifos
wire         pi0_ep_write;
wire         po0_ep_read;
wire [31:0]  pi0_ep_dataout;
wire [31:0]  po0_ep_datain;

wire [159:0] o_dout;
wire [31:0]  sample_count;

//wire [0:7]	iADC_CNV_n;
wire [0:4]	ADC_SCK;
wire [0:9]	ADC_SDO;

wire [0:7]	o_ADC_Sck_p_wire;
wire [0:7]	o_ADC_Sck_n_wire;

wire [9:0] o_rdy;          //10 bits
	
wire [169: 0] probe0;

function [7:0] xem7310_led;
input [7:0] a;
integer i;
begin
	for(i=0; i<8; i=i+1) begin: u
		xem7310_led[i] = (a[i]==1'b1) ? (1'b0) : (1'bz);
	end
end
endfunction

assign led = xem7310_led({start_led,3'hf,ep00wire[0],ep00wire[1],app_wdf_rdy,init_calib_complete});

	//MIG Infrastructure Reset
reg [31:0] rst_cnt;
initial rst_cnt = 32'b0;
always @(posedge okClk) begin						// comment process for simulation
	if(rst_cnt < 32'h0800_0000) begin
		rst_cnt <= rst_cnt + 1;
		sys_rst <= 1'b1;
	end
	else begin
		sys_rst <= 1'b0;
	end
end

// MIG User Interface instantiation
ddr3_256_32 u_ddr3_256_32 (
	// Memory interface ports
	.ddr3_addr                      (ddr3_addr),
	.ddr3_ba                        (ddr3_ba),
	.ddr3_cas_n                     (ddr3_cas_n),
	.ddr3_ck_n                      (ddr3_ck_n),
	.ddr3_ck_p                      (ddr3_ck_p),
	.ddr3_cke                       (ddr3_cke),
	.ddr3_ras_n                     (ddr3_ras_n),
	.ddr3_reset_n                   (ddr3_reset_n),
	.ddr3_we_n                      (ddr3_we_n),
	.ddr3_dq                        (ddr3_dq),
	.ddr3_dqs_n                     (ddr3_dqs_n),
	.ddr3_dqs_p                     (ddr3_dqs_p),
	.init_calib_complete            (init_calib_complete),
	
	.ddr3_dm                        (ddr3_dm),
	.ddr3_odt                       (ddr3_odt),
	// Application interface ports
	.app_addr                       (app_addr),
	.app_cmd                        (app_cmd),
	.app_en                         (app_en),
	.app_wdf_data                   (app_wdf_data),
	.app_wdf_end                    (app_wdf_end),
	.app_wdf_wren                   (app_wdf_wren),
	.app_rd_data                    (app_rd_data),
	.app_rd_data_end                (app_rd_data_end),
	.app_rd_data_valid              (app_rd_data_valid),
	.app_rdy                        (app_rdy),
	.app_wdf_rdy                    (app_wdf_rdy),
	.app_sr_req                     (1'b0),
	.app_sr_active                  (),
	.app_ref_req                    (1'b0),
	.app_ref_ack                    (),
	.app_zq_req                     (1'b0),
	.app_zq_ack                     (),
	.ui_clk                         (clk),
	.ui_clk_sync_rst                (rst),
	
	.app_wdf_mask                   (app_wdf_mask),
	
	// System Clock Ports
	.sys_clk_p                      (sys_clk_p),
	.sys_clk_n                      (sys_clk_n),
	
	.sys_rst                        (sys_rst)
	);


// OK MIG DDR3 Testbench Instatiation
ddr3_test ddr3_tb (
	.clk                (clk),
	.reset              (ep00wire[2] | rst),	// dont touch here for simulation
	.reads_en           (ep00wire[0]),	// fix for simulation
	.writes_en          (ep00wire[1]),	// fix for simulation
	.calib_done         (init_calib_complete),

	.ib_re              (pipe_in_read),
	.ib_data            (pipe_in_data),
	.ib_count           (pipe_in_rd_count),
	.ib_valid           (pipe_in_valid),
	.ib_empty           (pipe_in_empty),
	
	.ob_we              (pipe_out_write),
	.ob_data            (pipe_out_data),
	.ob_count           (pipe_out_wr_count),
	.ob_full            (pipe_out_full),
	
	.app_rdy            (app_rdy),
	.app_en             (app_en),
	.app_cmd            (app_cmd),
	.app_addr           (app_addr),
	
	.app_rd_data        (app_rd_data),
	.app_rd_data_end    (app_rd_data_end),
	.app_rd_data_valid  (app_rd_data_valid),
	
	.app_wdf_rdy        (app_wdf_rdy),
	.app_wdf_wren       (app_wdf_wren),
	.app_wdf_data       (app_wdf_data),
	.app_wdf_end        (app_wdf_end),
	.app_wdf_mask       (app_wdf_mask)
	);

//Block Throttle
always @(posedge okClk) begin
	// Check for enough space in input FIFO to pipe in another block
	// The count is compared against a reduced size to account for delays in
	// FIFO count updates.
	if(pipe_in_wr_count <= (FIFO_SIZE-BUFFER_HEADROOM-BLOCK_SIZE) ) begin
		pipe_in_ready <= 1'b1;
	end
	else begin
		pipe_in_ready <= 1'b0;
	end

	// Check for enough space in output FIFO to pipe out another block
	if(pipe_out_rd_count >= BLOCK_SIZE) begin
		pipe_out_ready <= 1'b1;
	end
	else begin
		pipe_out_ready <= 1'b0;
	end
end


// Instantiate the okHost and connect endpoints.
wire [65*5-1:0]  okEHx;

okHost okHI(
	.okUH(okUH),
	.okHU(okHU),
	.okUHU(okUHU),
	.okAA(okAA),
	.okClk(okClk),
	.okHE(okHE),
	.okEH(okEH)
	);

okWireOR # (.N(5)) wireOR (okEH, okEHx);
okWireIn       wi00 (.okHE(okHE),                             .ep_addr(8'h00), .ep_dataout(ep00wire));
okWireOut      wo00 (.okHE(okHE), .okEH(okEHx[ 0*65 +: 65 ]), .ep_addr(8'h20), .ep_datain({31'h00, init_calib_complete}));
okWireOut      wo01 (.okHE(okHE), .okEH(okEHx[ 1*65 +: 65 ]), .ep_addr(8'h3e), .ep_datain(CAPABILITY));
okBTPipeOut    po0  (.okHE(okHE), .okEH(okEHx[ 3*65 +: 65 ]), .ep_addr(8'ha0), .ep_read(po0_ep_read),   .ep_blockstrobe(), .ep_datain(po0_ep_datain),   .ep_ready(pipe_out_ready));

okTriggerIn    trig40 (.okHE(okHE),                             .ep_addr(8'h40), .ep_clk(clk), .ep_trigger(ep40trigger));
okWireIn       wi01   (.okHE(okHE),                             .ep_addr(8'h01), .ep_dataout(samples_count));
okTriggerOut   trig60( .okHE(okHE), .okEH(okEHx[ 4*65 +: 65 ]),                    .ep_addr(8'h60), .ep_clk(clk), .ep_trigger({ep60trigger}) );


Test_Template Test_Template_instance (
    .rst(ep00wire[2] | rst),	// fix for simulation
    .clk(clk),
    .i_start(ep40trigger[0]),
    .o_finished(ep60trigger[0]),
    .i_debug_en(ep00wire[7]),
    .o_start_led(start_led),
    .i_samples_count(samples_count),
    .o_data(o_dout),
    .o_rdy(o_rdy),
	
	.o_ADC_SCK(ADC_SCK),     	             // SPI Serial Clock
    .o_ADC_CNV_n(o_ADC_CNV_n),   	         // SPI Convert Input, negative polarity
    .i_ADC_SDO(ADC_SDO),

	.init_calib_complete(init_calib_complete)    //place for simulation	
	
/*     .o_adc_sck_p(o_adc_sck_p),
    .o_adc_sck_n(o_adc_sck_n),
    .o_adc_cnv_n(o_adc_cnv_n),
    .i_adc_sdo_p(i_adc_sdo_p),
    .i_adc_sdo_n(i_adc_sdo_n) */
);


fifo_w32_1024_r256_128 okPipeIn_fifo (                  // write 128 bits wide
	.rst(ep00wire[2] | rst),	// fix for simulation
	.wr_clk(clk),
	.rd_clk(clk),
	.din(o_dout), // Bus [127 : 0]
	.wr_en(o_rdy),
	.rd_en(pipe_in_read),
	.dout(pipe_in_data), // Bus [256 : 0]
	.full(pipe_in_full),
	.empty(pipe_in_empty),
	.valid(pipe_in_valid),
	.rd_data_count(pipe_in_rd_count), // Bus [6 : 0]
	.wr_data_count(pipe_in_wr_count)); // Bus [9 : 0]

	
fifo_w256_128_r32_1024 okPipeOut_fifo (
	.rst(ep00wire[2] | rst),	// fix for simulation
	.wr_clk(clk),
	.rd_clk(okClk),
	.din(pipe_out_data), // Bus [256 : 0]
	.wr_en(pipe_out_write),
	.rd_en(po0_ep_read),
	.dout(po0_ep_datain), // Bus [31 : 0]
	.full(pipe_out_full),
	.empty(pipe_out_empty),
	.valid(),
	.rd_data_count(pipe_out_rd_count), // Bus [9 : 0]
	.wr_data_count(pipe_out_wr_count)); // Bus [6 : 0]

//
// LVDS on the Top module
//

genvar i;
generate
    for (i=0; i<=4; i=i+1) begin: OBUFDS
    OBUFDS whatever_OBUFDS (
        .I(ADC_SCK[i]),
		.O(o_ADC_SCK_p[i]),
        .OB(o_ADC_SCK_n[i])

    );
end 
endgenerate
 
/* assign o_ADC_Sck_p = o_ADC_Sck_p_wire;
assign o_ADC_Sck_n = o_ADC_Sck_n_wire;  */
 
genvar v;
generate
    for (v=0; v<=9; v=v+1) begin: IBUFDS
    IBUFDS whatever_IBUFDS (
        .I(i_ADC_SDO_p[v]),
        .IB(i_ADC_SDO_n[v]),
        .O(ADC_SDO[v])

    );
end 
endgenerate	

ila_0 u_ila_0(
	  .clk	(clk),
	  .probe0 (probe0)
	  );

assign probe0 = {o_dout,o_rdy};


/* assign o_ADC_CNV_n[0] = iADC_CNV_n[0];
assign o_ADC_CNV_n[1] = iADC_CNV_n[2];
assign o_ADC_CNV_n[2] = iADC_CNV_n[4];
assign o_ADC_CNV_n[3] = iADC_CNV_n[6]; */	
	
endmodule
