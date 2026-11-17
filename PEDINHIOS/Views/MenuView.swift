import SwiftUI

struct LearningView: View {
    private let lessons: [(String, String, String)] = [
        ("01 • HEX & DECIMAL", "Hệ thập lục phân dùng các ký tự 0–9 và A–F. Mỗi chữ số HEX tương ứng 4 bit; 0x10 = 16 ở hệ thập phân.", "number"),
        ("02 • ARM64 REGISTERS", "X0–X30 là các thanh ghi đa dụng 64-bit; W0–W30 là phần 32-bit tương ứng. SP là stack pointer, PC là program counter.", "cpu"),
        ("03 • MACH-O", "Mach-O là định dạng executable/object của Apple. Header mô tả magic, CPU type, file type và số load commands.", "doc.text"),
        ("04 • IPA & BUNDLE", "IPA thường là gói ZIP có thư mục Payload chứa .app. Info.plist lưu metadata như bundle identifier và version.", "shippingbox"),
        ("05 • DYLIB", "Dynamic library là thư viện có thể được liên kết khi chạy. Tệp .dylib không tự động cho phép truy cập tiến trình khác.", "puzzlepiece.extension"),
        ("06 • ASLR & SLIDE", "ASLR ngẫu nhiên hóa vị trí nạp. Trong nghiên cứu hợp pháp, cần phân biệt địa chỉ trong tệp với địa chỉ ảo khi nạp.", "arrow.left.arrow.right"),
        ("07 • FILE OFFSET / RVA", "File offset chỉ vị trí byte trên tệp. RVA là độ lệch tương đối trong image. Không thể luôn đổi trực tiếp giữa hai loại nếu chưa biết segment/section mapping.", "point.3.connected.trianglepath.dotted"),
        ("08 • POINTER & ENDIAN", "Pointer lưu địa chỉ theo kiến trúc. Endianness quy định thứ tự byte; ARM64 trên iOS thường dùng little-endian.", "memorychip")
    ]
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                Panel(title: "LEARNING PATH", icon: "graduationcap.fill") {
                    Text("Lộ trình tự học nền tảng phân tích nhị phân và cấu trúc ứng dụng iOS.").font(.system(size: 11)).foregroundColor(.white.opacity(0.55))
                    ForEach(lessons, id: \.0) { item in
                        VStack(alignment: .leading, spacing: 7) {
                            Label(item.0, systemImage: item.2).font(.system(size: 12, weight: .bold)).foregroundColor(.iceBlue)
                            Text(item.1).font(.system(size: 11)).foregroundColor(.white.opacity(0.68)).fixedSize(horizontal: false, vertical: true)
                        }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 5)
                    }
                }
                Panel(title: "PRACTICE CHECKLIST", icon: "checklist") {
                    Text("• Chuyển đổi HEX ↔ DECIMAL\n• Tính Base + Offset\n• Phân biệt File Offset, RVA và VA\n• Mở tệp mẫu và đọc Hex Dump\n• Nhận diện magic bytes\n• Tìm chuỗi ASCII trong dữ liệu")
                        .font(.system(size: 11, design: .monospaced)).foregroundColor(.white.opacity(0.7))
                }
            }.padding(16)
        }
    }
}
