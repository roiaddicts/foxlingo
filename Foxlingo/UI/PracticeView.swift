import SwiftUI

struct PracticeRoute: Identifiable, Hashable {
    let id = UUID()
    let objectiveIDs: [UUID]
    let dueMode: Bool
    init(_ objectives: [Objective], dueMode: Bool) { objectiveIDs=objectives.map(\.id); self.dueMode=dueMode }
}
struct PracticeHome: View {
    @EnvironmentObject var model: AppModel
    @State private var route: PracticeRoute?
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:24) {
                Eyebrow(text:"Keep the connections")
                Text("Practice").font(.system(.largeTitle,design:.rounded,weight:.black))
                Leopard(pose:"encourage").frame(height:95).frame(maxWidth:.infinity)
                if !model.due.isEmpty {
                    Text("\(model.due.count) memories\nready to revisit.").font(.title.bold())
                    Text("A short recall session, across both clubs. No timer, no pressure.").foregroundStyle(Palette.muted)
                    Button { route=PracticeRoute(model.due,dueMode:true) } label: { HStack {Text("Start review").font(.headline);Spacer();Image(systemName:"arrow.right")}.padding(18).background(Palette.green,in:RoundedRectangle(cornerRadius:18)).foregroundStyle(.white) }.accessibilityIdentifier("start-review")
                } else if let p=model.pack {
                    let learned=p.objectives.filter {model.state.reviews[$0.id] != nil}.sorted{$0.key < $1.key}
                    Text(learned.isEmpty ? "Your first memories\nstart with a lesson." : "You're all caught up.").font(.title.bold())
                    Text(learned.isEmpty ? "Choose Xolos or Madrid in Learn, then come back for recall." : "Your memories are resting. You can rehearse now, or wait until they're due.").foregroundStyle(Palette.muted)
                    if !learned.isEmpty {
                        if let next=model.state.reviews.values.map(\.due).min() { Text("Next review: \(next.formatted(date:.abbreviated,time:.shortened))").font(.subheadline) }
                        Button {route=PracticeRoute(Array(learned.prefix(10)),dueMode:false)} label:{Label("Optional practice",systemImage:"play.fill").font(.headline)}.accessibilityIdentifier("optional-practice")
                    }
                }
                Divider()
                Text("Why recall?").font(.headline)
                Text("Finding an answer in memory builds a different skill from recognizing it on a screen. Card upgrades come from successful recall when reviews are due.").foregroundStyle(Palette.muted)
            }.padding(24)
        }.journal().navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item:$route) { r in if let p=model.pack {PracticeSession(objectives:r.objectiveIDs.map(p.objective),dueMode:r.dueMode)} }
    }
}
struct PracticeSession: View {
    let objectives: [Objective]
    let dueMode: Bool
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) var dismiss
    @State private var index=0
    @State private var answer=""
    @State private var submitted=false
    @State private var hinted=false
    @State private var correct=false
    @State private var successes=0
    @State private var sessionID=UUID()
    @State private var completed=false
    @FocusState private var focused: Bool
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:24) {
                if completed {
                    Leopard(pose:"celebrate").frame(height:110).frame(maxWidth:.infinity)
                    Text("Practice complete").font(.largeTitle.bold()).accessibilityIdentifier("practice-complete")
                    Text("\(successes) of \(objectives.count) recalled independently.").font(.headline)
                    Text(dueMode ? "Your next reviews are scheduled. Every attempt helps you find what to revisit." : "A little rehearsal counts toward your streak. Scheduled recall is what improves your cards.").foregroundStyle(Palette.muted)
                    PrimaryButton(title:"Done") {dismiss()}.accessibilityIdentifier("practice-done")
                } else if !objectives.isEmpty {
                    let o=objectives[index]
                    ProgressView(value:Double(index),total:Double(objectives.count))
                    Eyebrow(text:dueMode ? "Scheduled recall · \(index+1) of \(objectives.count)" : "Rehearsal · \(index+1) of \(objectives.count)")
                    Text(o.prompt).font(.title2.bold())
                    Text("A short answer is enough.").foregroundStyle(Palette.muted)
                    TextField("Your answer",text:$answer,axis:.vertical).font(.title3).padding(18).background(.white,in:RoundedRectangle(cornerRadius:16)).focused($focused).disabled(submitted).autocorrectionDisabled().submitLabel(.done).accessibilityIdentifier("recall-answer")
                    if submitted {
                        Label(correct && !hinted ? "You remembered" : "A connection to revisit",systemImage:correct && !hinted ? "checkmark.circle.fill" : "lightbulb.fill").font(.headline).foregroundStyle(Palette.green)
                        Text(o.feedback).accessibilityIdentifier("recall-feedback")
                        if hinted {Text("Revealed answers don't count as independent recall.").font(.footnote).foregroundStyle(Palette.muted)}
                        PrimaryButton(title:index == objectives.count-1 ? "Finish practice" : "Next memory") {next()}.accessibilityIdentifier("recall-next")
                    } else {
                        PrimaryButton(title:"Check answer") {submit(reveal:false)}.disabled(Recall.normalize(answer).isEmpty).opacity(Recall.normalize(answer).isEmpty ? 0.5 : 1).accessibilityIdentifier("check-recall")
                        Button("Reveal answer") {submit(reveal:true)}.frame(minHeight:44).accessibilityIdentifier("reveal-recall")
                    }
                }
            }.padding(24)
        }.journal().navigationTitle("Recall practice").navigationBarTitleDisplayMode(.inline)
    }
    private func submit(reveal: Bool) {
        guard !submitted else{return}
        focused=false;hinted=reveal
        let o=objectives[index];correct = !reveal && Recall.accepts(answer,for:o)
        if correct {successes += 1}
        model.state.recordRecall(Attempt(objectiveID:o.id,answer:answer,correct:correct,hinted:reveal,mode:dueMode ? "due" : "early",timestamp:model.now),objective:o)
        model.respond(correct);model.save();submitted=true
    }
    private func next() {
        if index == objectives.count-1 { _ = model.state.completePractice(id:sessionID,count:objectives.count,now:model.now);model.save();completed=true }
        else {index += 1;answer="";submitted=false;hinted=false;correct=false}
    }
}
