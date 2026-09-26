`timescale 1ns / 1ps

module tb_apb_top;

  localparam ADDR_WIDTH = 16;
  localparam DATA_WIDTH = 32;
  localparam REGS       = 1024;
  localparam WAITSTATE  = 4;

  reg                     pclk;
  reg                     presetn;
  reg                     start;
  reg                     write;
  reg  [ADDR_WIDTH-1:0]   addr;
  reg  [DATA_WIDTH-1:0]   wdata;
  wire [DATA_WIDTH-1:0]   rdata;
  wire                    done;
  wire                    resp_err;

  APB_Top #(
    .addrwidth(ADDR_WIDTH),
    .datawidth(DATA_WIDTH),
    .regs     (REGS),
    .WAITSTATE(WAITSTATE)
  ) dut (
    .pclk    (pclk),
    .presetn (presetn),
    .start   (start),
    .write   (write),
    .addr    (addr),
    .wdata   (wdata),
    .rdata   (rdata),
    .done    (done),
    .resp_err(resp_err)
  );

  // 100 MHz clock generation (Period = 10ns)
  always #5 pclk = ~pclk;
  
  task apb_write(input [ADDR_WIDTH-1:0] target_addr, input [DATA_WIDTH-1:0] data_in);
    begin
      @(posedge pclk);
      #2;
      start <= 1'b1;
      write <= 1'b1;
      addr  <= target_addr;
      wdata <= data_in;
      @(posedge pclk);
      #2;
      start <= 1'b0;
      wait(done == 1'b1);
      @(posedge pclk);
    end
  endtask

  task apb_read(input [ADDR_WIDTH-1:0] target_addr);
    begin
      @(posedge pclk);
      #2;
      start <= 1'b1;
      write <= 1'b0;
      addr  <= target_addr;
      @(posedge pclk);
      #2;
      start <= 1'b0;
      wait(done == 1'b1);
      @(posedge pclk);
    end
  endtask

  initial begin
    pclk    = 0;
    presetn = 0;
    start   = 0;
    write   = 0;
    addr    = 0;
    wdata   = 0;

    #25;
    presetn = 1; 
    #20;

    // Test 1: Write Operation to valid register (Address 2)
    $display("[T=%0t] --- Starting WRITE to Reg 2 ---", $time);
    apb_write(16'h0002, 32'hDEADBEEF);
    $display("[T=%0t] WRITE Complete! Resp_err = %b", $time, resp_err);

    #20;

    // Test 2: Read Operation from valid register (Address 2)
    $display("[T=%0t] --- Starting READ from Reg 2 ---", $time);
    apb_read(16'h0002);
    if (rdata == 32'hDEADBEEF && !resp_err)
      $display("[PASS] Read Data matched: 0x%08h", rdata);
    else
      $display("[FAIL] Read mismatch: Expected 0xDEADBEEF, got 0x%08h", rdata);

    #20;

    // Test 3: Accessing Invalid Address (1024 / 0x0400 >= REGS) to test PSLVERR
    $display("[T=%0t] --- Accessing Invalid Reg 1024 (0x0400) for PSLVERR Test ---", $time);
    apb_read(16'h0400);
    if (resp_err)
      $display("[PASS] PSLVERR triggered successfully as expected!");
    else
      $display("[FAIL] Expected error but got OKAY");

    #50;
    $display("=== All APB Subsystem Tests Completed ===");
    $finish;
  end

endmodule