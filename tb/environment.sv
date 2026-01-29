`include "transaction.sv"
`include "generator.sv"
`include "driver.sv"
`include "monitor.sv"
`include "scoreboard.sv"
`include "coverage.sv"

class environment;

    generator gen;
    driver drv;
    monitor mon;
    scoreboard scb; 
    coverage cov; 
    
    mailbox #(transaction) gen2drv;
    mailbox #(transaction) mon2scb;
    mailbox #(transaction) mon2cov; 

    virtual intf vif;
    int num_transactions;

    function new(virtual intf vif, int num = 20);
        this.vif = vif;
        this.num_transactions = num;
        
        gen2drv = new();
        mon2scb = new();
        mon2cov = new();

        gen = new(gen2drv, num_transactions);
        drv = new(vif.DRV, gen2drv);
		mon = new(vif, mon2scb, mon2cov);
        scb = new(mon2scb);
        cov = new(mon2cov);
    endfunction

    task run();
        fork
            gen.run();
            drv.run();
            mon.run();
            scb.run();
            cov.run();
        join_any

        wait(scb.pass_count + scb.fail_count == num_transactions);
        
        #50;
        scb.report();
    endtask

endclass