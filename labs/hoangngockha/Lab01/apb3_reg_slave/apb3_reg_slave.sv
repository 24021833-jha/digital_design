
module apb3_reg_slave (
  input  logic        PCLK,
  input  logic        PRESETn,
  input  logic        PSEL,
  input  logic        PENABLE,
  input  logic        PWRITE,
  input  logic [7:0]  PADDR,
  input  logic [31:0] PWDATA,
  output logic [31:0] PRDATA,
  output logic        PREADY,
  output logic        PSLVERR
);

  localparam logic [7:0] ADDR_CONTROL = 8'h00;
  localparam logic [7:0] ADDR_DATA    = 8'h04;
  localparam logic [7:0] ADDR_STATUS  = 8'h08;

  
  logic        control_en;   
  logic [31:0] data_reg;    

  
  logic [31:0] status_val;
  assign status_val = {30'b0, control_en, 1'b1};

 
  assign PREADY = 1'b1;

  
  logic access;
  assign access = PSEL && PENABLE;

  
  logic addr_valid;
  assign addr_valid = (PADDR == ADDR_CONTROL) ||
                      (PADDR == ADDR_DATA)    ||
                      (PADDR == ADDR_STATUS);

  
  assign PSLVERR = access && (!addr_valid || (PWRITE && (PADDR == ADDR_STATUS)));

  
  always_ff @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
      control_en <= 1'b0;
      data_reg   <= 32'h0;
    end else if (access && PREADY && PWRITE && addr_valid) begin
      case (PADDR)
        ADDR_CONTROL: control_en <= PWDATA[0];  
        ADDR_DATA:    data_reg   <= PWDATA;    
        default: ;                             
      endcase
    end
  end

  
  always_comb begin
    PRDATA = 32'h0;
    if (access && !PWRITE) begin
      case (PADDR)
        ADDR_CONTROL: PRDATA = {31'b0, control_en};
        ADDR_DATA:    PRDATA = data_reg;
        ADDR_STATUS:  PRDATA = status_val;
        default:      PRDATA = 32'h0;
      endcase
    end
  end

endmodule