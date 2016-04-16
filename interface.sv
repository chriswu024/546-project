`include "/afs/eos.ncsu.edu/lockers/research/ece/paulf/DiRAMController/MemoryController/HDL/common/common.vh"
`include "/afs/eos.ncsu.edu/lockers/research/ece/paulf/DiRAMController/MemoryController/HDL/common/mc.vh"
`include "/afs/eos.ncsu.edu/lockers/research/ece/paulf/DiRAMController/MemoryController/HDL/common/mc_decoder.vh"
///////////////////////////////////////////////////////////////////////////////
// interface between CPU and decoder
///////////////////////////////////////////////////////////////////////////////
interface cpu_ifc(input bit clk);
  // general singals
  logic    reset;
  // interface from system to Decoder
  logic                                                   sys__mc__dram_req         ;
  logic                                                   sys__mc__dram_rdwr        ;
  logic    [`DEC_CONT_SYSTEM_INTF_ADDR_RANGE       ]      sys__mc__dram_addr        ;
  logic    [`DEC_CONT_SYSTEM_INTF_WRITE_DATA_RANGE ]      sys__mc__dram_wr_data     ;
  // DEBUGGING, the read control signal for input FIFO
  logic                                                   input_fifo_read           ;
  /*                      
  // interface from Decoder to system
  logic  [`DEC_CONT_SYSTEM_INTF_READ_DATA_RANGE]          mc__sys__dram_rd_data     ;
  logic                                                   mc__sys__dram_rd_done     ;
 */ 
  clocking cb @(posedge clk);
  //  input     mc__sys__dram_rd_data     ,
  //            mc__sys__dram_rd_done     ;
      output   sys__mc__dram_req         ,  
               input_fifo_read           ,
               sys__mc__dram_rdwr        ,
               sys__mc__dram_addr        ,
               sys__mc__dram_wr_data     ; 
  endclocking : cb
  modport TB_Sys2Dec (clocking cb, output reset);

endinterface : cpu_ifc

typedef virtual cpu_ifc.TB_Sys2Dec vCPU_T;


/////////////////////////////////////////////////////////////////////////
// interface between decoder and bank controller
/////////////////////////////////////////////////////////////////////////
interface dec_ifc(input bit clk);
  //signals sent from decoder to bank controller
  logic                                                     dec__bnc__valid       ;
  logic    [`DEC_CONT_TO_BANK_CONT_ROW_ADDR_RANGE  ]        dec__bnc__page_addr   ;
  logic    [`DEC_CONT_TO_BANK_CONT_COL_ADDR_RANGE  ]        dec__bnc__col_addr    ;
  logic                                                     dec__bnc__rdwr        ;
  logic    [`DEC_CONT_TO_BANK_CONT_CMD_RANGE       ]        dec__bnc__wr_data     ;
  logic    [`DEC_CONT_TO_BANK_CONT_CNTL_RANGE      ]        dec__bnc__cntl        ;
  logic    [`DEC_CONT_TO_BANK_CONT_CMD_RANGE       ]        dec__bnc__tag         ;
  // signals sent from bank controller to decoder
  logic                                                     bnc__dec__ready       ;

  clocking cb @(posedge clk);
      input      dec__bnc__valid       , 
                 dec__bnc__page_addr   ,
                 dec__bnc__col_addr    ,
                 dec__bnc__rdwr        ,
                 dec__bnc__wr_data     ,
                 dec__bnc__cntl        ,
                 dec__bnc__tag         ;
      output     bnc__dec__ready       ;
  endclocking : cb

  modport TB_Dec2Bnc (clocking cb);
endinterface : dec_ifc

typedef virtual dec_ifc.TB_Dec2Bnc vDEC_T;


/*
///////////////////////////////////////////////////////////////////////////////
//interface for input FIFO, FOR DEBUGGING
///////////////////////////////////////////////////////////////////////////////
interface fifo_ifc(input bit clk);
    //output signals of input fifo
    logic                                                  input_fifo_read_rdwr              ;
    logic    [`DEC_CONT_SYSTEM_INTF_ADDR_RANGE       ]     input_fifo_read_addr              ;
    logic    [`DEC_CONT_SYSTEM_INTF_WRITE_DATA_RANGE ]     input_fifo_read_wr_data           ;
    logic                                                  input_fifo_empty                  ;
    logic                                                  mc__sys__dram_busy                ;

    clocking cb @(posedge clk);
	input	    input_fifo_read_rdwr              ,
		    input_fifo_read_addr              ,
		    input_fifo_read_wr_data           ,
		    input_fifo_empty                  ,
                    mc__sys__dram_busy                ;
    endclocking:cb

    modport TB_Fifo (clocking cb);
endinterface:fifo_ifc

typedef virtual fifo_ifc.TB_Fifo vFIFO_T;
*/




