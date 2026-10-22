# LAB 01 — RTL Design & Basic On-Chip Bus Interfaces

**Ngôn ngữ:** SystemVerilog (`.sv`)  
**Mục tiêu:** luyện RTL có thể tổng hợp, thiết kế khối điều khiển theo clock, tạo testbench kiểm thử chức năng và đọc timing của giao tiếp bus.

## Quy định chung

- Lab có **3 bài độc lập**, sắp xếp từ dễ đến khó. **Giảng viên quyết định số bài mỗi sinh viên phải làm**.
- Thiết kế chạy bằng clock cạnh lên; reset bất đồng bộ active-low (`rst_n`, `PRESETn`, `HRESETn`).
- Không sử dụng `#delay`, `$display`, `$finish`, `initial` trong **RTL thiết kế**. Các lệnh này chỉ được phép trong **testbench**.
- Sử dụng `always_ff` cho sequential logic, `always_comb` / `assign` cho combinational logic; dùng nonblocking `<=` cho thanh ghi.
- Bổ sung các test case ngoài testbench mẫu. Testbench mẫu **không bao phủ mọi trường hợp**.
- Bài nộp: file RTL, file testbench, `report.md` (mô tả kiến trúc, test cases, kết quả mô phỏng).
- Những file trong `starter/rtl` là **khung giao diện, không phải lời giải**. Testbench sẽ báo FAIL cho tới khi cài đặt xong.

---

## Bài 1 — Thiết kế Synchronous FIFO (cơ bản)

### Bối cảnh

Hai khối xử lý làm việc trên **cùng một clock**. Khối A đưa dữ liệu 8-bit vào FIFO; khối B lấy dữ liệu ra theo thứ tự **First-In, First-Out**. Thiết kế FIFO dung lượng **8 phần tử**.

### Giao diện bắt buộc

| Tín hiệu | Hướng | Rộng | Mô tả |
| --- | --- | ---: | --- |
| `clk` | input | 1 | Clock cạnh lên |
| `rst_n` | input | 1 | Reset bất đồng bộ, active-low |
| `wr_en` | input | 1 | Yêu cầu ghi 1 phần tử |
| `wr_data` | input | 8 | Dữ liệu đầu vào |
| `rd_en` | input | 1 | Yêu cầu đọc 1 phần tử |
| `rd_data` | output | 8 | Dữ liệu đọc được, giữ nguyên nếu không có đọc hợp lệ |
| `rd_valid` | output | 1 | Xung HIGH 1 chu kỳ khi đọc thành công |
| `full` | output | 1 | FIFO đang đầy |
| `empty` | output | 1 | FIFO đang rỗng |
| `count` | output | 4 | Số phần tử hiện có, từ 0 đến 8 |

### Yêu cầu chức năng

1. Lưu trữ bằng `logic [7:0] mem [0:7]` (hoặc cấu trúc tương đương), read pointer và write pointer dạng vòng.
2. **Ghi hợp lệ:** tại cạnh lên, nếu `wr_en=1` và FIFO **chưa đầy trước cạnh clock** thì ghi `wr_data`, tăng write pointer và `count`.
3. **Đọc hợp lệ:** tại cạnh lên, nếu `rd_en=1` và FIFO **không rỗng trước cạnh clock** thì đưa phần tử đầu ra `rd_data`, tăng read pointer, bật `rd_valid` trong chu kỳ đó.
4. Ghi khi `full=1` hoặc đọc khi `empty=1` phải **bị bỏ qua**, không mất dữ liệu đã có.
5. Nếu cùng lúc ghi và đọc đều hợp lệ, `count` không đổi; dữ liệu được đọc là phần tử **cũ nhất**.
6. Nếu `wr_en=rd_en=1` tại trạng thái **rỗng**, chỉ ghi được (đọc bị bỏ qua); nếu ở trạng thái **đầy**, chỉ đọc được (ghi bị bỏ qua). Tất cả điều kiện kiểm tra dựa trên `full/empty` **trước cạnh clock**.
7. Reset: `count=0`, `empty=1`, `full=0`, `rd_valid=0`, `rd_data=0`; reset hai pointer về 0.

### Ví dụ hoạt động

