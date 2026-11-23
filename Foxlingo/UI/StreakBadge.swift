import SwiftUI

/// Particle flame, animated in real time while the app is active.
struct StreakBadge: View {
    let days: Int
    #if DEBUG
    @AppStorage(StreakFlameConfiguration.storageKey) private var savedFlame = ""
    #endif
    private var flameConfiguration: StreakFlameConfiguration {
        #if DEBUG
        StreakFlameConfiguration.decode(savedFlame).grown(at: days)
        #else
        StreakFlameConfiguration.standard.grown(at: days)
        #endif
    }
    @Environment(\.accessibilityReduceMotion) private var reduced
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.streakFlameAnimationsEnabled) private var animationsEnabled
    @State private var visible=false
    @State private var flameSeed=Double.random(in:0..<10000)
    @State private var lowPower=ProcessInfo.processInfo.isLowPowerModeEnabled
    var body: some View {
        HStack(spacing:5) {
            if days == 0 {
                Image(systemName:"flame.fill").font(.system(size:29)).foregroundStyle(Palette.muted.opacity(0.35)).frame(width:34,height:42)
            } else {
                StreakFlame(intensity:flameConfiguration.colorProgress(at:days),seed:flameSeed,configuration:flameConfiguration,
                            growth:StreakFlameConfiguration.growth(at:days),
                            isAnimating:visible && animationsEnabled && !reduced && !lowPower && scenePhase == .active)
                    .frame(width:34,height:42)
                    .accessibilityHidden(true)
            }
            Text("\(days)").font(.headline).monospacedDigit().contentTransition(.numericText()).foregroundStyle(Palette.brand)
        }.accessibilityElement(children:.ignore).accessibilityLabel("\(days) active day streak").accessibilityIdentifier("streak-badge")
            .onAppear {visible=true}.onDisappear {visible=false}
            .onReceive(NotificationCenter.default.publisher(for:.NSProcessInfoPowerStateDidChange)) {_ in lowPower=ProcessInfo.processInfo.isLowPowerModeEnabled}
    }
}

/// Shared values let the playground exercise the same renderer as the badge.
struct StreakFlameConfiguration: Codable, Equatable {
    var particles: Double = 1400
    var speed: Double = 1
    var lifetime: Double = 1
    var height: Double = 0.75
    var baseWidth: Double = 0.25
    var particleSize: Double = 0.75
    var turbulence: Double = 1
    var brightness: Double = 1
    var coreHeat: Double = 1
    static let standard = Self()

    /// Reach the chosen full flame at 30 days, easing growth along a log scale.
    static func growth(at days: Int) -> Double {
        let t = min(1, max(0, log(Double(max(1, days))) / log(30)))
        return t * t * (3 - 2 * t)
    }

    /// Color milestones change only the color of newly born particles.
    func colorProgress(at days: Int) -> Double {
        days >= 365 ? 3 : days >= 100 ? 2 : days >= 30 ? 1 : 0
    }

    func grown(at days: Int) -> Self {
        let progress = Self.growth(at: days)
        var result = self
        let startingParticles = min(720, particles)
        let startingWidth = min(0.16, baseWidth)
        result.particles = (startingParticles + (particles - startingParticles) * progress).rounded()
        result.baseWidth = startingWidth + (baseWidth - startingWidth) * progress
        return result
    }

    /// Shorter flames occupy the bottom of the texture; lift the visible body
    /// into the number's center without moving the badge's layout or baseline.
    var verticalOffset: Double { 0.5 - (0.92 - 0.38 * height) }

    #if DEBUG
    static let storageKey = "debug.streakFlame.configuration.v1"
    static func decode(_ text: String) -> Self {
        guard let data = text.data(using: .utf8),
              let value = try? JSONDecoder().decode(Self.self, from: data) else { return .standard }
        return value
    }
    var json: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(self), let text = String(data: data, encoding: .utf8) else { return "" }
        return text
    }
    #endif
}

private struct StreakFlameAnimationsKey: EnvironmentKey {
    static let defaultValue = true
}
extension EnvironmentValues {
    var streakFlameAnimationsEnabled: Bool {
        get { self[StreakFlameAnimationsKey.self] }
        set { self[StreakFlameAnimationsKey.self] = newValue }
    }
}

