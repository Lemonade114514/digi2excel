import Foundation

/// CSV file parser that reads CSV into a 2D string array
/// Handles the BOM character and preserves empty cells
struct CSVParser {
    
    /// Parse a CSV file at the given URL into a 2D string array
    /// - Parameter url: File URL of the CSV
    /// - Returns: 2D array of strings [row][col]
    static func parse(url: URL) throws -> [[String]] {
        let data = try Data(contentsOf: url)
        
        // Try UTF-8 with BOM handling
        var string: String
        if data.starts(with: [0xEF, 0xBB, 0xBF]) {
            string = String(data: data.dropFirst(3), encoding: .utf8) ?? ""
        } else {
            string = String(data: data, encoding: .utf8) ?? ""
        }
        
        // Remove any remaining BOM characters
        string = string.replacingOccurrences(of: "\u{FEFF}", with: "")
        
        // Split into lines (handles both \n and \r\n)
        let rawLines = string.components(separatedBy: "\n")
        
        return rawLines.compactMap { line -> [String]? in
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { return nil }
            return parseCSVLine(trimmed)
        }
    }
    
    /// Parse a single CSV line into an array of strings
    private static func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var currentField = ""
        var inQuotes = false
        let chars = [Character](line)
        var i = 0
        
        while i < chars.count {
            let char = chars[i]
            
            if char == "\"" {
                if inQuotes && i + 1 < chars.count && chars[i + 1] == "\"" {
                    // Escaped quote ""
                    currentField.append("\"")
                    i += 2
                } else {
                    inQuotes.toggle()
                    i += 1
                }
            } else if char == "," && !inQuotes {
                fields.append(currentField)
                currentField = ""
                i += 1
            } else {
                currentField.append(char)
                i += 1
            }
        }
        
        fields.append(currentField)
        return fields
    }
}
