import SwiftUI

/// Small procedural flame; the redraw loop is scoped to the visible, active app.
struct StreakBadge: View {
    let days: Int
    @Environment(\.accessibilityReduceMotion) private var reduced
    @Environment(\.scenePhase) private var scenePhase
    @State private var visible=false
    @State private var started=Date()
    @State private var lowPower=ProcessInfo.processInfo.isLowPowerModeEnabled
    var body: some View {
        HStack(spacing:5) {
            TimelineView(.animation(minimumInterval:1.0/24,paused:!visible || reduced || lowPower || scenePhase != .active || days == 0)) {timeline in
                if days == 0 {
                    Image(systemName:"flame.fill").font(.system(size:29)).foregroundStyle(Palette.muted.opacity(0.35)).frame(width:34,height:42)
                } else {
                    let time=reduced || lowPower ? 0 : Float(timeline.date.timeIntervalSince(started))
                    Rectangle().fill(.white).frame(width:34,height:42)
                        .colorEffect(ShaderLibrary.streakFire(.float2(34,42),.float(time),.float(min(1,Float(log2(Double(max(1,days))))/6))))
                        .accessibilityHidden(true)
                }
            }
            Text("\(days)").font(.headline).monospacedDigit().contentTransition(.numericText()).foregroundStyle(Palette.brand)
        }.accessibilityElement(children:.ignore).accessibilityLabel("\(days) active day streak").accessibilityIdentifier("streak-badge")
            .onAppear {visible=true}.onDisappear {visible=false}
            .onReceive(NotificationCenter.default.publisher(for:.NSProcessInfoPowerStateDidChange)) {_ in lowPower=ProcessInfo.processInfo.isLowPowerModeEnabled}
    }
}
