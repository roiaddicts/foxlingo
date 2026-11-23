import SwiftUI
import MetalKit

/// MTKView owns the display clock; SwiftUI only sends changed controls, never frames.
struct StreakFlame: UIViewRepresentable {
    let intensity: Double
    var initialIntensity: Double? = nil
    var seed: Double = 0
    var configuration: StreakFlameConfiguration = .standard
    var growth: Double = 1
    var isAnimating = true
    var comparison = false

    func makeCoordinator() -> FlameMetalRenderer { FlameMetalRenderer() }

    func makeUIView(context: Context) -> FlameMetalView {
        let view = FlameMetalView(frame: .zero, device: FlameMetalResources.shared?.device)
        view.backgroundColor = .clear
        view.isOpaque = false
        view.layer.isOpaque = false
        view.clearColor = MTLClearColorMake(0, 0, 0, 0)
        view.colorPixelFormat = .bgra8Unorm
        view.preferredFramesPerSecond = 30
        view.isPaused = true
        view.enableSetNeedsDisplay = true
        view.isUserInteractionEnabled = false
        view.delegate = context.coordinator
        view.playbackChanged = { [weak renderer = context.coordinator] view in renderer?.synchronizePlayback(in: view) }
        if FlameMetalResources.shared == nil {
            // A static fallback for devices without Metal, with no CPU animation.
            let image = UIImageView(image: UIImage(systemName: "flame.fill"))
            image.tintColor = .systemOrange
            image.contentMode = .scaleAspectFit
            image.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(image)
            NSLayoutConstraint.activate([image.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                                         image.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                                         image.topAnchor.constraint(equalTo: view.topAnchor),
                                         image.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
        }
        return view
    }

    func updateUIView(_ view: FlameMetalView, context: Context) {
        let renderer = context.coordinator
        renderer.setColorStage(Float(intensity), initial: initialIntensity.map(Float.init), animate: isAnimating)
        renderer.seed = Float(seed)
        renderer.configuration = configuration
        renderer.growth = Float(growth)
        renderer.comparison = comparison
        renderer.desiredAnimation = isAnimating
        renderer.synchronizePlayback(in: view)
        if view.isPaused { view.setNeedsDisplay() }
    }

    static func dismantleUIView(_ view: FlameMetalView, coordinator: FlameMetalRenderer) {
        coordinator.desiredAnimation = false
        coordinator.synchronizePlayback(in: view)
        view.delegate = nil
        view.playbackChanged = nil
    }
}

final class FlameMetalView: MTKView {
    var playbackChanged: ((FlameMetalView) -> Void)?
    override func didMoveToWindow() {
        super.didMoveToWindow()
        playbackChanged?(self)
    }
}

struct FlameUniforms {
    var motion: SIMD4<Float>
    var shape: SIMD4<Float>
    var appearance: SIMD4<Float>
    var rectangle: SIMD4<Float> = SIMD4(0, 0, 1, 1)
    var evolution: SIMD4<Float> = SIMD4(1, 0, 0, 0)
}

/// Compile once and share immutable pipelines and the queue between flame views.
final class FlameMetalResources {
    static let shared = try? FlameMetalResources()
    let device: MTLDevice
    let queue: MTLCommandQueue
    let particles: MTLRenderPipelineState
    let light: MTLRenderPipelineState

    private init() throws {
        guard let device = MTLCreateSystemDefaultDevice(), let queue = device.makeCommandQueue(),
              let library = device.makeDefaultLibrary(),
              let particleVertex = library.makeFunction(name: "streakParticleVertex"),
              let particleFragment = library.makeFunction(name: "streakParticleDensity"),
              let lightVertex = library.makeFunction(name: "streakFlameVertex"),
              let lightFragment = library.makeFunction(name: "streakFlameLight") else {
            throw NSError(domain: "StreakFlame.Metal", code: 1)
        }
        self.device = device
        self.queue = queue
        let density = MTLRenderPipelineDescriptor()
        density.label = "Streak particle accumulation"
        density.vertexFunction = particleVertex
        density.fragmentFunction = particleFragment
        let attachment = density.colorAttachments[0]!
        attachment.pixelFormat = .rgba16Float
        attachment.isBlendingEnabled = true
        attachment.sourceRGBBlendFactor = .one
        attachment.destinationRGBBlendFactor = .one
        attachment.rgbBlendOperation = .add
        attachment.sourceAlphaBlendFactor = .one
        attachment.destinationAlphaBlendFactor = .one
        attachment.alphaBlendOperation = .add
        particles = try device.makeRenderPipelineState(descriptor: density)
        let output = MTLRenderPipelineDescriptor()
        output.label = "Streak emitted light"
        output.vertexFunction = lightVertex
        output.fragmentFunction = lightFragment
        output.colorAttachments[0].pixelFormat = .bgra8Unorm
        light = try device.makeRenderPipelineState(descriptor: output)
    }
}

final class FlameMetalRenderer: NSObject, MTKViewDelegate {
    private var intensity: Float = 0
    private var colorHistory: [SIMD2<Float>] = []
    private var clock: Float { Float(elapsed + (running ? CACurrentMediaTime() - anchor : 0)) }

    func setColorStage(_ stage: Float, initial: Float?, animate: Bool) {
        if !animate {
            colorHistory = [SIMD2(-1e10, stage)]
        } else if colorHistory.isEmpty {
            let first = animate ? initial ?? stage : stage
            colorHistory = [SIMD2(-1e10, first)]
            if first != stage { colorHistory.append(SIMD2(clock + 1.2, stage)) }
        } else if stage != intensity {
            colorHistory.append(SIMD2(clock, stage))
        }
        intensity = stage
        // Keep the last event before any currently alive particle was born.
        let oldestBirth = clock - Float(configuration.lifetime * 1.85 / max(0.01, configuration.speed))
        while colorHistory.count > 1 && colorHistory[1].x < oldestBirth { colorHistory.removeFirst() }
    }
    var growth: Float = 1
    var seed: Float = 0
    var configuration = StreakFlameConfiguration.standard
    var comparison = false
    var desiredAnimation = false
    private var running = false
    private var elapsed = 0.0
    private var anchor = CACurrentMediaTime()
    private let inFlight = DispatchSemaphore(value: 2)
    private let resources = FlameMetalResources.shared
    private var density: MTLTexture?

    override init() {
        super.init()
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba16Float, width: 136, height: 168, mipmapped: false)
        descriptor.usage = [.renderTarget, .shaderRead]
        descriptor.storageMode = .private
        density = resources?.device.makeTexture(descriptor: descriptor)
        density?.label = "Persistent streak particle density"
    }

    func synchronizePlayback(in view: FlameMetalView) {
        let animate = desiredAnimation && view.window != nil && resources != nil
        if running != animate {
            let now = CACurrentMediaTime()
            if running { elapsed += now - anchor }
            if animate { anchor = now }
            running = animate
        }
        view.isPaused = !animate
        view.enableSetNeedsDisplay = !animate
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        // Never wait for GPU work on the UI thread; drop a frame if it is busy.
        guard inFlight.wait(timeout: .now()) == .success else { return }
        guard let resources, let density, view.drawableSize.width > 0, view.drawableSize.height > 0,
              let drawable = view.currentDrawable, let outputPass = view.currentRenderPassDescriptor,
              let command = resources.queue.makeCommandBuffer() else { inFlight.signal(); return }
        let c = configuration
        var uniforms = FlameUniforms(
            motion: SIMD4(clock, intensity, seed, Float(c.particles)),
            shape: SIMD4(Float(c.speed), Float(c.lifetime), Float(c.height), Float(c.baseWidth)),
            appearance: SIMD4(Float(c.particleSize), Float(c.turbulence), Float(c.brightness), Float(c.coreHeat)),
            evolution: SIMD4(growth, Float(c.verticalOffset), Float(colorHistory.count), 0))
        command.label = "Streak flame GPU frame"
        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = density
        pass.colorAttachments[0].loadAction = .clear
        pass.colorAttachments[0].storeAction = .store
        pass.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0)
        guard let particles = command.makeRenderCommandEncoder(descriptor: pass) else { inFlight.signal(); return }
        particles.setRenderPipelineState(resources.particles)
        particles.setVertexBytes(&uniforms, length: MemoryLayout<FlameUniforms>.stride, index: 0)
        particles.setVertexBytes(colorHistory, length: MemoryLayout<SIMD2<Float>>.stride * colorHistory.count, index: 1)
        particles.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: Int(c.particles))
        particles.endEncoding()

        guard let light = command.makeRenderCommandEncoder(descriptor: outputPass) else { inFlight.signal(); return }
        light.setRenderPipelineState(resources.light)
        light.setFragmentTexture(density, index: 0)
        light.setFragmentBytes(&uniforms, length: MemoryLayout<FlameUniforms>.stride, index: 0)
        if comparison {
            // Both sizes sample ONE accumulated particle texture, in one MTKView.
            let width = Float(view.bounds.width)
            let height = Float(view.bounds.height)
            let left = (width - 238) / 2
            uniforms.rectangle = SIMD4(left / width, 0, 102 / width, 126 / height)
            light.setVertexBytes(&uniforms, length: MemoryLayout<FlameUniforms>.stride, index: 0)
            light.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
            uniforms.rectangle = SIMD4((left + 159) / width, 29 / height, 34 / width, 42 / height)
        }
        light.setVertexBytes(&uniforms, length: MemoryLayout<FlameUniforms>.stride, index: 0)
        light.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        light.endEncoding()
        let semaphore = inFlight
        command.addCompletedHandler { _ in semaphore.signal() }
        command.present(drawable)
        command.commit()
    }
}
