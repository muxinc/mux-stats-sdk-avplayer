# Releasing Mux Data for AVPlayer

This guide describes the current maintainer release process for this SDK.

## How To Use This Guide

- Humans can use the manual checklist for a concise overview of the release
  flow.
- AI agents must follow the agent-assisted runbook. Use the manual checklist as
  summary context, not as the execution procedure.
- Keep this file public-safe. Do not add internal documentation URLs, private
  repository names, team-only links, credentials, or screenshots.

## How Distribution Works

Swift Package Manager and CocoaPods use different publish paths:

- Swift Package Manager resolves versions from Git tags. Once `vX.Y.Z` exists
  on GitHub, SwiftPM clients can resolve that version.
- The GitHub release is used for release notes, the public tag, and the
  CocoaPods binary artifacts.
- Merging a PR from a `releases/vX.Y.Z` branch triggers
  `.github/workflows/tagged-release-pr.yml`, which creates a draft GitHub
  release for the merged commit.
- Buildkite builds the `releases/vX.Y.Z` branch. The `Build for CocoaPods`
  step runs only on `releases/*` branches and produces the binary zip and
  podspec artifacts used by the GitHub release.
- The manual `Upload Buildkite Release Artifacts` GitHub workflow can download,
  verify, and attach those Buildkite artifacts to the draft GitHub release.
- CocoaPods is published manually after the GitHub release/tag exists by running
  `pod trunk push Mux-Stats-AVPlayer.podspec`.

The release version must stay in sync across:

- `scripts/MUXSDKStatsFramework.xcconfig` - `MARKETING_VERSION`
- `Sources/MUXSDKStats/MUXSDKPlayerBinding.m` - `MUXSDKPluginVersion`
- the release branch name, PR, GitHub release, and Git tag

The MuxCore dependency version must stay consistent across:

- `Package.swift`
- `scripts/build-pod.sh` - `MUXCORE_VERSION`

`scripts/build-pod.sh` generates these release artifacts:

- `Cocoapods-Mux-Stats-AVPlayer.zip`
- `Mux-Stats-AVPlayer.podspec`

## Manual Release Checklist

1. Confirm the target version and verify the intended changes are on `master`.
2. Create `releases/vX.Y.Z` from `origin/master`.
3. Confirm the MuxCore dependency is consistent in `Package.swift` and
   `scripts/build-pod.sh`.
4. Update `MARKETING_VERSION` and `MUXSDKPluginVersion` to `X.Y.Z`.
5. Run validation, commit the release metadata, push the release branch, and
   open a PR into `master`.
6. Review and curate the generated release notes on the release PR.
7. After the release PR is approved, squash and merge it into `master`.
8. Wait for the draft GitHub release and the Buildkite build for the
   `releases/vX.Y.Z` branch.
9. Run the `Upload Buildkite Release Artifacts` GitHub workflow to verify and
   attach the CocoaPods artifacts to the draft GitHub release.
10. Review and publish the GitHub release.
11. Publish CocoaPods with `pod trunk push Mux-Stats-AVPlayer.podspec`.
12. Update public documentation and changelog content when the release changes
    customer-facing behavior, installation, or public API.

## Agent-Assisted Release Runbook

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
- Prefer the `Upload Buildkite Release Artifacts` workflow for artifact
  retrieval, verification, and upload. Use read-only Buildkite MCP access for
  finding release-branch builds and reading logs when available. If Buildkite
  access is unavailable, ask the maintainer for the Buildkite build number or
  URL instead of asking for secrets.
- The current repo workflow creates a draft GitHub release when the release PR
  is merged. Prefer publishing that draft after review. If the workflow fails,
  stop and ask before creating a release manually.
- Let maintainers collaborate on release notes. Draft notes are useful, but do
  not treat generated notes as final if a human edits them.
- GitHub release publishing is a maintainer approval point. Stop for approval
  before publishing the draft release.
- CocoaPods publishing can require trunk authorization. Check authorization
  before publishing. If CocoaPods asks for registration or email confirmation,
  stop and report the exact prompt. Do not try to bypass the maintainer's
  email-auth step.
- For follow-up branches outside this repo, such as documentation site updates,
  use the maintainer's normal team branch convention. Ask if it is not already
  clear. Do not invent agent-specific prefixes for team-visible branches.
- If validation, merge, release, Buildkite artifact retrieval, CocoaPods
  publish, or docs steps fail, stop and report the failure, the command or
  external step that failed, and the safest next step.
- When asked to continue an interrupted release, inspect the current branch, PR,
  tag, GitHub release, Buildkite build, CocoaPods version, and docs state first.
  Resume from the first incomplete step instead of starting over.

### Prepare The Release PR

1. Confirm the target version with the maintainer.
   - Example: `4.12.0`
   - The release branch and tag will be `releases/v4.12.0` and `v4.12.0`.