```text
Sau reset:               FIFO = []                   count = 0
Ghi 0x11:                FIFO = [11]                 count = 1
Ghi 0x22:                FIFO = [11, 22]             count = 2
Đọc:                     rd_data=11, FIFO=[22]       count = 1
Đồng thời ghi 33 / đọc:  rd_data=22, FIFO=[33]       count = 1
Đọc:                     rd_data=33, FIFO=[]         count = 0
```

### Kiểm thử tối thiểu

- Reset, ghi 1 phần tử, đọc 1 phần tử.
- Ghi liên tiếp đến khi `full=1`, thử ghi vượt quá 8 phần tử.
- Đọc đến `empty=1`, thử đọc khi rỗng.
- Ghi + đọc đồng thời khi FIFO đang có 2 phần tử.
- Ghi + đọc đồng thời khi FIFO rỗng và khi FIFO đầy.
- Kiểm tra thứ tự dữ liệu **sau khi pointer quay vòng**.

**Điểm cộng:** nâng cấp `DATA_WIDTH`, `DEPTH` thành parameter (vẫn phải chạy đúng với WIDTH=8, DEPTH=8). Không yêu cầu FIFO bất đồng bộ hoặc CDC.

---

## Bài 2 — Thiết kế APB3 Register Slave (trung bình)

### Bối cảnh

Thiết kế một ngoại vi có **3 địa chỉ thanh ghi**, được CPU truy cập qua bus **AMBA APB3**. Chỉ thiết kế **slave**, không cần CPU, bridge hoặc APB master RTL; testbench đóng vai trò APB master.

### Giao diện bắt buộc

| Tín hiệu | Hướng | Rộng | Mô tả |
| --- | --- | ---: | --- |
| `PCLK`, `PRESETn` | input | 1 | Clock, reset bất đồng bộ active-low |
| `PSEL` | input | 1 | Peripheral select |
| `PENABLE` | input | 1 | Phân biệt SETUP và ACCESS |
| `PWRITE` | input | 1 | 1 = ghi; 0 = đọc |
| `PADDR` | input | 8 | Địa chỉ byte (local address) |
| `PWDATA` | input | 32 | Dữ liệu ghi |
| `PRDATA` | output | 32 | Dữ liệu đọc |
| `PREADY` | output | 1 | Slave báo giao dịch hoàn thành |
| `PSLVERR` | output | 1 | Báo lỗi địa chỉ/không cho phép ghi |

### Register map

| Địa chỉ | Tên | Truy cập | Reset | Hành vi |
| --- | --- | --- | --- | --- |
| `0x00` | `CONTROL` | R/W | `0` | Chỉ giữ bit `[0]` (`enable`); đọc các bit khác bằng 0 |
| `0x04` | `DATA` | R/W | `0` | Lưu đủ 32-bit |
| `0x08` | `STATUS` | R/O | — | Bit `[0]=1` (ready), bit `[1]=CONTROL[0]`, bit khác = 0 |

### Yêu cầu chức năng

1. Giao dịch có 2 pha: **SETUP** với `PSEL=1`, `PENABLE=0`, rồi **ACCESS** với `PSEL=1`, `PENABLE=1`.
2. Phiên bản này **không có wait state**: `PREADY=1` cố định.
3. Chỉ **thực hiện ghi tại cạnh lên kết thúc ACCESS** khi `PSEL && PENABLE && PREADY && PWRITE` và địa chỉ hợp lệ, ghi được. **Không ghi trong SETUP**.
4. Với lệnh đọc, `PRDATA` là giá trị thanh ghi tương ứng, hợp lệ trong ACCESS trước cạnh clock kết thúc giao dịch; khi không trong ACCESS, cho `PRDATA=0`.
5. `PSLVERR=1` **chỉ trong ACCESS** nếu địa chỉ không có trong map hoặc ghi vào `STATUS`; nếu không, `PSLVERR=0`.
6. Ghi `CONTROL` chỉ cập nhật bit 0; ghi `DATA` cập nhật đủ 32 bit.
7. Sau reset, `CONTROL=0`, `DATA=0`, `STATUS=0x00000001`.
8. Địa chỉ dùng **byte addressing**, chỉ chấp nhận chính xác `0x00`, `0x04`, `0x08`; ví dụ `0x01` là địa chỉ không hợp lệ.

