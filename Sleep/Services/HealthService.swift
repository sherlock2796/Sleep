import Foundation
import HealthKit

/// Riepilogo di una notte letta dall'app Salute.
struct NightSummary: Identifiable {
    let date: Date
    var core: TimeInterval = 0
    var deep: TimeInterval = 0
    var rem: TimeInterval = 0
    var unspecified: TimeInterval = 0
    var awake: TimeInterval = 0
    var sources: Set<String> = []

    var id: Date { date }
    var asleep: TimeInterval { core + deep + rem + unspecified }
}

/// Legge dall'app Salute le fasi del sonno registrate dall'Apple Watch.
@MainActor
final class HealthService: ObservableObject {
    @Published private(set) var status = "Non collegata"
    @Published private(set) var nights: [NightSummary] = []

    private let store = HKHealthStore()

    func connect() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            status = "App Salute non disponibile su questo dispositivo"
            AppLog.shared.add("Salute: non disponibile")
            return
        }
        let read: Set<HKObjectType> = [HKCategoryType(.sleepAnalysis), HKQuantityType(.heartRate)]
        do {
            try await store.requestAuthorization(toShare: [], read: read)
            AppLog.shared.add("Salute: autorizzazione richiesta correttamente")
            await loadLastNights()
        } catch {
            status = "Errore: \(error.localizedDescription)"
            AppLog.shared.add("Salute: errore autorizzazione: \(error.localizedDescription)")
        }
    }

    func loadLastNights() async {
        let start = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.categorySample(type: HKCategoryType(.sleepAnalysis), predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.startDate)]
        )
        do {
            let samples = try await descriptor.result(for: store)
            nights = Self.summarize(samples)
            if nights.isEmpty {
                status = "Nessun dato del sonno negli ultimi 7 giorni (o accesso negato in Salute)"
            } else {
                status = "Collegata: \(nights.count) notti trovate"
            }
            AppLog.shared.add("Salute: letti \(samples.count) campioni, \(nights.count) notti")
        } catch {
            status = "Errore lettura: \(error.localizedDescription)"
            AppLog.shared.add("Salute: errore lettura: \(error.localizedDescription)")
        }
    }

    /// Raggruppa i campioni per notte. Spostando l'orario di 12 ore,
    /// una notte dalle 23 alle 7 finisce tutta sul giorno del risveglio.
    private static func summarize(_ samples: [HKCategorySample]) -> [NightSummary] {
        let calendar = Calendar.current
        var byDay: [Date: NightSummary] = [:]
        for sample in samples {
            let day = calendar.startOfDay(for: sample.startDate.addingTimeInterval(12 * 3600))
            var night = byDay[day] ?? NightSummary(date: day)
            let duration = sample.endDate.timeIntervalSince(sample.startDate)
            switch HKCategoryValueSleepAnalysis(rawValue: sample.value) {
            case .asleepCore: night.core += duration
            case .asleepDeep: night.deep += duration
            case .asleepREM: night.rem += duration
            case .asleepUnspecified: night.unspecified += duration
            case .awake: night.awake += duration
            default: continue
            }
            night.sources.insert(sample.sourceRevision.source.name)
            byDay[day] = night
        }
        return byDay.values.sorted { $0.date > $1.date }
    }
}
