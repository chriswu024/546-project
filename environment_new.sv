`include "generator.sv"
`include "driver.sv"
`include "monitor_new.sv"
`include "scoreboard.sv"

/////////////////////////////////////////////////////////
// Call scoreboard from Driver using callbacks
/////////////////////////////////////////////////////////
class Scb_Driver_cbs extends Driver_cbs;
    Scoreboard scb;

    function new(input Scoreboard scb);
	this.scb = scb;
    endfunction

    //send received instruction to scoreboard
    virtual task post_tx(input Driver drv, 
	                 input CPU_Instr cpu_instr); 
	scb.save_expected(cpu_instr);
    endtask : post_tx
endclass : Scb_Driver_cbs


/////////////////////////////////////////////////////////
// Call scoreboard from Monitor using callbacks
/////////////////////////////////////////////////////////
class Scb_Monitor_cbs extends Monitor_cbs;
    Scoreboard scb;

    function new(input Scoreboard scb);
	this.scb = scb;
    endfunction : new

    // send received instructions to scoreboard
    virtual task post_rx(input Monitor mon, input FIFO_Instr fifo_instr);
	scb.check_actual(fifo_instr, mon.PortID);
    endtask : post_rx
endclass : Scb_Monitor_cbs


/////////////////////////////////////////////////////////
// Environment class
////////////////////////////////////////////////////////
class Environment;
    Generator  gen;
    mailbox    gen2drv;
    event      drv2gen;
    Driver     drv;
    Monitor    mon[];
    Scoreboard scb;
    vCPU_T vSys2Dec;
    vDEC_T vDec2Bnc[];
    int numBnc;
    extern function new( input vDEC_T vDec2Bnc[],
	                 input int numBnc,
			 input vCPU_T vSys2Dec);
    extern virtual function void build();
    extern virtual task run();
    extern virtual function void wrap_up();

endclass:Environment
//----------------------------------------------------------
//construct an environment instance
//----------------------------------------------------------
function Environment::new(input vDEC_T vDec2Bnc[],
                          input int numBnc,
                          input vCPU_T vSys2Dec);
    this.vDec2Bnc = new[vDec2Bnc.size()];
    foreach (vDec2Bnc[i]) this.vDec2Bnc[i] = vDec2Bnc[i];
    this.numBnc = numBnc;
    this.vSys2Dec = vSys2Dec;
endfunction:new
//----------------------------------------------------------
//build the envrionment objects for this test
//objects are built for every bank controller
//even they are not used. This reduces null handle bugs
//---------------------------------------------------------
function void Environment::build();
    gen2drv = new();
    gen = new(gen2drv, drv2gen);
    drv = new(gen2drv, drv2gen, vSys2Dec, vDec2Bnc, numBnc);
    scb = new(vSys2Dec, vDec2Bnc);

    mon = new[numBnc];
    foreach (mon[i])
	mon[i] = new(vDec2Bnc[i], i);

    //Connect scb to drv & mon with callbacks
    begin
	Scb_Driver_cbs  sdc = new(scb);
	Scb_Monitor_cbs smc = new(scb);
        drv.cbsq.push_back(sdc);
        foreach(mon[i])	mon[i].cbsq.push_back(smc);
    end
endfunction:build
//----------------------------------------------------------
// Start the transactors: generators, drivers, monitors
//----------------------------------------------------------
task Environment::run();
    // start the generator and driver
    fork
	gen.run();
	drv.run();
	scb.run();
    join_none

    // start the monitor for each bank controller
    foreach(mon[i]) begin
	int j = i;             // Automatic variable to hold index in spawned threads
	fork 
	    mon[j].run();
	join_none
    end

    // wait a little longer for the data flow through switch, into monitors,
    // and scoreboards
    repeat (20) @vSys2Dec.cb;
endtask : run
//----------------------------------------------------------
// Post_run cleaup / reporting
//----------------------------------------------------------
function void Environment::wrap_up();
    scb.wrap_up;
endfunction:wrap_up

