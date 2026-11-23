import SwiftUI

@main struct FoxlingoApp: App {
    @StateObject private var model = AppModel()
    var body: some Scene { WindowGroup { RootView().environmentObject(model).tint(Palette.brand).preferredColorScheme(.light) } }
}
struct RootView: View {
    @EnvironmentObject var model: AppModel
    @State private var settings = false
    @Environment(\.scenePhase) private var scenePhase
    var body: some View {
        Group {
            if model.isLoading {
                VStack(spacing: 20) {
                    Leopard().frame(width: 88, height: 100)
                    ProgressView("Preparing your football stories…")
                }.frame(maxWidth: .infinity, maxHeight: .infinity).journal()
                    .accessibilityIdentifier("startup-loading")
            } else if let error = model.contentError {
                ContentUnavailableView("Lessons unavailable",systemImage:"book.closed",description:Text(error)).journal()
            } else if model.recoveryRequired {
                NavigationStack { VStack(spacing:24) { Leopard().frame(height:110); Text("Let's recover your progress").font(.title.bold()); Text(model.message ?? "Saved progress needs attention."); PrimaryButton(title:"Retry",action:{model.recoveryRequired=false;model.load()}); Button("Settings") { settings=true } }.padding(24).journal() }
            } else if model.state.selectedClub == nil && !(model.pack?.roadmaps.contains {$0.id == model.state.selectedRoadmapID} ?? false), let pack = model.pack {
                WelcomeView(pack:pack)
            } else {
                TabView {
                    NavigationStack { LearnView().toolbar { Button {settings=true} label:{Image(systemName:"gearshape")}.accessibilityLabel("Settings") } }.tabItem { Label("Learn",systemImage:"map") }
                    NavigationStack { PracticeHome().toolbar { Button {settings=true} label:{Image(systemName:"gearshape")}.accessibilityLabel("Settings") } }.tabItem { Label("Practice",systemImage:"arrow.clockwise") }
                    NavigationStack { GamesHome() }.tabItem { Label("Games",systemImage:"sportscourt") }
                    NavigationStack { AlbumView().toolbar { Button {settings=true} label:{Image(systemName:"gearshape")}.accessibilityLabel("Settings") } }.tabItem { Label("Album",systemImage:"rectangle.stack") }
                }
            }
        }.modifier(StreakSuccessOverlay())
        .onChange(of: model.state.streak.activeDays) { previous, current in
            let today = StreakState.dayKey(model.now, zone: model.state.homeTimeZone)
            if current.contains(today) && !previous.contains(today) {
                var prior = model.state.streak
                prior.activeDays = previous
                model.streakSuccess = StreakSuccess(days: model.state.streak.current(at: model.now, zone: model.state.homeTimeZone),
                                                   previousDays: prior.current(at: model.now, zone: model.state.homeTimeZone))
            }
        }.environment(\.streakFlameAnimationsEnabled,!settings && model.streakSuccess == nil).onChange(of:scenePhase) { if scenePhase == .active {model.objectWillChange.send();Task {await model.refreshDailyIfNeeded()}} else {model.stopSounds()} }.onChange(of:model.state.sound) {if !model.state.sound {model.stopSounds()}}.sheet(isPresented:$settings) { NavigationStack { SettingsView() } }
        .alert("Progress notice",isPresented:Binding(get:{model.message != nil && !model.recoveryRequired},set:{if !$0 {model.message=nil}})) { Button("OK") { model.message=nil } } message:{Text(model.message ?? "")}
    }
}
struct WelcomeView: View {
    let pack: ContentPack
    @EnvironmentObject var model: AppModel
    private var startingClubs: [Entity] {
        let favorites=pack.clubRoadmaps.map {pack.entity($0.entityID)}.filter {$0.key == "entity-xolos" || $0.key == "entity-madrid"}
        return favorites.isEmpty ? pack.clubRoadmaps.prefix(2).map {pack.entity($0.entityID)} : favorites
    }
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:22) {
                HStack { Text("foxlingo").font(.system(.largeTitle,design:.rounded,weight:.black)); Spacer(); Image(systemName:"soccerball").font(.title2) }
                Leopard().frame(height:130).frame(maxWidth:.infinity)
                Eyebrow(text:"Your football story starts here")
                Text(startingClubs.count == 2 && startingClubs.allSatisfy({["entity-xolos","entity-madrid"].contains($0.key)}) ? "Two favorite clubs.\nA world to learn." : "Choose a club.\nA world to learn.").font(.system(.largeTitle,design:.rounded,weight:.bold))
                Text("Short stories, playful practice, and a collection that grows with what you remember.").foregroundStyle(Palette.muted)
                Text("Where shall we start?").font(.headline)
                ForEach(startingClubs) { club in
                    Button { model.select(club.id) } label: {
                        HStack(spacing:16) { ClubMark(club:club,size:52); VStack(alignment:.leading,spacing:4) { Text(club.visual == "XT" ? "Xolos" : club.name).font(.title3.bold()); Text(club.key == "entity-xolos" ? "Club Tijuana · Mexico" : club.key == "entity-madrid" ? "Real Madrid · Spain" : "Start the club story").font(.subheadline).foregroundStyle(Palette.muted) }; Spacer(); Image(systemName:"arrow.right") }.padding(16).background(.white.opacity(0.7),in:RoundedRectangle(cornerRadius:20))
                    }.buttonStyle(.plain).accessibilityIdentifier("choose-\(club.visual)")
                }
                Text("You can switch clubs anytime. About 3 minutes per lesson.").font(.footnote).foregroundStyle(Palette.muted)
            }.padding(24)
        }.journal()
    }
}
struct LearnView: View {
    @EnvironmentObject var model: AppModel
    @State private var activeLesson: Lesson?
    @State private var practiceRoute: PracticeRoute?
    @State private var clubLibrary=false
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduced
    var body: some View {
        ScrollView {
            if let pack=model.pack, let r=model.roadmap {
                let club=pack.entity(r.entityID),progress=RoadmapProgress.make(roadmap:r,pack:pack,state:model.state)
                VStack(alignment:.leading,spacing:26) {
                    HStack { Text("foxlingo").font(.system(.title,design:.rounded,weight:.black)); Spacer(); StreakBadge(days:model.state.streak.current(at:model.now,zone:model.state.homeTimeZone)) }
                    if typeSize.isAccessibilitySize {
                        VStack(alignment:.leading,spacing:16) {
                            HStack(spacing:14) {ClubMark(club:club);Eyebrow(text:club.type == "player" ? "Player starter" : club.type == "competition" ? "Competition foundations" : "Your roadmap").dynamicTypeSize(...DynamicTypeSize.xxxLarge)}
                            Text(club.visual == "XT" ? "Xolos" : club.name).font(.title2.bold())
                        }
                    } else {
                    HStack(spacing:14) { ClubMark(club:club); VStack(alignment:.leading,spacing:4) { Eyebrow(text:club.type == "player" ? "Player starter" : club.type == "competition" ? "Competition foundations" : "Your roadmap").dynamicTypeSize(...DynamicTypeSize.xxxLarge); Text(club.visual == "XT" ? "Xolos" : club.name).font(.largeTitle.bold()) }; Spacer() }
                    }
                    Button {clubLibrary=true} label:{Label("Choose roadmap",systemImage:"arrow.left.arrow.right").font(.subheadline.bold()).frame(minHeight:44)}.buttonStyle(PressFeedback()).accessibilityIdentifier("switch-club")
                    RoadmapSaveButton(roadmap:r,showsTitle:true,identifierPrefix:"active-toggle")
                    HStack {Text("\(progress.completedRequired) of \(progress.requiredLessonIDs.count) \(club.type == "player" ? "starter lessons" : club.type == "competition" ? "foundation lessons" : "lessons") complete").accessibilityIdentifier("roadmap-progress").contentTransition(.numericText()).animation(reduced ? nil : .easeInOut(duration:0.2),value:progress.completedRequired).font(.subheadline).foregroundStyle(Palette.muted);Spacer();Leopard().frame(width:52,height:60)}
                    if let summary=r.summary {Text(summary).font(.subheadline).foregroundStyle(Palette.muted)}
                    DailyPlanView(pack:pack,openLesson:{activeLesson=$0},openPractice:{practiceRoute=$0})
                    RoadmapChapters(roadmap:r,pack:pack,openLesson:{activeLesson=$0})
                    Text(club.type == "player" ? "Club context stays optional. Scheduled recall strengthens the connections you learn." : club.type == "competition" ? "A foundation in this competition. Historical and season-specific facts keep their scope." : "Every club has a story. You're building yours.").font(.footnote).foregroundStyle(Palette.muted).padding(.bottom,20)
                }.padding(24)
            }
        }.journal().navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented:$clubLibrary) {NavigationStack {ClubLibrary(onSelect:{id in model.selectSubject(id);clubLibrary=false},onClose:{clubLibrary=false},allowPlayers:true)}}
            .fullScreenCover(item:$activeLesson) { lesson in NavigationStack { LessonView(lesson:lesson) } }
            .navigationDestination(item:$practiceRoute) { r in if let p=model.pack {PracticeSession(objectives:r.objectiveIDs.map(p.objective),dueMode:r.dueMode)} }
    }
}

