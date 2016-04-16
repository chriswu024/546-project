package instruction;
`include "/afs/eos.ncsu.edu/lockers/research/ece/paulf/DiRAMController/MemoryController/HDL/common/common.vh"
`include "/afs/eos.ncsu.edu/lockers/research/ece/paulf/DiRAMController/MemoryController/HDL/common/mc.vh"
`include "/afs/eos.ncsu.edu/lockers/research/ece/paulf/DiRAMController/MemoryController/HDL/common/mc_decoder.vh"

///////////////////////////////////////////////////////////////////
// pure virtual BaseTr class for other transactions
///////////////////////////////////////////////////////////////////
virtual class BaseTr;
    static int count;    // Number of instance created
    int id;              // Unique transaction id

    function new();
	id = count++;    // Give each object a unique ID
    endfunction

    pure virtual function bit compare (input BaseTr to);
    pure virtual function BaseTr copy ();
    pure virtual function void display (input string prefix="");

endclass : BaseTr


///////////////////////////////////////////////////////////////////
// CPU instruction class
///////////////////////////////////////////////////////////////////
class CPU_Instr extends BaseTr;
    // Physical fields
    rand logic                                                sys__mc__req         ;
    rand logic                                                sys__mc__rdwr        ;
    rand logic [`DEC_CONT_SYSTEM_INTF_ADDR_RANGE       ]      sys__mc__addr        ;
    rand logic [`DEC_CONT_SYSTEM_INTF_WRITE_DATA_RANGE ]      sys__mc__wr_data     ;

    extern virtual function void display(input string prefix="");
    extern virtual function BaseTr copy();
    extern function Input_FIFO_Data to_Input_FIFO_Data();
    extern virtual function bit compare(input BaseTr to);
endclass : CPU_Instr


///////////////////////////////////////////////////////////////////
// intput_fifo_data class
///////////////////////////////////////////////////////////////////
class Input_FIFO_Data extends BaseTr;
    // Physical fields
    logic                                                   sys__mc__fifo_rdwr        ;
    logic    [`DEC_CONT_SYSTEM_INTF_ADDR_RANGE       ]      sys__mc__fifo_addr        ;
    logic    [`DEC_CONT_SYSTEM_INTF_WRITE_DATA_RANGE ]      sys__mc__fifo_wr_data     ;

    extern virtual function void display(input string prefix="");
    extern virtual function BaseTr copy();
    extern function bit compare(input BaseTr to); 
endclass : Input_FIFO_Data

///////////////////////////////////////////////////////////////////
// fifo_instruction class
///////////////////////////////////////////////////////////////////
class FIFO_Instr extends BaseTr;
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

    extern virtual function void display(input string prefix="");
    extern virtual function bit compare(input BaseTr to); 
    extern virtual function BaseTr copy();
endclass : FIFO_Instr

///////////////////////////////////////////////////////////////////
// output_fifo_data class
///////////////////////////////////////////////////////////////////
class Output_FIFO_Data extends BaseTr;
    // Physical fields
    logic    [`DEC_CONT_TO_BANK_CONT_ROW_ADDR_RANGE  ]        dec__bnc__page_addr   ;
    logic    [`DEC_CONT_TO_BANK_CONT_COL_ADDR_RANGE  ]        dec__bnc__col_addr    ;
    logic                                                     dec__bnc__rdwr        ;
    logic    [`DEC_CONT_TO_BANK_CONT_CMD_RANGE       ]        dec__bnc__wr_data     ;
    logic    [`DEC_CONT_TO_BANK_CONT_CNTL_RANGE      ]        dec__bnc__cntl        ;
    logic    [`DEC_CONT_TO_BANK_CONT_CMD_RANGE       ]        dec__bnc__tag         ;

    extern virtual function void display(input string prefix="");
    extern virtual function BaseTr copy();
    extern function bit compare(input BaseTr to); 
endclass : Output_FIFO_Data

///////////////////////////////////////////////////////////////////
// extern functions for CPU_instruction class
///////////////////////////////////////////////////////////////////
function void CPU_Instr::display(input string prefix="");
    $display("%sCPU_Instr id: %0d address:%0h, wr_data:%0h, rdwr:%0h, req:%0b",
             prefix, id, sys__mc__addr, sys__mc__wr_data, sys__mc__rdwr, sys__mc__req);
endfunction : display

// Make a copy of this object
function BaseTr CPU_Instr::copy();
    CPU_Instr Ccopy;
    Ccopy = new();
    Ccopy.sys__mc__req    = this.sys__mc__req         ;
    Ccopy.sys__mc__rdwr   = this.sys__mc__rdwr        ;
    Ccopy.sys__mc__addr   = this.sys__mc__addr        ;
    Ccopy.sys__mc__wr_data= this.sys__mc__wr_data     ;
    return Ccopy;
endfunction : copy

function Input_FIFO_Data CPU_Instr::to_Input_FIFO_Data();
    Input_FIFO_Data copy;
    copy = new();
    copy.sys__mc__fifo_rdwr = this.sys__mc__rdwr;
    copy.sys__mc__fifo_addr = this.sys__mc__addr;
    copy.sys__mc__fifo_wr_data = this.sys__mc__wr_data;
    return copy;
endfunction:to_Input_FIFO_Data

function bit CPU_Instr::compare(input BaseTr to);
    Input_FIFO_Data fifo_data;
    $cast(fifo_data, to);
    if (this.sys__mc__rdwr != fifo_data.sys__mc__fifo_rdwr) return 0;
    if (this.sys__mc__addr != fifo_data.sys__mc__fifo_addr) return 0;
    if (this.sys__mc__wr_data != fifo_data.sys__mc__fifo_wr_data) return 0;
    return 1;
