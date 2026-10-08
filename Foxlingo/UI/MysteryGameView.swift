import SwiftUI

struct MysteryGameView: View {
    @State private var rounds: [MysteryRound]
    init(rounds: [MysteryRound]) {
        #if DEBUG
        _rounds=State(initialValue:ProcessInfo.processInfo.arguments.contains("-ui-testing") ? rounds : rounds.shuffled())
        #else
        _rounds=State(initialValue:rounds.shuffled())
        #endif
    }
    @EnvironmentObject private var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduced
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var index=0
    @State private var turn=MysteryTurn()
    @State private var choosing=false
    @State private var sources=false
    @State private var feedback=""
    @State private var contradicted=false
    @State private var sessionID=UUID()
    @State private var finished=false
    @State private var clueCounts: [Int]=[]
    @State private var loaded=false
    @State private var confirmRestart=false
    @State private var resumeNotice: String?
    @Environment(\.scenePhase) private var scenePhase
    var round: MysteryRound {rounds[index]}
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:22) {
                HStack {Eyebrow(text:"\(index+1) of \(rounds.count) players");Spacer();Text("UNTIMED").font(.caption.bold()).foregroundStyle(Palette.muted)}
                ProgressView(value:Double(finished ? rounds.count : index),total:Double(rounds.count)).animation(reduced ? nil : .snappy,value:index)
                if let resumeNotice {Text(resumeNotice).font(.subheadline).foregroundStyle(Palette.muted).accessibilityIdentifier("mystery-resume-notice")}
                if finished {
                    HStack(spacing:16) {Leopard(pose:"celebrate").frame(width:80,height:88);VStack(alignment:.leading,spacing:6) {Text("Faces found!").font(.title.bold()).accessibilityIdentifier("mystery-complete");Text("\(rounds.count) players connected to their stories.").foregroundStyle(Palette.muted)}}
                    Text("Clues used: \(clueCounts.map(String.init).joined(separator:" · ")). This is practice, not an independent recall score.").font(.subheadline)
                    PrimaryButton(title:"Play again",symbol:"arrow.clockwise") {replay()}.accessibilityIdentifier("mystery-replay")
                } else {
                    VStack(spacing:12) {
                        if turn.solved {
                            ClubMark(club:round.player,size:108).transition(.scale(scale:0.88).combined(with:.opacity))
                            Text(round.player.name).font(.title2.bold()).accessibilityIdentifier("mystery-identity")
                            Text("\(turn.revealed) of 3 clues used").font(.subheadline).foregroundStyle(Palette.muted)
                        } else {
                            Image(systemName:"person.crop.circle.badge.questionmark").font(.system(size:70)).foregroundStyle(Palette.green).accessibilityHidden(true)
                            Text("Which featured player?").font(.title2.bold())
                            Text("One of the \(rounds.count) players on this board. Use the clues to find the person.").font(.subheadline).foregroundStyle(Palette.muted).multilineTextAlignment(.center)
                        }
                    }.frame(maxWidth:.infinity).padding(.vertical,8).animation(reduced ? nil : .spring(response:0.4,dampingFraction:0.8),value:turn.solved)
                    ForEach(0..<turn.revealed,id:\.self) {i in clue(i).transition(.opacity.combined(with:.move(edge:.bottom)))}
                    if !feedback.isEmpty {Label(feedback,systemImage:contradicted ? "arrow.triangle.branch" : turn.solved ? "checkmark.circle.fill" : "lightbulb").font(.subheadline).foregroundStyle(contradicted ? Palette.ink : Palette.green).accessibilityIdentifier("mystery-feedback")}
                    if turn.solved {
                        PrimaryButton(title:index == rounds.count-1 ? "Finish board" : "Next player") {next()}.accessibilityIdentifier("mystery-next")
                        Button("Sources & context",systemImage:"text.book.closed") {sources=true}.accessibilityIdentifier("mystery-sources")
                    } else {
                        PrimaryButton(title:"Choose a player",symbol:"person.crop.circle") {choosing=true}.accessibilityIdentifier("mystery-choose")
                        if turn.revealed < 3 {Button("Reveal another clue",systemImage:"lightbulb") {withAnimation(reduced ? nil : .easeOut(duration:0.22)) {turn.reveal(in:round);feedback="";persist();model.playSound(.reveal)}}.frame(minHeight:44).accessibilityIdentifier("mystery-reveal")}
                    }
                }
                Text("Historical lesson facts. Clues count toward game practice; card upgrades still require scheduled recall.").font(.caption).foregroundStyle(Palette.muted)
            }.padding(24)
        }.journal().navigationTitle("Who am I?").navigationBarTitleDisplayMode(.inline)
        .onAppear {restore()}
        .onDisappear {persist()}
        .onChange(of:scenePhase) {if scenePhase != .active {persist()}}
        .toolbar {if !finished {Button("Start again",systemImage:"arrow.counterclockwise") {if index > 0 || turn.revealed > 1 || turn.guesses > 0 || turn.solved {confirmRestart=true} else {replay()}}.accessibilityIdentifier("mystery-restart")}}
        .alert("Start a new mystery board?",isPresented:$confirmRestart) {Button("Start a new board",role:.destructive) {replay()};Button("Keep playing",role:.cancel) {}} message:{Text("This clears the clues and players on this board. Your other games and learning progress stay saved.")}
        .sheet(isPresented:$choosing) {
            NavigationStack {
                ScrollView {
                    VStack(alignment:.leading,spacing:18) {
                        Text("The featured players").font(.title2.bold())
                        Text("A guess that still fits the clues reveals another clue. Missing evidence is never treated as a wrong fact.").font(.subheadline).foregroundStyle(Palette.muted)
                        LazyVGrid(columns:typeSize.isAccessibilitySize ? [GridItem(.flexible())] : [GridItem(.flexible()),GridItem(.flexible())],spacing:14) {
                            ForEach(rounds) {candidate in
                                Button {guess(candidate.player)} label: {VStack(spacing:10) {ClubMark(club:candidate.player,size:72);Text(candidate.player.name).font(.headline).multilineTextAlignment(.center)}.frame(maxWidth:.infinity,minHeight:130).padding(12).background(.white,in:RoundedRectangle(cornerRadius:18))}.buttonStyle(PressFeedback()).accessibilityLabel(candidate.player.name).accessibilityIdentifier("mystery-player-\(candidate.player.key)")
                            }
                        }
                    }.padding(24)
                }.journal().navigationTitle("Choose a player").navigationBarTitleDisplayMode(.inline).toolbar {Button("Cancel") {choosing=false}}
            }
        }
        .sheet(isPresented:$sources) {
            NavigationStack {List {
                Section(round.player.name) {
                    ForEach(round.definition.clues.compactMap(\.factID),id:\.self) {id in
                        if let fact=round.facts[id] {VStack(alignment:.leading,spacing:6) {Text(fact.evidence);Text(fact.scope).font(.caption).foregroundStyle(.secondary)}}
                    }
                }
                Section("Supporting sources") {ForEach(round.sources) {source in if let url=URL(string:source.url) {Link(source.title,destination:url)}}}
            }.navigationTitle("Sources & context").toolbar {Button("Done") {sources=false}}}
        }
    }
    private func clue(_ i: Int) -> some View {
        let clue=round.definition.clues[i]
        return VStack(alignment:.leading,spacing:10) {
            HStack(spacing:10) {
                Text("\(i+1)").font(.caption.bold()).frame(width:24,height:24).background(Palette.green.opacity(0.1),in:Circle())
                if let context=clue.contextEntityID,let pack=model.pack {EntityArtwork(asset:pack.entity(context).imageAsset,url:pack.entity(context).imageURL,initials:pack.entity(context).visual,size:28).accessibilityElement(children:.ignore).accessibilityLabel(pack.entity(context).name).accessibilityIdentifier("mystery-context-\(i)")}
                Text(clue.label).font(.subheadline.bold()).foregroundStyle(Palette.muted)
            }
            if let pack=model.pack {KnowledgeAnswer(text:round.value(at:i),expectedType:round.visualType(at:i,pack:pack)).font(.system(.title,design:.rounded,weight:.bold)).accessibilityIdentifier("mystery-clue-\(i)")}
            if let id=clue.factID,let fact=round.facts[id] {
                if let unit=fact.value.unit,unit != "year" {Text(unit).font(.subheadline).foregroundStyle(Palette.muted)}
                Text(fact.scope).font(.caption).foregroundStyle(Palette.muted)
            }
        }.frame(maxWidth:.infinity,alignment:.leading).padding(18).background(.white.opacity(0.8),in:RoundedRectangle(cornerRadius:18))
    }
    private func guess(_ player: Entity) {
        choosing=false
        withAnimation(reduced ? nil : .easeOut(duration:0.22)) {
            switch turn.guess(player,in:round) {
            case .identified:contradicted=false;feedback="Found the connection.";model.respond(true,event:.connection)
            case .moreClues:contradicted=false;feedback="We cannot rule that player out from these clues. Let’s reveal another."
            case .contradicted:model.respond(false,event:.mismatch);contradicted=true;feedback="That player differs from a clue already shown. Try another connection."
            case .ignored:break
            }
        }
        persist()
    }
    private func next() {
        guard turn.solved,!finished else {return}
        clueCounts.append(turn.revealed)
        if index == rounds.count-1 {
            finished=true
            _ = model.state.completeGame(id:sessionID,kind:"mystery",count:rounds.count,now:model.now);model.state.removeSavedGame("mystery");model.save();model.respond(true,event:.completion)
        } else {index += 1;turn=MysteryTurn();feedback="";contradicted=false}
        persist()
    }
    private func replay() {
        #if DEBUG
        if !ProcessInfo.processInfo.arguments.contains("-ui-testing") {rounds.shuffle()}
        #else
        rounds.shuffle()
        #endif
        model.state.removeSavedGame("mystery");resumeNotice=nil
        index=0;turn=MysteryTurn();clueCounts=[];feedback="";contradicted=false;finished=false;sessionID=UUID();persist()}
    private func persist() {
        guard loaded,!finished else {return}
        let progress=MysteryProgress(roundIDs:rounds.map(\.id),index:index,revealed:turn.revealed,solved:turn.solved,guesses:turn.guesses,clueCounts:clueCounts)
        model.state.storeGame(GameResume(signature:GameResumeRules.mysterySignature(rounds),sessionID:sessionID,mystery:progress),kind:"mystery");model.save()
    }
    private func restore() {
        guard !loaded else {return};loaded=true
        if let resume=model.state.savedGame("mystery") {
            if let progress=GameResumeRules.restoreMystery(resume,rounds:rounds,completedSessions:Set(model.state.sessions.map(\.id))) {
                let byID=Dictionary(uniqueKeysWithValues:rounds.map {($0.id,$0)})
                rounds=progress.roundIDs.map {byID[$0]!};index=progress.index;turn=MysteryTurn(restoring:progress);clueCounts=progress.clueCounts;sessionID=resume.sessionID
                resumeNotice="Your players and clues are right where you left them.";return
            }
            model.state.removeSavedGame("mystery");resumeNotice="That saved game could not be used with this content. A fresh board is ready; your completed activity is preserved."
        }
        persist()
    }
}
