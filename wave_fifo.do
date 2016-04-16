
add wave -noupdate -radix hexadecimal /top/mc_decoder/clk
add wave -noupdate -radix hexadecimal /top/mc_decoder/reset
add wave -noupdate -expand -group {System Interface} -radix hexadecimal /top/mc_decoder/sys__mc__dram_req
add wave -noupdate -expand -group {System Interface} -radix hexadecimal /top/mc_decoder/sys__mc__dram_addr
add wave -noupdate -expand -group {System Interface} -radix hexadecimal /top/mc_decoder/sys__mc__dram_rdwr
add wave -noupdate -expand -group {System Interface} -radix hexadecimal /top/mc_decoder/sys__mc__dram_wr_data
add wave -noupdate -expand -group {System Interface} -radix hexadecimal /top/mc_decoder/input_fifo_read_rdwr
add wave -noupdate -expand -group {System Interface} -radix hexadecimal /top/mc_decoder/input_fifo_read_addr
add wave -noupdate -expand -group {System Interface} -radix hexadecimal /top/mc_decoder/input_fifo_read_wr_data
add wave -noupdate -expand -group {System Interface} -radix hexadecimal /top/mc_decoder/input_fifo_empty
add wave -noupdate -expand -group {System Interface} -radix hexadecimal /top/mc_decoder/mc__sys__dram_busy



add wave -noupdate -expand -group {System FIFO} -radix hexadecimal {/top/mc_decoder/from_system_fifo[0]/reset}
add wave -noupdate -expand -group {System FIFO} -radix hexadecimal {/top/mc_decoder/from_system_fifo[0]/clear}
add wave -noupdate -expand -group {System FIFO} -radix hexadecimal {/top/mc_decoder/from_system_fifo[0]/addr}
add wave -noupdate -expand -group {System FIFO} -radix hexadecimal {/top/mc_decoder/from_system_fifo[0]/rdwr}
add wave -noupdate -expand -group {System FIFO} -radix hexadecimal {/top/mc_decoder/from_system_fifo[0]/wr_data}
add wave -noupdate -expand -group {System FIFO} -radix hexadecimal {/top/mc_decoder/from_system_fifo[0]/fifo_rdwr}
add wave -noupdate -expand -group {System FIFO} -radix hexadecimal {/top/mc_decoder/from_system_fifo[0]/fifo_addr}
add wave -noupdate -expand -group {System FIFO} -radix hexadecimal {/top/mc_decoder/from_system_fifo[0]/fifo_wr_data}
add wave -noupdate -expand -group {System FIFO} -radix hexadecimal {/top/mc_decoder/from_system_fifo[0]/fifo_read_addr}
add wave -noupdate -expand -group {System FIFO} -radix hexadecimal {/top/mc_decoder/from_system_fifo[0]/fifo_read_rdwr}
add wave -noupdate -expand -group {System FIFO} -radix hexadecimal {/top/mc_decoder/from_system_fifo[0]/fifo_read_wr_data}
add wave -noupdate -expand -group {System FIFO} -radix hexadecimal {/top/mc_decoder/from_system_fifo[0]/fifo_write}
add wave -noupdate -expand -group {System FIFO} -radix hexadecimal {/top/mc_decoder/from_system_fifo[0]/fifo_read}
add wave -noupdate -expand -group {System FIFO} -radix hexadecimal {/top/mc_decoder/from_system_fifo[0]/fifo_wp}
add wave -noupdate -expand -group {System FIFO} -radix hexadecimal {/top/mc_decoder/from_system_fifo[0]/fifo_rp}
add wave -noupdate -expand -group {System FIFO} -radix hexadecimal {/top/mc_decoder/from_system_fifo[0]/fifo_almost_full}
add wave -noupdate -expand -group {System FIFO} -radix hexadecimal {/top/mc_decoder/from_system_fifo[0]/fifo_empty}
add wave -noupdate -expand -group {System FIFO} -radix hexadecimal {/top/mc_decoder/from_system_fifo[0]/fifo_depth}
