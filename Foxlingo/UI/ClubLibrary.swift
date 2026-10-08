import SwiftUI

struct ClubLibrary: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduced
    let onSelect: (UUID) -> Void
    let onClose: () -> Void
    var excludedClubID: UUID? = nil
    var selectedClubID: UUID? = nil
    var allowPlayers = false
    @State private var query=""
    @State private var competition="all"
    @State private var subjectType="club"
    let competitions=[("all","All"),("champions","Champions League"),("bundesliga","Bundesliga"),("ligamx","Liga MX")]
    private var searching: Bool {!Recall.normalize(query).isEmpty}
    var body: some View {
        List {
            Section {
                if allowPlayers {
                    if typeSize.isAccessibilitySize {subjectPicker.pickerStyle(.menu)}
                    else {subjectPicker.pickerStyle(.segmented)}
                }
                if subjectType == "club" && !searching {
                    Picker("Filter clubs by competition",selection:$competition) {ForEach(competitions,id:\.0) {key,title in Text(title).tag(key)}}
                    if let scope=model.pack?.competitionScopes?[competition] {Text("Participating clubs · "+scope).font(.caption).foregroundStyle(.secondary)}
                }
                if searching && allowPlayers {Text("Matching competitions, clubs and players").font(.caption).foregroundStyle(.secondary)}
            }
            if let pack=model.pack {
                if allowPlayers && !searching {
                    Section("My roadmaps") {
                        ForEach(model.state.savedRoadmaps(pack)) {roadmap in subjectRow(pack.entity(roadmap.entityID),pack:pack,savedRow:true)}
                        if model.state.savedRoadmaps(pack).isEmpty {Text("Save a club, player or competition with its bookmark. Removing a roadmap keeps everything you've learned.").font(.subheadline).foregroundStyle(.secondary)}
                        let unavailable=model.state.unavailableSavedRoadmapCount(pack)
                        if unavailable > 0 {Text("\(unavailable) saved \(unavailable == 1 ? "roadmap is" : "roadmaps are") unavailable in this content version. Your saved choices are preserved.").font(.caption).foregroundStyle(.secondary)}
                    }
                }
                if allowPlayers && !searching && subjectType == "club" {
                    Section("Learn a competition") {ForEach(pack.competitionRoadmaps) {roadmap in subjectRow(pack.entity(roadmap.entityID),pack:pack)}}
                }
                let subjects=matchingSubjects(pack)
                Section(searching ? "\(subjects.count) results" : "\(subjects.count) \(subjectType == "club" ? "club roadmaps" : subjectType == "player" ? "player starters" : "competition courses")") {
                    ForEach(subjects) {subject in subjectRow(subject,pack:pack)}
                    if subjects.isEmpty {Text("No matching roadmaps. Try a different name or nickname.").foregroundStyle(.secondary)}
                }
            }
        }.searchable(text:$query,prompt:allowPlayers ? "Find any roadmap" : "Find a club").navigationTitle(allowPlayers ? "Choose a roadmap" : "Choose a club").toolbar {Button("Done",action:onClose)}
        .animation(reduced ? nil : .easeInOut(duration:0.2),value:subjectType)
        .onAppear {if allowPlayers,let subject=model.pack.flatMap({pack in model.roadmap.map {pack.entity($0.entityID)}}) {subjectType=subject.type}}
    }
    private var subjectPicker: some View {
        Picker("Roadmap subjects",selection:$subjectType) {Text("Clubs").tag("club");Text("Players").tag("player");Text("Competitions").tag("competition")}.accessibilityIdentifier("roadmap-subject-type")
    }
    private func matchingSubjects(_ pack: ContentPack) -> [Entity] {
        let search=Recall.normalize(query)
        return pack.roadmaps.map {pack.entity($0.entityID)}.filter {subject in
            let typeMatches=searching && allowPlayers ? true : subject.type == subjectType
            let scopeMatches=searching || subject.type != "club" || competition == "all" || subject.competitions?.contains(competition) == true
            return typeMatches && scopeMatches && (search.isEmpty || ([subject.name]+subject.aliases).contains {Recall.normalize($0).contains(search)})
        }.sorted {a,b in
            let af=a.type == "club" ? ["entity-xolos","entity-madrid"].contains(a.key) : a.type == "player" && pack.roadmaps.first {$0.entityID == a.id}?.clubID == model.state.selectedClub
            let bf=b.type == "club" ? ["entity-xolos","entity-madrid"].contains(b.key) : b.type == "player" && pack.roadmaps.first {$0.entityID == b.id}?.clubID == model.state.selectedClub
            return af != bf ? af : a.name < b.name
        }
    }
    private func subtitle(_ subject: Entity,pack: ContentPack) -> String {
        guard let roadmap=pack.roadmaps.first(where:{$0.entityID == subject.id}) else {return "Roadmap"}
        if subject.type == "player",let clubID=roadmap.clubID {return "Player starter · "+pack.entity(clubID).name}
        if subject.type == "competition" {
            let progress=RoadmapProgress.make(roadmap:roadmap,pack:pack,state:model.state)
            return "\(progress.completedRequired) of \(progress.requiredLessonIDs.count) foundations · History & format"
        }
        return subject.competitions?.compactMap {key in competitions.first {$0.0 == key}?.1}.joined(separator:" · ") ?? "Favorite club"
    }
    private func subjectRow(_ subject: Entity,pack: ContentPack,savedRow: Bool = false) -> some View {
        HStack(spacing:8) {
            Button {onSelect(subject.id)} label: {
                if typeSize.isAccessibilitySize {
                    VStack(alignment:.leading,spacing:12) {
                        HStack {ClubMark(club:subject,size:42);selectionMark(subject);Spacer()}
                        subjectText(subject,pack:pack,savedRow:savedRow)
                    }.frame(maxWidth:.infinity,alignment:.leading).frame(minHeight:52).contentShape(Rectangle())
                } else {
                    HStack(spacing:14) {ClubMark(club:subject,size:42);subjectText(subject,pack:pack,savedRow:savedRow);Spacer();selectionMark(subject)}.frame(minHeight:52).contentShape(Rectangle())
                }
            }.buttonStyle(PressFeedback()).disabled(subject.id == excludedClubID).accessibilityHint(subject.id == excludedClubID ? "Already selected as the other club" : "Choose this roadmap").accessibilityIdentifier("\(savedRow ? "saved" : "club")-\(subject.key)")
            if allowPlayers,let roadmap=pack.roadmaps.first(where:{$0.entityID == subject.id}) {RoadmapSaveButton(roadmap:roadmap,identifierPrefix:savedRow ? "saved-toggle" : "toggle")}
        }
    }
    private func subjectText(_ subject: Entity,pack: ContentPack,savedRow: Bool) -> some View {
        VStack(alignment:.leading,spacing:5) {Text(subject.name).font(.headline);Text(savedRow ? savedProgress(subject,pack:pack) : subtitle(subject,pack:pack)).font(.caption).foregroundStyle(.secondary)}
    }
    @ViewBuilder private func selectionMark(_ subject: Entity) -> some View {
        if (selectedClubID ?? (allowPlayers ? model.roadmap?.entityID : model.state.selectedClub)) == subject.id {Image(systemName:"checkmark.circle.fill").font(.system(size:20)).accessibilityLabel("Selected")}
    }
    private func savedProgress(_ subject: Entity,pack: ContentPack) -> String {
        guard let roadmap=pack.roadmaps.first(where:{$0.entityID == subject.id}) else {return ""}
        let progress=RoadmapProgress.make(roadmap:roadmap,pack:pack,state:model.state)
        return "\(progress.completedRequired) of \(progress.requiredLessonIDs.count) lessons"
    }
}

