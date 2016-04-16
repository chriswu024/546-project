//`include "instructions.sv"
import instruction::*;
class Generator;
    CPU_Instr blueprint;
    mailbox   gen2drv;
    event     drv2gen;

    function new(input mailbox gen2drv,
                 input event drv2gen);
        this.gen2drv = gen2drv;
        this.drv2gen = drv2gen;
	blueprint = new();
    endfunction : new


    task run();
	CPU_Instr cpu_instr;
	repeat (5) begin
	    assert(blueprint.randomize());
	    $cast(cpu_instr, blueprint.copy());
	    cpu_instr.display($sformatf("@%0t: Gen: ", $time));	
	    gen2drv.put(cpu_instr);
	    @drv2gen;   // wait for driver to finish with it
	end
    endtask : run
endclass:Generator

