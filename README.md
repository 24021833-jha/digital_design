# Nộp bài Lab qua GitHub

Repository dùng để nộp bài thực hành. Mỗi sinh viên **chỉ làm việc trong thư mục của mình** tại `labs/`.

## 1. Cấu trúc thư mục

```text
labs/
├── NguyenVanA/
│   ├── Lab01/
│   │   └── main.c
│   └── Lab02/
│       └── ...
└── TranThiB/
    └── Lab01/
        └── ...
```

- Đặt tên thư mục theo **họ tên không dấu, không khoảng trắng** (ví dụ: `NguyenVanA`). Nếu trùng tên, thêm mã sinh viên: `NguyenVanA_22001234`.
- Mỗi bài để trong một thư mục `Lab01`, `Lab02`, ...
- **Không sửa hoặc xóa** bài của sinh viên khác; không sửa `README.md` hay thư mục `.github/`.

## 2. Cách nộp bài (5 bước)

### Bước 1 — Fork repository

Mở repository của giảng viên trên GitHub, bấm **Fork → Create fork**. Sinh viên **không cần quyền ghi** trên repository của giảng viên.

### Bước 2 — Clone fork về máy

Thay `GITHUB_USERNAME` và `TEN_REPO` bằng thông tin của bạn:

```bash
git clone https://github.com/GITHUB_USERNAME/TEN_REPO.git
cd TEN_REPO
```

### Bước 3 — Tạo thư mục và chép bài vào

Ví dụ sinh viên `NguyenVanA` nộp `Lab01`:

```bash
mkdir -p labs/NguyenVanA/Lab01
```

Chép các file bài làm (`.c`, `.h`, `.v`, `.sv`, ...) vào `labs/NguyenVanA/Lab01/`.

### Bước 4 — Commit và push

```bash
git add labs/NguyenVanA/Lab01
git commit -m "NguyenVanA - Lab01"
git push origin main
```

Nếu Git báo chưa có thông tin tác giả, cấu hình một lần:

```bash
git config --global user.name "Nguyen Van A"
git config --global user.email "email-github@example.com"
```

### Bước 5 — Tạo Pull Request (bắt buộc)

1. Mở **fork của bạn** trên GitHub.
2. Chọn **Contribute → Open pull request** (hoặc **Compare & pull request**).
3. Kiểm tra **base repository** là repository của giảng viên, nhánh `main`; **head repository** là fork của bạn.
4. Đặt tiêu đề theo mẫu: `NguyenVanA - Lab01` rồi bấm **Create pull request**.

**Chỉ `git commit`/`git push` mà chưa tạo Pull Request thì chưa được tính là nộp bài.** Giảng viên sẽ kiểm tra và merge PR.

## 3. Nộp Lab tiếp theo

**Đợi PR của Lab trước được merge** nếu bạn đang nộp trên nhánh `main` của fork.

Trước khi làm bài tiếp theo, trên GitHub mở fork và chọn **Sync fork → Update branch** để cập nhật bài mới nhất từ repository của giảng viên. Sau đó chạy:

```bash
git pull origin main
mkdir -p labs/NguyenVanA/Lab02
# Chép bài vào Lab02
git add labs/NguyenVanA/Lab02
git commit -m "NguyenVanA - Lab02"
git push origin main
```

Cuối cùng tạo **Pull Request mới** cho `Lab02`.

## 4. Lưu ý

- Mỗi Lab tạo **một Pull Request riêng** để dễ chấm điểm.
- Có thể commit nhiều lần; trước khi nộp cần `push` để GitHub nhận các commit đó.
- Không đưa file thực thi, file biên dịch hoặc file dung lượng lớn vào repository.
- Nếu PR có xung đột (**conflict**), hãy báo giảng viên hoặc cập nhật lại fork.

**Giảng viên:** Mở tab **Pull requests** của repository, kiểm tra bài và chọn **Merge pull request**.
