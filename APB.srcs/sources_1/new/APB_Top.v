`timescale 1ns/1ps

module APB_Top #(
  parameter addrwidth = 16,
  parameter datawidth = 32,
  parameter regs      = 1024,
  parameter WAITSTATE = 4
)(
  input  wire                 pclk,
  input  wire                 presetn,

  input  wire                 start,
  input  wire                 write,
  input  wire [addrwidth-1:0] addr,
  input  wire [datawidth-1:0] wdata,
  output wire [datawidth-1:0] rdata,
  output wire                 done,
  output wire                 resp_err
);

  wire [addrwidth-1:0] paddr;
  wire                 psel;
  wire                 penable;
  wire                 pwrite;
  wire [datawidth-1:0] pwdata;
  wire [datawidth-1:0] prdata;
  wire                 pready;
  wire                 pslverr;

  APB_Master #(
    .addrwidth(addrwidth),
    .datawidth(datawidth)
  ) Master_inst (
    .pclk    (pclk),
    .presetn (presetn),
    .start   (start),
    .write   (write),
    .addr    (addr),
    .wdata   (wdata),
    .rdata   (rdata),
    .done    (done),
    .resp_err(resp_err),
    .paddr   (paddr),
    .psel    (psel),
    .penable (penable),
    .pwrite  (pwrite),
    .pwdata  (pwdata),
    .prdata  (prdata),
    .pready  (pready),
    .pslverr (pslverr)
  );

  APB_Slave #(
    .addrwidth(addrwidth),
    .datawidth(datawidth),
    .regs     (regs),
    .WAITSTATE(WAITSTATE)
  ) Slave_inst (
    .pclk    (pclk),
    .presetn (presetn),
    .paddr   (paddr),
    .pwrite  (pwrite),
    .pwdata  (pwdata),
    .psel    (psel),
    .penable (penable),
    .prdata  (prdata),
    .pready  (pready),
    .pslverr (pslverr)
  );

endmodule