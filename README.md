# mux-stats-sdk-avplayer

Mux integration with `AVPlayer` and `AVPlayerLayer` for iOS native applications.

This integration is built on top of [Mux's core Objective-C library](https://github.com/muxinc/stats-sdk-objc), allowing thinner wrappers for each new player, such as any third-party players that do not use (or expose) an underlying `AVPlayer` and/or `AVPlayerLayer`.

## Integration Instructions
Full integration instructions can be found here: https://docs.mux.com/docs/avplayer-integration-guide.

## How to release
* Bump version in Mux-Stats-AVPlayer.podspec
* Bump version in MUXSDKStats/MUXSDKStats/Info.plist
* Bump version in MUXSDKStats/MUXSDKStatsTv/Info.plist
* Bump version in MUXSDKStats/MUXSDKStats/MUXSDKPlayerBinding.m
* Execute `update-release-frameworks.sh` to make a full build
* Github - Create a PR to check in all changed files.
* If approved, `git tag [YOUR NEW VERSION]` and `git push --tags`
* Github - Make a new release with the new version
* Cocoapod - Run `pod spec lint` to local check pod validity
* Cocoapod - Run `pod trunk push Mux-Stats-AVPlayer.podspec`

* To support Carthage framework management,
* After the `update-release-frameworks.sh` build, run carthage-archive.sh.
* Then attach the output to the release
* Update the release notes in the [AVPlayer Integration Guide](https://docs.mux.com/docs/avplayer-integration-guide)
* If you added new methods then document them in the AVPlayer Integration Guide
* Update the sample apps in this repo to pull in the latest versions of our libraries

## Sample apps
* apps/DemoApp - Objective C demo
* apps/video-demo - Swift demo
* apps/TvDemoApp - Apple TV demo
