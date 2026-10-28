`timescale 1ns/1ps

module tb_apb3_reg_slave;

  logic        PCLK = 0, PRESETn;
  logic        PSEL, PENABLE, PWRITE;
  logic [7:0]  PADDR;
  logic [31:0] PWDATA, PRDATA;
  logic        PREADY, PSLVERR;

  int errors = 0;

  apb3_reg_slave dut (.*);

  always #5 PCLK = ~PCLK;

  
  task automatic apb_write(input logic [7:0] addr, input logic [31:0] data,
                           output logic err);
    @(posedge PCLK); #1;                     
    PSEL = 1; PENABLE = 0; PWRITE = 1; PADDR = addr; PWDATA = data;
    @(posedge PCLK); #1;                      
    PENABLE = 1;
    @(negedge PCLK);                          
    err = PSLVERR;
    @(posedge PCLK); #1;                    
    PSEL = 0; PENABLE = 0; PWRITE = 0; PADDR = 'x; PWDATA = 'x;
  endtask

  task automatic apb_read(input logic [7:0] addr, output logic [31:0] data,
                          output logic err);
    @(posedge PCLK); #1;                     
    PSEL = 1; PENABLE = 0; PWRITE = 0; PADDR = addr; PWDATA = 'x;
    @(posedge PCLK); #1;                   
    PENABLE = 1;
    @(negedge PCLK);
    data = PRDATA;
    err  = PSLVERR;
    @(posedge PCLK); #1;                    
    PSEL = 0; PENABLE = 0; PADDR = 'x;
  endtask

  task automatic check(input string name, input logic [31:0] got,
                       input logic [31:0] exp);
    if (got !== exp) begin
      $display("[FAIL] %s: got=0x%08h exp=0x%08h", name, got, exp);
      errors++;
    end else
      $display("[PASS] %s = 0x%08h", name, got);
  endtask

  logic [31:0] rd;
  logic        e;

  initial begin
    PSEL = 0; PENABLE = 0; PWRITE = 0; PADDR = '0; PWDATA = '0;
    PRESETn = 0;
    repeat (3) @(posedge PCLK);
    #1 PRESETn = 1;

    apb_read(8'h00, rd, e); check("reset CONTROL", rd, 32'h0);        check("err", e, 0);
    apb_read(8'h04, rd, e); check("reset DATA",    rd, 32'h0);        check("err", e, 0);
    apb_read(8'h08, rd, e); check("reset STATUS",  rd, 32'h1);        check("err", e, 0);

    apb_write(8'h00, 32'h1, e); check("err", e, 0);
    apb_read (8'h00, rd, e);    check("CONTROL", rd, 32'h1);
    apb_read (8'h08, rd, e);    check("STATUS",  rd, 32'h3);

    apb_write(8'h00, 32'hFFFF_FFFE, e);
    apb_read (8'h00, rd, e);    check("CONTROL bit0 only", rd, 32'h0);
    apb_write(8'h00, 32'hFFFF_FFFF, e);
    apb_read (8'h00, rd, e);    check("CONTROL bit0 only", rd, 32'h1);

    apb_write(8'h04, 32'hDEAD_BEEF, e); check("err", e, 0);
    apb_read (8'h04, rd, e);            check("DATA", rd, 32'hDEAD_BEEF);

    apb_write(8'h08, 32'hFFFF_FFFF, e); check("STATUS write PSLVERR", e, 1);
    apb_read (8'h08, rd, e);            check("STATUS unchanged", rd, 32'h3);
    apb_read (8'h04, rd, e);            check("DATA unchanged", rd, 32'hDEAD_BEEF);

    
    apb_read (8'h0C, rd, e); check("read 0x0C PSLVERR", e, 1); check("PRDATA", rd, 0);
    apb_read (8'h01, rd, e); check("read 0x01 PSLVERR", e, 1);
    apb_write(8'h0C, 32'h1234, e); check("write 0x0C PSLVERR", e, 1);
    apb_write(8'h01, 32'h1234, e); check("write 0x01 PSLVERR", e, 1);
    apb_read (8'h04, rd, e);       check("DATA unchanged", rd, 32'hDEAD_BEEF);


    @(posedge PCLK); #1;
    PSEL = 1; PENABLE = 0; PWRITE = 1; PADDR = 8'h04; PWDATA = 32'hCAFE_F00D;
    @(posedge PCLK); #1;
    PSEL = 0; PWRITE = 0; PADDR = 'x; PWDATA = 'x;
    apb_read(8'h04, rd, e); check("DATA after SETUP-only", rd, 32'hDEAD_BEEF);

    
    @(negedge PCLK); check("PRDATA idle", PRDATA, 32'h0);

 
    #1 PRESETn = 0; #2 PRESETn = 1;
    apb_read(8'h04, rd, e); check("DATA after reset", rd, 32'h0);
    apb_read(8'h08, rd, e); check("STATUS after reset", rd, 32'h1);

    if (errors == 0) $display("=== TAT CA TEST DEU PASS ===");
    else             $display("=== %0d LOI ===", errors);
    $finish;
  end

endmodule