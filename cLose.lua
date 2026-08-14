if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local Rep = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer or Players.PlayerAdded:Wait()
local PlayerGui = Player:WaitForChild("PlayerGui")

-- ============================================================
-- 1. LOAD RESMI GUI CONTROL DARI GAME
-- ============================================================
local GuiControl = nil
pcall(function()
    local modules = Rep:WaitForChild("Modules", 5)
    if modules then
        local gc = modules:FindFirstChild("GuiControl")
        if gc then
            GuiControl = require(gc)
        end
    end
end)

local function triggerGameRestoreHUD()
    if GuiControl then
        pcall(function() GuiControl:RestoreHUD() end)
        pcall(function() GuiControl.RestoreHUD() end)
        pcall(function() GuiControl:SetHUDVisibility(true) end)
        pcall(function() GuiControl.SetHUDVisibility(true) end)
        pcall(function() GuiControl:Unlock() end)
        pcall(function() GuiControl.Unlock() end)
        pcall(function() GuiControl:Close("!!! Daily Login") end)
        pcall(function() GuiControl:Close("!!! Update Log") end)
        pcall(function() GuiControl:Close("DailyLogin") end)
        pcall(function() GuiControl:Close("UpdateLog") end)
    end
end

-- ============================================================
-- 2. DISABLE BLUR (game:GetService("Lighting").Blur)
-- ============================================================
local function disableBlur(obj)
    if obj and (obj.Name == "Blur" or obj:IsA("BlurEffect")) then
        pcall(function()
            obj.Enabled = false
            obj:GetPropertyChangedSignal("Enabled"):Connect(function()
                if obj.Enabled then obj.Enabled = false end
            end)
        end)
    end
end

for _, child in ipairs(Lighting:GetChildren()) do
    disableBlur(child)
end
Lighting.ChildAdded:Connect(disableBlur)

-- ============================================================
-- 3. ALWAYS HIDE & CLOSE TARGETS
-- ============================================================
local ALWAYS_HIDE = {
    ["!!! Daily Login"] = true,
    ["!!! Update Log"] = true,
    ["Quest"] = true
}

local function hideAndClose(child)
    if not ALWAYS_HIDE[child.Name] then return end

    pcall(function()
        if child:IsA("ScreenGui") then
            child.Enabled = false
            child:GetPropertyChangedSignal("Enabled"):Connect(function()
                if child.Enabled then
                    child.Enabled = false
                    triggerGameRestoreHUD()
                end
            end)
        elseif child:IsA("GuiObject") then
            child.Visible = false
            child:GetPropertyChangedSignal("Visible"):Connect(function()
                if child.Visible then
                    child.Visible = false
                    triggerGameRestoreHUD()
                end
            end)
        end
    end)

    -- Panggil pemulihan HUD resmi dari game
    task.spawn(function()
        triggerGameRestoreHUD()
        task.wait(0.2)
        triggerGameRestoreHUD()
        task.wait(0.5)
        triggerGameRestoreHUD()
    end)
end

-- ============================================================
-- 4. ALWAYS VISIBLE FALLBACK (Backpack, Events, Compass)
-- ============================================================
local ALWAYS_VISIBLE = {"Backpack", "Events", "Compass"}

local function ensureVisible()
    for _, name in ipairs(ALWAYS_VISIBLE) do
        local gui = PlayerGui:FindFirstChild(name)
        if gui and gui:IsA("ScreenGui") then
            pcall(function()
                if not gui.Enabled then gui.Enabled = true end
            end)
        end
    end
end

-- Jalankan untuk semua elemen yang sudah ada
for _, child in ipairs(PlayerGui:GetChildren()) do
    hideAndClose(child)
end
triggerGameRestoreHUD()
ensureVisible()

-- Monitor elemen baru yang muncul
PlayerGui.ChildAdded:Connect(function(child)
    hideAndClose(child)
    ensureVisible()
end)
