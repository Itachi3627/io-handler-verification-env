class driver;
    mailbox #(transaction) gen2drv;
    virtual intf.DRV vif;
    transaction trans;

    function new(virtual intf.DRV vif, mailbox #(transaction) g2d);
        this.vif = vif;
        this.gen2drv = g2d;
    endfunction

    task run();
        $display("[DRIVER] Starting driver");
        forever begin
            gen2drv.get(trans);
            
            vif.drv_cb.io_addr <= trans.io_addr;
            vif.drv_cb.io_write <= trans.io_write;
            vif.drv_cb.io_read <= trans.io_read;
            vif.drv_cb.io_wdata <= trans.io_wdata;  
            vif.drv_cb.io_in <= trans.io_in;
            
            @(vif.drv_cb);
            
            
            vif.drv_cb.io_write <= 0;
            vif.drv_cb.io_read  <= 0;
        end
    endtask
endclass