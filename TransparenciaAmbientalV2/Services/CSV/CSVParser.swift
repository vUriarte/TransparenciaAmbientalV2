import Foundation

enum CSVParser {
    static func parseCSV(_ originalText: String) -> (headers: [String], rows: [[String: String]]) {
        var text = originalText
        if text.hasPrefix("\u{FEFF}") {
            text.removeFirst()
        }

        let lines = text.split(whereSeparator: \.isNewline).map(String.init)
        guard let headerLine = lines.first else { return ([], []) }
        let headersRaw = parseCSVLine(headerLine)
        let headers = headersRaw.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        var rows: [[String: String]] = []
        for line in lines.dropFirst() {
            let fieldsRaw = parseCSVLine(line)
            let padded = fieldsRaw + Array(repeating: "", count: max(0, headers.count - fieldsRaw.count))
            var dict: [String: String] = [:]
            for (i, h) in headers.enumerated() {
                if i < padded.count {
                    dict[h] = padded[i].trimmingCharacters(in: .whitespacesAndNewlines)
                } else {
                    dict[h] = ""
                }
            }
            rows.append(dict)
        }
        return (headers, rows)
    }

    private static func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        var i = line.startIndex

        while i < line.endIndex {
            let ch = line[i]
            if ch == "\"" {
                if inQuotes {
                    let next = line.index(after: i)
                    if next < line.endIndex && line[next] == "\"" {
                        current.append("\"")
                        i = next
                    } else {
                        inQuotes = false
                    }
                } else {
                    inQuotes = true
                }
            } else if ch == "," && !inQuotes {
                result.append(current)
                current.removeAll(keepingCapacity: true)
            } else {
                current.append(ch)
            }
            i = line.index(after: i)
        }
        result.append(current)
        return result
    }
}
