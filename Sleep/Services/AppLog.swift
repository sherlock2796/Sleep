import Foundation

/// Registro diagnostico salvato su file, consultabile ed esportabile dall'app.
@MainActor
final class AppLog: ObservableObject {
    static let shared = AppLog()

    private static let maxLines = 2000

    @Published private(set) var lines: [String] = []
    let fileURL: URL
    private let formatter: DateFormatter

    private init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = documents.appendingPathComponent("diagnostica.log")
        formatter = DateFormatter()
        formatter.dateFormat = "dd/MM HH:mm:ss"
        if let text = try? String(contentsOf: fileURL, encoding: .utf8) {
            lines = Array(text.split(separator: "\n").map(String.init).suffix(Self.maxLines))
        }
    }

    func add(_ message: String) {
        lines.append("\(formatter.string(from: Date())) \(message)")
        if lines.count > Self.maxLines {
            lines.removeFirst(lines.count - Self.maxLines)
        }
        try? (lines.joined(separator: "\n") + "\n").write(to: fileURL, atomically: true, encoding: .utf8)
    }

    func clear() {
        lines.removeAll()
        try? FileManager.default.removeItem(at: fileURL)
        add("Registro svuotato")
    }
}
