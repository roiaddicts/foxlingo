import SwiftUI

enum FootballGame: String, CaseIterable, Identifiable {
    case bingo, lineup, grid
    var id: String {rawValue}
    var title: String {switch self {case .bingo:"Football bingo";case .lineup:"Complete the lineup";case .grid:"Football grid"}}
    var subtitle: String {switch self {case .bingo:"12 categories. Find a home for each player.";case .lineup:"Build a classic XI, one position at a time.";case .grid:"Two clues. One player at their intersection."}}
    var symbol: String {switch self {case .bingo:"square.grid.3x3.fill";case .lineup:"sportscourt.fill";case .grid:"rectangle.split.3x3"}}
}
struct GamesHome: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:22) {
                HStack {VStack(alignment:.leading,spacing:8) {Eyebrow(text:"The training ground");Text("Play with football").font(.largeTitle.bold())};Spacer();Leopard().frame(width:70,height:80)}
                Text("Different ways to connect the names you know. No timer. Try, learn, and try again.").foregroundStyle(Palette.muted)
                if !model.memoryPairs.isEmpty {
                    NavigationLink {MemoryGameView(pairs:model.memoryPairs)} label: {
                        HStack(spacing:16) {Image(systemName:"rectangle.on.rectangle.angled").font(.title2).frame(width:50,height:60).foregroundStyle(Palette.green);VStack(alignment:.leading,spacing:6) {Text("Memory match").font(.title3.bold());Text(model.state.savedGame("memory") != nil ? "Continue your saved pairs." : "16 cards. Faces, badges, names and stats.").font(.subheadline).foregroundStyle(Palette.muted)};Spacer();Image(systemName:"chevron.right")}.padding(18).background(.white.opacity(0.8),in:RoundedRectangle(cornerRadius:20))
                    }.buttonStyle(PressFeedback()).accessibilityIdentifier("game-memory")
                }
                if let pack=model.games {
                    if !model.mysteries.isEmpty {
                        NavigationLink {MysteryGameView(rounds:model.mysteries)} label: {
                            HStack(spacing:16) {Image(systemName:"person.crop.circle.badge.questionmark").font(.title2).frame(width:50,height:60).foregroundStyle(Palette.green);VStack(alignment:.leading,spacing:6) {Text("Who am I?").font(.title3.bold());Text(model.state.savedGame("mystery") != nil ? "Continue your saved clues." : "Reveal a clue. Find a familiar face.").font(.subheadline).foregroundStyle(Palette.muted)};Spacer();Image(systemName:"chevron.right")}.padding(18).background(.white.opacity(0.8),in:RoundedRectangle(cornerRadius:20))
                        }.buttonStyle(PressFeedback()).accessibilityIdentifier("game-mystery")
                    }
                    ForEach(FootballGame.allCases) { game in
                        NavigationLink {FootballGameView(game:game,pack:pack)} label: {
                            HStack(spacing:16) {Image(systemName:game.symbol).font(.title2).frame(width:50,height:60).foregroundStyle(Palette.green);VStack(alignment:.leading,spacing:6) {Text(game.title).font(.title3.bold());Text(model.state.savedGame(game.rawValue).flatMap(\.board).map {"Continue · \($0.placed.count) connections saved"} ?? game.subtitle).font(.subheadline).foregroundStyle(Palette.muted)};Spacer();Image(systemName:"chevron.right")}.padding(18).background(.white.opacity(0.8),in:RoundedRectangle(cornerRadius:20))
                        }.buttonStyle(PressFeedback()).accessibilityIdentifier("game-\(game.rawValue)")
                    }
                    Text("\(pack.players.count) players · \(pack.lineups.count) classic Madrid squads").font(.subheadline.bold())
                    Text("Finished games count toward your streak. Album upgrades come from scheduled recall.").font(.footnote).foregroundStyle(Palette.muted)
                    DisclosureGroup("About these boards") {Text(pack.scope).font(.footnote);if let u=URL(string:pack.sourceURL){Link("Futbol11 reference",destination:u)}}
                } else {Text(model.gamesError ?? "Game content unavailable.")}
            }.padding(24)
        }.journal().navigationTitle("Games").navigationBarTitleDisplayMode(.inline)
    }
}
struct FootballGameView: View {
    let game: FootballGame
    let pack: GamePack
    @EnvironmentObject var model: AppModel
    @State private var squadIndex=1
    @State private var placed: [Int:String]=[:]
    @State private var selectedSlot: Int?
    @State private var offered: String?
    @State private var feedback=""
    @State private var feedbackError=false
    @Environment(\.accessibilityReduceMotion) private var reduced
    @State private var history: [Int]=[]
    @State private var assisted=Set<Int>()
    @State private var sessionID=UUID()
    @State private var awarded=false
    @State private var loaded=false
    @State private var confirmRestart=false
    @State private var resumeNotice: String?
    @Environment(\.scenePhase) private var scenePhase
    var squad: ClassicSquad {pack.lineups[min(squadIndex,pack.lineups.count-1)]}
    var candidates: [Set<String>] {
        switch game {
        case .bingo:pack.bingoCategoryIDs.map{Set(pack.category($0)!.playerIDs)}
        case .grid:(0..<9).map{pack.gridCandidates(row:$0/3,column:$0%3)}
        case .lineup:(0..<11).map(squad.candidates)
        }
    }
    var count: Int {candidates.count}
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:18) {
                HStack {Text("\(placed.count) / \(count)").font(.title2.bold()).contentTransition(.numericText()).animation(reduced ? nil : .snappy,value:placed.count);Spacer();Text("UNTIMED").font(.caption.bold()).tracking(2).foregroundStyle(Palette.muted)}
                if let resumeNotice {Text(resumeNotice).font(.subheadline).foregroundStyle(Palette.muted).accessibilityIdentifier("game-resume-notice")}
                ProgressView(value:Double(placed.count),total:Double(count)).animation(reduced ? nil : .easeOut(duration:0.25),value:placed.count)
                if placed.count == count {
                    HStack {Leopard(pose:"celebrate").frame(width:70,height:75);VStack(alignment:.leading,spacing:5) {Text("Board complete!").font(.title2.bold()).accessibilityIdentifier("game-complete");Text(assisted.isEmpty ? "You made every connection." : "\(assisted.count) helped connections. Play again to recall them.").font(.subheadline)}}
                    PrimaryButton(title:"Play again",symbol:"arrow.clockwise") {reset()}.accessibilityIdentifier("game-replay")
                } else {
                    Text(game == .bingo ? "Place this player in any matching category, or skip." : game == .grid ? "Tap a square. Find a player who fits both clues. Each player can be used once." : "Tap a position and name a player from this season’s squad. Each player can be used once.").font(.subheadline).foregroundStyle(Palette.muted)
                    if game == .bingo, let player=offered.flatMap(pack.player) {
                        HStack(spacing:16) {portrait(player,size:70);Text(player.name).font(.title3.bold()).accessibilityIdentifier("bingo-offered-player");Spacer();Button("Skip") {nextPlayer(excluding:player.id);persist()}.accessibilityIdentifier("bingo-skip")}.padding(14).background(.white,in:RoundedRectangle(cornerRadius:18))
                    }
                }
                if game == .lineup {
                    HStack(spacing:12) {
                        if let madrid=model.pack?.entities.first(where:{$0.key == "entity-madrid"}) {ClubMark(club:madrid,size:48)}
                        Text("Real Madrid").font(.headline)
                        Spacer()
                    }
                    Picker("Classic squad",selection:Binding(get:{squadIndex},set:{squadIndex=$0;reset()})) {ForEach(Array(pack.lineups.enumerated()),id:\.offset) {i,s in Text(s.title).tag(i)}}.disabled(!placed.isEmpty).accessibilityIdentifier("lineup-squad")
                    Text(squad.scope).font(.caption).foregroundStyle(Palette.muted)
                    VStack(spacing:20) {
                        ForEach(Array([[0,1,2],[3,4,5],[6,7,8,9],[10]].enumerated()),id:\.offset) {_,row in
                            HStack(alignment:.top,spacing:8) {ForEach(row,id:\.self) {slot in cell(slot,label:squad.positions[slot]).frame(maxWidth:row.count == 1 ? 95 : .infinity)}}.frame(maxWidth:.infinity)
                        }
                    }.padding(16).background(Palette.green.opacity(0.09),in:RoundedRectangle(cornerRadius:22))
                } else if game == .grid {
                    Grid(horizontalSpacing:6,verticalSpacing:6) {
                        GridRow {Image(systemName:"multiply").accessibilityLabel("Club and country");ForEach(0..<3,id:\.self) {c in GameCategoryMark(category:pack.category(pack.gridColumnIDs[c])!).frame(maxWidth:.infinity)}}
                        ForEach(0..<3,id:\.self) {r in GridRow {GameCategoryMark(category:pack.category(pack.gridRowIDs[r])!).frame(width:62);ForEach(0..<3,id:\.self) {c in cell(r*3+c,label:"+")}}}
                    }
                } else {
                    LazyVGrid(columns:Array(repeating:GridItem(.flexible(),spacing:8),count:3),spacing:8) {
                        ForEach(0..<12,id:\.self) {slot in cell(slot,label:shortTitle(pack.category(pack.bingoCategoryIDs[slot])!.title))}
                    }
                }
                if !feedback.isEmpty {Text(feedback).font(.subheadline).foregroundStyle(feedbackError ? Palette.red : Palette.green).accessibilityIdentifier("game-feedback")}
                if !awarded {
                    HStack {Button("Undo",systemImage:"arrow.uturn.backward") {undo()}.disabled(history.isEmpty);Spacer();Button("Help me connect",systemImage:"lightbulb") {hint()}.accessibilityIdentifier("game-hint")}.frame(minHeight:44)
                }
                Text(game == .lineup ? squad.source : "Historical club and nationality connections · Futbol11 seed snapshot").font(.caption).foregroundStyle(Palette.muted)
            }.padding(20)
        }.journal().navigationTitle(game.title).navigationBarTitleDisplayMode(.inline)
        .onAppear {restore()}
        .onDisappear {persist()}
        .onChange(of:scenePhase) {if scenePhase != .active {persist()}}
        .toolbar {if !awarded {Button("Start again",systemImage:"arrow.counterclockwise") {if placed.isEmpty {reset()} else {confirmRestart=true}}.accessibilityIdentifier("game-restart")}}
        .alert("Start a new board?",isPresented:$confirmRestart) {Button("Start a new board",role:.destructive) {reset()};Button("Keep playing",role:.cancel) {}} message:{Text("This clears this board’s connections. Your other games and learning progress stay saved.")}
        .sheet(isPresented:Binding(get:{selectedSlot != nil},set:{if !$0 {selectedSlot=nil}})) {
            if let slot=selectedSlot {
                NavigationStack {PlayerAnswerSheet(players:game == .lineup ? pack.players.filter { $0.id.hasPrefix("classic-player-") } : pack.players.filter { $0.id.hasPrefix("player-") },title:game == .grid ? "Choose a player" : squad.positions[slot],clues:game == .grid ? [pack.category(pack.gridRowIDs[slot/3])!,pack.category(pack.gridColumnIDs[slot%3])!] : [],contextClub:game == .lineup ? model.pack?.entities.first(where:{$0.key == "entity-madrid"}) : nil,contextTitle:game == .lineup ? squad.title : nil,contextScope:game == .lineup ? squad.scope : nil) {player in place(player.id,at:slot)} }
            }
        }
    }
    private func shortTitle(_ title: String) -> String {title.replacingOccurrences(of:"Played for ",with:"").replacingOccurrences(of:"From ",with:"")}
    private func portrait(_ p: GamePlayer, size: CGFloat) -> some View {EntityArtwork(asset:p.imageAsset,url:p.imageURL,initials:p.name.split(separator:" ").compactMap(\.first).map(String.init).prefix(2).joined(),size:size,isPlayer:true)}
    private func cell(_ slot: Int,label: String) -> some View {
        Button {
            guard placed[slot] == nil else {return}
            if game == .bingo {if let offered {place(offered,at:slot)}} else {selectedSlot=slot}
        } label: {
            VStack(spacing:5) {
                if game == .bingo {GameCategoryMark(category:pack.category(pack.bingoCategoryIDs[slot])!,size:placed[slot] == nil ? 48 : 24)}
                if let player=placed[slot].flatMap(pack.player) {portrait(player,size:game == .lineup ? 44 : 46).transition(.scale(scale:0.86).combined(with:.opacity));Text(player.name).font(.system(size:10,weight:.semibold)).lineLimit(3);if game == .lineup {Text(label).font(.system(size:9,weight:.bold)).foregroundStyle(Palette.muted)}}
                else if game != .bingo {Image(systemName:game == .lineup ? "tshirt.fill" : "plus").font(.headline).foregroundStyle(Palette.green);if game == .lineup {Text(label).font(.caption2.bold())}}
            }.frame(maxWidth:.infinity,minHeight:game == .lineup ? 76 : 94).padding(6)
                .background(placed[slot] == nil ? .white : Palette.green.opacity(0.12),in:RoundedRectangle(cornerRadius:12))
                .overlay {RoundedRectangle(cornerRadius:12).stroke(Palette.green.opacity(placed[slot] == nil ? 0.12 : 0.35),lineWidth:1)}
        }.animation(reduced ? nil : .spring(response:0.32,dampingFraction:0.82),value:placed[slot]).buttonStyle(PressFeedback()).accessibilityLabel(accessibleCell(slot,label:label)).accessibilityIdentifier("game-cell-\(slot)")
    }
    private func accessibleCell(_ slot: Int,label: String) -> String {
        let clue=game == .grid ? "\(shortTitle(pack.category(pack.gridRowIDs[slot/3])!.title)) and \(shortTitle(pack.category(pack.gridColumnIDs[slot%3])!.title))" : label
        return clue + ": " + (placed[slot].flatMap(pack.player)?.name ?? "Choose a player")
    }
    @discardableResult private func place(_ player: String,at slot: Int,helped: Bool = false) -> Bool {
        guard BoardMatcher.accepts(player:player,slot:slot,candidates:candidates,placed:placed) else {feedbackError=true;feedback="That connection doesn’t fit this square, or the player is already on the board. Try another.";model.respond(false);return false}
        feedbackError=false;placed[slot]=player;history.append(slot);selectedSlot=nil
        if helped {assisted.insert(slot)}
        feedback=helped ? "A helped connection. Try to remember this pair next time." : "Connection made.";model.respond(true)
        if placed.count == count {
            if !awarded {_ = model.state.completeGame(id:sessionID,kind:game.rawValue,count:count,now:model.now);model.state.removeSavedGame(game.rawValue);model.save();awarded=true}
        } else if game == .bingo {nextPlayer()}
        if BoardMatcher.solution(candidates,fixed:placed) == nil {feedbackError=true;feedback="Each connection fits, but the remaining board needs a different combination. Undo a choice to make room."}
        persist();return true
    }
    private func nextPlayer(excluding: String? = nil) {
        let ids=BoardMatcher.solution(candidates,fixed:placed,randomized:true)?.filter{placed[$0.key] == nil}.map(\.value) ?? candidates.enumerated().filter{placed[$0.offset] == nil}.flatMap{$0.element.subtracting(Set(placed.values))}
        offered=(ids.filter{$0 != excluding}.shuffled().first ?? ids.first)
    }
    private func hint() {
        guard let solution=BoardMatcher.solution(candidates,fixed:placed), let slot=solution.keys.sorted().first(where:{placed[$0] == nil}), let player=solution[slot] else {feedbackError=true;feedback="Undo a choice first so every remaining square can be filled.";return}
        place(player,at:slot,helped:true)
    }
    private func undo() {guard !awarded, let slot=history.popLast() else {return};placed.removeValue(forKey:slot);assisted.remove(slot);feedbackError=false;feedback="Make a new connection.";if game == .bingo {nextPlayer()};persist()}
    private func reset() {model.state.removeSavedGame(game.rawValue);resumeNotice=nil;placed=[:];history=[];assisted=[];awarded=false;feedbackError=false;feedback="";sessionID=UUID();offered=nil;if game == .bingo {nextPlayer()};persist()}
    private func persist() {
        guard loaded,!awarded,let signature=GameResumeRules.boardSignature(kind:game.rawValue,pack:pack,squadID:game == .lineup ? squad.id : nil) else {return}
        model.state.storeGame(GameResume(signature:signature,sessionID:sessionID,board:BoardProgress(squadID:game == .lineup ? squad.id : nil,placed:placed,history:history,assisted:assisted,offered:offered)),kind:game.rawValue)
        model.save()
    }
    private func restore() {
        guard !loaded else {return};loaded=true
        if let resume=model.state.savedGame(game.rawValue) {
            if let board=GameResumeRules.restoreBoard(resume,kind:game.rawValue,pack:pack,completedSessions:Set(model.state.sessions.map(\.id))) {
                if let id=board.squadID,let i=pack.lineups.firstIndex(where:{$0.id == id}) {squadIndex=i}
                placed=board.placed;history=board.history;assisted=board.assisted;offered=board.offered;sessionID=resume.sessionID
                resumeNotice="Your board is right where you left it."
                if BoardMatcher.solution(candidates,fixed:placed) == nil {feedbackError=true;feedback="These connections fit, but the remaining board needs a different combination. Undo a choice to make room."}
                return
            }
            model.state.removeSavedGame(game.rawValue);resumeNotice="That saved board could not be used with this content. A fresh board is ready; your completed activity is preserved."
        }
        if game == .bingo {nextPlayer()};persist()
    }

}
struct PlayerAnswerSheet: View {
    let players: [GamePlayer]
    let title: String
    var clues: [GameCategory] = []
    var contextClub: Entity? = nil
    var contextTitle: String? = nil
    var contextScope: String? = nil
    let onChoose: (GamePlayer) -> Bool
    @Environment(\.dismiss) var dismiss
    @State private var query=""
    @State private var message=""
    var results: [GamePlayer] {
        guard Recall.normalize(query).count >= 2 else {return []}
        // Classic and general namespace IDs may name the same human; keep one row per ID.
        return Array(players.filter {$0.aliases.contains{Recall.normalize($0).contains(Recall.normalize(query))}}.prefix(30))
    }
    var body: some View {
        List {
            if let contextClub {
                VStack(alignment:.leading,spacing:10) {
                    HStack {ClubMark(club:contextClub,size:48);Text(contextClub.name).font(.headline)}
                    if let contextTitle {Text(contextTitle).font(.headline)}
                    if let contextScope {Text(contextScope).font(.caption).foregroundStyle(Palette.muted)}
                }.padding(.vertical,8).accessibilityElement(children:.combine).accessibilityIdentifier("game-lineup-context")
            }
            if !clues.isEmpty {HStack {ForEach(clues) {GameCategoryMark(category:$0,size:56)};Spacer()}.padding(.vertical,8)}
            Section {TextField("Type a player’s name",text:$query).autocorrectionDisabled().accessibilityIdentifier("game-player-search");Text("Select the person you mean. The board checks the relationship.").font(.caption).foregroundStyle(.secondary)}
            if !message.isEmpty {Text(message).foregroundStyle(Palette.red).accessibilityIdentifier("game-answer-error")}
            ForEach(results) {player in
                Button {if !onChoose(player) {message="That player doesn’t fit both clues, this squad position, or has already been used. Try another."}} label: {HStack {EntityArtwork(asset:player.imageAsset,url:player.imageURL,initials:String(player.name.prefix(2)),size:36,isPlayer:true);Text(player.name)}}.accessibilityIdentifier("game-player-\(player.id)")
            }
            if !query.isEmpty && results.isEmpty {Text("No name found in this historical seed. Try the full name or a known nickname.").font(.subheadline)}
        }.navigationTitle(title).navigationBarTitleDisplayMode(.inline).toolbar {Button("Cancel"){dismiss()}}
    }
}