2. Verify the intended feature changes are already merged to `master`.
   - Check the relevant feature PRs.
   - Fetch the latest master and tags:
     ```sh
     git fetch origin master --tags
     ```
   - Confirm `origin/master` contains the intended release contents.

3. Check the current version and release state.
   ```sh
   git tag --list 'v*' --sort=-version:refname
   gh release list --limit 20
   git show origin/master:scripts/MUXSDKStatsFramework.xcconfig
   git show origin/master:Sources/MUXSDKStats/MUXSDKPlayerBinding.m | grep MUXSDKPluginVersion
   ```
   Confirm the latest Git tag, latest published GitHub release, and checked-in
   version metadata match before bumping.

4. Create a release branch from `origin/master`.
   ```sh
   git switch -c releases/vX.Y.Z origin/master
   ```
   If using a worktree, keep it inside this repository:
   ```sh
   git worktree add <worktree-path> -b releases/vX.Y.Z origin/master
   ```

5. Confirm the MuxCore dependency is consistent.
   - `Package.swift`: confirm the MuxCore dependency points at the intended
     released MuxCore version.
   - `scripts/build-pod.sh`: confirm `MUXCORE_VERSION` uses the same
     major/minor line, for example `~> X.Y`.
   - If `Package.swift` is temporarily using a local development dependency,
     stop and ask before preparing the release PR.

6. Bump release metadata to the same `X.Y.Z` value.
   - `scripts/MUXSDKStatsFramework.xcconfig`: update `MARKETING_VERSION`.
   - `Sources/MUXSDKStats/MUXSDKPlayerBinding.m`: update
     `MUXSDKPluginVersion`.

7. Confirm the release metadata values match.
   ```sh
   grep -n 'MARKETING_VERSION' scripts/MUXSDKStatsFramework.xcconfig
   grep -n 'MUXSDKPluginVersion' Sources/MUXSDKStats/MUXSDKPlayerBinding.m
   ```
   If running in Buildkite on a release branch, `scripts/version-check.sh`
   verifies `MUXSDKPluginVersion` against the branch version.

8. Validate the release branch.
   ```sh
   xcrun swift build
   xcrun swift test
   git diff --check
   ```
   If local Xcode or SwiftPM validation cannot run, report that clearly in the
   PR. Do not pretend Buildkite has passed before it has.

9. Commit the version bump.
   ```sh
   git add scripts/MUXSDKStatsFramework.xcconfig Sources/MUXSDKStats/MUXSDKPlayerBinding.m
   git commit -m "Version Bump"
   ```

10. Push the release branch.
    ```sh
    git push -u origin releases/vX.Y.Z
    ```

11. Open a release PR.
    - Base: `master`
    - Head: `releases/vX.Y.Z`
    - Title: `Releases/vX.Y.Z`
    - Body:
      ```md
      ## Summary
      - bump SDK version from A.B.C to X.Y.Z
      ```

12. Wait for the changelog workflow to update the PR, then review and curate
    the release notes with the maintainer.

13. Stop until the PR is approved and merged.

### Collect Buildkite Artifacts

Continue only after the release PR has been merged to `master`.

1. Fetch the merged master branch and tags.
   ```sh
   git fetch origin master --tags
   ```

2. Identify the merged release commit on `origin/master`.
   ```sh
   git rev-parse origin/master
   ```

3. Wait for the draft GitHub release.
   ```sh
   gh release view vX.Y.Z --json tagName,name,url,targetCommitish,publishedAt,isDraft,isPrerelease
   ```
   Confirm:
   - `tagName` is `vX.Y.Z`.
   - `isDraft` is `true`.
   - `targetCommitish` corresponds to the merged release PR.

4. Find the passed Buildkite build for the `releases/vX.Y.Z` branch.
   - The CocoaPods artifacts are produced by the `Build for CocoaPods` step,
     which runs only on `releases/*` branches.
   - Preferred: use read-only Buildkite MCP to list builds for this pipeline
     and branch.
   - Fallback: ask the maintainer for the Buildkite build number or URL.
   - Do not use a `master` build for CocoaPods artifacts; the artifact step is
     skipped on `master`.
   - If the workflow build-number input is left blank, the artifact workflow
     will use the latest passed Buildkite build for `releases/vX.Y.Z`.

5. Wait for the Buildkite build to pass.
   - The `Build for CocoaPods` step must pass.
   - If the build fails, use available Buildkite logs to summarize the failing
     step and stop for maintainer direction.

