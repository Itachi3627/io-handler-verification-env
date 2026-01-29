module IO_Handler #(
    parameter IO_PORTS = 4
)(
    input logic clk,
    input logic reset,

    // CPU Interface
    input logic [31:0] io_addr,       // Address for I/O access
    input logic io_write,             // CPU write enable
    input logic io_read,              // CPU read enable
    input logic [31:0] io_wdata,      // Data from CPU
    output logic [31:0] io_rdata,     // Data to CPU
    output logic io_irq,              // Interrupt to NVIC

    // External Physical I/O Lines
    input  logic [7:0] io_in  [IO_PORTS-1:0],  // Inputs from external devices
    output logic [7:0] io_out [IO_PORTS-1:0]   // Outputs to external devices
);

    // Memory-Mapped Registers
    logic [7:0] data_in_reg  [IO_PORTS-1:0];   // Stores latest input values
    logic [7:0] data_out_reg [IO_PORTS-1:0];   // Holds output values
    logic [7:0] control_reg  [IO_PORTS-1:0];   // Control bits (e.g., enable IRQ, dir)
    logic [7:0] status_reg   [IO_PORTS-1:0];   // Status bits (e.g., input ready)

    integer i;
    initial begin
        io_irq = 0;
        for(i=0; i<IO_PORTS; i=i+1) begin
            data_in_reg[i]  = 0;
            data_out_reg[i] = 0;
            control_reg[i]  = 0;
            status_reg[i]   = 0;
            io_out[i]       = 0;
        end
    end

    // --- External Input Capture ---
    always @(posedge clk) begin
        for (i=0; i<IO_PORTS; i=i+1) begin
            if (io_in[i] != data_in_reg[i]) begin
                data_in_reg[i] <= io_in[i];
                status_reg[i][0] <= 1;    // Bit0 = data ready
                if (control_reg[i][0])    // Bit0 of control = IRQ enable
                    io_irq <= 1;
            end
        end
    end

    // --- CPU Access (Memory-Mapped I/O) ---
    wire [3:0] port_sel = io_addr[5:2]; // each port has 4 registers
    wire [1:0] reg_sel  = io_addr[1:0]; // 00=DATA_IN, 01=DATA_OUT, 10=CTRL, 11=STATUS

    always @(posedge clk) begin
        if (reset) begin
            io_irq <= 0;
        end
        else begin
            if (io_write) begin
                case (reg_sel)
                    2'b01: begin data_out_reg[port_sel] <= io_wdata[7:0]; io_out[port_sel] <= io_wdata[7:0]; end
                    2'b10: control_reg[port_sel] <= io_wdata[7:0];
                    2'b11: status_reg[port_sel]  <= io_wdata[7:0]; // allow clearing status
                endcase
            end
            if (io_read) begin
                case (reg_sel)
                    2'b00: io_rdata <= {24'b0, data_in_reg[port_sel]};
                    2'b01: io_rdata <= {24'b0, data_out_reg[port_sel]};
                    2'b10: io_rdata <= {24'b0, control_reg[port_sel]};
                    2'b11: io_rdata <= {24'b0, status_reg[port_sel]};
                endcase
            end
        end
    end

    // --- Clear IRQ when CPU acknowledges ---
    always @(posedge clk) begin
        if (io_read && reg_sel==2'b11) begin
            io_irq <= 0;               // reading status clears interrupt
            status_reg[port_sel][0] <= 0;
        end
    end

endmodule