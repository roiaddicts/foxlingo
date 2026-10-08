import SwiftUI

private enum GraphLens: String, CaseIterable, Identifiable {
    case football, all, history, events, places, origins
    var id: String {rawValue}
    var title: String {switch self {case .football:"Football links";case .all:"All relationships";case .history:"Club history";case .events:"Matches & moments";case .places:"Cities & venues";case .origins:"Countries"}}
    var groups: Set<GraphGroup> {switch self {case .football:[.history,.events];case .all:Set(GraphGroup.allCases);case .history:[.history];case .events:[.events];case .places:[.places];case .origins:[.origins]}}
}
private enum GraphSelection: String, Identifiable {case focus,start,end;var id:String {rawValue}}

struct ExplorerView: View {
    var initialID: UUID? = nil
    @EnvironmentObject private var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduced
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var focusID: UUID?
    @State private var startID: UUID?
    @State private var endID: UUID?
    @State private var selecting: GraphSelection?
    @State private var lens: GraphLens = .football
    @State private var inspecting: GraphEdge?
    var body: some View {
        ScrollView {
            if let pack=model.pack,let focus=focusID ?? initialID ?? pack.entities.first(where:{$0.key == "entity-madrid"})?.id ?? pack.entities.first?.id {
                let graph=KnowledgeGraph(pack:pack),entity=pack.entity(focus),nearby=graph.neighbors(of:focus,groups:lens.groups)
                VStack(alignment:.leading,spacing:24) {
                    if typeSize.isAccessibilitySize {
                        VStack(alignment:.leading,spacing:12) {
                            Text("Connections").font(.title2.bold())
                            Button {selecting = .focus} label:{Label("Find subject",systemImage:"magnifyingglass").font(.subheadline).frame(minHeight:44)}.accessibilityIdentifier("graph-find")
                        }
                    } else {
                        HStack {Text("Connections").font(.largeTitle.bold());Spacer();Button {selecting = .focus} label:{Image(systemName:"magnifyingglass").frame(width:44,height:44)}.accessibilityLabel("Find a subject").accessibilityIdentifier("graph-find")}
                    }
                    Picker("Relationships",selection:$lens) {ForEach(GraphLens.allCases) {Text($0.title).tag($0)}}.pickerStyle(.menu).accessibilityIdentifier("graph-filter")
                    if !typeSize.isAccessibilitySize && !nearby.isEmpty {
                        NeighborhoodMap(focus:entity,neighbors:nearby,pack:pack,choose:{id in withAnimation(reduced ? nil : .easeInOut(duration:0.2)) {focusID=id}})
                    } else {GraphEntityLabel(entity:entity,size:72).font(.title2.bold()).accessibilityIdentifier("graph-focus")}
                    Text("\(nearby.count) supported \(nearby.count == 1 ? "link" : "links") · \(lens.title)").font(.subheadline).foregroundStyle(Palette.muted).accessibilityIdentifier("graph-neighbor-count")
                    if nearby.isEmpty {Text("No links for this filter in this library. Try another relationship or subject.").font(.subheadline).foregroundStyle(Palette.muted)}
                    ForEach(nearby) {edge in
                        let other=pack.entity(edge.other(focus)!)
                        HStack(spacing:12) {
                            Button {withAnimation(reduced ? nil : .easeInOut(duration:0.2)) {focusID=other.id}} label:{HStack(spacing:12) {GraphEntityLabel(entity:other,size:44);Spacer()}.frame(minHeight:52).contentShape(Rectangle())}.buttonStyle(PressFeedback()).accessibilityIdentifier("graph-neighbor-\(other.key)-\(edge.id)")
                            Button {inspecting=edge} label:{Image(systemName:"info.circle").frame(width:44,height:44)}.accessibilityLabel("Explain \(edge.label), \(other.name)").accessibilityIdentifier("graph-edge-\(edge.id)")
                        }
                        Text(edge.label + " · " + edge.scope).font(.caption).foregroundStyle(Palette.muted)
                        Divider()
                    }
                    pathFinder(pack:pack,graph:graph)
                    let facts=pack.facts.filter {$0.subjectID == focus}
                    if !facts.isEmpty {
                        Text("Facts about \(entity.name)").font(.title2.bold())
                        ForEach(facts) {fact in DisclosureGroup {
                            Text(fact.evidence).font(.subheadline)
                            Text(fact.scope).font(.caption).foregroundStyle(Palette.muted)
                            GraphSources(factIDs:[fact.id],pack:pack)
                        } label:{KnowledgeAnswer(text:fact.value.display,expectedType:fact.predicate == "country" || fact.predicate.hasSuffix("-country") ? "country" : fact.value.entityID.map {pack.entity($0).type}).font(.headline)}.accessibilityIdentifier("graph-fact-\(fact.key)")}
                    }
                    Text("Links reflect this sourced library. Shared club history does not establish that players were teammates. Exploration earns no recall credit.").font(.footnote).foregroundStyle(Palette.muted)
                }.padding(24)
            }
        }.journal().navigationTitle("Explorer").navigationBarTitleDisplayMode(.inline)
        .sheet(item:$selecting) {selection in if let pack=model.pack {NavigationStack {GraphSubjectPicker(pack:pack) {id in
            switch selection {case .focus:focusID=id;case .start:startID=id;case .end:endID=id};selecting=nil
        }}}}
        .sheet(item:$inspecting) {edge in if let pack=model.pack {NavigationStack {GraphEdgeDetail(edge:edge,pack:pack)}}}
        .animation(reduced ? nil : .easeInOut(duration:0.2),value:lens)
    }
    private func pathFinder(pack: ContentPack,graph: KnowledgeGraph) -> some View {
        let first=startID ?? initialID ?? pack.entities.first(where:{$0.key == "entity-madrid"})?.id ?? pack.entities[0].id
        let second=endID ?? pack.entities.first(where:{$0.key == "entity-ramos"})?.id ?? first
        return VStack(alignment:.leading,spacing:18) {
            Text("Find the closest connection").font(.title2.bold())
            VStack(spacing:12) {
                Button {selecting = .start} label:{HStack {Text("From").font(.caption);GraphEntityLabel(entity:pack.entity(first),size:44);Spacer();Image(systemName:"chevron.down")}.frame(minHeight:52).contentShape(Rectangle())}.buttonStyle(PressFeedback()).accessibilityIdentifier("graph-path-from")
                Button {selecting = .end} label:{HStack {Text("To").font(.caption);GraphEntityLabel(entity:pack.entity(second),size:44);Spacer();Image(systemName:"chevron.down")}.frame(minHeight:52).contentShape(Rectangle())}.buttonStyle(PressFeedback()).accessibilityIdentifier("graph-path-to")
            }
            if let path=graph.shortestPath(from:first,to:second,groups:lens.groups) {
                if path.isEmpty {Text("Same subject · 0 links").font(.headline).accessibilityIdentifier("graph-path-result")}
                else {
                    Text("\(path.count) \(path.count == 1 ? "link" : "links") · shortest supported path").font(.headline).accessibilityIdentifier("graph-path-result")
                    ScrollView(.horizontal) {HStack(spacing:14) {
                        GraphEntityLabel(entity:pack.entity(first),size:48,vertical:true)
                        ForEach(path) {step in Image(systemName:"arrow.right").foregroundStyle(Palette.green);GraphEntityLabel(entity:pack.entity(step.toID),size:48,vertical:true)}
                    }.padding(.vertical,8)}
                    ForEach(Array(path.enumerated()),id:\.element.id) {index,step in
                        Button {inspecting=step.edge} label:{VStack(alignment:.leading,spacing:8) {
                            Label("Step \(index+1) · \(step.edge.label)",systemImage:"info.circle").font(.headline)
                            Text(step.edge.claim).font(.subheadline)
                            Text(step.edge.scope).font(.caption).foregroundStyle(Palette.muted)
                        }.frame(maxWidth:.infinity,alignment:.leading).padding(.vertical,8).contentShape(Rectangle())}.buttonStyle(PressFeedback()).accessibilityIdentifier("graph-path-step-\(index)")
                    }
                }
            } else {Text("No supported path in this library for \(lens.title.lowercased()). Try another filter or subject.").font(.subheadline).foregroundStyle(Palette.muted).accessibilityIdentifier("graph-path-result")}
        }
    }
}

