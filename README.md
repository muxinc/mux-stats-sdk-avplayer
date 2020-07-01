# mux-stats-sdk-avplayer

Mux integration with `AVPlayer` and `AVPlayerLayer` for iOS native applications.

This integration is built on top of [Mux's core Objective-C library](https://github.com/muxinc/stats-sdk-objc), allowing thinner wrappers for each new player, such as any third-party players that do not use (or expose) an underlying `AVPlayer` and/or `AVPlayerLayer`.

## Integration Instructions
Full integration instructions can be found here: https://docs.mux.com/docs/avplayer-integration-guide.

## How to release
1. Bump versions in Mux-Stats-AVPlayer.podspec
1. Bump version in MUXSDKStats/MUXSDKStats/Info.plist
1. Bump version in MUXSDKStats/MUXSDKStatsTv/Info.plist
1. Bump version in MUXSDKStats/MUXSDKStats/MUXSDKPlayerBinding.m
1. Execute `update-release-frameworks.sh` to make a full build
1. Github - Create a PR to check in all changed files.
1. If approved, squash & merge into master
1. Pull master locally and `git tag [YOUR NEW VERSION]` and `git push --tags`
1. Cocoapod - Run `pod spec lint` to local check pod validity
1. Cocoapod - Run `pod trunk push Mux-Stats-AVPlayer.podspec`
1. Github UI - Make a new release with the new version
1. Update the release notes in the [AVPlayer Integration Guide](https://docs.mux.com/docs/avplayer-integration-guide)

Create Carthage framework:

1. Run `./carthage-archive.sh` and attach the generated .zip file to the release.
1. Delete the generate .zip file after uploading

After release:

* Try the new version to the sample apps in this repo.

## Sample apps
* apps/DemoApp - Objective C demo
* apps/video-demo - Swift demo
* apps/TvDemoApp - Apple TV demo
