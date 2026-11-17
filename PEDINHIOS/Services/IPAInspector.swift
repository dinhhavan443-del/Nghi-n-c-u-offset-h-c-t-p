import Foundation

struct FileReport {
    let name: String
    let fileExtension: String
    let size: Int
    let sha256Note: String
    let preview: String
    let printableStrings: [String]
    let machoInfo: String
    let bytes: [UInt8]
}

enum FileStudyService {
    static func inspect(url: URL) throws -> FileReport {
        let data = try Data(contentsOf: url, options: [.mappedIfSafe])
        guard data.count <= 64 * 1024 * 1024 else { throw NSError(domain: "PEDINHIOS", code: 64, userInfo: [NSLocalizedDescriptionKey: "Tệp vượt giới hạn xem trước 64 MB."]) }
        let bytes = [UInt8](data.prefix(4096))
        let preview = hexDump(bytes: bytes, baseOffset: 0)
        let strings = extractStrings(data: data, minimumLength: 5, limit: 80)
        return FileReport(
            name: url.lastPathComponent,
            fileExtension: url.pathExtension.isEmpty ? "Không rõ" : url.pathExtension.uppercased(),
            size: data.count,
            sha256Note: "Bản xem trước cục bộ • không tải tệp lên máy chủ",
            preview: preview,
            printableStrings: strings,
            machoInfo: machoSummary(data: data),
            bytes: [UInt8](data)
        )
    }

    static func hexDump(bytes: [UInt8], baseOffset: Int) -> String {
        guard !bytes.isEmpty else { return "(Tệp rỗng)" }
        var lines: [String] = []
        for start in stride(from: 0, to: bytes.count, by: 16) {
            let chunk = Array(bytes[start..<min(start + 16, bytes.count)])
            let hex = chunk.map { String(format: "%02X", $0) }.joined(separator: " ")
            let padded = hex.padding(toLength: 47, withPad: " ", startingAt: 0)
            let ascii = chunk.map { value -> Character in
                (value >= 32 && value <= 126) ? Character(UnicodeScalar(value)) : "."
            }
            lines.append(String(format: "%08X  %@  |%@|", baseOffset + start, padded, String(ascii)))
        }
        return lines.joined(separator: "\n")
    }

    private static func extractStrings(data: Data, minimumLength: Int, limit: Int) -> [String] {
        var results: [String] = []
        var current: [UInt8] = []
        for byte in data {
            if byte >= 32 && byte <= 126 {
                current.append(byte)
            } else {
                if current.count >= minimumLength, let value = String(bytes: current, encoding: .ascii) {
                    results.append(value)
                    if results.count >= limit { return results }
                }
                current.removeAll(keepingCapacity: true)
            }
        }
        if current.count >= minimumLength, let value = String(bytes: current, encoding: .ascii) { results.append(value) }
        return Array(results.prefix(limit))
    }

    private static func machoSummary(data: Data) -> String {
        guard data.count >= 4 else { return "Tệp quá nhỏ để nhận diện header." }
        let magic = data.prefix(4).map { String(format: "%02X", $0) }.joined()
        let known: [String: String] = [
            "FEEDFACE": "Mach-O 32-bit (byte order cần xác định)",
            "FEEDFACF": "Mach-O 64-bit (byte order cần xác định)",
            "CEFAEDFE": "Mach-O 32-bit little-endian",
            "CFFAEDFE": "Mach-O 64-bit little-endian",
            "CAFEBABE": "Universal/FAT binary hoặc Java class tùy ngữ cảnh",
            "BEBAFECA": "FAT binary dạng byte-swapped"
        ]
        return known[magic] ?? "Không nhận diện được Mach-O từ 4 byte đầu (magic: \(magic)). Tệp vẫn có thể là dữ liệu hợp lệ khác."
    }
}

import SwiftUI
import UniformTypeIdentifiers

