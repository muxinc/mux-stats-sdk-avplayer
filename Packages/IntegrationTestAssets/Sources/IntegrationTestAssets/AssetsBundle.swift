import Foundation

public struct IntegrationTestAssets {
    public static var assetsPath: String {
        #if SWIFT_PACKAGE
            // Find the bundle containing this file
            let bundle = Bundle(for: BundleToken.self)
            
            // First try to find as a resource
            if let resourcePath = bundle.path(forResource: "assets", ofType: nil) {
                return resourcePath
            }
            
            // Look in the bundle's resource path directly
            if let resourceURL = bundle.resourceURL {
                let assetsURL = resourceURL.appendingPathComponent("assets")
                if FileManager.default.fileExists(atPath: assetsURL.path) {
                    return assetsURL.path
                }
            }
            
            // Look in the bundle path directly
            let assetsURL = bundle.bundleURL.appendingPathComponent("assets")
            if FileManager.default.fileExists(atPath: assetsURL.path) {
                return assetsURL.path
            }
            
            fatalError("Could not find assets directory in package bundle. Tried resource path and bundle path")
        #else
            // Fallback for other build systems
            guard let bundle = Bundle(identifier: "IntegrationTestAssets"),
                  let resourcePath = bundle.path(forResource: "assets", ofType: nil) else {
                fatalError("Could not find assets directory")
            }
            return resourcePath
        #endif
    }
}

// Private class to get the bundle containing this file (needed for fallback)
private class BundleToken {} 