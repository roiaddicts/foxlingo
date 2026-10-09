import SwiftUI

struct DraftXIView: View {
    let engine: DraftEngine
    @EnvironmentObject private var model: AppModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduced
    @State private var board: DraftProgress?
    @State private var sessionID=UUID()
    @State private var selected: String?
    @State private var chooser=false
    @State private var loaded=false
    @State private var feedback=""
    @State private var restart=false
    @State private var scrollReset=0
    private var kind: String {"draft-"+engine.mode.id}
    private var offered: DraftGroup? {board?.offeredID.flatMap {engine.groups[$0]}}
    private var pool: [GamePlayer] {
        let ids=Set(engine.mode.groups.flatMap(\.playerIDs))
        return engine.pack.players.filter {ids.contains($0.person.id)}.map(\.person)
    }
    var body: some View {
        ScrollViewReader {reader in
            ScrollView {
                VStack(alignment:.leading,spacing:12) {
                    if let board,let formation=engine.formation(board) {
                        HStack {
                            Text("\(board.placed.count) / 11").font(.title3.bold()).contentTransition(.numericText())
                            Spacer()
                            if !board.finished {
                                Picker("Formation",selection:Binding(get:{board.formationID},set:{begin(formation:$0)})) {
                                    ForEach(engine.pack.formations) {Text($0.id.map(String.init).joined(separator:"–")).tag($0.id)}
                                }.pickerStyle(.menu).disabled(!board.placed.isEmpty).accessibilityIdentifier("draft-formation")
                            }
                        }
                        ProgressView(value:Double(board.placed.count),total:11)
                        if board.finished {
                            HStack {Leopard(pose:"celebrate").frame(width:64,height:72);VStack(alignment:.leading,spacing:4) {Text("Your XI is complete!").font(.title2.bold()).accessibilityIdentifier("draft-complete");Text(board.assisted.isEmpty ? "Eleven connections made." : "\(board.assisted.count) helped picks. Try recalling them next time.").font(.subheadline)}}
                            PrimaryButton(title:"Play again",symbol:"arrow.clockwise") {begin()}.accessibilityIdentifier("draft-replay")
                        } else if let offered {
                            HStack(spacing:12) {
                                groupMark(offered,size:44)
                                VStack(alignment:.leading,spacing:4) {
                                    Text(offered.name).font(.headline).accessibilityIdentifier("draft-offered")
                                    if let person=selected.flatMap({engine.profiles[$0]?.person}) {
                                        Text(person.name).font(.subheadline.bold()).accessibilityIdentifier("draft-selected")
                                        Text("Tap a highlighted position").font(.caption).foregroundStyle(Palette.muted)
                                    } else {Text("Find a player. Pick an open position.").font(.caption).foregroundStyle(Palette.muted)}
                                }
                                Spacer(minLength:0)
                                if let person=selected.flatMap({engine.profiles[$0]?.person}) {playerMark(person,group:offered,size:52)}
                            }.padding(10).background(.white,in:RoundedRectangle(cornerRadius:16))
                        }
                        GeometryReader {geo in
                            let width=(geo.size.width-24-Double((formation.rows.map(\.count).max() ?? 4)-1)*6)/Double(formation.rows.map(\.count).max() ?? 4)
                            VStack(spacing:9) {
                                ForEach(formation.rows.indices,id:\.self) {row in
                                    HStack(spacing:6) {ForEach(formation.rows[row],id:\.self) {slot in
                                        slotCard(slot,formation:formation,board:board,width:width)
                                    }}.frame(maxWidth:.infinity)
                                }
                            }.padding(12).frame(maxWidth:.infinity,maxHeight:.infinity).background(Palette.brand.opacity(0.09),in:RoundedRectangle(cornerRadius:20))
                        }.frame(height:Double(formation.rows.count)*104+Double(formation.rows.count-1)*9+24)
                        if !feedback.isEmpty {Text(feedback).font(.subheadline).foregroundStyle(Palette.brand).accessibilityIdentifier("draft-feedback")}
                        DisclosureGroup("Source & squad context") {Text(engine.mode.scope).font(.caption);if let url=URL(string:engine.mode.sourceURL) {Link("Futbol11 reference",destination:url).font(.caption)}}
                        Text("Completed games support your streak. Player pools reflect the archived source, with no published roster cutoff.").font(.caption).foregroundStyle(Palette.muted)
                    } else {Text("A complete XI cannot be drawn from this pool.")}
                }.padding(16).id("draft-top")
            }.onChange(of:scrollReset) {withAnimation(reduced ? nil : .easeOut(duration:0.2)) {reader.scrollTo("draft-top",anchor:.top)}}
        }.journal().navigationTitle(engine.mode.title).navigationBarTitleDisplayMode(.inline).toolbar(.hidden,for:.tabBar)
        .safeAreaInset(edge:.bottom) {
            if board?.finished == false {
                HStack(spacing:10) {
                    Button {board?.undo();selected=nil;feedback="Pick undone. Try another position.";scrollReset+=1;persist();model.playSound(.reveal)} label: {Image(systemName:"arrow.uturn.backward").font(.title3).frame(width:38,height:50)}
                        .disabled(board?.history.isEmpty != false).accessibilityLabel("Undo").accessibilityIdentifier("draft-undo")
                    PrimaryButton(title:selected == nil ? "Find a player" : "Change player",symbol:"magnifyingglass") {chooser=true}.accessibilityIdentifier("draft-search")
                    Button {help()} label: {Image(systemName:"lightbulb").font(.title3).frame(width:38,height:50)}.accessibilityLabel("Help me connect").accessibilityIdentifier("draft-help")
                }.padding(14).background(.regularMaterial)
            }
        }
        .sheet(isPresented:$chooser) {
            if let offered {
                NavigationStack {PlayerAnswerSheet(players:pool,title:"Choose a player",contextClubName:offered.name,contextClubImageURL:offered.imageURL,contextClubImageAsset:offered.imageAsset,contextTitle:engine.mode.title,fallbackImageAsset:offered.imageAsset,fallbackImageURL:offered.imageURL) {choose($0)}}.presentationDetents([.large])
            }
        }
        .toolbar {if board?.finished == false {Button("Start again",systemImage:"arrow.counterclockwise") {restart=true}.accessibilityIdentifier("draft-restart")}}
        .alert("Start a new XI?",isPresented:$restart) {Button("Start new XI",role:.destructive) {begin()};Button("Keep playing",role:.cancel) {}} message:{Text("This replaces this XI. Your learning progress stays saved.")}
        .onAppear {restore()}.onDisappear {persist()}.onChange(of:scenePhase) {if scenePhase != .active {persist()}}
    }
    private func groupMark(_ group: DraftGroup,size: CGFloat) -> some View {
        EntityArtwork(asset:group.imageAsset,url:group.imageURL,initials:"⚽",size:size)
    }
    @ViewBuilder private func playerMark(_ player: GamePlayer,group: DraftGroup,size: CGFloat) -> some View {
        if player.imageAsset != nil || player.imageURL != nil {EntityArtwork(asset:player.imageAsset,url:player.imageURL,initials:"⚽",size:size,isPlayer:true,portraitFocus:true)}
        else {groupMark(group,size:size)}
    }
    private func slotCard(_ slot: Int,formation: DraftFormation,board: DraftProgress,width: CGFloat) -> some View {
        let pick=board.placed[slot]
        let eligible=selected.map {engine.accepts($0,at:slot,on:board)} ?? false
        return Button {
            guard let selected else {feedback="Find a player first, then choose a position.";return}
            if !place(selected,slot:slot) {
                if let person=engine.profiles[selected]?.person {model.recordGameGap(game:kind,context:engine.mode.title+" · "+formation.positions[slot],names:[person.name],assets:offered.map {[$0.imageAsset]} ?? [],playerIDs:[selected])}
                feedback="That player doesn’t fit this position. Try a highlighted position.";model.respond(false,event:.mismatch)}
        } label: {
            VStack(spacing:3) {
                Text(formation.positions[slot]).font(.system(size:10,weight:.bold)).foregroundStyle(Palette.brand)
                if let pick,let player=engine.profiles[pick.playerID]?.person,let group=engine.groups[pick.groupID] {
                    playerMark(player,group:group,size:min(62,width-8))
                    Text(player.name).font(.system(size:10,weight:.semibold)).lineLimit(2).minimumScaleFactor(0.75).multilineTextAlignment(.center).frame(height:24)
                } else {
                    if let offered {groupMark(offered,size:34).opacity(eligible ? 0.9 : 0.25)}
                    Image(systemName:eligible ? "plus.circle.fill" : "plus").font(.title3).frame(maxHeight:.infinity).foregroundStyle(Palette.brand)
                }
            }.frame(width:width,height:104).background(eligible ? Palette.brand.opacity(0.15) : .white.opacity(0.95),in:RoundedRectangle(cornerRadius:12))
                .overlay {RoundedRectangle(cornerRadius:12).stroke(eligible ? Palette.brand : .clear,lineWidth:2)}
        }.buttonStyle(PressFeedback()).disabled(pick != nil || board.finished).accessibilityLabel(formation.positions[slot]+(pick.flatMap {engine.profiles[$0.playerID]?.person.name}.map {", "+$0} ?? ", open")).accessibilityIdentifier("draft-slot-\(slot)")
    }
    private func choose(_ player: GamePlayer) -> Bool {
        guard let board,let formation=engine.formation(board) else {return false}
        guard formation.positions.indices.contains(where:{engine.accepts(player.id,at:$0,on:board)}) else {
            model.recordGameGap(game:kind,context:engine.mode.title+" · "+(offered?.name ?? ""),names:[player.name],assets:offered.map {[$0.imageAsset]} ?? [],playerIDs:[player.id]);model.respond(false,event:.mismatch);return false
        }
        selected=player.id;chooser=false;feedback="Tap a highlighted position to place \(player.name).";scrollReset+=1;model.playSound(.reveal);return true
    }
    @discardableResult private func place(_ id: String,slot: Int,assisted: Bool=false) -> Bool {
        guard var current=board,engine.place(id,at:slot,on:&current,assisted:assisted) else {return false}
        withAnimation(reduced ? nil : .spring(duration:0.25)) {board=current;selected=nil;scrollReset+=1}
        feedback=current.finished ? "Eleven players. Eleven connections." : "Connection made. Next up: \(offered?.name ?? "the next club")."
        if current.finished {model.state.removeSavedGame(kind);_ = model.state.completeGame(id:sessionID,kind:kind,count:11,now:model.now);model.save()}
        model.respond(true,event:current.finished ? .completion : .connection);persist();return true
    }
    private func help() {
        guard let board,let id=board.offeredID,let answer=engine.solution(board)?.first(where:{$0.value.groupID == id}) else {feedback="No complete XI fits these picks. Undo a pick and try another position.";return}
        _ = place(answer.value.playerID,slot:answer.key,assisted:true)
    }
    private func begin(formation: String="433") {
        var randomized=true
        #if DEBUG
        randomized = !ProcessInfo.processInfo.arguments.contains("-ui-testing")
        #endif
        board=engine.make(formationID:formation,randomized:randomized);sessionID=UUID();selected=nil;feedback="";scrollReset+=1;persist()
    }
    private func persist() {
        guard loaded,let board,!board.finished else {return}
        model.state.storeGame(GameResume(signature:engine.signature,sessionID:sessionID,draft:board),kind:kind);model.save()
    }
    private func restore() {
        guard !loaded else {return};loaded=true
        if let saved=model.state.savedGame(kind),let restored=engine.restore(saved,completedSessions:Set(model.state.sessions.map(\.id))) {board=restored;sessionID=saved.sessionID;feedback="Your XI is right where you left it."}
        else {begin()}
    }
}
