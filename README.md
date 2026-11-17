# PEDINHIOS MENU

Ứng dụng SwiftUI phong cách đen – xanh băng, iOS Deployment Target 15.0.

## Tính năng
- Home / Menu / Settings.
- Offset Calculator: phép tính Base Address + Offset trên dữ liệu nhập thủ công.
- Không truy cập hoặc sửa bộ nhớ của game/ứng dụng khác.
- Không cung cấp overlay toàn hệ thống. Menu chỉ hiển thị bên trong ứng dụng.

## Build IPA bằng GitHub Actions
1. Tạo repository GitHub mới.
2. Upload toàn bộ nội dung ZIP này lên repository.
3. Mở tab **Actions** và bật workflow nếu GitHub yêu cầu.
4. Chạy workflow **Build PEDINHIOS IPA**.
5. Tải artifact `PEDINHIOS-unsigned-ipa` ở cuối workflow.

Artifact mặc định là IPA chưa ký (unsigned). Để cài lên iPhone cần ký bằng Apple Developer account / công cụ ký hợp lệ. GitHub Actions không thể tự tạo chữ ký phân phối hợp lệ nếu bạn chưa cấu hình chứng chỉ và provisioning profile.

## Build bằng Xcode
Mở `PEDINHIOS.xcodeproj`, chọn target PEDINHIOS, đặt Team/signing phù hợp, chọn thiết bị hoặc Any iOS Device, sau đó Archive.

## Tương thích
- Deployment target: iOS 15.0.
- SwiftUI; thiết kế cho iPhone và tự co giãn theo kích thước màn hình.
- Build trên phiên bản Xcode/macOS hiện được GitHub runner hỗ trợ.

## Cấu trúc
- `PEDINHIOS/App`: entry point và cấu hình.
- `PEDINHIOS/Views`: giao diện.
- `PEDINHIOS/Services`: logic tính toán và đọc metadata.
- `PEDINHIOS/Models`: kiểu dữ liệu.
- `.github/workflows`: pipeline build.
