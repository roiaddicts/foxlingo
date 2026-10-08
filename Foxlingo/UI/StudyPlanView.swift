import SwiftUI

struct SessionSizePicker: View {
    @EnvironmentObject private var model: AppModel
    var body: some View {
        Picker("Session length",selection:Binding(get:{model.state.preferredSessionSize ?? 10},set:{model.state.preferredSessionSize=$0;model.save()})) {
            Text("Quick · 5").tag(5)
            Text("Standard · 10").tag(10)
            Text("Longer · 20").tag(20)
        }.pickerStyle(.menu).accessibilityIdentifier("session-size")
    }
}
struct DailyPlanView: View {
    let pack: ContentPack
    let openLesson: (Lesson) -> Void
    let openPractice: (PracticeRoute) -> Void
    @EnvironmentObject private var model: AppModel
    var plan: DailyStudyPlan {model.studyPlan!}
    var body: some View {
        VStack(alignment:.leading,spacing:14) {
            HStack {Eyebrow(text:"Today's plan");Spacer();SessionSizePicker()}
            if model.state.streak.activeDays.contains(StreakState.dayKey(model.now,zone:model.state.homeTimeZone)) {
                Label("You practiced today",systemImage:"checkmark.circle.fill").font(.subheadline.bold()).foregroundStyle(Palette.brand)
            }
            if plan.totalDue > 0 {
                Text("A few familiar connections.").font(.title3.bold())
                Text("\(plan.dueObjectiveIDs.count) in this session · \(plan.totalDue) ready across your roadmaps. \(plan.totalDue > plan.dueObjectiveIDs.count ? "The rest can wait." : "No timer, no pressure.")").font(.subheadline).foregroundStyle(Palette.muted).accessibilityIdentifier("daily-due-count")
                PrimaryButton(title:"Review \(plan.dueObjectiveIDs.count) \(plan.dueObjectiveIDs.count == 1 ? "memory" : "memories")",symbol:"arrow.clockwise") {openPractice(PracticeRoute(plan.dueObjectiveIDs.map(pack.objective),dueMode:true))}.accessibilityIdentifier("daily-review")
                if let id=plan.lessonID {lessonLink(id,primary:false)}
            } else if let id=plan.lessonID {
                Text(plan.isResuming ? "Pick up your story." : "One new football story.").font(.title3.bold())
                lessonLink(id,primary:true)
            } else if !plan.rehearsalObjectiveIDs.isEmpty {
                Text(model.roadmap.map {pack.entity($0.entityID).type == "player"} == true ? "Your player starter is complete." : model.roadmap.map {pack.entity($0.entityID).type == "competition"} == true ? "Your competition foundations are complete." : "Your roadmap is complete.").font(.title3.bold())
                Text("Rehearse a few connections, explore optional context, or choose another roadmap.").font(.subheadline).foregroundStyle(Palette.muted)
                PrimaryButton(title:"Rehearse \(plan.rehearsalObjectiveIDs.count) \(plan.rehearsalObjectiveIDs.count == 1 ? "memory" : "memories")",symbol:"arrow.clockwise") {openPractice(PracticeRoute(plan.rehearsalObjectiveIDs.map(pack.objective),dueMode:false))}.accessibilityIdentifier("daily-rehearsal")
            }
            if !plan.mistakeObjectiveIDs.isEmpty {
                Button {openPractice(PracticeRoute(plan.mistakeObjectiveIDs.map(pack.objective),dueMode:false))} label: {Label("Revisit \(plan.mistakeObjectiveIDs.count) recent tricky \(plan.mistakeObjectiveIDs.count == 1 ? "connection" : "connections")",systemImage:"lightbulb").font(.subheadline.bold()).frame(minHeight:44)}.buttonStyle(PressFeedback()).accessibilityIdentifier("daily-mistakes")
            }
        }.padding(18).background(.white.opacity(0.65),in:RoundedRectangle(cornerRadius:20))
    }
    @ViewBuilder private func lessonLink(_ id: UUID,primary: Bool) -> some View {
        let lesson=pack.lesson(id)
        let selectedOwner=model.roadmap.flatMap {r in r.chapters.filter {$0.isOptional != true}.flatMap(\.lessonIDs).contains(id) ? r : nil}
        let owner=selectedOwner ?? pack.playerRoadmaps.first(where:{$0.chapters.filter {$0.isOptional != true}.flatMap(\.lessonIDs).contains(id)}) ?? pack.competitionRoadmaps.first(where:{$0.chapters.filter {$0.isOptional != true}.flatMap(\.lessonIDs).contains(id)}) ?? pack.clubRoadmaps.first(where:{$0.chapters.flatMap(\.lessonIDs).contains(id)})
        let title="\(plan.isResuming ? "Continue" : "Start"): \(lesson.title)"
        if let owner {Text("\(pack.entity(owner.entityID).name) · \(owner.id == model.roadmap?.id ? "Your roadmap" : "Shared learning library")").font(.caption).foregroundStyle(Palette.muted).accessibilityIdentifier("daily-lesson-subject")}
        if primary {PrimaryButton(title:title,symbol:plan.isResuming ? "play.fill" : "book") {openLesson(lesson)}.accessibilityIdentifier("daily-lesson")}
        else {Button {openLesson(lesson)} label:{Label(title,systemImage:"book").font(.subheadline.bold()).frame(minHeight:44)}.buttonStyle(PressFeedback()).accessibilityIdentifier("daily-lesson")}
    }
}