private struct GraphEntityLabel: View {
    let entity: Entity
    var size: CGFloat = 52
    var vertical = false
    var body: some View {
        Group {
            if vertical {VStack(spacing:6) {art;Text(entity.name).font(.caption.bold()).multilineTextAlignment(.center).frame(width:104).fixedSize(horizontal:false,vertical:true).background(Palette.paper)}.frame(width:110)}
            else {HStack(spacing:12) {art;Text(entity.name).font(.subheadline.bold())}}
        }.accessibilityElement(children:.ignore).accessibilityLabel(entity.name)
    }
    @ViewBuilder private var art: some View {
        if entity.type == "country",let flag=AnswerArtwork.flags[Recall.normalize(entity.name)] {Image(flag).resizable().scaledToFit().frame(width:size,height:size)}
        else if ["match","tie","goal","city","venue"].contains(entity.type) {Image(systemName:entity.type == "goal" ? "soccerball" : entity.type == "city" ? "building.2" : entity.type == "venue" ? "sportscourt" : "flag.checkered").font(.system(size:size*0.5)).frame(width:size,height:size).foregroundStyle(Palette.green).background(.white.opacity(0.7),in:Circle())}
        else {ClubMark(club:entity,size:size)}
    }
}
private struct NeighborhoodMap: View {
    let focus: Entity
    let neighbors: [GraphEdge]
    let pack: ContentPack
    let choose: (UUID) -> Void
    private var ids:[UUID] {Array(Array(Set(neighbors.compactMap {$0.other(focus.id)})).sorted {pack.entity($0).name < pack.entity($1).name}.prefix(6))}
    var body: some View {
        GeometryReader {geo in
            let center=CGPoint(x:geo.size.width/2,y:180)
            ZStack {
                Canvas {context,_ in
                    for index in ids.indices {var line=Path();line.move(to:center);line.addLine(to:position(index,width:geo.size.width));context.stroke(line,with:.color(Palette.green.opacity(0.25)),lineWidth:1.5)}
                }.accessibilityHidden(true)
                GraphEntityLabel(entity:focus,size:62,vertical:true).position(center).accessibilityIdentifier("graph-focus")
                ForEach(Array(ids.enumerated()),id:\.element) {index,id in
                    Button {choose(id)} label:{GraphEntityLabel(entity:pack.entity(id),size:44,vertical:true).frame(minHeight:86).contentShape(Rectangle())}.buttonStyle(PressFeedback()).position(position(index,width:geo.size.width)).accessibilityIdentifier("graph-node-\(pack.entity(id).key)")
                }
            }
        }.frame(height:360)
        .overlay(alignment:.bottom) {if Set(neighbors.compactMap {$0.other(focus.id)}).count > 6 {Text("More links below").font(.caption).foregroundStyle(Palette.muted)}}
    }
    private func position(_ index:Int,width:CGFloat) -> CGPoint {
        let count=ids.count,angle=Double(index)*2*Double.pi/Double(count)-Double.pi/2
        return CGPoint(x:width/2+cos(angle)*max(0,(width-110)/2),y:180+sin(angle)*132)
    }
}
private struct GraphSubjectPicker: View {
    let pack: ContentPack
    let select: (UUID) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var query=""
    var body: some View {
        List {
            ForEach(pack.entities.filter {query.isEmpty || ([$0.name]+$0.aliases).contains {Recall.normalize($0).contains(Recall.normalize(query))}}.sorted {$0.name < $1.name}) {entity in
                Button {select(entity.id)} label:{HStack {GraphEntityLabel(entity:entity,size:40);Spacer();Text(entity.type.capitalized).font(.caption).foregroundStyle(Palette.muted)}.frame(minHeight:48).contentShape(Rectangle())}.buttonStyle(.plain).accessibilityIdentifier("graph-select-\(entity.key)")
            }
        }.searchable(text:$query,prompt:"Find a player, club, or moment").navigationTitle("Choose a subject").toolbar {Button("Done") {dismiss()}}
    }
}
private struct GraphEdgeDetail: View {
    let edge: GraphEdge
    let pack: ContentPack
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ScrollView {VStack(alignment:.leading,spacing:22) {
            GraphEntityLabel(entity:pack.entity(edge.subjectID),size:64)
            Label(edge.label,systemImage:"arrow.down").font(.headline)
            GraphEntityLabel(entity:pack.entity(edge.objectID),size:64)
            Text(edge.claim).font(.title3.bold()).accessibilityIdentifier("graph-edge-claim")
            Text(edge.scope).foregroundStyle(Palette.muted)
            Text("Evidence & sources").font(.headline)
            ForEach(edge.factIDs,id:\.self) {id in if let fact=pack.facts.first(where:{$0.id == id}) {Text(fact.evidence).font(.subheadline);Text(fact.scope).font(.caption).foregroundStyle(Palette.muted)}}
            GraphSources(factIDs:edge.factIDs,pack:pack)
        }.padding(24)}.journal().navigationTitle("Connection").navigationBarTitleDisplayMode(.inline).toolbar {Button("Done") {dismiss()}.accessibilityIdentifier("graph-edge-done")}
    }
}
private struct GraphSources: View {
    let factIDs:[UUID]
    let pack:ContentPack
    var body:some View {
        let keys=Set(pack.facts.filter {factIDs.contains($0.id)}.flatMap(\.sourceKeys))
        ForEach(pack.sources.filter {keys.contains($0.key)}) {source in if let url=URL(string:source.url) {Link(source.title,destination:url).font(.subheadline);Text("Checked \(source.verifiedAt)").font(.caption).foregroundStyle(Palette.muted)}}
    }
}
