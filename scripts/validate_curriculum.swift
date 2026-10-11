import Foundation

@main struct ValidateCurriculum {
    static func main() throws {
        guard CommandLine.arguments.count==3 else {throw ContentError.invalid("Provide previous and expanded curriculum files.")}
        let old=try ContentPack.load(Data(contentsOf:URL(fileURLWithPath:CommandLine.arguments[1])))
        let raw=try Data(contentsOf:URL(fileURLWithPath:CommandLine.arguments[2]))
        let expanded=try ContentUpdateRules.decode(raw,bundled:old)
        try ContentUpdateRules.validateTransition(from:old,to:expanded)
        print("Validated curriculum version \(expanded.contentVersion): \(expanded.lessons.count) lessons, \(expanded.objectives.count) memories, \(expanded.playerRoadmaps.count) player courses; previous progress semantics preserved.")
    }
}
