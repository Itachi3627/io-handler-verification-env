class generator;
    mailbox #(transaction) gen2drv;
    int num_transaction = 0;

    function new (mailbox #(transaction) g2d,int num_trans = 1 );
        this.gen2drv = g2d;
        this.num_transaction = num_trans;
    endfunction

    task run();
    transaction trans;
    $display("[GENERATOR] Starting generation of %0d transactions", num_transaction);
    for(int i = 1; i <= num_transaction; i++)begin
        trans = new();
        if(!trans.randomize())begin
            $error("Randomization failed!");
        end
        gen2drv.put(trans);
      
      $display("[GENERATOR] Generated Trans #%0d: io_addr[1:0]=%b, Port=%d, write=%b, read=%b, io_wdata=%h, io_in=%p", 
          i, 
          trans.io_addr[1:0], 
          trans.io_addr[5:2],
          trans.io_write, 
          trans.io_read, 
          trans.io_wdata, 
          trans.io_in  
      );
      

    end
    $display("[GENERATOR] Generation complete");
    $display("-------------------------------------------------------------------------------------------------------------------------------------------------------------------------");

    endtask
endclass