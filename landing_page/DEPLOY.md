# Hướng dẫn triển khai Website ChiTieu Plus

Website này được thiết kế dưới dạng **Trang web tĩnh (Static Site)**, vì vậy bạn không cần thực hiện bước "build" phức tạp. Tất cả mã nguồn nằm trong thư mục `landing_page/` đã sẵn sàng để hoạt động.

## 1. Lưu ý quan trọng (Gói Spark)
Firebase Hosting gói miễn phí **không cho phép** tải lên các tệp tin thực thi (`.exe`, `.apk`). 
- Tôi đã xóa tệp `.exe` khỏi thư mục `landing_page/downloads`.
- Cập nhật liên kết tải xuống sang **GitHub Releases** và **MediaFire** trong `index.html`.
- Bạn cần tải tệp cài đặt lên các dịch vụ này và cập nhật link chính xác.

## 1. Kiểm tra môi trường
Đảm bảo bạn đã cài đặt Firebase CLI:
```bash
npm install -g firebase-tools
```

## 2. Triển khai lên Firebase Hosting
Dự án của bạn đã được cấu hình sẵn trong `firebase.json`. Để đưa website lên internet, bạn chỉ cần chạy lệnh sau tại thư mục gốc của dự án (`d:/CHITIEU_PLUS`):

```bash
# Đăng nhập (nếu chưa)
firebase login

# Triển khai website
firebase deploy --only hosting
```

## 3. Xem kết quả
Sau khi lệnh chạy xong, Firebase sẽ cung cấp cho bạn một đường dẫn (Hosting URL). Bạn có thể truy cập vào đó để xem website đã hoạt động chưa.

## 4. Chỉnh sửa
- Mọi thay đổi về nội dung, bạn hãy chỉnh sửa trực tiếp trong `landing_page/index.html`.
- Mọi thay đổi về giao diện, hãy chỉnh sửa trong `landing_page/styles.css`.
- Sau khi sửa xong, chỉ cần chạy lại lệnh `firebase deploy --only hosting`.