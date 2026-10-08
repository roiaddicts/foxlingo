import SwiftUI

struct RehearsalLibrary: View {
    var lessonIDs: Set<UUID>? = nil
    var onPreview: (Set<UUID>)->Void = {_ in}
    @EnvironmentObject private var model: AppModel
    private var topics: [RehearsalTopic] {model.rehearsalTopics.filter {lessonIDs == nil || lessonIDs!.contains($0.lesson.id)}}
    var body: some View {
        ScrollView {VStack(alignment:.leading,spacing:22) {
            Eyebrow(text:"Coverage rehearsal")
            Text("Tell the football story").font(.largeTitle.bold())
            Text("Try a short explanation, then check three sourced anchors. Write a note or rehearse aloud.").foregroundStyle(Palette.muted)
            ForEach(topics) {topic in
                NavigationLink {RehearsalView(topic:topic,onPreview:onPreview)} label: {
                    HStack(spacing:14) {ClubMark(club:topic.subject,size:48);VStack(alignment:.leading,spacing:5) {Text(topic.lesson.title).font(.headline);Text(model.state.rehearsals?.drafts[topic.id] != nil ? "Continue your explanation" : topic.lesson.subtitle).font(.subheadline).foregroundStyle(Palette.muted)};Spacer();Image(systemName:"chevron.right").font(.caption)}.frame(minHeight:72).padding(.vertical,8)
                }.buttonStyle(PressFeedback()).accessibilityIdentifier("rehearsal-topic-\(topic.lesson.key)")
                Divider()
            }
            if topics.isEmpty {Text(model.rehearsalError ?? "No rehearsal stories are available for these clubs yet.").foregroundStyle(Palette.muted)}
            if model.state.rehearsals?.records.isEmpty == false {NavigationLink {RehearsalHistoryView(onPreview:onPreview)} label:{Label("Saved explanations",systemImage:"text.book.closed")}.frame(minHeight:44).accessibilityIdentifier("rehearsal-history")}
            Text("Historical stories, not a live fixture briefing. Self-check supports reflection; it does not grade your explanation or upgrade cards.").font(.footnote).foregroundStyle(Palette.muted)
        }.padding(24)}.journal().navigationTitle("Rehearse").navigationBarTitleDisplayMode(.inline)
    }
}
struct RehearsalView: View {
    let topic: RehearsalTopic
    var onPreview: (Set<UUID>)->Void = {_ in}
    @EnvironmentObject private var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduced
    @Environment(\.scenePhase) private var scenePhase
    @State private var draft: RehearsalDraft?
    @State private var finished=false
    @State private var notice: String?
    @State private var restart=false
    @FocusState private var writing: Bool
    var body: some View {
        ScrollView {
            if let draft {VStack(alignment:.leading,spacing:22) {
                HStack(spacing:14) {ClubMark(club:topic.subject,size:60);VStack(alignment:.leading,spacing:5) {Eyebrow(text:finished ? "Rehearsal complete" : draft.revealed ? "Check your account" : "Tell the story");Text(topic.lesson.title).font(.title2.bold())}}
                if let notice {Text(notice).font(.subheadline).foregroundStyle(Palette.muted).accessibilityIdentifier("rehearsal-notice")}
                Text(topic.definition.prompt).font(.title3.bold())
                if finished {
                    HStack(spacing:12) {Leopard(pose:"celebrate").frame(width:60,height:70);Text("Rehearsal complete").font(.title2.bold()).accessibilityIdentifier("rehearsal-complete")}
                    Text("Your explanation and reflection are saved. Scheduled recall still builds card mastery.").foregroundStyle(Palette.muted)
                    PrimaryButton(title:"Rehearse again",symbol:"arrow.clockwise") {begin()}.accessibilityIdentifier("rehearsal-replay")
                }
                if !draft.revealed {
                    Picker("How to rehearse",selection:Binding(get:{draft.mode},set:{mode in update {$0.mode=mode}})) {Text("Write a note").tag(RehearsalMode.typed);Text("Say it aloud").tag(RehearsalMode.aloud)}.pickerStyle(.segmented).accessibilityIdentifier("rehearsal-mode")
                    if draft.mode == .typed {
                        Text("Explain it in your own words before seeing the anchors.").font(.subheadline).foregroundStyle(Palette.muted)
                        TextEditor(text:textBinding(revised:false)).frame(minHeight:150).padding(10).background(.white,in:RoundedRectangle(cornerRadius:14)).scrollContentBackground(.hidden).focused($writing).accessibilityLabel("Your original explanation").accessibilityIdentifier("rehearsal-response")
                        Text("\(draft.response.count) / 4000 characters · saved locally").font(.caption).foregroundStyle(Palette.muted)
                    } else {
                        Text("Try saying the story aloud. The app does not listen or record; you’ll check it yourself.").font(.subheadline).foregroundStyle(Palette.muted)
                        Toggle("I finished explaining",isOn:Binding(get:{draft.explained},set:{value in update {$0.explained=value}})).accessibilityIdentifier("rehearsal-explained")
                    }
                    PrimaryButton(title:"Check the story",symbol:"text.magnifyingglass") {
                        guard draft.canReveal else {return};writing=false
                        withAnimation(reduced ? nil : .easeInOut(duration:0.25)) {update {$0.revealed=true}}
                        onPreview(topic.objectiveIDs);model.playSound(.reveal)
                    }.disabled(!draft.canReveal).opacity(draft.canReveal ? 1 : 0.4).accessibilityIdentifier("rehearsal-check")
                } else {
                    if draft.mode == .typed {Text("Your original explanation").font(.headline);Text(draft.response).textSelection(.enabled).accessibilityIdentifier("rehearsal-original")}
                    else {Label("Rehearsed aloud · no recording",systemImage:"waveform").font(.subheadline)}
                    Text("Which points did you include? Choose a reflection for every anchor. It’s fine to mark all three as missed.").font(.subheadline).foregroundStyle(Palette.muted)
                    ForEach(Array(topic.objectives.enumerated()),id:\.element.id) {index,objective in
                        VStack(alignment:.leading,spacing:12) {
                            Text(topic.definition.anchorTitles[index]).font(.headline)
                            ForEach(topic.facts[index]) {fact in
                                HStack {KnowledgeAnswer(text:fact.value.display,expectedType:AnswerArtwork.type(objectiveID:objective.id,pack:model.pack!)).font(.title3.bold());Spacer()}
                                Text(fact.scope).font(.caption).foregroundStyle(Palette.muted)
                                Text(fact.evidence).font(.subheadline)
                                if let pack=model.pack {ForEach(pack.sources.filter {fact.sourceKeys.contains($0.key)}) {source in if let url=URL(string:source.url) {Link(source.title,destination:url).font(.caption)}}}
                            }
                            if !finished {
                                Menu {ForEach(RehearsalReflection.allCases,id:\.self) {reflection in Button(reflectionLabel(reflection)) {update {$0.checks[objective.id]=reflection}}}} label: {
                                    HStack {Text(draft.checks[objective.id].map(reflectionLabel) ?? "Choose your reflection");Spacer();Image(systemName:"chevron.down")}.font(.subheadline.bold()).frame(minHeight:44)
                                }.accessibilityLabel("\(topic.definition.anchorTitles[index]), \(draft.checks[objective.id].map(reflectionLabel) ?? "not reflected yet")").accessibilityIdentifier("rehearsal-reflection-\(index)")
                            } else {Text(draft.checks[objective.id].map(reflectionLabel) ?? "").font(.subheadline.bold()).foregroundStyle(Palette.muted)}
                        }.padding(18).frame(maxWidth:.infinity,alignment:.leading).background(.white.opacity(0.8),in:RoundedRectangle(cornerRadius:18))
                    }
                    if !finished {
                        Text("A revised explanation (optional)").font(.headline)
                        TextEditor(text:textBinding(revised:true)).frame(minHeight:120).padding(10).background(.white,in:RoundedRectangle(cornerRadius:14)).scrollContentBackground(.hidden).focused($writing).accessibilityLabel("Your revised explanation").accessibilityIdentifier("rehearsal-revised")
                        PrimaryButton(title:"Finish rehearsal",symbol:"checkmark") {finish()}.disabled(!draft.canFinish(topic)).opacity(draft.canFinish(topic) ? 1 : 0.4).accessibilityIdentifier("rehearsal-finish")
                    }
                }
            }.padding(24)}
        }.journal().navigationTitle("Coverage rehearsal").navigationBarTitleDisplayMode(.inline)
        .toolbar {if writing {Button("Done") {writing=false}} else if !finished {Button("Start again",systemImage:"arrow.counterclockwise") {restart=true}.accessibilityIdentifier("rehearsal-restart")}}
        .alert("Start this explanation again?",isPresented:$restart) {Button("Start again",role:.destructive) {if let draft {model.state.archiveRehearsal(draft,title:topic.lesson.title,now:model.now)};begin()};Button("Keep my explanation",role:.cancel) {}} message:{Text("Your current notes will be kept in Saved explanations.")}
        .onAppear {restore()}.onDisappear {persist()}.onChange(of:scenePhase) {if scenePhase != .active {persist()}}
        .task(id:"\(draft?.response ?? "")\u{0}\(draft?.revisedResponse ?? "")") {do {try await Task.sleep(for:.milliseconds(400))} catch {return};persist()}
    }
    private func reflectionLabel(_ value: RehearsalReflection) -> String {switch value {case .included:"I included this";case .missed:"I missed this";case .unsure:"I'm unsure"}}
    private func textBinding(revised: Bool) -> Binding<String> {Binding(get:{revised ? draft?.revisedResponse ?? "" : draft?.response ?? ""},set:{value in guard !finished,var changed=draft else {return};if revised {changed.revisedResponse=String(value.prefix(4000))} else if !changed.revealed {changed.response=String(value.prefix(4000))};draft=changed})}
    private func update(_ action: (inout RehearsalDraft)->Void) {guard !finished,var value=draft else {return};action(&value);draft=value;persist()}
    private func persist() {guard !finished,let draft else {return};model.state.storeRehearsal(draft);model.save()}
    private func begin() {draft=RehearsalDraft(topic:topic);finished=false;notice=nil;persist()}
    private func restore() {
        guard draft == nil else {return}
        if let saved=model.state.rehearsals?.drafts[topic.id] {
            if saved.valid(for:topic,completed:Set(model.state.sessions.map(\.id))) {draft=saved;notice="Your explanation is right where you left it.";if saved.revealed {onPreview(topic.objectiveIDs)};return}
            model.state.archiveRehearsal(saved,title:topic.lesson.title,now:model.now);begin();notice="The story changed. Your earlier notes are in Saved explanations; this rehearsal uses the updated anchors.";return
        }
        begin()
    }
    private func finish() {guard !finished,let draft,model.state.completeRehearsal(draft,topic:topic,now:model.now) else {return};writing=false;finished=true;model.save();model.respond(true,event:.completion)}
}
struct RehearsalHistoryView: View {
    var onPreview: (Set<UUID>)->Void = {_ in}
    @EnvironmentObject private var model: AppModel
    var body: some View {
        List {ForEach((model.state.rehearsals?.records ?? []).reversed()) {record in
            Section(record.title) {Text(record.completed ? "Completed rehearsal" : "Earlier draft").font(.headline);Text(record.savedAt.formatted(date:.abbreviated,time:.shortened)).font(.caption)
                Text(record.draft.prompt).font(.subheadline)
                ForEach(Array(zip(record.draft.anchorIDs,record.draft.anchorTitles)),id:\.0) {id,title in if let reflection=record.draft.checks[id] {Text(title+": "+(reflection == .included ? "Included" : reflection == .missed ? "Missed" : "Unsure"))}}
                if !record.draft.response.isEmpty {Text("Original explanation").font(.headline);Text(record.draft.response).textSelection(.enabled)}
                if record.draft.mode == .aloud {Text("Rehearsed aloud; no audio was recorded.")}
                if !record.draft.revisedResponse.isEmpty {Text("Revised explanation").font(.headline);Text(record.draft.revisedResponse).textSelection(.enabled)}
            }
        }}.navigationTitle("Saved explanations").onAppear {onPreview(Set((model.state.rehearsals?.records ?? []).flatMap {$0.draft.anchorIDs}))}
    }
}
