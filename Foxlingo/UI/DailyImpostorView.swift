import SwiftUI

struct DailyImpostorView:View {
    let pack:DailyChallengePack
    let round:DailyImpostor
    @EnvironmentObject private var model:AppModel
    @Environment(\.scenePhase) private var phase
    @State private var progress:ImpostorProgress?
    @State private var level:ImpostorLevel = .normal
    @State private var saveError=""
    @State private var correctionInfo=false
    private var artwork:GameCategory? {let matches=model.games?.categories.filter {$0.title == round.title && ($0.imageAsset != nil || $0.imageURL != nil)} ?? [];return matches.count == 1 ? matches[0]:nil}
    var body:some View {
        ScrollView {
            VStack(alignment:.leading,spacing:16) {
                HStack {Text(pack.isToday(model.now) ? "DAILY IMPOSTOR":"SAVED · "+pack.gameDate).font(.caption.bold()).tracking(1);Spacer();if let p=progress,p.status != .ready {Text("\(p.found) found").font(.headline.monospacedDigit()).accessibilityIdentifier("daily-impostor-count")}}
                if !round.reviews.isEmpty {Button("Reviewed data correction",systemImage:"info.circle") {correctionInfo=true}.font(.caption.bold()).accessibilityIdentifier("daily-impostor-corrections")}
                if progress?.status == .ready {
                    Text("Find the matches. Avoid the impostors.").font(.title2.bold())
                    Text("Ten portraits, one source category. Choose a way to play.").font(.subheadline).foregroundStyle(Palette.muted)
                    Picker("Mode",selection:$level) {Text("Normal").tag(ImpostorLevel.normal);Text("One by One").tag(ImpostorLevel.hard)}.pickerStyle(.segmented).accessibilityIdentifier("daily-impostor-level")
                    Text(level == .normal ? "Select every match. One submission finishes the round.":"Check one player at a time. The first impostor ends the round.").font(.subheadline).foregroundStyle(Palette.muted)
                    PrimaryButton(title:"Start impostor",symbol:"play.fill",action:start).accessibilityIdentifier("daily-impostor-start")
                } else if let p=progress {
                    if p.finished {
                        HStack {Leopard(pose:p.status == .won ? "celebrate":"welcome").frame(width:56,height:66);VStack(alignment:.leading,spacing:4) {Text(p.status == .won ? "Every match found!":"A football detail to learn.").font(.title2.bold()).accessibilityIdentifier("daily-impostor-result");Text(p.status == .won ? "You spotted the whole group.":"Explore the source matches, then take this connection into practice.").font(.subheadline).foregroundStyle(Palette.muted)}}
                        clue
                        if p.level == .normal {Text("\(p.found) correct · \(p.marks.values.filter {$0 == .missed}.count) missed · \(p.marks.values.filter {$0 == .wrong}.count) impostors selected").font(.subheadline).foregroundStyle(Palette.muted).accessibilityIdentifier("daily-impostor-summary")}
                        if p.level == .hard,p.status == .lost,!p.revealed {PrimaryButton(title:"Reveal correct players",symbol:"eye") {if progress?.reveal(in:round) == true {model.playSound(.reveal);handleResult();persist()}}.accessibilityIdentifier("daily-impostor-reveal")}
                    } else {Text(p.level == .normal ? "Select every player who matches. Submit once.":"Choose one player to check. Confirmed matches stay locked.").font(.subheadline).foregroundStyle(Palette.muted)}
                    LazyVGrid(columns:Array(repeating:GridItem(.flexible(),spacing:8),count:3),spacing:8) {
                        ForEach(p.order,id:\.self) {id in if let player=round.player(id) {card(player,p)}}
                    }
                    Text("\(pack.gameDate) · This source puzzle supplies the matches and impostors explicitly. Historical or dated categories follow that snapshot; classifications are not live career updates.").font(.caption).foregroundStyle(Palette.muted)
                }
                if !saveError.isEmpty {Text(saveError).font(.caption).foregroundStyle(Palette.red)}
            }.padding(16)
        }.journal().navigationTitle("Daily Impostor").navigationBarTitleDisplayMode(.inline).toolbar(.hidden,for:.tabBar)
        .safeAreaInset(edge:.top) {if progress?.status == .playing {clue.padding(.horizontal,16).padding(.vertical,10).background(.regularMaterial)}}
        .safeAreaInset(edge:.bottom) {if let p=progress,p.status == .playing {HStack(spacing:12) {
            PrimaryButton(title:p.level == .normal ? "Submit \(p.selected.count) players":"Check player",symbol:"checkmark",action:check).disabled(p.selected.isEmpty).accessibilityIdentifier("daily-impostor-check")
            Button("Clear selection",systemImage:"xmark.circle") {progress?.clear();persist()}.labelStyle(.iconOnly).font(.title2).disabled(p.selected.isEmpty).accessibilityIdentifier("daily-impostor-clear")
        }.padding(16).background(.regularMaterial)}}
        .sheet(isPresented:$correctionInfo) {NavigationStack {ScrollView {VStack(alignment:.leading,spacing:16) {ForEach(round.reviews) {review in Text(review.note).font(.body);Text("Reviewed "+review.reviewedAt).font(.caption).foregroundStyle(Palette.muted);ForEach(review.sources.indices,id:\.self) {i in if let url=URL(string:review.sources[i].url) {Link(review.sources[i].title,destination:url).font(.subheadline)}}}}.padding(20)}.journal().navigationTitle("Data correction").navigationBarTitleDisplayMode(.inline).toolbar {Button("Done") {correctionInfo=false}}}.presentationDetents([.medium,.large])}
        .onAppear {restore()}.onDisappear {persist()}.onChange(of:phase) {if phase != .active {persist()}}.onChange(of:level) {if progress?.status == .ready {progress?.level=level;persist()}}
    }
    private var clue:some View {HStack(spacing:12) {if let artwork {GameCategoryMark(category:artwork,size:42)} else {Image(systemName:"person.3.sequence.fill").font(.title2).foregroundStyle(Palette.brand).frame(width:42)};Text(round.title).font(.headline);Spacer(minLength:0)}.accessibilityIdentifier("daily-impostor-clue")}
    private func card(_ player:GamePlayer,_ p:ImpostorProgress)->some View {
        let mark=p.marks[player.id]
        return Button {progress?.select(player.id);model.playSound(.reveal);persist()} label: {
            VStack(spacing:4) {
                ZStack(alignment:.bottomTrailing) {EntityArtwork(asset:player.imageAsset,url:player.imageURL,initials:String(player.name.prefix(2)),size:84,isPlayer:true,portraitFocus:true);if let mark {Image(systemName:mark == .correct ? "checkmark.circle.fill":mark == .wrong ? "xmark.circle.fill":"questionmark.circle.fill").font(.system(size:16)).foregroundStyle(mark == .correct ? Palette.brand:mark == .wrong ? Palette.red:Palette.ochre).padding(2).background(.white,in:Circle())}}
                Text(player.name).font(.caption.bold()).lineLimit(2).minimumScaleFactor(0.75).frame(height:30)
            }.frame(maxWidth:.infinity).padding(.vertical,8).background(p.selected.contains(player.id) ? Palette.brand.opacity(0.12):.white,in:RoundedRectangle(cornerRadius:14)).overlay {RoundedRectangle(cornerRadius:14).stroke(p.selected.contains(player.id) ? Palette.brand:Palette.brand.opacity(0.1),lineWidth:p.selected.contains(player.id) ? 2:1)}
        }.buttonStyle(PressFeedback()).disabled(p.finished || mark != nil).accessibilityLabel(player.name).accessibilityValue(mark.map {$0 == .correct ? "Confirmed match":$0 == .wrong ? "Source puzzle impostor":"Missed source match"} ?? (p.selected.contains(player.id) ? "Selected":"Not selected")).accessibilityIdentifier("daily-impostor-player-"+player.id)
    }
    private func restore() {guard progress == nil else {return};progress=model.dailyCache?.progress(for:round) ?? ImpostorProgress(round:round);level=progress!.level;handleResult();persist()}
    private func start() {var rng=SystemRandomNumberGenerator();if progress?.start(in:round,level:level,rng:&rng) == true {model.playSound(.reveal);persist()}}
    private func check() {guard let correct=progress?.check(in:round) else {return};model.respond(correct,event:correct ? progress?.status == .won ? .completion:.correct:.mismatch);handleResult();persist()}
    private func handleResult() {
        guard var p=progress,p.finished else {return}
        if p.status == .won,model.state.completeGame(id:p.sessionID,kind:"impostor",count:round.positives(p.level).count,now:model.now) {model.save()}
        func record(_ ids:[String]) {for id in ids {if let player=round.player(id) {model.state.recordPracticeGap(PracticeGap(game:"impostor",context:round.title,subjectIDs:[],timestamp:model.now,referenceNames:[player.name],referencePlayerIDs:[id]));model.save()}}}
        if !p.reviewRecorded {record(p.marks.filter {$0.value == .wrong || p.level == .normal && $0.value == .missed}.map(\.key));p.reviewRecorded=true}
        if p.level == .hard,p.revealed,!p.revealReviewRecorded {record(p.marks.filter {$0.value == .missed}.map(\.key));p.revealReviewRecorded=true}
        progress=p
    }
    private func persist() {guard let progress else {return};do {try model.dailyCache?.save(progress,for:round)} catch {saveError="Couldn’t save this round: "+error.localizedDescription}}
}
