# Desktop Toilet

A small native macOS desktop toy inspired by the [viral rug that lives on the Finder desktop](https://x.com/terkelg/status/2107540718461886464). This is the toilet version: drop files or folders into the bowl, flush, and they go to Trash.

The toilet sits in a borderless, transparent, desktop-level window. It has no Dock icon. A menu bar extra (the drop) is how you quit, empty the bowl, undo, and open settings.

## What it does

- Drag the porcelain toilet to move it. The position is remembered.
- Drop Finder files or folders onto it. The lid lifts, you get a plop, and a count badge appears.
- Click the gold handle to flush (or ⌘F / Return / Space while the toilet is focused).
- **Default flush moves items to the macOS Trash** via `NSWorkspace.recycle`. Anything flushed this way can be restored from Trash, or with **Undo Last Flush** (⌘Z) if the Trash copies are still there.
- Hover or drag to open the lid. Drag a chip out of the bowl, or click × / **Empty Bowl**, to rescue items *before* you flush. Rescue does not move the original files.
- Protected paths refuse with *“that’s too big to flush”*: `/`, `/System` (not ordinary files on the data volume), `/Applications` itself, your home folder itself, and the Desktop folder itself.
- Flushing more than 20 items (configurable) or anything over 1 GB asks first.
- Permanent delete exists only as an off-by-default setting with an explicit warning. Undo cannot restore a permanent flush.

## Requirements

- macOS 13 Ventura or later
- Apple Silicon
- Swift command-line tools (`xcode-select --install`). Xcode is not required.

This repository is a Swift package. The pure flush logic (`ToiletCore`) builds and unit-tests on Linux. The AppKit/SwiftUI app target is macOS-only.

## Build and run on a Mac

```bash
git clone <this-repo>
cd <this-repo>
make test          # ToiletCore unit tests
make app           # → dist/Desktop Toilet.app (ad-hoc signed)
open "dist/Desktop Toilet.app"
```

Equivalent:

```bash
swift test --filter ToiletCoreTests
./scripts/build-app.sh
open "dist/Desktop Toilet.app"
```

Look for the **drop** icon in the menu bar. The toilet appears on the desktop (above wallpaper/icons, below normal windows). Drag files onto it, then click the handle.

To run the executable without bundling (Dock icon may appear; sounds resolve from `Resources/Sounds`):

```bash
swift build -c release --product DesktopToilet
.build/release/DesktopToilet
```

### Launch at login

`SMAppService` only reliably registers a packaged app, preferably in `/Applications`:

1. `make app`
2. Copy `dist/Desktop Toilet.app` into `/Applications`
3. Open it once
4. Menu bar extra → **Settings…** → **Launch at login**

Or: System Settings → General → Login Items → add **Desktop Toilet**.

## Safety

| Action | Result |
| --- | --- |
| Flush (default) | `NSWorkspace.recycle` → Trash. Undo last flush moves those Trash items back if they are still there. |
| Empty Bowl | Clears the in-memory queue only. Files stay on disk. |
| Permanent delete | Off by default. Enabling it shows a warning. Every permanent flush also confirms. There is no undo. |
| Protected drop | Refused; not added to the bowl. |
| Large flush | Confirm if count > N (default 20) or total size > 1 GB. |

It will not flush `/`, `/System` (sealed system volume), the `/Applications` folder itself, your home folder itself, or the Desktop folder itself. Individual files *on* the Desktop, and individual apps *inside* `/Applications`, can still be flushed to Trash.

## Sounds

`Resources/Sounds/plop.wav` and `flush.wav` are original synthesised effects (sine waves, envelopes, and filtered noise). Regenerated with:

```bash
python3 scripts/generate-sounds.py
```

No third-party samples. Public domain / CC0.

The toilet itself is drawn with SwiftUI shapes (no copyrighted art).

## Layout

```
Sources/ToiletCore/        Portable guardrails, queue, size, flush plan
Sources/DesktopToilet/     macOS SwiftUI + AppKit UI
Tests/ToiletCoreTests/     Linux-friendly XCTest
scripts/build-app.sh       Builds dist/Desktop Toilet.app
Resources/Info.plist       LSUIElement = true (no Dock icon)
```

## Tests on Linux

```bash
swift test --filter ToiletCoreTests
```

The macOS app target is omitted from the package graph on Linux, so `swift test` only builds `ToiletCore`.

## Notes if the Mac build complains

The UI was written against the macOS 13 SDK, Swift 5 language mode, and APIs that have been stable for years (`NSPanel`, `NSWorkspace.recycle`, `NSHostingView`, `MenuBarExtra`, `SMAppService`). It was **not** compiled here (this environment is Linux). Things most likely to need a one-line tweak on a real Mac:

- `NSWorkspace.recycle(_:completionHandler:)` mapping type — if the SDK labels it differently, `TrashFlusher.recycle` is the only call site. `FileManager.trashItem` is the fallback.
- Finder drops onto a desktop-icon-level window — the panel is an `NSDraggingDestination`. If drops pass through to the Desktop, raise `ToiletWindowController`’s window level a little more.
- `onChange(of:)` uses the macOS 13 single-parameter form. A newer SDK may warn; the two-parameter form is macOS 14+.
- `SMAppService.mainApp.register()` often fails until the `.app` lives in `/Applications`.
- Ad-hoc signing is enough to launch locally. Gatekeeper may still require a right-click → Open the first time if the app was downloaded.
