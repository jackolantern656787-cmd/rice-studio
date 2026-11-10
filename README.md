<div align="left">

# Rice Studio
### A desktop workshop for Arch + Hyprland.

**Workshop 02 · portable beta**

Browse a collection, tune the details, capture it in motion, and return to your own desktop.

![Rice Studio collection](docs/collection.png)

</div>

## Before installing

This is the **portable edition**, not a copy of the author's personal dotfiles. It includes the Studio UI and **16 original palette studies + your personal Main**, with procedural wallpapers, a shared native panel, optional widgets, and separate Kitty palettes.

The names echo the personal collection. They **do not recreate every Serpantinum-specific shell, animated wallpaper, themed app launcher, or reference desktop**. Those adapters are still being ported. No third-party wallpaper packs, private configs, credentials, or personal recordings are distributed.

Tested on Arch, Hyprland 0.57.0 (Lua), Quickshell 0.3.2, Qt 6.12. Older config providers have an adapter but are not live-tested. Use a current Arch + Hyprland session; this is a beta, not a universal desktop installer.

## Install

Private repository: the owner must grant your GitHub account access first. With GitHub CLI authenticated:

```bash
gh repo clone jackolantern656787-cmd/rice-studio
cd rice-studio
./install.sh --deps
./install.sh --check
./install.sh --install
~/.local/bin/rice-studio
```

Alternatively download the source ZIP through GitHub, extract it, and run the last four commands from that directory.

`--deps` explicitly invokes **sudo pacman -Syu --needed** for the documented package set. It performs a full Arch system upgrade; inspect the transaction before accepting. The installer itself runs **without sudo**, downloads nothing, does not run third-party installers, and leaves your current desktop active.

Dependencies: Python + Pillow, Quickshell, Qt Quick/Multimedia/ImageFormats/SVG, Kitty, Grim, wf-recorder, FFmpeg, xdg-utils, playerctl, JetBrains Mono, and gsfonts. Hyprland must already be installed and running. Optional networking/audio tools are reported in Setup.

## What you get

- Screenshot-led collection, search, sort, favorites, keyboard navigation.
- Appearance editor: wallpaper, corner geometry, palette, native-panel font, and Studio Terminal palette selection.
- Drag/resize optional clock, calendar, CPU, RAM, music, and notes widgets.
- Private local screenshots and 8-second silent recordings after a countdown.
- Image/video imports, looping playback, preset notes, dependency checks.
- Independent timed-preview watchdog: close the UI and rollback still works.
- Checkpoints, personal Main, and a terminal recovery command.
- Reduced motion and rectangular controls with eased hover/pressed feedback.

The portable panel is shared across presets; it is not a separate Waybar config per preset. Your existing launcher and global window behavior stay unchanged. Terminal changes apply only to **Studio Terminal**, opened with:

```bash
~/.local/bin/rice-studio-terminal
```

## Main is yours

At first install, Studio reads the original compositor values it can change: gaps, border size/color, and corner radius. It saves them once in `~/.local/state/rice-studio-portable/original-main.json`.

Your existing wallpaper/bar daemons, terminal configs, monitors, keybindings and shell files are **never replaced**. Studio adds separate wallpaper/panel layers while a preset is active; Main hides those layers and restores the saved compositor values. That is how your own starting desktop comes back, rather than somebody else's "Main" preset.

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
| `~/.local/bin/rice-studio*` | Three user-local commands |
| `~/.local/share/applications/rice-studio.desktop` | Launcher entry |

An existing unrelated `rice-studio` command or app directory is a collision: installation stops and preserves it. Do not run this installer on top of the author's personal edition. No `~/.config/hypr`, `~/.config/kitty`, `.bashrc`, SSH, browser or authentication files are copied or edited.

## Development

```bash
python3 -m unittest discover -s tests -v
python3 -m compileall -q app install.py uninstall.py presets.py
```

Tests use temporary homes and mock compositor commands. Coverage includes read-only preflight, conflicting file preservation, first baseline, upgrade preservation, invalid baseline refusal, typed gap/gradient conversion, and conservative uninstall. Native launch and real timed rollback were also checked on the versions listed above. No clean second physical PC has been tested yet.

The optional GitHub Actions configuration is stored as `docs/github-actions-template.yml`; it is not active. A maintainer with workflow permissions can install it under `.github/workflows/checks.yml`.

Architecture and limits: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

Built with [Quickshell](https://quickshell.org/docs/v0.3.0/guide/install-setup/) and the [Hyprland configuration API](https://wiki.hypr.land/configuring/core/config-options/). Color studies acknowledge the Catppuccin palette family and the earlier rice collection; no upstream personal dotfiles or artwork are vendored. Project code and generated wallpaper designs: MIT.
