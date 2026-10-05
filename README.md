# MenuAtPointer

Bring the current macOS application's main menu to your mouse pointer.

Instead of moving the pointer all the way to the menu bar every time you want **File**, **Edit**, **View**, **Window**, or another application menu, MenuAtPointer shows the same menu hierarchy wherever the pointer already is.

By default:

- **Option + left-click** opens the current application's menu at the pointer.
- Normal left-click works normally.
- Normal right-click still opens the application's usual context menu.

MenuAtPointer uses [Hammerspoon](https://www.hammerspoon.org/) and the macOS Accessibility API. It does not replace or modify applications.

## Installation

### 1. Install Hammerspoon

Install Hammerspoon from its website, or with Homebrew:

```sh
brew install --cask hammerspoon
```

Launch Hammerspoon and allow it under **System Settings → Privacy & Security → Accessibility** when macOS asks.

For the feature to be available after each login, enable **Launch Hammerspoon at login** in Hammerspoon's settings.

### 2. Install MenuAtPointer

Download `MenuAtPointer.lua` from this repository and place it in:

```text
~/.hammerspoon/MenuAtPointer.lua
```

Then add this line to your Hammerspoon config at `~/.hammerspoon/init.lua`:

```lua
dofile(hs.configdir .. "/MenuAtPointer.lua")
```

If you do not already have an `init.lua`, create one containing just that line.

### 3. Reload Hammerspoon

Choose **Reload Config** from the Hammerspoon menu-bar icon.

Now **Option + left-click** anywhere in an application to open its main menu at the pointer.

## What it does

MenuAtPointer reads the active application's real menu structure using macOS Accessibility, rebuilds it as a popup menu, and invokes the application's original menu command when you choose an item.

That means application-specific menus are included automatically. For example, Safari can show Safari, File, Edit, View, History, Bookmarks, Window and Help, while another app will show its own menu set.

The application's own menu is included at the top, so items such as **Settings…**, **About**, **Hide** and **Quit** remain available.

## Changing the trigger

The default trigger is **Option + left-click**.

Near the top of `MenuAtPointer.lua` you will find:

```lua
local triggerModifier = "alt"
```

Hammerspoon names the Option key `alt`. You can change this to:

```text
shift
ctrl
cmd
```

For example, to use Control + left-click:

```lua
local triggerModifier = "ctrl"
```

Note that macOS normally uses Control-click as an alternative to right-click, so Option is usually the least disruptive choice.

## Notes

- MenuAtPointer requires Hammerspoon to be running.
- Some applications may expose parts of their menus differently through Accessibility.
- Menu contents are read from the frontmost application each time, so dynamic and application-specific menu items are preserved.
- Normal macOS right-click behaviour is untouched.

## Licence

MIT. See [LICENSE](LICENSE).
