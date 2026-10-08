import SwiftUI

struct LessonView: View {
    let lesson: Lesson
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.accessibilityReduceMotion) var reduced
    @State private var resume = LessonResume()
    @State private var loaded = false
    @State private var completed = false
    @State private var unlocked: [AlbumCard] = []
    @State private var choiceOrder: [Choice] = []
    @State private var leftOrder: [Choice] = []
    @State private var rightOrder: [Choice] = []
    @State private var selectedLeft: String?
    @State private var feedback: String?
    @State private var correct = false
    @State private var choiceAnswered = false
    @State private var retries = 0
    var exercise: Exercise? { guard let pack=model.pack, resume.step >= 2 && resume.step < 7 else {return nil}; return pack.exercise(lesson.exerciseIDs[resume.step-2]) }
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:24) {
                if completed {
                    result
                } else {
                    ProgressView(value:Double(resume.step),total:7).tint(Palette.green).accessibilityLabel("Lesson progress, \(resume.step) of 7 steps")
                    Eyebrow(text:resume.step < 2 ? "The story" : "Try it out")
                    if resume.step < 2 {
                        let page=lesson.story[resume.step]
                        Text(page.title).font(.system(.largeTitle,design:.rounded,weight:.bold))
                        Text(page.body).font(.title3).lineSpacing(6)
                        Leopard(pose:"encourage").frame(height:140).frame(maxWidth:.infinity)
                        PrimaryButton(title:resume.step == 0 ? "Keep reading" : "Let's practice") { advance() }.accessibilityIdentifier("lesson-next")
                    } else if let x=exercise {
                        Text(x.prompt).font(.title2.bold())
                        if x.kind == "choice" { choiceBoard(x) } else { matchingBoard(x) }
                        if let feedback {
                            Label(correct ? "Good connection" : "Let's build that memory",systemImage:correct ? "checkmark.circle.fill" : "lightbulb.fill").font(.headline).foregroundStyle(correct ? Palette.green : Palette.ink)
                            Text(feedback).foregroundStyle(Palette.muted).accessibilityIdentifier("answer-feedback")
                        }
                        if x.kind == "choice", choiceAnswered {
                            PrimaryButton(title:correct ? "Continue" : "Try again") {
                                if correct { advance() } else { choiceAnswered=false; feedback=nil; retries += 1 }
                            }.accessibilityIdentifier("answer-next")
                        }
                        if x.kind == "match", resume.matched.count == 3 { PrimaryButton(title:"Finish lesson") { advance() }.accessibilityIdentifier("finish-lesson") }
                    }
                    NavigationLink { LessonSources(lesson:lesson) } label:{Label("Sources & context",systemImage:"text.book.closed").font(.footnote)}
                }
            }.padding(24)
        }.journal().navigationTitle(lesson.title).navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement:.topBarLeading) { Button { persist(); dismiss() } label:{Image(systemName:"xmark")}.accessibilityLabel("Close lesson") } }
        .onAppear { if !loaded { resume=model.state.resumes[lesson.id] ?? LessonResume(); loaded=true; prepare() } }
        .onDisappear { if loaded && !completed { persist() } }
    }
    private func prepare() {
        feedback=nil; correct=false; choiceAnswered=false; selectedLeft=nil; retries=0
        if let x=exercise { choiceOrder=x.choices.shuffled(); leftOrder=x.left.shuffled(); rightOrder=x.right.shuffled() }
    }
    private func persist() { if !completed { model.state.resumes[lesson.id]=resume;model.save() } }
    private func advance() {
        if resume.step == 6, let pack=model.pack {
            let previous=model.state.acquiredCards
            _ = model.state.completeLesson(lesson,pack:pack,sessionID:resume.sessionID,attempts:resume.attempts,now:model.now)
            unlocked=pack.cards.filter {model.state.acquiredCards.contains($0.id) && !previous.contains($0.id)}
            completed=true;model.respond(true);model.save()
        } else { withAnimation(reduced ? nil : .easeInOut(duration:0.2)) { resume.step += 1; resume.matched=[]; prepare() }; persist() }
    }
    private func record(_ id: UUID, answer: String, success: Bool, hinted: Bool) {
        resume.attempts.append(Attempt(objectiveID:id,answer:answer,correct:success,hinted:hinted,mode:"acquisition",timestamp:model.now));persist()
    }
    private func choiceBoard(_ x: Exercise) -> some View {
        VStack(spacing:12) {
            ForEach(choiceOrder) { choice in
                Button {
                    guard !choiceAnswered else{return}
                    correct=x.accepts(choice.id);choiceAnswered=true;feedback=x.feedback;model.respond(correct)
                    record(x.objectiveIDs[0],answer:choice.text,success:correct,hinted:retries>0)
                } label: {
                    HStack { Text(choice.text).font(.headline);Spacer(); if choiceAnswered && x.accepts(choice.id) {Image(systemName:"checkmark.circle.fill").foregroundStyle(Palette.green)} }
                        .padding(18).frame(minHeight:56).background(.white.opacity(0.8),in:RoundedRectangle(cornerRadius:16)).overlay { RoundedRectangle(cornerRadius:16).stroke(choiceAnswered && x.accepts(choice.id) ? Palette.green : Palette.ink.opacity(0.12),lineWidth:choiceAnswered && x.accepts(choice.id) ? 2 : 1) }
                }.buttonStyle(.plain).disabled(choiceAnswered).accessibilityIdentifier("answer-\(choice.id)")
            }
        }
    }
    private func matchingBoard(_ x: Exercise) -> some View {
        VStack(alignment:.leading,spacing:12) {
            Text("Choose a label, then its matching fact.").foregroundStyle(Palette.muted).font(.subheadline)
            HStack(alignment:.top,spacing:12) {
                VStack(spacing:12) { ForEach(leftOrder) { item in
                    let done=resume.matched.contains(item.id)
                    Button {selectedLeft=item.id;feedback=nil} label:{Text(item.text).font(.subheadline.bold()).frame(maxWidth:.infinity,minHeight:72).padding(10).background(done ? Palette.green.opacity(0.12) : .white,in:RoundedRectangle(cornerRadius:14)).overlay {RoundedRectangle(cornerRadius:14).stroke(selectedLeft == item.id ? Palette.green : .clear,lineWidth:2)}}.buttonStyle(.plain).disabled(done).opacity(done ? 0.6 : 1).accessibilityIdentifier("match-\(item.id)")
                } }
                VStack(spacing:12) { ForEach(rightOrder) { item in
                    let matchedLeft=x.pairs.first{$0.right == item.id}?.left
                    let done=matchedLeft.map{resume.matched.contains($0)} ?? false
                    Button {
                        guard let left=selectedLeft else{return}
                        correct=x.accepts(left:left,right:item.id);model.respond(correct)
                        if correct {
                            withAnimation(reduced ? nil : .easeInOut(duration:0.18)) {resume.matched.append(left)}
                            if let i=x.left.firstIndex(where:{$0.id == left}) {record(x.objectiveIDs[i],answer:item.text,success:true,hinted:false)}
                            feedback="That pair belongs together."; selectedLeft=nil;persist()
                        } else {
                            if let pair=x.pairs.first(where:{$0.left==left}),let target=x.right.first(where:{$0.id==pair.right}),let label=x.left.first(where:{$0.id==left}) {feedback="\(label.text) connects to \(target.text). Try that pair."}
                            if let i=x.left.firstIndex(where:{$0.id == left}) {record(x.objectiveIDs[i],answer:item.text,success:false,hinted:false)}
                        }
                    } label:{Text(item.text).font(.subheadline.bold()).frame(maxWidth:.infinity,minHeight:72).padding(10).background(done ? Palette.green.opacity(0.12) : .white,in:RoundedRectangle(cornerRadius:14))}.buttonStyle(.plain).disabled(done || selectedLeft == nil).opacity(done ? 0.6 : 1).accessibilityIdentifier("match-\(item.id)")
                } }
            }
        }
    }
    private var result: some View {
        VStack(alignment:.leading,spacing:22) {
            Leopard(pose:"celebrate").frame(height:110).frame(maxWidth:.infinity)
            Eyebrow(text:"Lesson complete")
            Text("A new part of\nyour football story.").font(.system(.largeTitle,design:.rounded,weight:.bold)).accessibilityIdentifier("lesson-complete")
            Text("Three connections learned. Your next recall is scheduled for tomorrow.").foregroundStyle(Palette.muted)
            ForEach(unlocked) { c in if let pack=model.pack { HStack {Image(systemName:"rectangle.portrait.fill").font(.title).foregroundStyle(Palette.ochre); VStack(alignment:.leading) {Text("Card unlocked").font(.caption.bold());Text(pack.entity(c.entityID).name).font(.headline)};Spacer();Text("Cardboard").font(.caption.bold())}.padding(16).background(.white,in:RoundedRectangle(cornerRadius:18)) } }
            Text("Your streak grows with practice. Your card grows with what you remember.").font(.subheadline)
            PrimaryButton(title:"Back to the roadmap") { dismiss() }.accessibilityIdentifier("back-roadmap")
        }
    }
}
struct LessonSources: View {
    let lesson: Lesson
    @EnvironmentObject var model: AppModel
    var body: some View {
        List {
            if let p=model.pack {
                ForEach(lesson.objectiveIDs,id:\.self) { oid in
                    let o=p.objective(oid)
                    Section(o.prompt) { ForEach(o.factIDs,id:\.self) { fid in if let f=p.facts.first(where:{$0.id==fid}) {
                        Text(f.value.display).font(.headline);Text(f.scope).font(.caption)
                        ForEach(f.sourceKeys,id:\.self) { key in if let s=p.sources.first(where:{$0.key==key}),let url=URL(string:s.url) { Link(s.title,destination:url);Text("Verified \(s.verifiedAt)").font(.caption).foregroundStyle(.secondary) } }
                    } } }
                }
            }
        }.navigationTitle("Sources & context")
    }
}
