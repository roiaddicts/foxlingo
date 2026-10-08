import AVFoundation

@MainActor final class SoundPlayer {
    private var player: AVAudioPlayer?
    private var ending: Task<Void,Never>?
    @discardableResult func play(_ asset: SoundAsset,preview: Bool=false) -> Bool {
        stop()
        guard let url=Bundle.main.url(forResource:asset.rawValue,withExtension:"mp3",subdirectory:"Sounds") else {return false}
        do {
            let session=AVAudioSession.sharedInstance()
            // Ambient audio respects the silent switch and mixes with the learner's music.
            try session.setCategory(.ambient,mode:.default,options:.mixWithOthers)
            try session.setActive(true)
            let next=try AVAudioPlayer(contentsOf:url)
            next.volume=asset.volume;next.prepareToPlay();player=next
            guard next.play() else {stop();return false}
            let duration=preview ? next.duration : min(next.duration,asset.maximumFeedbackDuration ?? next.duration)
            ending=Task { [weak self] in
                do {try await Task.sleep(for:.seconds(max(0,duration-0.08)))} catch {return}
                guard !Task.isCancelled else {return}
                self?.player?.setVolume(0,fadeDuration:0.08)
                do {try await Task.sleep(for:.seconds(0.08))} catch {return}
                guard !Task.isCancelled else {return};self?.stop()
            }
            return true
        } catch {stop();return false}
    }
    func stop() {
        ending?.cancel();ending=nil;player?.stop();player=nil
        try? AVAudioSession.sharedInstance().setActive(false,options:.notifyOthersOnDeactivation)
    }
}
