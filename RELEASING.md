# Releasing Mux Data for AVPlayer

This guide describes the maintainer release process for this SDK. The flow is
**tag-driven**: a release branch validates the change, and the `vX.Y.Z` tag
publishes it.

## How To Use This Guide

- This runbook is the execution procedure for an AI agent preparing or
  publishing a release. Follow the sections in order.
- A condensed human quick-reference is maintained separately. Do not
  reintroduce it here.
- Keep this file public-safe. Do not add internal documentation URLs, private
  repository names, team-only links, credentials, or screenshots.

## How Distribution Works

Swift Package Manager and CocoaPods publish from the same `vX.Y.Z` tag:

- The **release branch** `releases/vX.Y.Z` carries the version bump and runs
  the release validation (version check, changelog, full SPM test, pod lint)
  on its PR — before anything is published.
- When that PR merges to `master`, `.github/workflows/tagged-release-pr.yml`
  (GitHub) **creates the `vX.Y.Z` tag** on the merge commit **and the draft
  GitHub release** (notes taken from the PR body). GitHub owns the release object.
- The tag drives the rest:
  - Swift Package Manager resolves the version directly from the tag.
  - **Buildkite builds the tag.** The tag-only `Publish Release Artifacts`
    step runs `scripts/build-pod.sh` (signed xcframework, zip, podspec) then
    `scripts/publish-release.sh`, which **verifies and uploads** the artifacts
    to that draft release. Buildkite owns the binaries.
- A maintainer reviews the draft release and **publishes it manually**.
- CocoaPods is published manually after the release is public, by running
  `pod trunk push Mux-Stats-AVPlayer.podspec`.

The release version must stay in sync across:

- `scripts/MUXSDKStatsFramework.xcconfig` - `MARKETING_VERSION`
- `Sources/MUXSDKStats/MUXSDKPlayerBinding.m` - `MUXSDKPluginVersion`
- the release branch name, the PR, and the `vX.Y.Z` tag

The MuxCore dependency version must stay consistent across:

- `Package.swift`
- `scripts/build-pod.sh` - `MUXCORE_VERSION`

`scripts/build-pod.sh` generates these release artifacts:

- `Cocoapods-Mux-Stats-AVPlayer.zip`
- `Mux-Stats-AVPlayer.podspec`

## Infrastructure Prerequisites

These must be true for the automated steps to work. Confirm them once; if any
is missing, stop and ask a maintainer rather than working around it.

- Buildkite is configured to **build tags** for this pipeline.
- The Buildkite macOS agent provides a **GitHub token** in the environment as
  `GITHUB_TOKEN`, scoped to `contents: write` on this repository (a GitHub App
  installation token or fine-grained token — not a personal token), and has
  `gh` on `PATH`.
- CocoaPods trunk access is available locally for the final `pod trunk push`.

## Release Runbook

Follow this section when using an AI agent to prepare or publish a new SDK
version.

### Agent Rules

- Ask for the target version before changing files. Do not infer patch, minor,
  or major unless the maintainer explicitly asks you to.
- Release branches use the `releases/vX.Y.Z` format. Do not use personal or
  agent prefixes for release branches.
- Keep release PRs small. A release PR should only include release metadata
  changes unless the maintainer explicitly includes another release-related
  change.
- Do not paste tokens or credentials into chat. Use existing local auth,
  configured connectors, or MCP access. If access is unavailable, ask for a
  manual handoff instead of asking for secrets.
- GitHub release publishing and CocoaPods publishing are maintainer approval
  points. Stop for approval before publishing the draft release, and before
  `pod trunk push`.
- If CocoaPods asks for registration or email confirmation, stop and report the
  exact prompt. Do not try to bypass the maintainer's email-auth step.
- If validation, merge, tagging, the Buildkite build, the draft release, the
  CocoaPods publish, or docs steps fail, stop and report the failure, the
  command or external step that failed, and the safest next step.
- When asked to continue an interrupted release, inspect the current branch,
  PR, tag, Buildkite build, GitHub release, CocoaPods version, and docs state
  first. Resume from the first incomplete step instead of starting over.

### Prepare The Release PR

1. Confirm the target version with the maintainer.
   - Example: `4.14.0`
   - The release branch and tag will be `releases/v4.14.0` and `v4.14.0`.

2. Verify the intended feature changes are already merged to `master`.
   ```sh
   git fetch origin master --tags
   ```
   Confirm `origin/master` contains the intended release contents.

3. Check the current version and release state.
   ```sh
   git tag --list 'v*' --sort=-version:refname
   gh release list --limit 20
   git show origin/master:scripts/MUXSDKStatsFramework.xcconfig
   git show origin/master:Sources/MUXSDKStats/MUXSDKPlayerBinding.m | grep MUXSDKPluginVersion
   ```

4. Create a release branch from `origin/master`.
   ```sh
   git switch -c releases/vX.Y.Z origin/master
   ```

5. Confirm the MuxCore dependency is consistent.
   - `Package.swift`: points at the intended released MuxCore version.
   - `scripts/build-pod.sh`: `MUXCORE_VERSION` uses the same major/minor line.
   - If `Package.swift` uses a local development dependency, stop and ask.

6. Set the release version with the script (keeps both files in sync):
   ```sh
   scripts/set-version.sh X.Y.Z
   ```
   This updates `MARKETING_VERSION` (`scripts/MUXSDKStatsFramework.xcconfig`) and
   `MUXSDKPluginVersion` (`Sources/MUXSDKStats/MUXSDKPlayerBinding.m`).

