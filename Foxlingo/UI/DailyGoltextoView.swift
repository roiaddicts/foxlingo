import SwiftUI

// Portraits, flags and shirts anchor the guesses; a signed score and expandable
// breakdown explain closeness without a large mystery card hiding the search.
struct DailyGoltextoView: View {
    let pack:DailyChallengePack
    let round:DailyGoltexto
    @EnvironmentObject private var model:AppModel
    @Environment(\.scenePhase) private var phase
    @Environment(\.accessibilityReduceMotion) private var reduced
    @State private var progress:GoltextoProgress?
    @State private var limit=20
    @State private var choosing=false
    @State private var revealing=false
    @State private var rules=false
    @State private var expanded:String?
    @State private var feedback=""
    private var finished:Bool {progress?.finished(round) == true}
    private var best:Int? {progress?.guesses.compactMap {round.profile($0)}.map {round.score($0).value}.max()}
    var body:some View {
        ScrollViewReader {proxy in
            ScrollView {
                VStack(alignment:.leading,spacing:16) {
                    HStack {Text(pack.isToday(model.now) ? "DAILY SIMILARITY":"SAVED · "+pack.gameDate).font(.caption.bold()).tracking(1);Spacer();Text("\(progress?.guesses.count ?? 0) / \(progress?.limit ?? limit)").font(.headline.monospacedDigit()).accessibilityIdentifier("goltexto-count")}.id("goltexto-top")
                    if finished {result} else {
                        Text("Find the player. Follow the clues.").font(.title2.bold())
                        Text("Closer profiles score higher. Only the exact player reaches 100.").font(.subheadline).foregroundStyle(Palette.muted)
                        if progress?.guesses.isEmpty == true {
                            Text("Guess budget").font(.caption.bold())
                            Picker("Guess budget",selection:$limit) {Text("10").tag(10);Text("20").tag(20);Text("100").tag(100)}.pickerStyle(.segmented).onChange(of:limit) {progress=GoltextoProgress(round:round,limit:limit);persist()}.accessibilityIdentifier("goltexto-limit")
                            HStack(spacing:14) {Image(systemName:"scope").font(.system(size:36)).foregroundStyle(Palette.brand);Text("Start with a player you know. Then follow the strongest similarities.").font(.subheadline)}.padding(18).background(.white,in:RoundedRectangle(cornerRadius:16))
                        }
                    }
                    HStack {if let best {Text("Closest so far: \(best)").font(.headline).accessibilityIdentifier("goltexto-best")};Spacer();Button("How scores work",systemImage:"info.circle") {rules=true}.font(.caption.bold()).accessibilityIdentifier("goltexto-rules")}
                    if !feedback.isEmpty {Text(feedback).font(.subheadline).foregroundStyle(Palette.muted).accessibilityIdentifier("goltexto-feedback")}
                    if let progress {ForEach(progress.guesses.reversed(),id:\.self) {id in if let player=round.profile(id) {guessCard(player)}}}
                    Text("\(pack.gameDate) · Traits come from the source game catalog. They are not live ratings or verified current club affiliations. League and regional groups follow the source, including shared unclassified groups.").font(.caption).foregroundStyle(Palette.muted)
                }.padding(20)
            }.onChange(of:finished) {if finished {withAnimation(reduced ? nil:.snappy(duration:0.3)) {proxy.scrollTo("goltexto-top",anchor:.top)}}}
        }.journal().navigationTitle("Goltexto").navigationBarTitleDisplayMode(.inline).toolbar(.hidden,for:.tabBar)
        .animation(reduced ? nil:.snappy(duration:0.25),value:progress?.guesses.count)
        .safeAreaInset(edge:.bottom) {if !finished {HStack {Button("Reveal",systemImage:"eye") {revealing=true}.accessibilityIdentifier("goltexto-reveal");Spacer();Button("Guess the player",systemImage:"magnifyingglass") {choosing=true}.font(.headline).accessibilityIdentifier("goltexto-guess")}.padding(16).background(.regularMaterial)}}
        .sheet(isPresented:$choosing) {NavigationStack {GoltextoPlayerSearch(round:round) {player in guess(player)}}.presentationDetents([.large])}
        .sheet(isPresented:$rules) {NavigationStack {GoltextoRulesView()}.presentationDetents([.large])}
        .confirmationDialog("Reveal the player and finish this round?",isPresented:$revealing,titleVisibility:.visible) {Button("Reveal player",role:.destructive) {giveUp()}}
        .onAppear {restore()}.onDisappear {persist()}.onChange(of:phase) {if phase != .active {persist()}}
    }
    private var result:some View {
        VStack(alignment:.leading,spacing:12) {
            HStack(spacing:16) {EntityArtwork(asset:round.answer.player.imageAsset,url:round.answer.player.imageURL,initials:String(round.answer.player.name.prefix(2)),size:88,isPlayer:true,portraitFocus:true);VStack(alignment:.leading,spacing:5) {Text(round.answer.player.name).font(.title2.bold()).accessibilityIdentifier("goltexto-answer");Text(progress?.won(round) == true ? "Exact match!":"A new profile to remember.").font(.subheadline)}}
            traits(round.answer)
        }
    }
    private func traits(_ player:GoltextoPlayer) -> some View {
        HStack(spacing:12) {
            if let country=round.countries.first(where:{$0.id == player.countryID}) {EntityArtwork(asset:nil,url:country.imageURL,initials:"",size:30).accessibilityLabel(country.name)}
            if let club=round.clubs.first(where:{$0.id == player.clubID}) {EntityArtwork(asset:nil,url:club.imageURL,initials:String(club.name.prefix(2)),size:38).accessibilityLabel("Catalog club: "+club.name)}
            Text(player.positions.joined(separator:" / ")).font(.caption.bold());Spacer()
            Text("\(player.age.map {String($0)+"y"} ?? "Age —") · OVR \(player.rating)").font(.caption.monospacedDigit())
        }
    }
    private func guessCard(_ profile:GoltextoPlayer) -> some View {
        let score=round.score(profile),id=profile.player.id
        return VStack(alignment:.leading,spacing:12) {
            HStack(spacing:12) {EntityArtwork(asset:profile.player.imageAsset,url:profile.player.imageURL,initials:String(profile.player.name.prefix(2)),size:64,isPlayer:true,portraitFocus:true);Text(profile.player.name).font(.headline).frame(maxWidth:.infinity,alignment:.leading);Text(String(score.value)).font(.system(size:32,weight:.bold,design:.rounded)).monospacedDigit().foregroundStyle(score.value < 0 ? Palette.red:Palette.brand).accessibilityIdentifier("goltexto-score-"+id)}
            GeometryReader {geo in
                ZStack(alignment:.leading) {Capsule().fill(Palette.brand.opacity(0.08));Capsule().fill(score.value < 0 ? Palette.red:Palette.brand).frame(width:geo.size.width*score.fraction);Rectangle().fill(.white.opacity(0.75)).frame(width:2).offset(x:geo.size.width*0.375)}
            }.frame(height:10)
            traits(profile)
            Button {expanded=expanded == id ? nil:id} label:{HStack {Text(expanded == id ? "Hide breakdown":"Why this score?").font(.caption.bold());Spacer();Image(systemName:expanded == id ? "chevron.up":"chevron.down").font(.caption)}}.accessibilityIdentifier("goltexto-breakdown-"+id)
            if expanded == id {ForEach(score.parts) {part in HStack {Text(part.title).font(.caption);Spacer();Text(part.points > 0 ? "+\(part.points)":String(part.points)).font(.caption.bold().monospacedDigit())}.accessibilityElement(children:.combine).accessibilityIdentifier("goltexto-part-"+part.id)}}
        }.padding(16).background(.white,in:RoundedRectangle(cornerRadius:18))
    }
    private func restore() {guard progress == nil else {return};progress=model.dailyCache?.progress(for:round) ?? GoltextoProgress(round:round);limit=progress!.limit;handleResult();persist()}
    private func persist() {guard let progress else {return};do {try model.dailyCache?.save(progress,for:round)} catch {feedback="Couldn’t save this round: "+error.localizedDescription}}
    private func guess(_ player:GamePlayer) -> Bool {
        guard var p=progress,let profile=round.profile(player.id),p.guess(player.id,in:round) else {return false}
        let oldBest=best;progress=p;choosing=false;expanded=nil
        let value=round.score(profile).value
        feedback=p.won(round) || p.finished(round) ? "":oldBest.map {value > $0 ? "A closer profile. Keep following those similarities.":"A useful clue. Compare this profile with your closest guess."} ?? "Your first clue. Tap the breakdown to see what matches."
        if p.won(round) {model.respond(true,event:.completion)} else if p.finished(round) {model.respond(false,event:.mismatch)} else if oldBest.map({value > $0}) == true {model.respond(true,event:.correct)} else {model.playSound(.reveal)}
        handleResult();persist();return true
    }
    private func giveUp() {guard var p=progress,p.reveal(in:round) else {return};progress=p;feedback="";handleResult();persist();model.playSound(.reveal)}
    private func handleResult() {
        guard var p=progress,p.finished(round) else {return}
        if p.won(round),model.state.completeGame(id:p.sessionID,kind:"goltexto",count:p.guesses.count,now:model.now) {model.save()}
        if !p.reviewRecorded {if p.gaveUp || p.guesses.contains(where:{$0 != round.answer.player.id}) {model.recordGameGap(game:"goltexto",context:"Source catalog similarity",names:[round.answer.player.name],playerIDs:[round.answer.player.id])};p.reviewRecorded=true;progress=p}
    }
}
private struct GoltextoRulesView:View {
    @Environment(\.dismiss) private var dismiss
    private let rules=[("Catalog club","+40 for matching"),("Rating","+5 down to +1 when within four points"),("Age","+7 down to +4 when within three years; a penalty when ten or more years apart"),("Positions","+10 for overlap, +5 more for the same primary position; otherwise −5"),("Broad role","+10 for the same role"),("Wide roles","+10 if both are wingers or both are fullbacks"),("Role mismatch","−5 if neither broad nor wide roles match"),("League group","+20 for matching; otherwise −5"),("Regional group","+6 for matching; otherwise −2"),("Nationality","+20 for matching; otherwise −5"),("Combined differences","Extra penalties for several key mismatches")]
    var body:some View {
        ScrollView {VStack(alignment:.leading,spacing:18) {Text("A similarity score, not a probability.").font(.title2.bold());Text("Scores combine the traits below. A shared club or nationality carries more weight than a small age difference.").font(.subheadline);ForEach(rules,id:\.0) {name,detail in VStack(alignment:.leading,spacing:4) {Text(name).font(.headline);Text(detail).font(.subheadline).foregroundStyle(Palette.muted)}};Text("Unclassified clubs share a league group and unclassified countries share a regional group. A wrong player is capped at 99; only the exact identity can win. Missing ages add no age points.").font(.subheadline);Text("Ratings, clubs and positions describe the game catalog, not verified current football data.").font(.caption).foregroundStyle(Palette.muted)}.padding(20)}.journal().navigationTitle("How scores work").navigationBarTitleDisplayMode(.inline).toolbar {ToolbarItem(placement:.confirmationAction) {Button("Done") {dismiss()}}}
    }
}

