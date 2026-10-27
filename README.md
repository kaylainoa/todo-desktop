# Floating Todo

A tiny floating to-do button for macOS: always on top, one click to open, with subtasks.

A round button sits on your desktop above every window. Click it to open your to-do list, click it again to tuck it away. Drag it anywhere on screen and it remembers where you left it.

## Features

- **Always within reach.** Floats above every app and shows up on all your desktops.
- **Subtasks.** Hover over a task and click **+**, or type `Project 1, write analysis, finalize` to create a task with two subtasks at once.
- **Satisfying check-offs.** A line draws across finished tasks, and they slide to the bottom.
- **Global shortcut.** Press **⌃⌥T** (Control + Option + T) from any app to show or hide your list.
- **Starts at login** and saves your tasks automatically.

## Install

You need **macOS 13 (Ventura) or later**. Floating Todo is built from source on your Mac, which takes about a minute.

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

4. **Open it** from Applications or Spotlight (⌘ Space, then type "Floating Todo"). The blue button appears near the top-right of your screen.

From then on, it opens by itself every time you log in. You never need Terminal again.

## Using it

| To do this | Do this |
|---|---|
| Open or close the list | Click the button, or press **⌃⌥T** |
| Move the button | Drag it |
| Add a task | Type it and press **Enter** |
| Add a task with subtasks | `Task, subtask one, subtask two` |
| Add a subtask later | Hover over a task, then click **+** |
| Check something off | Click its circle |
| Delete | Hover over it, then click **✕** |
| Close the list | **Esc** or the **–** button |
| Hide the button | The 👁 icon in the list, or right-click the button → **Hide** |
| Turn off start at login, or quit | Right-click the button |

## Updating

```bash
cd todo-desktop
git pull
./build.sh --install
```

Then quit Floating Todo (right-click → Quit) and open it again.

## Uninstall

1. Right-click the button → **Quit Floating Todo**.
2. Drag **Floating Todo** from Applications to the Trash.
3. Optional: delete your saved tasks, which are stored in `~/Library/Application Support/FloatingTodo/`.

## Built with

Swift, SwiftUI and AppKit. No dependencies.
