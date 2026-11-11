<div align="left">

# Rice Studio
### A desktop workshop for Arch, Hyprland and Serpantinum.

**Workshop 02 · theme collection beta**

Browse a collection, tune the details, capture it in motion, and return to your own desktop.

![Rice Studio collection](docs/collection.png)

</div>

## Before installing

This beta ships the **16 original desktop rices** and your own Main. The collection uses the actual wallpapers, Waybar styles, Kitty and Fastfetch files, and the bundled native components. Serashell uses its own Quickshell panel. Tideglass includes its animated wallpaper.

The installer is intended for Arch + Hyprland, with Serpantinum recommended for the shared settings, weather and notification actions. Personal Main settings, recordings, and machine credentials are excluded from the bundle.

Tested on Arch, Hyprland 0.57.0 (Lua), Quickshell 0.3.2, Qt 6.12. Older config providers have an adapter but are not live-tested. Use a current Arch + Hyprland session; this is a beta, not a universal desktop installer.

## Install

From a terminal in Hyprland:

```bash
git clone https://github.com/jackolantern656787-cmd/rice-studio.git
cd rice-studio
./install.sh --deps
./install.sh --check
./install.sh --install
~/.local/bin/rice-studio
```

Alternatively download the source ZIP through GitHub, extract it, and run the last four commands from that directory.

`--deps` explicitly invokes **sudo pacman -Syu --needed** for the documented package set. It performs a full Arch system upgrade; inspect the transaction before accepting. The installer itself runs **without sudo**, downloads nothing, does not run third-party installers, and leaves your current desktop active.

The dependency command includes Waybar, Wofi, Cava, Fastfetch, Starship and the fonts used by most themes. Check **Setup** for available commands and the Serpantinum bar hook.

## Illogical Impulse bar switching

Studio closes the Illogical Impulse bar after the selected theme bar appears. Returning to Main or reverting a preview restores the bar if Studio closed it. This uses the shell’s own bar controls, so its launcher, sidebars, notifications and other panels stay available. Older Illogical Impulse configs need to expose `bar close` and `bar open` through Quickshell IPC.

## Serpantinum bar switching

If Setup shows the bar hook as connected, Studio hides the Serpantinum bar only after the theme bar appears and restores it when you go back to Main.

For a compatible stock Serpantinum installation without the hook, run this after installing Studio:

```bash
python3 ~/.local/share/rice-studio-portable/serpantinum_hook.py --install
```

This optional hook backs up and edits only Serpantinum's `Shell.qml` and `bar/Bar.qml`. It checks for the expected layout before writing. Reopen Studio and check Setup after Quickshell reloads. Add `--hide` to the hook command to close the running Serpantinum bar immediately. Without the hook the original panel can remain visible alongside the theme bar.

Restore the two original files with the same command using `--restore`.

## What you get

- Screenshot-led collection, search, sort, favorites, keyboard navigation.
- Appearance editor: wallpaper, corner geometry, palette, native-panel font, and Studio Terminal palette selection.
- Drag/resize optional clock, calendar, CPU, RAM, music, and notes widgets.
- Private local screenshots and 8-second silent recordings after a countdown.
- Image/video imports, looping playback, preset notes, dependency checks.
- Independent timed-preview watchdog: close the UI and rollback still works.
- Checkpoints, personal Main, and a terminal recovery command.
- Reduced motion and rectangular controls with eased hover/pressed feedback.

The preset bar opens the included native launcher, Wofi style, or bundled Zunder style. Zunder uses a separate local socket and requires x86-64 plus GTK Layer Shell. If it cannot start, Studio uses the available Serpantinum or Wofi launcher. Studio applies the original frame colors and corner styles through Hyprland. Open **Edit → Window Mode** to choose Tiling, Floating or Scrolling for the current Hyprland session. The setting is shared by workspaces and separate from preset appearance. Floating requires the Hyprland Lua API and Scrolling requires the native scrolling layout. Some panel actions depend on local services such as NetworkManager, MPRIS, and Serpantinum. Fuji Dusk uses a system font fallback when Anurati is unavailable.

New Kitty windows opened through your normal shortcut inherit the active preset. The installer appends one managed include to the existing Kitty config. Main clears the include’s contents, and uninstall removes the include block. Studio Terminal is also available for shortcuts that launch a different terminal app:

```bash
~/.local/bin/rice-studio-terminal
```

## Main PC setup on another machine

