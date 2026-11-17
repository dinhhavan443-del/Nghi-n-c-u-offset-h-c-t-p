import Foundation
import UniformTypeIdentifiers

/// Reads basic metadata from a user-selected file URL.
/// Full IPA extraction/signature verification is intentionally not performed here.
struct IPAInspector {
    static func describe(url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        return """
        Tên tệp: \(url.lastPathComponent)
        Định dạng: \(ext.isEmpty ? "Không rõ" : ext.uppercased())
        Kích thước: \(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file))
        """
    }
}
