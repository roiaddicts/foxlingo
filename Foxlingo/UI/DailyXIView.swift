import SwiftUI

struct DailyXIView:View {
    let pack:DailyChallengePack
    let round:DailyXI
    @EnvironmentObject private var model:AppModel
    @Environment(\.scenePhase) private var phase
    @Environment(\.accessibilityReduceMotion) private var reduced
    @State private var progress:DailyXIProgress?
    @State private var level:DailyXILevel = .normal
    @State private var timer=0
    @State private var selected:String?
    @State private var choosing=false
    @State private var reveal=false
    @State private var feedback=""
    @State private var clock=Date()
    private let ticker=Timer.publish(every:0.25,on:.main,in:.common).autoconnect()
    private var now:Date {ProcessInfo.processInfo.arguments.contains("-ui-testing") && !ProcessInfo.processInfo.arguments.contains("-test-live-game-clock") ? model.now:Date()}
    private var engine:DraftEngine {round.engine(progress?.level ?? level)}
    private var board:DraftProgress {progress?.board ?? round.initialBoard(level)}
    private var formation:DraftFormation {engine.pack.formations[0]}
    private var offered:DraftGroup? {board.offeredID.flatMap {engine.groups[$0]}}
    private var examples:[Int:DraftPick] {guard progress?.finished == true,progress?.status != .won else {return [:]};return engine.solution(round.initialBoard(progress!.level),nodeLimit:100_000) ?? [:]}
    private var pool:[GamePlayer] {let ids=Set(engine.mode.groups.flatMap(\.playerIDs));return engine.pack.players.filter {ids.contains($0.person.id)}.map(\.person)}
    var body:some View {
        ScrollView {
            VStack(alignment:.leading,spacing:12) {
                HStack {Text(pack.isToday(model.now) ? "DAILY XI":"SAVED · "+pack.gameDate).font(.caption.bold()).tracking(1);Spacer();Text("\(progress?.board?.placed.count ?? 0) / 11").font(.headline.monospacedDigit()).accessibilityIdentifier("daily-xi-count")}
                if progress?.finished == true {
                    HStack {Leopard(pose:progress?.status == .won ? "celebrate":"idle").frame(width:58,height:68);VStack(alignment:.leading,spacing:4) {Text(progress?.status == .won ? "Your XI is complete!":progress?.status == .lost ? "Time’s up.":"An XI to explore.").font(.title2.bold()).accessibilityIdentifier("daily-xi-result");Text(progress?.status == .won ? (board.assisted.isEmpty ? "Eleven connections made.":"\(board.assisted.count) helped picks to revisit."):"An example lineup is shown below.").font(.subheadline).foregroundStyle(Palette.muted)}}
                } else {
                    Text("Eleven offers. One formation.").font(.title2.bold())
                    Text("Find a player for the flag or shirt, then tap an open position.").font(.subheadline).foregroundStyle(Palette.muted)
                }
                if progress?.status == .ready {
                    Picker("Difficulty",selection:$level) {ForEach(DailyXILevel.allCases,id:\.self) {Text($0.rawValue.capitalized).tag($0)}}.pickerStyle(.segmented).accessibilityIdentifier("daily-xi-level")
                    if round.id == "legends" {Text(level == .normal ? "Historical pool, excluding records marked active.":"The same countries, with the source’s active records included.").font(.caption).foregroundStyle(Palette.muted)}
                    Picker("Timer",selection:$timer) {Text("No timer").tag(0);Text("40s").tag(40);Text("60s").tag(60);Text("90s").tag(90)}.pickerStyle(.segmented).accessibilityIdentifier("daily-xi-timer")
                    if timer != 0 {Text("The timer pauses when you leave this game.").font(.caption).foregroundStyle(Palette.muted)}
                }
                HStack {Text(formation.id.map(String.init).joined(separator:"–")).font(.headline).accessibilityIdentifier("daily-xi-formation");Spacer();Text((progress?.level ?? level).rawValue.capitalized).font(.caption.bold()).foregroundStyle(Palette.muted)}
                ProgressView(value:Double(progress?.board?.placed.count ?? 0),total:11)
                if progress?.status == .playing,let offered {
                    HStack(spacing:12) {mark(offered,size:52);VStack(alignment:.leading,spacing:3) {Text(offered.name).font(.headline).accessibilityIdentifier("daily-xi-offered");Text(selected.flatMap {engine.profiles[$0]?.person.name} ?? "Find a player for this offer").font(.subheadline).accessibilityIdentifier("daily-xi-selected");if selected != nil {Text("Tap a highlighted position").font(.caption).foregroundStyle(Palette.muted)}};Spacer(minLength:0);if let person=selected.flatMap({engine.profiles[$0]?.person}) {portrait(person,group:offered,size:58)}}.padding(10).background(.white,in:RoundedRectangle(cornerRadius:16))
                }
                GeometryReader {geo in
                    let width=(geo.size.width-24-CGFloat((formation.rows.map(\.count).max() ?? 4)-1)*6)/CGFloat(formation.rows.map(\.count).max() ?? 4)
                    VStack(spacing:8) {ForEach(formation.rows.indices,id:\.self) {row in HStack(spacing:6) {ForEach(formation.rows[row],id:\.self) {slot in slotCard(slot,width:width)}}.frame(maxWidth:.infinity)}}.padding(12).frame(maxWidth:.infinity,maxHeight:.infinity).background(Palette.brand.opacity(0.09),in:RoundedRectangle(cornerRadius:20))
                }.frame(height:CGFloat(formation.rows.count)*110+CGFloat(formation.rows.count-1)*8+24)
                if !feedback.isEmpty {Text(feedback).font(.subheadline).foregroundStyle(Palette.brand).accessibilityIdentifier("daily-xi-feedback")}
                if progress?.status == .playing {Button("Reveal an example XI",systemImage:"eye") {reveal=true}.font(.subheadline).accessibilityIdentifier("daily-xi-reveal")}
                DisclosureGroup("\(pack.gameDate) · Squad context") {Text(engine.mode.scope).font(.caption).foregroundStyle(Palette.muted);if let url=URL(string:engine.mode.sourceURL) {Link("Futbol11 reference",destination:url).font(.caption)}}
            }.padding(16)
        }.journal().navigationTitle("Daily "+round.title).navigationBarTitleDisplayMode(.inline).toolbar(.hidden,for:.tabBar)
        .safeAreaInset(edge:.bottom) {
            if progress?.status == .ready {PrimaryButton(title:"Start XI",symbol:"play.fill",action:start).padding(16).background(.regularMaterial).accessibilityIdentifier("daily-xi-start")}
            else if progress?.status == .playing {
                HStack(spacing:10) {if let seconds=progress?.remaining(at:now) {Text("\(seconds)s").font(.headline.monospacedDigit()).accessibilityIdentifier("daily-xi-clock")};Button {undo()} label:{Image(systemName:"arrow.uturn.backward").frame(width:30,height:48)}.disabled(board.history.isEmpty).accessibilityLabel("Undo").accessibilityIdentifier("daily-xi-undo");PrimaryButton(title:selected == nil ? "Find a player":"Change player",symbol:"magnifyingglass") {choosing=true}.accessibilityIdentifier("daily-xi-search");Button {help()} label:{Image(systemName:"lightbulb").frame(width:30,height:48)}.accessibilityLabel("Help me connect").accessibilityIdentifier("daily-xi-help")}.padding(14).background(.regularMaterial)
            }
        }
        .sheet(isPresented:$choosing) {if let offered {NavigationStack {PlayerAnswerSheet(players:pool,title:"Choose a player",contextClubName:offered.name,contextClubImageURL:offered.imageURL,contextClubImageAsset:offered.imageAsset,contextTitle:round.title,rejectionMessage:"That player isn’t listed for this offer and an open position.",fallbackImageAsset:offered.imageAsset,fallbackImageURL:offered.imageURL) {choose($0)}}.presentationDetents([.large])}}
        .confirmationDialog("Reveal an example and finish this round?",isPresented:$reveal,titleVisibility:.visible) {Button("Reveal example XI",role:.destructive) {giveUp()}}
        .onAppear {restore()}.onDisappear {pause()}
        .onChange(of:level) {if progress?.status == .ready {progress?.level=level;persist()}}.onChange(of:timer) {if progress?.status == .ready {progress?.timer=timer;persist()}}
        .onChange(of:phase) {clock=Date();if phase == .active {progress?.resume(at:now);tick()} else {pause()}}
        .onReceive(ticker) {date in guard phase == .active,progress?.status == .playing,progress?.timer != 0 else {return};if Int(date.timeIntervalSince1970) != Int(clock.timeIntervalSince1970) {clock=date;tick();persist()}}
    }
    private func mark(_ group:DraftGroup,size:CGFloat)->some View {EntityArtwork(asset:group.imageAsset.isEmpty ? nil:group.imageAsset,url:group.imageURL,initials:"⚽",size:size)}
    @ViewBuilder private func portrait(_ player:GamePlayer,group:DraftGroup,size:CGFloat)->some View {if player.imageURL != nil {EntityArtwork(asset:player.imageAsset,url:player.imageURL,initials:"⚽",size:size,isPlayer:true,portraitFocus:true)} else {mark(group,size:size)}}
    private func slotCard(_ slot:Int,width:CGFloat)->some View {
        let example=examples[slot],pick=example ?? board.placed[slot],eligible=progress?.status == .playing && (selected.map {engine.accepts($0,at:slot,on:board)} ?? false)
        return Button {guard let selected,progress?.status == .playing else {return};_ = place(selected,slot:slot)} label: {
            VStack(spacing:3) {Text(formation.positions[slot]).font(.system(size:10,weight:.bold)).foregroundStyle(Palette.brand);if let pick,let player=engine.profiles[pick.playerID]?.person,let group=engine.groups[pick.groupID] {portrait(player,group:group,size:min(68,width-8));Text(player.name).font(.system(size:10,weight:.semibold)).lineLimit(2).minimumScaleFactor(0.75).multilineTextAlignment(.center).frame(height:24)} else {if let offered {mark(offered,size:min(50,width-8)).opacity(eligible ? 0.9:0.3)};Image(systemName:eligible ? "plus.circle.fill":"plus").font(.title3).frame(maxHeight:.infinity)}}.frame(width:width,height:110).background(eligible ? Palette.brand.opacity(0.15):.white.opacity(0.95),in:RoundedRectangle(cornerRadius:12)).overlay {RoundedRectangle(cornerRadius:12).stroke(eligible ? Palette.brand:.clear,lineWidth:2)}
        }.buttonStyle(PressFeedback()).disabled(progress?.status != .playing || board.placed[slot] != nil).accessibilityLabel(formation.positions[slot]+(pick.flatMap {engine.profiles[$0.playerID]?.person.name}.map {", "+$0} ?? ", open")+(example != nil ? ", example":"")).accessibilityIdentifier("daily-xi-slot-\(slot)")
    }
    private func restore() {guard progress == nil else {return};progress=model.dailyCache?.progress(for:round) ?? DailyXIProgress(round:round);level=progress!.level;timer=progress!.timer;progress?.resume(at:now);tick();handleResult();persist()}
    private func start() {guard progress?.start(in:round,level:level,timer:timer,now:now) == true else {return};feedback="";persist();model.playSound(.reveal)}
    private func choose(_ player:GamePlayer)->Bool {
        tick();guard progress?.status == .playing else {return false}
        guard formation.positions.indices.contains(where:{engine.accepts(player.id,at:$0,on:board)}) else {recordGap(player,context:offered?.name ?? round.title);model.respond(false,event:.mismatch);return false}
        selected=player.id;choosing=false;feedback="Choose a highlighted position for "+player.name+".";model.playSound(.reveal);return true
    }
    @discardableResult private func place(_ id:String,slot:Int,assisted:Bool=false)->Bool {
        guard var p=progress else {return false};let group=offered;let ok=p.place(id,at:slot,in:round,now:now,assisted:assisted)
        withAnimation(reduced ? nil:.spring(duration:0.25)) {progress=p;if ok {selected=nil}}
        if ok {choosing=false;feedback=p.status == .won ? "Eleven connections made.":"Connection made!";model.respond(true,event:p.status == .won ? .completion:.connection)}
        else if !p.finished {if let player=engine.profiles[id]?.person {recordGap(player,context:(group?.name ?? round.title)+" · "+formation.positions[slot])};feedback="Try a highlighted position, or choose another player.";model.respond(false,event:.mismatch)}
        handleResult();persist();return ok
    }
    private func undo() {if progress?.undo(in:round,now:now) == true {selected=nil;feedback="Try another connection.";model.playSound(.reveal)};handleResult();persist()}
    private func help() {tick();guard progress?.status == .playing,let id=board.offeredID,let answer=engine.solution(board,nodeLimit:100_000)?.first(where:{$0.value.groupID == id}) else {feedback="Undo a pick to make room for a complete XI.";return};_ = place(answer.value.playerID,slot:answer.key,assisted:true)}
    private func giveUp() {if progress?.reveal(in:round,now:now) == true {choosing=false;selected=nil;feedback="";model.playSound(.reveal)};handleResult();persist()}
    private func tick() {if progress?.expire(at:now) == true {choosing=false;selected=nil;feedback="";model.respond(false,event:.mismatch);handleResult();persist()}}
    private func pause() {progress?.pause(at:now);handleResult();persist()}
    private func recordGap(_ player:GamePlayer,context:String) {model.recordGameGap(game:round.kind,context:round.title+" · "+context,names:[player.name],assets:offered.map {[$0.imageAsset]} ?? [],playerIDs:[player.id])}
    private func handleResult() {
        guard var p=progress,p.finished else {return}
        if p.status == .won,model.state.completeGame(id:p.sessionID,kind:round.kind,count:11,now:model.now) {model.save()}
        if !p.reviewRecorded {for slot in board.assisted {if let pick=board.placed[slot],let player=engine.profiles[pick.playerID]?.person {recordGap(player,context:(engine.groups[pick.groupID]?.name ?? "")+" · "+formation.positions[slot])}};if p.status != .won {for id in board.groupIDs.dropFirst(board.placed.count) {if let g=engine.groups[id] {model.recordGameGap(game:round.kind,context:round.title+" · Unfinished offer",names:[g.name])}}};p.reviewRecorded=true;progress=p}
    }
    private func persist() {guard var snapshot=progress else {return};snapshot.pause(at:now);do {try model.dailyCache?.save(snapshot,for:round)} catch {feedback="Couldn’t save this XI: "+error.localizedDescription}}
}
