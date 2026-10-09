import SwiftUI

struct TimelineGameView: View {
    let rounds: [TimelineRound]
    @EnvironmentObject private var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduced
    @Environment(\.scenePhase) private var scenePhase
    @State private var progress=TimelineProgress(roundID:"",order:[],checks:0)
    @State private var sessionID=UUID()
    @State private var loaded=false
    @State private var finished=false
    @State private var assisted=false
    @State private var feedback: String?
    @State private var notice: String?
    @State private var pendingRound: String?
    @State private var confirmRestart=false
    @State private var confirmReveal=false
    @State private var sources=false
    private var round: TimelineRound {rounds.first {$0.id == progress.roundID} ?? rounds[0]}
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:22) {
                HStack(alignment:.center,spacing:16) {
                    ClubMark(club:round.subject,size:64)
                    VStack(alignment:.leading,spacing:6) {
                        Eyebrow(text:"Football timeline")
                        Text(round.definition.title).font(.title2.bold()).accessibilityIdentifier("timeline-title")
                    }
                }
                if let notice {Text(notice).font(.subheadline).foregroundStyle(Palette.muted).accessibilityIdentifier("timeline-notice")}
                Text(finished ? "A few milestones, connected in time." : "Put these milestones from earliest to latest. Drag a milestone to its place in the story.").font(.subheadline).foregroundStyle(Palette.muted)
                HStack {Label("Earliest",systemImage:"arrow.down");Spacer();Text("\(progress.order.count) milestones").contentTransition(.numericText())}.font(.caption.bold()).foregroundStyle(Palette.muted)
                VStack(spacing:0) {
                    ForEach(progress.order,id:\.self) {id in
                        if let event=round.events.first(where:{$0.id == id}),let index=progress.order.firstIndex(of:id) {
                            eventRow(event,index:index)
                                .draggable(finished ? "" : event.id)
                                .dropDestination(for:String.self) {items,_ in
                                    guard !finished,items.count == 1,let id=items.first,progress.order.contains(id),let target=progress.order.firstIndex(of:event.id) else {return false}
                                    withAnimation(reduced ? nil : .snappy) {progress=progress.moving(id,to:target);feedback=nil}
                                    model.playSound(.reveal);persist();return true
                                }
                        }
                    }
                }
                Text("Latest").font(.caption.bold()).foregroundStyle(Palette.muted).padding(.leading,8)
                if finished {
                    HStack(spacing:14) {Leopard(pose:"celebrate").frame(width:62,height:72);VStack(alignment:.leading,spacing:6) {
                        Text(assisted ? "Your timeline, revealed." : "The story is in order!").font(.title2.bold()).accessibilityIdentifier("timeline-complete")
                        Text(assisted ? "Read the dates, then try another round when you’re ready." : "You connected \(round.events.count) milestones.").font(.subheadline).foregroundStyle(Palette.muted)
                    }}.transition(.opacity)
                    PrimaryButton(title:"Play again",symbol:"arrow.clockwise") {begin(round.id)}.accessibilityIdentifier("timeline-replay")
                    Button("Sources & story context",systemImage:"text.book.closed") {sources=true}.frame(minHeight:44).accessibilityIdentifier("timeline-sources")
                } else {
                    if let feedback {Text(feedback).font(.subheadline).foregroundStyle(Palette.muted).accessibilityIdentifier("timeline-feedback")}
                    PrimaryButton(title:"Check the order",symbol:"checkmark") {check()}.accessibilityIdentifier("timeline-check")
                    Button("Reveal the timeline",systemImage:"lightbulb") {confirmReveal=true}.frame(minHeight:44).accessibilityIdentifier("timeline-reveal")
                }
                Text("Story rehearsal, without a timer. Finished timelines support your streak; scheduled recall builds card mastery.").font(.caption).foregroundStyle(Palette.muted)
            }.padding(20)
        }.journal().navigationTitle("Timeline").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Menu {
                ForEach(rounds) {item in Button(item.subject.name) {choose(item.id)}}
            } label:{Label("Choose club",systemImage:"flag")}.accessibilityIdentifier("timeline-club")
            if !finished {Button("Start again",systemImage:"arrow.counterclockwise") {choose(round.id)}.accessibilityIdentifier("timeline-restart")}
        }
        .alert("Start a new timeline?",isPresented:$confirmRestart) {
            Button("Start new timeline",role:.destructive) {begin(pendingRound ?? round.id);pendingRound=nil}
            Button("Keep arranging",role:.cancel) {pendingRound=nil}
        } message:{Text("This replaces your current timeline. Your other games and learning progress stay saved.")}
        .alert("Reveal the dates and order?",isPresented:$confirmReveal) {
            Button("Reveal timeline") {complete(helped:true)}
            Button("Keep arranging",role:.cancel) {}
        } message:{Text("You’ll see the supported timeline and its sources. This is assisted rehearsal and won’t upgrade album cards.")}
        .onAppear {restore()}.onDisappear {persist()}.onChange(of:scenePhase) {if scenePhase != .active {persist()}}
        .sheet(isPresented:$sources) {
            NavigationStack {List {ForEach(round.events.sorted {$0.year < $1.year}) {event in
                Section(event.definition.title) {
                    HStack {EntityArtwork(asset:event.subject.imageAsset,url:nil,initials:"",size:44,isPlayer:event.subject.type == "player");Text(event.subject.name).font(.headline)}
                    Text(event.fact.value.display).font(.title3.bold());Text(event.fact.scope);Text(event.fact.evidence)
                    if let pack=model.pack {ForEach(pack.sources.filter {event.fact.sourceKeys.contains($0.key)}) {source in if let url=URL(string:source.url) {Link(source.title,destination:url)}}}
                }
            }}.navigationTitle("Story context").toolbar {Button("Done") {sources=false}.accessibilityIdentifier("timeline-sources-done")}}
        }
    }
    private func eventRow(_ event: TimelineEvent,index: Int) -> some View {
        HStack(alignment:.center,spacing:10) {
            VStack(spacing:0) {
                Rectangle().fill(index == 0 ? .clear : Palette.brand.opacity(0.18)).frame(width:2)
                Text("\(index+1)").font(.system(size:13,weight:.bold)).frame(width:26,height:26).background(finished ? Palette.brand : Palette.brand.opacity(0.09),in:Circle()).foregroundStyle(finished ? .white : Palette.brand)
                Rectangle().fill(index == progress.order.count-1 ? .clear : Palette.brand.opacity(0.18)).frame(width:2)
            }.frame(width:26).accessibilityHidden(true)
            EntityArtwork(asset:event.subject.imageAsset,url:nil,initials:"",size:44,isPlayer:event.subject.type == "player").accessibilityHidden(true)
            VStack(alignment:.leading,spacing:6) {
                Text(event.definition.title).font(.headline).fixedSize(horizontal:false,vertical:true)
                if finished {Text(event.fact.value.display).font(.subheadline.bold()).foregroundStyle(Palette.brand).transition(.opacity).accessibilityIdentifier("timeline-date-\(event.id)")}
            }.frame(maxWidth:.infinity,alignment:.leading).padding(.vertical,18).accessibilityElement(children:.combine).accessibilityLabel("\(index+1). \(event.definition.title)\(finished ? ". "+event.fact.value.display : "")").accessibilityIdentifier("timeline-event-\(event.id)")
            if !finished {
                VStack(spacing:0) {
                    Button {move(event.id,by:-1)} label:{Image(systemName:"chevron.up").frame(width:44,height:44)}.disabled(index == 0).opacity(index == 0 ? 0.3 : 1).accessibilityLabel("Move \(event.definition.title) earlier").accessibilityValue("Position \(index+1) of \(progress.order.count)").accessibilityIdentifier("timeline-up-\(event.id)")
                    Button {move(event.id,by:1)} label:{Image(systemName:"chevron.down").frame(width:44,height:44)}.disabled(index == progress.order.count-1).opacity(index == progress.order.count-1 ? 0.3 : 1).accessibilityLabel("Move \(event.definition.title) later").accessibilityValue("Position \(index+1) of \(progress.order.count)").accessibilityIdentifier("timeline-down-\(event.id)")
                }.buttonStyle(PressFeedback()).foregroundStyle(Palette.brand)
            }
        }.background(alignment:.bottom) {Rectangle().fill(Palette.brand.opacity(0.09)).frame(height:1).padding(.leading,36)}
    }
    private func move(_ id: String,by offset: Int) {
        guard !finished else {return}
        withAnimation(reduced ? nil : .spring(response:0.32,dampingFraction:0.85)) {progress=progress.moving(id,by:offset);feedback=nil}
        model.playSound(.reveal);persist()
        if let event=round.events.first(where:{$0.id == id}),let index=progress.order.firstIndex(of:id) {UIAccessibility.post(notification:.announcement,argument:"\(event.definition.title), position \(index+1) of \(progress.order.count)")}

    }
    private func check() {
        guard !finished else {return}
        progress=TimelineProgress(roundID:progress.roundID,order:progress.order,checks:min(progress.checks+1,100_000),moves:progress.moves)
        if round.accepts(progress.order) {complete(helped:false)}
        else {model.recordGameGap(game:"timeline",context:round.definition.title,subjects:[round.subject.id],facts:round.events.map(\.fact.id));feedback="Not quite yet. Move a milestone, or reveal the dated story to learn the sequence.";model.respond(false,event:.mismatch);persist();UIAccessibility.post(notification:.announcement,argument:feedback)}
    }
    private func complete(helped: Bool) {
        guard !finished else {return}
        withAnimation(reduced ? nil : .easeInOut(duration:0.3)) {
            if helped {progress=TimelineProgress(roundID:round.id,order:round.answer,checks:progress.checks,moves:progress.moves)}
            assisted=helped;finished=true;feedback=nil;notice=nil
        }
        model.state.removeSavedGame("timeline");_ = model.state.completeGame(id:sessionID,kind:"timeline",count:round.events.count,now:model.now);model.save();model.respond(true,event:.completion)
        UIAccessibility.post(notification:.announcement,argument:helped ? "Timeline revealed. Dates and sources are now available." : "The story is in order. Dates and sources are now available.")
    }
    private func choose(_ id: String) {
        if !finished && (progress.moves > 0 || progress.checks > 0) {pendingRound=id;confirmRestart=true}
        else {begin(id)}
    }
    private func begin(_ id: String) {
        guard let item=rounds.first(where:{$0.id == id}) else {return}
        var order=item.shuffledOrder()
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-ui-testing") {order=Array(item.answer.reversed())}
        #endif
        progress=TimelineProgress(roundID:id,order:order,checks:0);sessionID=UUID();finished=false;assisted=false;feedback=nil;notice=nil;persist()
    }
    private func persist() {
        guard loaded,!finished else {return}
        model.state.storeGame(GameResume(signature:round.signature,sessionID:sessionID,timeline:progress),kind:"timeline");model.save()
    }
    private func restore() {
        guard !loaded else {return};loaded=true
        if let saved=model.state.savedGame("timeline"),let progress=TimelineDeck.restore(saved,rounds:rounds,completedSessions:Set(model.state.sessions.map(\.id))) {
            self.progress=progress;sessionID=saved.sessionID;notice="Your milestones are right where you left them.";return
        }
        let hadSave=model.state.savedGame("timeline") != nil;begin(rounds[0].id)
        if hadSave {notice="The timeline changed. A fresh one is ready; your learning progress is preserved."}
    }
}
