import SwiftUI

struct AlbumView: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        ScrollView {
            LazyVStack(alignment:.leading,spacing:24) {
                Eyebrow(text:"A collection of connections")
                Text("Your album").font(.system(.largeTitle,design:.rounded,weight:.black))
                Text("\(model.state.acquiredCards.count) of \(model.pack?.cards.count ?? 0) discovered").foregroundStyle(Palette.muted)
                if let p=model.pack {
                    ForEach(p.roadmaps) { r in
                        let lessonSet=Set(r.chapters.flatMap(\.lessonIDs))
                        let cards=p.cards.filter{!lessonSet.isDisjoint(with:Set($0.lessonIDs))}
                        HStack {ClubMark(club:p.entity(r.clubID),size:34);Text(p.entity(r.clubID).name).font(.title2.bold())}
                        LazyVGrid(columns:[GridItem(.adaptive(minimum:145),spacing:14)],spacing:14) {
                            ForEach(cards) { card in NavigationLink {CardDetail(card:card)} label:{Collectible(card:card,pack:p,tier:model.state.tier(card))}.buttonStyle(.plain).accessibilityIdentifier(card.key) }
                        }
                    }
                }
                Text("Discover a subject to unlock its card. Remember its knowledge over time to earn diamond.").font(.footnote).foregroundStyle(Palette.muted)
            }.padding(24)
        }.journal().navigationBarTitleDisplayMode(.inline)
    }
}
struct Collectible: View {
    let card: AlbumCard
    let pack: ContentPack
    let tier: Int
    var body: some View {
        let entity=pack.entity(card.entityID)
        VStack(alignment:.leading,spacing:14) {
            HStack {Text(tier < 0 ? "UNDISCOVERED" : LearnerState.tierNames[tier].uppercased()).font(.system(size:10,weight:.bold)).tracking(1);Spacer();Image(systemName:tier < 0 ? "lock.fill" : tier == 4 ? "diamond.fill" : "sparkle")}
            ZStack {Circle().stroke(Palette.ink.opacity(0.12),lineWidth:1).frame(width:86,height:86);EntityArtwork(asset:entity.imageAsset,url:entity.imageURL,initials:entity.visual,size:86,isPlayer:entity.type == "player")}.frame(maxWidth:.infinity,minHeight:105)
            Text(entity.name).font(.headline).frame(maxWidth:.infinity,alignment:.leading)
            Text(card.caption).font(.caption).foregroundStyle(Palette.muted)
        }.padding(16).frame(maxWidth:.infinity,alignment:.leading).background(tier < 0 ? Color.white.opacity(0.35) : tier == 0 ? Color(red:0.87,green:0.8,blue:0.67) : tier == 1 ? Color(red:0.86,green:0.72,blue:0.55) : tier == 2 ? Color(red:0.84,green:0.87,blue:0.87) : tier == 3 ? Palette.ochre.opacity(0.5) : Color(red:0.78,green:0.91,blue:0.89),in:RoundedRectangle(cornerRadius:18))
        .overlay {RoundedRectangle(cornerRadius:18).stroke(Palette.ink.opacity(tier < 0 ? 0.08 : 0.2),lineWidth:1)}
        .accessibilityElement(children:.combine)
    }
}
struct CardDetail: View {
    let card: AlbumCard
    @EnvironmentObject var model: AppModel
    @State private var lesson: Lesson?
    var body: some View {
        ScrollView {
            if let p=model.pack {
                let tier=model.state.tier(card)
                VStack(alignment:.leading,spacing:22) {
                    Collectible(card:card,pack:p,tier:tier).frame(maxWidth:260).frame(maxWidth:.infinity)
                    Text(tier < 0 ? "Discover this story" : "Your knowledge set").font(.title2.bold())
                    Text("\(card.objectiveIDs.filter{model.state.reviews[$0] != nil}.count) of \(card.objectiveIDs.count) connections learned · Set version \(card.knowledgeVersion)").foregroundStyle(Palette.muted)
                    ForEach(card.objectiveIDs,id:\.self) { id in
                        let o=p.objective(id), r=model.state.reviews[id]
                        HStack(alignment:.top) {Image(systemName:r == nil ? "circle" : "checkmark.circle.fill").foregroundStyle(Palette.green);VStack(alignment:.leading,spacing:5) {Text(o.prompt).font(.subheadline);if let r {Text("Recall stage \(r.stage) · Next \(r.due.formatted(date:.abbreviated,time:.omitted))").font(.caption).foregroundStyle(Palette.muted)}else{Text("Not learned yet").font(.caption).foregroundStyle(Palette.muted)}}}
                    }
                    let related=card.lessonIDs.map(p.lesson)
                    ForEach(related) { l in Button {lesson=l} label:{Label(l.title,systemImage:"book.fill").font(.headline).frame(minHeight:44)}.accessibilityIdentifier("card-open-\(l.key)") }
                    if tier >= 0 {
                        let learned=card.objectiveIDs.compactMap{id -> Objective? in model.state.reviews[id] == nil ? nil : p.objective(id)}
                        if !learned.isEmpty {NavigationLink {PracticeSession(objectives:learned,dueMode:true)} label:{Label("Practice these connections",systemImage:"arrow.clockwise").font(.headline)}}
                    }
                    Text("Earned tiers stay with you. Current recall can change, and due practice helps you refresh it. Diamond covers this defined set, not every fact about the subject.").font(.footnote).foregroundStyle(Palette.muted)
                }.padding(24)
            }
        }.journal().navigationTitle(model.pack?.entity(card.entityID).name ?? "Card").navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item:$lesson){ l in NavigationStack {LessonView(lesson:l)} }
    }
}
struct SettingsView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) var dismiss
    @State private var confirmReset=false
    var body: some View {
        Form {
            Section("Your experience") {
                Toggle("Sound",isOn:$model.state.sound).onChange(of:model.state.sound){model.save()}
                Toggle("Haptics",isOn:$model.state.haptics).onChange(of:model.state.haptics){model.save()}
                Text("English · Offline starter edition").foregroundStyle(.secondary)
            }
            Section("Streaks") {
                Text("Complete a lesson or practice session to count an active day. One freeze protects one missed day between active days, without counting it as practice. Earn another freeze after seven active days, up to one at a time.")
                LabeledContent("Home time zone",value:model.state.homeTimeZone)
                LabeledContent("Available freeze",value:"\(model.state.streak.freezes)")
                LabeledContent("Longest active streak",value:"\(model.state.streak.longest) days")
                Text("Your home time zone stays fixed while you travel.").font(.caption)
            }
            Section("Album tiers") {
                Text("Cards unlock when you complete a related lesson. Bronze, silver, gold, and diamond require independent recall when reviews are due, across every connection in the card’s set. A clean sequence reaches diamond after about 25 days.")
            }
            Section("Content & sources") {
                Text("Club lessons checked October 8, 2026. Competition membership is a dated snapshot. Game relationships come from the supplied historical Futbol11 seed. Each lesson includes source links and context.")
                if let p=model.pack {ForEach(p.sources) {s in if let url=URL(string:s.url){Link(s.title,destination:url)}}}
            }
            Section("Progress") {
                Button("Reset all progress",role:.destructive){confirmReset=true}.accessibilityIdentifier("reset-progress")
                Text("A reset starts a new collection. A copy of your old progress stays archived on this device.").font(.caption)
            }
        }.navigationTitle("Settings").toolbar {Button("Done"){dismiss()}}
        .confirmationDialog("Reset lessons, cards, reviews, and streaks?",isPresented:$confirmReset,titleVisibility:.visible){Button("Reset all progress",role:.destructive){model.reset();dismiss()}}message:{Text("This starts over. Your previous save will be archived on the device.")}
    }
}
