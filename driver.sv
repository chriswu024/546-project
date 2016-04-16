//`include "instructions.sv"
//`include "interface.sv"
import instruction::*;
import virtual_interface::*;
////////////////////////////////////////////////////////////////
// basic driver cbs class
////////////////////////////////////////////////////////////////
typedef class Driver;

class Driver_cbs;
    virtual task pre_tx(input Driver drv,
                        input CPU_Instr cpu_instr,
                        inout bit drop);
    endtask : pre_tx

    virtual task post_tx(input Driver drv,
	                 input CPU_Instr cpu_instr);
    endtask : post_tx
endclass : Driver_cbs



////////////////////////////////////////////////////////////////
// Driver class
////////////////////////////////////////////////////////////////
typedef class Driver_cbs;
class Driver;

    mailbox gen2drv;       // Mailbox between Gen and Dri, notice there is only one mailbox
    event   drv2gen;
    vCPU_T vSys2Dec;
    vDEC_T vDec2Bnc[];
    int numBnc;
    Driver_cbs cbsq[$];    // Queue of callback objects
    
    extern function new (input mailbox gen2drv,
	                 input event   drv2gen,
	                 input vCPU_T vSys2Dec,
                         input vDEC_T vDec2Bnc[],
                         input int numBnc    );
    extern task run();
    extern task send (input CPU_Instr cpu_instr,
	              input FIFO_Instr fifo_instr);

endclass : Driver


//---------------------------------------------------------------
// new(): Construct a driver object
//---------------------------------------------------------------
function Driver::new (input mailbox gen2drv,
	              input event   drv2gen,    
                      input vCPU_T vSys2Dec,
                      input vDEC_T vDec2Bnc[],
                      input int numBnc    );
    this.gen2drv = gen2drv;
    this.drv2gen = drv2gen;
    this.vSys2Dec = vSys2Dec;
    this.vDec2Bnc[] = vDec2Bnc[];
    this.numBnc = numBnc;
endfunction : new


//---------------------------------------------------------------
// run(): Run the driver
// Get transactions from generator, send into DUT
//---------------------------------------------------------------
task Driver::run();
    CPU_Instr cpu_instr;           // handle to a Transaction object

    bit drop = 0;

    // Initialize ports
    
    repeat (5) begin
	// Read the cell at the front of the mailbox
	gen2drv.peek(cpu_instr);
	begin: CPU_Instr
	    // Pre-transmit callbacks
	    foreach (cbsq[i]) begin
		cbsq[i].pre_tx(this, cpu_instr, drop);
		if (drop) disable CPU_Instr;   // Don't transmit this instruction
	    end
        
            cpu_instr.display($sformatf("@%0t: Drv: ", $time));
	    send(cpu_instr, fifo_instr);

            // Post-transmit callbacks
	    foreach (cbsq[i]) begin
	        cbsq[i].post_tx(this, cpu_instr);
            end
	end: CPU_Instr

	gen2drv.get(cpu_instr);     // Remove cell from the mailbox
	->drv2gen;          // Tell the generator we are done with this cell
    end
endtask : run


//---------------------------------------------------------------
// Send(): Send a cell into the DUT
//---------------------------------------------------------------
task Driver::send(input CPU_Instr cpu_instr,
                  input FIFO_Instr fifo_instr);
    $display ("Sending instruction: ");
    fork begin
	// send CPU instructions to DUT at each clock cycle
	@ (vSys2Dec.cb); begin
	    vSys2Dec.cb.sys__mc__dram_req <= cpu_instr.sys__mc__req;
	    vSys2Dec.cb.sys__mc__dram_rdwr <= cpu_instr.sys__mc__rdwr;
	    vSys2Dec.cb.sys__mc__dram_wr_data <= cpu_instr.sys__mc__wr_data;
	    vSys2Dec.cb.sys__mc__dram_addr <= cpu_instr.sys__mc__addr;
	    vSys2Dec.cb.input_fifo_read <= cpu_instr.input_fifo_read;
	end
	foreach (vDec2Bnc[i]) begin
	    @ (vDec2Bnc[i].cb); begin
		vDec2Bnc[i].cb.bnc__dec__ready <= cpu_instr.bnc_dec_ready[i];
	    end
	end
endtask : send




  
