import SwiftUI

@MainActor final class AppModel: ObservableObject {
    @Published var pack: ContentPack?
    @Published var state = LearnerState()
    @Published var rehearsalTopics: [RehearsalTopic] = []
    @Published var rehearsalError: String?
    @Published var timelines: [TimelineRound] = []
    @Published var timelineError: String?
    @Published var memoryPairs: [MemoryGamePair] = []
    @Published var mysteries: [MysteryRound] = []
    @Published var games: GamePack?
    @Published var gamesError: String?
    @Published var message: String?
    @Published var contentError: String?
    @Published var recoveryRequired = false
    @Published var updateMessage: String?
    @Published var stagedVersion: Int?
    @Published var rollbackVersion: Int?
    private var contentCache: ContentCache?
    @Published var audioPreviewStatus: String?
    private let sounds=SoundPlayer()
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
        #if DEBUG
        if args.contains("-ui-testing"),args.contains("-stage-test-lessons"),let cache=contentCache,let pack {
            do {
                var json=try JSONSerialization.jsonObject(with:cache.bundledData) as! [String:Any]
                json["contentVersion"]=pack.contentVersion+1
                var lessons=json["lessons"] as! [[String:Any]]
                var story=lessons[0]["story"] as! [[String:String]]
                story[0]["title"]="Updated story fixture";lessons[0]["story"]=story;json["lessons"]=lessons
                if args.contains("-test-library-without-favorites") {
                    json["roadmaps"]=(json["roadmaps"] as! [[String:Any]]).filter {!["roadmap-xolos","roadmap-madrid"].contains($0["key"] as! String)}
                }
                try cache.stage(JSONSerialization.data(withJSONObject:json),active:pack)
                refreshUpdateStatus();updateMessage="Test lesson version is waiting for next launch."
            } catch {updateMessage=error.localizedDescription}
        }
        #endif
    }
    func load() {
        do {
            guard let url = Bundle.main.url(forResource:"starter-en",withExtension:"json") else { throw ContentError.invalid("The starter lessons are missing.") }
            let bundledData=try Data(contentsOf:url)
            let contentBase=store.directory.deletingLastPathComponent().appendingPathComponent(store.directory.lastPathComponent == "UITest" ? "ContentUITest" : "FoxlingoContent")
            contentCache=try ContentCache(directory:contentBase,bundledData:bundledData)
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-reset-test-state") {try? FileManager.default.removeItem(at:contentBase)}
            #endif
            do {
                let result=try contentCache!.load();pack=result.pack;updateMessage=result.notice
            } catch {pack=try ContentPack.load(bundledData);updateMessage="Saved lesson updates could not be opened. Bundled lessons are available: \(error.localizedDescription)"}
            refreshUpdateStatus()
        } catch { contentError = error.localizedDescription; return }
        do {
            guard let url=Bundle.main.url(forResource:"games-en",withExtension:"json") else {throw ContentError.invalid("Game content is missing.")}
            games=try GamePack.load(Data(contentsOf:url))
        } catch { gamesError=error.localizedDescription }
        if let pack,let url=Bundle.main.url(forResource:"mystery-en",withExtension:"json"),let data=try? Data(contentsOf:url) {
            mysteries=(try? MysteryDeck.load(data,pack:pack)) ?? []
        }
        if let pack,let url=Bundle.main.url(forResource:"memory-en",withExtension:"json"),let data=try? Data(contentsOf:url) {
            memoryPairs=(try? MemoryGameDeck.load(data,pack:pack)) ?? []
        }
        if let pack {
            do {
                guard let url=Bundle.main.url(forResource:"timeline-en",withExtension:"json") else {throw ContentError.invalid("Timeline content is missing.")}
                let data=try Data(contentsOf:url)
                timelines=try TimelineDeck.load(data,pack:pack)
                if timelines.count < (try JSONDecoder().decode([TimelineDefinition].self,from:data)).count {timelineError="Some stories need refreshed evidence. Available timelines are ready to play."}
            } catch {timelineError=error.localizedDescription}
        }
        if let pack {
            do {
                guard let url=Bundle.main.url(forResource:"rehearsal-en",withExtension:"json") else {throw ContentError.invalid("Rehearsal stories are missing.")}
                rehearsalTopics=try RehearsalTopic.load(Data(contentsOf:url),pack:pack)
            } catch {rehearsalError=error.localizedDescription}
        }
        do {
            let restored = try store.loadWithNotice()
            state = restored.state ?? LearnerState()
            #if DEBUG
            let args=ProcessInfo.processInfo.arguments
            if args.contains("-ui-testing"),let i=args.firstIndex(of:"-test-streak-days"),args.count > i+1,let count=Int(args[i+1]),(1...64).contains(count) {
                for offset in (0..<count).reversed() {state.streak.record(now.addingTimeInterval(-Double(offset)*86400),zone:state.homeTimeZone)}
            }
            #endif
            state.reconcileRehearsals(rehearsalTopics,now:now)
            message = restored.notice
            if (state.rehearsals?.discardedDrafts ?? 0) > 0 {message="A rehearsal draft could not be opened. Your learning history is preserved."}
            if let pack {
                if state.installedContentVersion != pack.contentVersion {
                    let previous=contentCache?.previousPack(version:state.installedContentVersion ?? contentCache?.bundled.contentVersion)
                    if restored.state != nil {try store.archiveBeforeContentUpdate(state)}
                    let retired=state.migrateContent(from:previous,to:pack,now:now)
                    if retired > 0 {updateMessage="Updated lessons are ready. \(retired) unfinished \(retired == 1 ? "lesson will" : "lessons will") restart; previous attempts are archived. Earned cards are preserved."}
                } else {state.reconcile(pack,now:now)}
            }
            if restored.state != nil && restored.notice == nil {save()}
        } catch { recoveryRequired = true; message = error.localizedDescription }
    }
    func recordGameGap(game: String,context: String,subjects: [UUID]=[],facts: [UUID]=[],names: [String]=[],assets: [String]=[],playerIDs: [String]=[]) {
        guard let pack else {return}
        var ids=Set(subjects)
        for name in names {
            let normalized=Recall.normalize(name)
            let matches=pack.entities.filter {$0.aliases.map(Recall.normalize).contains(normalized) || Recall.normalize($0.name) == normalized}
            if matches.count == 1 {ids.insert(matches[0].id)}
        }
        for asset in assets {
            let matches=pack.entities.filter {$0.imageAsset == asset}
            if matches.count == 1 {ids.insert(matches[0].id)}
        }
        state.recordPracticeGap(PracticeGap(game:game,context:context,subjectIDs:ids.sorted {$0.uuidString < $1.uuidString},factIDs:facts,timestamp:now,referenceNames:names,referenceAssets:assets,referencePlayerIDs:playerIDs));save()
    }
    func save() {
        guard !recoveryRequired else { return }
        if let pack {state.initializeSavedRoadmaps(pack);state.captureCardAchievements(pack)}
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
    var updateAddress: String {
        get {guard let cache=contentCache else {return ""};return (try? String(contentsOf:cache.directory.appendingPathComponent("feed.txt"),encoding:.utf8)) ?? ""}
    }
    func saveUpdateAddress(_ value: String) throws {
        let address=value.trimmingCharacters(in:.whitespacesAndNewlines)
        if !address.isEmpty {_ = try ContentUpdateRules.https(address)}
        guard let cache=contentCache else {throw ContentError.invalid("Lesson storage is unavailable.")}
        try FileManager.default.createDirectory(at:cache.directory,withIntermediateDirectories:true)
        try address.write(to:cache.directory.appendingPathComponent("feed.txt"),atomically:true,encoding:.utf8)
    }
    private func refreshUpdateStatus() {stagedVersion=contentCache?.pendingVersion;rollbackVersion=contentCache?.previousVersion}
    func importLessons(_ data: Data) async throws {
        guard let cache=contentCache,let pack else {throw ContentError.invalid("Lesson storage is unavailable.")}
        let work=Task.detached {try Task.checkCancellation();try cache.stage(data,active:pack)}
        try await withTaskCancellationHandler(operation:{try await work.value},onCancel:{work.cancel()})
        refreshUpdateStatus()
        updateMessage="Version \(stagedVersion ?? 0) is waiting. Quit Foxlingo from the app switcher, then reopen it to use this version."
    }
    func checkForLessons(_ address: String) async throws {
        guard let cache=contentCache else {throw ContentError.invalid("Lesson storage is unavailable.")}
        try saveUpdateAddress(address)
        let data=try await ContentDownload.fetch(manifestURL:address.trimmingCharacters(in:.whitespacesAndNewlines),bundled:cache.bundled)
        try Task.checkCancellation()
        let fetched=try ContentPack.load(data)
        if fetched.contentVersion == pack?.contentVersion {updateMessage="Your lesson library is up to date.";return}
        try await importLessons(data)
    }
    func rollbackLessons() throws {
        guard let cache=contentCache,let pack else {throw ContentError.invalid("Lesson storage is unavailable.")}
        try cache.stageRollback(active:pack);refreshUpdateStatus()
        updateMessage="Previous lesson version \(stagedVersion ?? 0) will return after you quit Foxlingo from the app switcher and reopen it. Your learning history stays."
    }
    func cancelLessonUpdate() throws {try contentCache?.cancelPending();refreshUpdateStatus();updateMessage="The waiting update was removed. Installed lessons stay available."}
    func select(_ id: UUID) {state.selectClub(id);save()}
    func selectSubject(_ id: UUID) {if let pack,let roadmap=pack.roadmaps.first(where:{$0.entityID == id}) {state.selectRoadmap(roadmap,pack:pack);save()}}
    func setRoadmapSaved(_ roadmap: Roadmap,saved: Bool) {
        guard let pack else {return}
        state.setRoadmapSaved(roadmap.id,saved:saved,pack:pack);save()
        if state.haptics {UISelectionFeedbackGenerator().selectionChanged()}
        UIAccessibility.post(notification:.announcement,argument:saved ? "Saved to My roadmaps" : "Removed from My roadmaps. Your learning is preserved.")
    }
    var roadmap: Roadmap? {pack.flatMap {state.activeRoadmap($0)}}
    var studyPlan: DailyStudyPlan? {pack.map {DailyStudyPlan.make(pack:$0,state:state,now:now,limit:state.preferredSessionSize ?? 10)}}
    var due: [Objective] {guard let pack,let studyPlan else {return []};return studyPlan.dueObjectiveIDs.map(pack.objective)}
    func respond(_ correct: Bool,event: SoundEvent?=nil) {
        if state.haptics { UINotificationFeedbackGenerator().notificationOccurred(correct ? .success : .error) }
        playSound(event ?? (correct ? .correct : .incorrect))
    }
    func playSound(_ event: SoundEvent) {if state.sound {sounds.play(event.asset)}}
    func stopSounds() {sounds.stop();audioPreviewStatus=nil}
    func previewSound(_ asset: SoundAsset) {
        guard state.sound else {return}
        audioPreviewStatus=sounds.play(asset,preview:true) ? "Previewed \(asset.title)." : "This sound could not be played."
    }

}