#if DEBUG
/// A development-only control room, available in Settings and Xcode Previews.
struct StreakFlamePlayground: View {
    @AppStorage(StreakFlameConfiguration.storageKey) private var savedFlame = ""
    @Environment(\.accessibilityReduceMotion) private var reduced
    @Environment(\.scenePhase) private var scenePhase
    @State private var configuration = StreakFlameConfiguration.standard
    @State private var playing = true
    @State private var visible = false
    @State private var lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
    @State private var seed = 42.0
    @State private var dark = false
    @State private var days = 7.0
    @State private var evolves = true
    @State private var previewSuccess = false
    private var canAnimate: Bool { playing && visible && !reduced && !lowPower && scenePhase == .active }

    var body: some View {
        VStack(spacing: 0) {
            livePreview.padding(.horizontal, 16).padding(.bottom, 12)
            Form {
                Section {
                    Toggle("Grow with streak", isOn: $evolves)
                    control("Streak days", value: $days, range: 1...400, step: 1, decimals: 0)
                    HStack {
                        ForEach([1, 30, 100, 365], id: \.self) { milestone in
                            Button("\(milestone)d") { days = Double(milestone) }
                                .frame(maxWidth: .infinity)
                        }
                    }.buttonStyle(.borderless)
                } header: { Text("Streak progression") } footer: {
                    Text("Orange to start, green at 30 days, blue at 100, and rainbow at 365. New particles take the new color; existing particles keep theirs. Size reaches your full preset at day 30.")
                }
                Section {
                    Button("Preview streak success") { previewSuccess = true }
                }
                Section("Full flame · particles & motion") {
                    control("Particles", value: $configuration.particles, range: 120...1400, step: 40, decimals: 0)
                    control("Speed", value: $configuration.speed, range: 0.3...2, step: 0.05)
                    control("Lifetime", value: $configuration.lifetime, range: 0.5...2, step: 0.05)
                    control("Height", value: $configuration.height, range: 0.6...1.1, step: 0.01)
                    control("Base width", value: $configuration.baseWidth, range: 0.16...0.38, step: 0.01)
                    control("Particle size", value: $configuration.particleSize, range: 0.6...1.35, step: 0.05)
                    control("Turbulence", value: $configuration.turbulence, range: 0...2, step: 0.05)
                }
                Section("Light") {
                    control("Brightness", value: $configuration.brightness, range: 0.4...2, step: 0.05)
                    control("Core heat", value: $configuration.coreHeat, range: 0.4...2, step: 0.05)
                }
                Section {
                    Button("Use in streak badge") { savedFlame = configuration.json }
                        .disabled(configuration == StreakFlameConfiguration.decode(savedFlame))
                    ShareLink(item: configuration.json) { Label("Share settings", systemImage: "square.and.arrow.up") }
                    Button("Restore recommended flame") { configuration = .standard; savedFlame = "" }
                } header: { Text("Keep this look") } footer: {
                    Text("These controls define the full flame. Use in streak badge saves the preset on this device for Debug builds, with streak growth applied automatically. Share settings to keep a preset or send it for the final design.")
                }
            }
        }
        .overlay { if previewSuccess { StreakSuccessView(days: Int(days), previousDays: max(0, Int(days) - 1), configuration: configuration) { previewSuccess = false } } }
        .navigationTitle("Flame playground")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { configuration = StreakFlameConfiguration.decode(savedFlame); visible = true }
        .onDisappear { visible = false }
        .onReceive(NotificationCenter.default.publisher(for: .NSProcessInfoPowerStateDidChange)) { _ in
            lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
        }
    }

