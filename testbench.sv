`include "environment_new.sv"
/////////////////////////////////////////////////////////
// Call scoreboard from Monitor using callbacks
/////////////////////////////////////////////////////////
class Request extends CPU_Instr;
    constraint request{ sys__mc__req == 1;
	                input_fifo_read == 1;
	              };
endclass

program automatic test
    #(parameter int NumBnc = 32)
    (dec_ifc.TB_Dec2Bnc Dec2Bnc[0: NumBnc - 1],
     cpu_ifc.TB_Sys2Dec Sys2Dec,
     input logic reset);

    Environment env;

    initial begin
	env = new (Dec2Bnc, Sys2Dec, NumBnc);
//	env.gen_cfg();
	env.build();
	begin
	    Request rq;
	    rq = new();
	    env.gen.blueprint = rq;
	end
	env.run();
	env.wrap_up();
    end
endprogram // test
