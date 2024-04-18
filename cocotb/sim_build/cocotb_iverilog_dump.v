module cocotb_iverilog_dump();
initial begin
    $dumpfile("sim_build/altera_max_10.fst");
    $dumpvars(0, altera_max_10);
end
endmodule
