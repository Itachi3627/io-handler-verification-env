// Code your testbench here
// or browse Examples
`include "interface.sv"
`include "environment.sv"
module tb;
    logic clk = 0;
    always #5 clk = ~clk;
  
  
    intf intf_inst(clk); 
    environment env;
    IO_Handler #(4) dut (
        .clk(clk),
        .reset(intf_inst.reset),
        .io_addr(intf_inst.io_addr),
        .io_write(intf_inst.io_write),
        .io_read(intf_inst.io_read),
        .io_wdata(intf_inst.io_wdata),
        .io_rdata(intf_inst.io_rdata),
        .io_irq(intf_inst.io_irq),
        .io_in(intf_inst.io_in),
        .io_out(intf_inst.io_out)
    );
    
    assign intf_inst.data_in_reg = dut.data_in_reg;
    assign intf_inst.data_out_reg = dut.data_out_reg;
    assign intf_inst.control_reg = dut.control_reg;
    assign intf_inst.status_reg = dut.status_reg;
    
    initial begin
      env = new(intf_inst, 200);
        env.run();
        $finish;
    end
  
  initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb);
    end
  
endmodule