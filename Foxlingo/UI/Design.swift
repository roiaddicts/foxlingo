import SwiftUI

enum Palette {
    static let paper = Color(red:0.97,green:0.95,blue:0.89)
    static let ink = Color(red:0.12,green:0.18,blue:0.15)
    static let green = Color(red:0.13,green:0.36,blue:0.27)
    static let muted = Color(red:0.36,green:0.39,blue:0.34)
    static let ochre = Color(red:0.87,green:0.65,blue:0.25)
    static let red = Color(red:0.68,green:0.19,blue:0.18)
}
struct PrimaryButton: View {
    let title: String
    var symbol = "arrow.right"
    var action: () -> Void
    var body: some View {
        Button(action:action) { HStack { Text(title).font(.headline); Spacer(); Image(systemName:symbol) }.padding(18).foregroundStyle(.white).background(Palette.green,in:RoundedRectangle(cornerRadius:18)) }
            .buttonStyle(.plain).frame(minHeight:52)
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
    var body: some View {
        Group {
            if let asset, let image=UIImage(named:asset) {
                Image(uiImage:image).resizable().scaledToFit()
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
