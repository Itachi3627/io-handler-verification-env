class monitor;
    mailbox #(transaction) mon2scb;
    mailbox #(transaction) mon2cov;
    transaction trans;
    
    virtual intf vif; 

    function new(virtual intf vif, mailbox #(transaction) m2s, mailbox #(transaction) m2c);
        this.vif = vif;
        this.mon2cov = m2c;
        this.mon2scb = m2s;
    endfunction

    task run();
        $display("[MONITOR] Starting monitor");
        forever begin
            @(vif.mon_cb);
            trans = new();
            
            
            trans.io_addr  = vif.mon_cb.io_addr;
            trans.io_write = vif.mon_cb.io_write;
            trans.io_read  = vif.mon_cb.io_read;
            trans.io_wdata = vif.mon_cb.io_wdata;
            trans.io_in    = vif.mon_cb.io_in;
            trans.reset    = vif.mon_cb.reset;

            
            if (trans.io_write == 0 && trans.io_read == 0) begin
                continue; 
            end

            
            #1;

            
            trans.io_rdata = vif.io_rdata;
            trans.io_irq   = vif.io_irq;
            trans.io_out   = vif.io_out;
            
            mon2scb.put(trans);
            mon2cov.put(trans);
            
            $display("----------------------------------------------------------------------------------------------------------------------------------------------------------");
            $display("[Monitor] Time: %0t", $time);
            $display("[Monitor] Captured Input  Trans: io_addr=0x%0h [reg_sel=%b, port=%0d], write=%b, read=%b, io_wdata=0x%0h, reset=%b",trans.io_addr, trans.io_addr[1:0], trans.io_addr[5:2], trans.io_write, trans.io_read, trans.io_wdata, trans.reset);
            
            $display("[Monitor]   io_in  = %p", trans.io_in);
            
            $display("[Monitor] Captured Output Trans: io_rdata=0x%0h, io_irq=%b", trans.io_rdata, trans.io_irq);
            $display("[Monitor]   io_out = %p", trans.io_out);
            
            $display("[Monitor] ----- Internal Register State -----");
            for(int i = 0; i < 4; i++) begin
                $display("[Monitor] Port[%0d]: data_in=0x%0h, data_out=0x%0h, ctrl=0x%0h, status=0x%0h",
                    i,
                    vif.data_in_reg[i],   
                    vif.data_out_reg[i],
                    vif.control_reg[i],
                    vif.status_reg[i]
                );
            end
            $display("----------------------------------------------------------------------------------------------------------------------------------------------------------\n");
        end
    endtask

endclass