6. Run the `Upload Buildkite Release Artifacts` GitHub workflow in dry-run mode
   first.
   - `version`: `vX.Y.Z`
   - `build_number`: the Buildkite build number from the release branch, or
     blank to use the latest passed release-branch build.
   - `upload`: `false`

   The workflow downloads and verifies:
   - `Cocoapods-Mux-Stats-AVPlayer.zip`
   - `Mux-Stats-AVPlayer.podspec`

   It verifies:
   - the podspec version matches `X.Y.Z`
   - the podspec source URL points at `releases/download/vX.Y.Z`
   - the downloaded zip checksum matches the podspec `:sha256`

7. After dry-run passes, run the same workflow with `upload` set to `true`.
   The workflow refuses to upload if the GitHub release is already published,
   then uploads the verified artifacts to the draft release.

8. Verify the draft release includes both assets.
   ```sh
   gh release view vX.Y.Z --json assets,isDraft,url
   ```

9. Stop for maintainer approval before publishing the GitHub release.

### Publish The GitHub Release

Continue only after the maintainer approves the final release notes and attached
artifacts.

1. Prepare final release notes.
   - Start from the release PR body or generated changelog.
   - Focus on customer-visible behavior and API changes.
   - Remove internal ticket IDs, implementation-only notes, and confusing
     generated wording.
   - If the maintainer edits notes in GitHub or another place, use the
     maintainer-edited version as final.

2. Publish the draft GitHub release.
   - The draft may be published in the GitHub UI.
   - Or use the CLI after final notes are approved:
     ```sh
     gh release edit vX.Y.Z \
       --title "vX.Y.Z" \
       --notes "<release notes>" \
       --draft=false
     ```

3. Verify the release and tag.
   ```sh
   git fetch origin master --tags
   gh release view vX.Y.Z --json tagName,name,url,targetCommitish,publishedAt,isDraft,isPrerelease,assets
   git rev-list -n 1 vX.Y.Z
   git rev-parse origin/master
   ```
   Confirm:
   - the release is published, not a draft
   - the release is not marked as a prerelease unless intentional
   - the tag commit matches the merged release PR commit on `origin/master`
   - both CocoaPods artifacts are attached

### Publish CocoaPods

Continue only after the GitHub release and tag exist.

1. Verify the podspec artifact is the one attached to the GitHub release.
   ```sh
   grep -n "s.version" Mux-Stats-AVPlayer.podspec
   grep -n "releases/download/vX.Y.Z" Mux-Stats-AVPlayer.podspec
   ```

2. Verify CocoaPods trunk access.
   ```sh
   pod trunk me
   ```
   If this shows the expected CocoaPods account, continue. If trunk access is
   not configured, stop and let a maintainer complete CocoaPods registration
   and email authorization locally.

3. Publish the pod.
   ```sh
   pod trunk push Mux-Stats-AVPlayer.podspec
   ```

4. Verify CocoaPods sees the new version.
   ```sh
   pod trunk info Mux-Stats-AVPlayer
   ```
   Confirm `X.Y.Z` appears in the published versions.

### Update Public Docs

After the SDK release is published, update public documentation in a separate PR
when release notes or customer-facing behavior require docs changes. Treat this
as part of the release being fully done when docs changes are needed.

1. Read the final GitHub release notes.
   ```sh
   gh release view vX.Y.Z --repo muxinc/mux-stats-sdk-avplayer --json body,url,name,tagName
   ```

2. Decide whether docs need updates.
   - Update docs when the release changes customer-facing behavior, setup,
     defaults, installation, or API usage.
   - Add a changelog post for significant updates or features.
   - If no docs change is needed, report that decision and why.

3. Work in the repository that owns the public documentation site. Use your
   local checkout of that repo, and create the docs branch from its latest
   default branch.

4. Validate the docs diff.
   ```sh
   git diff --check
   ```

5. Open a docs PR for the update and wait for review. The SDK release can be
   considered complete after the docs PR is merged, or after the maintainer
   confirms no docs update is needed.

## Common Pitfalls

- Do not bump `MARKETING_VERSION` without also bumping `MUXSDKPluginVersion`.
- Do not leave `Package.swift` pointing at a local development dependency for a
  release PR.
- Do not create a release branch with a personal or agent prefix. Use
  `releases/vX.Y.Z`.
- Do not publish the GitHub release before the release PR is merged.
- Do not use CocoaPods artifacts from a `master` Buildkite build. The
  `Build for CocoaPods` step runs on `releases/*` branches.
- Do not upload CocoaPods artifacts before the artifact workflow dry-run has
  passed for the same version and Buildkite build.
- Do not manually create a replacement release/tag if the workflow fails without
  first inspecting the failed Actions run.
- Do not assume SwiftPM availability means CocoaPods is published. CocoaPods is
  a separate `pod trunk push` step.
- Do not continue through CocoaPods auth prompts. Stop and let the maintainer
  complete email authorization.
- Do not publish generated release notes if a maintainer edited the final notes.
