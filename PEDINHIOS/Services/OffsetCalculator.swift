import Foundation

/// Calculator for educational examples only.
/// It does not inspect or modify another app's memory.
enum OffsetCalculator {
    static func parseHex(_ input: String) throws -> UInt64 {
        let cleaned = input.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "0x", with: "")
            .replacingOccurrences(of: "0X", with: "")
        guard !cleaned.isEmpty, let value = UInt64(cleaned, radix: 16) else {
            throw LabError.invalidHex
        }
        return value
    }

    static func add(base: UInt64, offset: UInt64) throws -> UInt64 {
        let result = base.addingReportingOverflow(offset)
        guard !result.overflow else { throw LabError.overflow }
        return result.partialValue
    }

    static func hex(_ value: UInt64) -> String {
        "0x" + String(value, radix: 16, uppercase: true)
    }
}
