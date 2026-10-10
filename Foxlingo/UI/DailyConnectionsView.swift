import SwiftUI

struct DailyConnectionsView:View {
    let pack:DailyChallengePack
    let round:DailyConnections
    @EnvironmentObject private var model:AppModel
    @Environment(\.scenePhase) private var phase
    @State private var progress:ConnectionsProgress?
    @State private var level:ConnectionsLevel = .normal
    @State private var reveal=false
    @State private var saveError=""
    private var board:DailyConnectionBoard {round.board(progress?.level ?? level)}
    var body:some View {
        ScrollViewReader {reader in
            ScrollView {
                VStack(alignment:.leading,spacing:16) {
                    HStack {Text(pack.isToday(model.now) ? "DAILY CONNECTIONS":"SAVED · "+pack.gameDate).font(.caption.bold()).tracking(1);Spacer();Text("\(progress?.solved.count ?? 0) / 4").font(.headline.monospacedDigit()).accessibilityIdentifier("daily-connections-count")}
                    if progress?.status == .ready {
                        Text("Sixteen players. Four connections.").font(.title2.bold())
                        Text("Find four players sharing one of today’s hidden groups. Clubs, countries, awards and career stories.").font(.subheadline).foregroundStyle(Palette.muted)
                        Picker("Difficulty",selection:$level) {ForEach(ConnectionsLevel.allCases,id:\.self) {Text($0.rawValue.capitalized).tag($0)}}.pickerStyle(.segmented).accessibilityIdentifier("daily-connections-level")
                        Text(level == .easy ? "Simpler source categories, unlimited mistakes.":level == .normal ? "The full category pool, unlimited mistakes.":"The Normal puzzle, with five mistakes allowed.").font(.caption).foregroundStyle(Palette.muted)
                        PrimaryButton(title:"Start connections",symbol:"play.fill") {start()}.accessibilityIdentifier("daily-connections-start")
                    } else if let p=progress {
                        if p.finished {HStack {Leopard(pose:p.status == .won ? "celebrate":"welcome").frame(width:56,height:66);VStack(alignment:.leading,spacing:4) {Text(p.status == .won ? "Every group found!":p.level == .hard ? "Five mistakes. New connections.":"Connections to explore.").font(.title2.bold()).accessibilityIdentifier("daily-connections-result");Text(p.status == .won ? "Four football stories connected.":"The remaining source groups are revealed below.").font(.subheadline).foregroundStyle(Palette.muted)}}}
                        else {Text("Pick four players with a shared connection.").font(.headline)}
                        HStack {Text(p.level.rawValue.capitalized+" · \(p.checks) checks").font(.caption.bold()).foregroundStyle(Palette.muted);Spacer();if p.level == .hard {HStack(spacing:5) {ForEach(0..<5,id:\.self) {i in Image(systemName:i < 5-p.errors ? "circle.fill":"circle").font(.caption).foregroundStyle(Palette.brand)}}.accessibilityElement(children:.ignore).accessibilityLabel("\(5-p.errors) mistakes remaining").accessibilityIdentifier("daily-connections-lives")}}
                        if let result=p.lastCheck,!p.finished {Text(result == .correct ? "Group connected. Find the next one.":result == .near ? "Three belong to one of today’s groups. Change one player.":"These four aren’t one of today’s groups. Try another selection.").font(.subheadline).foregroundStyle(result == .correct ? Palette.brand:Palette.red).accessibilityIdentifier("daily-connections-feedback")}
                        ForEach(p.solved.compactMap {id in board.groups.first {$0.id == id}},id:\.id) {group in groupRow(group,solved:true)}
                        if p.finished {ForEach(board.groups.filter {!p.solved.contains($0.id)},id:\.id) {group in groupRow(group,solved:false)}}
                        else {
                            LazyVGrid(columns:Array(repeating:GridItem(.flexible(),spacing:6),count:4),spacing:8) {
                                ForEach(board.order.filter {p.available(in:round).contains($0)},id:\.self) {id in
                                    if let player=round.player(id) {Button {progress?.select(id,in:round);model.playSound(.reveal);persist()} label: {
                                        VStack(spacing:4) {EntityArtwork(asset:player.imageAsset,url:player.imageURL,initials:String(player.name.prefix(2)),size:68,isPlayer:true,portraitFocus:true);Text(player.name).font(.system(size:11,weight:.semibold)).lineLimit(2).minimumScaleFactor(0.75).frame(height:30)}.frame(maxWidth:.infinity).padding(.vertical,8).background(p.selected.contains(id) ? Palette.brand.opacity(0.12):.white,in:RoundedRectangle(cornerRadius:12)).overlay {RoundedRectangle(cornerRadius:12).stroke(p.selected.contains(id) ? Palette.brand:Palette.brand.opacity(0.1),lineWidth:p.selected.contains(id) ? 2:1)}
                                    }.buttonStyle(PressFeedback()).accessibilityLabel(player.name).accessibilityValue(p.selected.contains(id) ? "Selected":"Not selected").accessibilityIdentifier("daily-connections-player-"+id)}
                                }
                            }
                        }
                        Text("\(pack.gameDate) · Groups follow this source snapshot and may describe historical clubs or dated achievements. Other real connections between these players may exist.").font(.caption).foregroundStyle(Palette.muted)
                    }
                    if !saveError.isEmpty {Text(saveError).font(.caption).foregroundStyle(Palette.red)}
                }.padding(16).id("connections-top")
            }.onChange(of:progress?.solved.count) {reader.scrollTo("connections-top",anchor:.top)}
        }.journal().navigationTitle("Daily Connections").navigationBarTitleDisplayMode(.inline).toolbar(.hidden,for:.tabBar)
        .safeAreaInset(edge:.bottom) {if let p=progress,p.status == .playing {HStack(spacing:12) {
            PrimaryButton(title:"Check \(p.selected.count) / 4",symbol:"checkmark",action:check).disabled(p.selected.count != 4).accessibilityIdentifier("daily-connections-check")
            Button("Clear selection",systemImage:"xmark.circle") {progress?.clear();persist()}.labelStyle(.iconOnly).font(.title2).disabled(p.selected.isEmpty).accessibilityIdentifier("daily-connections-clear")
            if p.level != .hard {Button("Reveal groups",systemImage:"eye") {reveal=true}.labelStyle(.iconOnly).font(.title2).accessibilityIdentifier("daily-connections-reveal")}
        }.padding(16).background(.regularMaterial)}}
        .confirmationDialog("Reveal the groups and finish this round?",isPresented:$reveal,titleVisibility:.visible) {Button("Reveal groups",role:.destructive) {if progress?.giveUp(in:round) == true {model.playSound(.reveal);handleResult();persist()}}}
        .onAppear {restore()}.onDisappear {persist()}.onChange(of:phase) {if phase != .active {persist()}}.onChange(of:level) {if progress?.status == .ready {progress?.level=level;persist()}}
    }
    private func groupRow(_ group:DailyConnectionGroup,solved:Bool)->some View {
        let artwork=model.games?.category("category-"+String(group.id.split(separator:"-").last!))
        return VStack(alignment:.leading,spacing:8) {
            HStack {if let artwork,artwork.title == group.title,artwork.imageAsset != nil || artwork.imageURL != nil {GameCategoryMark(category:artwork,size:28).accessibilityIdentifier("daily-connections-category-"+group.id)};Text(group.title).font(.subheadline.bold());Spacer();Text(solved ? "Found":"Revealed").font(.caption).foregroundStyle(Palette.muted)}
            HStack(spacing:8) {ForEach(group.playerIDs,id:\.self) {id in if let player=round.player(id) {VStack(spacing:4) {EntityArtwork(asset:player.imageAsset,url:player.imageURL,initials:String(player.name.prefix(2)),size:58,isPlayer:true,portraitFocus:true);Text(player.name).font(.caption2).lineLimit(2).frame(height:28)}.frame(maxWidth:.infinity)}}}
        }.padding(12).background(solved ? Palette.brand.opacity(0.08):.white,in:RoundedRectangle(cornerRadius:14)).accessibilityIdentifier("daily-connections-group-"+group.id)
    }
    private func restore() {guard progress == nil else {return};progress=model.dailyCache?.progress(for:round) ?? ConnectionsProgress(round:round);level=progress!.level;handleResult();persist()}
    private func start() {if progress?.start(in:round,level:level) == true {model.playSound(.reveal);persist()}}
    private func check() {guard let result=progress?.check(in:round) else {return};model.respond(result == .correct,event:result == .correct ? progress?.status == .won ? .completion:.connection:.mismatch);handleResult();persist()}
    private func handleResult() {
        guard var p=progress,p.finished else {return}
        if p.status == .won,model.state.completeGame(id:p.sessionID,kind:"connections",count:16,now:model.now) {model.save()}
        if !p.reviewRecorded {for ids in p.mistakes {model.state.recordPracticeGap(PracticeGap(game:"connections",context:"Daily hidden groups",subjectIDs:[],timestamp:model.now,referenceNames:ids.compactMap {round.player($0)?.name},referencePlayerIDs:ids));model.save()};p.reviewRecorded=true;progress=p}
    }
    private func persist() {guard let progress else {return};do {try model.dailyCache?.save(progress,for:round)} catch {saveError="Couldn’t save these connections: "+error.localizedDescription}}
}
