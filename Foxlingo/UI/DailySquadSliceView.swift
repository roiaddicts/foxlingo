import SwiftUI
import Charts

// The nationality ring is the visual anchor. Flags identify whole revealed slices;
// quick sector fades and a fixed bottom search keep the three chances easy to follow.
struct DailySquadSliceView: View {
    let pack: DailyChallengePack
    let round: DailySquadSlice
    @EnvironmentObject private var model: AppModel
    @Environment(\.scenePhase) private var phase
    @Environment(\.accessibilityReduceMotion) private var reduced
    @State private var progress: SquadSliceProgress?
    @State private var choosing=false
    @State private var clockwise=false
    @State private var selectedAngle: Double?
    @State private var selectedCountry: Int?
    @State private var feedback=""
    private var finished: Bool {progress?.finished(round) == true}
    private var visible: Set<Int> {round.visibleCountries(at:progress?.guesses.count ?? 0,clockwise:progress?.clockwise ?? clockwise,finished:finished)}
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:16) {
                HStack {Text(pack.isToday(model.now) ? "DAILY SQUAD":"SAVED · "+pack.gameDate).font(.caption.bold()).tracking(1);Spacer();Text("\(progress?.guesses.count ?? 0) / 3 chances").font(.subheadline.monospacedDigit()).accessibilityIdentifier("squad-chances")}
                Text("Which club is this squad?").font(.title3.bold())
                if progress?.guesses.isEmpty == true {
                    Picker("Reveal order",selection:$clockwise) {Text("Random").tag(false);Text("Clockwise").tag(true)}.pickerStyle(.segmented).onChange(of:clockwise) {progress=SquadSliceProgress(round:round,clockwise:clockwise);selectedCountry=nil;persist()}.accessibilityIdentifier("squad-reveal-order")
                }
                ZStack {
                    Chart(round.countries) {country in
                        let shown=visible.contains(country.id)
                        SectorMark(angle:.value("Players",Double(country.count)),innerRadius:.ratio(0.62),angularInset:shown ? 1.5:0)
                            .foregroundStyle(shown ? color(country.color):Palette.brand.opacity(0.08))
                            .annotation(position:.overlay) {if shown {EntityArtwork(asset:nil,url:country.flagURL,initials:"",size:country.count > 2 ? 30:22)}}
                            .accessibilityLabel(shown ? country.name:"Hidden nationality").accessibilityValue(shown ? "\(country.count) players":"Not revealed")
                    }.chartLegend(.hidden).accessibilityIdentifier("squad-chart").chartAngleSelection(value:$selectedAngle).chartGesture {proxy in SpatialTapGesture().onEnded {event in proxy.selectAngleValue(at:proxy.angle(at:event.location))}}.onChange(of:selectedAngle) {selectSlice()}
                    VStack(spacing:5) {
                        if finished {
                            EntityArtwork(asset:nil,url:round.answer.imageURL,initials:String(round.answer.name.prefix(2)),size:54)
                            Text(round.answer.name).font(.headline).accessibilityIdentifier("squad-answer")
                        } else {Text("Guess the club").font(.subheadline.bold())}
                        Text(round.season).font(.headline).accessibilityIdentifier("squad-season")
                        Text("\(round.total) players").font(.caption).foregroundStyle(Palette.muted)
                    }.allowsHitTesting(false)
                }.frame(height:320)
                if let country=round.countries.first(where:{$0.id == selectedCountry}),visible.contains(country.id) {
                    HStack {EntityArtwork(asset:nil,url:country.flagURL,initials:"",size:32);Text(country.name).font(.headline);Spacer();Text("\(country.count) / \(round.total)").font(.subheadline.monospacedDigit())}.accessibilityElement(children:.combine).accessibilityIdentifier("squad-selected-country")
                    if finished {
                        ScrollView(.horizontal) {HStack(alignment:.top,spacing:12) {ForEach(country.players) {player in
                            VStack(spacing:5) {EntityArtwork(asset:player.imageAsset,url:player.imageURL,initials:String(player.name.prefix(2)),size:64,isPlayer:true,portraitFocus:true);Text(player.name).font(.caption).lineLimit(2).frame(width:85)}
                        }}}.accessibilityIdentifier("squad-country-players")
                    }
                }
                LazyVGrid(columns:[GridItem(.flexible()),GridItem(.flexible())],spacing:10) {
                    ForEach(round.countries.filter {visible.contains($0.id)}) {country in
                        Button {selectedCountry=country.id} label: {
                            HStack(spacing:10) {EntityArtwork(asset:nil,url:country.flagURL,initials:"",size:34);Text("\(country.count)").font(.title3.bold());Text(country.count == 1 ? "player":"players").font(.caption).foregroundStyle(Palette.muted);Spacer()}.padding(10).background(selectedCountry == country.id ? Palette.brand.opacity(0.10):.white,in:RoundedRectangle(cornerRadius:12))
                        }.accessibilityLabel(country.name+": \(country.count) players").accessibilityIdentifier("squad-country-\(country.id)")
                    }
                }
                if finished {Text(progress?.won(round) == true ? "Squad identified!":"A new squad to remember. Tap a flag to meet its players.").font(.headline).accessibilityIdentifier("squad-result")}
                else {Text("Tap a slice or flag to see its size. A wrong guess or skip reveals more of the squad.").font(.subheadline).foregroundStyle(Palette.muted)}
                if !feedback.isEmpty {Text(feedback).font(.subheadline).foregroundStyle(Palette.muted).accessibilityIdentifier("squad-feedback")}
                if let progress,!progress.guesses.isEmpty {
                    HStack(spacing:8) {ForEach(Array(progress.guesses.enumerated()),id:\.offset) {_,id in
                        if let club=round.clubs.first(where:{$0.id == id}) {EntityArtwork(asset:nil,url:club.imageURL,initials:String(club.name.prefix(2)),size:40).accessibilityLabel(club.name)}
                        else {Image(systemName:"forward.end").frame(width:40,height:40).accessibilityLabel("Skipped chance")}
                    };Spacer()}
                }
                Text("\(pack.gameDate) · Source squad snapshot for \(round.season), not a current roster.").font(.caption).foregroundStyle(Palette.muted)
            }.padding(20)
        }.journal().navigationTitle("SquadSlice").navigationBarTitleDisplayMode(.inline).toolbar(.hidden,for:.tabBar)
        .animation(reduced ? nil:.easeOut(duration:0.3),value:progress?.guesses.count)
        .safeAreaInset(edge:.bottom) {if !finished {HStack {Button(progress?.guesses.count == 2 ? "Reveal club":"Skip",systemImage:"forward.end") {submit(nil)}.accessibilityIdentifier("squad-skip");Spacer();Button("Guess the club",systemImage:"magnifyingglass") {choosing=true}.font(.headline).accessibilityIdentifier("squad-guess")}.padding(16).background(.regularMaterial)}}
        .sheet(isPresented:$choosing) {NavigationStack {DailyClubAnswerSheet(clubs:round.clubs) {club in submit(club.id)}}.presentationDetents([.large])}
        .onAppear {restore()}.onDisappear {persist()}.onChange(of:phase) {if phase != .active {persist()}}
    }
    private func color(_ hex: String) -> Color {
        let cleaned=hex.trimmingCharacters(in:CharacterSet(charactersIn:"#"))
        guard cleaned.count == 6,let value=UInt(cleaned,radix:16) else {return Palette.brand}
        return Color(red:Double(value>>16)/255,green:Double((value>>8)&255)/255,blue:Double(value&255)/255)
    }
    private func selectSlice() {
        guard let angle=selectedAngle else {selectedCountry=nil;return}
        var total=0.0
        for country in round.countries {total += Double(country.count);if angle < total {selectedCountry=visible.contains(country.id) ? country.id:nil;return}}
    }
    @discardableResult private func submit(_ id: Int?) -> Bool {
        guard var next=progress,next.submit(id,in:round) else {return false}
        progress=next;choosing=false;selectedCountry=nil;selectedAngle=nil
        feedback=id == nil ? "More of the squad is revealed.":next.won(round) ? "You identified the club.":"That club doesn’t fit this squad. More flags are revealed."
        if next.won(round) {model.respond(true,event:.completion)} else if id != nil || next.finished(round) {model.respond(false,event:.mismatch)} else {model.playSound(.reveal)}
        handleResult();persist();return true
    }
    private func restore() {guard progress == nil else {return};progress=model.dailyCache?.progress(for:round) ?? SquadSliceProgress(round:round);clockwise=progress!.clockwise;handleResult();persist()}
    private func persist() {guard let progress else {return};do {try model.dailyCache?.save(progress,for:round)} catch {feedback="Couldn’t save this squad: "+error.localizedDescription}}
    private func handleResult() {
        guard var value=progress,value.finished(round) else {return}
        if value.won(round),model.state.completeGame(id:value.sessionID,kind:"squadslice",count:value.guesses.count,now:model.now) {model.save()}
        if !value.reviewRecorded {
            if value.guesses.contains(where:{$0 != round.answer.id}) {
                let names=value.guesses.compactMap {id in round.clubs.first {$0.id == id}?.name}
                model.recordGameGap(game:"squadslice",context:"Squad nationality mix · "+round.season,names:[round.answer.name]+names)
            }
            value.reviewRecorded=true;progress=value
        }
    }
}
struct DailyClubAnswerSheet: View {
    let clubs: [DailyClub]
    let onChoose: (DailyClub) -> Bool
    @Environment(\.dismiss) private var dismiss
    @State private var query=""
    @State private var error=""
    @FocusState private var focused: Bool
    private var results: [DailyClub] {let q=Recall.normalize(query);return q.count < 2 ? []:Array(clubs.filter {Recall.normalize($0.name).contains(q)}.prefix(20))}
    var body: some View {
        ScrollView {
            LazyVStack(alignment:.leading,spacing:8) {
                if !error.isEmpty {Text(error).foregroundStyle(Palette.red)}
                ForEach(results) {club in Button {if !onChoose(club) {error="You already tried this club."}} label: {HStack(spacing:14) {EntityArtwork(asset:nil,url:club.imageURL,initials:String(club.name.prefix(2)),size:58);Text(club.name).font(.headline);Spacer()}.padding(10).background(.white,in:RoundedRectangle(cornerRadius:14))}.accessibilityIdentifier("squad-club-\(club.id)")}
                if results.isEmpty {Text(query.count < 2 ? "Type at least two letters to find a club.":"No club found. Try a shorter name.").foregroundStyle(Palette.muted)}
            }.padding(16)
        }.scrollDismissesKeyboard(.interactively).safeAreaInset(edge:.bottom) {HStack {Image(systemName:"magnifyingglass");TextField("Search clubs",text:$query).focused($focused).autocorrectionDisabled().accessibilityIdentifier("squad-club-search")}.padding(14).background(.white,in:RoundedRectangle(cornerRadius:14)).padding(12).background(.regularMaterial)}
        .journal().navigationTitle("Guess the club").navigationBarTitleDisplayMode(.inline).toolbar {Button("Cancel") {dismiss()}}.task {focused=true}.onChange(of:query) {error=""}
    }
}
