# Bangchak

A small iOS storage utility that manages **its own** container only.
Built from scratch — no borrowed binary, no activation gate, no media layer.

- Display name: **Bangchak**
- Bundle id: `com.qxzzyjjiikk.bangchak` (signable with any Apple ID)
- Icon: `Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png` (1024×1024, opaque)
- Project: `Bangchak.xcodeproj` ships ready to open — no generator required

## What is in the box

| | |
|---|---|
| UI | SwiftUI, dark-first, iOS 17+ |
| Storage scan | `Library/Caches`, `tmp`, `Library/Application Support`, `Documents` |
| Cleaning | caches + tmp only, guarded by a container-path check |
| File browser | navigate, inspect sizes, delete single items |
| Import / Export | `UIDocumentPicker` in, `ShareLink` out |
| Background video | **none** — no `AVPlayer`, no `.mp4` in the bundle |
| Music | **none** — no `AVAudioPlayer`, no `.mp3` in the bundle |
| License key | **none** — no key screen, no server, no expiry |
| Network | **none** — the app never makes a request |
| Dependencies | none (no SPM packages) |

## Bundle identifier

`com.qxzzyjjiikk.bangchak` — signable with any Apple ID.

The id originally specified (`com.apple.mobile.MobileHouseArrest`) sits in Apple's own
namespace and cannot be provisioned, so device installs failed with
`The app identifier ... cannot be registered`. It also grants no extra access:
sandbox rights come from entitlements in the signature, not from the bundle name.

To change it, edit the one line in `project.yml` **and** `Bangchak.xcodeproj/project.pbxproj`
(`PRODUCT_BUNDLE_IDENTIFIER`), then rebuild.

## App group

`group.com.st01.ffcachemanager` is **not** wired into this project, on purpose.

App groups are issued per developer team. An entitlement naming another team's
group cannot be provisioned, and shipping one would be an attempt to reach a
container this app does not own. Bangchak therefore stays inside its own sandbox,
and the Settings screen states that plainly.

## Build

`Bangchak.xcodeproj` is included and ready to open:

```bash
open Bangchak.xcodeproj
```

`project.yml` is the readable source of truth; if you prefer generating the project
again after editing it:

```bash
brew install xcodegen
xcodegen generate
```

Then in Xcode:

1. Select the `Bangchak` target → **Signing & Capabilities**.
2. Set your Team.
3. Pick a device or simulator and press ⌘R.

Command-line build:

```bash
xcodebuild -project Bangchak.xcodeproj \
           -scheme Bangchak \
           -configuration Debug \
           -destination 'generic/platform=iOS' \
           -allowProvisioningUpdates build
```

## Sideload

```bash
xcodebuild -project Bangchak.xcodeproj -scheme Bangchak \
           -configuration Release -sdk iphoneos \
           -archivePath build/Bangchak.xcarchive archive

xcodebuild -exportArchive -archivePath build/Bangchak.xcarchive \
           -exportPath build/ipa -exportOptionsPlist ExportOptions.plist
```

Then point Sideloadly / AltStore at the exported `.ipa`.

## Icon

The source logo was flattened onto an opaque white square and scaled to 1024×1024
(`Format24bppRgb`, no alpha — the App Store and iOS reject transparent icons).
To swap it, drop a new opaque 1024×1024 PNG at that path and keep the filename
`AppIcon.png`.

## Honest limits

* The app can only touch **its own** sandbox. Another app's documents, including a
  game's cache folder, are behind a container boundary that requires an entitlement
  signed by Apple (or a jailbroken/TrollStore environment with the right entitlements).
* It is a storage utility, not a game tool. There is no hooking, no injection and no
  third-party binary patching anywhere in this project.

## Layout

```
Sources/
  App/      BangchakApp.swift, RootView.swift
  Core/     FileWalker, StorageEngine, ScanTarget, Models, SizeFormat, Preferences
  UI/       Theme, Components
  Views/    DashboardView, BrowseView, SettingsView
Resources/  Info.plist, Assets.xcassets
project.yml · ExportOptions.plist
```
