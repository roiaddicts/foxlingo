import SwiftUI

struct DailyWordleView:View {
    let pack:DailyChallengePack
    let round:DailyWordle
    @EnvironmentObject private var model:AppModel
    @Environment(\.scenePhase) private var phase
    @State private var progress:DailyWordleProgress?
    @State private var feedback=""
    private var finished:Bool {progress?.finished(round) == true}
    var body:some View {
        ScrollViewReader {proxy in
            ScrollView {
                VStack(alignment:.leading,spacing:14) {
                    HStack {Text(pack.isToday(model.now) ? "DAILY FOOTBALL NAME":"SAVED · "+pack.gameDate).font(.caption.bold()).tracking(1);Spacer();Text("\(progress?.guesses.count ?? 0) / 6").font(.headline.monospacedDigit()).accessibilityIdentifier("daily-wordle-count")}.id("wordle-top")
                    Text("One name. Six chances.").font(.title2.bold())
                    Text("Find the \(round.answer.count)-letter football name. Blue means the right spot; gold means another spot.").font(.subheadline).foregroundStyle(Palette.muted)
                    if progress?.guesses.isEmpty == true {
                        Picker("Difficulty",selection:Binding(get:{progress?.mode ?? .normal},set:{mode in if progress?.setMode(mode,in:round) == true {feedback="";persist()}})) {Text("Normal").tag(DailyWordleDifficulty.normal);Text("Easy").tag(DailyWordleDifficulty.easy)}.pickerStyle(.segmented).accessibilityIdentifier("daily-wordle-mode")
                    }
                    if !finished {Text(progress?.mode == .easy ? "Easy · Any letter sequence is accepted.":"Normal · Use a name in the source catalog.").font(.caption).foregroundStyle(Palette.muted)}
                    VStack(spacing:7) {
                        ForEach(0..<6,id:\.self) {index in
                            let guess=progress.flatMap {$0.guesses.indices.contains(index) ? $0.guesses[index]:nil}
                            let word=guess ?? (index == progress?.guesses.count && !finished ? progress?.input ?? "":"")
                            let letters=Array(word),marks=guess.flatMap {FootballWordle.feedback(guess:$0,answer:round.answer)}
                            HStack(spacing:6) {ForEach(0..<round.answer.count,id:\.self) {column in Text(letters.indices.contains(column) ? String(letters[column]):" ").font(.system(size:24,weight:.bold,design:.rounded)).frame(maxWidth:.infinity).frame(height:44).background(color(marks?[column]),in:RoundedRectangle(cornerRadius:9)).foregroundStyle(marks == nil ? Palette.brand:.white)}}
                            .accessibilityElement(children:.ignore).accessibilityLabel("Guess \(index+1): \(word.isEmpty ? "empty":word)").accessibilityValue(marks?.map(\.rawValue).joined(separator:", ") ?? "Not submitted").accessibilityIdentifier("daily-wordle-row-\(index)")
                        }
                    }
                    if !feedback.isEmpty {Text(feedback).font(.subheadline).foregroundStyle(Palette.muted).accessibilityIdentifier("daily-wordle-feedback")}
                    if finished {
                        HStack {Leopard().frame(width:62,height:72);VStack(alignment:.leading,spacing:4) {Text(progress?.won(round) == true ? "Name found!":"A name to remember.").font(.title2.bold()).accessibilityIdentifier("daily-wordle-result");Text(round.answer).font(.title2.bold().monospaced()).accessibilityIdentifier("daily-wordle-answer")}}
                        if !round.matchingPlayers.isEmpty {
                            Text("Players with this name").font(.headline)
                            ScrollView(.horizontal,showsIndicators:false) {HStack(alignment:.top,spacing:18) {ForEach(round.matchingPlayers) {player in VStack(spacing:7) {EntityArtwork(asset:player.imageAsset,url:player.imageURL,initials:String(player.name.prefix(2)),size:80,isPlayer:true,portraitFocus:true);Text(player.name).font(.caption.bold()).frame(width:96)}.accessibilityIdentifier("daily-wordle-player-"+player.id)}}}
                        }
                        Text("Today’s result is saved. Try practice Wordle for more names.").font(.subheadline).foregroundStyle(Palette.muted)
                    }
                    Text("\(pack.gameDate) · Source dictionary names, surnames and nicknames. A name can belong to several players.").font(.caption).foregroundStyle(Palette.muted)
                }.padding(16)
            }.onChange(of:finished) {if finished {withAnimation(.snappy(duration:0.25)) {proxy.scrollTo("wordle-top",anchor:.top)}}}
        }.journal().navigationTitle("Daily Wordle").navigationBarTitleDisplayMode(.inline).toolbar(.hidden,for:.tabBar)
        .safeAreaInset(edge:.bottom) {if !finished {keyboard}}
        .onAppear {restore()}.onDisappear {persist()}.onChange(of:phase) {if phase != .active {persist()}}
    }
    private var keyboard:some View {
        VStack(spacing:6) {
            ForEach(["QWERTYUIOP","ASDFGHJKL","ZXCVBNM"],id:\.self) {row in
                HStack(spacing:4) {ForEach(Array(row),id:\.self) {letter in
                    let mark=round.keyMark(letter,guesses:progress?.guesses ?? [])
                    Button {if progress?.type(letter,in:round) == true {feedback="";model.playSound(.reveal);persist()}} label: {Text(String(letter)).font(.system(size:14,weight:.bold)).frame(maxWidth:.infinity).frame(height:38).background(color(mark),in:RoundedRectangle(cornerRadius:7)).foregroundStyle(mark == nil ? Palette.brand:.white)}.accessibilityIdentifier("daily-wordle-key-\(letter)")
                }}
            }
            HStack {Button("Delete",systemImage:"delete.left") {if progress?.delete(in:round) == true {feedback="";persist()}}.frame(minHeight:38).accessibilityIdentifier("daily-wordle-delete");Spacer();Button("Check name",systemImage:"checkmark") {submit()}.font(.headline).frame(minHeight:38).disabled(progress?.input.count != round.answer.count).accessibilityIdentifier("daily-wordle-submit")}
        }.padding(12).background(.regularMaterial)
    }
    private func color(_ mark:LetterMark?)->Color {switch mark {case .correct:Palette.brand;case .present:Palette.ochre;case .absent:Palette.muted;case nil:.white}}
    private func restore() {guard progress == nil else {return};progress=model.dailyCache?.progress(for:round) ?? DailyWordleProgress(round:round);handleResult();persist()}
    private func submit() {
        guard var p=progress,!p.finished(round) else {return}
        guard p.submit(in:round) else {feedback=p.guesses.isEmpty ? "That name isn’t in the source catalog. Try another, or choose Easy before your first guess.":"That name isn’t in the source catalog. Try another.";model.respond(false,event:.mismatch);return}
        progress=p;feedback=""
        if p.won(round) {model.respond(true,event:.completion)} else if p.finished(round) {model.respond(false,event:.mismatch)} else {model.playSound(.reveal)}
        handleResult();persist()
    }
    private func handleResult() {
        guard var p=progress,p.finished(round) else {return}
        if p.won(round),model.state.completeGame(id:p.sessionID,kind:"wordle",count:p.guesses.count,now:model.now) {model.save()}
        if !p.reviewRecorded {
            if !p.won(round) {
                // A surname alone cannot safely choose a canonical footballer.
                model.state.recordPracticeGap(PracticeGap(game:"wordle",context:"Daily football name",subjectIDs:[],timestamp:model.now,referenceNames:[round.answer],referencePlayerIDs:round.matchingPlayers.map(\.id)));model.save()
            }
            p.reviewRecorded=true;progress=p
        }
    }
    private func persist() {guard let progress else {return};do {try model.dailyCache?.save(progress,for:round)} catch {feedback="Couldn’t save this round: "+error.localizedDescription}}
}
