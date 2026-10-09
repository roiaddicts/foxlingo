import Foundation

private final class HTTPSRedirects: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
    func urlSession(_ session: URLSession,task: URLSessionTask,willPerformHTTPRedirection response: HTTPURLResponse,newRequest request: URLRequest,completionHandler: @escaping @Sendable (URLRequest?) -> Void) {
        let safe=request.url.flatMap {try? ContentUpdateRules.https($0.absoluteString)} != nil
        completionHandler(safe ? request : nil)
    }
}
public enum ContentDownload {
    public static func fetch(manifestURL: String,bundled: ContentPack) async throws -> Data {
        try await fetch(manifestURL:manifestURL,bundled:bundled,testingSession:nil)
    }
    static func fetch(manifestURL: String,bundled: ContentPack,testingSession: URLSession?) async throws -> Data {
        let configuration=URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest=30;configuration.timeoutIntervalForResource=90
        configuration.httpCookieStorage=nil;configuration.urlCredentialStorage=nil
        let session=testingSession ?? URLSession(configuration:configuration,delegate:HTTPSRedirects(),delegateQueue:nil)
        defer {session.invalidateAndCancel()}
        let manifestData=try await read(try ContentUpdateRules.https(manifestURL),limit:64*1024,session:session)
        let manifest=try JSONDecoder().decode(ContentManifest.self,from:manifestData)
        guard manifest.packKey == bundled.key,manifest.schemaVersion == bundled.schemaVersion,
              manifest.language == bundled.language,manifest.contentVersion > 0 else {throw ContentError.invalid("This update feed is for a different app edition.")}
        let data=try await read(try ContentUpdateRules.https(manifest.contentURL),limit:ContentUpdateRules.maximumBytes,session:session)
        _ = try manifest.verify(data,bundled:bundled)
        return data
    }
    public static func fetchDaily(pointerURL: String) async throws -> Data {
        try await fetchDaily(pointerURL:pointerURL,testingSession:nil)
    }
    static func fetchDaily(pointerURL: String,testingSession: URLSession?) async throws -> Data {
        let url=try ContentUpdateRules.https(pointerURL)
        let config=URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest=30;config.timeoutIntervalForResource=90
        config.httpCookieStorage=nil;config.urlCredentialStorage=nil
        let session=testingSession ?? URLSession(configuration:config,delegate:HTTPSRedirects(),delegateQueue:nil)
        defer {session.invalidateAndCancel()}
        let pointer=try JSONDecoder().decode(DailyChallengePointer.self,from:await read(url,limit:64*1024,session:session))
        let data=try await read(pointer.contentURL(relativeTo:url),limit:ContentUpdateRules.maximumBytes,session:session)
        _ = try pointer.verify(data)
        return data
    }
    private static func read(_ url: URL,limit: Int,session: URLSession) async throws -> Data {
        let (stream,response)=try await session.bytes(from:url)
        guard let http=response as? HTTPURLResponse,http.statusCode == 200,
              let final=response.url,(try? ContentUpdateRules.https(final.absoluteString)) != nil else {
            throw ContentError.invalid("The update server did not return a valid HTTPS lesson file.")
        }
        guard response.expectedContentLength <= Int64(limit) else {throw ContentError.invalid("The update download is too large.")}
        var data=Data()
        for try await byte in stream {
            try Task.checkCancellation()
            guard data.count < limit else {throw ContentError.invalid("The update download is too large.")}
            data.append(byte)
        }
        return data
    }
}

public enum ContentImport {
    public static func read(_ file: URL) throws -> Data {
        let scoped=file.startAccessingSecurityScopedResource()
        defer {if scoped {file.stopAccessingSecurityScopedResource()}}
        let handle=try FileHandle(forReadingFrom:file);defer {try? handle.close()}
        var data=Data()
        while true {
            try Task.checkCancellation()
            guard let chunk=try handle.read(upToCount:64*1024),!chunk.isEmpty else {break}
            guard data.count+chunk.count <= ContentUpdateRules.maximumBytes else {throw ContentError.invalid("This lesson file is too large.")}
            data.append(chunk)
        }
        return data
    }
}