struct FileLabView: View {
    @State private var showImporter = false
    @State private var report: FileReport?
    @State private var errorMessage: String?
    @State private var selectedSection = 0
    @State private var fileOffsetInput = "0x0"
    @State private var offsetPreview: String?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                Panel(title: "LOCAL FILE INSPECTOR", icon: "doc.viewfinder") {
                    Text("Chọn tệp từ ứng dụng Tệp để xem metadata cơ bản, byte đầu, Hex Dump và chuỗi ASCII. Phân tích được thực hiện ngay trên thiết bị.")
                        .font(.system(size: 11)).foregroundColor(.white.opacity(0.58))
                    Button { showImporter = true } label: {
                        Label("CHỌN TỆP ĐỂ PHÂN TÍCH", systemImage: "folder.badge.plus")
                            .font(.system(size: 12, weight: .black)).frame(maxWidth: .infinity).padding(14)
                            .background(Color.iceBlue).foregroundColor(.black).clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    if let errorMessage { Text(errorMessage).font(.system(size: 11)).foregroundColor(.red) }
                }
                if let report {
                    Panel(title: "FILE INFORMATION", icon: "info.circle") {
                        InfoLine(label: "Name", value: report.name)
                        InfoLine(label: "Type", value: report.fileExtension)
                        InfoLine(label: "Size", value: ByteCountFormatter.string(fromByteCount: Int64(report.size), countStyle: .file))
                        Text(report.sha256Note).font(.system(size: 9)).foregroundColor(.green.opacity(0.8))
                    }
                    Panel(title: "BINARY FORMAT", icon: "cpu") {
                        Text(report.machoInfo).font(.system(size: 11)).foregroundColor(.white.opacity(0.72)).textSelection(.enabled)
                    }
                    Panel(title: "FILE OFFSET EXPLORER", icon: "scope") {
                        Text("Nhập vị trí byte trong chính tệp đã chọn để xem vùng dữ liệu xung quanh.").font(.system(size: 10)).foregroundColor(.white.opacity(0.55))
                        HexField(title: "FILE OFFSET", text: $fileOffsetInput)
                        Button("READ 256 BYTES AT OFFSET") { inspectOffset(report) }
                            .font(.system(size: 10, weight: .bold)).foregroundColor(.iceBlue)
                        if let offsetPreview {
                            ScrollView(.horizontal) { Text(offsetPreview).font(.system(size: 9, design: .monospaced)).foregroundColor(.iceBlue).textSelection(.enabled) }
                        }
                    }
                    Panel(title: "DATA VIEWER", icon: "chevron.left.forwardslash.chevron.right") {
                        Picker("View", selection: $selectedSection) {
                            Text("Hex Dump").tag(0); Text("ASCII Strings").tag(1)
                        }.pickerStyle(SegmentedPickerStyle())
                        if selectedSection == 0 {
                            ScrollView(.horizontal, showsIndicators: true) {
                                Text(report.preview).font(.system(size: 9, design: .monospaced)).foregroundColor(.iceBlue).textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        } else {
                            if report.printableStrings.isEmpty {
                                Text("Không tìm thấy chuỗi ASCII đủ dài trong phần dữ liệu đã quét.").font(.system(size: 11)).foregroundColor(.white.opacity(0.55))
                            } else {
                                ForEach(Array(report.printableStrings.enumerated()), id: \.offset) { index, value in
                                    Text(String(format: "%02d  %@", index + 1, value)).font(.system(size: 10, design: .monospaced)).foregroundColor(.white.opacity(0.75)).textSelection(.enabled)
                                }
                            }
                        }
                    }
                }
                Panel(title: "LEARNING NOTE", icon: "lightbulb") {
                    NoteRow(title: "Magic bytes", detail: "Một số định dạng có chữ ký byte ở đầu tệp. Đây chỉ là nhận diện sơ bộ, không phải xác minh an toàn/chữ ký.")
                    NoteRow(title: "Hex dump", detail: "Hiển thị byte dưới dạng HEX, kèm cột ASCII để quan sát dữ liệu dễ đọc.")
                    NoteRow(title: "Giới hạn iOS", detail: "Ứng dụng chỉ đọc tệp mà bạn chủ động chọn và được iOS cấp quyền. Không thể tự duyệt vùng dữ liệu riêng của app khác.")
                }
            }.padding(16)
        }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.item], allowsMultipleSelection: false) { result in
            handleImport(result)
        }
    }

    private func inspectOffset(_ report: FileReport) {
        do {
            let value = try OffsetCalculator.parseHex(fileOffsetInput)
            guard value < UInt64(report.bytes.count) else { throw NSError(domain: "PEDINHIOS", code: 2, userInfo: [NSLocalizedDescriptionKey: "Offset nằm ngoài kích thước tệp."]) }
            let start = Int(value)
            let end = min(start + 256, report.bytes.count)
            offsetPreview = FileStudyService.hexDump(bytes: Array(report.bytes[start..<end]), baseOffset: start)
            errorMessage = nil
        } catch { errorMessage = error.localizedDescription }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let access = url.startAccessingSecurityScopedResource()
            defer { if access { url.stopAccessingSecurityScopedResource() } }
            do {
                let values = try url.resourceValues(forKeys: [.fileSizeKey])
                if let size = values.fileSize, size > 64 * 1024 * 1024 {
                    errorMessage = "Tệp lớn hơn 64 MB. Hãy chọn tệp nhỏ hơn để xem trước an toàn."
                    return
                }
                report = try FileStudyService.inspect(url: url)
                fileOffsetInput = "0x0"
                offsetPreview = nil
                selectedSection = 0
                errorMessage = nil
            } catch {
                errorMessage = "Không đọc được tệp: \(error.localizedDescription)"
            }
        case .failure(let error):
            errorMessage = "Không thể mở tệp: \(error.localizedDescription)"
        }
    }
}
