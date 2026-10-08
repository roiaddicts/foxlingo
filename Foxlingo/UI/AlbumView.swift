import SwiftUI

struct AlbumView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduced
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var scope: AlbumScope = .favorites
    @State private var discoveredOnly = false
    @State private var query = ""
    var body: some View {
        ScrollView {
            LazyVStack(alignment:.leading,spacing:22) {
                HStack {VStack(alignment:.leading,spacing:8) {Eyebrow(text:"A collection of connections");Text("Your album").font(.largeTitle.bold())};Spacer();Leopard().frame(width:52,height:60)}
                NavigationLink {ExplorerView()} label:{Label("Explore connections",systemImage:"point.3.connected.trianglepath.dotted").font(.headline).frame(minHeight:44)}.buttonStyle(PressFeedback()).accessibilityIdentifier("graph-open")
                Picker("Collection",selection:$scope) {ForEach(AlbumScope.allCases) {s in Text(s.title).tag(s)}}.pickerStyle(.menu).accessibilityIdentifier("album-collection")
                Toggle("Discovered only",isOn:$discoveredOnly).accessibilityIdentifier("album-discovered-only")
                if let pack=model.pack {
                    let collection=AlbumCollection.make(pack:pack,state:model.state,scope:scope,discoveredOnly:discoveredOnly,query:query)
                    Text("\(collection.discovered) of \(collection.total) discovered · \(scope.title)").font(.subheadline).foregroundStyle(Palette.muted).contentTransition(.numericText()).accessibilityIdentifier("album-count")
                    if !query.isEmpty {Text("\(collection.visibleCount) search \(collection.visibleCount == 1 ? "result" : "results")").font(.subheadline).foregroundStyle(Palette.muted).accessibilityIdentifier("album-results")}
                    if collection.sections.isEmpty {
                        ContentUnavailableView {
                            Label(query.isEmpty ? "Your collection starts with a story" : "No matching cards",systemImage:query.isEmpty ? "book" : "magnifyingglass")
                        } description: {Text(query.isEmpty ? "Complete a club lesson to discover its card." : "Try a club, player, or nickname.")}
                        actions: {
                            if !query.isEmpty {Button("Clear search") {query=""}.accessibilityIdentifier("album-clear-search")}
                            if discoveredOnly {Button("Show all cards") {discoveredOnly=false}.accessibilityIdentifier("album-show-all")}
                        }
                    }
                    ForEach(collection.sections) {section in
                        HStack {ClubMark(club:pack.entity(section.clubID),size:34);Text(pack.entity(section.clubID).name).font(.title2.bold())}
                        LazyVGrid(columns:[GridItem(.adaptive(minimum:typeSize.isAccessibilitySize ? 280 : 145),spacing:14)],spacing:14) {
                            ForEach(section.cards) {card in
                                NavigationLink {CardDetail(card:card)} label: {Collectible(card:card,pack:pack,tier:model.state.tier(card),readiness:CardReadiness.make(card:card,pack:pack,state:model.state,now:model.now))}.buttonStyle(PressFeedback()).accessibilityIdentifier(card.key)
                            }
                        }
                    }
                }
                Text("Cards celebrate their defined knowledge sets. Scheduled recall improves them over time.").font(.footnote).foregroundStyle(Palette.muted)
            }.padding(24)
        }.scrollDismissesKeyboard(.interactively).journal().navigationTitle("Album").navigationBarTitleDisplayMode(.inline)
        .searchable(text:$query,prompt:"Find a club or player")
        .animation(reduced ? nil : .easeInOut(duration:0.2),value:scope)
        .animation(reduced ? nil : .easeInOut(duration:0.2),value:discoveredOnly)
    }
}
struct Collectible: View {
    let card: AlbumCard
    let pack: ContentPack
    let tier: Int
    var readiness: CardReadiness? = nil
    var body: some View {
        let entity=pack.entity(card.entityID)
        VStack(alignment:.leading,spacing:12) {
            HStack {Text(tier < 0 ? "Locked" : LearnerState.tierNames[tier]).font(.caption2.bold());Spacer();Image(systemName:tier < 0 ? "lock.fill" : tier == 4 ? "diamond.fill" : "sparkle").font(.caption)}
            ZStack {Circle().stroke(Palette.ink.opacity(0.12),lineWidth:1).frame(width:86,height:86);EntityArtwork(asset:entity.imageAsset,url:entity.imageURL,initials:entity.visual,size:86,isPlayer:entity.type == "player")}.frame(maxWidth:.infinity,minHeight:105)
            Text(entity.name).font(.headline).frame(maxWidth:.infinity,alignment:.leading)
            Text(CardReadiness.scopeLabel(card:card,pack:pack)).font(.caption).foregroundStyle(Palette.muted)
            if tier >= 0,let readiness {
                Text("\(readiness.introduced) of \(card.objectiveIDs.count) introduced").font(.caption)
                if readiness.refresh > 0 {Label("\(readiness.refresh) to refresh",systemImage:"arrow.triangle.2.circlepath").font(.caption).foregroundStyle(Palette.green)}
                else if readiness.due > 0 {Label("\(readiness.due) ready to review",systemImage:"arrow.clockwise").font(.caption).foregroundStyle(Palette.green)}
            }
        }.padding(16).frame(maxWidth:.infinity,alignment:.leading).background(tier < 0 ? Color.white.opacity(0.35) : tier == 0 ? Color(red:0.87,green:0.8,blue:0.67) : tier == 1 ? Color(red:0.86,green:0.72,blue:0.55) : tier == 2 ? Color(red:0.84,green:0.87,blue:0.87) : tier == 3 ? Palette.ochre.opacity(0.5) : Color(red:0.78,green:0.91,blue:0.89),in:RoundedRectangle(cornerRadius:18))
        .overlay {RoundedRectangle(cornerRadius:18).stroke(Palette.ink.opacity(tier < 0 ? 0.08 : 0.2),lineWidth:1)}
        .accessibilityElement(children:.combine)
    }
}
struct CardDetail: View {
    let card: AlbumCard
    @EnvironmentObject var model: AppModel
    @Environment(\.openURL) private var openURL
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduced
    @State private var lesson: Lesson?
    @State private var practice: PracticeRoute?
    @State private var expanded = Set<UUID>()
    @State private var previewed = Set<UUID>()
    private var achievementScope: String {
        guard let achievement=model.state.cardAchievements?[card.id] else {return "set version \(card.knowledgeVersion)"}
        return achievement.knowledgeVersion.map {"set version \($0)"} ?? "earlier set · version unrecorded"
    }
    var body: some View {
        ScrollView {
            if let pack=model.pack {
                let tier=model.state.tier(card), readiness=CardReadiness.make(card:card,pack:pack,state:model.state,now:model.now)
                VStack(alignment:.leading,spacing:22) {
                    Collectible(card:card,pack:pack,tier:tier).frame(maxWidth:typeSize.isAccessibilitySize ? .infinity : 260).frame(maxWidth:.infinity)
                    NavigationLink {ExplorerView(initialID:card.entityID).onAppear {previewed.formUnion(card.objectiveIDs)}} label:{Label("Explore connections",systemImage:"point.3.connected.trianglepath.dotted").font(.headline).frame(minHeight:44)}.buttonStyle(PressFeedback()).accessibilityIdentifier("card-graph-open")
                    if let roadmap=pack.playerRoadmaps.first(where:{$0.entityID == card.entityID}) {
                        NavigationLink {PlayerRoadmapView(roadmap:roadmap).onAppear {previewed.formUnion(card.objectiveIDs)}} label:{Label("Open player roadmap",systemImage:"map").font(.headline).frame(minHeight:44)}.buttonStyle(PressFeedback()).accessibilityIdentifier("card-player-roadmap")
                    }
                    Text(tier < 0 ? "Discover this story" : "Your knowledge set").font(.title2.bold())
                    if tier >= 0 {
                        Text("Earned \(LearnerState.tierNames[tier]) · \(achievementScope)").font(.headline).accessibilityIdentifier("card-achievement")
                    }
                    Text("\(readiness.introduced) of \(card.objectiveIDs.count) connections introduced · Active set version \(card.knowledgeVersion)").foregroundStyle(Palette.muted).accessibilityIdentifier("card-coverage")
                    ProgressView(value:Double(readiness.introduced),total:Double(card.objectiveIDs.count)).accessibilityLabel("Current knowledge coverage")
                    if let stage=readiness.currentStage {Text("Current recall stage \(stage) of 4 · \(readiness.due) ready to review").font(.subheadline).accessibilityIdentifier("card-current-recall")}
                    else {Text("\(readiness.missing) to discover · \(readiness.refresh) to refresh · \(readiness.due) ready to review").font(.subheadline).accessibilityIdentifier("card-current-recall")}
                    ForEach(card.objectiveIDs,id:\.self) {id in
                        let objective=pack.objective(id), review=model.state.reviews[id]
                        VStack(alignment:.leading,spacing:8) {
                            Text(objective.prompt).font(.subheadline.bold())
                            if let review,review.revision == objective.revision {
                                Text(review.refreshRequired == true ? "Updated fact · recall refresh needed" : "Recall stage \(review.stage) · Next \(review.due.formatted(date:.abbreviated,time:.omitted))").font(.caption).foregroundStyle(Palette.muted)
                            } else {Text(review == nil ? "Not introduced yet" : "Updated fact · recall refresh needed").font(.caption).foregroundStyle(Palette.muted)}
                            Button {
                                withAnimation(reduced ? nil : .easeInOut(duration:0.2)) {if expanded.contains(id) {expanded.remove(id)} else {expanded.insert(id);previewed.insert(id)}}
                            } label:{Label(expanded.contains(id) ? "Hide context" : "Context & sources",systemImage:"text.book.closed").font(.caption.bold()).frame(minHeight:44)}.buttonStyle(PressFeedback()).accessibilityIdentifier("card-context-\(objective.key)")
                            if expanded.contains(id) {
                                ForEach(objective.factIDs,id:\.self) {fid in
                                    if let fact=pack.facts.first(where:{$0.id == fid}) {
                                        Text(fact.scope).font(.caption).foregroundStyle(Palette.muted)
                                        ForEach(fact.sourceKeys,id:\.self) {key in if let source=pack.sources.first(where:{$0.key == key}),let url=URL(string:source.url) {Button(source.title) {previewed.insert(id);openURL(url)}.font(.caption);Text("Checked \(source.verifiedAt)").font(.caption2).foregroundStyle(Palette.muted)}}
                                    }
                                }
                            }
                            Divider()
                        }
                    }
                    ForEach(card.lessonIDs.map(pack.lesson)) {l in Button {lesson=l} label:{Label(l.title,systemImage:"book.fill").font(.headline).frame(minHeight:44)}.accessibilityIdentifier("card-open-\(l.key)")}
                    let learned=card.objectiveIDs.filter {model.state.reviews[$0]?.revision == pack.objective($0).revision}.map(pack.objective)
                    if tier >= 0 && !learned.isEmpty {
                        PrimaryButton(title:"Practice this knowledge set",symbol:"arrow.clockwise") {practice=PracticeRoute(learned,dueMode:readiness.due > 0,assistedObjectiveIDs:previewed)}.accessibilityIdentifier("card-practice")
                    }
                    Text("Earned tiers stay with you. Current recall reflects this active knowledge set; context, a linked player roadmap, or the explorer opened here counts as rehearsal in card practice.").font(.footnote).foregroundStyle(Palette.muted)
                }.padding(24)
            }
        }.journal().navigationTitle(model.pack?.entity(card.entityID).name ?? "Card").navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item:$lesson){l in NavigationStack {LessonView(lesson:l)}}
        .navigationDestination(item:$practice) {route in if let pack=model.pack {PracticeSession(objectives:route.objectiveIDs.map(pack.objective),dueMode:route.dueMode,assistedObjectiveIDs:route.assistedObjectiveIDs,previewContext:"the card context or explorer")}}
    }
}
struct SettingsView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) var dismiss
    @State private var confirmReset=false
    var body: some View {
        Form {
            Section("Your experience") {
                Toggle("Sound",isOn:$model.state.sound).onChange(of:model.state.sound){model.save()}
                Toggle("Haptics",isOn:$model.state.haptics).onChange(of:model.state.haptics){model.save()}
                Text("English · Offline starter edition").foregroundStyle(.secondary)
            }
            Section("Streaks") {
                Text("Complete a lesson or practice session to count an active day. One freeze protects one missed day between active days, without counting it as practice. Earn another freeze after seven active days, up to one at a time.")
                LabeledContent("Home time zone",value:model.state.homeTimeZone)
                LabeledContent("Available freeze",value:"\(model.state.streak.freezes)")
                LabeledContent("Longest active streak",value:"\(model.state.streak.longest) days")
                Text("Your home time zone stays fixed while you travel.").font(.caption)
            }
            Section("Album tiers") {
                Text("Cards unlock when you complete a related lesson. Bronze, silver, gold, and diamond require independent recall when reviews are due, across every connection in the card’s set. A clean sequence reaches diamond after about 25 days.")
            }
            Section("Content & sources") {
                Text("Club lessons checked October 8, 2026. Competition membership is a dated snapshot. Game relationships come from the supplied historical Futbol11 seed. Each lesson includes source links and context.")
                if let p=model.pack {ForEach(p.sources) {s in if let url=URL(string:s.url){Link(s.title,destination:url)}}}
            }
            Section("Progress") {
                Button("Reset all progress",role:.destructive){confirmReset=true}.accessibilityIdentifier("reset-progress")
                Text("A reset starts a new collection. A copy of your old progress stays archived on this device.").font(.caption)
            }
        }.navigationTitle("Settings").toolbar {Button("Done"){dismiss()}}
        .confirmationDialog("Reset lessons, cards, reviews, and streaks?",isPresented:$confirmReset,titleVisibility:.visible){Button("Reset all progress",role:.destructive){model.reset();dismiss()}}message:{Text("This starts over. Your previous save will be archived on the device.")}
    }
}
