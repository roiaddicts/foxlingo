import SwiftUI

struct LessonView: View {
    let lesson: Lesson
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.accessibilityReduceMotion) var reduced
    @State private var resume = LessonResume()
    @State private var voiceOver = UIAccessibility.isVoiceOverRunning
    @State private var loaded = false
    @State private var completed = false
    @State private var unlocked: [AlbumCard] = []
    @State private var choiceOrder: [Choice] = []
    @State private var memory = MemoryMatch(pairs:[])
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
                        Text(x.kind == "match" ? "Find the three pairs" : x.prompt).font(.title2.bold())
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
        .onReceive(NotificationCenter.default.publisher(for:UIAccessibility.voiceOverStatusDidChangeNotification)) {_ in voiceOver=UIAccessibility.isVoiceOverRunning}
        .onDisappear { if loaded && !completed { persist() } }
    }
    private func prepare() {
        feedback=nil; correct=false; choiceAnswered=false; retries=0
        if let x=exercise {
            choiceOrder=x.choices.shuffled()
            if x.kind == "match" {
                let ids=(x.left+x.right).map(\.id)
                if resume.memoryOrder == nil || Set(resume.memoryOrder!) != Set(ids) {resume.memoryOrder=ids.shuffled()}
                memory=MemoryMatch(pairs:x.pairs,completed:resume.matched);persist()
            }
        }
    }
    private func persist() { if !completed { model.state.resumes[lesson.id]=resume;model.save() } }
    private func advance() {
        if resume.step == 6, let pack=model.pack {
            let previous=model.state.acquiredCards
            _ = model.state.completeLesson(lesson,pack:pack,sessionID:resume.sessionID,attempts:resume.attempts,now:model.now)
            unlocked=pack.cards.filter {model.state.acquiredCards.contains($0.id) && !previous.contains($0.id)}
            completed=true;model.respond(true);model.save()
        } else { withAnimation(reduced ? nil : .easeInOut(duration:0.2)) { resume.step += 1; resume.matched=[]; resume.memoryOrder=nil; prepare() }; persist() }
    }
    private func record(_ id: UUID, answer: String, success: Bool, hinted: Bool) {
        resume.attempts.append(Attempt(objectiveID:id,answer:answer,correct:success,hinted:hinted,mode:"acquisition",timestamp:model.now));persist()
    }
    private func choiceVisualType(_ x: Exercise) -> String? {
        guard let pack=model.pack,let type=AnswerArtwork.type(objectiveID:x.objectiveIDs[0],pack:pack),x.choices.allSatisfy({AnswerArtwork.canShow($0.text,type:type,pack:pack)}) else {return nil}
        return type
    }
    private func memoryVisualType(_ id: String,exercise x: Exercise) -> String? {
        guard let pack=model.pack,let pair=x.pairs.first(where:{$0.right == id}),let index=x.left.firstIndex(where:{$0.id == pair.left}) else {return nil}
        return AnswerArtwork.type(objectiveID:x.objectiveIDs[index],pack:pack)
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
    private func matchingBoard(_ x: Exercise) -> some View {
        let tiles=resume.memoryOrder ?? (x.left+x.right).map(\.id)
        return VStack(alignment:.leading,spacing:14) {
            Text("Reveal two cards. Match a clue with its fact. Unmatched cards turn face down again.").foregroundStyle(Palette.muted).font(.subheadline)
            Text("\(resume.matched.count) of 3 pairs found").font(.caption.bold()).accessibilityIdentifier("memory-progress")
            LazyVGrid(columns:[GridItem(.flexible()),GridItem(.flexible())],spacing:12) {
                ForEach(Array(tiles.enumerated()),id:\.element) { index,id in
                    if let tile=(x.left+x.right).first(where:{$0.id == id}) {
                        let visible=memory.isVisible(id), done=memory.matched.contains(id)
                        Button {flipMemory(id,exercise:x)} label: {
                            ZStack {
                                RoundedRectangle(cornerRadius:16).fill(done ? Palette.green.opacity(0.12) : visible ? Color.white : Palette.green)
                                if visible {
                                    VStack(spacing:8) {KnowledgeAnswer(text:tile.text,expectedType:memoryVisualType(id,exercise:x)).font(.subheadline.bold()).multilineTextAlignment(.center);if done {Image(systemName:"checkmark.circle.fill").foregroundStyle(Palette.green)}}.padding(14)
                                } else {
                                    VStack(spacing:8) {Image(systemName:"soccerball").font(.title2);Text("Tap to reveal").font(.caption.bold())}.foregroundStyle(.white).padding(14)
                                }
                            }.frame(minHeight:115).contentShape(RoundedRectangle(cornerRadius:16))
                                .overlay {RoundedRectangle(cornerRadius:16).stroke(visible ? Palette.green.opacity(0.4) : .clear,lineWidth:2)}
                        }.buttonStyle(.plain)
                            .accessibilityLabel(visible ? tile.text : "Hidden card \(index+1)")
                            .accessibilityValue(done ? "Matched" : visible ? "Revealed" : "Face down")
                            .accessibilityHint(done ? "Pair found" : "Reveal this card to find its matching connection")
                            .accessibilityIdentifier("match-\(id)")
                    }
                }
            }
            if voiceOver && memory.waitingToClose {
                Button("Turn cards back over") {memory.closeMismatch()}.buttonStyle(PressFeedback())
            }
        }.task(id:"\(memory.faceUp)-\(voiceOver)") {
            guard !voiceOver, memory.waitingToClose else {return}
            do {try await Task.sleep(for:.seconds(1.8))} catch {return}
            guard !Task.isCancelled else {return}
            withAnimation(reduced ? nil : .easeInOut(duration:0.2)) {memory.closeMismatch()}
        }
    }
    private func flipMemory(_ id: String,exercise x: Exercise) {
        let outcome=memory.flip(id)
        switch outcome {
        case .ignored:return
        case .revealed:feedback=nil
        case .matched(let left):
            correct=true;model.respond(true);resume.matched.append(left)
            if let i=x.left.firstIndex(where:{$0.id == left}),let pair=x.pairs.first(where:{$0.left == left}),let target=x.right.first(where:{$0.id == pair.right}) {record(x.objectiveIDs[i],answer:target.text,success:true,hinted:false)}
            feedback="That pair belongs together.";persist()
        case .mismatch:
            correct=false;model.respond(false);feedback="Not a pair. Remember what you revealed, then try another connection."
            if let left=memory.faceUp.first(where:{id in x.left.contains{$0.id == id}}),let i=x.left.firstIndex(where:{$0.id == left}) {
                record(x.objectiveIDs[i],answer:memory.faceUp.compactMap{id in (x.left+x.right).first{$0.id == id}?.text}.joined(separator:" / "),success:false,hinted:false)
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
