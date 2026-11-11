# Architecture and boundaries

The Qt Quick frontend talks to a serialized Python JSON-lines backend over a child-process pipe. There is no HTTP listener, login service, telemetry, token store, or automatic uploader.

`core.py` retains managed-file checkpoints and independent rollback. `control.py` adapts only a small explicit set of compositor options and starts the app's own desktop/widget QML paths. It never stops another person's Waybar, Quickshell, wallpaper daemon, or session service.

Before the first install, `ensure_main()` captures supported values under a lock. Gap values and ARGB gradient output from `hyprctl getoption` are translated into Lua-native CSS-box and gradient structures when restoring on Hyprland 0.57. Repeated installs preserve the original snapshot.

The installer stages code and generated assets, backs up managed app files before upgrades, and rolls back file writes if installation fails. It refuses conflicting unmanaged files. Config edits are never overwritten on upgrade. The installation manifest contains relative paths and SHA-256 digests, not credentials.

Media actions are explicit. Screenshots/recordings capture the focused monitor, so users should close private windows first. Recordings are silent and bounded. Media stays in the per-user state directory; imports are normalized with argument-array subprocesses, never shell concatenation.

Limits:

- Studio bundles the full Waybar collection and the Serashell native panel. Theme launchers and actions depend on available local applications and services.
- Original wallpaper and shell processes stay running. The optional Serpantinum hook or built-in Illogical Impulse bar IPC hides the original bar after the Studio bar appears.
- Keep persists the selection in Studio's state, not Hyprland autostart. Reapply deliberately after a new login.
- Border/rounding window-specific rules can override global compositor values.
- A background process that constantly rewrites compositor options can conflict with global themes.
- Clipboard, network passwords, auth cookies, SSH keys and hardware-specific monitor/input settings are out of scope.
- The legacy keyword adapter is not tested on older physical installations.
