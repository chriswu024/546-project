/*********************************************************************************************

    File name   : mc_decoder.v
    Author      : Yuejian Wu/Lee Baker
    Affiliation : North Carolina State University, Raleigh, NC
    Date        : February 2016
    email       : ywu34@ncsu.edu

    Description : This module interfaces to the CPU and bank controller.
                  This module includes input FIFO, decoder and output FIFO. 
                  The main function of this module is to store, decode CPU instructions, 
                  and finally steer them to corresponding bank controller. 
                  This module also receives data read from memory from scheduler module 
                  and send these data to CPU using tags. 
                  Input FIFO is used to store instructions from CPU. Unique tag is also assigned to each instruction.
                  Decoder is used to decode each instruction and steer instruction 
                  and data associated with it to different output FIFOs. 
                  Output FIFO will communicate with bank controlle using handshake signal.
                  This module also 

*********************************************************************************************/


`timescale 1ns/10ps
`include "common.vh"
`include "mc.vh"
`include "mc_decoder.vh"

module mc_decoder (
                
                // Request interface from system to Decoder
                sys__mc__dram_req                ,
                sys__mc__dram_rdwr               ,
                sys__mc__dram_addr               ,
                sys__mc__dram_wr_data            ,
                mc__sys__dram_busy               ,
                
                // Response interface from Decoder to system
                mc__sys__dram_rd_data            ,
                mc__sys__dram_rd_done            ,

                // interface from scheduler to Decoder
                sch__dec__rd_data                ,

                // interface from Decoder to Bank Controller(s)
                `include "/afs/eos.ncsu.edu/lockers/research/ece/paulf/DiRAMController/MemoryController/HDL/common/mc_decoder_bnc_ports.vh"
                         
                // General interface
                clk                        ,
                reset                     
                
  );


  //-------------------------------------------------------------------------------------------
  // Port declarations
  //

  input                   clk       ;
  input                   reset     ;
  
  // interface from system to Decoder
  input                                                   sys__mc__dram_req         ;
  input                                                   sys__mc__dram_rdwr        ;
  input    [`DEC_CONT_SYSTEM_INTF_ADDR_RANGE       ]      sys__mc__dram_addr        ;
  input    [`DEC_CONT_SYSTEM_INTF_WRITE_DATA_RANGE ]      sys__mc__dram_wr_data     ;
  output                                                  mc__sys__dram_busy        ;
                        
  // interface from Decoder to system
  output  [`DEC_CONT_SYSTEM_INTF_READ_DATA_RANGE]         mc__sys__dram_rd_data     ;
  output                                                  mc__sys__dram_rd_done     ;


  // interface from Scheduler to Decoder
  input    [`DEC_CONT_FROM_SCH_DATA_RANGE ]               sch__dec__rd_data  ;


  // interface from Decoder to Bank Controller(s)
  `include "/afs/eos.ncsu.edu/lockers/research/ece/paulf/DiRAMController/MemoryController/HDL/common/mc_decoder_bnc_ports_declaration.vh"


  //-------------------------------------------------------------------------------------------
  // Wires and Registers
  //
  // regs for interface from Decoder to system, response interface
  reg  [`DEC_CONT_SYSTEM_INTF_READ_DATA_RANGE]         mc__sys__dram_rd_data     ;
  reg                                                  mc__sys__dram_rd_done     ;
  // reg for interface from system to Decoder, request interface
  reg                                                  mc__sys__dram_busy        ;


  `include "/afs/eos.ncsu.edu/lockers/research/ece/paulf/DiRAMController/MemoryController/HDL/common/mc_decoder_bnc_ports_wires.vh"


  //-------------------------------------------------------------------------------------------
  //------------------------------------------
  // Capture transactions from the system
  //
  genvar gvi;
  generate
    for (gvi=0; gvi<1; gvi=gvi+1) 
      begin: from_system_fifo
        `From_System_FIFO
      end
  endgenerate

  assign from_system_fifo[0].reset      = reset                    ;
  assign from_system_fifo[0].clear      = 1'b0                     ;
  assign from_system_fifo[0].rdwr       = sys__mc__dram_rdwr       ;
  assign from_system_fifo[0].addr       = sys__mc__dram_addr       ;
  assign from_system_fifo[0].wr_data    = sys__mc__dram_wr_data    ;
  // when req == 1, data will be written into FIFO, no matter the current
  // instr is read or write
  assign from_system_fifo[0].fifo_write = sys__mc__dram_req        ;
  always @(posedge clk)
    mc__sys__dram_busy    <= from_system_fifo[0].fifo_almost_full ;

  wire sys_fifo_read;
  assign from_system_fifo[0].fifo_read = sys_fifo_read ; // read comes from sys2bank controller fsm

  //-------------------------------------------------------------------------------------------
  //------------------------------------------
  // Transactions to bank Controller
  //
  
  generate
    for (gvi=0; gvi<32; gvi=gvi+1) 
      begin: to_bnc_fifo
        `To_Bnc_FIFO
      end
  endgenerate

  wire  [`DEC_CONT_SYSTEM_INTF_ADDR_RANGE          ]   sys_addr                 ; 
  wire  [`DEC_CONT_SYSTEM_ADDR_BANK_MAPPING_RANGE  ]   sys_bank_addr            ; // parts of address for bank, use to select output bank interface
  reg   [`DEC_CONT_SYSTEM_ADDR_BANK_MAPPING_RANGE  ]   sys_bank_addr_captured   ; // assume address is valid only on first cycle of request
  wire  [`DEC_CONT_SYSTEM_ADDR_BANK_MAPPING_RANGE  ]   selectedBank             ; // used to direct the bank fifo ready and bank fifo write signals

  wire  [`MC_TOP_STD_INTF_CNTL_RANGE            ]   sys2BankFifoCntl         ;

  reg   [`DEC_CONT_TO_BANK_CONT_TAG_RANGE       ]   tagToBankController      ; 


  // create a destination fifo ready by muxing the fifo_almost_full flags from
  // the bank output fifo's
  reg                                               destinationBankFifoReady ; // mux of all bank output fifo empty flags
  // create a common fifo write that is steered to bank output fifo based on
  // bank address
  wire                                              destinationBankFifoWrite ; // muxed to appropriate fifo based on bank address
  // logic to implement fifo ready and fifo write
  `include "/afs/eos.ncsu.edu/lockers/research/ece/paulf/DiRAMController/MemoryController/HDL/common/mc_decoder_bank_output_fifo_mux.vh"




  assign sys_addr       = from_system_fifo[0].fifo_read_addr ;  // extract address from fifo before separating into bank, rol, col
  assign sys_bank_addr  = sys_addr[`DEC_CONT_SYSTEM_ADDR_BANK_MAPPING_RANGE  ];

  // Connect the from system fifo outputs to all the bank controller output
  // fifo's
  // Each bank output fifo write is controlled by the controller fsm
  //
  `include "/afs/eos.ncsu.edu/lockers/research/ece/paulf/DiRAMController/MemoryController/HDL/common/mc_decoder_sys_fifo_outputs_to_bank_fifo_input_connections.vh"


  //------------------------------------------
  // Controller fsm for transfers between sys 
  // fifo and bank output fifo
  
  reg [`DEC_CONT_SYS2BANK_CNTL_STATE_RANGE ] dec_sys2bank_cntl_state     ; // state flop
  reg [`DEC_CONT_SYS2BANK_CNTL_STATE_RANGE ] dec_sys2bank_cntl_state_next;
  
  reg [2:0] sys2bankTransferCount   ;  // counter for number of transfers between system fifo and bank fifo
  
  // State register 
  always @(posedge clk)
    begin
      dec_sys2bank_cntl_state <= ( reset ) ? `DEC_CONT_SYS2BANK_CNTL_WAIT   :
                                              dec_sys2bank_cntl_state_next  ;
    end
  
  always @(*)
    begin
      case (dec_sys2bank_cntl_state)

        `DEC_CONT_SYS2BANK_CNTL_WAIT: 
          dec_sys2bank_cntl_state_next = ( (~from_system_fifo[0].fifo_empty) && ( sys2bankTransferCount ==  (`DEC_CONT_TRANSFERS_FROM_SYS_TO_BANK-1)))  ? `DEC_CONT_SYS2BANK_CNTL_SEND_SOM_EOM :  // we will only transfer if the bank output fifo has available space and check if data is transferred in one cycle
                                         ( (~from_system_fifo[0].fifo_empty)                                                                         )  ? `DEC_CONT_SYS2BANK_CNTL_SEND_SOM     :  // we will only transfer if the bank output fifo has available space
                                                                                                                                                          `DEC_CONT_SYS2BANK_CNTL_WAIT         ;  // but we can prime the output of the fifo
  
        // Note: The output of the fifo is registered, so contents only
        // available after one clock
        //
        // A cache line will take 4 transfers, so send them one after the
        // other as we already know the destination fifo has the space
        
        `DEC_CONT_SYS2BANK_CNTL_SEND_SOM: // SOM ~ start of message
          dec_sys2bank_cntl_state_next = ( (~from_system_fifo[0].fifo_empty && destinationBankFifoReady ) && ( sys2bankTransferCount ==  (`DEC_CONT_TRANSFERS_FROM_SYS_TO_BANK-1)))  ? `DEC_CONT_SYS2BANK_CNTL_SEND_EOM :  // we will only transfer if the bank output fifo has available space and check if data is transferred in one cycle
                                         (  ~from_system_fifo[0].fifo_empty && destinationBankFifoReady )                                                                            ? `DEC_CONT_SYS2BANK_CNTL_SEND_MOM :  // only transfer if the bank output fifo has available space
                                                                                                                                                                                       `DEC_CONT_SYS2BANK_CNTL_SEND_SOM ;

        `DEC_CONT_SYS2BANK_CNTL_SEND_MOM: // MOM ~ middle of message
          dec_sys2bank_cntl_state_next = ( sys2bankTransferCount == `DEC_CONT_TRANSFERS_FROM_SYS_TO_BANK-1 )  ? `DEC_CONT_SYS2BANK_CNTL_SEND_EOM :  // we have sent SOM and will send EOM, so subtract 2 from total transfer count
                                                                                                                `DEC_CONT_SYS2BANK_CNTL_SEND_MOM ;

        `DEC_CONT_SYS2BANK_CNTL_SEND_EOM:
          dec_sys2bank_cntl_state_next = ( ~from_system_fifo[0].fifo_empty && destinationBankFifoReady )  ? `DEC_CONT_SYS2BANK_CNTL_SEND_SOM :  // only transfer if the bank output fifo has available space
                                                                                                            `DEC_CONT_SYS2BANK_CNTL_WAIT     ;
  
        `DEC_CONT_SYS2BANK_CNTL_SEND_SOM_EOM:
          dec_sys2bank_cntl_state_next = ( (~from_system_fifo[0].fifo_empty && destinationBankFifoReady ) && ( sys2bankTransferCount ==  (`DEC_CONT_TRANSFERS_FROM_SYS_TO_BANK-1)))  ? `DEC_CONT_SYS2BANK_CNTL_SEND_SOM_EOM :  // we will only transfer if the bank output fifo has available space and check if data is transferred in one cycle
                                         (  ~from_system_fifo[0].fifo_empty && destinationBankFifoReady )                                                                            ? `DEC_CONT_SYS2BANK_CNTL_SEND_SOM     :  // only transfer if the bank output fifo has available space
                                                                                                                                                                                       `DEC_CONT_SYS2BANK_CNTL_WAIT         ;
  
        `DEC_CONT_SYS2BANK_CNTL_ERROR:
          dec_sys2bank_cntl_state_next = `DEC_CONT_SYS2BANK_CNTL_ERROR ;
  
        default:
          dec_sys2bank_cntl_state_next = `DEC_CONT_SYS2BANK_CNTL_WAIT ;
    
      endcase // case(so_cntl_state)
    end // always @ (*)
  
  //-------------------------------------------------------------------------------------------------
  // fsm signals
  
  always @(posedge clk)
    begin
  
      sys2bankTransferCount   <= ( reset                                                                   )          ? 'd0                     :
                                 (  (dec_sys2bank_cntl_state_next == `DEC_CONT_SYS2BANK_CNTL_WAIT          )
                                 || (dec_sys2bank_cntl_state_next == `DEC_CONT_SYS2BANK_CNTL_SEND_EOM      ) 
                                 || (dec_sys2bank_cntl_state_next == `DEC_CONT_SYS2BANK_CNTL_SEND_SOM_EOM  )       )  ? 'd0                     :
/*
                                 ((dec_sys2bank_cntl_state == `DEC_CONT_SYS2BANK_CNTL_SEND_SOM) && destinationBankFifoReady && ~from_system_fifo[0].fifo_empty   )  ? sys2bankTransferCount+1 :
                                 ((dec_sys2bank_cntl_state == `DEC_CONT_SYS2BANK_CNTL_SEND_MOM) && destinationBankFifoReady && ~from_system_fifo[0].fifo_empty   )  ? sys2bankTransferCount+1 :
*/
                                 ( sys_fifo_read                                                          )           ? sys2bankTransferCount+1 :
                                                                                                                        sys2bankTransferCount   ;

      // captured bank address on first cycle
      sys_bank_addr_captured   <= ( reset                                                           )  ? 'd0                     :
                                  ( dec_sys2bank_cntl_state == `DEC_CONT_SYS2BANK_CNTL_SEND_SOM     )  ? sys_bank_addr           :
                                  ( dec_sys2bank_cntl_state == `DEC_CONT_SYS2BANK_CNTL_SEND_SOM_EOM )  ? sys_bank_addr           :
                                                                                                         sys_bank_addr_captured  ;
    end

  // fifo read to "from system" fifo, it is valid when state is WAIT, and
  // input FIFO is not empty, state is SOM | MOM | EOM, input FIFO is not empty and output
  // fifo is ready
  assign sys_fifo_read             = ((dec_sys2bank_cntl_state == `DEC_CONT_SYS2BANK_CNTL_WAIT        ) & ( ~from_system_fifo[0].fifo_empty )                           )  |
                                     ((dec_sys2bank_cntl_state == `DEC_CONT_SYS2BANK_CNTL_SEND_SOM    ) & ( ~from_system_fifo[0].fifo_empty & destinationBankFifoReady ))  |
                                     ((dec_sys2bank_cntl_state == `DEC_CONT_SYS2BANK_CNTL_SEND_MOM    ) & ( ~from_system_fifo[0].fifo_empty & destinationBankFifoReady ))  |
                                     ((dec_sys2bank_cntl_state == `DEC_CONT_SYS2BANK_CNTL_SEND_EOM    ) & ( ~from_system_fifo[0].fifo_empty & destinationBankFifoReady ))  |
                                     ((dec_sys2bank_cntl_state == `DEC_CONT_SYS2BANK_CNTL_SEND_SOM_EOM) & ( ~from_system_fifo[0].fifo_empty & destinationBankFifoReady ))  ;

  // it is valid when state is SOM | MOM, and input fifo is not empty, and
  // output fifo is ready. Or state is EOM				     
  assign destinationBankFifoWrite  = ((dec_sys2bank_cntl_state == `DEC_CONT_SYS2BANK_CNTL_SEND_SOM    ) & ( ~from_system_fifo[0].fifo_empty & destinationBankFifoReady ))  |
                                     ((dec_sys2bank_cntl_state == `DEC_CONT_SYS2BANK_CNTL_SEND_MOM    ) & ( ~from_system_fifo[0].fifo_empty & destinationBankFifoReady ))  |
                                     ((dec_sys2bank_cntl_state == `DEC_CONT_SYS2BANK_CNTL_SEND_SOM_EOM)                                                                 )  |
                                     ((dec_sys2bank_cntl_state == `DEC_CONT_SYS2BANK_CNTL_SEND_EOM    )                                                                 )  ;

  // the cntl signal sent to each bank controller 				     
  assign sys2BankFifoCntl          = (dec_sys2bank_cntl_state == `DEC_CONT_SYS2BANK_CNTL_SEND_SOM     ) ? `MC_STD_INTF_CNTL_SOM      :
                                     (dec_sys2bank_cntl_state == `DEC_CONT_SYS2BANK_CNTL_SEND_MOM     ) ? `MC_STD_INTF_CNTL_MOM      :
                                     (dec_sys2bank_cntl_state == `DEC_CONT_SYS2BANK_CNTL_SEND_SOM_EOM ) ? `MC_STD_INTF_CNTL_SOM_EOM  :
                                                                                                          `MC_STD_INTF_CNTL_EOM      ;

  assign selectedBank              = (dec_sys2bank_cntl_state == `DEC_CONT_SYS2BANK_CNTL_SEND_SOM     ) ? sys_bank_addr          :  // select bank when data first registered from fifo
                                     (dec_sys2bank_cntl_state == `DEC_CONT_SYS2BANK_CNTL_SEND_SOM_EOM ) ? sys_bank_addr          :  // select bank when data first registered from fifo
                                                                                                          sys_bank_addr_captured ;  // after first fifo output, use captured address to select target bank fifo
                                                                                                    

  //-------------------------------------------------------------------------------------------
  // Tag generation
  //

  always @(posedge clk)
    begin
      tagToBankController      <= ( reset                                                       )  ? 'd0                    :
                                  ( dec_sys2bank_cntl_state == `DEC_CONT_SYS2BANK_CNTL_SEND_EOM )  ? tagToBankController+1  :
                                                                                                     tagToBankController    ;
    end
  

  //-------------------------------------------------------------------------------------------
  //------------------------------------------
  // Bank output fifo's to IO to bank Controller
  //
  
  // Port outputs to Bank Controller
  // 
  `include "/afs/eos.ncsu.edu/lockers/research/ece/paulf/DiRAMController/MemoryController/HDL/common/mc_decoder_bank_output_fifo_io_connections.vh"


endmodule

