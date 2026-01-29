class coverage;

    mailbox #(transaction) mon2cov;
    transaction trans;


    covergroup cp_IO_Handler;
    option.per_instance = 1;
    option.comment = "IO_Handler Functional Coverage";

    cp_reg_sel: coverpoint trans.io_addr[1:0] {
        bins DATA_IN = {2'b00};
        bins DATA_OUT = {2'b01};
        bins CTRL = {2'b10};
        bins STATUS = {2'b11};
    }

    cp_port_sel: coverpoint trans.io_addr[5:2] {
        bins valid_ports[] = {4'h0, 4'h1, 4'h2, 4'h3};
        bins invalid_ports = {[4'h4:4'hF]};
    }

    cp_io_read: coverpoint trans.io_read {
        bins inactive = {1'b0};
        bins active = {1'b1};
    }

    cp_io_write: coverpoint trans.io_write {
        bins inactive = {1'b0};
        bins active = {1'b1};
    }

    cp_wdata: coverpoint trans.io_wdata[7:0] {
        bins zero = {8'h00};
        bins max = {8'hFF};
        bins corners[] = {8'h01, 8'h7F, 8'h80, 8'hFE};
        bins others = default;
    }

    cp_irq: coverpoint trans.io_irq {
        bins clear = {1'b0};
        bins set = {1'b1};
    }

    cp_io_in_0: coverpoint trans.io_in[0] {
        bins zero = {8'h00};
        bins max = {8'hFF};
        bins mid = {[8'h01:8'hFE]};
    }

    cp_io_in_1: coverpoint trans.io_in[1] {
        bins zero = {8'h00};
        bins max = {8'hFF};
        bins mid = {[8'h01:8'hFE]};
    }

    cp_io_in_2: coverpoint trans.io_in[2] {
        bins zero = {8'h00};
        bins max = {8'hFF};
        bins mid = {[8'h01:8'hFE]};
    }

    cp_io_in_3: coverpoint trans.io_in[3] {
        bins zero = {8'h00};
        bins max = {8'hFF};
        bins mid = {[8'h01:8'hFE]};
    }
    

    cross_read_ops: cross cp_io_read, cp_reg_sel, cp_port_sel {
        ignore_bins not_reading = !binsof(cp_io_read.active);
        ignore_bins invalid_read = binsof(cp_port_sel.invalid_ports);
    }

    cross_write_ops: cross cp_io_write, cp_reg_sel, cp_port_sel {
        ignore_bins not_writing = !binsof(cp_io_write.active);
        ignore_bins invalid_write = binsof(cp_port_sel.invalid_ports);
        ignore_bins write_data_in = binsof(cp_reg_sel.DATA_IN); // Can't write DATA_IN
    }

    cross_irq_gen: cross cp_irq, cp_reg_sel {
        bins irq_on_status = binsof(cp_irq.set) && binsof(cp_reg_sel.STATUS);
    }

endgroup


    function new(mailbox #(transaction) m2c);
        this.mon2cov = m2c;
        cp_IO_Handler  = new(); 
    endfunction

    task run();
      $display("[COVERAGE] Starting coverage sampling");
        forever begin
            mon2cov.get(trans);      
            cp_IO_Handler.sample();
            $display("[COVERAGE] Current Coverage: %.2f%%", cp_IO_Handler.get_inst_coverage());
        end
    endtask

endclass