### Minh họa một giao dịch ghi

```text
Chu kỳ             IDLE       SETUP         ACCESS         IDLE
PSEL                 0          1              1             0
PENABLE              0          0              1             0
PWRITE               X          1              1             X
PADDR                X         0x04           0x04           X
PWDATA               X        0x1234         0x1234          X
PREADY               1          1              1             1
                                         ^ ghi ở cạnh lên cuối ACCESS
```

Master phải giữ `PADDR`, `PWRITE`, `PWDATA` ổn định trong SETUP/ACCESS.

### Kiểm thử tối thiểu

- Reset rồi đọc `CONTROL`, `DATA`, `STATUS`.
- Ghi `CONTROL=1` → đọc lại `CONTROL=1` và `STATUS=3`.
- Ghi `DATA=0xDEADBEEF`, đọc lại đúng giá trị.
- Thử ghi `STATUS`: `PSLVERR=1`, trạng thái không thay đổi.
- Đọc/ghi địa chỉ sai (`0x0C`, `0x01`): `PSLVERR=1`.
- Chỉ đưa tín hiệu SETUP, **không** vào ACCESS: thanh ghi không được thay đổi.

**Điểm cộng:** hỗ trợ wait state bằng cách thêm logic `PREADY` (nếu làm phải giữ chuẩn điều kiện giao dịch hoàn tất).

---

## Bài 3 — Thiết kế AHB-Lite Register Slave (trung bình+)

### Bối cảnh

Thiết kế AHB-Lite slave có 4 thanh ghi 32-bit. Khác APB, giao dịch AHB-Lite được **pipeline** giữa **address phase** và **data phase**: địa chỉ của giao dịch mới có thể đến cùng lúc dữ liệu của giao dịch cũ.

### Giao diện bắt buộc

| Tín hiệu | Hướng | Rộng | Mô tả |
| --- | --- | ---: | --- |
| `HCLK`, `HRESETn` | input | 1 | Clock, reset bất đồng bộ active-low |
| `HSEL` | input | 1 | Chọn slave trong address phase |
| `HADDR` | input | 32 | Địa chỉ byte trong address phase |
| `HTRANS` | input | 2 | `00` IDLE, `01` BUSY, `10` NONSEQ, `11` SEQ |
| `HWRITE` | input | 1 | 1=ghi; 0=đọc; thuộc address phase |
| `HSIZE` | input | 3 | Bài chỉ hỗ trợ `3'b010` (word 32-bit) |
| `HWDATA` | input | 32 | Dữ liệu ghi thuộc **data phase** (trễ 1 chu kỳ so với địa chỉ) |
| `HREADY` | input | 1 | Global ready: cho phép tiến tới pha tiếp theo |
| `HRDATA` | output | 32 | Dữ liệu đọc trong data phase |
| `HREADYOUT` | output | 1 | Bài này luôn bằng 1 (slave không tạo wait state) |
| `HRESP` | output | 1 | Luôn 0 (`OKAY`) trong bài đơn giản này |

### Register map

| Địa chỉ | Tên | Reset | Truy cập |
| --- | --- | --- | --- |
| `0x00000000` | `REG0` | 0 | 32-bit R/W |
| `0x00000004` | `REG1` | 0 | 32-bit R/W |
| `0x00000008` | `REG2` | 0 | 32-bit R/W |
| `0x0000000C` | `REG3` | 0 | 32-bit R/W |

### Yêu cầu chức năng

