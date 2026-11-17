import Foundation
import UniformTypeIdentifiers
import SwiftUI
import UIKit

struct StringHit: Identifiable {
    let id = UUID()
    let offset: Int
    let value: String
}

struct ByteHit: Identifiable {
    let id = UUID()
    let offset: Int
}

struct FileReport {
    let name: String
    let fileExtension: String
    let size: Int
    let formatInfo: String
    var bytes: [UInt8]
    let printableStrings: [StringHit]

    var preview: String { FileStudyService.hexDump(bytes: Array(bytes.prefix(4096)), baseOffset: 0) }
}

enum FileStudyService {
    static let maximumFileSize = 64 * 1024 * 1024

    static func inspect(data: Data, name: String) throws -> FileReport {
        guard data.count <= maximumFileSize else {
            throw NSError(domain: "PEDINHIOS", code: 64, userInfo: [NSLocalizedDescriptionKey: "Tệp vượt giới hạn 64 MB trong bản này."])
        }
        let bytes = [UInt8](data)
        let ext = (name as NSString).pathExtension
        return FileReport(name: name,
                          fileExtension: ext.isEmpty ? "Không rõ" : ext.uppercased(),
                          size: bytes.count, formatInfo: identifyFormat(bytes: bytes), bytes: bytes,
                          printableStrings: extractStringsWithOffsets(bytes: bytes, minimumLength: 4, limit: 300))
    }

    /// Read a Files/iCloud/provider URL while its security scope is active.
    /// NSFileCoordinator lets File Provider download or vend the selected item.
    static func readSelectedFile(at url: URL) throws -> Data {
        let didStartAccess = url.startAccessingSecurityScopedResource()
        defer { if didStartAccess { url.stopAccessingSecurityScopedResource() } }
        var coordinationError: NSError?
        var readError: Error?
        var result: Data?
        let coordinator = NSFileCoordinator(filePresenter: nil)
        coordinator.coordinate(readingItemAt: url, options: [], error: &coordinationError) { coordinatedURL in
            do {
                let values = try coordinatedURL.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
                if let isRegular = values.isRegularFile, !isRegular {
                    throw NSError(domain: "PEDINHIOS", code: 65, userInfo: [NSLocalizedDescriptionKey: "Mục đã chọn không phải tệp thông thường."])
                }
                if let size = values.fileSize, size > maximumFileSize {
                    throw NSError(domain: "PEDINHIOS", code: 64, userInfo: [NSLocalizedDescriptionKey: "Tệp lớn hơn giới hạn 64 MB."])
                }
                result = try Data(contentsOf: coordinatedURL, options: [.mappedIfSafe])
            } catch { readError = error }
        }
        if let coordinationError { throw coordinationError }
        if let readError { throw readError }
        guard let result else {
            throw NSError(domain: "PEDINHIOS", code: 66, userInfo: [NSLocalizedDescriptionKey: "iOS không cung cấp được dữ liệu của tệp đã chọn. Hãy tải tệp từ iCloud về máy rồi thử lại."])
        }
        return result
    }

    static func hexDump(bytes: [UInt8], baseOffset: Int) -> String {
        guard !bytes.isEmpty else { return "(Tệp rỗng)" }
        return stride(from: 0, to: bytes.count, by: 16).map { start in
            let chunk = Array(bytes[start..<min(start + 16, bytes.count)])
            let hex = chunk.map { String(format: "%02X", $0) }.joined(separator: " ")
            let padded = hex.padding(toLength: 47, withPad: " ", startingAt: 0)
            let ascii = String(chunk.map { ($0 >= 32 && $0 <= 126) ? Character(UnicodeScalar($0)) : "." })
            return String(format: "%08X  %@  |%@|", baseOffset + start, padded, ascii)
        }.joined(separator: "\n")
    }

    static func extractStringsWithOffsets(bytes: [UInt8], minimumLength: Int, limit: Int) -> [StringHit] {
        var hits: [StringHit] = [], start: Int? = nil
        for index in 0...bytes.count {
            let printable = index < bytes.count && bytes[index] >= 32 && bytes[index] <= 126
            if printable {
                if start == nil { start = index }
            } else if let begin = start {
                if index - begin >= minimumLength {
                    let value = String(bytes: bytes[begin..<index], encoding: .ascii) ?? ""
                    hits.append(StringHit(offset: begin, value: value))
                    if hits.count >= limit { return hits }
                }
                start = nil
            }
        }
        return hits
    }

