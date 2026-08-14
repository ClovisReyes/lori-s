if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local Rep = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer or Players.PlayerAdded:Wait()
local PlayerGui = Player:WaitForChild("PlayerGui")

-- ============================================================
-- 1. LOAD MASTER GUI CONTROLLER DARI GAME
-- ============================================================
local GuiControl = nil
pcall(function()
    local modules = Rep:WaitForChild("Modules", 5)
    if modules and modules:FindFirstChild("GuiControl") then
        GuiControl = require(modules.GuiControl)
    end
end)

local function triggerGameRestoreHUD()
    if not GuiControl then return end
    pcall(function() GuiControl:RestoreHUD() end)
    pcall(function() GuiControl:SetHUDVisibility(true) end)
    pcall(function() GuiControl:Unlock() end)
    pcall(function() GuiControl:Close("!!! Daily Login") end)
    pcall(function() GuiControl:Close("!!! Update Log") end)
    pcall(function() GuiControl:Close("DailyLogin") end)
    pcall(function() GuiControl:Close("UpdateLog") end)
end

-- ============================================================
-- 2. DISABLE BLUR EFFECT
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
-- 3. ALWAYS HIDE & AUTO-CLOSE POPUPS
-- ============================================================
local ALWAYS_HIDE = {
    ["!!! Daily Login"] = true,
    ["!!! Update Log"] = true,
    ["Quest"] = true
}

local processed = {}

local function handlePopup(child)
    if not ALWAYS_HIDE[child.Name] or processed[child] then return end
    processed[child] = true

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

    -- Jalankan pemulihan HUD resmi
    task.spawn(function()
        triggerGameRestoreHUD()
        task.wait(0.2)
        triggerGameRestoreHUD()
    end)
end

-- ============================================================
-- 4. INISIALISASI & EVENT LISTENER
-- ============================================================
for _, child in ipairs(PlayerGui:GetChildren()) do
    handlePopup(child)
end

triggerGameRestoreHUD()

PlayerGui.ChildAdded:Connect(handlePopup)
