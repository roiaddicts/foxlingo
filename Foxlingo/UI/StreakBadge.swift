import SwiftUI

/// Particle flame, animated in real time while the app is active.
struct StreakBadge: View {
    let days: Int
    #if DEBUG
    @AppStorage(StreakFlameConfiguration.storageKey) private var savedFlame = ""
    #endif
    private var flameConfiguration: StreakFlameConfiguration {
        #if DEBUG
        StreakFlameConfiguration.decode(savedFlame)
        #else
        .standard
        #endif
    }
    @Environment(\.accessibilityReduceMotion) private var reduced
    @Environment(\.scenePhase) private var scenePhase
    @State private var visible=false
    @State private var started=Date()
    @State private var flameSeed=Double.random(in:0..<10000)
    @State private var lowPower=ProcessInfo.processInfo.isLowPowerModeEnabled
    var body: some View {
        HStack(spacing:5) {
            TimelineView(.animation(minimumInterval:1.0/30,paused:!visible || reduced || lowPower || scenePhase != .active || days == 0)) {timeline in
                if days == 0 {
                    Image(systemName:"flame.fill").font(.system(size:29)).foregroundStyle(Palette.muted.opacity(0.35)).frame(width:34,height:42)
                } else {
                    let time=reduced || lowPower ? 0 : timeline.date.timeIntervalSince(started)
                    StreakFlame(time:time,intensity:min(1,log2(Double(max(1,days)))/6),seed:flameSeed,configuration:flameConfiguration)
                        .frame(width:34,height:42)
                        .accessibilityHidden(true)
                }
            }
            Text("\(days)").font(.headline).monospacedDigit().contentTransition(.numericText()).foregroundStyle(Palette.brand)
        }.accessibilityElement(children:.ignore).accessibilityLabel("\(days) active day streak").accessibilityIdentifier("streak-badge")
            .onAppear {visible=true}.onDisappear {visible=false}
            .onReceive(NotificationCenter.default.publisher(for:.NSProcessInfoPowerStateDidChange)) {_ in lowPower=ProcessInfo.processInfo.isLowPowerModeEnabled}
    }
}

/// Shared values let the playground exercise the same renderer as the badge.
private struct StreakFlameConfiguration: Codable, Equatable {
    var particles: Double = 720
    var speed: Double = 1
    var lifetime: Double = 1
    var height: Double = 1
    var baseWidth: Double = 0.31
    var particleSize: Double = 1
    var turbulence: Double = 1
    var brightness: Double = 1
    var coreHeat: Double = 1

    static let standard = Self()
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

/// Every visible mark is a rising particle. Additive overlap makes the dense
/// center hotter and brighter without painting a separate inner flame.
private struct StreakFlame: View {
    let time: Double
    let intensity: Double
    var seed: Double = 0
    var configuration: StreakFlameConfiguration = .standard

    private static func random(_ seed: Double) -> Double {
        let value = sin(seed * 127.1 + 311.7) * 43758.5453
        return value - floor(value)
    }

    /// Smooth, non-looping wind shared by nearby particles, with smaller eddies.
    private static func noise(_ coordinate: Double, seed: Double) -> Double {
        let cell = floor(coordinate)
        let fraction = coordinate - cell
        let blend = fraction * fraction * (3 - 2 * fraction)
        return (random(cell + seed) * (1 - blend) + random(cell + seed + 1) * blend) * 2 - 1
    }