    static func findString(_ query: String, in bytes: [UInt8], caseSensitive: Bool = true) -> [ByteHit] {
        guard !query.isEmpty else { return [] }
        let source = bytes
        let needle = Array(query.utf8)
        guard !needle.isEmpty, needle.count <= source.count else { return [] }
        var hits: [ByteHit] = []
        for index in 0...(source.count - needle.count) {
            let candidate = Array(source[index..<(index + needle.count)])
            let matches: Bool
            if caseSensitive { matches = candidate == needle }
            else { matches = String(bytes: candidate, encoding: .utf8)?.lowercased() == query.lowercased() }
            if matches { hits.append(ByteHit(offset: index)); if hits.count >= 500 { break } }
        }
        return hits
    }

    static func parseHexPattern(_ input: String) throws -> [UInt8] {
        let tokens = input.replacingOccurrences(of: "0x", with: "", options: [.caseInsensitive])
            .replacingOccurrences(of: ",", with: " ").split(whereSeparator: { $0.isWhitespace })
        guard !tokens.isEmpty else { throw LabError.invalidHex }
        return try tokens.map { token in
            guard token.count == 2, let value = UInt8(token, radix: 16) else { throw LabError.invalidHex }
            return value
        }
    }

    static func findBytes(_ pattern: [UInt8], in bytes: [UInt8]) -> [ByteHit] {
        guard !pattern.isEmpty, pattern.count <= bytes.count else { return [] }
        var hits: [ByteHit] = []
        for index in 0...(bytes.count - pattern.count) where Array(bytes[index..<(index + pattern.count)]) == pattern {
            hits.append(ByteHit(offset: index)); if hits.count >= 500 { break }
        }
        return hits
    }

    static func replaceEqualLength(at offset: Int, oldLength: Int, with replacement: [UInt8], in bytes: inout [UInt8]) throws {
        guard oldLength == replacement.count, offset >= 0, offset <= bytes.count,
              oldLength <= bytes.count - offset else {
            throw NSError(domain: "PEDINHIOS", code: 2, userInfo: [NSLocalizedDescriptionKey: "Dữ liệu thay thế phải đúng số byte và nằm trong phạm vi tệp."])
        }
        bytes.replaceSubrange(offset..<(offset + oldLength), with: replacement)
    }

    static func identifyFormat(bytes: [UInt8]) -> String {
        guard bytes.count >= 4 else { return "Tệp nhỏ / định dạng chưa xác định • vẫn đọc HEX được" }
        let magic = bytes.prefix(4).map { String(format: "%02X", $0) }.joined()
        let signatures: [String: String] = [
            "FEEDFACE": "Mach-O 32-bit big-endian", "FEEDFACF": "Mach-O 64-bit big-endian",
            "CEFAEDFE": "Mach-O 32-bit little-endian", "CFFAEDFE": "Mach-O 64-bit little-endian",
            "CAFEBABE": "FAT / Universal binary hoặc Java class", "BEBAFECA": "FAT binary byte-swapped",
            "7F454C46": "ELF executable / shared object (.so)", "504B0304": "ZIP / APK / IPA / package archive",
            "1F8B0800": "GZIP compressed data", "89504E47": "PNG image", "FFD8FFE0": "JPEG image",
            "FFD8FFE1": "JPEG image", "47494638": "GIF image", "25504446": "PDF document",
            "424D": "Bitmap image (BMP)", "52494646": "RIFF container (WAV/AVI/WebP tùy header)",
            "00000100": "Windows icon / CUR family (cần kiểm tra header đầy đủ)"
        ]
        if let known = signatures[magic] { return known }
        if bytes.starts(with: [0x53, 0x51, 0x4C, 0x69, 0x74, 0x65]) { return "SQLite database" }
        return "Chưa nhận diện được chữ ký • binary/định dạng tùy biến; vẫn phân tích HEX, strings và offset được"
    }
}

struct EditedBinaryDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.data, .item] }
    var data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws { data = configuration.file.regularFileContents ?? Data() }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}

