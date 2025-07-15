import Foundation
import Swifter
import AVFoundation
import IntegrationTestAssets

public class MockHLSServer {
    private let server = HttpServer()
    private var isRunning = false
    private var port: UInt16 = 0
    
    public init() {
        if #available(iOS 13.4, *) {
            setupRoutes()
        } else {
            // Fallback
        }
    }
    
    public var baseURL: String {
        return "http://localhost:\(port)"
    }
    
    public func start() throws {
        port = UInt16.random(in: 8080...9000)
        try server.start(port)
        isRunning = true
        print("MockHLSServer started on port \(port)")
    }
    
    public func stop() {
        server.stop()
        isRunning = false
        print("MockHLSServer stopped")
    }
    
    @available(iOS 13.4, *)
    private func setupRoutes() {
        
        server.GET["/sanity-check"] = { [weak self] request in
            guard let _ = self else { return .internalServerError }
            return HttpResponse.ok(.text("Works!"))
        }
        
        // Dynamic segment routing for testing failures
        server["/not-found"] = { request in
            let segmentPath = request.path.replacingOccurrences(of: "/not-found/", with: "")
            print("404 -> \(segmentPath)")
            return HttpResponse.notFound
        }
        
        server["/unauthorized"] = { request in
            return HttpResponse.raw(401, "Unauthorized", [:]) { _ in }
        }
        
        // Playlist endpoints with working segments
        server.GET["/normal-playlist.m3u8"] = { [weak self] request in
            guard let self = self else { return .internalServerError }
            let content = self.normalVariantPlaylist(quality: "normal")
            return .ok(.text(content))
        }
        
        // Playlist endpoints that use failing segments
        server.GET["/failing-playlist.m3u8"] = { [weak self] request in
            guard let self = self else { return .internalServerError }
            let content = self.failingVariantPlaylist(quality: "failing")
            return .ok(.text(content))
        }
        
        // Proxy endpoint
        server.GET["/proxy"] = { request in
            let proxyPath = request.path.replacingOccurrences(of: "/proxy/", with: "")
            
            guard let proxyHost = request.queryParams.first(where: { $0.0 == "proxyHost" })?.1 else {
                return .badRequest(.text("Missing proxyHost parameter"))
            }
            
            let targetURL = "https://\(proxyHost)/\(proxyPath)"
            print("Proxying: \(request.path) -> \(targetURL)")
            
            guard let url = URL(string: targetURL) else {
                return .badRequest(.text("Invalid target URL"))
            }
            
            let semaphore = DispatchSemaphore(value: 0)
            let resultContainer = NSMutableArray()
            
            URLSession.shared.dataTask(with: url) { data, response, error in
                defer { semaphore.signal() }
                
                let httpResponse: HttpResponse
                
                if let error = error {
                    print("Proxy error: \(error)")
                    httpResponse = .internalServerError
                } else if let httpResp = response as? HTTPURLResponse,
                          let data = data {
                    
                    print("Proxy success: \(httpResp.statusCode)")
                    
                    if httpResp.statusCode == 200 {
                        let contentType = httpResp.allHeaderFields["Content-Type"] as? String ?? "application/octet-stream"
                        
                        if contentType.contains("text") || contentType.contains("application/vnd.apple.mpegurl") {
                            if let textContent = String(data: data, encoding: .utf8) {
                                httpResponse = .ok(.text(textContent))
                            } else {
                                httpResponse = .ok(.data(data))
                            }
                        } else {
                            httpResponse = .ok(.data(data))
                        }
                    } else {
                        print("HTTP error: \(httpResp.statusCode)")
                        switch httpResp.statusCode {
                        case 404: httpResponse = .notFound
                        case 500: httpResponse = .internalServerError
                        case 400: httpResponse = .badRequest(.text("HTTP Error \(httpResp.statusCode)"))
                        default: httpResponse = .internalServerError
                        }
                    }
                } else {
                    httpResponse = .internalServerError
                }
                
                resultContainer.add(httpResponse)
            }.resume()
            
            let timeout = DispatchTime.now() + .seconds(10)
            if semaphore.wait(timeout: timeout) == .timedOut {
                return .internalServerError
            }
            
            return resultContainer.firstObject as? HttpResponse ?? .internalServerError
        }
        
        // Fallback route
        server.notFoundHandler = { [weak self] request in
            guard let self = self else { return .internalServerError }
            
            let fullPath = request.path
            
            // Remove leading slash and any route prefixes
            var cleanPath = fullPath.hasPrefix("/") ? String(fullPath.dropFirst()) : fullPath
            
            if cleanPath.hasPrefix("normal/") {
                cleanPath = String(cleanPath.dropFirst(7))
            }
            
            // Prevent directory traversal attacks
            let safePath = cleanPath
                .split(separator: "/")
                .filter { !$0.contains("..") }
                .joined(separator: "/")
            
            let assetsPath = IntegrationTestAssets.assetsPath
            let filePath = "\(assetsPath)/\(safePath)"
            
            if FileManager.default.fileExists(atPath: filePath) {
                do {
                    let fileData = try Data(contentsOf: URL(fileURLWithPath: filePath))
                    
                    let contentType: String
                    if safePath.hasSuffix(".m3u8") {
                        contentType = "application/vnd.apple.mpegurl"
                    } else if safePath.hasSuffix(".ts") {
                        contentType = "video/MP2T"
                    } else if safePath.hasSuffix(".m4s") || safePath.hasSuffix(".mp4") {
                        contentType = "video/mp4"
                    } else if safePath.hasSuffix(".key") {
                        contentType = "application/octet-stream"
                    } else {
                        contentType = "application/octet-stream"
                    }
                    
                    return HttpResponse.raw(200, "OK", ["Content-Type": contentType]) { writer in
                        try writer.write(fileData)
                    }
                } catch {
                    print("Error reading file \(filePath): \(error)")
                    return HttpResponse.notFound
                }
            } else {
                print("File not found: \(filePath)")
                return HttpResponse.notFound
            }
        }
    }
    
    // Generate playlist with segments that will work
    private func normalVariantPlaylist(quality: String) -> String {
        let segments = (0..<10).map { i in
            "#EXTINF:10.0,\n\(baseURL)/normal/segments/\(i).ts"
        }.joined(separator: "\n")
        
        return """
        #EXTM3U
        #EXT-X-VERSION:3
        #EXT-X-TARGETDURATION:10
        #EXT-X-MEDIA-SEQUENCE:0
        \(segments)
        #EXT-X-ENDLIST
        """
    }
    
    // Generate playlist with segments that will fail 
    private func failingVariantPlaylist(quality: String) -> String {
        let segments = (0..<10).map { i in
            "#EXTINF:10.0,\n\(baseURL)/not-found/segment\(i).ts"
        }.joined(separator: "\n")
        
        return """
        #EXTM3U
        #EXT-X-VERSION:3
        #EXT-X-TARGETDURATION:10
        #EXT-X-MEDIA-SEQUENCE:0
        \(segments)
        #EXT-X-ENDLIST
        """
    }
}

// MARK: - Test Helper Extensions
extension MockHLSServer {
    public func forPath(_ path: String) -> String {
        return "\(baseURL)/\(path)"
    }
    
    // Get URL for fatal error testing
    public var errorURL: String {
        return "\(baseURL)/error/404.m3u8"
    }
    
    // Playlist with segments that will work (return 200)
    public var normalSegmentsURL: String {
        return "\(baseURL)/segments/index.m3u8"
    }
    
    // Playlist with segments that will fail (return 404)
    public var failingSegmentsURL: String {
        return "\(baseURL)/failing-playlist.m3u8"
    }
    
    // Direct segment URLs for testing
    public func normalSegmentURL(_ segmentName: String) -> String {
        return "\(baseURL)/normal/\(segmentName)"
    }
    
    public func failingSegmentURL(_ segmentName: String) -> String {
        return "\(baseURL)/not-found/\(segmentName)"
    }
    
    // Proxy URL helper
    public func proxyURL(path: String, host: String) -> String {
        return "\(baseURL)/proxy/\(path)?proxyHost=\(host)"
    }
} 