To bring over the main PC’s shortcuts, Hyprland animations and input preferences, LazyVim, Cava, Fastfetch, Starship, Qt settings and the Phosphor GTK theme, run this after the regular installer:

```bash
~/.local/bin/rice-studio-main-pc --install
```

This optional step requires a native Hyprland Lua config. It backs up files before writing and replaces overlapping keybindings. Use `--restore` to restore the original files. To enable just the Hyprland shortcuts and visuals, use `rice-studio-keys --install`. Serpantinum-specific lock layouts and shell panels require Serpantinum. They are separate from the Illogical Impulse bar integration.

With those shortcuts, **Alt+Space** opens the themed launcher, **Super+F1** opens the shortcut sheet, **Super+[ / ]** place a terminal left or right, and **Super+Alt+R** returns it to the center. Tideglass opens new Kitty windows floating, centered and horizontal by default. The target is 1200×700, capped to the available screen area. The preset rule requires Hyprland’s Lua API.

```bash
~/.local/bin/rice-studio-bar                 # choose a standalone Waybar
~/.local/bin/rice-studio-bar --list          # list the installed bars
~/.local/bin/rice-studio-terminal --list     # list the standalone Kitty profiles
~/.local/bin/rice-studio-dashboard tideglass # also phosphor, cyanframe, serashell
```

The companion bundle is an export of the portable desktop setup. Each machine supplies its own display configuration, installed applications, and Serpantinum or Illogical Impulse session. Personal state, account files, and machine-specific device settings are excluded.

## Main is yours

At first install, Studio reads the original compositor values it can change: gaps, border size/color, and corner radius. It saves them once in `~/.local/state/rice-studio-portable/original-main.json`.

Your existing wallpaper and bar daemons keep running. Studio adds its own wallpaper and panel layers. Main removes those layers, restores the saved compositor values and returns the Serpantinum bar to its starting state when the hook is available. The optional hook is the only change to existing Serpantinum source files.

Upgrades preserve this original baseline. Invalid or incomplete Main data stops installation instead of silently recapturing a themed desktop. This is not a full-system backup.

## Recovery / uninstall

```bash
~/.local/bin/rice-studio-recover
```

This restores personal Main. If a component crashes, your original desktop processes still exist underneath. In a new login your normal Hyprland configuration loads as usual; this beta does not modify autostart or automatically reapply a rice.

From the cloned repository:

```bash
python3 uninstall.py --uninstall
```

Uninstall restores Main first, stops **only this edition's explicitly scoped Quickshell instances**, and removes only installed files whose contents still match the manifest. Edited files, captures, checkpoint history, and Main recovery data are retained. Dependency packages are not removed.

## Install locations

| Location | Purpose |
| --- | --- |
| `~/.local/share/rice-studio-portable/` | Application code |
| `~/.config/rice-studio-portable/` | Presets, generated wallpapers, terminal palettes |
| `~/.local/state/rice-studio-portable/` | Main, history, captures, installation manifest |
| `~/.local/bin/rice-studio*` | User-local launcher and setup commands |
| `~/.local/share/applications/rice-studio.desktop` | Launcher entry |

An existing unrelated `rice-studio` command or app directory is a collision: installation stops and preserves it. Do not run this installer on top of the author's personal edition. The installer leaves Hyprland, shell startup files, SSH, browser, and authentication files alone. The Kitty integration adds a marked include block to `~/.config/kitty/kitty.conf`.

## Development

```bash
python3 -m unittest discover -s tests -v
python3 -m compileall -q app install.py uninstall.py presets.py
```

Tests use temporary homes and mock compositor commands. Coverage includes read-only preflight, conflicting file preservation, first baseline, upgrade preservation, invalid baseline refusal, typed gap/gradient conversion, and conservative uninstall. Native launch and real timed rollback were also checked on the versions listed above. No clean second physical PC has been tested yet.

The optional GitHub Actions configuration is stored as `docs/github-actions-template.yml`; it is not active. A maintainer with workflow permissions can install it under `.github/workflows/checks.yml`.

Architecture and limits: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

Built with [Quickshell](https://quickshell.org/docs/v0.3.0/guide/install-setup/) and the [Hyprland configuration API](https://wiki.hypr.land/configuring/core/config-options/). Project code is MIT. The theme bundle also contains existing theme art and upstream components. See [theme credits](docs/THEMES.md) for attribution and bundled licenses.
