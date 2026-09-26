`timescale 1ns / 1ps

module APB_Master #(
  parameter addrwidth = 16,
  parameter datawidth = 32
)(
  input  wire                 pclk,
  input  wire                 presetn,

  input  wire                 start,
  input  wire                 write,
  input  wire [addrwidth-1:0] addr,
  input  wire [datawidth-1:0] wdata,
  output reg  [datawidth-1:0] rdata,
  output reg                  done,
  output reg                  resp_err,

  output reg  [addrwidth-1:0] paddr,
  output reg                  psel,
  output reg                  penable,
  output reg                  pwrite,
  output reg  [datawidth-1:0] pwdata,
  input  wire [datawidth-1:0] prdata,
  input  wire                 pready,
  input  wire                 pslverr
);

  localparam IDLE   = 2'b00,
             SETUP  = 2'b01,
             ACCESS = 2'b10;

  reg [1:0] state, next_state;

  always @(*) begin
    case (state)
      IDLE:   next_state = start ? SETUP : IDLE;
      SETUP:  next_state = ACCESS;
      ACCESS: next_state = pready ? (start ? SETUP : IDLE) : ACCESS;
      default: next_state = IDLE;
    endcase
  end

  always @(posedge pclk or negedge presetn) begin
    if (!presetn)
      state <= IDLE;
    else
      state <= next_state;
  end

  always @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      psel     <= 1'b0;
      penable  <= 1'b0;
      paddr    <= {addrwidth{1'b0}};
      pwrite   <= 1'b0;
      pwdata   <= {datawidth{1'b0}};
      rdata    <= {datawidth{1'b0}};
      done     <= 1'b0;
      resp_err <= 1'b0;
    end else begin
      case (state)
        IDLE: begin
          psel     <= 1'b0;
          penable  <= 1'b0;
          done     <= 1'b0;
        end

        SETUP: begin
          psel     <= 1'b1;
          penable  <= 1'b0;
          paddr    <= addr;
          pwrite   <= write;
          done     <= 1'b0;
          resp_err <= 1'b0;
          if (write)
            pwdata <= wdata;
        end

        ACCESS: begin
           psel    <= 1'b1;
           penable <= 1'b1;
           if (pready) begin
               done <= 1'b1;
            if (pslverr) begin
                resp_err <= 1'b1;       
            end else begin
                resp_err <= 1'b0;
                if (!pwrite)
                rdata <= prdata;
            end
         end else begin
            done <= 1'b0;
            end
        end

        default: begin
          psel    <= 1'b0;
          penable <= 1'b0;
          done    <= 1'b0;
        end
      endcase
    end
  end

endmodule