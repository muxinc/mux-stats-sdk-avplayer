## How to release
1. Bump versions in Mux-Stats-AVPlayer.podspec
1. Bump version in XCode "General" for target: MUXSDKStats
1. Bump version in XCode "General" for target: MUXSDKStatsTv
1. Bump version in MUXSDKStats/MUXSDKStats/MUXSDKPlayerBinding.m
1. Execute `update-release-xcframeworks.sh` to make a full build
1. Github - Create a PR to check in all changed files.
1. If approved, squash & merge into master
1. Pull master locally and `git tag [YOUR NEW VERSION]` and `git push --tags`
1. Cocoapod - Run `pod spec lint` to local check pod validity
1. Cocoapod - Run `pod trunk push Mux-Stats-AVPlayer.podspec`
1. Github UI - Make a new release with the new version. Run `zip -r XCFramework.zip XCFramework` and attach the zip file to the Github release
1. Update the release notes in the [AVPlayer Integration Guide](https://docs.mux.com/docs/avplayer-integration-guide)

After release:

* Try the new version to the sample apps in this repo.

