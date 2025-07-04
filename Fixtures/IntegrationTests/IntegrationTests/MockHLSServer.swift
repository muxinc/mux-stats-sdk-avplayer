import Foundation
import Swifter
import AVFoundation

class MockHLSServer {
    private let server = HttpServer()
    private var isRunning = false
    private var port: UInt16 = 0
    
    init() {
        setupRoutes()
    }
    
    var baseURL: String {
        return "http://localhost:\(port)"
    }
    
    func start() throws {
        port = UInt16.random(in: 8080...9000)
        try server.start(port)
        isRunning = true
        print("MockHLSServer started on port \(port)")
    }
    
    func stop() {
        server.stop()
        isRunning = false
        print("MockHLSServer stopped")
    }
    
    private func setupRoutes() {
        // Dynamic segment routing for testing
        server.GET["/not-found/:segment"] = { request in
            let segmentPath = request.params[":segment"] ?? "unknown"
            print("404 -> \(segmentPath)")
            return .notFound
        }
        
        server.GET["/normal/:segment"] = { [weak self] request in
            let segmentPath = request.params[":segment"] ?? "unknown"
            print("200 -> \(segmentPath)")
            
            guard let self = self else { return .internalServerError }
            let segmentData = self.mockSegmentData()
            return .ok(.data(segmentData))
        }
        
        // Playlist endpoints that use normal (working) segments
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
        
        // Proxy endpoint - using synchronous URLSession
        server.GET["/proxy/:proxyPath"] = { request in
            let proxyPath = request.params[":proxyPath"] ?? ""
            
            // Query parameters
            guard let proxyHost = request.queryParams.first(where: { $0.0 == "proxyHost" })?.1 else {
                return .badRequest(.text("Missing proxyHost parameter"))
            }
            
            // Build target URL
            let targetURL = "https://\(proxyHost)/\(proxyPath)"
            print("Proxying: \(request.path) -> \(targetURL)")
            
            guard let url = URL(string: targetURL) else {
                return .badRequest(.text("Invalid target URL"))
            }
            
            // Use synchronous request to avoid concurrency issues
            let semaphore = DispatchSemaphore(value: 0)
            let resultContainer = NSMutableArray() // Thread-safe container
            
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
    }
    
    // Generate playlist with segments that will work
    private func normalVariantPlaylist(quality: String) -> String {
        let segments = (0..<10).map { i in
            "#EXTINF:10.0,\n\(baseURL)/normal/segment\(i).ts"
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
    
    private func mockSegmentData() -> Data {
        // Return minimal valid MPEG-TS data
        let mockBytes: [UInt8] = [
            0x47, 0x40, 0x00, 0x10, // TS sync byte and header
            0x00, 0x00, 0x01, 0xe0, // Start of PES packet
        ]
        return Data(mockBytes + Array(repeating: 0x00, count: 1000)) // Pad to reasonable size
    }
}

// MARK: - Test Helper Extensions
extension MockHLSServer {
    
    // Get URL for fatal error testing
    var errorURL: String {
        return "\(baseURL)/error/404.m3u8"
    }
    
    // Playlist with segments that will work (return 200)
    var normalSegmentsURL: String {
        return "\(baseURL)/normal-playlist.m3u8"
    }
    
    // Playlist with segments that will fail (return 404)
    var failingSegmentsURL: String {
        return "\(baseURL)/failing-playlist.m3u8"
    }
    
    // Direct segment URLs for testing
    func normalSegmentURL(_ segmentName: String) -> String {
        return "\(baseURL)/normal/\(segmentName)"
    }
    
    func failingSegmentURL(_ segmentName: String) -> String {
        return "\(baseURL)/not-found/\(segmentName)"
    }
    
    // Proxy URL helper
    func proxyURL(path: String, host: String) -> String {
        return "\(baseURL)/proxy/\(path)?proxyHost=\(host)"
    }
} 
