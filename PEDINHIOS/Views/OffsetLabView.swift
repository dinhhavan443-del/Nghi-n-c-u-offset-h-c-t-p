import SwiftUI

struct OffsetLabView: View {
    @State private var base = "0x10000000"
    @State private var offset = "0x1234"
    @State private var result = "0x10001234"
    @State private var error: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Panel(title: "OFFSET CALCULATOR", icon: "number") {
                    Text("Tính Base Address + Offset bằng dữ liệu ví dụ. Công cụ không đọc hoặc sửa bộ nhớ game hay ứng dụng khác.")
                        .font(.system(size: 11)).foregroundColor(.white.opacity(0.55))
                    HexField(title: "BASE ADDRESS", text: $base)
                    HexField(title: "OFFSET", text: $offset)
                    Button(action: calculate) {
                        Label("CALCULATE ADDRESS", systemImage: "equal")
                            .font(.system(size: 12, weight: .black)).frame(maxWidth: .infinity).padding(14)
                            .background(Color.iceBlue).foregroundColor(Color.black)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    VStack(alignment: .leading, spacing: 5) {
                        Text("RESULT").font(.system(size: 9, weight: .bold)).tracking(1.4).foregroundColor(Color.iceBlue)
                        Text(result).font(.system(size: 22, weight: .black, design: .monospaced)).foregroundColor(.white)
                            .textSelection(.enabled)
                    }.frame(maxWidth: .infinity, alignment: .leading).padding(13)
                        .background(Color.black.opacity(0.25)).clipShape(RoundedRectangle(cornerRadius: 12))
                    if let error {
                        Text(error).font(.system(size: 11)).foregroundColor(.red)
                    }
                }
                Panel(title: "LEARNING NOTES", icon: "book.closed") {
                    NoteRow(title: "ASLR", detail: "Địa chỉ nạp có thể thay đổi giữa các lần chạy.")
                    NoteRow(title: "Module-relative offset", detail: "Độ lệch tính tương đối với một module.")
                    NoteRow(title: "Pointer", detail: "Giá trị có thể trỏ tới một vùng dữ liệu khác.")
                }
            }.padding(18)
        }
    }

    private func calculate() {
        do {
            let b = try OffsetCalculator.parseHex(base)
            let o = try OffsetCalculator.parseHex(offset)
            result = OffsetCalculator.hex(try OffsetCalculator.add(base: b, offset: o))
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct HexField: View {
    let title: String
    @Binding var text: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(size: 9, weight: .bold)).tracking(1.3).foregroundColor(.white.opacity(0.55))
            TextField("0x...", text: $text).textInputAutocapitalization(.characters)
                .autocorrectionDisabled().font(.system(size: 14, weight: .semibold, design: .monospaced))
                .padding(12).background(Color.black.opacity(0.25)).clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

struct NoteRow: View {
    let title: String
    let detail: String
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.system(size: 12, weight: .bold)).foregroundColor(Color.iceBlue)
            Text(detail).font(.system(size: 11)).foregroundColor(.white.opacity(0.58))
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}
