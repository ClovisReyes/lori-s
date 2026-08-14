if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local Rep = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer or Players.PlayerAdded:Wait()
local PlayerGui = Player:WaitForChild("PlayerGui")

local GuiControl
pcall(function()
    local modules = Rep:WaitForChild("Modules", 5)
    if modules and modules:FindFirstChild("GuiControl") then
        GuiControl = require(modules.GuiControl)
    end
end)

local function restoreHUD()
    if not GuiControl then return end
    pcall(function() GuiControl.RestoreHUD() end)
    pcall(function() GuiControl:RestoreHUD() end)
    pcall(function() GuiControl.SetHUDVisibility(true) end)
    pcall(function() GuiControl:SetHUDVisibility(true) end)
    pcall(function() GuiControl.Unlock() end)
    pcall(function() GuiControl:Unlock() end)

    local targets = {"!!! Daily Login", "!!! Update Log"}
    for _, t in ipairs(targets) do
        pcall(function() GuiControl.Close(t) end)
        pcall(function() GuiControl:Close(t) end)
    end
end

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

local ALWAYS_HIDE = {
    ["!!! Daily Login"] = true,
    ["!!! Update Log"] = true,
    ["Quest"] = true
}

local processed = setmetatable({}, {__mode = "k"})

local function handlePopup(child)
    if not ALWAYS_HIDE[child.Name] or processed[child] then return end
    processed[child] = true

    pcall(function()
        if child:IsA("ScreenGui") then
            child.Enabled = false
            child:GetPropertyChangedSignal("Enabled"):Connect(function()
                if child.Enabled then
                    child.Enabled = false
                    restoreHUD()
                end
            end)
        elseif child:IsA("GuiObject") then
            child.Visible = false
            child:GetPropertyChangedSignal("Visible"):Connect(function()
                if child.Visible then
                    child.Visible = false
                    restoreHUD()
                end
            end)
        end
    end)

    task.spawn(function()
        restoreHUD()
        task.wait(0.2)
        restoreHUD()
    end)
end

for _, child in ipairs(PlayerGui:GetChildren()) do
    handlePopup(child)
end

restoreHUD()

PlayerGui.ChildAdded:Connect(handlePopup)
