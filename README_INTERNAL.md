## How to release
1. Starting from the release branch you've been merging to (eg, `releases/v4.4.1`)
1. Bump versions in Mux-Stats-AVPlayer.podspec
1. Bump version in XCode "General" for target: MUXSDKStats
1. Bump version in XCode "General" for target: MUXSDKStatsTv
1. Bump version in MUXSDKStats/MUXSDKStats/MUXSDKPlayerBinding.m
1. Bump version in Package.swift (if the dependency on Mux-Stats-Core has changed)
1. Update the version and url in project specification file MUXSDKStats.json for Carthage
1. Push to your feature branch in Github
1. Download artifact from the Build step of the [Buildkite pipeline](https://buildkite.com/mux/stats-sdk-avplayer).
![Screen Shot 2021-04-13 at 8 27 29 PM](https://user-images.githubusercontent.com/1444681/114637753-14089180-9c98-11eb-87df-05e894d066d9.png) Make sure this is from the latest commit on your branch. 
1. Unzip the file and copy the resulting `MUXSDKStats.xcframework` into `XCFramework`and commit this.
4. Github - Create a PR to check in all changed files.
5. If approved, squash & merge into master
6. Pull master locally and `git tag [YOUR NEW VERSION]` and `git push --tags`
7. Cocoapod - Run `pod spec lint` to local check pod validity
8. Cocoapod - Run `pod trunk push Mux-Stats-AVPlayer.podspec`
9. Github UI - Make a new release with the new version. Attach the XCFramework artifacts from the automated build to the release.
10. Update the release notes in the [AVPlayer Integration Guide](https://docs.mux.com/docs/avplayer-integration-guide)

After release:

* Try the new version to the sample apps in this repo.