1. Khi `HREADY=1` tại cạnh lên, nhận địa chỉ/điều khiển cho giao dịch **mới** nếu `HSEL=1` và `HTRANS[1]=1` (`NONSEQ` hoặc `SEQ`). `IDLE`/`BUSY` không tạo giao dịch mới.
2. Lưu địa chỉ, loại đọc/ghi, độ hợp lệ vào thanh ghi **data-phase**. **Không** dùng `HADDR` đang hiện diện để quyết định thao tác ghi ở data phase.
3. Trong data phase của **lệnh ghi**, lấy `HWDATA` và cập nhật thanh ghi đã chốt ở address phase trước đó tại cạnh lên nếu `HREADY=1`.
4. Trong data phase của **lệnh đọc**, đưa nội dung thanh ghi đã chốt ra `HRDATA` (combinational), để master lấy tại cạnh lên kết thúc data phase.
5. Nếu `HREADY=0`: giữ nguyên thông tin đang chờ trong data phase, **không cập nhật thanh ghi** và không nhận địa chỉ mới.
6. Slave không tạo wait state (`HREADYOUT=1`), phản hồi luôn `OKAY` (`HRESP=0`). `HREADY` là ready toàn hệ thống đưa vào slave, **không phải** `HREADYOUT`.
7. Chỉ hỗ trợ word transfer: `HSIZE=3'b010` và địa chỉ thuộc chính xác 4 từ đã liệt kê. Giao dịch sai size, sai alignment hoặc sai địa chỉ: bỏ qua ghi; đọc trả `0`, vẫn `OKAY` (quy ước **giản lược cho Lab**, không tuyên bố hỗ trợ đầy đủ AHB-Lite).
8. Reset toàn bộ 4 thanh ghi và thông tin pha dữ liệu về 0.

### Minh họa pipelining (rất quan trọng)

```text
                      Chu kỳ N                 Chu kỳ N+1              Chu kỳ N+2
Address phase          WRITE REG0               WRITE REG1              IDLE
HADDR                  0x00                     0x04                    --
HWRITE                 1                        1                       --
HTRANS                 NONSEQ                   SEQ                     IDLE

Data phase             (của giao dịch trước)    WRITE REG0              WRITE REG1
HWDATA                 --                       0x11111111              0x22222222

Kết quả: REG0 = 0x11111111, REG1 = 0x22222222.
```

**Lỗi điển hình:** ghi `HWDATA` theo `HADDR` của cùng chu kỳ → dữ liệu bị ghi vào thanh ghi **sai địa chỉ** khi có các transfer liên tiếp.

### Kiểm thử tối thiểu

- Reset; đọc cả 4 thanh ghi đều bằng 0.
- Ghi REG0 rồi đọc lại.
- Ghi liền nhau REG0 và REG1 theo **2 address phases liên tiếp**, kiểm tra dữ liệu đi đúng thanh ghi.
- Đặt `HTRANS=IDLE`/`BUSY` hoặc `HSEL=0` → không tạo giao dịch.
- Đưa `HREADY=0` ở address phase và data phase → không được nhận địa chỉ mới hoặc ghi dữ liệu quá sớm.
- Thử `HSIZE` không phải word, địa chỉ lệch word hoặc ngoài map → bỏ qua ghi / trả 0.

**Điểm cộng:** hỗ trợ byte/halfword write có byte-enable hợp lệ; nâng cao khác (burst/wait states) không bắt buộc.

---

## Gợi ý cấu trúc nộp bài

```text
labs/NguyenVanA/Lab01/
├── fifo/                    # Chỉ tạo những thư mục đề được giao
│   ├── sync_fifo.sv
│   └── tb_sync_fifo.sv
├── apb/
│   ├── apb_reg_slave.sv
│   └── tb_apb_reg_slave.sv
├── ahb/
│   ├── ahb_lite_reg_slave.sv
│   └── tb_ahb_lite_reg_slave.sv
└── report.md                # Thiết kế, test cases, kết quả
```

`report.md` cần ít nhất: (1) bài nào đã làm, (2) mô tả các thanh ghi/trạng thái/pointer, (3) bảng test case với PASS/FAIL, (4) nêu 1 lỗi tìm được khi mô phỏng và cách sửa.

## Thang điểm tham khảo (mỗi bài, 10 điểm)

| Tiêu chí | Điểm |
| --- | ---: |
| RTL tổng hợp được, port đúng, reset đúng | 2.0 |
| Đúng chức năng cơ bản theo yêu cầu | 4.0 |
| Đúng trường hợp biên / timing của giao thức | 2.0 |
| Testbench tự viết và report giải thích kết quả | 2.0 |

## Tài liệu tham khảo

- Arm — AMBA specifications: https://www.arm.com/architecture/system-architectures/amba/amba-specifications
- Arm — AMBA AHB protocol documentation: https://developer.arm.com/documentation/ihi0033/

> Đây là bài thực hành được **giản lược có chủ ý**; không phải hiện thực đầy đủ mọi tính năng của APB3/AHB-Lite.
