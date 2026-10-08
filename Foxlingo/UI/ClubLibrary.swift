import SwiftUI

struct ClubLibrary: View {
    @EnvironmentObject var model: AppModel
    let onSelect: (UUID) -> Void
    let onClose: () -> Void
    @State private var query=""
    @State private var competition="all"
    let competitions=[("all","All"),("champions","Champions League"),("bundesliga","Bundesliga"),("ligamx","Liga MX")]
    var body: some View {
        List {
            Section {
                Picker("Competition",selection:$competition) {ForEach(competitions,id:\.0) {key,title in Text(title).tag(key)}}
                if let scope=model.pack?.competitionScopes?[competition] {Text(scope).font(.caption).foregroundStyle(.secondary)}
            }
            if let pack=model.pack {
                let clubs=pack.roadmaps.map{pack.entity($0.clubID)}.filter{(competition == "all" || $0.competitions?.contains(competition) == true) && (query.isEmpty || Recall.normalize($0.name).contains(Recall.normalize(query)) || $0.aliases.contains{Recall.normalize($0).contains(Recall.normalize(query))})}.sorted {a,b in
                    let af=["entity-xolos","entity-madrid"].contains(a.key), bf=["entity-xolos","entity-madrid"].contains(b.key)
                    return af != bf ? af : a.name < b.name
                }
                Section("\(clubs.count) club roadmaps") {
                    ForEach(clubs) {club in
                        Button {onSelect(club.id)} label: {
                            HStack(spacing:14) {ClubMark(club:club,size:42);VStack(alignment:.leading,spacing:5) {Text(club.name).font(.headline);Text(club.competitions?.compactMap{key in competitions.first{$0.0 == key}?.1}.joined(separator:" · ") ?? "Favorite club").font(.caption).foregroundStyle(.secondary)};Spacer();if model.state.selectedClub == club.id {Image(systemName:"checkmark.circle.fill")}}.contentShape(Rectangle())
                        }.buttonStyle(.plain).accessibilityIdentifier("club-\(club.key)")
                    }
                }
            }
        }.searchable(text:$query,prompt:"Find a club").navigationTitle("Choose a club").toolbar {Button("Done",action:onClose)}
    }
}
