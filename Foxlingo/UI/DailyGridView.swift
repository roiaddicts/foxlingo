import SwiftUI

struct DailyGridView:View {
    let pack:DailyChallengePack
    let round:DailyGrid
    @EnvironmentObject private var model:AppModel
    @Environment(\.scenePhase) private var phase
    @State private var progress:DailyGridProgress?
    @State private var level:DailyGridLevel = .easy
    @State private var timer=0
    @State private var choosing=false
    @State private var selectedSlot:Int?
    @State private var proposed:String?
    @State private var inspected:GameCategory?
    @State private var reveal=false
    @State private var feedback=""
    @State private var clock=Date()
    @State private var lastSaved=Date.distantPast
    private let ticker=Timer.publish(every:0.25,on:.main,in:.common).autoconnect()
    private var now:Date {ProcessInfo.processInfo.arguments.contains("-ui-testing") && !ProcessInfo.processInfo.arguments.contains("-test-live-game-clock") ? model.now:Date()}
    private var board:DailyGridBoard {round.board(progress?.status == .ready ? level:progress?.level ?? level)}
    private var finished:Bool {progress?.finished == true}
    private var examples:[Int:String] {
        guard finished,progress?.status != .won else {return [:]}
        return BoardMatcher.solution(board.candidates,fixed:progress?.placed ?? [:]) ?? Dictionary(uniqueKeysWithValues:board.candidates.enumerated().compactMap {i,ids in ids.sorted().first.map {(i,$0)}})
    }
    private var proposedSlots:Set<Int> {guard let proposed,let p=progress,!p.placed.values.contains(proposed) else {return []};return Set(board.candidates.indices.filter {p.placed[$0] == nil && board.candidates[$0].contains(proposed)})}
    var body:some View {
        ScrollView {
            VStack(alignment:.leading,spacing:16) {
                HStack {Text(pack.isToday(model.now) ? "DAILY INTERSECTIONS":"SAVED · "+pack.gameDate).font(.caption.bold()).tracking(1);Spacer();Text("\(progress?.placed.count ?? 0) / 9").font(.headline.monospacedDigit()).accessibilityIdentifier("daily-grid-count")}
                if finished {
                    HStack {Leopard().frame(width:58,height:68);VStack(alignment:.leading,spacing:4) {Text(progress?.status == .won ? "Nine connections!":progress?.status == .lost ? "Time’s up.":"Explore the matches.").font(.title2.bold()).accessibilityIdentifier("daily-grid-result");Text(progress?.status == .won ? "A full grid to remember.":"Examples fill the open squares below.").font(.subheadline).foregroundStyle(Palette.muted)}}
                } else {
                    Text("Two categories. One player.").font(.title2.bold())
                    Text("Tap a square or find a player. Each player can be used once.").font(.subheadline).foregroundStyle(Palette.muted)
                }
                if progress?.status == .ready {
                    Picker("Difficulty",selection:$level) {ForEach(DailyGridLevel.allCases,id:\.self) {Text($0.rawValue.capitalized).tag($0)}}.pickerStyle(.segmented).accessibilityIdentifier("daily-grid-level")
                    Text(levelDescription).font(.caption).foregroundStyle(Palette.muted)
                    Picker("Timer",selection:$timer) {Text("No timer").tag(0);Text("60s").tag(60);Text("90s").tag(90)}.pickerStyle(.segmented).accessibilityIdentifier("daily-grid-timer")
                    if timer != 0 {Text("The timer pauses when you leave this game.").font(.caption).foregroundStyle(Palette.muted)}
                    PrimaryButton(title:"Start grid",symbol:"play.fill",action:start).accessibilityIdentifier("daily-grid-start")
                } else {Text("\(progress?.level.rawValue.capitalized ?? "") · \(timerLabel)").font(.caption.bold()).foregroundStyle(Palette.muted)}
                if !feedback.isEmpty {Text(feedback).font(.subheadline).foregroundStyle(Palette.muted).accessibilityIdentifier("daily-grid-feedback")}
                GeometryReader { geometry in
                    let width=(geometry.size.width-42-24)/3
                    VStack(spacing:8) {
                        HStack(spacing:8) {Color.clear.frame(width:42,height:48);ForEach(board.columns) {category in categoryHeader(category).frame(width:width)}}
                        ForEach(0..<3,id:\.self) {row in HStack(spacing:8) {categoryHeader(board.rows[row]).frame(width:42);ForEach(0..<3,id:\.self) {column in cell(row*3+column).frame(width:width)}}}
                    }
                }.frame(height:396)
                Text("\(pack.gameDate) · Source-listed category memberships, including historical clubs. An unlisted pairing is not proof that a player never made that connection. Tap a header to inspect its name.").font(.caption).foregroundStyle(Palette.muted)
            }.padding(16)
        }.journal().navigationTitle("Daily Grid").navigationBarTitleDisplayMode(.inline).toolbar(.hidden,for:.tabBar)
        .safeAreaInset(edge:.bottom) {if progress?.status == .playing {
            HStack {if let seconds=progress?.remaining(at:now) {Label("\(seconds)s",systemImage:"timer").font(.headline.monospacedDigit()).accessibilityIdentifier("daily-grid-clock")};Button("Undo",systemImage:"arrow.uturn.backward") {undo()}.labelStyle(.iconOnly).disabled(progress?.history.isEmpty != false).accessibilityIdentifier("daily-grid-undo");Button("Reveal",systemImage:"eye") {reveal=true}.labelStyle(.iconOnly).accessibilityIdentifier("daily-grid-reveal");Spacer();Button("Find a player",systemImage:"magnifyingglass") {selectedSlot=nil;proposed=nil;choosing=true}.font(.headline).accessibilityIdentifier("daily-grid-search")}.padding(16).background(.regularMaterial)
        }}
        .sheet(isPresented:$choosing) {NavigationStack {PlayerAnswerSheet(players:round.players,title:selectedSlot == nil ? "Find a player":"Find a match",clues:selectedSlot.map {[board.rows[$0/3],board.columns[$0%3]]} ?? [],rejectionMessage:"That player is already used or isn’t listed for this connection.") {choose($0)}}.presentationDetents([.large])}
        .sheet(item:$inspected) {category in NavigationStack {ScrollView {VStack(alignment:.leading,spacing:16) {GameCategoryMark(category:category,size:80);Text(category.title).font(.title2.bold());Text("Source catalog category").foregroundStyle(Palette.muted)}.padding(20)}.journal().navigationTitle("Category").navigationBarTitleDisplayMode(.inline).toolbar {Button("Done") {inspected=nil}}}.presentationDetents([.medium])}
        .confirmationDialog("Reveal examples and finish this round?",isPresented:$reveal,titleVisibility:.visible) {Button("Reveal examples",role:.destructive) {giveUp()}}
        .onAppear {restore()}.onDisappear {pause()}
        .onChange(of:level) {if progress?.status == .ready {progress?.level=level;persist()}}.onChange(of:timer) {if progress?.status == .ready {progress?.timer=timer;persist()}}.onChange(of:phase) {clock=Date();if phase == .active {progress?.resume(at:now);tick()} else {pause()}}
        .onReceive(ticker) {date in
            guard phase == .active,progress?.status == .playing,progress?.timer != 0 else {return}
            if Int(date.timeIntervalSince1970) != Int(clock.timeIntervalSince1970) {clock=date;tick();persist()}
        }
    }
    private var timerLabel:String {progress?.timer == 0 ? "No timer":"\(progress?.timer ?? 0)-second timer"}
    private var levelDescription:String {switch level {case .easy:"Major clubs and countries";case .normal:"Major club × club connections";case .hard:"Major clubs and a broader country pool";case .legend:"The widest source club and country pool"}}
    private func categoryHeader(_ category:GameCategory)->some View {Button {inspected=category} label:{GameCategoryMark(category:category,size:40).frame(maxWidth:.infinity).frame(height:48)}.accessibilityIdentifier("daily-grid-header-"+category.id)}
    private func cell(_ slot:Int)->some View {
        let actual=progress?.placed[slot],example=actual == nil ? examples[slot]:nil,player=(actual ?? example).flatMap(round.player)
        return Button {
            guard progress?.status == .playing,actual == nil else {return}
            if let proposed {if proposedSlots.contains(slot) {_ = place(proposed,slot:slot)} else {feedback="Choose a highlighted square, or search for another player."}} else {selectedSlot=slot;choosing=true}
        } label: {
            VStack(spacing:4) {if let player {EntityArtwork(asset:player.imageAsset,url:player.imageURL,initials:String(player.name.prefix(2)),size:72,isPlayer:true,portraitFocus:true);Text((example == nil ? "":"Example · ")+player.name).font(.caption2.bold()).lineLimit(2).minimumScaleFactor(0.8).frame(height:28)} else {Image(systemName:proposedSlots.contains(slot) ? "plus.circle.fill":"plus").font(.title3).frame(height:76);Text(" ").frame(height:24)}}.frame(maxWidth:.infinity).frame(height:108).background(actual != nil ? Palette.brand.opacity(0.1):proposedSlots.contains(slot) ? Palette.ochre.opacity(0.2):.white,in:RoundedRectangle(cornerRadius:14)).animation(nil,value:actual)
        }.buttonStyle(PressFeedback()).accessibilityLabel("\(board.rows[slot/3].title) and \(board.columns[slot%3].title), \(player?.name ?? "empty")\(example == nil ? "":", example")").accessibilityIdentifier("daily-grid-cell-\(slot)")
    }
    private func restore() {guard progress == nil else {return};progress=model.dailyCache?.progress(for:round) ?? DailyGridProgress(round:round);level=progress!.level;timer=progress!.timer;progress?.resume(at:now);tick();handleResult();persist()}
    private func start() {guard progress?.start(in:round,level:level,timer:timer,now:now) == true else {return};feedback="";persist();model.playSound(.reveal)}
    private func choose(_ player:GamePlayer)->Bool {
        if let slot=selectedSlot {return place(player.id,slot:slot)}
        guard let p=progress,p.status == .playing,!p.placed.values.contains(player.id) else {return false}
        let slots=board.candidates.indices.filter {p.placed[$0] == nil && board.candidates[$0].contains(player.id)}
        guard !slots.isEmpty else {return false}
        if slots.count == 1 {return place(player.id,slot:slots[0])}
        proposed=player.id;choosing=false;feedback="Choose a highlighted square for "+player.name+".";return true
    }
    private func place(_ player:String,slot:Int)->Bool {
        guard var p=progress else {return false};let ok=p.place(player,at:slot,in:round,now:now);progress=p
        if p.finished {choosing=false;proposed=nil} else if !ok {model.respond(false,event:.mismatch)}
        if ok {choosing=false;selectedSlot=nil;proposed=nil;feedback="A connection made!";model.respond(true,event:p.status == .won ? .completion:.correct)}
        handleResult();persist();return ok
    }
    private func undo() {if progress?.undo(in:round,now:now) == true {proposed=nil;feedback="Try a different connection.";persist()} else {handleResult();persist()}}
    private func giveUp() {if progress?.reveal(in:round,now:now) == true {choosing=false;proposed=nil;feedback="";model.playSound(.reveal)};handleResult();persist()}
    private func tick() {if progress?.expire(at:now) == true {choosing=false;proposed=nil;feedback="";model.respond(false,event:.mismatch);handleResult();persist()}}
    private func pause() {progress?.pause(at:now);handleResult();persist()}
    private func handleResult() {
        guard var p=progress,p.finished else {return}
        if p.status == .won,model.state.completeGame(id:p.sessionID,kind:"grid",count:9,now:model.now) {model.save()}
        if !p.reviewRecorded {
            for mistake in p.mistakes {if let player=round.player(mistake.playerID) {model.state.recordPracticeGap(PracticeGap(game:"grid",context:board.rows[mistake.slot/3].title+" × "+board.columns[mistake.slot%3].title,subjectIDs:[],timestamp:model.now,referenceNames:[player.name],referencePlayerIDs:[player.id]));model.save()}}
            if p.status != .won {for slot in board.candidates.indices where p.placed[slot] == nil {model.recordGameGap(game:"grid",context:"Daily intersection",names:[board.rows[slot/3].title,board.columns[slot%3].title])}}
            p.reviewRecorded=true;progress=p
        }
    }
    private func persist() {
        guard var snapshot=progress else {return};snapshot.pause(at:now)
        do {try model.dailyCache?.save(snapshot,for:round);lastSaved=clock} catch {feedback="Couldn’t save this grid: "+error.localizedDescription}
    }
}
