import SwiftUI

struct CoverageView: View {
    @EnvironmentObject private var model: AppModel
    @State private var firstID: UUID?
    @State private var secondID: UUID?
    @State private var selectingFirst: Bool?
    @State private var lesson: Lesson?
    @State private var practice: PracticeRoute?
    @State private var message: String?
    @State private var expanded = Set<UUID>()
    @State private var previewed = Set<UUID>()
    @Environment(\.accessibilityReduceMotion) private var reduced

    var body: some View {
        ScrollView {
            if let pack=model.pack,let first=firstID ?? pack.entities.first(where:{$0.key == "entity-xolos"})?.id,let second=secondID ?? pack.entities.first(where:{$0.key == "entity-madrid"})?.id {
                VStack(alignment:.leading,spacing:24) {
                    Eyebrow(text:"Coverage preparation")
                    Text("Compare two clubs").font(.title.bold())
                    HStack(spacing:12) {selection(pack.entity(first),first:true);Image(systemName:"arrow.left.arrow.right").foregroundStyle(Palette.muted);selection(pack.entity(second),first:false)}
                    if let message {Text(message).foregroundStyle(Palette.red)}
                    if let study=try? CoverageStudyPack.make(pack:pack,firstID:first,secondID:second) {
                        Label("Club comparison · no fixture selected",systemImage:"books.vertical").font(.subheadline.bold()).accessibilityIdentifier("coverage-scope")
                        Text("\(Set(study.first.factIDs + study.second.factIDs).count) sourced historical facts. Live squads, statistics, and a complete head-to-head briefing aren't included.").font(.subheadline).foregroundStyle(Palette.muted)
                        NavigationLink {RehearsalLibrary(lessonIDs:Set(study.first.lessonIDs+study.second.lessonIDs),onPreview:{previewed.formUnion($0)})} label:{Label("Rehearse these stories",systemImage:"text.bubble").font(.headline).frame(minHeight:44)}.buttonStyle(PressFeedback()).accessibilityIdentifier("coverage-rehearse")
                        recall(study,pack:pack)
                        clubStories(study.first,pack:pack)
                        clubStories(study.second,pack:pack)
                        Text("Try explaining one story from each club in your own words. Use Sources & context to check the original evidence before coverage.").font(.subheadline).foregroundStyle(Palette.muted)
                    }
                }.padding(24)
            }
        }.journal().navigationTitle("Study pack").navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented:Binding(get:{selectingFirst != nil},set:{if !$0 {selectingFirst=nil}})) {
            NavigationStack {ClubLibrary(onSelect:{id in
                let other=selectingFirst == true ? secondID ?? model.pack?.entities.first(where:{$0.key == "entity-madrid"})?.id : firstID ?? model.pack?.entities.first(where:{$0.key == "entity-xolos"})?.id
                guard id != other else {message="Choose two different clubs.";selectingFirst=nil;return}
                withAnimation(reduced ? nil : .easeInOut(duration:0.2)) {if selectingFirst == true {firstID=id} else {secondID=id};message=nil}
                selectingFirst=nil
            },onClose:{selectingFirst=nil},excludedClubID:selectingFirst == true ? secondID ?? model.pack?.entities.first(where:{$0.key == "entity-madrid"})?.id : firstID ?? model.pack?.entities.first(where:{$0.key == "entity-xolos"})?.id,selectedClubID:selectingFirst == true ? firstID ?? model.pack?.entities.first(where:{$0.key == "entity-xolos"})?.id : secondID ?? model.pack?.entities.first(where:{$0.key == "entity-madrid"})?.id)}
        }
        .fullScreenCover(item:$lesson) {l in NavigationStack {LessonView(lesson:l)}}
        .navigationDestination(item:$practice) {route in if let pack=model.pack {PracticeSession(objectives:route.objectiveIDs.map(pack.objective),dueMode:true,isCoverage:true,assistedObjectiveIDs:route.assistedObjectiveIDs)}}
    }
    private func selection(_ club: Entity,first: Bool) -> some View {
        Button {selectingFirst=first} label: {
            VStack(spacing:10) {ClubMark(club:club,size:54);Text(club.name).font(.subheadline.bold()).multilineTextAlignment(.center);Image(systemName:"chevron.down").font(.caption)}.frame(maxWidth:.infinity,minHeight:108).padding(12).background(.white.opacity(0.8),in:RoundedRectangle(cornerRadius:18)).contentShape(Rectangle())
        }.buttonStyle(PressFeedback()).accessibilityLabel("Change \(first ? "first" : "second") club, \(club.name)").accessibilityIdentifier(first ? "coverage-first" : "coverage-second")
    }
    private func recall(_ study: CoverageStudyPack,pack: ContentPack) -> some View {
        let learned=study.learnedObjectiveIDs(pack:pack,state:model.state,now:model.now,limit:model.state.preferredSessionSize ?? 10)
        return VStack(alignment:.leading,spacing:12) {
            HStack {Text("Test your connections").font(.headline);Spacer();SessionSizePicker()}
            HStack(spacing:16) {
                ForEach([study.first,study.second],id:\.clubID) {club in
                    let count=learned.filter {club.objectiveIDs.contains($0)}.count
                    HStack(spacing:6) {ClubMark(club:pack.entity(club.clubID),size:24);Text("\(count)").font(.subheadline.bold())}.accessibilityElement(children:.ignore).accessibilityLabel("\(pack.entity(club.clubID).name), \(count) learned connections in this session")
                }
            }
            if learned.isEmpty {
                Text("Read the stories below, then complete a lesson to add its connections to recall.").foregroundStyle(Palette.muted).font(.subheadline).accessibilityIdentifier("coverage-new-learner")
            } else {
                Text("\(learned.count) learned connections in this session. Facts opened here count as rehearsal. Other due answers update your recall. New material stays in its lessons.").font(.subheadline).foregroundStyle(Palette.muted)
                PrimaryButton(title:"Recall this pack",symbol:"arrow.clockwise") {practice=PracticeRoute(learned.map(pack.objective),dueMode:true,assistedObjectiveIDs:previewed)}.accessibilityIdentifier("coverage-recall")
            }
        }.padding(18).background(Palette.brand.opacity(0.07),in:RoundedRectangle(cornerRadius:20))
    }
    private func clubStories(_ study: CoverageClub,pack: ContentPack) -> some View {
        VStack(alignment:.leading,spacing:16) {
            HStack(spacing:12) {ClubMark(club:pack.entity(study.clubID),size:38);Text(pack.entity(study.clubID).name).font(.title2.bold())}
            ForEach(study.lessonIDs,id:\.self) {id in
                let l=pack.lesson(id)
                Button {
                    withAnimation(reduced ? nil : .easeInOut(duration:0.2)) {
                        if expanded.contains(id) {expanded.remove(id)} else {expanded.insert(id);previewed.formUnion(l.objectiveIDs)}
                    }
                } label: {
                    HStack {VStack(alignment:.leading,spacing:4) {Text(l.title).font(.headline);Text(l.subtitle).font(.caption).foregroundStyle(Palette.muted)};Spacer();Image(systemName:expanded.contains(id) ? "chevron.up" : "chevron.down").font(.caption)}.frame(minHeight:48).contentShape(Rectangle())
                }.buttonStyle(PressFeedback()).accessibilityValue(expanded.contains(id) ? "Expanded" : "Collapsed").accessibilityIdentifier("coverage-story-\(l.key)")
                if expanded.contains(id) {
                    VStack(alignment:.leading,spacing:16) {
                        ForEach(Array(l.story.enumerated()),id:\.offset) {_,page in Text(page.body).font(.subheadline).lineSpacing(3)}
                        ForEach(l.objectiveIDs,id:\.self) {oid in
                            let objective=pack.objective(oid)
                            ForEach(objective.factIDs,id:\.self) {fid in
                                if let fact=pack.facts.first(where:{$0.id == fid}) {factRow(fact,objective:objective,pack:pack)}
                            }
                        }
                        Button {lesson=l} label:{Label(model.state.completedLessons.contains(id) ? "Revisit lesson" : "Learn this story",systemImage:"book").font(.headline).frame(minHeight:44)}.accessibilityIdentifier("coverage-learn-\(l.key)")
                    }.padding(.top,12)
                }
                Divider()
            }
        }
    }
    private func factRow(_ fact: Fact,objective: Objective,pack: ContentPack) -> some View {
        VStack(alignment:.leading,spacing:6) {
            Text(objective.prompt).font(.caption).foregroundStyle(Palette.muted)
            HStack(spacing:12) {KnowledgeAnswer(text:fact.value.display,expectedType:AnswerArtwork.type(objectiveID:objective.id,pack:pack)).font(.headline);Spacer()}
            Text(fact.scope).font(.caption).foregroundStyle(Palette.muted)
            ForEach(fact.sourceKeys,id:\.self) {key in
                if let source=pack.sources.first(where:{$0.key == key}),let url=URL(string:source.url) {Link(source.title,destination:url).font(.caption);Text("Checked \(source.verifiedAt)").font(.caption2).foregroundStyle(Palette.muted)}
            }
        }
    }
}
