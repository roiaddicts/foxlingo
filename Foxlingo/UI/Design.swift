import SwiftUI

enum Palette {
    static let paper = Color(red:244/255,green:247/255,blue:251/255)
    static let ink = brand
    static let brand = Color(.sRGB,red:0,green:45/255,blue:86/255,opacity:1)
    static let muted = Color(red:86/255,green:103/255,blue:122/255)
    static let ochre = Color(red:0.87,green:0.65,blue:0.25)
    static let red = Color(red:0.68,green:0.19,blue:0.18)
}
struct PrimaryButton: View {
    let title: String
    var symbol = "arrow.right"
    var action: () -> Void
    var body: some View {
        Button(action:action) { HStack { Text(title).font(.headline); Spacer(); Image(systemName:symbol) }.padding(18).foregroundStyle(.white).background(Palette.brand,in:RoundedRectangle(cornerRadius:18)) }
            .buttonStyle(PressFeedback()).frame(minHeight:52)
    }
}
struct Leopard: View {
    var pose = "welcome"
    @Environment(\.accessibilityReduceMotion) var reduced
    @State private var appeared = false
    var body: some View {
        Image("Leopard").resizable().scaledToFit()
            .rotationEffect(.degrees(reduced ? 0 : (pose == "celebrate" ? -8 : pose == "encourage" ? 5 : 0)))
            .scaleEffect(appeared || reduced ? 1 : 0.94)
            .onAppear { withAnimation(reduced ? nil : .spring(response:0.45,dampingFraction:0.7)) { appeared = true } }
            .accessibilityLabel("Your leopard companion")
    }
}
struct ClubMark: View {
    let club: Entity
    var size: CGFloat = 64
    var body: some View {
        EntityArtwork(asset:club.imageAsset,url:club.imageURL,initials:club.visual,size:size,isPlayer:club.type == "player")
            .accessibilityHidden(true)
    }
}
/// Club identity artwork stays separate from season kits and source memberships.
struct ClubBadgeArtwork: View {
    let name: String
    var size: CGFloat = 58
    @EnvironmentObject private var model: AppModel
    private static let assets: [String:String] = [
        "chelsea":"entity-chelsea","tottenham":"entity-tottenham",
        "atl madrid":"entity-atletico-madrid","dortmund":"entity-borussia-dortmund",
        "bayer leverkusen":"entity-bayer-leverkusen","psg":"entity-psg",
        "frankfurt":"entity-eintracht-frankfurt","bayern munich":"entity-bayern-munich",
        "rb leipzig":"entity-leipzig",
        "ajax":"club-badge-ajax","benfica":"club-badge-benfica",
        "newcastle":"club-badge-newcastle","leicester":"club-badge-leicester",
        "wolves":"club-badge-wolves","everton":"club-badge-everton",
        "west ham":"club-badge-west-ham","brighton":"club-badge-brighton",
        "athletic club":"club-badge-athletic-club","real sociedad":"club-badge-real-sociedad",
        "sevilla":"club-badge-sevilla","girona":"club-badge-girona",
        "valencia":"club-badge-valencia","atalanta":"club-badge-atalanta",
        "lazio":"club-badge-lazio","bologna":"club-badge-bologna",
        "fiorentina":"club-badge-fiorentina","monaco":"club-badge-monaco","lyon":"club-badge-lyon"
    ]
    var body: some View {
        let club=model.pack.flatMap {AnswerArtwork.entity(name,type:"club",pack:$0)}
        EntityArtwork(asset:Self.assets[Recall.normalize(name)] ?? club?.imageAsset,url:club?.imageURL,initials:String(name.prefix(2)),size:size)
            .accessibilityLabel(name)
    }
}
struct Eyebrow: View {
    let text: String
    var body: some View { Text(text.uppercased()).font(.caption.weight(.bold)).tracking(2).foregroundStyle(Palette.muted) }
}
struct PageBackground: ViewModifier {
    func body(content: Content) -> some View { content.background(Palette.paper.ignoresSafeArea()).foregroundStyle(Palette.ink) }
}
extension View { func journal() -> some View { modifier(PageBackground()) } }


struct EntityArtwork: View {
    let asset: String?
    let url: String?
    let initials: String
    var size: CGFloat = 64
    var isPlayer = false
    var portraitFocus = false
    var body: some View {
        Group {
            if let asset, let image=UIImage(named:asset) {
                if asset == "entity-competition-bundesliga" {
                    // Frame the red emblem from the original wide federation lockup.
                    Image(uiImage:image).resizable()
                        .frame(width:size*1024/135,height:size*1024/135)
                        .offset(x:size*(512-87.5)/135)
                        .frame(width:size,height:size).clipped()
                } else {
                    Image(uiImage:image).resizable().scaledToFit()
                        .scaleEffect(portraitFocus && ["entity-riascos","entity-arce","entity-saucedo"].contains(asset) ? 2.1 : asset == "entity-competition-champions-league" ? 1.35 : 1)
                        .offset(y:portraitFocus && ["entity-riascos","entity-arce","entity-saucedo"].contains(asset) ? size*0.55 : 0)
                }
            } else if let url, let remote=URL(string:url), remote.scheme == "https" {
                AsyncImage(url:remote) { phase in
                    if let image=phase.image { image.resizable().scaledToFit() } else { fallback }
                }
            } else {fallback}
        }.frame(width:size,height:size)
            .background(isPlayer ? Color.white.opacity(0.65) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius:isPlayer ? size*0.22 : 0))
    }
    private var fallback: some View {
        Text(initials).font(.system(size:size*0.3,weight:.black,design:.rounded)).foregroundStyle(Palette.ink)
            .frame(width:size,height:size).background(Palette.ochre.opacity(0.18),in:RoundedRectangle(cornerRadius:size*0.22))
    }
}

struct PressFeedback: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduced
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed && !reduced ? 0.97 : 1)
            .animation(reduced ? nil : .spring(response:0.25,dampingFraction:0.8),value:configuration.isPressed)
    }
}
struct GameCategoryMark: View {
    let category: GameCategory
    var size: CGFloat = 42
    var body: some View {
        Group {
            if let flag=category.flag, category.imageAsset == nil {Text(flag).font(.system(size:size*0.8)).frame(width:size,height:size)}
            else {EntityArtwork(asset:category.imageAsset,url:category.imageURL,initials:"⚽",size:size)}
        }.accessibilityElement(children:.ignore).accessibilityLabel(category.title)
    }
}

/// Only explicit semantic types can opt into visual answers: a city named
/// Monterrey must never turn into the football club’s badge.
struct KnowledgeAnswer: View {
    let text: String
    var expectedType: String? = nil
    var visualSize: CGFloat = 56
    @EnvironmentObject private var model: AppModel
    var body: some View {
        Group {
            if expectedType == "country", let flag=AnswerArtwork.flags[Recall.normalize(text)] {Image(flag).resizable().scaledToFit().frame(width:visualSize,height:visualSize*5/7)}
            else if let expectedType, let pack=model.pack, let entity=AnswerArtwork.entity(text,type:expectedType,pack:pack) {ClubMark(club:entity,size:visualSize)}
            else {Text(text)}
        }.accessibilityElement(children:.ignore).accessibilityLabel(text)
    }
}