// Source IDs stay distinct even when names repeat. Visible catalog traits make
// those choices distinguishable without importing facts from another namespace.
private struct GoltextoPlayerSearch:View {
    let round:DailyGoltexto
    let onChoose:(GamePlayer)->Bool
    @Environment(\.dismiss) private var dismiss
    @State private var query=""
    @State private var message=""
    @FocusState private var focused:Bool
    private var results:[GoltextoPlayer] {
        let q=Recall.normalize(query)
        guard q.count >= 2 else {return []}
        return Array(round.profiles.filter {$0.player.aliases.contains {Recall.normalize($0).contains(q)}}.prefix(30))
    }
    var body:some View {
        ScrollView {
            LazyVStack(alignment:.leading,spacing:10) {
                if !message.isEmpty {Text(message).foregroundStyle(Palette.red).accessibilityIdentifier("game-answer-error")}
                ForEach(results,id:\.player.id) {profile in
                    let country=round.countries.first {$0.id == profile.countryID}
                    let club=round.clubs.first {$0.id == profile.clubID}
                    Button {if !onChoose(profile.player) {message="You already tried that player."}} label: {
                        HStack(spacing:12) {
                            EntityArtwork(asset:profile.player.imageAsset,url:profile.player.imageURL,initials:String(profile.player.name.prefix(2)),size:64,isPlayer:true,portraitFocus:true)
                            VStack(alignment:.leading,spacing:7) {
                                Text(profile.player.name).font(.headline)
                                HStack(spacing:8) {
                                    EntityArtwork(asset:nil,url:country?.imageURL,initials:"",size:24)
                                    EntityArtwork(asset:nil,url:club?.imageURL,initials:String((club?.name ?? "").prefix(2)),size:30)
                                    Text(profile.positions.joined(separator:" / ")).font(.caption.bold())
                                }
                                Text("\(profile.age.map {String($0)+"y"} ?? "Age —") · OVR \(profile.rating)").font(.caption).foregroundStyle(Palette.muted)
                            }
                            Spacer(minLength:0)
                        }.frame(maxWidth:.infinity,alignment:.leading).padding(10).background(.white,in:RoundedRectangle(cornerRadius:14))
                    }.accessibilityLabel("\(profile.player.name), \(country?.name ?? ""), catalog club \(club?.name ?? ""), \(profile.positions.joined(separator:", ")), \(profile.age.map {String($0)+" years"} ?? "age unavailable"), rating \(profile.rating)")
                    .accessibilityIdentifier("game-player-"+profile.player.id)
                }
                if results.isEmpty {Text(query.count < 2 ? "Type at least two letters to find a player.":"No name found. Try a full name or known nickname.").font(.subheadline).foregroundStyle(Palette.muted)}
            }.padding(12)
        }.scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge:.bottom,spacing:0) {
            HStack {Image(systemName:"magnifyingglass");TextField("Type a player’s name",text:$query).focused($focused).autocorrectionDisabled().accessibilityIdentifier("game-player-search")}
                .padding(14).background(.white,in:RoundedRectangle(cornerRadius:14)).padding(12).background(.regularMaterial)
        }.journal().navigationTitle("Find a similar player").navigationBarTitleDisplayMode(.inline).toolbar {Button("Cancel") {dismiss()}}
        .task {focused=true}.onChange(of:query) {message=""}
    }
}
