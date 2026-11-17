import SwiftUI
import UIKit

struct OffsetLabView: View {
    @State private var base = "0x10000000"
    @State private var offset = "0x1234"
    @State private var imageBase = "0x10000000"
    @State private var rva = "0x2340"
    @State private var va = "0x10002340"
    @State private var result = "0x10001234"
    @State private var secondary = "0x10002340"
    @State private var error: String?
    @State private var mode = 0

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                Panel(title: "OFFSET WORKBENCH", icon: "number") {
                    Text("Máy tính địa chỉ dùng dữ liệu nhập thủ công hoặc dữ liệu mẫu. Không kết nối vào tiến trình game/app.")
                        .font(.system(size: 11)).foregroundColor(.white.opacity(0.55))
                    Picker("Mode", selection: $mode) {
                        Text("Base + Offset").tag(0); Text("RVA → VA").tag(1); Text("VA → RVA").tag(2)
                    }.pickerStyle(SegmentedPickerStyle())
                    if mode == 0 {
                        HexField(title: "BASE ADDRESS", text: $base)
                        HexField(title: "OFFSET", text: $offset)
                    } else if mode == 1 {
                        HexField(title: "IMAGE BASE", text: $imageBase)
                        HexField(title: "RVA", text: $rva)
                    } else {
                        HexField(title: "IMAGE BASE", text: $imageBase)
                        HexField(title: "VIRTUAL ADDRESS", text: $va)
                    }
                    Button(action: calculate) {
                        Label("CALCULATE", systemImage: "equal.circle.fill").font(.system(size: 12, weight: .black))
                            .frame(maxWidth: .infinity).padding(14).background(Color.iceBlue).foregroundColor(.black).clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    resultCard(title: "RESULT", value: result)
                    if let error { Text(error).font(.system(size: 11)).foregroundColor(.red) }
                }
                Panel(title: "NUMBER CONVERTER", icon: "arrow.left.arrow.right") {
                    InfoLine(label: "HEX result", value: result)
                    InfoLine(label: "Decimal", value: decimalResult)
                    InfoLine(label: "Binary", value: binaryResult)
                    Button("Copy result") { UIPasteboard.general.string = result }.font(.system(size: 11, weight: .bold)).foregroundColor(.iceBlue)
                }
                Panel(title: "OFFSET CONCEPTS", icon: "graduationcap") {
                    NoteRow(title: "File Offset", detail: "Vị trí byte trong tệp trên đĩa, thường bắt đầu từ 0.")
                    NoteRow(title: "RVA", detail: "Relative Virtual Address: độ lệch tương đối so với image base khi nạp.")
                    NoteRow(title: "VA", detail: "Virtual Address: địa chỉ ảo minh họa = Image Base + RVA.")
                    NoteRow(title: "ASLR", detail: "Hệ thống có thể thay đổi image base giữa các lần chạy.")
                    NoteRow(title: "Pointer", detail: "Một giá trị có thể biểu diễn địa chỉ; cần biết kiến trúc và ngữ cảnh để diễn giải.")
                }
                Panel(title: "SAMPLE DATA", icon: "wand.and.stars") {
                    Button("Load example values") { base = "0x10000000"; offset = "0x1234"; imageBase = "0x10000000"; rva = "0x2340"; va = "0x10002340"; mode = 0; calculate() }
                        .font(.system(size: 11, weight: .bold)).foregroundColor(.iceBlue)
                }
            }.padding(16)
        }
    }

    private var decimalResult: String { (try? OffsetCalculator.parseHex(result)).map { String($0) } ?? "—" }
    private var binaryResult: String { (try? OffsetCalculator.parseHex(result)).map { String($0, radix: 2) } ?? "—" }
    private func resultCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(size: 9, weight: .bold)).tracking(1.4).foregroundColor(.iceBlue)
            Text(value).font(.system(size: 21, weight: .black, design: .monospaced)).foregroundColor(.white).textSelection(.enabled)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(13).background(Color.black.opacity(0.25)).clipShape(RoundedRectangle(cornerRadius: 12))
    }
    private func calculate() {
        do {
            if mode == 0 {
                let b = try OffsetCalculator.parseHex(base); let o = try OffsetCalculator.parseHex(offset)
                result = OffsetCalculator.hex(try OffsetCalculator.add(base: b, offset: o))
            } else if mode == 1 {
                let b = try OffsetCalculator.parseHex(imageBase); let r = try OffsetCalculator.parseHex(rva)
                result = OffsetCalculator.hex(try OffsetCalculator.add(base: b, offset: r))
            } else {
                let b = try OffsetCalculator.parseHex(imageBase); let v = try OffsetCalculator.parseHex(va)
                guard v >= b else { throw LabError.invalidHex }
                result = OffsetCalculator.hex(v - b)
            }
            error = nil
        } catch { self.error = error.localizedDescription }
    }
}

struct HexField: View {
    let title: String; @Binding var text: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(size: 9, weight: .bold)).tracking(1.3).foregroundColor(.white.opacity(0.55))
            TextField("0x...", text: $text).textInputAutocapitalization(.characters).autocorrectionDisabled()
                .font(.system(size: 14, weight: .semibold, design: .monospaced)).padding(12)
                .background(Color.black.opacity(0.25)).clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

struct NoteRow: View {
    let title: String; let detail: String
    var body: some View { VStack(alignment: .leading, spacing: 3) { Text(title).font(.system(size: 12, weight: .bold)).foregroundColor(.iceBlue); Text(detail).font(.system(size: 11)).foregroundColor(.white.opacity(0.58)) }.frame(maxWidth: .infinity, alignment: .leading) }
}
