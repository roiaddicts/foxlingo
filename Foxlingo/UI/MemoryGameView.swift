import SwiftUI

struct MemoryGameView: View {
    let pairs: [MemoryGamePair]
    @EnvironmentObject private var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduced
    @Environment(\.scenePhase) private var scenePhase
    @ScaledMetric(relativeTo:.body) private var cardHeight: CGFloat=112
    @State private var order: [String]=[]
    @State private var board=MemoryMatch(pairs:[])
    @State private var moves=0
    @State private var sessionID=UUID()
    @State private var loaded=false
    @State private var finished=false
    @State private var restart=false
    @State private var voiceOver=UIAccessibility.isVoiceOverRunning
    @State private var notice: String?
    @State private var scope: String?
    @State private var sources=false
    private var found: Int {board.matched.count/2}
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:18) {
                HStack {Text("\(found) / 8 pairs").font(.title2.bold()).contentTransition(.numericText());Spacer();Text("\(moves) turns").font(.subheadline).foregroundStyle(Palette.muted)}
                if let notice {Text(notice).font(.subheadline).foregroundStyle(Palette.muted)}
                Text("Match each face or badge with its name or historical stat.").foregroundStyle(Palette.muted)
                LazyVGrid(columns:Array(repeating:GridItem(.flexible(),spacing:8),count:4),spacing:8) {
                    ForEach(Array(order.enumerated()),id:\.element) {index,id in
                        if let pair=pairs.first(where:{$0.relationship.left == id || $0.relationship.right == id}) {
                            let image=id == pair.relationship.left,visible=board.isVisible(id),matched=board.matched.contains(id)
                            let spoken=visible ? (image ? pair.subject.name+" image" : pair.answer.replacingOccurrences(of:"\n",with:" ")+(pair.fact.map {". "+$0.scope} ?? "")) : "Hidden card \(index+1)"
                            Button {flip(id,pair:pair)} label: {
                                MemoryCardFace(pair:pair,image:image,angle:visible ? 180 : 0,matched:matched)
                                    .frame(height:min(cardHeight,200)).animation(reduced ? nil : .easeInOut(duration:0.38),value:visible)
                            } .buttonStyle(MemoryLiftStyle())
                                .accessibilityRepresentation {
                                    Button {flip(id,pair:pair)} label:{Text(spoken)}
                                        .accessibilityValue(matched ? "Matched" : visible ? "Revealed" : "Face down")
                                        .accessibilityIdentifier("memory-\(id)")
                                }
                        }
                    }
                }.accessibilityIdentifier("memory-board")
                if let scope {Text(scope).font(.caption).foregroundStyle(Palette.muted)}
                if board.waitingToClose && voiceOver {Button("Turn cards back over") {closeMismatch()}.accessibilityIdentifier("memory-close")}
                if finished {
                    HStack {Leopard(pose:"celebrate").frame(width:60,height:68);Text("All eight pairs found!").font(.title2.bold()).accessibilityIdentifier("memory-complete")}
                    PrimaryButton(title:"Play again",symbol:"arrow.clockwise") {newBoard()}.accessibilityIdentifier("memory-replay")
                    Button("Sources & stat context",systemImage:"text.book.closed") {sources=true}
                }
                Text("Untimed practice. Finished boards count toward your streak; card upgrades come from scheduled recall.").font(.caption).foregroundStyle(Palette.muted)
            }.padding(20)
        }.journal().navigationTitle("Memory match").navigationBarTitleDisplayMode(.inline)
        .toolbar {if !finished {Button("Start again",systemImage:"arrow.counterclockwise") {if moves > 0 || !board.faceUp.isEmpty {restart=true} else {newBoard()}}.accessibilityIdentifier("memory-restart")}}
        .alert("Start a new memory board?",isPresented:$restart) {Button("Start a new board",role:.destructive) {newBoard()};Button("Keep playing",role:.cancel) {}} message:{Text("This clears this board. Your other games and learning progress stay saved.")}
        .onAppear {restore()}.onDisappear {persist()}.onChange(of:scenePhase) {if scenePhase != .active {persist()}}
        .onReceive(NotificationCenter.default.publisher(for:UIAccessibility.voiceOverStatusDidChangeNotification)) {_ in voiceOver=UIAccessibility.isVoiceOverRunning}
        .task(id:"\(board.faceUp)-\(voiceOver)") {
            guard !voiceOver,board.waitingToClose else {return}
            do {try await Task.sleep(for:.seconds(1.8))} catch {return}
            guard !Task.isCancelled else {return};closeMismatch()
        }
        .sheet(isPresented:$sources) {
            NavigationStack {List {ForEach(pairs) {pair in
                Section(pair.subject.name) {if let fact=pair.fact {Text(pair.answer);Text(fact.scope);Text(fact.evidence);if let pack=model.pack {ForEach(pack.sources.filter {fact.sourceKeys.contains($0.key)}) {source in if let url=URL(string:source.url) {Link(source.title,destination:url)}}}} else {Text("Portrait or badge matched to its canonical name.")}}
            }}.navigationTitle("Sources & context").toolbar {Button("Done") {sources=false}}}
        }
    }
    private func flip(_ id: String,pair: MemoryGamePair) {
        let outcome=board.flip(id)
        switch outcome {
        case .ignored:return
        case .revealed:scope=pair.fact?.scope;model.playSound(.reveal)
        case .mismatch:moves += 1;scope=pair.fact?.scope;model.respond(false,event:.mismatch)
        case .matched:moves += 1;scope=pair.fact?.scope;if found < 8 {model.respond(true,event:.connection)}
        }
        if found == 8 {
            finished=true;notice=nil;model.state.removeSavedGame("memory")
            _ = model.state.completeGame(id:sessionID,kind:"memory",count:8,now:model.now);model.save();model.respond(true,event:.completion)
        } else {persist()}
    }
    private func closeMismatch() {board.closeMismatch();scope=nil}
    private func newBoard() {
        let ids=pairs.flatMap {[$0.relationship.left,$0.relationship.right]}
        #if DEBUG
        order=ProcessInfo.processInfo.arguments.contains("-ui-testing") ? ids : ids.shuffled()
        #else
        order=ids.shuffled()
        #endif
        board=MemoryMatch(pairs:pairs.map(\.relationship));moves=0;sessionID=UUID();finished=false;scope=nil;notice=nil;persist()
    }
    private func persist() {
        guard loaded,!finished else {return}
        let progress=MemoryProgress(order:order,matched:pairs.map(\.relationship.left).filter {board.matched.contains($0)},moves:moves)
        model.state.storeGame(GameResume(signature:MemoryGameDeck.signature(pairs),sessionID:sessionID,memory:progress),kind:"memory");model.save()
    }
    private func restore() {
        guard !loaded else {return};loaded=true
        if let saved=model.state.savedGame("memory"),let progress=MemoryGameDeck.restore(saved,pairs:pairs,completedSessions:Set(model.state.sessions.map(\.id))) {
            order=progress.order;board=MemoryMatch(pairs:pairs.map(\.relationship),completed:progress.matched);moves=progress.moves;sessionID=saved.sessionID;notice="Your matched pairs are right where you left them.";return
        }
        let hadSave=model.state.savedGame("memory") != nil;newBoard()
        if hadSave {notice="The saved board changed. A fresh one is ready; your learning progress is preserved."}
    }
}

