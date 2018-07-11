# mux-stats-sdk-avplayer

Mux integration with `AVPlayer` and `AVPlayerLayer` for iOS native applications.

This integration is built on top of [Mux's core Objective-C library](), allowing thinner wrappers for each new player, such as any third-party players that do not use (or expose) an underlying `AVPlayer` and/or `AVPlayerLayer`.

## Integration Instructions
Full integration instructions can be found here: https://docs.mux.com/docs/ios-integration-guide.

## Quick Start
### Installing via CocoaPods (preferred)
To install with CocoaPods, modify your Podfile to use frameworks by including `use_frameworks!` and then add the following pod:
 - `pod "Mux-Stats-AVPlayer", "~> 0.1"`
This will use our current release, which is version 0.1.0. There will no be API breaking changes within our 0.1.x releases, so you can safely run pod update.

### Installing Manually
To install manually, include the correct Mux AVPlayer SDK for your project by cloning our repository and dragging the framework into your Xcode project. The Frameworks folder contains two folders, one for iOS and one for tvOS. Inside these folders, there are 3 additional folders containing different architecture combinations. The fat folder contains a library with all architectures in one.

You can use the fat library when developing but this library cannot be used when compiling for submission to the App Store as it contains the simulator architectures that are not used by any Apple devices (the community believes [this is a bug](http://www.openradar.me/radar?id=6409498411401216)). You can use the framework in the release folder when building a release version of your application, or you can run a [script to strip unneeded architectures](https://gist.github.com/brett-stover-hs/b25947a125ff7e38e7ca#file-frameworks_blogpost_removal_script_a-sh).

### Add the Mux Data Monitor
```objective-c
// For iOS, use the following
@import MUXSDKStats;

// For tvOS, use the following instead
@import MUXSDKStatsTv;
```
To monitor the performance of an `AVPlayer`, call either `monitorAVPlayerViewController:withPlayerName:playerData:videoData:` or `monitorAVPlayerLayer:withPlayerName:playerData:videoData:`, passing a pointer to your `AVPlayer` container (either the `AVPlayerLayer` or `AVPlayerViewController`) to the SDK. The `playerName` parameter passed can be any string identifier for this instance of your player. When calling `destroyPlayer` or `videoChangeForPlayer:withVideoData:` to change the video, the same player name used for the monitor call must be used.

```objective-c
// Property and player data that persists until the player is destroyed
MUXSDKCustomerPlayerData *playerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:@"EXAMPLE_ENV_KEY"];
// ...insert player metadata

// Video metadata (cleared with videoChangeForPlayer:withVideoData:)
MUXSDKCustomerVideoData *videoData = [MUXSDKCustomerVideoData new];
// ...insert video metadata

AVPlayerLayer *player = [AVPlayerLayer new];
[MUXSDKStats monitorAVPlayerViewController:player withPlayerName:@"awesome" playerData:playerData videoData:videoData];
```

### Test It
After you've integrated, start playing a video in the player you've integrated with. A few minutes after you stop watching, you'll see the results in your Mux account. We'll also email you when your first video view has been recorded.

You can also test that Mux is receiving data in the Mux Data dashboard. Login to the dashboard and find the environment that corresponds to your `env_key` and look for video views.

Note that it may take a few minutes for views to show up in the Mux Data dashboard.

## Full Documentation
The full documentation on using this library, including metadata configuration and additional methods used for destroying player monitors or changing videos can be found here: https://docs.mux.com/docs/ios-integration-guide.

## How to release
* Bump versions in MUXSDKStats.info, MUXSDKStatsTv.info, and Mux-Stats-SDK.podspec
* Execute `update-release-frameworks.sh` to make a full build
* Github - Create a PR to check in all changed files.
* If approved, `git tag [YOUR NEW VERSION]` and `git push --tags`
* Github - Make a new release with the new version
* Cocoapod - Run `pod spec lint` to local check pod validity
* Cocoapod - Run `pod trunk push Mux-Stats-AVPlayer.podspec`


## Sample apps
* apps/DemoApp - Objective C demo
* apps/video-demo - Swift demo
* apps/TvDemoAPp - Apple TV demo
