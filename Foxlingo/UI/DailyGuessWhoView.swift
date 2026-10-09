import SwiftUI

// Questions are the primary action; a compact mystery heading leaves room for
// visual question options, the yes/no history, and keyboard-safe player search.
struct DailyGuessWhoView: View {
    let pack: DailyChallengePack
    let round: DailyGuessWho
    @EnvironmentObject private var model: AppModel
    @Environment(\.scenePhase) private var phase
    @Environment(\.accessibilityReduceMotion) private var reduced
    @State private var progress: GuessWhoProgress?
    @State private var topic: GuessWhoTopic = .club
    @State private var option: Int?
    @State private var number=28
    @State private var comparison: GuessWhoComparison = .equal
    @State private var choosingOption=false
    @State private var choosingPlayer=false
    @State private var revealing=false
    @State private var feedback=""
    private var finished: Bool {progress?.finished(round) == true}
    private var question: GuessWhoQuestion? {
        if topic == .age || topic == .height {return GuessWhoQuestion(topic,value:number,comparison:comparison)}
        return option.map {GuessWhoQuestion(topic,value:$0)}
    }
    var body: some View {
        ScrollViewReader {proxy in
        ScrollView {
            VStack(alignment:.leading,spacing:14) {
                HStack {Text(pack.isToday(model.now) ? "DAILY MYSTERY":"SAVED · "+pack.gameDate).font(.caption.bold()).tracking(1);Spacer();Text("\(progress?.guesses.count ?? 0) / 3 guesses").font(.subheadline.monospacedDigit()).accessibilityIdentifier("guesswho-guesses")}.id("guesswho-top")
                if finished {answer} else {
                    Text("Ask. Eliminate. Identify.").font(.title2.bold())
                    Text("\(10-(progress?.questions.count ?? 0)) questions left").font(.headline).accessibilityIdentifier("guesswho-questions")
                    if (progress?.questions.count ?? 0) < 10 {composer}
                    else {Text("All ten questions used. Make your remaining guesses.").font(.subheadline).foregroundStyle(Palette.muted)}
                }
                if !feedback.isEmpty {Text(feedback).font(.subheadline).foregroundStyle(Palette.muted).accessibilityIdentifier("guesswho-feedback")}
                if let p=progress,!p.questions.isEmpty {
                    Text("Your clues").font(.headline)
                    ForEach(Array(p.questions.enumerated().reversed()),id:\.offset) {index,q in
                        HStack(spacing:10) {
                            questionArtwork(q,size:40)
                            Text(round.text(q)).font(.subheadline).frame(maxWidth:.infinity,alignment:.leading)
                            let yes=round.response(q)
                            Text(yes == true ? "Yes":yes == false ? "No":"Not listed").font(.subheadline.bold()).foregroundStyle(yes == true ? Palette.brand:Palette.muted)
                        }.padding(12).background(.white,in:RoundedRectangle(cornerRadius:14)).accessibilityElement(children:.combine).accessibilityIdentifier("guesswho-clue-\(index)")
                    }
                }
                if let p=progress,!p.guesses.isEmpty {
                    Text("Your guesses").font(.headline)
                    ForEach(p.guesses,id:\.self) {id in if let player=round.players.first(where:{$0.id == id}) {
                        HStack {EntityArtwork(asset:player.imageAsset,url:player.imageURL,initials:String(player.name.prefix(2)),size:48,isPlayer:true,portraitFocus:true);Text(player.name).font(.subheadline);Spacer();Image(systemName:id == round.answer.id ? "checkmark":"xmark").font(.caption)}
                    }}
                }
                Text("\(pack.gameDate) · Club, league and career answers describe the supplied snapshot. No means not listed, not a complete career claim. Age is calculated for this game date.").font(.caption).foregroundStyle(Palette.muted)
            }.padding(20)
        }.onChange(of:finished) {if finished {withAnimation(reduced ? nil:.snappy(duration:0.3)) {proxy.scrollTo("guesswho-top",anchor:.top)}}}
        }.journal().navigationTitle("Guess the Footballer").navigationBarTitleDisplayMode(.inline).toolbar(.hidden,for:.tabBar)
        .safeAreaInset(edge:.bottom) {if !finished {HStack {Button("Reveal",systemImage:"eye") {revealing=true}.accessibilityIdentifier("guesswho-reveal");Spacer();Button("Guess the player",systemImage:"magnifyingglass") {choosingPlayer=true}.font(.headline).accessibilityIdentifier("guesswho-guess")}.padding(16).background(.regularMaterial)}}
        .sheet(isPresented:$choosingOption) {NavigationStack {GuessWhoOptionSheet(options:round.options(topic),title:topic.title) {picked in option=picked.id;choosingOption=false}}.presentationDetents([.large])}
        .sheet(isPresented:$choosingPlayer) {NavigationStack {PlayerAnswerSheet(players:round.players,title:"Guess the player",rejectionMessage:"You already guessed that player.") {player in guess(player)}}.presentationDetents([.large])}
        .confirmationDialog("Reveal the player and finish this round?",isPresented:$revealing,titleVisibility:.visible) {Button("Reveal player",role:.destructive) {giveUp()}}
        .onAppear {restore()}.onDisappear {persist()}.onChange(of:phase) {if phase != .active {persist()}}
    }
    private var composer: some View {
        VStack(alignment:.leading,spacing:12) {
            LazyVGrid(columns:[GridItem(.flexible()),GridItem(.flexible())],spacing:8) {
                ForEach(GuessWhoTopic.allCases,id:\.self) {value in
                    Button {topic=value;option=nil;number=value == .height ? 180:28;comparison = .equal} label: {
                        HStack {Image(systemName:value.icon).frame(width:24);Text(value.title).font(.subheadline.bold());Spacer()}.padding(12).background(topic == value ? Palette.brand: .white,in:RoundedRectangle(cornerRadius:12)).foregroundStyle(topic == value ? .white:Palette.brand)
                    }.accessibilityIdentifier("guesswho-topic-"+value.rawValue)
                }
            }
            if topic == .age || topic == .height {
                Picker("Comparison",selection:$comparison) {Text("Exactly").tag(GuessWhoComparison.equal);Text("Over").tag(GuessWhoComparison.greater);Text("Under").tag(GuessWhoComparison.less)}.pickerStyle(.segmented).accessibilityIdentifier("guesswho-comparison")
                Picker(topic.title,selection:$number) {ForEach(topic == .age ? Array(15...60):Array(140...220),id:\.self) {Text("\($0)\(topic == .height ? " cm":" years")").tag($0)}}.pickerStyle(.wheel).frame(height:100).clipped().accessibilityIdentifier("guesswho-number")
            } else if topic == .position {
                LazyVGrid(columns:[GridItem(.flexible()),GridItem(.flexible())]) {ForEach(Array(DailyGuessWho.positions.enumerated()),id:\.offset) {index,name in
                    Button {option=index} label:{Label(name,systemImage:["hand.raised.fill","shield.fill","arrow.left.arrow.right","soccerball"][index]).font(.subheadline).padding(12).frame(maxWidth:.infinity).background(option == index ? Palette.brand.opacity(0.12):.white,in:RoundedRectangle(cornerRadius:12))}.accessibilityIdentifier("guesswho-position-\(index)")
                }}
            } else {
                Button {choosingOption=true} label:{HStack {if let value=round.options(topic).first(where:{$0.id == option}) {EntityArtwork(asset:value.imageAsset,url:value.imageURL,initials:String(value.name.prefix(2)),size:50);Text(value.name).font(.headline)} else {Image(systemName:"magnifyingglass");Text("Choose "+topic.title.lowercased()).font(.headline)};Spacer();Image(systemName:"chevron.right")}.padding(12).background(.white,in:RoundedRectangle(cornerRadius:14))}.accessibilityIdentifier("guesswho-choose-option")
            }
            if let question {Text(round.text(question)).font(.subheadline).accessibilityIdentifier("guesswho-prompt")}
            PrimaryButton(title:"Ask question",symbol:"questionmark.bubble.fill",action:ask).opacity(question == nil ? 0.45:1).disabled(question == nil).accessibilityIdentifier("guesswho-ask")
        }
    }
    private var answer: some View {
        VStack(alignment:.leading,spacing:12) {
            HStack(spacing:14) {EntityArtwork(asset:round.answer.imageAsset,url:round.answer.imageURL,initials:String(round.answer.name.prefix(2)),size:88,isPlayer:true,portraitFocus:true);VStack(alignment:.leading,spacing:5) {Text(round.answer.name).font(.title2.bold()).accessibilityIdentifier("guesswho-answer");Text(progress?.won(round) == true ? "Mystery solved!":"A new player to remember.").font(.subheadline)}}
            HStack {if let country=round.countries.first(where:{$0.id == round.country}) {EntityArtwork(asset:nil,url:country.imageURL,initials:"",size:36)};Text(DailyGuessWho.positions[round.position]);Spacer();Text("\(round.age) years · \(round.height) cm").font(.subheadline)}
            if let club=round.clubs.first(where:{$0.id == round.currentClub}) {HStack {EntityArtwork(asset:club.imageAsset,url:club.imageURL,initials:String(club.name.prefix(2)),size:48);Text("Snapshot club: "+club.name).font(.subheadline)}}
        }
    }
    @ViewBuilder private func questionArtwork(_ q:GuessWhoQuestion,size:CGFloat) -> some View {
        if let value=round.options(q.topic).first(where:{$0.id == q.value}) {EntityArtwork(asset:value.imageAsset,url:value.imageURL,initials:String(value.name.prefix(2)),size:size)}
        else {Image(systemName:q.topic.icon).font(.title3).frame(width:size,height:size).background(Palette.brand.opacity(0.08),in:RoundedRectangle(cornerRadius:10))}
    }
    private func ask() {guard var p=progress,let question,p.ask(question,in:round) else {feedback="Choose a new question; repeated questions do not use another turn.";return};progress=p;feedback="";option=nil;model.playSound(.reveal);persist()}
    private func guess(_ player:GamePlayer) -> Bool {guard var p=progress,p.guess(player.id,in:round) else {return false};progress=p;choosingPlayer=false;feedback=p.won(round) ? "":p.finished(round) ? "":"That player doesn’t fit. \(3-p.guesses.count) guesses left.";model.respond(p.won(round),event:p.won(round) ? .completion:.mismatch);handleResult();persist();return true}
    private func giveUp() {guard var p=progress,p.reveal(in:round) else {return};progress=p;feedback="";handleResult();persist();model.playSound(.reveal)}
    private func restore() {guard progress == nil else {return};progress=model.dailyCache?.progress(for:round) ?? GuessWhoProgress(round:round);handleResult();persist()}
    private func persist() {guard let progress else {return};do {try model.dailyCache?.save(progress,for:round)} catch {feedback="Couldn’t save this round: "+error.localizedDescription}}
    private func handleResult() {
        guard var p=progress,p.finished(round) else {return}
        if p.won(round),model.state.completeGame(id:p.sessionID,kind:"guesswho",count:p.questions.count+p.guesses.count,now:model.now) {model.save()}
        if !p.reviewRecorded {if p.gaveUp || p.guesses.contains(where:{$0 != round.answer.id}) {model.recordGameGap(game:"guesswho",context:"Daily question mystery",names:[round.answer.name],playerIDs:[round.answer.id])};p.reviewRecorded=true;progress=p}
    }
}
private struct GuessWhoOptionSheet: View {
    let options:[GuessWhoOption]
    let title:String
    let select:(GuessWhoOption)->Void
    @Environment(\.dismiss) private var dismiss
    @State private var query=""
    @FocusState private var focused:Bool
    private var filtered:[GuessWhoOption] {options.filter {query.isEmpty || Recall.normalize($0.name).contains(Recall.normalize(query))}}
    var body: some View {
        ScrollView {LazyVStack(spacing:10) {ForEach(filtered) {option in
            Button {select(option)} label:{HStack(spacing:14) {EntityArtwork(asset:option.imageAsset,url:option.imageURL,initials:String(option.name.prefix(2)),size:58);Text(option.name).font(.headline);Spacer()}.padding(10).background(.white,in:RoundedRectangle(cornerRadius:14))}.accessibilityIdentifier("guesswho-option-\(option.id)")
        }}.padding(20)}.journal().navigationTitle(title).navigationBarTitleDisplayMode(.inline)
            .toolbar {ToolbarItem(placement:.cancellationAction) {Button("Cancel") {dismiss()}}}
            .safeAreaInset(edge:.bottom) {TextField("Search "+title.lowercased(),text:$query).textFieldStyle(.roundedBorder).focused($focused).autocorrectionDisabled().padding(16).background(.regularMaterial).accessibilityIdentifier("guesswho-option-search")}
            .onAppear {focused=true}
    }
}
