import SwiftUI

struct SoundAssetsView: View {
    @EnvironmentObject private var model: AppModel
    var body: some View {
        List {
            Section {
                Toggle("Sound",isOn:$model.state.sound).onChange(of:model.state.sound) {if !model.state.sound {model.stopSounds()};model.save()}.accessibilityIdentifier("sound-assets-toggle")
                Text("Feedback respects Silent Mode. Your music keeps playing. Previews play the full clip; in-game cues stay brief.").font(.footnote).foregroundStyle(.secondary)
                if let status=model.audioPreviewStatus {Text(status).font(.subheadline).accessibilityIdentifier("sound-preview-status")}
            }
            Section("Sound library") {
                ForEach(SoundAsset.allCases) {asset in
                    Button {model.previewSound(asset)} label: {
                        HStack(spacing:14) {Image(systemName:"play.circle.fill").font(.title2).foregroundStyle(Palette.brand);VStack(alignment:.leading,spacing:4) {Text(asset.title).foregroundStyle(Palette.ink);Text(asset.usage).font(.caption).foregroundStyle(Palette.muted)};Spacer()}.padding(.vertical,4)
                    }.disabled(!model.state.sound).accessibilityLabel("Preview \(asset.title)").accessibilityIdentifier("sound-preview-\(asset.rawValue)")
                }
            }
        }.navigationTitle("Sounds").navigationBarTitleDisplayMode(.inline).onDisappear {model.stopSounds()}
    }
}
