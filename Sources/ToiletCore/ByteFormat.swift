import Foundation

public enum ByteFormat {
    /// Decimal units so "1 GB" matches the 1_000_000_000 confirmation threshold.
    public static func string(_ bytes: UInt64) -> String {
        if bytes < 1000 {
            return "\(bytes) bytes"
        }
        let units = ["KB", "MB", "GB", "TB"]
        var value = Double(bytes)
        var unitIndex = -1
        while value >= 1000 && unitIndex < units.count - 1 {
            value /= 1000
            unitIndex += 1
        }
        let unit = units[max(0, unitIndex)]
        if value >= 10 || unit == "KB" {
            return String(format: "%.0f %@", value, unit)
        }
        return String(format: "%.1f %@", value, unit)
    }
}
