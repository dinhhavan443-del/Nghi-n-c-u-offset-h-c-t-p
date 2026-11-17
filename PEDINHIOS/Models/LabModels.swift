import Foundation

struct MemoryRegionExample: Identifiable {
    let id = UUID()
    let name: String
    let baseAddress: UInt64
    let offset: UInt64

    var calculatedAddress: UInt64? {
        baseAddress.addingReportingOverflow(offset).overflow ? nil : baseAddress + offset
    }
}

enum LabError: LocalizedError {
    case invalidHex
    case overflow

    var errorDescription: String? {
        switch self {
        case .invalidHex: return "Nhập số hex hợp lệ, ví dụ 0x10000000."
        case .overflow: return "Phép tính vượt giới hạn UInt64."
        }
    }
}