private struct MemoryCardFace: View, Animatable {
    let pair: MemoryGamePair
    let image: Bool
    var angle: Double
    let matched: Bool
    @ScaledMetric(relativeTo:.caption) private var textSize: CGFloat=13
    var animatableData: Double {get {angle} set {angle=newValue}}
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius:14).fill(Palette.brand)
                .overlay {Image(systemName:"pawprint.fill").font(.title2).foregroundStyle(.white.opacity(0.9))}
                .opacity(angle < 90 ? 1 : 0)
            RoundedRectangle(cornerRadius:14).fill(matched ? Palette.brand.opacity(0.12) : .white)
                .overlay {
                    VStack(spacing:6) {
                        if image {EntityArtwork(asset:pair.subject.imageAsset,url:pair.subject.imageURL,initials:pair.subject.visual,size:52,isPlayer:pair.subject.type == "player")}
                        else if let fact=pair.fact {
                            Text(fact.value.display).font(.system(size:min(textSize*1.6,30),weight:.bold,design:.rounded)).lineLimit(1).minimumScaleFactor(0.65)
                            Text(pair.definition.label ?? "").font(.system(size:min(textSize*0.85,16),weight:.semibold)).multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.65)
                        } else {Text(pair.subject.name).font(.system(size:min(textSize,22),weight:.semibold,design:.rounded)).multilineTextAlignment(.center).lineLimit(4).minimumScaleFactor(0.65).padding(.horizontal,5)}
                        if matched {Image(systemName:"checkmark.circle.fill").font(.caption).foregroundStyle(Palette.brand)}
                    }
                }.rotation3DEffect(.degrees(180),axis:(x:0,y:1,z:0)).opacity(angle >= 90 ? 1 : 0)
        }.overlay {RoundedRectangle(cornerRadius:14).stroke(Palette.brand.opacity(0.18),lineWidth:1)}
            .rotation3DEffect(.degrees(angle),axis:(x:0,y:1,z:0),perspective:0.45).accessibilityHidden(true)
    }
}
private struct MemoryLiftStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduced
    @State private var hovering=false
    func makeBody(configuration: Configuration) -> some View {
        let lifted=configuration.isPressed || hovering
        configuration.label.scaleEffect(lifted && !reduced ? 1.035 : 1)
            .offset(y:lifted && !reduced ? -3 : 0)
            .shadow(color:Palette.ink.opacity(lifted ? 0.18 : 0.04),radius:lifted ? 8 : 2,y:lifted ? 5 : 1)
            .animation(reduced ? nil : .spring(response:0.23,dampingFraction:0.75),value:lifted)
            .onHover {hovering=$0}
    }
}
