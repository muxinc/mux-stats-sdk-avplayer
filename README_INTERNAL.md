## How to release
1. Starting from the release branch you've been merging to (eg, `releases/v4.4.1`)
2. Bump versions in Mux-Stats-AVPlayer.podspec
3. Bump version in Xcode "General" for target: MUXSDKStats
4. Bump version in Xcode "General" for target: MUXSDKStatsTv
5. Bump version in MUXSDKStats/MUXSDKStats/MUXSDKPlayerBinding.m
6. Bump version in Package.swift (if the dependency on Mux-Stats-Core has changed)
7. Update the version and url in project specification file MUXSDKStats.json for Carthage
8. Push to your release branch in Github
9. Wait for automated tests and validation to pass
10. Download artifact from the Build step of the `build` GitHub Action. Make sure this is from the latest commit on your branch. 
11. Unzip the file and copy the resulting `MUXSDKStats.xcframework` into `XCFramework`and commit this.
12. Github - Create a PR to check in all changed files.
13. If approved, squash & merge into master
14. A GitHub action will create a draft release
15. Update release notes on draft release if necessary
16. Update the release with zipped files prepared in the `build-static` and `build` GitHub actions
17. Publish the release
18. Cocoapod - Run `pod spec lint` to local check pod validity (Can be skipped, linted by CI)
19. Cocoapod - Run `pod trunk push Mux-Stats-AVPlayer.podspec`
20. Github UI - Make a new release with the new version. Attach the XCFramework artifacts from the automated build to the release.
21. Update the release notes in the [AVPlayer Integration Guide](https://docs.mux.com/docs/avplayer-integration-guide)

After release:

* Try the new version with the sample apps in this repo.

