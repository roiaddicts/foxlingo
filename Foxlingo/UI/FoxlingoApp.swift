import SwiftUI

@main struct FoxlingoApp: App {
    @StateObject private var model = AppModel()
    var body: some Scene { WindowGroup { RootView().environmentObject(model).tint(Palette.green).preferredColorScheme(.light) } }
}
struct RootView: View {
    @EnvironmentObject var model: AppModel
    @State private var settings = false
    @Environment(\.scenePhase) private var scenePhase
    var body: some View {
        Group {
            if let error = model.contentError {
                ContentUnavailableView("Lessons unavailable",systemImage:"book.closed",description:Text(error)).journal()
            } else if model.recoveryRequired {
                NavigationStack { VStack(spacing:24) { Leopard().frame(height:110); Text("Let's recover your progress").font(.title.bold()); Text(model.message ?? "Saved progress needs attention."); PrimaryButton(title:"Retry",action:{model.recoveryRequired=false;model.load()}); Button("Settings") { settings=true } }.padding(24).journal() }
            } else if model.state.selectedClub == nil, let pack = model.pack {
                WelcomeView(pack:pack)
            } else {
                TabView {
                    NavigationStack { LearnView().toolbar { Button {settings=true} label:{Image(systemName:"gearshape")}.accessibilityLabel("Settings") } }.tabItem { Label("Learn",systemImage:"map") }
                    NavigationStack { PracticeHome().toolbar { Button {settings=true} label:{Image(systemName:"gearshape")}.accessibilityLabel("Settings") } }.tabItem { Label("Practice",systemImage:"arrow.clockwise") }
                    NavigationStack { GamesHome() }.tabItem { Label("Games",systemImage:"sportscourt") }
                    NavigationStack { AlbumView().toolbar { Button {settings=true} label:{Image(systemName:"gearshape")}.accessibilityLabel("Settings") } }.tabItem { Label("Album",systemImage:"rectangle.stack") }
                }
            }
        }.onChange(of:scenePhase) { if scenePhase == .active {model.objectWillChange.send()} }.sheet(isPresented:$settings) { NavigationStack { SettingsView() } }
        .alert("Progress notice",isPresented:Binding(get:{model.message != nil && !model.recoveryRequired},set:{if !$0 {model.message=nil}})) { Button("OK") { model.message=nil } } message:{Text(model.message ?? "")}
    }
}
struct WelcomeView: View {
    let pack: ContentPack
    @EnvironmentObject var model: AppModel
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:22) {
                HStack { Text("foxlingo").font(.system(.largeTitle,design:.rounded,weight:.black)); Spacer(); Image(systemName:"soccerball").font(.title2) }
                Leopard().frame(height:130).frame(maxWidth:.infinity)
                Eyebrow(text:"Your football story starts here")
                Text("Two favorite clubs.\nA world to learn.").font(.system(.largeTitle,design:.rounded,weight:.bold))
                Text("Short stories, playful practice, and a collection that grows with what you remember.").foregroundStyle(Palette.muted)
                Text("Where shall we start?").font(.headline)
                ForEach(pack.roadmaps.filter { ["roadmap-xolos","roadmap-madrid"].contains($0.key) }) { r in
                    let club = pack.entity(r.clubID)
                    Button { model.select(club.id) } label: {
                        HStack(spacing:16) { ClubMark(club:club,size:52); VStack(alignment:.leading,spacing:4) { Text(club.visual == "XT" ? "Xolos" : club.name).font(.title3.bold()); Text(club.visual == "XT" ? "Club Tijuana · Mexico" : "Real Madrid · Spain").font(.subheadline).foregroundStyle(Palette.muted) }; Spacer(); Image(systemName:"arrow.right") }.padding(16).background(.white.opacity(0.7),in:RoundedRectangle(cornerRadius:20))
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
    var body: some View {
        ScrollView {
            if let pack=model.pack, let r=model.roadmap {
                let club=pack.entity(r.clubID)
                VStack(alignment:.leading,spacing:26) {
                    HStack { Text("foxlingo").font(.system(.title,design:.rounded,weight:.black)); Spacer(); Label("\(model.state.streak.current(at:model.now,zone:model.state.homeTimeZone))",systemImage:"flame.fill").font(.headline).foregroundStyle(Palette.green).accessibilityLabel("\(model.state.streak.current(at:model.now,zone:model.state.homeTimeZone)) active day streak") }
                    HStack(spacing:14) { ClubMark(club:club); VStack(alignment:.leading,spacing:4) { Eyebrow(text:"Your roadmap"); Text(club.visual == "XT" ? "Xolos" : club.name).font(.largeTitle.bold()) }; Spacer(); Button {clubLibrary=true} label: { Image(systemName:"arrow.left.arrow.right").frame(width:44,height:44).background(.white.opacity(0.8),in:Circle()) }.accessibilityLabel("Switch club").accessibilityIdentifier("switch-club") }
                    HStack(alignment:.center,spacing:10) { VStack(alignment:.leading,spacing:10) { Text("A little practice.\nA lasting memory.").font(.title3.bold()); Text("\(r.chapters.flatMap(\.lessonIDs).filter {model.state.completedLessons.contains($0)}.count) of \(r.chapters.flatMap(\.lessonIDs).count) lessons complete").font(.subheadline).foregroundStyle(Palette.muted) }; Spacer(); Leopard().frame(width:72,height:82) }
                    if !model.due.isEmpty { Button { practiceRoute=PracticeRoute(model.due,dueMode:true) } label: { Label("\(model.due.count) memories ready to revisit",systemImage:"arrow.clockwise").font(.subheadline.bold()).frame(maxWidth:.infinity,alignment:.leading).padding(16).background(Palette.green.opacity(0.08),in:RoundedRectangle(cornerRadius:14)) } }
                    ForEach(Array(r.chapters.enumerated()),id:\.element.id) { index, chapter in
                        VStack(alignment:.leading,spacing:18) {
                            HStack { Eyebrow(text:"Chapter \(index+1)"); Rectangle().fill(Palette.ink.opacity(0.12)).frame(height:1) }
                            Text(chapter.title).font(.title2.bold())
                            ForEach(Array(chapter.lessonIDs.enumerated()),id:\.element) { n,id in
                                let l=pack.lesson(id), done=model.state.completedLessons.contains(id), started=model.state.resumes[id] != nil
                                Button { activeLesson=l } label: {
                                    HStack(spacing:18) {
                                        VStack(spacing:0) { Circle().fill(done ? Palette.green : .white).frame(width:52,height:52).overlay { Image(systemName:done ? "checkmark" : started ? "play.fill" : "book.fill").foregroundStyle(done ? .white : Palette.green) }; if n < chapter.lessonIDs.count-1 { Rectangle().fill(Palette.green.opacity(0.2)).frame(width:3,height:22) } }
                                        VStack(alignment:.leading,spacing:5) { Text(l.title).font(.headline); Text(done ? "Completed · Play again" : started ? "Continue lesson" : l.subtitle).font(.subheadline).foregroundStyle(Palette.muted) }.padding(.bottom,n < chapter.lessonIDs.count-1 ? 22 : 0)
                                        Spacer(); Image(systemName:"chevron.right").font(.caption.bold()).padding(.bottom,n < chapter.lessonIDs.count-1 ? 22 : 0)
                                    }
                                }.buttonStyle(.plain).accessibilityIdentifier(l.key)
                            }
                        }
                    }
                    Text("Every club has a story. You're building yours.").font(.footnote).foregroundStyle(Palette.muted).padding(.bottom,20)
                }.padding(24)
            }
        }.journal().navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented:$clubLibrary) {NavigationStack {ClubLibrary(onSelect:{id in model.select(id);clubLibrary=false},onClose:{clubLibrary=false})}}
            .fullScreenCover(item:$activeLesson) { lesson in NavigationStack { LessonView(lesson:lesson) } }
            .navigationDestination(item:$practiceRoute) { r in if let p=model.pack {PracticeSession(objectives:r.objectiveIDs.map(p.objective),dueMode:r.dueMode)} }
    }
}
