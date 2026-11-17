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

    static func inspect(url: URL) throws -> FileReport {
        var coordinatedData: Data?
        var coordinationError: NSError?
        var readError: Error?
        let coordinator = NSFileCoordinator(filePresenter: nil)
        coordinator.coordinate(readingItemAt: url, options: [], error: &coordinationError) { readableURL in
            do {
                coordinatedData = try Data(contentsOf: readableURL, options: [.mappedIfSafe])
            } catch {
                readError = error
            }
        }
        if let coordinationError { throw coordinationError }
        if let readError { throw readError }
        guard let data = coordinatedData else {
            throw NSError(domain: "PEDINHIOS", code: 65, userInfo: [NSLocalizedDescriptionKey: "Không đọc được nội dung tệp từ Files. Hãy thử tải tệp về máy hoặc lưu vào mục Trên iPhone của tôi rồi chọn lại."])
        }
        guard data.count <= maximumFileSize else {
            throw NSError(domain: "PEDINHIOS", code: 64, userInfo: [NSLocalizedDescriptionKey: "Tệp vượt giới hạn chỉnh sửa an toàn 64 MB."])
        }
        let bytes = [UInt8](data)
        return FileReport(name: url.lastPathComponent,
                          fileExtension: url.pathExtension.isEmpty ? "Không rõ" : url.pathExtension.uppercased(),
                          size: bytes.count, formatInfo: identifyFormat(bytes: bytes), bytes: bytes,
                          printableStrings: extractStringsWithOffsets(bytes: bytes, minimumLength: 4, limit: 300))
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
                        if let offsetPreview { ScrollView(.horizontal) { Text(offsetPreview).font(.system(size: 9, design: .monospaced)).foregroundColor(.iceBlue).textSelection(.enabled) } }
                        Text("Offset là vị trí byte trong tệp. Một giá trị như 0x7729 không tự chứng minh đó là Aimlock, vị trí hay bone; cần phân tích cấu trúc và ngữ cảnh.")
                            .font(.system(size: 10)).foregroundColor(.white.opacity(0.55))
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
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.item],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let pickedURL = urls.first else {
                    status = "Chưa chọn tệp nào."
                    return
                }
                handlePickedURL(pickedURL)
            case .failure(let error):
                errorMessage = "Không mở được trình chọn tệp: \(error.localizedDescription)"
                status = "Trình chọn tệp đã trả về lỗi."
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
            offsetPreview = FileStudyService.hexDump(bytes: Array(report.bytes[start..<end]), baseOffset: start)
            errorMessage = nil
        } catch { errorMessage = error.localizedDescription }
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
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        do {
            let values = try? url.resourceValues(forKeys: [.fileSizeKey])
            if let size = values?.fileSize, size > FileStudyService.maximumFileSize {
                throw messageError("Tệp lớn hơn 64 MB. Hãy dùng tệp nhỏ hơn.")
            }
            let openedReport = try FileStudyService.inspect(url: url)
            report = openedReport
            undoBytes = nil
            offsetInput = "0x0"; patchOffset = "0x0"; offsetPreview = nil; searchHits = []
            status = "Đã mở \(url.lastPathComponent) • \(openedReport.formatInfo)"
            errorMessage = nil
        } catch {
            errorMessage = "Không đọc được tệp: \(error.localizedDescription)"
            status = "Chưa mở được tệp. Hãy thử lưu tệp vào On My iPhone rồi mở lại."
        }
    }

    private func messageError(_ message: String) -> NSError {
        NSError(domain: "PEDINHIOS", code: 3, userInfo: [NSLocalizedDescriptionKey: message])
    }
}
