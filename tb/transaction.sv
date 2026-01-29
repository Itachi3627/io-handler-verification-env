class transaction;
    rand logic [31:0] io_addr;
    rand logic io_write;
    rand logic io_read;
    rand logic [31:0] io_wdata;
    rand logic [7:0] io_in [3:0];
    
    
    rand logic reset;
    
    logic [31:0] io_rdata;
    logic io_irq;
    logic [7:0] io_out [3:0];
    
    constraint addr_c {
        
        reset == 1'b0;
        
        io_addr[1:0] dist {
            2'b00 := 25,
            2'b01 := 25,
            2'b10 := 25,
            2'b11 := 25
        };
        
        io_addr[5:2] dist {
            4'h0 := 22,
            4'h1 := 23,
            4'h2 := 23,
            4'h3 := 22,
            [4'h4:4'hF] :/ 10
        };
        
        io_addr[31:6] inside {[26'h0000000:26'h1000000]};
    }
    
    constraint rw_c {
        io_write != io_read;
        io_write dist {0:=50, 1:=50};
        io_read dist {0:=50, 1:=50};
    }
endclass