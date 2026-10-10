import Foundation

/// Builds with the app's Core sources; never downloads or runs provider code.
@main struct ValidateDaily {
    static func main() async throws {
        if CommandLine.arguments.count == 3,CommandLine.arguments[1] == "--url" {
            let raw=try await ContentDownload.fetchDaily(pointerURL:CommandLine.arguments[2])
            let pack=try DailyChallengePack.load(raw)
            guard pack.isToday(Date()),pack.supportedModeIDs == DailyChallengePack.modeIDs else {throw ContentError.invalid("The hosted feed is stale or missing native modes.")}
            print("Verified live HTTPS feed · \(pack.gameDate) · \(pack.supportedModeIDs.count) native daily modes")
            return
        }
        guard CommandLine.arguments.count >= 2 else {throw ContentError.invalid("Provide a current daily packet and optional rollback packets.")}
        for (index,path) in CommandLine.arguments.dropFirst().enumerated() {
            let data=try Data(contentsOf:URL(fileURLWithPath:path))
            let pack=try DailyChallengePack.load(data)
            if index == 0 && pack.supportedModeIDs != DailyChallengePack.modeIDs {throw ContentError.invalid("The current feed must support all nineteen daily games.")}
            print("Validated \(pack.gameDate) · \(pack.supportedModeIDs.count) native daily modes")
        }
    }
}