7. Confirm the values match.
   ```sh
   grep -n 'MARKETING_VERSION' scripts/MUXSDKStatsFramework.xcconfig
   grep -n 'MUXSDKPluginVersion' Sources/MUXSDKStats/MUXSDKPlayerBinding.m
   ```

8. Validate locally where possible.
   ```sh
   xcrun swift build
   xcrun swift test
   git diff --check
   ```
   Do not claim Buildkite has passed before it has.

9. Commit, push, and open the release PR.
   ```sh
   git add scripts/MUXSDKStatsFramework.xcconfig Sources/MUXSDKStats/MUXSDKPlayerBinding.m
   git commit -m "Version Bump"
   git push -u origin releases/vX.Y.Z
   ```
   - Base: `master`, Head: `releases/vX.Y.Z`, Title: `Releases/vX.Y.Z`.

10. Wait for the changelog workflow to update the PR, then review and curate the
    release notes with the maintainer. On a release branch, Buildkite also runs
    the version check, full SPM test, and pod lint — confirm these pass.

11. Stop until the PR is approved and merged.

### Tag, Build, And Draft (Automated)

Continue only after the release PR is merged to `master`.

1. Merging the `releases/vX.Y.Z` PR triggers
   `.github/workflows/tagged-release-pr.yml`, which creates the `vX.Y.Z` tag on
   the merge commit and the draft GitHub release with notes. Confirm both:
   ```sh
   git fetch origin --tags
   git rev-list -n 1 vX.Y.Z
   gh release view vX.Y.Z --json isDraft,url
   ```

2. The tag triggers the Buildkite `Publish Release Artifacts` step, which builds
   the pod and runs `scripts/publish-release.sh`. That script:
   - verifies the podspec version, the `releases/download/vX.Y.Z` source URL,
     and the zip `:sha256` checksum,
   - uploads `Cocoapods-Mux-Stats-AVPlayer.zip` and
     `Mux-Stats-AVPlayer.podspec` to the draft release (creating the draft only
     as a fallback if the workflow did not), and confirms both are attached.

   If the build fails, summarize the failing step from the Buildkite logs and
   stop for maintainer direction. Do not upload artifacts by hand.

3. Confirm the draft release has both assets.
   ```sh
   gh release view vX.Y.Z --json isDraft,assets,url
   ```

4. Stop for maintainer approval before publishing the GitHub release.

### Publish The GitHub Release

Continue only after the maintainer approves the notes and attached artifacts.

1. Finalize the notes from the draft (the PR body / changelog). Remove internal
   ticket IDs and implementation-only details. If the maintainer edits notes,
   treat the maintainer's version as final.

2. Publish the draft.
   ```sh
   gh release edit vX.Y.Z --title "vX.Y.Z" --notes "<release notes>" --draft=false
   ```

3. Verify.
   ```sh
   gh release view vX.Y.Z --json tagName,isDraft,isPrerelease,assets,url
   git rev-list -n 1 vX.Y.Z
   git rev-parse origin/master
   ```
   Confirm it is published (not a draft), not an unintended prerelease, the tag
   commit matches the merged release commit, and both artifacts are attached.

### Publish CocoaPods

Continue only after the GitHub release is published (the podspec's source zip URL
only resolves once the release is public).

1. Verify trunk access.
   ```sh
   pod trunk me
   ```
   If trunk access is not configured, stop and let a maintainer complete
   CocoaPods registration and email authorization locally.

2. Publish, using the podspec attached to the release.
   ```sh
   gh release download vX.Y.Z --pattern 'Mux-Stats-AVPlayer.podspec'
   pod trunk push Mux-Stats-AVPlayer.podspec
   ```

3. Confirm CocoaPods sees the new version.
   ```sh
   pod trunk info Mux-Stats-AVPlayer
   ```

### Update Public Docs

After the release is published, update public documentation in a separate PR
when release notes or customer-facing behavior require it.

1. Read the final release notes.
   ```sh
   gh release view vX.Y.Z --repo muxinc/mux-stats-sdk-avplayer --json body,url,name,tagName
   ```

2. Update docs when the release changes customer-facing behavior, setup,
   defaults, installation, or API usage; add a changelog post for significant
   updates. If no docs change is needed, report that decision and why.

3. Open the docs PR from the docs repo's default branch and wait for review.

## Common Pitfalls

- Use `scripts/set-version.sh` to bump the version so `MARKETING_VERSION` and
  `MUXSDKPluginVersion` stay in sync; don't edit them by hand.
- Do not leave `Package.swift` pointing at a local development dependency for a
  release PR.
- Do not create a release branch with a personal or agent prefix. Use
  `releases/vX.Y.Z`.
- Do not create the `vX.Y.Z` tag by hand for a normal release; merging the
  release PR creates it. Tagging by hand will start the publish build early.
- Do not upload release artifacts by hand. The tag build attaches them; if it
  fails, fix the build rather than working around it.
- Do not publish the GitHub release before reviewing the attached artifacts.
- Do not run `pod trunk push` before the GitHub release is published — the
  podspec's source URL will not resolve while the release is a draft.
- Do not continue through CocoaPods auth prompts. Stop and let the maintainer
  complete email authorization.
- Do not publish the auto-drafted release notes if a maintainer edited the final notes.
