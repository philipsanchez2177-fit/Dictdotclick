# scaffold/ — files waiting for the Xcode project to exist

These were written in the Claude container before Xcode existed on the Mac. They are staged here
rather than at their final paths so they cannot collide with the folder Xcode's New Project wizard
creates.

**This folder is temporary.** Once the steps below are done it gets deleted, and the files live in
the real project.

---

## Step 1 — create the Xcode project

Xcode → **File → New → Project → macOS → App**

| Field | Value |
|---|---|
| Product Name | `Dictdotclick` |
| Team | None (or your personal team — free signing is fine) |
| Organization Identifier | anything reverse-domain, e.g. `com.philipsanchez` |
| Interface | **SwiftUI** |
| Language | **Swift** |
| Testing System | **None** |
| Storage | **None** |

Save it into the repo folder (`Dictdotclick/`), and **uncheck "Create Git repository"** — the repo
already exists, and a second one nested inside would fight with it.

Xcode creates `Dictdotclick/Dictdotclick.xcodeproj` and a `Dictdotclick/Dictdotclick/` source folder.

Press **⌘R** once. A blank white window appears. That is the checkpoint that says the toolchain
works — nothing about this app is right yet, it just builds.

## Step 2 — make it menu-bar-only

Select the project in the sidebar → the **Dictdotclick** target → the **Info** tab. Hover any row,
click **+**, and add:

| Key | Value |
|---|---|
| `Application is agent (UIElement)` | `YES` |

(That key's raw name is `LSUIElement`. It is the switch that removes the Dock icon and the ⌘-Tab
entry — the difference between a normal app that happens to have a menu-bar item and an app that
lives *only* in the menu bar.)

## Step 3 — drop in the app file

Replace the wizard's `DictdotclickApp.swift` with `scaffold/DictdotclickApp.swift`, then delete the
wizard's `ContentView.swift` — nothing references it any more.

## Step 4 — run it

⌘R. What success looks like:

- A microphone icon in the menu bar
- **No** Dock icon, no window on screen
- Clicking the icon opens a menu: Settings…, Quit
- Settings… opens a small placeholder window
- Quit removes the icon
- ⌘-Tab does not list Dictdotclick

If it fails to build, paste the errors into the next Claude session. That loop is expected for this
project, not a setback.

## Step 5 — clean up

Delete this `scaffold/` folder and commit.

---

## Folder structure (do this in Step 3, while you're in there)

Inside the `Dictdotclick/Dictdotclick/` source folder, create these groups so later phases have an
obvious home for their files. Right-click the folder in Xcode → New Group:

`App/` · `UI/` · `Hotkey/` · `Audio/` · `Transcription/` · `Delivery/` · `Dictionary/` · `Storage/`

Move `DictdotclickApp.swift` into `App/`. They map one-to-one onto the build phases, which keeps
"where does this go?" from ever being a question.
