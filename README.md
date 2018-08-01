# mux-stats-sdk-avplayer

Mux integration with `AVPlayer` and `AVPlayerLayer` for iOS native applications.

This integration is built on top of [Mux's core Objective-C library](), allowing thinner wrappers for each new player, such as any third-party players that do not use (or expose) an underlying `AVPlayer` and/or `AVPlayerLayer`.

## Integration Instructions
Full integration instructions can be found here: https://docs.mux.com/docs/ios-integration-guide.

## How to release
* Bump versions in MUXSDKStats.info, MUXSDKStatsTv.info, and Mux-Stats-SDK.podspec
* Execute `update-release-frameworks.sh` to make a full build
* Github - Create a PR to check in all changed files.
* If approved, `git tag [YOUR NEW VERSION]` and `git push --tags`
* Github - Make a new release with the new version
* Cocoapod - Run `pod spec lint` to local check pod validity
* Cocoapod - Run `pod trunk push Mux-Stats-AVPlayer.podspec`

* To support Carthage framework management,
* After the `update-release-frameworks.sh` build, run carthage-archive.sh.
* Then attach the output to the release

## Sample apps
* apps/DemoApp - Objective C demo
* apps/video-demo - Swift demo
* apps/TvDemoApp - Apple TV demo
