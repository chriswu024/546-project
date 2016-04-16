`include "/afs/eos.ncsu.edu/lockers/research/ece/paulf/DiRAMController/MemoryController/HDL/common/mc_decoder.vh"
//`include "instructions.sv"


import instruction::*;
import virtual_interface::*;
import scb_classes::*;


////////////////////////////////////////////////////////////////
// scoreboard class
////////////////////////////////////////////////////////////////
class Scoreboard;
    From_System_FIFO fifo;
    vCPU_T vSys2Dec;
    vDEC_T vDec2Bnc;
    FIFO_Data from_driver_data;
    FIFO_Data from_fifo_data;
    CPU_Instr cpu_instr;
    int iexpect, iactual;
    

    extern function new(input vCPU_T vSys2Dec,
                        input vFIFO_T vFifo);
    extern virtual function void wrap_up();
    extern function void save_expected(input CPU_Instr cpu_instr);
    extern function void check_actual(input FIFO_Instr fifo_instr);
    extern task write_to_input_fifo();
    extern task write_to_output_fifo();
    extern task read_from_input_fifo();
    extern task read_from_output_fifo();
    extern task fsm(();
    extern virtual task run();
   // extern function void display(input string prefix="");
endclass:Scoreboard


//---------------------------------------------------------------
// construct a new socreboard
//---------------------------------------------------------------
function Scoreboard::new(input vCPU_T vSys2Dec,
                         input vDEC_T vDec2Bnc);
    fifo = new();
    from_driver_data = new();
    from_fifo_data = new();
    cpu_instr = new();
    this.vSys2Dec = vSys2Dec;
    this.vDec2Bnc = vDec2Bnc;
endfunction:new

//---------------------------------------------------------------
// save the instruction sent from the driver
//---------------------------------------------------------------
function void Scoreboard::save_expected(input CPU_Instr cpu_instr);
    from_driver_data = cpu_instr.to_FIFO_Data;
    fifo.fifo_write = cpu_instr.sys__mc__req;
    cpu_instr.display($sformatf("@%0t: Scb save: ", $time));
endfunction:save_expected

//---------------------------------------------------------------
// write cpu_instr to fifo
//---------------------------------------------------------------
/*
task Scoreboard::write_to_fifo();
    wait (vSys2Dec.cb.sys__mc__dram_req == 1);
    @(vSys2Dec.cb);
    if (fifo.fifo_write == 1) begin
	from_driver_data.display($sformatf("@%0t: Writting to fifo: ", $time));
    end
    else begin 
	$display("@%0t: fifo_write: %0d", $time, fifo.fifo_write);
    end
    fifo.capacity_check();
    fifo.write_data(from_driver_data);
    iexpect ++;
endtask:write_to_fifo
*/

//---------------------------------------------------------------
// write cpu_instr to fifo
//---------------------------------------------------------------
task Scoreboard::run();
    repeat (5) begin
	write_to_fifo();
    end
endtask



//---------------------------------------------------------------
// check the instr from scb with the instr from monitor for correctness
//---------------------------------------------------------------
function void Scoreboard::check_actual(input FIFO_Instr fifo_instr);
    fifo_instr.display($sformatf("@%0t: Scb check: ", $time));
    
    if (fifo.q.size() == 0)begin
	$display("@%0t: ERROR, scb empty", $time);
	return;
    end

    iactual++;

    fifo.fifo_read = 1'b1;
    from_fifo_data = fifo.read_data();
    if(from_fifo_data.compare(fifo_instr))
	$display("@%0t: Match FIFO read data", $time);
    else 
        $display("@%0t: Wrong FIFO read data", $time);
endfunction:check_actual


//---------------------------------------------------------------
// wrap_up
//---------------------------------------------------------------
function void Scoreboard::wrap_up();
    $display("@%0t: expected data number:%0d, actual data number:%0d", $time, iexpect, iactual);
endfunction:wrap_up



        

    

