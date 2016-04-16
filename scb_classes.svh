package scb_classes;
////////////////////////////////////////////////////////////////
// parameterized fifo class
////////////////////////////////////////////////////////////////
class Fifo #(type T=int);
    T q[$:10];
    // control signal for FIFO
    logic   fifo_read;
    logic   fifo_write;
    logic   fifo_write_delay;
    logic   clear;
    logic   reset;
    logic   fifo_empty;
    logic   fifo_almost_full;

    // write data
    function void write_data(input T fifo_write_data);
	if (reset) q = {};
	else if (clear) q = {};
	else if (fifo_write) 
	    q.push_back(fifo_write_data);
    endfunction:write_data

    // read data
    function T read_data();
	if (reset) q = {};
	else if (clear) q = {};
	else if (fifo_read)
	    return q.pop_front;
    endfunction:read_data

    // empty and almost_full signal
    function void capacity_check();
	fifo_empty = (q.size() == 0);
	fifo_almost_full = (q.size() >= 8);
    endfunction:capacity_check
    
endclass:Fifo

////////////////////////////////////////////////////////////////
// Decoder class
////////////////////////////////////////////////////////////////
class Decoder;
    Fifo #(Input_FIFO_Data) input_fifo;
    Fifo #(Output_FIFO_Data) output_fifo[];
    Input_FIFO_Data IFD, try_IFD, IFD_delay;
    Output_FIFO_Data OFD, OFD_delay;
    logic fifo_write_delay;
    logic output_fifo_wr;
    logic output_fifo_ready;
    logic input_fifo_read;
    logic sys2BFCntl;
    logic sys_bank_addr;
    logic sys_bank_addr_captured;
    int   count;
    logic [`DEC_CONT_SYS2BANK_CNTL_STATE_RANGE ] cntl_state     ; // state flop
    logic [`DEC_CONT_SYS2BANK_CNTL_STATE_RANGE ] cntl_state_next;
    parameter   WAIT     =   6'b00_0001
		SOM      =   6'b00_0010
		MOM      =   6'b00_0100
		EOM      =   6'b00_1000
		SOM_EOM  =   6'b01_0000
		ERROR    =   6'b10_0000

    
    extern function new();
    extern function void output_fifo_wr_generation();
    extern function void output_fifo_ready_generation(input int selectedbank);
    extern function void Count_generation();
    extern function void Input_fifo_read_generation();
    extern function void Selectedbank_generation();
    extern function void Addr_generation();
    extern function void write_to_input_fifo(input Input_FIFO_Data IFD);
    extern function void read_from_input_fifo();
    extern function void try_read_from_input_fifo();
    extern function void write_to_output_fifo(input Output_FIFO_Data OFD);
    extern function void output_fifo_write_signal_generation();
    extern function void read_from_output_fifo();
    extern function void output_fifo_read_signal_generation(input bit bnc_dec_ready[])
    extern function void fsm();
    extern task run();
endclass:Decoder

//--------------------------------------------------------------
// Construct an decoder instance
//--------------------------------------------------------------
function Decoder::new();
    this.input_fifo = input_fifo;
    this.output_fifo[] = new[output_fifo.size()];
    foreach (output_fifo[i]) this.output_fifo[i] = output_fifo[i];
endfunction
   

//--------------------------------------------------------------
// generate the destination bank fifo write signal
//--------------------------------------------------------------
function Decoder::output_fifo_wr_generation();
    input_fifo.capacity_check();
    if ((cntl_state == SOM) && (~input_fifo.fifo_empty) && output_fifo_ready)
	output_fifo_wr = 1;
    else if ((cntl_state == MOM) && (~input_fifo.fifo_empty) && output_fifo_ready))
	output_fifo_wr = 1;
    else if (cntl_state == EOM)
	output_fifo_wr = 1;
    else 
	output_fifo_wr = 0;
endfunction:output_fifo_wr_generation


//--------------------------------------------------------------
// generate the destination bank fifo ready signal
// which means that the selected bank fifo is not almost full
//--------------------------------------------------------------
function Decoder::output_fifo_ready_generation(input int selectedbank);
    output_fifo[selectedbank].capacity_check();
    if (output_fifo[selectedbank].fifo_almost_full == 0)
	output_fifo_ready = 1;
endfunction:output_fifo_ready_generation

//--------------------------------------------------------------
// generate count, which is used to determine which stage is in when 
// transferring the instruction
//--------------------------------------------------------------
function Decoder::Count_generation();
    if (reset) 
	count = 0;
    else if (cntl_state_next == WAIT) || (cntl_state_next == EOM)
	count = 0;
    else if (input_fifo_read == 1)
	count ++;
    else 
	count = count;
endfunction:Count_generation

//--------------------------------------------------------------
// generate the input_fifo_read signal
//--------------------------------------------------------------
function Decoder::Input_fifo_read_generation();
    input_fifo.capacity_check();
    input_fifo_read =   ((cntl_state == WAIT   ) & ( ~input_fifo.fifo_empty )                           )  |
		      ((cntl_state == SOM    ) & ( ~input_fifo.fifo_empty & destinationBankFifoReady ))  |
		      ((cntl_state == MOM    ) & ( ~input_fifo.fifo_empty & destinationBankFifoReady ))  |
		      ((cntl_state == EOM    ) & ( ~input_fifo.fifo_empty & destinationBankFifoReady ))  ;
endfunction:Input_fifo_read_generation

//--------------------------------------------------------------
// generate the chosen bank address
//--------------------------------------------------------------
function Decoder::Selectedbank_generation();
    selbnk_write = selectedbank;
    if (cntl_state == SOM)
	selectedbank = sys_bank_addr;
    else
	selectedbank = sys_bank_addr_caputred;
