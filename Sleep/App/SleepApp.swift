import SwiftUI

@main
struct SleepApp: App {
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        AppLog.shared.add("Avvio app, versione \(version) (build \(build))")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active: AppLog.shared.add("App in primo piano")
            case .inactive: AppLog.shared.add("App inattiva")
            case .background: AppLog.shared.add("App in background")
            @unknown default: break
            }
        }
    }
}