struct RoadmapChapters: View {
    let roadmap: Roadmap
    let pack: ContentPack
    let openLesson: (Lesson) -> Void
    @EnvironmentObject private var model: AppModel
    var body: some View {
        ForEach(Array(roadmap.chapters.enumerated()),id:\.element.id) {index,chapter in
            VStack(alignment:.leading,spacing:18) {
                HStack {Eyebrow(text:chapter.isOptional == true ? "Optional club context" : "Chapter \(index+1)");Rectangle().fill(Palette.ink.opacity(0.12)).frame(height:1)}
                Text(chapter.title).font(.title2.bold())
                if let note=chapter.note {Text(note).font(.subheadline).foregroundStyle(Palette.muted)}
                if chapter.isOptional == true {Text("\(chapter.lessonIDs.filter {model.state.completedLessons.contains($0)}.count) of \(chapter.lessonIDs.count) optional lessons complete").font(.caption).foregroundStyle(Palette.muted).accessibilityIdentifier("roadmap-optional-progress")}
                ForEach(Array(chapter.lessonIDs.enumerated()),id:\.element) {n,id in
                    let lesson=pack.lesson(id),done=model.state.completedLessons.contains(id),started=model.state.resumes[id] != nil
                    Button {openLesson(lesson)} label:{
                        HStack(spacing:18) {
                            VStack(spacing:0) {Circle().fill(done ? Palette.brand : .white).frame(width:52,height:52).overlay {Image(systemName:done ? "checkmark" : started ? "play.fill" : "book.fill").foregroundStyle(done ? .white : Palette.brand)};if n < chapter.lessonIDs.count-1 {Rectangle().fill(Palette.brand.opacity(0.2)).frame(width:3,height:22)}}
                            VStack(alignment:.leading,spacing:5) {Text(lesson.title).font(.headline);Text(done ? "Completed · Play again" : started ? "Continue lesson" : lesson.subtitle).font(.subheadline).foregroundStyle(Palette.muted)}.padding(.bottom,n < chapter.lessonIDs.count-1 ? 22 : 0)
                            Spacer();Image(systemName:"chevron.right").font(.caption.bold()).padding(.bottom,n < chapter.lessonIDs.count-1 ? 22 : 0)
                        }.contentShape(Rectangle())
                    }.buttonStyle(PressFeedback()).accessibilityIdentifier(lesson.key)
                }
            }
        }
    }
}
struct SubjectRoadmapView: View {
    let roadmap: Roadmap
    @EnvironmentObject private var model: AppModel
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var lesson: Lesson?
    var body: some View {
        ScrollView {
            if let pack=model.pack {
                let player=pack.entity(roadmap.entityID),progress=RoadmapProgress.make(roadmap:roadmap,pack:pack,state:model.state)
                VStack(alignment:.leading,spacing:24) {
                    if typeSize.isAccessibilitySize {
                        VStack(alignment:.leading,spacing:16) {ClubMark(club:player,size:88);Eyebrow(text:player.type == "player" ? "Player starter" : "Competition foundations").dynamicTypeSize(...DynamicTypeSize.xxxLarge);Text(player.name).font(.title2.bold())}
                    } else {
                        HStack(spacing:18) {ClubMark(club:player,size:88);VStack(alignment:.leading,spacing:6) {Eyebrow(text:player.type == "player" ? "Player starter" : "Competition foundations").dynamicTypeSize(...DynamicTypeSize.xxxLarge);Text(player.name).font(.title2.bold())}}
                    }
                    if let summary=roadmap.summary {Text(summary).foregroundStyle(Palette.muted)}
                    Text("\(progress.completedRequired) of \(progress.requiredLessonIDs.count) \(player.type == "player" ? "starter" : "foundation") lessons complete · \(progress.requiredObjectiveIDs.count) memories").font(.subheadline).accessibilityIdentifier(player.type == "player" ? "player-roadmap-progress" : "competition-roadmap-progress")
                    if model.roadmap?.id == roadmap.id {Label("Selected for Learn",systemImage:"checkmark.circle.fill").foregroundStyle(Palette.brand).font(.headline).accessibilityIdentifier(player.type == "player" ? "player-roadmap-selected" : "competition-roadmap-selected")}
                    else {PrimaryButton(title:"Make this my roadmap",symbol:"map") {model.selectSubject(player.id)}.accessibilityIdentifier(player.type == "player" ? "player-roadmap-select" : "competition-roadmap-select")}
                    RoadmapSaveButton(roadmap:roadmap,showsTitle:true,identifierPrefix:"subject-toggle")
                    RoadmapChapters(roadmap:roadmap,pack:pack,openLesson:{lesson=$0})
                }.padding(24)
            }
        }.journal().navigationTitle(model.pack?.entity(roadmap.entityID).type == "player" ? "Player roadmap" : "Competition roadmap").navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item:$lesson) {lesson in NavigationStack {LessonView(lesson:lesson)}}
    }
}
