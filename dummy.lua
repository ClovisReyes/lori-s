if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local PlayerGui = (Players.LocalPlayer or Players.PlayerAdded:Wait()):WaitForChild("PlayerGui")

-- 1. DISABLE BLUR (game:GetService("Lighting").Blur)
local function disableBlur(obj)
    if obj and (obj.Name == "Blur" or obj:IsA("BlurEffect")) then
        pcall(function()
            obj.Enabled = false
            obj:GetPropertyChangedSignal("Enabled"):Connect(function()
                if obj.Enabled then
                    obj.Enabled = false
                end
            end)
        end)
    end
end

for _, child in ipairs(Lighting:GetChildren()) do
    disableBlur(child)
end
Lighting.ChildAdded:Connect(disableBlur)

-- 2. LIST TARGET (ALWAYS HIDE & ALWAYS VISIBLE)
local ALWAYS_HIDE = {
    ["!!! Daily Login"] = true,
    ["!!! Update Log"] = true,
    ["Quest"] = true
}

local ALWAYS_VISIBLE = {
    ["Backpack"] = true,
    ["Events"] = true,
    ["Compass"] = true
}

-- Sembunyikan GUI secara permanen (jika game mencoba memunculkan kembali, paksa mati)
local function applyHide(gui)
    pcall(function()
        if gui:IsA("ScreenGui") then
            gui.Enabled = false
            gui:GetPropertyChangedSignal("Enabled"):Connect(function()
                if gui.Enabled then
                    gui.Enabled = false
                end
            end)
        elseif gui:IsA("GuiObject") then
            gui.Visible = false
            gui:GetPropertyChangedSignal("Visible"):Connect(function()
                if gui.Visible then
                    gui.Visible = false
                end
            end)
        end
    end)
end

-- Tampilkan GUI secara permanen (jika game mencoba menyembunyikan, paksa tampilkan)
local function applyVisible(gui)
    pcall(function()
        if gui:IsA("ScreenGui") then
            gui.Enabled = true
            gui:GetPropertyChangedSignal("Enabled"):Connect(function()
                if not gui.Enabled then
                    gui.Enabled = true
                end
            end)
        elseif gui:IsA("GuiObject") then
            gui.Visible = true
            gui:GetPropertyChangedSignal("Visible"):Connect(function()
                if not gui.Visible then
                    gui.Visible = true
                end
            end)
        end
    end)
end

local function handleGUI(gui)
    if ALWAYS_HIDE[gui.Name] then
        applyHide(gui)
    elseif ALWAYS_VISIBLE[gui.Name] then
        applyVisible(gui)
    end
end

-- Tangani semua GUI yang ada di PlayerGui
for _, desc in ipairs(PlayerGui:GetDescendants()) do
    handleGUI(desc)
end

-- Tangani GUI baru yang muncul atau berubah di PlayerGui
PlayerGui.DescendantAdded:Connect(function(desc)
    handleGUI(desc)
end)
