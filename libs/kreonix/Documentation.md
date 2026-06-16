
# Kronex UI Library — Documentation

Welcome to the official Kronex UI Library documentation. Kronex is a high-performance, smooth, and modern interface ecosystem designed for Roblox script developers, featuring dynamic Lucide icon fetching, complete theme management, and auto-saving configuration profiles.

---

## 1. Booting the Library

To load the core library and its essential addons (ThemeManager and SaveManager) into your script environment, use the following initialization structure:

-- Load Core Library
local KronexLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/YourUsername/YourRepo/main/Library.lua"))()

-- Load Addons
KronexLib.ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/YourUsername/YourRepo/main/ThemeManager.lua"))()
KronexLib.SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/YourUsername/YourRepo/main/SaveManager.lua"))()

-- Initialize Addons
KronexLib.ThemeManager:Init(KronexLib)
KronexLib.SaveManager:Init(KronexLib)

---

## 2. Creating a Window

The window is the main frame holding all your elements and sidebar tabs. 
* Keybind to Toggle visibility: RightShift (Default)

local Window = KronexLib:CreateWindow({
    Title = "kronex.fun | HvH Edition"
})

---

## 3. Creating Tabs

Tabs appear on the sidebar and group your execution modules. Icons are automatically fetched from the Lucide database using their standard asset names.

-- Syntaxes: Window:AddTab(Name, LucideIconName)
local CombatTab = Window:AddTab("Combat", "sword")
local BlatantTab = Window:AddTab("Blatant", "zap")
local SettingsTab = Window:AddTab("Settings", "settings")

> Tip: You can use any icon name from the official Lucide library (e.g., "shield", "eye", "user", "box"). Spacers like spaces are automatically converted to hyphens.

---

## 4. Creating Groupboxes

Groupboxes act as modular containers inside a tab to separate different features cleanly.

local KillauraGroup = CombatTab:AddGroupbox("Killaura Settings")
local VisualsGroup = BlatantTab:AddGroupbox("Render Options")

---

## 5. UI Elements

All interactive UI components must be created inside a Groupbox.

### 5.1 Toggles
Used for binary (true/false) parameters.

local KillauraToggle = KillauraGroup:AddToggle("killaura_enabled", {
    Text = "Enable Killaura",
    Default = false,
    Callback = function(state)
        print("Killaura status:", state)
    end
})

-- Change state programmatically
KillauraToggle:SetValue(true)

-- Listen for changes anywhere else
KillauraToggle:OnChanged(function(state)
    -- Your extra logic
end)

### 5.2 Sliders
Perfect for adjustments requiring numeric value intervals, incorporating a smooth lerp animation.

local RangeSlider = KillauraGroup:AddSlider("killaura_range", {
    Text = "Target Range",
    Min = 2,
    Max = 25,
    Default = 4,
    Rounding = 0.5, -- Snaps values to the nearest 0.5 (Optional)
    Callback = function(value)
        print("Range set to:", value)
    end
})

-- Change value programmatically
RangeSlider:SetValue(12.5)

---

## 6. Utilizing Addons (Theme & Save Managers)

The easiest way to display management settings to the player is by using the built-in automated section builders within your designated settings tab.

-- Generates toggles for all presets (Default, Midnight, Mantis, Light)
KronexLib.ThemeManager:BuildThemeSection(SettingsTab)

-- Generates Configuration actions (Save 'default', Load 'default', Auto-save)
KronexLib.SaveManager:BuildFolderSection(SettingsTab)

### 6.1 Programmatic Theme Controls
You can change, save, or load your user themes explicitly inside your script code:

-- Apply a built-in theme style
KronexLib.ThemeManager:ApplyTheme("Midnight")

-- Save current theme state
KronexLib.ThemeManager:SaveTheme("custom_profile")

-- Load user theme state on script startup
KronexLib.ThemeManager:LoadTheme("custom_profile")

### 6.2 Programmatic Configuration Controls
To implement multi-profile configs manually or outside of the automatic UI section builder:

-- Save current state of all UI elements to 'rage_combat.json'
KronexLib.SaveManager:Save("rage_combat")

-- Load parameters from 'rage_combat.json'
KronexLib.SaveManager:Load("rage_combat")

-- Delete a specific profile
KronexLib.SaveManager:Delete("old_config")

-- Exclude an index from being saved globally
KronexLib.SaveManager:Ignore("killaura_range")

---

## 7. Full Example Script

Here is an example setup demonstrating how a full implementation looks in a single script:

local KronexLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/YourUsername/YourRepo/main/Library.lua"))()
KronexLib.ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/YourUsername/YourRepo/main/ThemeManager.lua"))()
KronexLib.SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/YourUsername/YourRepo/main/SaveManager.lua"))()

KronexLib.ThemeManager:Init(KronexLib)
KronexLib.SaveManager:Init(KronexLib)

local Window = KronexLib:CreateWindow({ Title = "Kronex Ecosystem Example" })

local MainTab = Window:AddTab("Main Features", "crosshair")
local ConfigTab = Window:AddTab("Configuration", "sliders")

local Combat = MainTab:AddGroupbox("Rage Modules")

Combat:AddToggle("aimbot", {
    Text = "Silent Aimbot",
    Default = false,
    Callback = function(v) print("Aimbot:", v) end
})

Combat:AddSlider("fov", {
    Text = "Aimbot FOV",
    Min = 10,
    Max = 180,
    Default = 90,
    Callback = function(v) print("FOV updated:", v) end
})

-- Load custom UI setups inside the second tab
KronexLib.ThemeManager:BuildThemeSection(ConfigTab)
KronexLib.SaveManager:BuildFolderSection(ConfigTab)

-- Load last configuration profile automatically
KronexLib.ThemeManager:LoadTheme()
KronexLib.SaveManager:Load("default")

