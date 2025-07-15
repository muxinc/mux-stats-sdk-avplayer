import Foundation

public struct IntegrationTestAssets {
    public static var assetsPath: String {
        #if SWIFT_PACKAGE
            // When built as a Swift Package, use Bundle.module
            guard let resourcePath = Bundle.module.path(forResource: "assets", ofType: nil) else {
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