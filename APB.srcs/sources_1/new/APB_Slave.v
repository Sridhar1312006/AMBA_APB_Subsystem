`timescale 1ns / 1ps

module APB_Slave #(
  parameter addrwidth = 16,
  parameter datawidth = 32,
  parameter regs      = 1024,
  parameter WAITSTATE = 4
)(
  input  wire                  pclk,
  input  wire                  presetn,
  input  wire [addrwidth-1:0]  paddr,
  input  wire                  pwrite,
  input  wire [datawidth-1:0]  pwdata,
  input  wire                  psel,
  input  wire                  penable,
  output reg  [datawidth-1:0]  prdata,
  output reg                   pready,
  output reg                   pslverr
);

  reg [datawidth-1:0] registers [0:regs-1];
  localparam cnt = (WAITSTATE > 0) ? $clog2(WAITSTATE + 1) : 1;
  reg [cnt - 1:0] wait_counter; 
  integer i;

  localparam IDLE   = 2'b00,
             SETUP  = 2'b01,
             ACCESS = 2'b10;

  reg [1:0] state, next_state;  

  always @(*) begin
    case (state)
      IDLE:   next_state = (psel) ? SETUP : IDLE;
      SETUP:  next_state = (penable) ? ACCESS : SETUP;
      ACCESS: next_state = (!pready) ? ACCESS : ((psel && !penable) ? SETUP : IDLE);
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
      pready       <= 1'b0;
      pslverr      <= 1'b0;
      wait_counter <= {cnt{1'b0}};
      prdata       <= {datawidth{1'b0}};

    end else begin
      case (state)
        SETUP: begin
          pready       <= 1'b0;
          pslverr      <= 1'b0;
          wait_counter <= {cnt{1'b0}};
        end

        ACCESS: begin
          if (wait_counter < WAITSTATE) begin
            wait_counter <= wait_counter + 1'b1;
            pready       <= 1'b0;
            pslverr      <= 1'b0;
          end else begin
            pready       <= 1'b1;
            wait_counter <= {cnt{1'b0}};

            if (paddr < regs) begin
              pslverr <= 1'b0;
              if (pwrite)
                registers[paddr] <= pwdata;
              else
                prdata <= registers[paddr];
            end else begin
              pslverr <= 1'b1;
              prdata  <= {datawidth{1'b0}};
            end
          end
        end

        default: begin
          pready       <= 1'b0;
          pslverr      <= 1'b0;
          wait_counter <= {cnt{1'b0}};
        end
      endcase
    end
  end

endmodule