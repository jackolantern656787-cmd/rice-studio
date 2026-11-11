local mainMod = "SUPER"
local root = os.getenv("HOME") .. "/.local/share/rice-studio-portable"
local commands = root .. "/commands/"
dofile(root .. "/integrations/main-pc-visuals.lua")
local terminal = "kitty"
local function bind(key, action, options)
  hl.unbind(key)
  hl.unbind((key:gsub("([^+ ]+)$", string.lower)))
  hl.unbind((key:gsub("([^+ ]+)$", function(k) return k:sub(1,1):upper() .. k:sub(2):lower() end)))
  hl.bind(key, action, options or {})
end

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

bind(mainMod .. " + SHIFT + Left", hl.dsp.window.resize({ x = -50, y = 0, relative = true }), { repeating = true })
bind(mainMod .. " + SHIFT + Right", hl.dsp.window.resize({ x = 50, y = 0, relative = true }), { repeating = true })
bind(mainMod .. " + SHIFT + Up", hl.dsp.window.resize({ x = 0, y = -50, relative = true }), { repeating = true })
bind(mainMod .. " + SHIFT + Down", hl.dsp.window.resize({ x = 0, y = 50, relative = true }), { repeating = true })

bind(mainMod .. " + CTRL + Left", hl.dsp.window.move({ direction = "l" }))
bind(mainMod .. " + CTRL + Right", hl.dsp.window.move({ direction = "r" }))
bind(mainMod .. " + CTRL + Up", hl.dsp.window.move({ direction = "u" }))
bind(mainMod .. " + CTRL + Down", hl.dsp.window.move({ direction = "d" }))

bind(mainMod .. " + Left", hl.dsp.focus({ direction = "left" }))
bind(mainMod .. " + Right", hl.dsp.focus({ direction = "right" }))
bind(mainMod .. " + Up", hl.dsp.focus({ direction = "up" }))
bind(mainMod .. " + Down", hl.dsp.focus({ direction = "down" }))

bind(mainMod .. " + Q", hl.dsp.window.close())
bind(mainMod .. " + ALT + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
bind(mainMod .. " + SHIFT + F", hl.dsp.window.float({ action = "toggle" }))

bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(commands .. "serpantinum brightness lower"), { locked = true })
bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(commands .. "serpantinum brightness raise"), { locked = true })

bind("Print", hl.dsp.exec_cmd(commands .. "serpantinum screenshot"), { locked = true })
bind("SHIFT + Print", hl.dsp.exec_cmd(commands .. "serpantinum screenshot --edit"), { locked = true })
bind("SUPER + Print", hl.dsp.exec_cmd(commands .. "serpantinum screenshot --full"), { locked = true })
bind("SUPER + SHIFT + Print", hl.dsp.exec_cmd(commands .. "serpantinum screenshot --full --edit"), { locked = true })

bind("XF86PowerOff", hl.dsp.exec_cmd(commands .. "serpantinum lock"), { locked = true })
bind(mainMod .. " + L", hl.dsp.exec_cmd(commands .. "serpantinum lock"), { repeating = true, locked = true })

bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
bind("XF86AudioMicMute", hl.dsp.exec_cmd(commands .. "serpantinum volume mic-toggle"), { locked = true })
bind("XF86AudioMute", hl.dsp.exec_cmd(commands .. "serpantinum volume mute-toggle"), { locked = true })
bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(commands .. "serpantinum volume lower"), { repeating = true, locked = true })
bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(commands .. "serpantinum volume raise"), { repeating = true, locked = true })

bind(mainMod .. " + F", hl.dsp.exec_cmd("firefox"))
bind(mainMod .. " + E", hl.dsp.exec_cmd("nautilus"))
bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))

bind(mainMod .. " + R", hl.dsp.exec_cmd(commands .. "serpantinum reload"))
bind(mainMod .. " + C", hl.dsp.exec_cmd(commands .. "rice-popup clipboard"))
bind(mainMod .. " + D", hl.dsp.exec_cmd(commands .. "rice-popup launcher"))
bind(mainMod .. " + M", hl.dsp.exec_cmd(commands .. "rice-popup music"))
bind(mainMod .. " + B", hl.dsp.exec_cmd(commands .. "rice-popup system"))
bind(mainMod .. " + W", hl.dsp.exec_cmd(commands .. "rice-popup wallpaper"))
bind(mainMod .. " + S", hl.dsp.exec_cmd(commands .. "rice-popup calendar"))
bind(mainMod .. " + N", hl.dsp.exec_cmd(commands .. "rice-panel network"))
bind(mainMod .. " + V", hl.dsp.exec_cmd(commands .. "rice-panel volume"))
bind(mainMod .. " + H", hl.dsp.exec_cmd(commands .. "rice-popup settings"))
bind(mainMod .. " + A", hl.dsp.exec_cmd(commands .. "serpantinum msg toggle autohide"))

for i = 1, 10 do
  local ws = tostring(i)
  local key = tostring(i % 10)
  bind(mainMod .. " + " .. key, hl.dsp.exec_cmd(commands .. "workspace " .. ws))
  bind(mainMod .. " + SHIFT + " .. key, hl.dsp.exec_cmd(commands .. "workspace " .. ws .. " move"))
end

-- Zunder launcher (separate from Serpantinum Super+D).
bind("ALT + SPACE", hl.dsp.exec_cmd(commands .. "rice-launch"))

-- Animate only the Zunder overlay.
hl.layer_rule({ name = "zunder-fade", match = { namespace = "^zunder$" }, animation = "fade" })

-- Unified desktop profiles and theme controls.
bind("SUPER + SHIFT + T", hl.dsp.exec_cmd(commands .. "studio"))

-- Searchable shortcut sheet.
bind("SUPER + F1", hl.dsp.exec_cmd("kitty --class shortcut-sheet --title 'Shortcut Sheet' -e " .. commands .. "keys"))

-- Native lock screen layout picker (selection does not lock).
bind("SUPER + ALT + L", hl.dsp.exec_cmd(commands .. "lock-picker"))

-- Rice Studio visual editor.
bind("SUPER + CTRL + T", hl.dsp.exec_cmd(commands .. "studio"))

-- Native scrolling-layout controls.
bind("SUPER + ALT + W", hl.dsp.layout("colresize +conf"))
bind("SUPER + ALT + Left", hl.dsp.layout("focus l"))
bind("SUPER + ALT + Right", hl.dsp.layout("focus r"))

-- Return the focused terminal to a centered horizontal floating window.
bind("SUPER + ALT + R", hl.dsp.exec_cmd(commands .. "terminal-right center"))

-- Left-half terminal placement; Super+Alt+L remains the lock picker.
bind("SUPER + ALT + SHIFT + L", hl.dsp.exec_cmd(commands .. "terminal-right left"))

-- Simple terminal side placement: adjacent bracket keys, one modifier.
bind("SUPER + bracketleft", hl.dsp.exec_cmd(commands .. "terminal-right left"))
bind("SUPER + bracketright", hl.dsp.exec_cmd(commands .. "terminal-right"))
