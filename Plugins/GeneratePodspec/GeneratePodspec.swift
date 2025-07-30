import PackagePlugin
import Foundation

extension URL {
    init(checkingAmbiguousFilePath path: String, relativeTo base: URL? = nil) {
        self = URL(filePath: path, directoryHint: .inferFromPath, relativeTo: base)
        if !hasDirectoryPath {
            self = URL(filePath: path, directoryHint: .checkFileSystem)
        }
    }
}

@main
struct GeneratePodspec: CommandPlugin {
    func performCommand(context: PackagePlugin.PluginContext, arguments: [String]) async throws {
        var argExtractor = ArgumentExtractor(arguments)

        guard let podVersion = argExtractor.extractOption(named: "version").first else {
            fatalError("--version option is required")
        }
        guard let sourceHTTP = argExtractor.extractOption(named: "url").first else {
            fatalError("--url option is required")
        }
        guard let sourceChecksum = argExtractor.extractOption(named: "checksum").first else {
            fatalError("--checksum option is required")
        }
        guard let muxCoreVersion = argExtractor.extractOption(named: "core-version").first else {
            fatalError("--core-version option is required")
        }
        guard let outputURLOrDirectory = argExtractor.extractOption(named: "output").first
            .map({ URL(checkingAmbiguousFilePath: $0) }) else {
            fatalError("--output option must be a local path")
        }
        let outputURL = outputURLOrDirectory.hasDirectoryPath
            ? outputURLOrDirectory.appending(path: "Mux-Stats-AVPlayer.podspec")
            : outputURLOrDirectory

        let iOSDeploymentTarget = "12.0"
        let tvOSDeploymentTarget = "12.0"
        let visionOSDeploymentTarget = "1.0"

        let podspec = """
            Pod::Spec.new do |s|
              s.name             = 'Mux-Stats-AVPlayer'

              s.version          = '\(podVersion)'
              s.source           = { :http => '\(sourceHTTP)',
                                     :sha256 => '\(sourceChecksum)' }

              s.summary          = 'The Mux Stats SDK'
              s.description      = 'The Mux Stats SDK connects AVPlayer to performance analytics and QoS monitoring for video.'

              s.homepage         = 'https://mux.com'
              s.social_media_url = 'https://twitter.com/muxhq'

              s.license          = 'Apache 2.0'
              s.author           = { 'Mux' => 'ios-sdk@mux.com' }

              s.dependency 'Mux-Stats-Core', '\(muxCoreVersion)'

              s.ios.deployment_target = '\(iOSDeploymentTarget)'
              s.tvos.deployment_target = '\(tvOSDeploymentTarget)'
              s.visionos.deployment_target = '\(visionOSDeploymentTarget)'

              s.vendored_frameworks = 'MUXSDKStats.xcframework'
            end
            
            """

        try podspec.write(to: outputURL, atomically: false, encoding: .utf8)

        print("Podspec written to \(outputURL.path())")
    }
}