endfunction:Selectedbank_generation

//--------------------------------------------------------------
// write to input fifo
//--------------------------------------------------------------
function Decoder::Addr_generation();
    // capture the value of address at previous cycle
    if (reset)
	sys_bank_addr_captured = 0;
    else if (cntl_state == SOM)
	sys_bank_addr_captured = sys_bank_addr;
    else 
	sys_bank_addr_captured = sys_bank_addr_captured;
    // generate the bank address value, asyn
    sys_bank_addr = try_IFD.sys__mc__fifo_addr[28:24];
endfunction:Addr_generation


//--------------------------------------------------------------
// write to input fifo
//--------------------------------------------------------------
function void Decoder::write_to_input_fifo(input Input_FIFO_Data IFD,
                                           input logic fifo_write);
    input_fifo.capacity_check();
    input_fifo.fifo_write = fifo_write_delay;
    input_fifo.write_data(IFD_delay);
    IFD_delay = IFD;
    fifo_write_delay = fifo_write;
    iexpect ++;
endfunction:write_to_input_fifo

//--------------------------------------------------------------
// try read from input fifo
//--------------------------------------------------------------
function void Decoder::try_read_from_input_fifo();
    input_fifo.capacity_check();
    input_fifo.fifo_read = input_fifo_read;
    try_IFD = input_fifo.read_data();
endfunction:read_from_input_fifo;
//--------------------------------------------------------------
// read from input fifo
//--------------------------------------------------------------
function void Decoder::read_from_input_fifo();
    input_fifo.capacity_check();
    IFD = input_fifo.read_data();
    input_fifo.fifo_read = input_fifo_read;
endfunction:read_from_input_fifo;
   
//--------------------------------------------------------------
// generate write enable signal for output fifo
//--------------------------------------------------------------
function void Decoder::output_fifo_write_signal_generation();
    // write to output fifo using the writing signal generated at 
    // previous cycle
    Addr_generation();
    Selectedbank_generation();
    foreach(output_fifo[i]) begin
	if (i == selectedbank) begin
	    output_fifo[i].capacity_check();
	    output_fifo_ready_generation(i);
	    output_fifo_wr_generation();
	    if (output_fifo_wr)
		output_fifo[i].fifo_write_delay = 1;
	    else
		output_fifo[i].fifo_write_delay = 0;
	else 
	    output_fifo[i].fifo_write = 0;
endfunction:write_to_output_fifo

//--------------------------------------------------------------
// write to selected output fifo
//--------------------------------------------------------------
function void Decoder::write_to_output_fifo(input Output_FIFO_Data OFD);
    output_fifo[selbnk_write].write_data(OFD_delay);
    OFD_delay = OFD;
    output_fifo[selbnk_write].fifo_write = output_fifo[selbnk_write].fifo_write_delay;
endfunction:write_to_output_fifo

//--------------------------------------------------------------
// generate output fifo read signal
//--------------------------------------------------------------
function void Decoder::output_fifo_read_signal_generation(input bit bnc_dec_ready[]);
    // read the data using the fifo_read signal generated in last cycle
    // to make sure the read operation is synchronous
    foreach (output_fifo[i]) begin
	if (bnc_dec_ready[i] == 1) begin
	    output_fifo[i].capacity_check();
	    output_fifo[i].fifo_read = (bnc_dec_ready[i]) && (~output_fifo[i].fifo_empty);
	end
    end
endfunction:output_fifo_read_signal_generation


//--------------------------------------------------------------
// read from output fifo
//--------------------------------------------------------------
function void Decoder::read_from_output_fifo();
    foreach (output_fifo[i])begin
	if (output_fifo[i].fifo_read) 
	    OFD[i] = output_fifo[i].read_data();
    end
endfunction:read_from_output_fifo

//--------------------------------------------------------------
// FSM 
//--------------------------------------------------------------
function void Decoder::fsm();
    input_fifo.capacity_check();
    cntl_state = (reset) ? WAIT : cntl_state_next;
    casex(cntl_state)
	WAIT: begin 
	    cntl_state_next = (~input_fifo.q.fifo_empty) ? SOM : WAIT;
	end
	SOM: begin
	    cntl_state_next = (~input_fifo.q.fifo_empty && output_fifo_ready) ? MOM : SOM;
	    sys2BFCntl = 1;
	end
	MOM: begin
	    cntl_state_next = (count == 3) ? EOM : MOM;
	    sys2BFCntl = 0;
	end
	EOM: begin
	    cntl_state_next = (~input_fifo.q.fifo_empty && output_fifo_ready) ? SOM : EOM;
	    sys2BFCntl = 2;
	end
	default: cntl_state_next = WAIT;
    endcase
endfunction:fsm

//--------------------------------------------------------------
// actual decoding process 
//--------------------------------------------------------------
task Decoder::run();
    // generate the count value for FSM
    Count_generation();
    // transfer between different cntl_state
    fsm();
    // read the instruction from output fifo
    read_from_output_fifo();
    // generate read control signal for output fifos, we delay the 
    output_fifo_read_signal_generation();
    // writing to output fifo, which is one cycle later than the
    // fifo_write signal being high, we achieve this by delaying input data
    // and write control signal
    write_to_output_fifo();
    // generate write control signal for output fifos
    output_fifo_write_signal_generation();
    // read the data from input fifo
    read_from_input_fifo();
    // generate the read control signal for input fifo
    Input_fifo_read_generation();
    // read the instruction one cycle earlier to generate the asyn signal
    try_read_from_input_fifo();
    // write instruction to input fifo
    write_to_input_fifo();
endtask:run

endpackage:scb_classes