    var body: some View {
        Canvas { context, size in
            // Two pixels per point, capped for enlarged playground previews.
            let width = min(136, max(68, Int(size.width * 2)))
            let height = min(168, max(84, Int(size.height * 2)))
            var density = [Float](repeating: 0, count: width * height)
            let energy = (0.85 + 0.15 * intensity) * configuration.speed
            // Accumulate particle energy before mapping it to emitted light.
            // This preserves bright overlap on both light and dark backgrounds.
            for index in 0..<Int(configuration.particles) {
                let slot = Double(index) + seed
                let lifetime = (1.05 + Self.random(slot + 19) * 0.8) * configuration.lifetime
                let clock = time * energy / lifetime + Self.random(slot + 47)
                let generation = floor(clock)
                let age = clock - generation
                // A new seed on every birth prevents a repeating silhouette.
                let seed = slot * 17.0 + generation * 251.0
                let spread = (Self.random(seed + 1) + Self.random(seed + 2) - 1) * configuration.baseWidth
                let bowl = sqrt(max(0, 1 - pow(spread / configuration.baseWidth, 2)))
                let originY = 0.80 + bowl * 0.095 + Self.random(seed + 3) * 0.018
                let rise = (0.47 + Self.random(seed + 4) * 0.29) * pow(age, 1.15) * configuration.height
                let wind = Self.noise(time * 1.7 - rise * 3, seed: 71)
                let eddy = Self.noise(time * 3.4 - age * 4, seed: floor(spread * 8) + 113)
                let curl = (wind * 0.13 + eddy * 0.055) * configuration.turbulence
                let x = 0.5 + spread * pow(1 - age, 0.7) + curl * pow(age, 1.2)
                let y = originY - rise
                let radius = (0.048 + Self.random(seed + 5) * 0.035) * (1 - age * 0.68) * configuration.particleSize
                // Soft birth/death hides recycling and lets the tips dissolve.
                let birth = min(1, age / 0.09)
                let death = min(1, (1 - age) / 0.28)
                let opacity = birth * death * (0.65 + Self.random(seed + 6) * 0.25)
                let centerX = x * Double(width)
                let centerY = y * Double(height)
                let radiusX = radius * Double(width)
                let radiusY = radiusX * 1.2
                let left = max(0, Int(floor(centerX - radiusX)))
                let right = min(width - 1, Int(ceil(centerX + radiusX)))
                let top = max(0, Int(floor(centerY - radiusY)))
                let bottom = min(height - 1, Int(ceil(centerY + radiusY)))
                guard left <= right, top <= bottom else { continue }
                for row in top...bottom {
                    let dy = (Double(row) + 0.5 - centerY) / radiusY
                    for column in left...right {
                        let dx = (Double(column) + 0.5 - centerX) / radiusX
                        let falloff = max(0, 1 - dx * dx - dy * dy)
                        density[row * width + column] += Float(opacity * falloff * falloff)
                    }
                }
            }
            var pixels = [UInt8](repeating: 0, count: width * height * 4)
            for index in density.indices {
                let heat = Double(density[index]) * configuration.brightness
                let alpha = 1 - exp(-heat * 1.8)
                // Sparse particles emit orange; accumulated energy becomes
                // yellow, then white-hot. No center mask or inner shape.
                let yellow = 1 - exp(-heat * 0.42)
                let white = 1 - exp(-max(0, heat - 2) * 0.22 * configuration.coreHeat)
                pixels[index * 4] = UInt8(255 * alpha)
                pixels[index * 4 + 1] = UInt8(255 * (0.18 + 0.80 * yellow) * alpha)
                pixels[index * 4 + 2] = UInt8(255 * (0.015 + 0.80 * white) * alpha)
                pixels[index * 4 + 3] = UInt8(255 * alpha)
            }
            if let provider = CGDataProvider(data: Data(pixels) as CFData),
               let image = CGImage(width: width, height: height, bitsPerComponent: 8,
                                   bitsPerPixel: 32, bytesPerRow: width * 4,
                                   space: CGColorSpaceCreateDeviceRGB(),
                                   bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                                   provider: provider, decode: nil, shouldInterpolate: true,
                                   intent: .defaultIntent) {
                context.draw(Image(decorative: image, scale: 2), in: CGRect(origin: .zero, size: size))
            }
        }
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
    @State private var elapsed = 0.0
    @State private var started = Date()
    @State private var seed = 42.0
    @State private var dark = false
    @State private var days = 7.0
    private var canAnimate: Bool { playing && visible && !reduced && !lowPower && scenePhase == .active }

    var body: some View {
        VStack(spacing: 0) {
            livePreview.padding(.horizontal, 16).padding(.bottom, 12)
            Form {
                Section("Particles & motion") {
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
                    control("Streak days", value: $days, range: 1...64, step: 1, decimals: 0)
                }
                Section {
                    Button("Use in streak badge") { savedFlame = configuration.json }
                        .disabled(configuration == StreakFlameConfiguration.decode(savedFlame))
                    ShareLink(item: configuration.json) { Label("Share settings", systemImage: "square.and.arrow.up") }
                    Button("Restore original flame") { configuration = .standard; savedFlame = "" }
                } header: { Text("Keep this look") } footer: {
                    Text("Use in streak badge saves these values on this device for Debug builds. Share settings to keep a preset or send it for the final design.")
                }
            }
        }
        .navigationTitle("Flame playground")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { configuration = StreakFlameConfiguration.decode(savedFlame); visible = true }
        .onDisappear { visible = false }
        .onChange(of: canAnimate) { oldValue, newValue in
            if oldValue { elapsed += Date().timeIntervalSince(started) }
            if newValue { started = Date() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSProcessInfoPowerStateDidChange)) { _ in
            lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
        }
    }

    private var livePreview: some View {
        VStack(spacing: 12) {
            TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !canAnimate)) { timeline in
                let time = elapsed + (canAnimate ? max(0, timeline.date.timeIntervalSince(started)) : 0)
                HStack(spacing: 32) {
                    StreakFlame(time: time, intensity: min(1, log2(days) / 6), seed: seed, configuration: configuration)
                        .frame(width: 102, height: 126)
                    VStack(spacing: 8) {
                        HStack(spacing: 5) {
                            StreakFlame(time: time, intensity: min(1, log2(days) / 6), seed: seed, configuration: configuration)
                                .frame(width: 34, height: 42)
                            Text("\(Int(days))").font(.headline).monospacedDigit().foregroundStyle(dark ? .white : Palette.brand)
                        }
                        Text("Actual badge size").font(.caption).foregroundStyle(dark ? .white.opacity(0.7) : .secondary)
                    }
                }
                .frame(maxWidth: .infinity).padding(.vertical, 12)
                .background(dark ? Color(red: 0.07, green: 0.08, blue: 0.10) : Color(red: 0.98, green: 0.97, blue: 0.95), in: RoundedRectangle(cornerRadius: 16))
                .accessibilityLabel("Animated flame preview and actual streak badge")
            }
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
        StreakBadge(days: 0)
        StreakBadge(days: 1)
        StreakBadge(days: 7)
        StreakBadge(days: 64)
    }
    .padding()
}
#endif
