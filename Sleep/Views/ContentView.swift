import SwiftUI

struct ContentView: View {
    @StateObject private var meter = SoundMeter()
    @StateObject private var health = HealthService()
    @ObservedObject private var log = AppLog.shared

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Versione di prova: verifica che microfono, ascolto a schermo spento e app Salute funzionino.")
                        .font(.callout)
                }

                Section("Microfono") {
                    HStack {
                        Text("Livello")
                        Spacer()
                        Text(meter.isRunning ? String(format: "%.0f dB", meter.level) : "—")
                            .monospacedDigit()
                    }
                    ProgressView(value: meter.normalizedLevel)
                    Button(meter.isRunning ? "Ferma ascolto" : "Avvia ascolto") {
                        Task { await meter.toggle() }
                    }
                    Text("Avvia l'ascolto, blocca il telefono per qualche minuto, poi controlla nel registro che le righe \"Minuto\" siano continuate con \"app in background\".")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Apple Watch e Salute") {
                    Text(health.status)
                    Button("Collega app Salute") {
                        Task { await health.connect() }
                    }
                    ForEach(health.nights) { night in
                        NightRow(night: night)
                    }
                }

                Section("Registro diagnostica") {
                    ShareLink(item: log.fileURL) {
                        Label("Esporta registro", systemImage: "square.and.arrow.up")
                    }
                    Button("Svuota registro", role: .destructive) {
                        log.clear()
                    }
                    ForEach(Array(log.lines.suffix(100).reversed().enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.caption.monospaced())
                    }
                }
            }
            .navigationTitle("Sleep")
        }
    }
}

private struct NightRow: View {
    let night: NightSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(night.date, format: .dateTime.weekday(.wide).day().month())
                .font(.headline)
            Text("Dormito \(Self.format(night.asleep)) · sveglio \(Self.format(night.awake))")
            Text("Profondo \(Self.format(night.deep)) · REM \(Self.format(night.rem)) · Leggero \(Self.format(night.core))")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text("Fonte: \(night.sources.sorted().joined(separator: ", "))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private static func format(_ interval: TimeInterval) -> String {
        let minutes = Int(interval / 60)
        return "\(minutes / 60)h \(String(format: "%02d", minutes % 60))m"
    }
}
