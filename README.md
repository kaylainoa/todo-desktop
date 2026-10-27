# Floating Todo

A tiny floating to-do button for macOS: always on top, one click to open, with subtasks.

A round button sits on your desktop above other windows. Click it to open your to-do list, and press **Esc** to shrink it back to a button. Drag it anywhere on screen and it remembers where you left it.

## Features

- **Always within reach.** Floats above other windows and shows up on all your desktops.
- **Subtasks.** Hover over a task and click **+**, or type `Project 1, write analysis, finalize` to create a task with two subtasks at once.
- **Check-off animation.** A line draws across finished tasks, and they slide to the bottom.
- **Global shortcut.** Press **⌃⌥T** (Control + Option + T) from any app to open or close your list.
- **Opens at login** and saves your tasks automatically.

## Install

You need **macOS 13 (Ventura) or later**. Floating Todo isn't signed by Apple, so you build it from source on your Mac. That takes a few minutes, most of it installing Apple's developer tools.

1. **Install Apple's developer tools** (skip this step if you already have Xcode). Open **Terminal** and run:
   ```bash
   xcode-select --install
   ```
   Click **Install** in the window that pops up and wait for it to finish.

2. **Download the code:**
   ```bash
   git clone https://github.com/kaylainoa/todo-desktop.git
   cd todo-desktop
   ```
   No git? Click the green **Code** button on GitHub, choose **Download ZIP**, unzip it, then `cd` into the folder in Terminal.

3. **Build and install:**
   ```bash
   ./build.sh --install
   ```
   This puts **Floating Todo** in your Applications folder.

4. **Open it** from **Finder → Applications**. A purple button appears near the top-right of your screen.

The first time it runs, it adds itself to your login items, so it opens automatically when you log in. macOS may show a "Background Items Added" notification about this. You can turn it off by right-clicking the button. You only need Terminal again to update.

> **Can't find it in Spotlight?** Spotlight can take a while to index newly installed apps. Until it does, open it from Finder → Applications, or Launchpad.

## Using it

| To do this | Do this |
|---|---|
| Open the list | Click the button, or press **⌃⌥T** |
| Close the list | **Esc**, the **–** button, or **⌃⌥T** |
| Move the button | Drag it |
| Add a task | Type it and press **Enter** |
| Add a task with subtasks | `Task, subtask one, subtask two` |
| Add a subtask later | Hover over a task, then click **+** |
| Check something off | Click its circle |
| Delete | Hover over it, then click **✕** |
| Hide the button | The crossed-out eye icon at the bottom of the list, or right-click the button → **Hide**. Press **⌃⌥T** to bring it back. |
| Turn off opening at login | Right-click the button → **Open at Login** |
| Quit | Right-click the button → **Quit Floating Todo** |

**Heads up:** typing a comma in the main box always starts a subtask, so `Buy eggs, milk` becomes "Buy eggs" with a subtask "milk."

If another app already uses ⌃⌥T, the shortcut won't work in Floating Todo.

## Updating

```bash
cd todo-desktop
git pull
./build.sh --install
```

Then quit Floating Todo (right-click → Quit) and open it again.

## Uninstall

1. Right-click the button and uncheck **Open at Login**.
2. Right-click again → **Quit Floating Todo**.
3. Drag **Floating Todo** from Applications to the Trash.
4. Optional: delete your saved tasks, which are stored in `~/Library/Application Support/FloatingTodo/`.

## Built with

Swift, SwiftUI and AppKit. No dependencies.
