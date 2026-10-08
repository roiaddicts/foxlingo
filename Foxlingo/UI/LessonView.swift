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
    @State private var feedback: String?
    @State private var correct = false
    @State private var choiceAnswered = false
    @State private var retries = 0
    var activities: [Exercise] { guard let pack=model.pack else {return []};return lesson.exerciseIDs.map(pack.exercise).filter {$0.kind == "choice"} }
    var exercise: Exercise? { let index=resume.step-2;return activities.indices.contains(index) ? activities[index] : nil }
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:24) {
                if completed {
                    result
                } else {
                    ProgressView(value:Double(resume.step),total:Double(2+activities.count)).tint(Palette.green).accessibilityLabel("Lesson progress, \(resume.step) of \(2+activities.count) steps")
                    Eyebrow(text:resume.step < 2 ? "The story" : "Try it out")
                    if resume.step < 2 {
                        let page=lesson.story[resume.step]
                        Text(page.title).font(.system(.largeTitle,design:.rounded,weight:.bold))
                        Text(page.body).font(.title3).lineSpacing(6)
                        Leopard(pose:"encourage").frame(height:140).frame(maxWidth:.infinity)
                        PrimaryButton(title:resume.step == 0 ? "Keep reading" : "Let's practice") { advance() }.accessibilityIdentifier("lesson-next")
                    } else if let x=exercise {
                        Text(x.prompt).font(.title2.bold())
                        choiceBoard(x)
                        if let feedback {
                            Label(correct ? "Good connection" : "Let's build that memory",systemImage:correct ? "checkmark.circle.fill" : "lightbulb.fill").font(.headline).foregroundStyle(correct ? Palette.green : Palette.ink)
                            Text(feedback).foregroundStyle(Palette.muted).accessibilityIdentifier("answer-feedback")
                        }
                        if x.kind == "choice", choiceAnswered {
                            PrimaryButton(title:correct ? (resume.step == 1+activities.count ? "Finish lesson" : "Continue") : "Try again") {
                                if correct { advance() } else { choiceAnswered=false; feedback=nil; retries += 1 }
                            }.accessibilityIdentifier("answer-next")
                        }
                    }
                    if resume.step >= 2+activities.count {PrimaryButton(title:"Finish lesson") {advance()}.accessibilityIdentifier("finish-lesson")}
                    NavigationLink { LessonSources(lesson:lesson) } label:{Label("Sources & context",systemImage:"text.book.closed").font(.footnote)}
                }
            }.padding(24)
        }.journal().navigationTitle(lesson.title).navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement:.topBarLeading) { Button { persist(); dismiss() } label:{Image(systemName:"xmark")}.accessibilityLabel("Close lesson") } }
        .onAppear { if !loaded { resume=model.state.resumes[lesson.id] ?? LessonResume(); loaded=true; prepare() } }
        .onDisappear { if loaded && !completed { persist() } }
    }
    private func prepare() {
        feedback=nil; correct=false; choiceAnswered=false; retries=0
        if let x=exercise {
            choiceOrder=x.choices.shuffled()

        }
    }
    private func persist() { if !completed { model.state.resumes[lesson.id]=resume;model.save() } }
    private func advance() {
        if resume.step >= 1+activities.count, let pack=model.pack {
            let previous=model.state.acquiredCards
            _ = model.state.completeLesson(lesson,pack:pack,sessionID:resume.sessionID,attempts:resume.attempts,now:model.now)
            unlocked=pack.cards.filter {model.state.acquiredCards.contains($0.id) && !previous.contains($0.id)}
            completed=true;model.respond(true,event:unlocked.isEmpty ? .completion : .unlock);model.save()
        } else { withAnimation(reduced ? nil : .easeInOut(duration:0.2)) { resume.step += 1; resume.matched=[]; resume.memoryOrder=nil; prepare() }; persist() }
    }
    private func record(_ id: UUID, answer: String, success: Bool, hinted: Bool) {
        resume.attempts.append(Attempt(objectiveID:id,answer:answer,correct:success,hinted:hinted,mode:"acquisition",timestamp:model.now));persist()
    }
    private func choiceVisualType(_ x: Exercise) -> String? {
        guard let pack=model.pack,let type=AnswerArtwork.type(objectiveID:x.objectiveIDs[0],pack:pack),x.choices.allSatisfy({AnswerArtwork.canShow($0.text,type:type,pack:pack)}) else {return nil}
        return type
    }
    private func choiceBoard(_ x: Exercise) -> some View {
        VStack(spacing:12) {
            ForEach(choiceOrder) { choice in
                Button {
                    guard !choiceAnswered else{return}
                    correct=x.accepts(choice.id);choiceAnswered=true;feedback=x.feedback;model.respond(correct)
                    record(x.objectiveIDs[0],answer:choice.text,success:correct,hinted:retries>0)
                } label: {
                    HStack { KnowledgeAnswer(text:choice.text,expectedType:choiceVisualType(x)).font(.headline);Spacer(); if choiceAnswered && x.accepts(choice.id) {Image(systemName:"checkmark.circle.fill").foregroundStyle(Palette.green)} }
                        .padding(18).frame(minHeight:56).background(.white.opacity(0.8),in:RoundedRectangle(cornerRadius:16)).overlay { RoundedRectangle(cornerRadius:16).stroke(choiceAnswered && x.accepts(choice.id) ? Palette.green : Palette.ink.opacity(0.12),lineWidth:choiceAnswered && x.accepts(choice.id) ? 2 : 1) }
                }.buttonStyle(.plain).disabled(choiceAnswered).accessibilityIdentifier("answer-\(choice.id)")
            }
        }
    }
    private var resultMessage: String {
        guard let due=lesson.objectiveIDs.compactMap({model.state.reviews[$0]?.due}).min() else {return "Three connections practiced."}
        return due <= model.now ? "Three connections practiced. Scheduled recall is ready in Practice." : "Three connections practiced. Next recall: \(due.formatted(date:.abbreviated,time:.shortened))."
    }
    private var result: some View {
        VStack(alignment:.leading,spacing:22) {
            Leopard(pose:"celebrate").frame(height:110).frame(maxWidth:.infinity)
            Eyebrow(text:"Lesson complete")
            Text("A new part of\nyour football story.").font(.system(.largeTitle,design:.rounded,weight:.bold)).accessibilityIdentifier("lesson-complete")
            Text(resultMessage).foregroundStyle(Palette.muted)
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
