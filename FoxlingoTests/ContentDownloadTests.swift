import XCTest
@testable import FoxlingoCore

private final class LessonURLProtocol: URLProtocol, @unchecked Sendable {
    struct Reply: Sendable {let data: Data;let status: Int;let length: Int?;let responseURL: URL?}
    nonisolated(unsafe) static var replies: [String:Reply]=[:]
    static let lock=NSLock()
    static func set(_ values: [String:Reply]) {lock.lock();defer {lock.unlock()};replies=values}
    override class func canInit(with request: URLRequest) -> Bool {true}
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {request}
    override func startLoading() {
        Self.lock.lock();let reply=Self.replies[request.url!.absoluteString];Self.lock.unlock()
        guard let reply else {client?.urlProtocol(self,didFailWithError:URLError(.resourceUnavailable));return}
        let headers=reply.length.map {["Content-Length":String($0)]} ?? [:]
        let response=HTTPURLResponse(url:reply.responseURL ?? request.url!,statusCode:reply.status,httpVersion:"HTTP/1.1",headerFields:headers)!
        client?.urlProtocol(self,didReceive:response,cacheStoragePolicy:.notAllowed)
        client?.urlProtocol(self,didLoad:reply.data)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}
final class ContentDownloadTests: XCTestCase, @unchecked Sendable {
    let feed="https://lessons.example/feed.json",file="https://lessons.example/pack.json"
    func fixture() throws -> (ContentPack,Data,Data) {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent()
        let bundled=try Data(contentsOf:root.appendingPathComponent("Foxlingo/Resources/starter-en.json"))
        let pack=try ContentPack.load(bundled)
        var json=try JSONSerialization.jsonObject(with:bundled) as! [String:Any];json["contentVersion"]=6
        let data=try JSONSerialization.data(withJSONObject:json)
        let manifest=ContentManifest(packKey:pack.key,contentVersion:6,schemaVersion:1,language:"en",contentURL:file,sha256:ContentUpdateRules.digest(data))
        return (pack,data,try JSONEncoder().encode(manifest))
    }
    func session() -> URLSession {
        let config=URLSessionConfiguration.ephemeral;config.protocolClasses=[LessonURLProtocol.self]
        return URLSession(configuration:config)
    }
    private func replies(_ data: Data,_ manifest: Data) -> [String:LessonURLProtocol.Reply] {
        [feed:.init(data:manifest,status:200,length:nil,responseURL:nil),file:.init(data:data,status:200,length:nil,responseURL:nil)]
    }
    func testHTTPSManifestAndStreamedContentWithoutLength() async throws {
        let (pack,data,manifest)=try fixture();LessonURLProtocol.set(replies(data,manifest))
        let result=try await ContentDownload.fetch(manifestURL:feed,bundled:pack,testingSession:session())
        XCTAssertEqual(result,data)
    }
    func testOversizedManifestAndUnsuccessfulResponseAreRejected() async throws {
        let (pack,data,manifest)=try fixture()
        var values=replies(data,manifest)
        values[feed] = .init(data:Data(repeating:32,count:64*1024+1),status:200,length:nil,responseURL:nil)
        LessonURLProtocol.set(values)
        do {_ = try await ContentDownload.fetch(manifestURL:feed,bundled:pack,testingSession:session());XCTFail("Oversized stream accepted")} catch {}
        values=replies(data,manifest);values[file] = .init(data:data,status:503,length:nil,responseURL:nil);LessonURLProtocol.set(values)
        do {_ = try await ContentDownload.fetch(manifestURL:feed,bundled:pack,testingSession:session());XCTFail("Unsuccessful response accepted")} catch {}
    }
    func testDowngradedFinalURLAndOversizedDeclaredContentAreRejected() async throws {
        let (pack,data,manifest)=try fixture();var values=replies(data,manifest)
        values[file] = .init(data:data,status:200,length:nil,responseURL:URL(string:"http://lessons.example/pack.json"));LessonURLProtocol.set(values)
        do {_ = try await ContentDownload.fetch(manifestURL:feed,bundled:pack,testingSession:session());XCTFail("HTTP response accepted")} catch {}
        values[file] = .init(data:data,status:200,length:ContentUpdateRules.maximumBytes+1,responseURL:nil);LessonURLProtocol.set(values)
        do {_ = try await ContentDownload.fetch(manifestURL:feed,bundled:pack,testingSession:session());XCTFail("Oversized declared download accepted")} catch {}
    }
    func testCancelledImportAndBoundedFileRead() async throws {
        let (_,data,_)=try fixture()
        let file=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString+".json")
        defer {try? FileManager.default.removeItem(at:file)}
        try data.write(to:file);XCTAssertEqual(try ContentImport.read(file),data)
        let task=Task {try Task.checkCancellation();return try ContentImport.read(file)}
        task.cancel()
        do {_ = try await task.value;XCTFail("Cancelled import continued")} catch is CancellationError {} catch {XCTFail(error.localizedDescription)}
        try Data(repeating:32,count:ContentUpdateRules.maximumBytes+1).write(to:file)
        XCTAssertThrowsError(try ContentImport.read(file))
    }
}
