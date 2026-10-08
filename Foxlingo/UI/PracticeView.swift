import SwiftUI

struct PracticeRoute: Identifiable, Hashable {
    let id = UUID()
    let objectiveIDs: [UUID]
    let dueMode: Bool
    let assistedObjectiveIDs: Set<UUID>
    init(_ objectives: [Objective], dueMode: Bool, assistedObjectiveIDs: Set<UUID> = []) { objectiveIDs=objectives.map(\.id); self.dueMode=dueMode;self.assistedObjectiveIDs=assistedObjectiveIDs }
}
struct PracticeHome: View {
    @EnvironmentObject var model: AppModel
    @State private var route: PracticeRoute?
    @State private var rehearsalPreviewed=Set<UUID>()
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:24) {
                Eyebrow(text:"Keep the connections")
                Text("Practice").font(.system(.largeTitle,design:.rounded,weight:.black))
                Leopard(pose:"encourage").frame(height:95).frame(maxWidth:.infinity)
                SessionSizePicker()
                if !model.due.isEmpty {
                    Text("\(model.studyPlan?.totalDue ?? 0) memories\nready to revisit.").font(.title.bold())
                    Text("\(model.due.count) in this session, across your learned subjects. No timer, no pressure. The rest can wait.").foregroundStyle(Palette.muted)
                    Button { route=PracticeRoute(model.due,dueMode:true,assistedObjectiveIDs:rehearsalPreviewed) } label: { HStack {Text("Start review").font(.headline);Spacer();Image(systemName:"arrow.right")}.padding(18).background(Palette.brand,in:RoundedRectangle(cornerRadius:18)).foregroundStyle(.white) }.accessibilityIdentifier("start-review")
                } else if let p=model.pack {
                    let learned=(model.studyPlan?.rehearsalObjectiveIDs ?? []).map(p.objective)
                    Text(learned.isEmpty ? "Your first memories\nstart with a lesson." : "You're all caught up.").font(.title.bold())
                    Text(learned.isEmpty ? "Choose a roadmap in Learn, then come back for recall." : "Your memories are resting. You can rehearse now, or wait until they're due.").foregroundStyle(Palette.muted)
                    if !learned.isEmpty {
                        if let next=model.state.reviews.values.map(\.due).min() { Text("Next review: \(next.formatted(date:.abbreviated,time:.shortened))").font(.subheadline) }
                        Button {route=PracticeRoute(learned,dueMode:false,assistedObjectiveIDs:rehearsalPreviewed)} label:{Label("Optional practice",systemImage:"play.fill").font(.headline)}.accessibilityIdentifier("optional-practice")
                    }
                }
                if let p=model.pack,let plan=model.studyPlan,!plan.mistakeObjectiveIDs.isEmpty {
                    Button {route=PracticeRoute(plan.mistakeObjectiveIDs.map(p.objective),dueMode:false,assistedObjectiveIDs:rehearsalPreviewed)} label:{Label("Recent tricky connections",systemImage:"lightbulb").font(.headline).frame(minHeight:44)}.accessibilityIdentifier("practice-mistakes")
                }
                NavigationLink {RehearsalLibrary(onPreview:{rehearsalPreviewed.formUnion($0)})} label: {Label("Rehearse a football story",systemImage:"text.bubble").font(.headline).frame(minHeight:44)}.buttonStyle(PressFeedback()).accessibilityIdentifier("rehearsal-open")
                NavigationLink {CoverageView()} label: {
                    HStack(spacing:14) {Image(systemName:"books.vertical").font(.title2);VStack(alignment:.leading,spacing:5) {Text("Prepare with two clubs").font(.headline);Text("Sourced stories and mixed recall").font(.subheadline).foregroundStyle(Palette.muted)};Spacer();Image(systemName:"chevron.right").font(.caption)}.padding(18).background(.white.opacity(0.75),in:RoundedRectangle(cornerRadius:18)).contentShape(Rectangle())
                }.buttonStyle(PressFeedback()).accessibilityIdentifier("coverage-open")
                Divider()
                Text("Why recall?").font(.headline)
                Text("Finding an answer in memory builds a different skill from recognizing it on a screen. Card upgrades come from successful recall when reviews are due.").foregroundStyle(Palette.muted)
            }.padding(24)
        }.journal().navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item:$route) { r in if let p=model.pack {PracticeSession(objectives:r.objectiveIDs.map(p.objective),dueMode:r.dueMode,assistedObjectiveIDs:r.assistedObjectiveIDs,previewContext:"the story rehearsal")} }
    }
}
struct PracticeSession: View {
    let objectives: [Objective]
    let dueMode: Bool
    var isCoverage = false
    var assistedObjectiveIDs: Set<UUID> = []
    var previewContext = "the study pack"
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) var dismiss
    @State private var index=0
    @State private var answer=""
    @State private var scoreLeft=0
    @State private var scoreRight=0
    @State private var submitted=false
    @State private var hinted=false
    @State private var correct=false
    @State private var successes=0
    @State private var scheduledAttempts=0
    @Environment(\.accessibilityReduceMotion) private var reduced
    @State private var sessionID=UUID()
    @State private var completed=false
    @FocusState private var focused: Bool
    var body: some View {
        ScrollViewReader {proxy in
        ScrollView {
            VStack(alignment:.leading,spacing:24) {
                if completed {
                    Leopard(pose:"celebrate").frame(height:110).frame(maxWidth:.infinity)
                    Text("Practice complete").font(.largeTitle.bold()).accessibilityIdentifier("practice-complete")
                    Text("\(successes) of \(objectives.count) recalled independently.").font(.headline)
                    Text(scheduledAttempts > 0 ? "\(scheduledAttempts) scheduled \(scheduledAttempts == 1 ? "review" : "reviews") updated. Early answers were rehearsal." : "This was rehearsal. Scheduled recall is what improves your cards.").foregroundStyle(Palette.muted)
                    PrimaryButton(title:"Done") {dismiss()}.accessibilityIdentifier("practice-done")
                } else if !objectives.isEmpty {
                    let o=objectives[index]
                    ProgressView(value:Double(index),total:Double(objectives.count)).animation(reduced ? nil : .easeInOut(duration:0.2),value:index)
                    Eyebrow(text:isCoverage ? "Coverage recall · \(index+1) of \(objectives.count)" : dueMode ? "Scheduled recall · \(index+1) of \(objectives.count)" : "Rehearsal · \(index+1) of \(objectives.count)")
                    if let pack=model.pack,let subject=Recall.subjectArtwork(for:o,pack:pack,answerRevealed:submitted) {
                        HStack(alignment:.top,spacing:12) {ClubMark(club:subject,size:48);Text(subject.name).font(.subheadline.bold()).foregroundStyle(Palette.muted).accessibilityIdentifier("recall-subject")}
                    }
                    Text(o.prompt).font(.title2.bold())
                    if let score=model.pack?.scoreInput(for:o.id) {
                        Text("Set both sides of the score.").foregroundStyle(Palette.muted)
                        ScoreWheels(input:score,left:$scoreLeft,right:$scoreRight).disabled(submitted)
                    } else {
                    Text("A short answer is enough.").foregroundStyle(Palette.muted)
                    TextField("Your answer",text:$answer,axis:.vertical).font(.title3).padding(18).background(.white,in:RoundedRectangle(cornerRadius:16)).focused($focused).disabled(submitted).autocorrectionDisabled().submitLabel(.done).accessibilityIdentifier("recall-answer")
                    }
                    if submitted {
                        Label(correct && !hinted ? "You remembered" : "A connection to revisit",systemImage:correct && !hinted ? "checkmark.circle.fill" : "lightbulb.fill").font(.headline).foregroundStyle(correct && !hinted ? Palette.brand : Palette.ink).id("recall-feedback-top").accessibilityIdentifier("recall-feedback-heading")
                        Text(o.feedback).accessibilityIdentifier("recall-feedback")
                        if hinted {Text(assistedObjectiveIDs.contains(o.id) ? "You previewed this fact in \(previewContext). This answer counts as rehearsal." : "Revealed answers don't count as independent recall.").font(.footnote).foregroundStyle(Palette.muted)}
                        PrimaryButton(title:index == objectives.count-1 ? "Finish practice" : "Next memory") {next()}.accessibilityIdentifier("recall-next")
                    } else {
                        PrimaryButton(title:model.pack?.scoreInput(for:o.id) == nil ? "Check answer" : "Check score") {submit(reveal:false)}.disabled(model.pack?.scoreInput(for:o.id) == nil && Recall.normalize(answer).isEmpty).opacity(model.pack?.scoreInput(for:o.id) == nil && Recall.normalize(answer).isEmpty ? 0.5 : 1).accessibilityIdentifier("check-recall")
                        Button("Reveal answer") {submit(reveal:true)}.frame(minHeight:44).accessibilityIdentifier("reveal-recall")
                    }
                }
            }.padding(24).id("recall-top")
        }
        .onChange(of:submitted) {_,value in if value {proxy.scrollTo("recall-feedback-top",anchor:.top)}}
        .onChange(of:index) {_,_ in proxy.scrollTo("recall-top",anchor:.top)}
        .onChange(of:completed) {_,_ in proxy.scrollTo("recall-top",anchor:.top)}
        }.journal().navigationTitle(isCoverage ? "Coverage recall" : "Recall practice").navigationBarTitleDisplayMode(.inline)
    }
    private func submit(reveal: Bool) {
        guard !submitted else{return}
        focused=false
        let o=objectives[index];let previewed=assistedObjectiveIDs.contains(o.id);hinted=reveal || previewed
        if let score=model.pack?.scoreInput(for:o.id) {
            answer="\(scoreLeft)–\(scoreRight)"
            correct = !reveal && score.accepts(left:scoreLeft,right:scoreRight)
        } else {correct = !reveal && Recall.accepts(answer,for:o)}
        if correct && !hinted {successes += 1}
        if dueMode && !previewed,let review=model.state.reviews[o.id],review.revision == o.revision,review.due <= model.now {scheduledAttempts += 1}
        let previousTier=model.pack?.cards.map {model.state.tier($0)} ?? []
        model.state.recordRecall(Attempt(objectiveID:o.id,answer:answer,correct:correct,hinted:hinted,mode:dueMode && !previewed ? "due" : "early",timestamp:model.now),objective:o)
        let upgraded=model.pack.map {pack in zip(previousTier,pack.cards.map {model.state.tier($0)}).contains {$1 > $0}} ?? false
        if !reveal {model.respond(correct,event:upgraded ? .unlock : nil)} else {model.playSound(.reveal)}
        model.save();submitted=true
    }
    private func next() {
        if index == objectives.count-1 { _ = model.state.completePractice(id:sessionID,count:objectives.count,now:model.now);model.save();completed=true;model.respond(true,event:.completion) }
        else {index += 1;answer="";scoreLeft=0;scoreRight=0;submitted=false;hinted=false;correct=false}
    }
}
