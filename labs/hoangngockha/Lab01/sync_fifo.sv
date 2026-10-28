
module sync_fifo (
  input  logic       clk,
  input  logic       rst_n,
  input  logic       wr_en,
  input  logic [7:0] wr_data,
  input  logic       rd_en,
  output logic [7:0] rd_data,
  output logic       rd_valid,
  output logic       full,
  output logic       empty,
  output logic [3:0] count
);

  logic [7:0] mem [0:7];
  logic [2:0] wr_ptr, rd_ptr;  

  assign full  = (count == 4'd8);
  assign empty = (count == 4'd0);

  
  logic wr_ok, rd_ok;
  assign wr_ok = wr_en && !full;
  assign rd_ok = rd_en && !empty;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr   <= 3'd0;
      rd_ptr   <= 3'd0;
      count    <= 4'd0;
      rd_data  <= 8'h00;
      rd_valid <= 1'b0;
    end else begin
      rd_valid <= rd_ok;                 

      if (wr_ok) begin
        mem[wr_ptr] <= wr_data;
        wr_ptr      <= wr_ptr + 3'd1;
      end

      if (rd_ok) begin
        rd_data <= mem[rd_ptr];          
        rd_ptr  <= rd_ptr + 3'd1;
      end

      case ({wr_ok, rd_ok})
        2'b10:   count <= count + 4'd1;
        2'b01:   count <= count - 4'd1;
        default: count <= count;         
      endcase
    end
  end

endmodule