import Foundation

public struct IntegrationTestAssets {
    public static var assetsPath: String {
        
        if let resourceURL = Bundle.module.resourceURL {
            let assetsURL = resourceURL.appendingPathComponent("assets")
            if FileManager.default.fileExists(atPath: assetsURL.path) {
                return assetsURL.path
            }
        }
        
        // Also try as a resource
        if let resourcePath = Bundle.module.path(forResource: "assets", ofType: nil) {
            return resourcePath
        }
        
        fatalError("Could not find assets directory in package bundle. ")
    }
}

// Private class to get the bundle containing this file (needed for fallback)
private class BundleToken {}
