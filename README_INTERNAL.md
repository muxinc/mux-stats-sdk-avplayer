## How to release
1. Starting from the release branch you've been merging to (eg, `releases/v4.4.1`)
2. Bump versions in Mux-Stats-AVPlayer.podspec
3. Bump version in MUXSDKStats/MUXSDKStats/MUXSDKPlayerBinding.m
4. Bump version in Package.swift (if the dependency on Mux-Stats-Core has changed)
5. Push to your release branch in Github
6. Wait for automated tests and validation to pass
7. Github - Create a PR to check in changes on the release branch
8. If approved, squash & merge into master
9. A GitHub action will create a draft release
10. Update release notes on draft release if necessary
11. Publish the release
12. Cocoapod - Run `pod spec lint` to local check pod validity (Can be skipped, linted by CI)
13. Cocoapod - Run `pod trunk push Mux-Stats-AVPlayer.podspec`
14. Publish the draft release on GitHub
15. Update the release notes in the [AVPlayer Integration Guide](https://docs.mux.com/docs/avplayer-integration-guide)

After release:

* Try the new version with the sample apps in this repo.