endfunction:compare


///////////////////////////////////////////////////////////////////
// extern functions for fifo_data class
///////////////////////////////////////////////////////////////////
function void Input_FIFO_Data::display(input string prefix="");
    $display("%sInput_FIFO_Data id: %0d address:%0h, wr_data:%0h, rdwr:%0h",
             prefix, id, sys__mc__fifo_addr, sys__mc__fifo_wr_data, sys__mc__fifo_rdwr);
endfunction : display

function bit Input_FIFO_Data::compare(input BaseTr to);
    FIFO_Instr fifo_instr;
    $cast(fifo_instr, to);
    if (this.sys__mc__fifo_rdwr != fifo_instr.sys__mc__fifo_rdwr) return 0;
    if (this.sys__mc__fifo_addr != fifo_instr.sys__mc__fifo_addr) return 0;
    if (this.sys__mc__fifo_wr_data != fifo_instr.sys__mc__fifo_wr_data) return 0;
    return 1;
endfunction:compare


function BaseTr Input_FIFO_Data::copy();
    Input_FIFO_Data FDcopy;
    FDcopy = new();
    FDcopy.sys__mc__fifo_rdwr    = this.sys__mc__fifo_rdwr       ;
    FDcopy.sys__mc__fifo_addr   = this.sys__mc__fifo_addr        ;
    FDcopy.sys__mc__fifo_wr_data= this.sys__mc__fifo_wr_data     ;
    return FDcopy;
endfunction : copy


///////////////////////////////////////////////////////////////////
// extern functions for fifo_instruction class
///////////////////////////////////////////////////////////////////
function void FIFO_Instr::display(input string prefix="");
    $display("%sFIFO_Instr id: %0d page_address:%0d, col_address:%0d, wr_data:%0d, rdwr:%0h, cntl:%0d, tag:%0d",
             prefix, id, dec__bnc__page_addr, dec__bnc__col_addr, dec__bnc__wr_data, dec__bnc__rdwr, dec__bnc__cntl, dec__bnc__tag);
endfunction : display

function bit FIFO_Instr::compare(input BaseTr to);
    Output_FIFO_Data fifo_data;
    $cast(fifo_data, to);
    if (this.dec__bnc__page_addr != fifo_data.dec__bnc__page_addr) return 0;
    if (this.dec__bnc__col_addr != fifo_data.dec__bnc__col_addr) return 0;
    if (this.dec__bnc__wr_data != fifo_data.dec__bnc__wr_data) return 0;
    if (this.dec__bnc__rdwr != fifo_data.dec__bnc__rdwr) return 0;
    if (this.dec__bnc__cntl != fifo_data.dec__bnc__cntl) return 0;
    if (this.dec__bnc__tag != fifo_data.dec__bnc__tag) return 0;
    return 1;
endfunction:compare


// Make a copy of this object
function BaseTr FIFO_Instr::copy();
    FIFO_Instr FIcopy;
    FIcopy = new();
    FIcopy.dec__bnc__valid  = this.dec__bnc__valid       ;
    FIcopy.dec__bnc__page_addr  = this.dec__bnc__page_addr       ;
    FIcopy.dec__bnc__rdwr   = this.dec__bnc__rdwr        ;
    FIcopy.dec__bnc__col_addr   = this.dec__bnc__col_addr        ;
    FIcopy.dec__bnc__wr_data= this.dec__bnc__wr_data     ;
    FIcopy.dec__bnc__cntl = this.dec__bnc__cntl     ;
    FIcopy.dec__bnc__tag= this.dec__bnc__tag     ;
    FIcopy.bnc__dec__ready= this.bnc__dec__ready     ;
    return FIcopy;
endfunction : copy



///////////////////////////////////////////////////////////////////
// extern functions for output_fifo_data class
///////////////////////////////////////////////////////////////////
function void Output_FIFO_Data::display(input string prefix="");
    $display("%sOutput_FIFO_Data id: %0d page_address:%0d, col_address:%0d, wr_data:%0d, rdwr:%0h, cntl:%0d, tag:%0d",
             prefix, id, dec__bnc__page_addr, dec__bnc__col_addr, dec__bnc__wr_data, dec__bnc__rdwr, dec__bnc__cntl, dec__bnc__tag);
endfunction : display

function bit Output_FIFO_Data::compare(input BaseTr to);
    FIFO_Instr fifo_instr;
    $cast(fifo_instr, to);
    if (this.dec__bnc__page_addr != fifo_data.dec__bnc__page_addr) return 0;
    if (this.dec__bnc__col_addr != fifo_data.dec__bnc__col_addr) return 0;
    if (this.dec__bnc__wr_data != fifo_data.dec__bnc__wr_data) return 0;
    if (this.dec__bnc__rdwr != fifo_data.dec__bnc__rdwr) return 0;
    if (this.dec__bnc__cntl != fifo_data.dec__bnc__cntl) return 0;
    if (this.dec__bnc__tag != fifo_data.dec__bnc__tag) return 0;
    return 1;
endfunction:compare


function BaseTr Output_FIFO_Data::copy();
    Output_FIFO_Data FDcopy;
    FDcopy = new();
    FIcopy.dec__bnc__page_addr  = this.dec__bnc__page_addr       ;
    FIcopy.dec__bnc__rdwr   = this.dec__bnc__rdwr        ;
    FIcopy.dec__bnc__col_addr   = this.dec__bnc__col_addr        ;
    FIcopy.dec__bnc__wr_data= this.dec__bnc__wr_data     ;
    FIcopy.dec__bnc__cntl = this.dec__bnc__cntl     ;
    FIcopy.dec__bnc__tag= this.dec__bnc__tag     ;
    return FDcopy;
endfunction : copy


endpackage:instruction
