import AVFoundation
import UIKit

/// Ascolta il microfono e misura il livello sonoro, anche a schermo spento.
/// Ogni minuto scrive nel registro il picco, lo stato dell'app e la batteria:
/// serve a verificare che l'ascolto notturno in background funzioni.
@MainActor
final class SoundMeter: ObservableObject {
    @Published private(set) var isRunning = false
    /// Livello in dBFS: 0 è il massimo, valori più negativi sono più silenziosi.
    @Published private(set) var level: Float = -160

    private let engine = AVAudioEngine()
    private var startedAt: Date?
    private var minuteStart = Date()
    private var minutePeak: Float = -160
    private var observers: [NSObjectProtocol] = []

    var normalizedLevel: Double {
        Double(min(max((level + 80) / 80, 0), 1))
    }

    init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let center = NotificationCenter.default
        observers.append(center.addObserver(
            forName: AVAudioSession.interruptionNotification, object: nil, queue: .main
        ) { [weak self] note in
            let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt ?? 0
            let began = AVAudioSession.InterruptionType(rawValue: raw) == .began
            MainActor.assumeIsolated { self?.handleInterruption(began: began) }
        })
        observers.append(center.addObserver(
            forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.handleConfigurationChange() }
        })
    }

    func toggle() async {
        if isRunning {
            stop()
        } else {
            await start()
        }
    }

    func start() async {
        guard await AVAudioApplication.requestRecordPermission() else {
            AppLog.shared.add("Microfono: permesso negato. Abilitalo in Impostazioni > Sleep.")
            return
        }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.mixWithOthers, .defaultToSpeaker])
            try session.setActive(true)
            try startEngine()
            isRunning = true
            startedAt = Date()
            minuteStart = Date()
            minutePeak = -160
            AppLog.shared.add("Ascolto avviato")
        } catch {
            AppLog.shared.add("Ascolto: errore all'avvio: \(error.localizedDescription)")
        }
    }

    func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        isRunning = false
        level = -160
        if let startedAt {
            let minutes = Int(Date().timeIntervalSince(startedAt) / 60)
            AppLog.shared.add("Ascolto fermato dopo \(minutes) minuti")
        }
        startedAt = nil
    }

    private func startEngine() throws {
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        guard format.sampleRate > 0 else {
            throw NSError(domain: "SoundMeter", code: 1, userInfo: [NSLocalizedDescriptionKey: "Microfono non disponibile"])
        }
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 4096, format: format, block: Self.makeTap { [weak self] db in
            Task { @MainActor in self?.handle(db) }
        })
        engine.prepare()
        try engine.start()
    }

    private func handle(_ db: Float) {
        level = db
        minutePeak = max(minutePeak, db)
        guard Date().timeIntervalSince(minuteStart) >= 60 else { return }
        let state = UIApplication.shared.applicationState == .background ? "background" : "primo piano"
        let battery = UIDevice.current.batteryLevel
        let batteryText = battery >= 0 ? "\(Int(battery * 100))%" : "?"
        AppLog.shared.add(String(format: "Minuto: picco %.0f dB, app in %@, batteria %@", minutePeak, state, batteryText))
        minuteStart = Date()
        minutePeak = -160
    }

    private func handleInterruption(began: Bool) {
        guard isRunning else { return }
        if began {
            AppLog.shared.add("Ascolto interrotto (es. telefonata o sveglia)")
        } else {
            AppLog.shared.add("Interruzione terminata, riavvio l'ascolto")
            restart()
        }
    }

    private func handleConfigurationChange() {
        guard isRunning else { return }
        AppLog.shared.add("Cambio configurazione audio, riavvio l'ascolto")
        restart()
    }

    private func restart() {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            try startEngine()
        } catch {
            AppLog.shared.add("Riavvio ascolto fallito: \(error.localizedDescription)")
        }
    }

    /// Crea il blocco che riceve l'audio dal microfono: gira su un thread audio, non sul main thread.
    nonisolated private static func makeTap(_ onLevel: @escaping @Sendable (Float) -> Void) -> AVAudioNodeTapBlock {
        return { buffer, _ in onLevel(decibels(of: buffer)) }
    }

    nonisolated static func decibels(of buffer: AVAudioPCMBuffer) -> Float {
        guard let channels = buffer.floatChannelData, buffer.frameLength > 0 else { return -160 }
        let samples = channels[0]
        let count = Int(buffer.frameLength)
        var sum: Float = 0
        for i in 0..<count {
            sum += samples[i] * samples[i]
        }
        let rms = (sum / Float(count)).squareRoot()
        return rms > 0 ? max(20 * log10(rms), -160) : -160
    }
}
