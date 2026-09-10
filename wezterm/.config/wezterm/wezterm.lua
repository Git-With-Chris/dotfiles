local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.default_prog = { 'pwsh.exe', '-NoLogo' }

-- Same face RStudio's terminal + editor use, so the two match exactly.
-- "NFM" is the single-cell-width Nerd Font variant (installed under
-- %LOCALAPPDATA%\Microsoft\Windows\Fonts). WezTerm still falls back to its
-- bundled fonts for anything this face doesn't cover.
config.font = wezterm.font 'JetBrainsMono NFM'

config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false

-- 🌙 Catppuccin
config.color_scheme = "Catppuccin Mocha"

-- Catppuccin Mocha's 16 ANSI slots, defined explicitly so RStudio's terminal
-- and this one are guaranteed identical. RStudio quantises 24-bit colour down
-- to these 16, so the starship prompt is written in ANSI names rather than hex.
-- Slots 8, 11 and 13 are repurposed: Catppuccin normally duplicates its bright
-- row, so those were spare and now carry overlay1 / peach / mauve, which the
-- prompt needs and plain ANSI has no equivalent for.
-- RStudio's theme makes bold a font-weight change only; WezTerm by default
-- swaps bold text to the BRIGHT slot instead. Since slots 0/3/5/7 now differ
-- between the two rows, that made bold text render different colours in the
-- two terminals. Turn it off so bold means weight in both.
config.bold_brightens_ansi_colors = false

config.colors = {
  ansi = {
    '#45475a', -- 0  black    surface1
    '#f38ba8', -- 1  red
    '#a6e3a1', -- 2  green
    '#f9e2af', -- 3  yellow
    '#89b4fa', -- 4  blue
    '#f5c2e7', -- 5  magenta  pink      <- git status
    '#94e2d5', -- 6  cyan     teal
    '#bac2de', -- 7  white    subtext1
  },
  brights = {
    '#7f849c', -- 8  overlay1           <- clock / duration (was surface2)
    '#f38ba8', -- 9  red
    '#a6e3a1', -- 10 green
    '#fab387', -- 11 peach              <- jobs (was yellow)
    '#89b4fa', -- 12 blue
    '#cba6f7', -- 13 mauve              <- git branch (was pink)
    '#94e2d5', -- 14 cyan
    '#a6adc8', -- 15 subtext0
  },
}


-- ✨ Best visual integration
config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"

return config
