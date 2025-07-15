import Foundation

public struct IntegrationTestAssets {
    public static var assetsPath: String {
        #if SWIFT_PACKAGE
            // When built as a Swift Package, find the bundle containing this file
            let bundle = Bundle(for: BundleToken.self)
            guard let resourcePath = bundle.path(forResource: "assets", ofType: nil) else {
                fatalError("Could not find assets directory in package bundle")
            }
            return resourcePath
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

// Private class to get the bundle containing this file
private class BundleToken {} 