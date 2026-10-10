import SwiftUI

struct DailyBingoRetroView:View {
    let pack:DailyChallengePack
    let round:any DailyBingoRound
    @EnvironmentObject private var model:AppModel
    @Environment(\.scenePhase) private var phase
    @State private var progress:BingoRetroProgress?
    @State private var timer=0
    @State private var feedback=""
    @State private var failed=false
    @State private var inspected:GameCategory?
    @State private var clock=Date()
    private let ticker=Timer.publish(every:0.25,on:.main,in:.common).autoconnect()
    private var now:Date {ProcessInfo.processInfo.arguments.contains("-ui-testing") ? model.now:clock}
    private var retro:Bool {round.kind == "bingo-retro"}
    private var prefix:String {retro ? "bingo-retro":"daily-bingo"}
    var body:some View {
        ScrollView {
            VStack(alignment:.leading,spacing:16) {
                HStack {Text(pack.isToday(model.now) ? (retro ? "DAILY LEGENDS":"DAILY FOOTBALL BINGO"): "SAVED · "+pack.gameDate).font(.caption.bold()).tracking(1);Spacer();Text("\(progress?.placements.count ?? 0) / 12").font(.headline.monospacedDigit()).accessibilityIdentifier(prefix+"-count")}
                if progress?.status == .ready {
                    Text((retro ? "Twelve categories. Football legends.":"Twelve categories. Football careers.")).font(.title2.bold())
                    Text("Place each offered player where they fit, or skip. A player may appear again for another category.").font(.subheadline).foregroundStyle(Palette.muted)
                    Picker("Timer",selection:$timer) {Text("No timer").tag(0);Text("60s").tag(60);Text("90s").tag(90)}.pickerStyle(.segmented).accessibilityIdentifier(prefix+"-timer")
                    if timer != 0 {Text("The clock keeps running if you leave this round.").font(.caption).foregroundStyle(Palette.muted)}
                    PrimaryButton(title:"Start game",symbol:"play.fill",action:start).accessibilityIdentifier(prefix+"-start")
                } else if progress?.finished == true {
                    HStack(spacing:12) {Image(systemName:progress?.status == .won ? "checkmark.seal.fill":"clock.badge.exclamationmark").font(.system(size:38)).foregroundStyle(Palette.brand);VStack(alignment:.leading,spacing:4) {Text(progress?.status == .won ? "Full house!":"Time’s up.").font(.title2.bold()).accessibilityIdentifier(prefix+"-result");Text(progress?.status == .won ? "Twelve connections to remember.":"\(progress?.placements.count ?? 0) connections made. Explore the remaining categories below.").font(.subheadline).foregroundStyle(Palette.muted)}}
                } else if let id=progress?.currentPlayerID,let player=round.player(id) {
                    HStack(spacing:14) {
                        EntityArtwork(asset:player.imageAsset,url:player.imageURL,initials:String(player.name.prefix(2)),size:86,isPlayer:true,portraitFocus:true)
                        VStack(alignment:.leading,spacing:5) {Text(player.name).font(.title3.bold()).accessibilityIdentifier(prefix+"-offer").accessibilityValue(id);Text("Find a matching category").font(.caption).foregroundStyle(Palette.muted)}
                        Spacer(minLength:0)
                    }.padding(14).background(.white,in:RoundedRectangle(cornerRadius:18)).accessibilityValue(id)
                }
                if !feedback.isEmpty {Text(feedback).font(.subheadline).foregroundStyle(failed ? Palette.red:Palette.brand).accessibilityIdentifier(prefix+"-feedback")}
                LazyVGrid(columns:Array(repeating:GridItem(.flexible(),spacing:8),count:3),spacing:8) {
                    ForEach(round.categories) {category in categoryCell(category)}
                }
                Text("\(pack.gameDate) · Source-listed historical memberships. Country categories follow the catalog’s represented country. Hold a category to inspect its name.").font(.caption).foregroundStyle(Palette.muted)
            }.padding(16)
        }.journal().navigationTitle((retro ? "Bingo Retro":"Daily Bingo")).navigationBarTitleDisplayMode(.inline).toolbar(.hidden,for:.tabBar)
        .safeAreaInset(edge:.bottom) {
            if progress?.status == .playing {
                HStack {if let remaining=progress?.remaining(at:now) {Label("\(remaining)s",systemImage:"timer").font(.title3.bold().monospacedDigit()).accessibilityIdentifier(prefix+"-clock")} else {Text("Take your time").font(.subheadline).foregroundStyle(Palette.muted)};Spacer();Button("Skip",systemImage:"arrow.right") {skip()}.font(.headline).accessibilityIdentifier(prefix+"-skip")}.padding(16).background(.regularMaterial)
            }
        }
        .sheet(item:$inspected) {category in NavigationStack {categoryDetails(category)}.presentationDetents([.medium,.large])}
        .onAppear {restore()}.onDisappear {tick();persist()}.onChange(of:phase) {clock=Date();tick();persist()}
        .onReceive(ticker) {date in guard phase == .active,progress?.status == .playing,progress?.timer != 0 else {return};if Int(date.timeIntervalSince1970) != Int(clock.timeIntervalSince1970) {clock=date;tick()}}
    }
    private func categoryCell(_ category:GameCategory)->some View {
        let player=progress?.placements[category.id].flatMap(round.player)
        return Button {
            if progress?.finished == true {inspected=category} else {place(category)}
        } label: {
            VStack(spacing:5) {
                ZStack(alignment:.bottomTrailing) {
                    if let player {EntityArtwork(asset:player.imageAsset,url:player.imageURL,initials:String(player.name.prefix(2)),size:76,isPlayer:true,portraitFocus:true);GameCategoryMark(category:category,size:24).padding(3).background(.white,in:Circle())}
                    else {GameCategoryMark(category:category,size:68).frame(width:76,height:76)}
                }
                Text(player?.name ?? category.title).font(.caption.bold()).lineLimit(2).minimumScaleFactor(0.8).frame(height:30)
            }.frame(maxWidth:.infinity).padding(.vertical,10).background(player == nil ? .white:Palette.brand.opacity(0.09),in:RoundedRectangle(cornerRadius:14)).animation(nil,value:player?.id)
        }.buttonStyle(PressFeedback()).accessibilityLabel(category.title+(player.map {", "+$0.name} ?? ", empty"))
        .accessibilityIdentifier(prefix+"-cell-"+category.id)
        .onLongPressGesture {inspected=category}
    }
    private func categoryDetails(_ category:GameCategory)->some View {
        ScrollView {VStack(alignment:.leading,spacing:16) {HStack {GameCategoryMark(category:category,size:68);Text(category.title).font(.title2.bold())};if progress?.finished == true {Text("Source-listed matches").font(.headline);ForEach(category.playerIDs.compactMap(round.player)) {player in HStack {EntityArtwork(asset:player.imageAsset,url:player.imageURL,initials:String(player.name.prefix(2)),size:54,isPlayer:true,portraitFocus:true);Text(player.name).font(.headline)}}} else {Text("Does the offered player fit this category?").foregroundStyle(Palette.muted)}}.padding(20)}.journal().navigationTitle("Category").navigationBarTitleDisplayMode(.inline).toolbar {Button("Done") {inspected=nil}}
    }
    private func restore() {guard progress == nil else {return};progress=model.dailyCache?.progress(for:round) ?? BingoRetroProgress(round:round);tick();handleResult();persist()}
    private func start() {guard var p=progress else {return};var rng=SystemRandomNumberGenerator();guard p.start(round:round,timer:timer,now:now,rng:&rng) else {return};progress=p;feedback="";model.playSound(.reveal);persist()}
    private func place(_ category:GameCategory) {
        guard var p=progress,p.status == .playing else {return}
        if p.placements[category.id] != nil {inspected=category;return}
        var rng=SystemRandomNumberGenerator();let accepted=p.place(category:category.id,in:round,now:now,rng:&rng);progress=p
        if accepted {failed=false;feedback="A connection made!";model.respond(true,event:p.status == .won ? .completion:.correct)} else if !p.finished {failed=true;feedback="That player isn’t listed for this category. Try another or skip.";model.respond(false,event:.mismatch)}
        handleResult();persist()
    }
    private func skip() {guard var p=progress else {return};var rng=SystemRandomNumberGenerator();guard p.skip(in:round,now:now,rng:&rng) else {progress=p;handleResult();persist();return};progress=p;failed=false;feedback="";model.playSound(.reveal);persist()}
    private func tick() {guard var p=progress else {return};if p.expire(at:now) {progress=p;feedback="";model.respond(false,event:.mismatch);handleResult();persist()}}
    private func handleResult() {
        guard var p=progress,p.finished else {return}
        if p.status == .won,model.state.completeGame(id:p.sessionID,kind:round.kind,count:12,now:model.now) {model.save()}
        if !p.reviewRecorded {
            // Short legend names cannot safely identify a canonical lesson subject.
            // Keep source references until a reviewed identity crosswalk exists.
            for mistake in p.mistakes {if let player=round.player(mistake.playerID),let category=round.categories.first(where:{$0.id == mistake.categoryID}) {model.state.recordPracticeGap(PracticeGap(game:round.kind,context:category.title,subjectIDs:[],timestamp:model.now,referenceNames:[player.name],referencePlayerIDs:[player.id]));model.save()}}
            if p.status == .lost {for c in round.categories where p.placements[c.id] == nil {model.recordGameGap(game:round.kind,context:c.title,names:[c.title])}}
            p.reviewRecorded=true;progress=p
        }
    }
    private func persist() {guard let progress else {return};do {try model.dailyCache?.save(progress,for:round)} catch {failed=true;feedback="Couldn’t save this round: "+error.localizedDescription}}
}
