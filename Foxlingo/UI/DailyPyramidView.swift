import SwiftUI

// A single ranking pyramid is the workspace, with a large offered portrait above it.
// Consistent slot sizes, quick swaps and subtle grade borders keep faces dominant.
struct DailyPyramidView: View {
    let pack: DailyChallengePack
    @EnvironmentObject private var model: AppModel
    @Environment(\.scenePhase) private var phase
    @Environment(\.accessibilityReduceMotion) private var reduced
    @State private var progress: PyramidProgress?
    @State private var selected: Int?
    @State private var target: Int?
    @State private var easy=false
    @State private var feedback=""
    private var round: DailyPyramid {pack.pyramid}
    private var finished: Bool {progress?.finished == true}
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:12) {
                HStack {Text(pack.isToday(model.now) ? "DAILY RANKING":"SAVED · "+pack.gameDate).font(.caption.bold()).tracking(1);Spacer();Text("\(progress?.count ?? 0) / 10").font(.headline.monospacedDigit()).contentTransition(.numericText()).accessibilityIdentifier("pyramid-count")}
                Text(round.title).font(.title3.bold()).accessibilityIdentifier("pyramid-title")
                Text("Highest at 1. Lowest at 10.").font(.subheadline).foregroundStyle(Palette.muted)
                if progress?.count == 0 {
                    Picker("Difficulty",selection:$easy) {Text("Normal").tag(false);Text("Easy").tag(true)}.pickerStyle(.segmented).onChange(of:easy) {progress=PyramidProgress(round:round,easy:easy);persist()}.accessibilityIdentifier("pyramid-difficulty")
                }
                if let offered=progress?.offered(round),!finished {
                    HStack(spacing:14) {
                        portrait(offered.player,size:66)
                        VStack(alignment:.leading,spacing:4) {Text(offered.player.name).font(.headline).accessibilityIdentifier("pyramid-offered");Text(easy ? bandText(offered.player.id):"Tap an empty rank to place this player.").font(.caption).foregroundStyle(Palette.muted)}
                        Spacer()
                    }
                } else {
                    Text(finished ? "\(progress?.correctSlots(round).count ?? 0) of 10 ranked correctly" : "Drag players to swap ranks, or tap two slots.").font(.headline).accessibilityIdentifier("pyramid-result")
                }
                GeometryReader {geo in
                    let width=(geo.size.width-24)/4
                    VStack(spacing:8) {
                        ForEach([[0],[1,2],[3,4,5],[6,7,8,9]],id:\.self) {row in
                            HStack(spacing:8) {ForEach(row,id:\.self) {slot in interactiveCell(slot,width:width)}}.frame(maxWidth:.infinity)
                        }
                    }
                }.frame(height:464)
                if finished {
                    Text(progress?.won(round) == true ? "Perfect pyramid!":"Compare the revealed totals and take these names into your next practice.").font(.headline).accessibilityIdentifier("pyramid-complete")
                }
                if !feedback.isEmpty {Text(feedback).font(.subheadline).foregroundStyle(Palette.muted).accessibilityIdentifier("pyramid-feedback")}
                Text("\(pack.gameDate) · Ranking values come from the source snapshot, rather than live totals.").font(.caption).foregroundStyle(Palette.muted)
            }.padding(20)
        }.journal().navigationTitle("Football Pyramid").navigationBarTitleDisplayMode(.inline).toolbar(.hidden,for:.tabBar)
        .animation(reduced ? nil:.snappy(duration:0.28),value:progress?.slots)
        .safeAreaInset(edge:.bottom) {
            if !finished,progress?.count == 10 {
                HStack {Button("Check once",systemImage:"lightbulb") {help()}.disabled(progress?.helpUsed == true).accessibilityIdentifier("pyramid-help");Spacer();Button("Submit ranking",systemImage:"checkmark") {submit()}.font(.headline).accessibilityIdentifier("pyramid-submit")}.padding(16).background(.regularMaterial)
            }
        }
        .onAppear {restore()}.onDisappear {persist()}.onChange(of:phase) {if phase != .active {persist()}}
    }
    private func portrait(_ player: GamePlayer,size: CGFloat) -> some View {EntityArtwork(asset:player.imageAsset,url:player.imageURL,initials:String(player.name.prefix(2)),size:size,isPlayer:true,portraitFocus:true)}
    private func bandText(_ id: String) -> String {switch round.hintBand(for:id)?.lowerBound {case 0:"One of the top three";case 3:"One of the middle three";default:"One of the bottom four"}}
    @ViewBuilder private func interactiveCell(_ slot: Int,width: CGFloat) -> some View {
        let cell=Button {tap(slot)} label: {rankCard(slot,width:width)}.buttonStyle(PressFeedback()).accessibilityIdentifier("pyramid-slot-\(slot)").accessibilityLabel(accessible(slot))
        if progress?.slots[slot] != nil,!finished,progress?.locked.contains(slot) != true {
            cell.draggable(String(slot)).dropDestination(for:String.self) {items,_ in drop(items,to:slot)} isTargeted:{active in if active {target=slot} else if target == slot {target=nil}}
        } else {cell.dropDestination(for:String.self) {items,_ in drop(items,to:slot)}}
    }
    private func rankCard(_ slot: Int,width: CGFloat) -> some View {
        let id=progress?.slots[slot],player=id.flatMap {round.player($0)}
        let correct=progress?.correctSlots(round).contains(slot) == true
        let locked=progress?.locked.contains(slot) == true
        let band=progress?.offered(round).flatMap {round.hintBand(for:$0.player.id)}
        let highlighted=target == slot || selected == slot || (!finished && easy && band?.contains(slot) == true)
        return VStack(spacing:3) {
            if let player {
                portrait(player.player,size:min(66,width-8))
                Text(player.player.name).font(.system(size:10,weight:.semibold)).lineLimit(2).multilineTextAlignment(.center).frame(width:width-8,height:25)
                if finished {Text(String(player.value)).font(.caption2.bold())}
            } else {Image(systemName:"plus").font(.title3).foregroundStyle(Palette.brand.opacity(0.45));Text("\(slot+1)").font(.caption.bold())}
        }.frame(width:width,height:110).background(highlighted ? Palette.brand.opacity(0.12):.white,in:RoundedRectangle(cornerRadius:12))
            .overlay {RoundedRectangle(cornerRadius:12).stroke(finished && !correct ? Palette.red:locked || highlighted ? Palette.brand:Palette.brand.opacity(0.15),lineWidth:locked || highlighted ? 2:1)}
            .overlay(alignment:.topLeading) {if player != nil {Text("\(slot+1)").font(.system(size:9,weight:.bold)).padding(3).background(.white.opacity(0.85),in:RoundedRectangle(cornerRadius:4)).padding(3)}}
    }
    private func accessible(_ slot: Int) -> String {
        let name=progress?.slots[slot].flatMap {round.player($0)?.player.name} ?? "Empty"
        return "Rank \(slot+1): "+name+(progress?.locked.contains(slot) == true ? ", correct and locked":"")
    }
    private func tap(_ slot: Int) {
        guard var next=progress,!finished else {return}
        if let from=selected {
            selected=nil;if next.move(from:from,to:slot,in:round) {progress=next;model.playSound(.reveal);persist()}
        } else if next.slots[slot] == nil {
            if next.place(at:slot,in:round) {progress=next;model.playSound(.reveal);persist()}
        } else if !next.locked.contains(slot) {selected=slot}
    }
    private func drop(_ items: [String],to: Int) -> Bool {
        guard var next=progress,let from=items.first.flatMap(Int.init),next.move(from:from,to:to,in:round) else {return false}
        selected=nil;target=nil;progress=next;model.playSound(.reveal);persist();return true
    }
    private func help() {
        guard var next=progress,next.help(in:round) else {return}
        progress=next;selected=nil;feedback="\(next.locked.count) correct ranks are now locked. You can move the others.";model.playSound(.reveal);persist()
    }
    private func submit() {
        guard var next=progress,next.submit(in:round) else {return}
        progress=next;selected=nil;feedback="";handleResult();persist();model.respond(next.won(round),event:next.won(round) ? .completion:.mismatch)
    }
    private func restore() {guard progress == nil else {return};progress=model.dailyCache?.progress(for:round) ?? PyramidProgress(round:round);easy=progress!.easy;handleResult();persist()}
    private func persist() {guard let progress else {return};do {try model.dailyCache?.save(progress,for:round)} catch {feedback="Couldn’t save this ranking: "+error.localizedDescription}}
    private func handleResult() {
        guard var value=progress,value.finished else {return}
        if value.won(round),model.state.completeGame(id:value.sessionID,kind:"pyramid",count:10,now:model.now) {model.save()}
        if !value.reviewRecorded {
            let wrong=value.slots.enumerated().filter {entry in entry.element != round.correctOrder[entry.offset]}.compactMap { $0.element }.compactMap {round.player($0)?.player}
            if !wrong.isEmpty {model.recordGameGap(game:"pyramid",context:round.title,names:wrong.map(\.name),playerIDs:wrong.map(\.id))}
            value.reviewRecorded=true;progress=value
        }
    }
}