    private var livePreview: some View {
        VStack(spacing: 12) {
            StreakFlame(intensity: evolves ? configuration.colorProgress(at: Int(days)) : 0,
                        seed: seed, configuration: evolves ? configuration.grown(at: Int(days)) : configuration,
                        growth: evolves ? StreakFlameConfiguration.growth(at: Int(days)) : 1,
                        isAnimating: canAnimate && !previewSuccess, comparison: true)
                .frame(height: 126)
                .overlay {
                    GeometryReader { geometry in
                        let left = (geometry.size.width - 238) / 2
                        Text("\(Int(days))").font(.headline).monospacedDigit()
                            .foregroundStyle(dark ? .white : Palette.brand)
                            .position(x: left + 202, y: 50)
                        Text("Actual badge size").font(.caption)
                            .foregroundStyle(dark ? .white.opacity(0.7) : .secondary)
                            .position(x: left + 186, y: 94)
                    }.allowsHitTesting(false)
                }
                .padding(.vertical, 12)
                .background(dark ? Color(red: 0.07, green: 0.08, blue: 0.10) : Color(red: 0.98, green: 0.97, blue: 0.95), in: RoundedRectangle(cornerRadius: 16))
                .accessibilityLabel("Animated flame preview and actual streak badge")
            HStack {
                Button { playing.toggle() } label: { Label(playing ? "Pause" : "Play", systemImage: playing ? "pause.fill" : "play.fill") }
                    .disabled(reduced || lowPower)
                Spacer()
                Button("New flame", systemImage: "shuffle") { seed = Double.random(in: 0..<10000) }
                Toggle("Dark", isOn: $dark).frame(width: 116)
            }.buttonStyle(.borderless)
            if reduced || lowPower { Text("Animation paused by Reduce Motion or Low Power Mode.").font(.caption).foregroundStyle(.secondary) }
        }
    }

    private func control(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, decimals: Int = 2) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text(value.wrappedValue, format: .number.precision(.fractionLength(decimals)))
                    .monospacedDigit().foregroundStyle(.secondary)
                Stepper(title, value: value, in: range, step: step)
                    .labelsHidden().fixedSize()
                    .accessibilityIdentifier("flame-\(title.lowercased().replacingOccurrences(of: " ", with: "-"))-stepper")
            }
            Slider(value: value, in: range, step: step) { Text(title) }
                .accessibilityIdentifier("flame-\(title.lowercased().replacingOccurrences(of: " ", with: "-"))")
        }
    }
}

#Preview("Flame playground") {
    NavigationStack { StreakFlamePlayground() }
}

#Preview("Streak flames") {
    HStack(spacing: 24) {
        StreakBadge(days: 1)
        StreakBadge(days: 7)
        StreakBadge(days: 30)
        StreakBadge(days: 100)
    }
    .padding()
}
#endif

/// One shared celebration, presented above the activity that earned today's streak.
struct StreakSuccess: Identifiable {
    let id = UUID()
    let days: Int
    let previousDays: Int
}

struct StreakSuccessView: View {
    let days: Int
    let previousDays: Int
    var configuration: StreakFlameConfiguration = .standard
    let onContinue: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduced
    @Environment(\.scenePhase) private var scenePhase
    @State private var lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
    private var milestone: String? {
        switch days { case 30: "Your flame is now green."; case 100: "Your flame is now blue."; case 365: "A year of learning. Your rainbow flame is here."; default: nil }
    }
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            StreakFlame(intensity: configuration.colorProgress(at: days),
                        initialIntensity: configuration.colorProgress(at: previousDays), seed: 42,
                        configuration: configuration.grown(at: days),
                        growth: StreakFlameConfiguration.growth(at: days),
                        isAnimating: !reduced && !lowPower && scenePhase == .active)
                .frame(width: 170, height: 210).accessibilityHidden(true)
            Text("\(days) day streak").font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(Palette.brand).accessibilityIdentifier("streak-success")
            Text(milestone ?? "Another day. Another part of your football story.")
                .font(.title3).foregroundStyle(Palette.muted).multilineTextAlignment(.center)
            Spacer()
            PrimaryButton(title: "Continue", action: onContinue).accessibilityIdentifier("streak-success-continue")
        }.padding(32).frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 0.98, green: 0.97, blue: 0.95).ignoresSafeArea())
            .onReceive(NotificationCenter.default.publisher(for: .NSProcessInfoPowerStateDidChange)) { _ in
                lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
            }
    }
}

struct StreakSuccessOverlay: ViewModifier {
    var isLessonHost = false
    @EnvironmentObject private var model: AppModel
    #if DEBUG
    @AppStorage(StreakFlameConfiguration.storageKey) private var savedFlame = ""
    #endif
    private var configuration: StreakFlameConfiguration {
        #if DEBUG
        StreakFlameConfiguration.decode(savedFlame)
        #else
        .standard
        #endif
    }
    func body(content: Content) -> some View {
        content.overlay {
            if let success = model.streakSuccess, model.lessonIsPresented == isLessonHost {
                StreakSuccessView(days: success.days, previousDays: success.previousDays, configuration: configuration) { model.streakSuccess = nil }
            }
        }
    }
}
