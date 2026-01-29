class scoreboard;
    mailbox #(transaction) mon2scb;
    transaction trans; 

    logic [7:0] ref_data_in_reg [3:0];
    logic [7:0] ref_data_out_reg [3:0];
    logic [7:0] ref_control_reg [3:0];
    logic [7:0] ref_status_reg [3:0];
    logic [31:0] expected_rdata;
    logic ref_io_irq;

    int pass_count = 0;
    int fail_count = 0;
    int total_count = 0;

    function new(mailbox #(transaction) m2s);
        this.mon2scb = m2s;
        for(int i = 0; i < 4; i++) begin
            ref_data_in_reg[i]  = 8'h00;
            ref_data_out_reg[i] = 8'h00;
            ref_control_reg[i]  = 8'h00;
            ref_status_reg[i]   = 8'h00;
        end
        ref_io_irq = 0;
    endfunction

    task reference_model(transaction trans);
        logic [3:0] port_sel;
        logic [1:0] reg_sel;
        bit irq_clear_pending; 

        port_sel = trans.io_addr[5:2];
        reg_sel  = trans.io_addr[1:0];
        irq_clear_pending = 0;

      
        if (trans.io_read) begin
            if (port_sel < 4) begin
                case (reg_sel)
                    2'b00: expected_rdata = {24'b0, ref_data_in_reg[port_sel]};
                    2'b01: expected_rdata = {24'b0, ref_data_out_reg[port_sel]};
                    2'b10: expected_rdata = {24'b0, ref_control_reg[port_sel]};
                    2'b11: expected_rdata = {24'b0, ref_status_reg[port_sel]};
                endcase
            end else begin
                expected_rdata = {24'b0, 8'bx}; 
            end

            
            if (reg_sel == 2'b11) begin
                irq_clear_pending = 1;
                if (port_sel < 4) begin
                    ref_status_reg[port_sel][0] = 1'b0; 
                end
            end
        end

      
        for (int i=0; i<4; i=i+1) begin
            if (trans.io_in[i] != ref_data_in_reg[i]) begin
                ref_data_in_reg[i] = trans.io_in[i];
                ref_status_reg[i][0] = 1; // This might "undo" the bit clear from Step 1
                
                // Set IRQ if enabled
                if (ref_control_reg[i][0]) ref_io_irq = 1;
            end
        end

        
        if (irq_clear_pending) begin
            ref_io_irq = 0;
            
            if (port_sel < 4) begin
                ref_status_reg[port_sel][0] = 0; 
            end
        end
    endtask

    task update_write(transaction trans);
        logic [3:0] port_sel;
        logic [1:0] reg_sel;

        port_sel = trans.io_addr[5:2];
        reg_sel  = trans.io_addr[1:0];

        if(trans.io_write && port_sel < 4) begin
            case (reg_sel)
                2'b01: ref_data_out_reg[port_sel] = trans.io_wdata[7:0];
                2'b10: ref_control_reg[port_sel] = trans.io_wdata[7:0];
                2'b11: ref_status_reg[port_sel]  = trans.io_wdata[7:0]; 
            endcase
        end 
    endtask

    task compare(transaction trans);
        bit error = 0;

        if(trans.reset) return;

        total_count++;
        
        if (trans.io_read) begin
            if (trans.io_rdata !== expected_rdata) begin
                $display("[SCOREBOARD]  FAIL: io_rdata mismatch!");
                $display("             Expected: 0x%h, Got: 0x%h", expected_rdata, trans.io_rdata);
                error = 1;
            end else begin
                $display("[SCOREBOARD]  PASS: io_rdata = 0x%h", trans.io_rdata);
            end
        end

        if (trans.io_irq !== ref_io_irq) begin
            $display("[SCOREBOARD]  FAIL: io_irq mismatch!");
            $display("             Expected: %b, Got: %b", ref_io_irq, trans.io_irq);
            error = 1;
        end else begin
            $display("[SCOREBOARD] PASS: io_irq = %b", trans.io_irq);
        end

        for(int i = 0; i < 4; i++) begin
            if (trans.io_out[i] !== ref_data_out_reg[i]) begin
                $display("[SCOREBOARD] FAIL: io_out[%0d] mismatch!", i);
                $display("             Expected: 0x%h, Got: 0x%h", ref_data_out_reg[i], trans.io_out[i]);
                error = 1;
            end else begin
                $display("[SCOREBOARD] PASS: io_out[%0d] = 0x%h", i, trans.io_out[i]);
            end
        end

        if (error) begin
            $display("\n[SCOREBOARD] ----- Internal Register State (Reference) -----");
            for(int i = 0; i < 4; i++) begin
                $display("[SCOREBOARD] Port[%0d]:", i);
                $display("             REF: data_in=0x%h, data_out=0x%h, ctrl=0x%h, status=0x%h",
                         ref_data_in_reg[i], ref_data_out_reg[i], ref_control_reg[i], ref_status_reg[i]);
            end
            fail_count++;
            $display("[SCOREBOARD]  Transaction FAILED ");
        end else begin
            pass_count++;
            $display("[SCOREBOARD]  Transaction PASSED ");
        end
        
        $display("[SCOREBOARD] Score: Pass=%0d, Fail=%0d, Total=%0d", pass_count, fail_count, total_count);
        $display("[SCOREBOARD] ====================================================================\n");
    endtask

    task run();
        $display("[SCOREBOARD] Starting scoreboard");
        forever begin
            mon2scb.get(trans);
            reference_model(trans);
            update_write(trans);
            compare(trans);
        end
    endtask

    function void report();
        $display("\n");
        $display("                      SCOREBOARD FINAL REPORT                     ");
        $display("Total Transactions : %0d", total_count);
        $display("Passed             : %0d", pass_count);
        $display("Failed             : %0d", fail_count);
        if (total_count > 0) begin
            $display("Pass Rate          : %.2f%%", (pass_count * 100.0) / total_count);
        end
        $display("========================================================================");
        if (fail_count == 0 && total_count > 0) begin
            $display("ALL TESTS PASSED");
        end else begin
            $display("SOME TESTS FAILED");
        end
        $display("========================================================================\n");
    endfunction

endclass