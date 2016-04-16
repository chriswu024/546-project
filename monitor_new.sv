import instruction::*;
import virtual_interface::*;

/////////////////////////////////////////////////////////
// Basic cbs class for monitor
/////////////////////////////////////////////////////////
typedef class Monitor;

class Monitor_cbs;
    virtual task post_rx(input Monitor mon,
			 input FIFO_Instr fifo_instr);
    endtask : post_rx
endclass: Monitor_cbs



/////////////////////////////////////////////////////////
// Monitor class
////////////////////////////////////////////////////////
typedef class Monitor_cbs;
class Monitor;
    vDEC_T vDec2Bnc;            // Virtual interface with output of mc_decoder
    Monitor_cbs cbsq[$];        // Queue of callback objects
    int PortID;
    extern function new (input vDEC_T vDec2Bnc, input int PortID);
    extern task run();
    extern task receive(output FIFO_Instr fifo_instr);
endclass : Monitor

//----------------------------------------------------------
//construct an monitor instance
//----------------------------------------------------------
function Monitor::new(input vDEC_T vDec2Bnc, input int PortID);
    this.vDec2Bnc = vDec2Bnc;
    this.PortID = PortID;
endfunction:new

//----------------------------------------------------------
// let the monitor run
//----------------------------------------------------------
task Monitor::run();
    FIFO_Instr fifo_instr;
    repeat (5) begin
        receive(fifo_instr);
        foreach (cbsq[i])
    	cbsq[i].post_rx(this, fifo_instr);
    end
endtask

//----------------------------------------------------------
// let the monitor receive data from fifo_ifc
//----------------------------------------------------------
task Monitor::receive(output FIFO_Instr fifo_instr);
    fifo_instr = new();
    wait (vDec2Bnc.cb.bnc__dec__ready == 1);
    @ (vDec2Bnc.cb);
	fifo_instr.dec__bnc__valid    = vDec2Bnc.cb.dec__bnc__valid    ;
	fifo_instr.dec__bnc__page_addr= vDec2Bnc.cb.dec__bnc__page_addr;
	fifo_instr.dec__bnc__col_addr = vDec2Bnc.cb.dec__bnc__col_addr ;
	fifo_instr.dec__bnc__rdwr     = vDec2Bnc.cb.dec__bnc__rdwr     ;
	fifo_instr.dec__bnc__wr_data  = vDec2Bnc.cb.dec__bnc__wr_data  ;
	fifo_instr.dec__bnc__cntl     = vDec2Bnc.cb.dec__bnc__cntl     ;
	fifo_instr.dec__bnc__tag      = vDec2Bnc.cb.dec__bnc__tag      ;
    fifo_instr.display($sformatf("@%0t: Mon: ", $time));
endtask : receive
