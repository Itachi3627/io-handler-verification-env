interface intf #(parameter IO_PORTS = 4) (input logic clk);
    logic reset;
    logic [31:0] io_addr;
    logic io_write;
    logic io_read;
    logic [31:0] io_wdata;
    logic [31:0] io_rdata;
    logic io_irq;
    logic [7:0] io_in [IO_PORTS-1:0];
    logic [7:0] io_out [IO_PORTS-1:0];

    logic [7:0] data_in_reg [IO_PORTS-1:0];
    logic [7:0] data_out_reg [IO_PORTS-1:0];
    logic [7:0] control_reg [IO_PORTS-1:0];
    logic [7:0] status_reg [IO_PORTS-1:0];

    clocking drv_cb @(posedge clk);
        default input #1ns output #1ns;
        output io_addr, io_write, io_read, io_wdata;
        output io_in;
        output reset;
        input  io_rdata, io_irq;
        input  io_out;
    endclocking

    clocking mon_cb @(posedge clk);
        default input #1ns;
        input io_addr, io_write, io_read, io_wdata;
        input io_in;
        input reset;
        input io_rdata, io_irq;
        input io_out;
        input data_in_reg, data_out_reg, control_reg, status_reg;
    endclocking

    modport DRV(clocking drv_cb);
    modport MON(clocking mon_cb);
    
endinterface