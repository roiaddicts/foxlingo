import SwiftUI
import UniformTypeIdentifiers

// A ranked list is the workspace: large flags turn into portraits as answers arrive.
// Navy anchors the heading; quick portrait reveals and numeric progress mark each win.
struct DailyTop10View: View {
    let pack: DailyChallengePack
    @EnvironmentObject private var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduced
    @Environment(\.scenePhase) private var phase
    @State private var progress: Top10Progress?
    @State private var choosing=false
    @State private var feedback=""
    @State private var failed=false
    private var round: DailyTop10 {pack.top10}
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:14) {
                HStack {Text(pack.isToday(model.now) ? "TODAY’S LIST" : "SAVED CHALLENGE · "+pack.gameDate).font(.caption.bold()).tracking(1);Spacer();Text("\(progress?.found.count ?? 0) / 10").font(.title3.bold()).contentTransition(.numericText())}
                Text(round.title).font(.title2.bold()).accessibilityIdentifier("top10-title")
                Text("Find the ten players. Their flags are your clues.").font(.subheadline).foregroundStyle(Palette.muted)
                ProgressView(value:Double(progress?.found.count ?? 0),total:10)
                VStack(spacing:0) {
                    ForEach(Array(round.rankedPlayers.enumerated()),id:\.element.id) {index,player in
                        let found=progress?.found.contains(player.id) == true
                        HStack(spacing:14) {
                            Text("\(index+1)").font(.title3.bold().monospacedDigit()).frame(width:28).foregroundStyle(Palette.muted)
                            EntityArtwork(asset:found ? player.imageAsset:nil,url:found ? player.imageURL:round.flags[index],initials:found ? String(player.name.prefix(2)):"⚽",size:64,isPlayer:found,portraitFocus:found)
                                .id(found).transition(.scale(scale:0.85).combined(with:.opacity))
                            VStack(alignment:.leading,spacing:3) {
                                Text(found ? player.name:"Who belongs here?").font(.headline).foregroundStyle(found ? Palette.brand:Palette.muted)
                                if progress?.assisted.contains(player.id) == true {Text("Revealed with help").font(.caption).foregroundStyle(Palette.muted)}
                            }
                            Spacer()
                        }.frame(minHeight:80).accessibilityIdentifier("top10-rank-\(index)")
                        if index < 9 {Divider()}
                    }
                }
                if let progress,progress.finished {
                    HStack {Leopard(pose:"celebrate").frame(width:64,height:70);VStack(alignment:.leading,spacing:4) {Text("Ten out of ten!").font(.title2.bold()).accessibilityIdentifier("top10-complete");Text("Come back for the next list.").foregroundStyle(Palette.muted)}}
                }
                if !feedback.isEmpty {Text(feedback).font(.subheadline).foregroundStyle(failed ? Palette.red:Palette.brand).accessibilityIdentifier("top10-feedback")}
                Text("Challenge: \(pack.gameDate) · \(pack.timeZone). Rankings refer to the season or award named above.").font(.caption).foregroundStyle(Palette.muted)
            }.padding(20)
        }.journal().navigationTitle("Football Top 10").navigationBarTitleDisplayMode(.inline).toolbar(.hidden,for:.tabBar)
        .animation(reduced ? nil:.snappy(duration:0.25),value:progress?.found.count)
        .safeAreaInset(edge:.bottom) {
            if progress?.finished == false {
                HStack {Button("Reveal one",systemImage:"lightbulb") {hint()}.font(.subheadline).accessibilityIdentifier("top10-hint");Spacer();Button("Name a player",systemImage:"magnifyingglass") {choosing=true}.font(.headline).accessibilityIdentifier("top10-choose")}.padding(16).background(.regularMaterial)
            }
        }
        .sheet(isPresented:$choosing) {NavigationStack {PlayerAnswerSheet(players:round.players,title:"Name a Top 10 player",rejectionMessage:"That player isn’t in this Top 10, or is already found.") {player in guess(player)}}.presentationDetents([.large])}
        .onAppear {restore()}.onDisappear {persist()}.onChange(of:phase) {if phase != .active {persist()}}
    }
    private func restore() {
        guard progress == nil else {return}
        progress=model.dailyCache?.progress(for:round) ?? Top10Progress(signature:round.signature)
        creditIfFinished();persist()
    }
    private func persist() {
        guard let progress else {return}
        do {try model.dailyCache?.save(progress,for:round)} catch {failed=true;feedback="This list couldn’t be saved. "+error.localizedDescription}
    }
    private func creditIfFinished() {
        guard let progress,progress.finished else {return}
        if model.state.completeGame(id:progress.sessionID,kind:"top10",count:10,now:model.now) {model.save()}
    }
    private func guess(_ player: GamePlayer) -> Bool {
        guard var next=progress,!next.finished else {return false}
        if next.found.contains(player.id) {failed=true;feedback="You already found "+player.name+".";return false}
        guard next.guess(player.id,in:round) else {
            failed=true;feedback="\(player.name) isn’t in this list. Try another."
            model.recordGameGap(game:"top10",context:round.title,names:[player.name],playerIDs:[player.id]);model.respond(false,event:.mismatch);return false
        }
        progress=next;choosing=false;failed=false;feedback="\(player.name) · number \(round.rank(of:player.id)!+1)."
        finishStep();return true
    }
    private func hint() {
        guard var next=progress,!next.finished,let player=round.rankedPlayers.first(where:{!next.found.contains($0.id)}) else {return}
        _ = next.guess(player.id,in:round,helped:true);progress=next;failed=false;feedback="\(player.name). Try to recall this one next time."
        model.recordGameGap(game:"top10",context:round.title,names:[player.name],playerIDs:[player.id]);finishStep()
    }
    private func finishStep() {persist();creditIfFinished();model.respond(true,event:progress?.finished == true ? .completion:.connection)}
}
struct DailyUpdatesView: View {
    @EnvironmentObject private var model: AppModel
    @State private var address=""
    @State private var importing=false
    @State private var busy=false
    @State private var error: String?
    @State private var operation: Task<Void,Never>?
    var body: some View {
        Form {
            Section("Saved challenges") {
                if let pack=model.daily {LabeledContent("Date",value:pack.gameDate);LabeledContent("Day resets in",value:pack.timeZone)}
                Text("Challenges stay available offline. A saved date is shown until a newer set arrives.")
                if let message=model.dailyMessage {Text(message).font(.subheadline)}
                if let error {Text(error).foregroundStyle(Palette.red)}
            }
            Section("From a file") {Button("Import challenge JSON") {importing=true}.disabled(busy).accessibilityIdentifier("daily-import")}
            Section("Daily update feed") {
                TextField("HTTPS daily feed address",text:$address).textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL)
                Text("Once connected, Foxlingo checks for a new set when it opens.").font(.caption)
                if busy {HStack {ProgressView();Text("Checking challenges…");Spacer();Button("Cancel") {operation?.cancel()}}}
                else {Button("Check for challenges") {run {try await model.checkForDaily(address)}}.disabled(address.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty)}
            }
        }.navigationTitle("Daily challenges").onAppear {address=model.dailyAddress}.onDisappear {operation?.cancel()}
        .fileImporter(isPresented:$importing,allowedContentTypes:[.json]) {result in
            run {
                let file=try result.get()
                let work=Task.detached {try ContentImport.read(file)}
                let data=try await withTaskCancellationHandler(operation:{try await work.value},onCancel:{work.cancel()})
                try await model.importDaily(data)
            }
        }
    }
    private func run(_ action: @escaping @MainActor () async throws -> Void) {
        error=nil;busy=true
        operation=Task {@MainActor in defer {busy=false;operation=nil};do {try await action()} catch is CancellationError {error="Check cancelled. Saved challenges are available."} catch {self.error=error.localizedDescription}}
    }
}
