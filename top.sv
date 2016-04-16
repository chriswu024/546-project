`include "/afs/eos.ncsu.edu/lockers/research/ece/paulf/DiRAMController/MemoryController/HDL/common/common.vh"
`include "/afs/eos.ncsu.edu/lockers/research/ece/paulf/DiRAMController/MemoryController/HDL/common/mc.vh"
`include "/afs/eos.ncsu.edu/lockers/research/ece/paulf/DiRAMController/MemoryController/HDL/common/mc_decoder.vh"
//`define  BncPorts 32
module top;
 //   parameter int NumBnc = `BncPorts;
    logic reset, clk;
    // system clock and reset
    initial begin
	reset = 0;
	clk = 0;
	#5ns reset = 1;
	#5ns clk = 1;
	#5ns reset = 0; clk = 0;
	forever 
	    #5ns clk = ~clk;
     end


   //  dec_ifc    Dec2Bnc[0: NumBnc - 1] (clk);   // 32 interface from decoder to bank controllers
     fifo_ifc Fifo (clk);    // interface of output of from system fifo
     cpu_ifc  Sys2Dec (clk);     // interface from system to decoder
   //  mc_decoder #(NumBnc) mc_decoder (Dec2Bnc, Sys2Dec, reset, clk);   //DUT
   //  test #(NumBnc) t1 (Dec2Bnc, Sys2Dec, reset)   // Test
     mc_decoder mc_decoder      (
	                         // global signals
	                         .clk(clk),   
                                 .reset(reset),
	                         // cpu_ifc interface signals
				 .sys__mc__dram_req    (Sys2Dec.sys__mc__dram_req    ),    
			         .sys__mc__dram_rdwr   (Sys2Dec.sys__mc__dram_rdwr   ),   
				 .sys__mc__dram_addr   (Sys2Dec.sys__mc__dram_addr   ),   
				 .sys__mc__dram_wr_data(Sys2Dec.sys__mc__dram_wr_data),
                                 .input_fifo_read      (Sys2Dec.input_fifo_read      ),
	                         // fifo_ifc interface signals
				 .input_fifo_read_rdwr   (Fifo.input_fifo_read_rdwr   ),   
				 .input_fifo_read_addr   (Fifo.input_fifo_read_addr   ),
				 .input_fifo_read_wr_data(Fifo.input_fifo_read_wr_data),
				 .input_fifo_empty       (Fifo.input_fifo_empty       ),
				 .mc__sys__dram_busy     (Fifo.mc__sys__dram_busy     )   
                                 );
     test ti (Fifo, Sys2Dec, reset);         // Test
endmodule : top