struct FileLabView: View {
    @State private var showImporter = false
    @State private var showExporter = false
    @State private var report: FileReport?
    @State private var exportDocument = EditedBinaryDocument(data: Data())
    @State private var exportName = "PEDINHIOS-edited.bin"
    @State private var errorMessage: String?
    @State private var offsetInput = "0x0"
    @State private var offsetPreview: String?
    @State private var offsetDetails: String?
    @State private var segmentFileOffset = "0x0"
    @State private var segmentVMAddress = "0x10000000"
    @State private var imageBaseForFile = "0x10000000"
    @State private var translatedOffset: String?
    @State private var searchText = ""
    @State private var searchMode = 0
    @State private var searchHits: [ByteHit] = []
    @State private var patchOffset = "0x0"
    @State private var patchHex = "00"
    @State private var boneOld = "bone_Hips"
    @State private var boneNew = "bone_Pelvis"
    @State private var undoBytes: [UInt8]?
    @State private var status = "Chọn tệp bất kỳ để bắt đầu."

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                Panel(title: "UNIVERSAL FILE LAB", icon: "doc.viewfinder") {
                    Text("Chọn mọi loại tệp mà iOS Files cho phép truy cập. Tệp lạ vẫn mở được dưới dạng byte/HEX; nhận diện cấu trúc chỉ mang tính sơ bộ.")
                        .font(.system(size: 11)).foregroundColor(.white.opacity(0.62))
                    Button { showImporter = true } label: {
                        Label("CHỌN BẤT KỲ TỆP NÀO", systemImage: "folder.badge.plus")
                            .font(.system(size: 12, weight: .black)).frame(maxWidth: .infinity).padding(14)
                            .background(Color.iceBlue).foregroundColor(.black).clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    Text(status).font(.system(size: 10)).foregroundColor(.iceBlue)
                    if let errorMessage { Text(errorMessage).font(.system(size: 11)).foregroundColor(.red) }
                }
                if let report {
                    Panel(title: "FILE SUMMARY", icon: "doc.text.magnifyingglass") {
                        InfoLine(label: "Tên", value: report.name)
                        InfoLine(label: "Đuôi", value: report.fileExtension)
                        InfoLine(label: "Kích thước", value: ByteCountFormatter.string(fromByteCount: Int64(report.bytes.count), countStyle: .file))
                        InfoLine(label: "Nhận diện", value: report.formatInfo)
                        InfoLine(label: "Byte", value: "\(report.bytes.count) • 0x\(String(report.bytes.count, radix: 16, uppercase: true))")
                        Button { prepareExport(report) } label: { Label("XUẤT TỆP ĐÃ CHỈNH SỬA", systemImage: "square.and.arrow.up") }
                            .font(.system(size: 11, weight: .bold)).foregroundColor(.iceBlue)
                    }
                    Panel(title: "OFFSET READER", icon: "scope") {
                        HexField(title: "FILE OFFSET (VÍ DỤ 0x7729)", text: $offsetInput)
                        Button("ĐỌC VÙNG BYTE TẠI OFFSET") { inspectOffset(report) }.font(.system(size: 10, weight: .bold)).foregroundColor(.iceBlue)
                        if let offsetDetails { Text(offsetDetails).font(.system(size: 10, design: .monospaced)).foregroundColor(.white).textSelection(.enabled) }
                        if let offsetPreview { ScrollView(.horizontal) { Text(offsetPreview).font(.system(size: 9, design: .monospaced)).foregroundColor(.iceBlue).textSelection(.enabled) } }
                        Text("Offset là vị trí byte trong tệp. Một giá trị như 0x7729 không tự chứng minh đó là Aimlock, vị trí hay bone; cần phân tích cấu trúc và ngữ cảnh.")
                            .font(.system(size: 10)).foregroundColor(.white.opacity(0.55))
                    }
                    Panel(title: "FILE OFFSET → RVA / VA", icon: "arrow.left.arrow.right") {
                        Text("Ánh xạ offset của tệp qua segment đã biết. Nhập metadata segment từ header Mach-O/ELF; không đoán địa chỉ khi thiếu segment.")
                            .font(.system(size: 10)).foregroundColor(.white.opacity(0.58))
                        HexField(title: "FILE OFFSET CẦN DỊCH", text: $offsetInput)
                        HexField(title: "SEGMENT FILEOFF", text: $segmentFileOffset)
                        HexField(title: "SEGMENT VMADDR", text: $segmentVMAddress)
                        HexField(title: "IMAGE BASE", text: $imageBaseForFile)
                        Button("DỊCH OFFSET SANG RVA / VA") { translateFileOffset() }
                            .font(.system(size: 10, weight: .bold)).foregroundColor(.iceBlue)
                        if let translatedOffset { Text(translatedOffset).font(.system(size: 10, design: .monospaced)).foregroundColor(.white).textSelection(.enabled) }
                    }
                    Panel(title: "FIND STRINGS / BYTES", icon: "magnifyingglass") {
                        Picker("Search mode", selection: $searchMode) { Text("String").tag(0); Text("HEX bytes").tag(1) }.pickerStyle(SegmentedPickerStyle())
                        HexField(title: searchMode == 0 ? "TEXT TO FIND" : "HEX PATTERN (VD: 4D 5A 90 00)", text: $searchText)
                        Button("TÌM TRONG TOÀN BỘ TỆP") { findInFile(report) }.font(.system(size: 10, weight: .bold)).foregroundColor(.iceBlue)
                        Text("Tìm thấy: \(searchHits.count) vị trí (hiển thị tối đa 500).").font(.system(size: 10)).foregroundColor(.white.opacity(0.6))
                        ForEach(Array(searchHits.prefix(80))) { hit in
                            Button { offsetInput = OffsetCalculator.hex(UInt64(hit.offset)); inspectOffset(report) } label: {
                                HStack { Text(OffsetCalculator.hex(UInt64(hit.offset))).font(.system(size: 10, design: .monospaced)); Spacer(); Text("Mở offset").font(.system(size: 9, weight: .bold)) }
                                    .foregroundColor(.iceBlue)
                            }
                        }
                    }
                    Panel(title: "HEX PATCH EDITOR", icon: "pencil.and.outline") {
                        Text("Chỉnh byte trực tiếp trong bản sao đang nằm trong bộ nhớ. Nhập HEX cách nhau bằng dấu cách; số byte thay thế phải bằng số byte bị ghi đè.")
                            .font(.system(size: 10)).foregroundColor(.white.opacity(0.58))
                        HexField(title: "OFFSET", text: $patchOffset)
                        HexField(title: "NEW BYTES (VD: 90 90 00)", text: $patchHex)
                        HStack {
                            Button("ÁP DỤNG HEX PATCH") { applyPatch() }.font(.system(size: 10, weight: .bold)).foregroundColor(.iceBlue)
                            Spacer()
                            Button("UNDO") { undoChanges() }.font(.system(size: 10, weight: .bold)).foregroundColor(.orange).disabled(undoBytes == nil)
                        }
                    }
                    Panel(title: "BONE / STRING RENAMER", icon: "character.cursor.ibeam") {
                        Text("Đổi tên chuỗi có trong tệp, ví dụ bone_Hips. Chỉ thay thế khi tên mới có cùng độ dài UTF-8 để không làm lệch offset và cấu trúc dữ liệu.")
                            .font(.system(size: 10)).foregroundColor(.white.opacity(0.58))
                        HexField(title: "OLD STRING", text: $boneOld)
                        HexField(title: "NEW STRING", text: $boneNew)
                        Button("RENAME STRING IN FILE") { renameString() }.font(.system(size: 10, weight: .bold)).foregroundColor(.iceBlue)
                    }
                    Panel(title: "STRING MAP", icon: "text.alignleft") {
                        Text("Các chuỗi ASCII tìm được và offset bắt đầu. Chuỗi Unicode/UTF-16 có thể cần bộ phân tích riêng.")
                            .font(.system(size: 10)).foregroundColor(.white.opacity(0.55))
                        ForEach(Array(report.printableStrings.prefix(100))) { hit in
                            VStack(alignment: .leading, spacing: 3) {
                                Text(OffsetCalculator.hex(UInt64(hit.offset))).font(.system(size: 9, design: .monospaced)).foregroundColor(.iceBlue)
                                Text(hit.value).font(.system(size: 10, design: .monospaced)).foregroundColor(.white.opacity(0.8)).textSelection(.enabled)
                            }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 3)
                        }
                    }
                    Panel(title: "HEX PREVIEW", icon: "chevron.left.forwardslash.chevron.right") {
                        ScrollView([.horizontal, .vertical]) {
                            Text(report.preview).font(.system(size: 9, design: .monospaced)).foregroundColor(.iceBlue).textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }.frame(maxHeight: 280)
                    }
                }
                Panel(title: "FORMAT SUPPORT", icon: "shippingbox") {
                    NoteRow(title: "Generic binary", detail: "Mọi định dạng mà Files cấp quyền: DAT, BIN, SO, DYLIB, 3D, 3DS, PAK, OBB, IPA, ZIP và tệp không có phần mở rộng.")
                    NoteRow(title: "Format-aware", detail: "Nhận diện magic bytes phổ biến: Mach-O/FAT, ELF, ZIP, SQLite, GZIP, PDF và ảnh. Nhận diện không đồng nghĩa giải mã mọi định dạng độc quyền.")
                    NoteRow(title: "An toàn", detail: "Chỉ đọc và sửa bản sao cục bộ do bạn chọn. Không đọc/ghi bộ nhớ tiến trình, không inject hoặc vượt sandbox iOS.")
                }
            }.padding(16)
        }
        .fileImporter(isPresented: $showImporter,
                      allowedContentTypes: [.item],
                      allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                guard let selectedURL = urls.first else {
                    errorMessage = "Bạn chưa chọn tệp."
                    status = "Chưa có tệp được chọn."
                    return
                }
                handlePickedURL(selectedURL)
            case .failure(let error):
                errorMessage = "Không chọn được tệp: \(error.localizedDescription)"
                status = "Trình chọn tệp đã báo lỗi."
            }
        }
        .fileExporter(isPresented: $showExporter, document: exportDocument, contentType: .data, defaultFilename: exportName) { result in
            switch result { case .success: status = "Đã xuất tệp đã chỉnh sửa."; case .failure(let error): errorMessage = error.localizedDescription }
        }
    }

    private func inspectOffset(_ report: FileReport) {
        do {
            let value = try OffsetCalculator.parseHex(offsetInput)
            guard value < UInt64(report.bytes.count) else { throw messageError("Offset nằm ngoài kích thước tệp.") }
            let start = Int(value), end = min(Int(value) + 256, report.bytes.count)
            let byte = report.bytes[start]
            let decimal = String(byte)
            let ascii = (byte >= 32 && byte <= 126) ? String(UnicodeScalar(byte)) : "."
            let next = Array(report.bytes[start..<min(start + 4, report.bytes.count)])
            let le32 = next.enumerated().reduce(UInt32(0)) { $0 | (UInt32($1.element) << (UInt32($1.offset) * 8)) }
            let be32 = next.reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
            offsetDetails = "File offset: \(OffsetCalculator.hex(value))\nDecimal: \(start)\nByte: 0x\(String(byte, radix: 16, uppercase: true)) (\(decimal)) ASCII: \(ascii)\nUInt32 LE: 0x\(String(le32, radix: 16, uppercase: true))\nUInt32 BE: 0x\(String(be32, radix: 16, uppercase: true))"
            offsetPreview = FileStudyService.hexDump(bytes: Array(report.bytes[start..<end]), baseOffset: start)
            errorMessage = nil
        } catch { errorMessage = error.localizedDescription }
    }

    private func translateFileOffset() {
        do {
            let fileOffset = try OffsetCalculator.parseHex(offsetInput)
            let segmentOffset = try OffsetCalculator.parseHex(segmentFileOffset)
            let segmentVM = try OffsetCalculator.parseHex(segmentVMAddress)
            let imageBase = try OffsetCalculator.parseHex(imageBaseForFile)
            guard fileOffset >= segmentOffset, segmentVM >= imageBase else {
                throw messageError("Offset nằm trước segment hoặc VM address nhỏ hơn image base.")
            }
            let delta = fileOffset - segmentOffset
            let va = try OffsetCalculator.add(base: segmentVM, offset: delta)
            guard va >= imageBase else { throw messageError("Không thể tính RVA với image base đã nhập.") }
            let rva = va - imageBase
            translatedOffset = "File Offset: \(OffsetCalculator.hex(fileOffset))\nRVA: \(OffsetCalculator.hex(rva))\nVA: \(OffsetCalculator.hex(va))\nCông thức: VA = Segment VMADDR + (File Offset - Segment FILEOFF)"
            errorMessage = nil
        } catch { translatedOffset = nil; errorMessage = error.localizedDescription }
    }

    private func findInFile(_ report: FileReport) {
        do {
            if searchMode == 0 { searchHits = FileStudyService.findString(searchText, in: report.bytes) }
            else { searchHits = FileStudyService.findBytes(try FileStudyService.parseHexPattern(searchText), in: report.bytes) }
            status = "Hoàn tất tìm kiếm trên \(report.bytes.count) byte."
            errorMessage = nil
        } catch { errorMessage = "Mẫu tìm kiếm không hợp lệ: \(error.localizedDescription)" }
    }

    private func applyPatch() {
        guard var current = report else { return }
        do {
            let offset = try OffsetCalculator.parseHex(patchOffset)
            guard offset <= UInt64(Int.max) else { throw messageError("Offset quá lớn.") }
            let replacement = try FileStudyService.parseHexPattern(patchHex)
            try FileStudyService.replaceEqualLength(at: Int(offset), oldLength: replacement.count, with: replacement, in: &current.bytes)
            undoBytes = report?.bytes
            report = current; status = "Đã áp dụng \(replacement.count) byte trong bản sao bộ nhớ."; errorMessage = nil
        } catch { errorMessage = error.localizedDescription }
    }

    private func renameString() {
        guard var current = report else { return }
        let oldBytes = Array(boneOld.utf8), newBytes = Array(boneNew.utf8)
        guard !oldBytes.isEmpty else { errorMessage = "Tên cũ không được để trống."; return }
        guard oldBytes.count == newBytes.count else { errorMessage = "Tên mới phải cùng số byte UTF-8 (\(oldBytes.count) byte)."; return }
        let hits = FileStudyService.findBytes(oldBytes, in: current.bytes)
        guard !hits.isEmpty else { errorMessage = "Không tìm thấy chuỗi cũ trong tệp."; return }
        undoBytes = current.bytes
        for hit in hits.reversed() {
            try? FileStudyService.replaceEqualLength(at: hit.offset, oldLength: oldBytes.count, with: newBytes, in: &current.bytes)
        }
        report = current; status = "Đã đổi \(hits.count) vị trí chuỗi trong bản sao."; errorMessage = nil
    }

    private func undoChanges() {
        guard var current = report, let previous = undoBytes else { return }
        current.bytes = previous; report = current; undoBytes = nil
        status = "Đã hoàn tác thay đổi gần nhất."
    }

    private func prepareExport(_ report: FileReport) {
        exportDocument = EditedBinaryDocument(data: Data(report.bytes))
        let base = (report.name as NSString).deletingPathExtension
        let ext = (report.name as NSString).pathExtension
        exportName = base + "-edited" + (ext.isEmpty ? ".bin" : "." + ext)
        showExporter = true
    }

    private func handlePickedURL(_ url: URL) {
        status = "Đang nhập \(url.lastPathComponent)…"
        errorMessage = nil
        do {
            let data = try FileStudyService.readSelectedFile(at: url)
            let openedReport = try FileStudyService.inspect(data: data, name: url.lastPathComponent)
            report = openedReport
            undoBytes = nil
            offsetInput = "0x0"
            patchOffset = "0x0"
            offsetPreview = nil
            offsetDetails = nil
            translatedOffset = nil
            searchHits = []
            status = "Đã mở \(url.lastPathComponent) • \(openedReport.size) byte • \(openedReport.formatInfo)"
            errorMessage = nil
        } catch {
            errorMessage = "Không đọc được \(url.lastPathComponent): \(error.localizedDescription)"
            status = "Đã chọn tệp nhưng không nhập được dữ liệu. Hãy tải tệp về On My iPhone rồi thử lại nếu tệp đang nằm trên iCloud/ổ mạng."
        }
    }

    private func messageError(_ message: String) -> NSError {
        NSError(domain: "PEDINHIOS", code: 3, userInfo: [NSLocalizedDescriptionKey: message])
    }
}

