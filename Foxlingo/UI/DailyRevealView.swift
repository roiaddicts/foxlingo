import SwiftUI

// The clues are the workspace. Large shirts and portraits reveal in place;
// a compact heading and fixed search action keep the game above the keyboard.
struct DailyRevealView: View {
    let pack: DailyChallengePack
    let round: DailyRevealRound
    @EnvironmentObject private var model: AppModel
    @Environment(\.scenePhase) private var phase
    @Environment(\.accessibilityReduceMotion) private var reduced
    @State private var progress: DailyRevealProgress?
    @State private var choosing=false
    @State private var feedback=""
    @State private var difficulty: RevealDifficulty = .normal
    private var outcome: DailyRevealProgress.Outcome {progress?.outcome(round) ?? .playing}
    private var revealed: Set<String> {progress?.revealed(round) ?? []}
    private var clues: [DailyClue] {
        let eligible=Set(round.clueIDs(progress?.difficulty ?? difficulty))
        return round.clues.filter {eligible.contains($0.id) && $0.id != "season"}
    }
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:16) {
                HStack {
                    Text(pack.isToday(model.now) ? "DAILY CHALLENGE":"SAVED · "+pack.gameDate).font(.caption.bold()).tracking(1)
                    Spacer();Text("\(progress?.attempts.count ?? 0) / \(round.mode.limit) chances").font(.subheadline.monospacedDigit()).accessibilityIdentifier("reveal-attempts")
                }
                Text(round.mode.instruction).font(.title3.bold())
                if round.mode == .statdle {
                    if let season=round.clues.first(where:{$0.id == "season"}) {
                        HStack(spacing:12) {EntityArtwork(asset:nil,url:season.imageURL,initials:"⚽",size:44);Text(season.value+" · "+season.title).font(.headline);Spacer()}.accessibilityIdentifier("reveal-season")
                    }
                    if progress?.attempts.isEmpty == true && outcome == .playing {
                        Picker("Difficulty",selection:$difficulty) {Text("Normal").tag(RevealDifficulty.normal);Text("Hard").tag(RevealDifficulty.hard)}.pickerStyle(.segmented).onChange(of:difficulty) {changeDifficulty()}.accessibilityIdentifier("statdle-difficulty")
                        if difficulty == .hard {Text("Club and nationality stay hidden.").font(.caption).foregroundStyle(Palette.muted)}
                    }
                }
                if outcome != .playing {
                    HStack(spacing:16) {
                        EntityArtwork(asset:round.answer.imageAsset,url:round.answer.imageURL,initials:String(round.answer.name.prefix(2)),size:88,isPlayer:true,portraitFocus:true)
                            .transition(.scale(scale:0.85).combined(with:.opacity))
                        VStack(alignment:.leading,spacing:5) {
                            Text(round.answer.name).font(.title2.bold()).accessibilityIdentifier("reveal-answer")
                            Text(outcome == .won ? "Connection found!":"A new name to remember.").font(.subheadline).foregroundStyle(Palette.muted)
                        }
                        Spacer()
                    }
                }
                LazyVGrid(columns:[GridItem(.flexible(),spacing:12),GridItem(.flexible(),spacing:12)],spacing:12) {
                    ForEach(clues) {clue in clueCell(clue)}
                }
                if outcome == .playing {
                    let allRevealed=progress.map {$0.revealed(round).count == $0.order.count} ?? false
                    Text(allRevealed ? (progress?.attempts.count == round.mode.limit-1 ? "All clues are revealed. This is your final chance.":"All clues are revealed. You can still name the player.") : "\(round.mode == .statdle ? "Two new clues" : "One new clue") after a wrong guess or a skip. Guess whenever you’re ready.").font(.subheadline).foregroundStyle(Palette.muted)
                }
                if !feedback.isEmpty {Text(feedback).font(.subheadline).foregroundStyle(Palette.muted).accessibilityIdentifier("reveal-feedback")}
                if let progress,!progress.attempts.isEmpty {
                    HStack(spacing:6) {ForEach(Array(progress.attempts.enumerated()),id:\.offset) {_,attempt in
                        if let id=attempt.playerID,let player=round.players.first(where:{$0.id == id}) {
                            EntityArtwork(asset:player.imageAsset,url:player.imageURL,initials:String(player.name.prefix(2)),size:38,isPlayer:true,portraitFocus:true).accessibilityLabel(player.name)
                        } else {Image(systemName:"forward.end").frame(width:38,height:38).foregroundStyle(Palette.muted).accessibilityLabel("Skipped turn")}
                    };Spacer()}.accessibilityIdentifier("reveal-history")
                }
                Text(pack.gameDate+" · "+round.scope).font(.caption).foregroundStyle(Palette.muted)
            }.padding(20)
        }.journal().navigationTitle(round.mode.title).navigationBarTitleDisplayMode(.inline).toolbar(.hidden,for:.tabBar)
        .animation(reduced ? nil:.snappy(duration:0.28),value:progress?.attempts.count)
        .safeAreaInset(edge:.bottom) {
            if outcome == .playing {
                HStack {
                    Button(progress?.attempts.count == round.mode.limit-1 ? "Reveal answer":"Skip",systemImage:progress?.attempts.count == round.mode.limit-1 ? "eye":"forward.end") {skip()}.accessibilityIdentifier("reveal-skip")
                    Spacer();Button("Guess the player",systemImage:"magnifyingglass") {choosing=true}.font(.headline).accessibilityIdentifier("reveal-guess")
                }.padding(16).background(.regularMaterial)
            }
        }
        .sheet(isPresented:$choosing) {NavigationStack {PlayerAnswerSheet(players:round.players,title:"Guess the player",rejectionMessage:"You already tried that player. Choose someone else.") {player in guess(player)}}.presentationDetents([.large])}
        .onAppear {restore()}.onDisappear {persist()}.onChange(of:phase) {if phase != .active {persist()}}
    }
    private func clueCell(_ clue: DailyClue) -> some View {
        let visible=revealed.contains(clue.id) || outcome != .playing
        return VStack(spacing:6) {
            if visible {
                if clue.kind != .text {
                    EntityArtwork(asset:nil,url:clue.imageURL,initials:clue.value.split(separator:" ").compactMap(\.first).map(String.init).prefix(2).joined(),size:round.mode == .statdle ? 58:94,isPlayer:clue.kind == .player,portraitFocus:clue.kind == .player)
                        .transition(.scale(scale:0.8).combined(with:.opacity))
                }
                Text(clue.value).font(clue.kind == .text && Int(clue.value) != nil ? .system(size:32,weight:.bold,design:.rounded):.headline).multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.8)
                Text(clue.title).font(.caption).foregroundStyle(Palette.muted)
            } else {
                Image(systemName:"questionmark").font(.system(size:32,weight:.bold,design:.rounded)).foregroundStyle(Palette.brand.opacity(0.4))
                Text(round.mode == .statdle ? clue.title:"Clue \((round.clues.firstIndex(where:{$0.id == clue.id}) ?? 0)+1)").font(.caption).foregroundStyle(Palette.muted)
            }
        }.frame(maxWidth:.infinity).frame(height:round.mode == .statdle ? 108:158).padding(.horizontal,8)
            .background(visible ? .white:Palette.brand.opacity(0.045),in:RoundedRectangle(cornerRadius:16))
            .accessibilityElement(children:.ignore).accessibilityLabel(visible ? clue.title+": "+clue.value:round.mode == .statdle ? clue.title+": hidden":"Hidden clue")
            .accessibilityIdentifier("reveal-clue-"+clue.id)
    }
    private func restore() {
        guard progress == nil else {return}
        progress=model.dailyCache?.progress(for:round) ?? DailyRevealProgress(round:round)
        difficulty=progress!.difficulty;handleResult();persist()
    }
    private func changeDifficulty() {
        guard progress?.attempts.isEmpty == true else {return}
        progress=DailyRevealProgress(round:round,difficulty:difficulty);persist()
    }
    private func persist() {
        guard let progress else {return}
        do {try model.dailyCache?.save(progress,for:round)} catch {feedback="Couldn’t save this round: "+error.localizedDescription}
    }
    private func guess(_ player: GamePlayer) -> Bool {
        guard var next=progress,next.submit(player.id,in:round) else {return false}
        progress=next;choosing=false
        feedback=player.id == round.answer.id ? "You found the connection.":"It isn’t \(player.name). More clues are now revealed."
        model.respond(player.id == round.answer.id,event:player.id == round.answer.id ? .completion:.mismatch)
        handleResult();persist();return true
    }
    private func skip() {
        guard var next=progress,next.submit(nil,in:round) else {return}
        progress=next;feedback=outcome == .lost ? "Keep this connection for your next practice.":"Another clue to help you connect the story."
        model.playSound(outcome == .lost ? .mismatch:.reveal);handleResult();persist()
    }
    private func handleResult() {
        guard var progress,outcome != .playing else {return}
        if outcome == .won,model.state.completeGame(id:progress.sessionID,kind:round.mode.rawValue,count:progress.attempts.count,now:model.now) {model.save()}
        // Wait until identification: recommendations and lesson names must not spoil a mystery.
        if !progress.reviewRecorded {
            if progress.attempts.contains(where:{$0.playerID != round.answer.id}) {
                let wrong=progress.attempts.compactMap(\.playerID).filter {$0 != round.answer.id}
                let names=wrong.compactMap {id in round.players.first {$0.id == id}?.name}
                model.recordGameGap(game:round.mode.rawValue,context:round.mode.title+" · "+round.scope,names:[round.answer.name]+names,playerIDs:[round.answer.id]+wrong)
            }
            progress.reviewRecorded=true;self.progress=progress
        }
    }
}
