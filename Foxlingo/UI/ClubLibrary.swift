import SwiftUI

struct ClubLibrary: View {
    @EnvironmentObject var model: AppModel
    let onSelect: (UUID) -> Void
    let onClose: () -> Void
    var excludedClubID: UUID? = nil
    var selectedClubID: UUID? = nil
    var allowPlayers = false
    @State private var query=""
    @State private var competition="all"
    @State private var subjectType="club"
    let competitions=[("all","All"),("champions","Champions League"),("bundesliga","Bundesliga"),("ligamx","Liga MX")]
    var body: some View {
        List {
            Section {
                if allowPlayers {Picker("Roadmap subjects",selection:$subjectType) {Text("Clubs").tag("club");Text("Players").tag("player")}.pickerStyle(.segmented).accessibilityIdentifier("roadmap-subject-type")}
                if subjectType == "club" {Picker("Competition",selection:$competition) {ForEach(competitions,id:\.0) {key,title in Text(title).tag(key)}}}
                if subjectType == "club",let scope=model.pack?.competitionScopes?[competition] {Text(scope).font(.caption).foregroundStyle(.secondary)}
            }
            if let pack=model.pack {
                let clubs=pack.roadmaps.map{pack.entity($0.entityID)}.filter{$0.type == subjectType && (subjectType == "player" || competition == "all" || $0.competitions?.contains(competition) == true) && (query.isEmpty || Recall.normalize($0.name).contains(Recall.normalize(query)) || $0.aliases.contains{Recall.normalize($0).contains(Recall.normalize(query))})}.sorted {a,b in
                    let af=subjectType == "club" ? ["entity-xolos","entity-madrid"].contains(a.key) : pack.roadmaps.first {$0.entityID == a.id}?.clubID == model.state.selectedClub
                    let bf=subjectType == "club" ? ["entity-xolos","entity-madrid"].contains(b.key) : pack.roadmaps.first {$0.entityID == b.id}?.clubID == model.state.selectedClub
                    return af != bf ? af : a.name < b.name
                }
                Section("\(clubs.count) \(subjectType == "club" ? "club roadmaps" : "player starters")") {
                    ForEach(clubs) {club in
                        Button {onSelect(club.id)} label: {
                            HStack(spacing:14) {ClubMark(club:club,size:42);VStack(alignment:.leading,spacing:5) {Text(club.name).font(.headline);Text(club.type == "player" ? "Player starter · \(pack.entity(pack.roadmaps.first {$0.entityID == club.id}!.clubID).name)" : club.competitions?.compactMap{key in competitions.first{$0.0 == key}?.1}.joined(separator:" · ") ?? "Favorite club").font(.caption).foregroundStyle(.secondary)};Spacer();if (selectedClubID ?? (allowPlayers ? model.roadmap?.entityID : model.state.selectedClub)) == club.id {Image(systemName:"checkmark.circle.fill")}}.contentShape(Rectangle())
                        }.buttonStyle(PressFeedback()).disabled(club.id == excludedClubID).accessibilityHint(club.id == excludedClubID ? "Already selected as the other club" : "Choose this roadmap").accessibilityIdentifier("club-\(club.key)")
                    }
                }
            }
        }.searchable(text:$query,prompt:allowPlayers ? "Find a club or player" : "Find a club").navigationTitle(allowPlayers ? "Choose a roadmap" : "Choose a club").toolbar {Button("Done",action:onClose)}
    }
}
