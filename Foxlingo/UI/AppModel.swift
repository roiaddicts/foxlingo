import SwiftUI
import AudioToolbox

@MainActor final class AppModel: ObservableObject {
    @Published var pack: ContentPack?
    @Published var state = LearnerState()
    @Published var games: GamePack?
    @Published var gamesError: String?
    @Published var message: String?
    @Published var contentError: String?
    @Published var recoveryRequired = false
    private let store: StateStore
    var now: Date {
        #if DEBUG
        if let i = ProcessInfo.processInfo.arguments.firstIndex(of:"-test-now"), ProcessInfo.processInfo.arguments.count > i + 1, let t = Double(ProcessInfo.processInfo.arguments[i+1]) { return Date(timeIntervalSince1970:t) }
        #endif
        return Date()
    }
    init() {
        let base = FileManager.default.urls(for:.applicationSupportDirectory,in:.userDomainMask)[0].appendingPathComponent("Foxlingo")
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        store = StateStore(directory:args.contains("-ui-testing") ? base.appendingPathComponent("UITest") : base)
        if args.contains("-reset-test-state") { try? FileManager.default.removeItem(at:store.directory) }
        #else
        store = StateStore(directory:base)
        #endif
        load()
    }
    func load() {
        do {
            guard let url = Bundle.main.url(forResource:"starter-en",withExtension:"json") else { throw ContentError.invalid("The starter lessons are missing.") }
            pack = try FileContentRepository(url:url).load()
        } catch { contentError = error.localizedDescription; return }
        do {
            guard let url=Bundle.main.url(forResource:"games-en",withExtension:"json") else {throw ContentError.invalid("Game content is missing.")}
            games=try GamePack.load(Data(contentsOf:url))
        } catch { gamesError=error.localizedDescription }
        do {
            let restored = try store.loadWithNotice()
            state = restored.state ?? LearnerState()
            message = restored.notice
            if let pack { state.reconcile(pack,now:now) }
            if restored.state != nil && restored.notice == nil {save()}
        } catch { recoveryRequired = true; message = error.localizedDescription }
    }
    func save() {
        guard !recoveryRequired else { return }
        if let pack {state.captureCardAchievements(pack)}
        do { try store.save(state) } catch { message = "Progress could not be saved: \(error.localizedDescription)" }
    }
    func reset() {
        do {
            // Preserve existing saves before an explicit reset.
            if FileManager.default.fileExists(atPath:store.directory.path) {
                let archive = store.directory.deletingLastPathComponent().appendingPathComponent("Foxlingo-archive-\(UUID().uuidString)")
                try FileManager.default.moveItem(at:store.directory,to:archive)
            }
            state = LearnerState(); recoveryRequired = false; message = nil; save()
        } catch { message = error.localizedDescription }
    }
    func select(_ id: UUID) {state.selectClub(id);save()}
    func selectSubject(_ id: UUID) {if let pack,let roadmap=pack.roadmaps.first(where:{$0.entityID == id}) {state.selectRoadmap(roadmap,pack:pack);save()}}
    var roadmap: Roadmap? {pack.flatMap {state.activeRoadmap($0)}}
    var studyPlan: DailyStudyPlan? {pack.map {DailyStudyPlan.make(pack:$0,state:state,now:now,limit:state.preferredSessionSize ?? 10)}}
    var due: [Objective] {guard let pack,let studyPlan else {return []};return studyPlan.dueObjectiveIDs.map(pack.objective)}
    func respond(_ correct: Bool) {
        if state.haptics { UINotificationFeedbackGenerator().notificationOccurred(correct ? .success : .error) }
        if state.sound { AudioServicesPlaySystemSound(correct ? 1104 : 1053) }
    }
}