struct RoadmapSaveButton: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduced
    let roadmap: Roadmap
    var showsTitle=false
    var identifierPrefix="toggle"
    private var saved: Bool {model.state.savedRoadmaps(model.pack!).contains {$0.id == roadmap.id}}
    var body: some View {
        Button {model.setRoadmapSaved(roadmap,saved:!saved)} label: {
            HStack(spacing:8) {
                Image(systemName:saved ? "bookmark.fill" : "bookmark").font(.system(size:20)).contentTransition(.opacity)
                if showsTitle {Text(saved ? "Saved" : "Save roadmap").font(.subheadline.bold())}
            }.frame(minWidth:44,minHeight:44).contentShape(Rectangle())
        }.buttonStyle(PressFeedback()).foregroundStyle(Palette.brand)
        .animation(reduced ? nil : .easeInOut(duration:0.2),value:saved)
        .accessibilityLabel("\(saved ? "Remove" : "Save") \(model.pack!.entity(roadmap.entityID).name) \(saved ? "from" : "to") My roadmaps")
        .accessibilityValue(saved ? "Saved" : "Not saved")
        .accessibilityHint(saved ? "Your lessons, reviews and cards will be preserved" : "Saving does not change your selected roadmap")
        .accessibilityIdentifier("\(identifierPrefix)-\(roadmap.key)")
    }
}
