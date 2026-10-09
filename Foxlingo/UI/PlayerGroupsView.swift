import SwiftUI

struct PlayerGroupsView: View {
    let mode: PlayerGroupMode
    let pack: GamePack
    @EnvironmentObject private var model: AppModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduced
    @State private var board: PlayerGroupProgress?
    @State private var sessionID=UUID()
    @State private var loaded=false
    @State private var feedback=""
    @State private var restart=false
    @State private var scrollReset=0
    private var title: String {mode == .connections ? "Football Connections" : "Find the Impostors"}
    var body: some View {
        ScrollViewReader {reader in
        ScrollView {
            VStack(alignment:.leading,spacing:16) {
                if let board {
                    HStack {Text("\(board.solved.count) / 4 groups").font(.title2.bold()).contentTransition(.numericText());Spacer();Text("\(board.checks) checks").font(.subheadline).foregroundStyle(Palette.muted)}
                    if board.finished {
                        HStack {Leopard(pose:"celebrate").frame(width:64,height:72);Text("Every group found!").font(.title2.bold()).accessibilityIdentifier("groups-complete")}
                        PrimaryButton(title:"Play again",symbol:"arrow.clockwise") {begin()}.accessibilityIdentifier("groups-replay")
                    } else {
                        Text(mode == .connections ? "Find four players with a shared country. Make four groups." : "Pick the four players from this country. Leave the four outsiders.").font(.subheadline).foregroundStyle(Palette.muted)
                        if mode == .impostor,let category=pack.category(board.groups[board.round].categoryID) {
                            GameCategoryMark(category:category,size:52).frame(maxWidth:.infinity).accessibilityIdentifier("groups-clue")
                        }
                    }
                    ForEach(board.groups.filter {board.solved.contains($0.categoryID)},id:\.categoryID) {group in
                        HStack(spacing:12) {
                            if let category=pack.category(group.categoryID) {GameCategoryMark(category:category,size:34)}
                            Text(group.playerIDs.compactMap {pack.player($0)?.name}.joined(separator:" · ")).font(.subheadline.bold())
                            Spacer();Image(systemName:"checkmark.circle.fill").foregroundStyle(Palette.brand)
                        }.padding(12).background(Palette.brand.opacity(0.08),in:RoundedRectangle(cornerRadius:14)).accessibilityIdentifier("groups-solved-\(group.categoryID)")
                    }
                    if !board.finished {
                        LazyVGrid(columns:Array(repeating:GridItem(.flexible(),spacing:8),count:mode == .connections ? 4 : 2),spacing:8) {
                            ForEach(board.order.filter {board.available.contains($0)},id:\.self) {id in
                                if let player=pack.player(id) {
                                    Button {self.board?.select(id);feedback="";persist();model.playSound(.reveal)} label: {
                                        VStack(spacing:5) {
                                            EntityArtwork(asset:player.imageAsset,url:player.imageURL,initials:String(player.name.prefix(2)),size:mode == .connections ? 68 : 100,isPlayer:true,portraitFocus:true)
                                            Text(player.name).font(.system(size:mode == .connections ? 11 : 14,weight:.semibold)).lineLimit(2).minimumScaleFactor(0.75).multilineTextAlignment(.center).frame(height:mode == .connections ? 30 : 36)
                                        }.frame(maxWidth:.infinity).padding(.vertical,8)
                                            .background(board.selected.contains(id) ? Palette.brand.opacity(0.12) : .white,in:RoundedRectangle(cornerRadius:14))
                                            .overlay {RoundedRectangle(cornerRadius:14).stroke(board.selected.contains(id) ? Palette.brand : Palette.brand.opacity(0.1),lineWidth:board.selected.contains(id) ? 2 : 1)}
                                    }.buttonStyle(PressFeedback()).accessibilityLabel(player.name).accessibilityValue(board.selected.contains(id) ? "Selected" : "Not selected").accessibilityIdentifier("groups-player-\(id)")
                                }
                            }
                        }.id(board.solved.count).animation(reduced ? nil : .snappy(duration:0.2),value:board.solved)
                    }
                    if !feedback.isEmpty {Text(feedback).font(.subheadline).foregroundStyle(Palette.brand).accessibilityIdentifier("groups-feedback")}
                    Text("Country connections from the Futbol11 seed snapshot. Untimed practice; finished boards support your streak.").font(.caption).foregroundStyle(Palette.muted)
                    if let url=URL(string:pack.sourceURL) {Link("Source & context",destination:url).font(.caption)}
                } else {Text("This content does not have enough distinct players for a board.")}
            }.padding(16).id("groups-top")
        }.onChange(of:scrollReset) {reader.scrollTo("groups-top",anchor:.top)}
        .onChange(of:board?.solved) {
            withAnimation(reduced ? nil : .easeOut(duration:0.2)) {reader.scrollTo("groups-top",anchor:.top)}
        }
        }.journal().navigationTitle(title).navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge:.bottom) {
            if let board,!board.finished {
                HStack(spacing:12) {
                    PrimaryButton(title:"Check \(board.selected.count) / 4",symbol:"checkmark") {check()}.disabled(board.selected.count != 4).accessibilityIdentifier("groups-check")
                    Button {
                        self.board?.selected=[];feedback="";scrollReset+=1;persist();model.playSound(.reveal)
                    } label:{Image(systemName:"xmark.circle").font(.title2).frame(width:44,height:52)}
                        .disabled(board.selected.isEmpty).accessibilityLabel("Clear selection").accessibilityIdentifier("groups-clear")
                }.padding(16).background(.regularMaterial)
            }
        }
        .toolbar {if board?.finished == false {Button("Start again",systemImage:"arrow.counterclockwise") {restart=true}.accessibilityIdentifier("groups-restart")}}
        .alert("Start a new board?",isPresented:$restart) {Button("Start new board",role:.destructive) {begin()};Button("Keep playing",role:.cancel) {}} message:{Text("This replaces this board. Your learning progress stays saved.")}
        .onAppear {restore()}.onDisappear {persist()}.onChange(of:scenePhase) {if scenePhase != .active {persist()}}
    }
    private func check() {
        guard var current=board else {return}
        let attempted=current.selected
        guard let correct=current.check() else {return}
        board=current
        if correct {
            feedback=current.finished ? "All four countries connected." : "Country connected. Find the next group."
            if current.finished {
                model.state.removeSavedGame(mode.rawValue)
                _ = model.state.completeGame(id:sessionID,kind:mode.rawValue,count:16,now:model.now);model.save()
            }
            model.respond(true,event:current.finished ? .completion : .connection)
        } else {
            let target=current.mode == .impostor ? pack.category(current.groups[current.round].categoryID) : nil
            model.recordGameGap(game:mode.rawValue,context:title+(target.map {" · "+$0.title} ?? " · country groups"),names:attempted.compactMap {pack.player($0)?.name},assets:target?.imageAsset.map {[$0]} ?? [],playerIDs:attempted.sorted())
            feedback="Those four don’t form the country group. Tap a selection to change it.";model.respond(false,event:.mismatch)
        }
        persist()
    }
    private func begin() {
        var randomized=true
        #if DEBUG
        randomized = !ProcessInfo.processInfo.arguments.contains("-ui-testing")
        #endif
        let artwork=Set(pack.connectionPlayers.compactMap {player in player.imageAsset.flatMap {UIImage(named:$0) == nil ? nil : $0}})
        board=PlayerGroupDeck.make(mode:mode,pack:pack,randomized:randomized,availableArtwork:artwork);sessionID=UUID();feedback="";persist()
    }
    private func persist() {
        guard loaded,let board,!board.finished else {return}
        model.state.storeGame(GameResume(signature:PlayerGroupDeck.signature(pack),sessionID:sessionID,grouping:board),kind:mode.rawValue);model.save()
    }
    private func restore() {
        guard !loaded else {return};loaded=true
        if let saved=model.state.savedGame(mode.rawValue),let restored=PlayerGroupDeck.restore(saved,mode:mode,pack:pack,completedSessions:Set(model.state.sessions.map(\.id))) {board=restored;sessionID=saved.sessionID;feedback="Your board is right where you left it."}
        else {begin()}
    }
}
