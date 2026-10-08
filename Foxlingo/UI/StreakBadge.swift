import SwiftUI

/// Small procedural flame; the redraw loop is scoped to the visible, active app.
struct StreakBadge: View {
    let days: Int
    @Environment(\.accessibilityReduceMotion) private var reduced
    @Environment(\.scenePhase) private var scenePhase
    @State private var visible=false
    @State private var lowPower=ProcessInfo.processInfo.isLowPowerModeEnabled
    var body: some View {
        HStack(spacing:5) {
            TimelineView(.animation(minimumInterval:1.0/24,paused:!visible || reduced || lowPower || scenePhase != .active || days == 0)) {timeline in
                Canvas {context,size in
                    let time=reduced || lowPower || days == 0 ? 0 : timeline.date.timeIntervalSinceReferenceDate
                    func flame(_ scale: CGFloat,_ phase: Double) -> Path {
                        let w=size.width,h=size.height,cx=w/2
                        let sway=CGFloat(sin(time*4.2+phase))*w*0.055
                        var p=Path()
                        p.move(to:CGPoint(x:cx,y:h*0.93))
                        p.addCurve(to:CGPoint(x:cx-w*0.32*scale,y:h*0.56),control1:CGPoint(x:cx-w*0.38*scale,y:h*0.96),control2:CGPoint(x:cx-w*0.45*scale,y:h*0.72))
                        p.addCurve(to:CGPoint(x:cx+sway,y:h*(0.08+(1-scale)*0.5)),control1:CGPoint(x:cx-w*0.28*scale,y:h*0.36),control2:CGPoint(x:cx+w*0.07*scale+sway,y:h*0.35))
                        p.addCurve(to:CGPoint(x:cx+w*0.22*scale,y:h*0.51),control1:CGPoint(x:cx+w*0.24*scale+sway,y:h*0.2),control2:CGPoint(x:cx+w*0.04*scale,y:h*0.43))
                        p.addCurve(to:CGPoint(x:cx+w*0.30*scale,y:h*0.61),control1:CGPoint(x:cx+w*0.29*scale,y:h*0.49),control2:CGPoint(x:cx+w*0.31*scale,y:h*0.39))
                        p.addCurve(to:CGPoint(x:cx,y:h*0.93),control1:CGPoint(x:cx+w*0.48*scale,y:h*0.82),control2:CGPoint(x:cx+w*0.27*scale,y:h*0.96))
                        p.closeSubpath();return p
                    }
                    if days == 0 {context.fill(flame(1,0),with:.color(Palette.muted.opacity(0.35)))}
                    else {
                        context.fill(flame(1,0),with:.linearGradient(Gradient(colors:[Color(red:1,green:0.64,blue:0.12),Color(red:0.96,green:0.28,blue:0.06)]),startPoint:.zero,endPoint:CGPoint(x:0,y:size.height)))
                        context.fill(flame(0.64,1.3),with:.linearGradient(Gradient(colors:[Color(red:1,green:0.9,blue:0.48),Color(red:1,green:0.64,blue:0.08)]),startPoint:.zero,endPoint:CGPoint(x:0,y:size.height)))
                        context.fill(flame(0.32,2.1),with:.color(Color(red:1,green:0.96,blue:0.75)))
                    }
                }.frame(width:27,height:33).accessibilityHidden(true)
            }
            Text("\(days)").font(.headline).monospacedDigit().contentTransition(.numericText()).foregroundStyle(Palette.brand)
        }.accessibilityElement(children:.ignore).accessibilityLabel("\(days) active day streak").accessibilityIdentifier("streak-badge")
            .onAppear {visible=true}.onDisappear {visible=false}
            .onReceive(NotificationCenter.default.publisher(for:.NSProcessInfoPowerStateDidChange)) {_ in lowPower=ProcessInfo.processInfo.isLowPowerModeEnabled}
    }
}
