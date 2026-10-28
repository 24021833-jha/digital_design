`timescale 1ns/1ps

module tb_sync_fifo;

  reg        clk;
  reg        rst_n;
  reg        wr_en;
  reg  [7:0] wr_data;
  reg        rd_en;
  wire [7:0] rd_data;
  wire       rd_valid;
  wire       full;
  wire       empty;
  wire [3:0] count;

  integer errors;
  integer i;

  sync_fifo dut (
    .clk     (clk),
    .rst_n   (rst_n),
    .wr_en   (wr_en),
    .wr_data (wr_data),
    .rd_en   (rd_en),
    .rd_data (rd_data),
    .rd_valid(rd_valid),
    .full    (full),
    .empty   (empty),
    .count   (count)
  );

  initial clk = 1'b0;
  always #5 clk = ~clk;

  reg [7:0] mdl [0:7];
  integer   m_wr, m_rd, m_cnt;
  reg [7:0] exp_data;
  reg       exp_valid;
  reg       w_ok, r_ok;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      m_wr      = 0;
      m_rd      = 0;
      m_cnt     = 0;
      exp_data  = 8'h00;
      exp_valid = 1'b0;
    end else begin
      w_ok = wr_en && (m_cnt < 8);
      r_ok = rd_en && (m_cnt > 0);
      if (r_ok) begin
        exp_data = mdl[m_rd];
        m_rd     = (m_rd + 1) % 8;
      end
      exp_valid = r_ok;
      if (w_ok) begin
        mdl[m_wr] = wr_data;
        m_wr      = (m_wr + 1) % 8;
      end
      if (w_ok && !r_ok) m_cnt = m_cnt + 1;
      if (!w_ok && r_ok) m_cnt = m_cnt - 1;
    end
  end

  // Kiem tra moi chu ky o canh xuong
  always @(negedge clk) begin
    if (rd_data  !== exp_data         ||
        rd_valid !== exp_valid        ||
        count    !== m_cnt            ||
        full     !== (m_cnt == 8)     ||
        empty    !== (m_cnt == 0)) begin
      $display("[FAIL] t=%0t rd_data=%h(%h) rd_valid=%b(%b) count=%0d(%0d) full=%b empty=%b",
               $time, rd_data, exp_data, rd_valid, exp_valid, count, m_cnt, full, empty);
      errors = errors + 1;
    end
  end


  task drive;
    input       w;
    input       r;
    input [7:0] d;
    begin
      @(negedge clk);
      wr_en   = w;
      rd_en   = r;
      wr_data = d;
    end
  endtask

  task idle;
    input integer n;
    integer k;
    begin
      for (k = 0; k < n; k = k + 1) drive(1'b0, 1'b0, 8'h00);
    end
  endtask

  initial begin
    errors  = 0;
    wr_en   = 1'b0;
    rd_en   = 1'b0;
    wr_data = 8'h00;
    rst_n   = 1'b0;
    repeat (3) @(negedge clk);
    rst_n = 1'b1;
    idle(2);

    // 1. Reset, ghi 1 phan tu, doc 1 phan tu
    $display("--- Test 1: ghi/doc 1 phan tu");
    drive(1, 0, 8'h11); idle(1);
    drive(0, 1, 8'h00); idle(1);

    // 2. Ghi lien tiep den full, thu ghi vuot qua 8
    $display("--- Test 2: ghi den full va ghi tran");
    for (i = 0; i < 8; i = i + 1) drive(1, 0, 8'hA0 + i);
    idle(1);
    drive(1, 0, 8'hEE);
    drive(1, 0, 8'hEF);
    idle(1);

    // 3. Doc den empty, thu doc khi rong
    $display("--- Test 3: doc den empty va doc khi rong");
    for (i = 0; i < 8; i = i + 1) drive(0, 1, 8'h00);
    idle(1);
    drive(0, 1, 8'h00);
    drive(0, 1, 8'h00);
    idle(1);

    // 4. Ghi + doc dong thoi khi co 2 phan tu
    $display("--- Test 4: dong thoi khi co 2 phan tu");
    drive(1, 0, 8'h11);
    drive(1, 0, 8'h22);
    drive(1, 1, 8'h33);
    idle(1);
    drive(0, 1, 8'h00);
    drive(0, 1, 8'h00);
    idle(1);

    // 5. Ghi + doc dong thoi khi rong va khi day
    $display("--- Test 5: dong thoi khi rong va khi day");
    drive(1, 1, 8'h55);
    idle(1);
    drive(0, 1, 8'h00);
    idle(1);
    for (i = 0; i < 8; i = i + 1) drive(1, 0, 8'hC0 + i);
    drive(1, 1, 8'hFF);
    idle(1);
    for (i = 0; i < 8; i = i + 1) drive(0, 1, 8'h00);
    idle(1);

    // 6. Quay vong pointer
    $display("--- Test 6: quay vong pointer");
    for (i = 0; i < 40; i = i + 1) begin
      drive(1, 0, i ^ 8'h5A);
      drive(1, 1, i + 8'd100);
      drive(0, 1, 8'h00);
    end
    idle(10);

    // 7. Random
    $display("--- Test 7: random 3000 chu ky");
    for (i = 0; i < 3000; i = i + 1)
      drive($random, $random, $random);
    idle(5);

    // 8. Reset khi con du lieu
    $display("--- Test 8: reset khi con du lieu");
    drive(1, 0, 8'h77);
    drive(1, 0, 8'h88);
    @(negedge clk);
    wr_en = 1'b0;
    rd_en = 1'b0;
    #2 rst_n = 1'b0;
    #2 rst_n = 1'b1;
    idle(3);

    if (errors == 0) $display("=== TAT CA TEST DEU PASS ===");
    else             $display("=== %0d LOI ===", errors);
    $finish;
  end

endmodule