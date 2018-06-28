# mux-stats-sdk-avplayer

## How to release
* Bump versions in MUXSDKStats.info, MUXSDKStatsTv.info, and Mux-Stats-SDK.podspec
* Execute `update-release-frameworks.sh` to make a full build
* Github - Create a PR to check in all changed files.
* If approved, `git tag [YOUR NEW VERSION]` and `git push --tags`
* Github - Make a new release with the new version
* Cocoapod - Run `pod spec lint` to local check pod validity
* Cocoapod - Run `pod trunk push Mux-Stats-SDK.podspec`
