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

-- 2. TARGET LIST (EXACT USER SPECIFIED)
local ALWAYS_HIDE_NAMES = {
    ["!!! Daily Login"] = true,
    ["!!! Update Log"] = true,
    ["Quest"] = true
}

local ALWAYS_VISIBLE_NAMES = {
    ["Backpack"] = true,
    ["Events"] = true,
    ["Compass"] = true
}

local processed = {}

local function applyHide(item)
    if processed[item] == "hide" then return end
    processed[item] = "hide"

    pcall(function()
        if item:IsA("ScreenGui") then
            item.Enabled = false
            item:GetPropertyChangedSignal("Enabled"):Connect(function()
                if item.Enabled then item.Enabled = false end
            end)
        elseif item:IsA("GuiObject") then
            item.Visible = false
            item:GetPropertyChangedSignal("Visible"):Connect(function()
                if item.Visible then item.Visible = false end
            end)
        end
    end)
end

local function applyDeepHide(root)
    applyHide(root)
    for _, desc in ipairs(root:GetDescendants()) do
        applyHide(desc)
    end
    root.DescendantAdded:Connect(applyHide)
end

local function applyVisible(item)
    if processed[item] == "visible" then return end
    processed[item] = "visible"

    pcall(function()
        if item:IsA("ScreenGui") then
            item.Enabled = true
            item:GetPropertyChangedSignal("Enabled"):Connect(function()
                if not item.Enabled then item.Enabled = true end
            end)
        elseif item:IsA("GuiObject") then
            item.Visible = true
            item:GetPropertyChangedSignal("Visible"):Connect(function()
                if not item.Visible then item.Visible = true end
            end)

            if item:IsA("CanvasGroup") then
                item.GroupTransparency = 0
                item:GetPropertyChangedSignal("GroupTransparency"):Connect(function()
                    if item.GroupTransparency > 0 then item.GroupTransparency = 0 end
                end)
            end
        end
    end)
end

local function applyTargetVisible(root)
    applyVisible(root)
    -- Terapkan ke semua anak langsung (direct children) dari Backpack, Events, dan Compass
    for _, child in ipairs(root:GetChildren()) do
        if child:IsA("GuiObject") then
            applyVisible(child)
        end
    end
    root.ChildAdded:Connect(function(child)
        if child:IsA("GuiObject") then
            applyVisible(child)
        end
    end)
end

local function checkElement(element)
    local name = element.Name
    if ALWAYS_HIDE_NAMES[name] then
        applyDeepHide(element)
    elseif ALWAYS_VISIBLE_NAMES[name] then
        applyTargetVisible(element)
    end
end

-- Monitor PlayerGui
for _, child in ipairs(PlayerGui:GetChildren()) do
    checkElement(child)
end
for _, desc in ipairs(PlayerGui:GetDescendants()) do
    if ALWAYS_HIDE_NAMES[desc.Name] or ALWAYS_VISIBLE_NAMES[desc.Name] then
        checkElement(desc)
    end
end

PlayerGui.ChildAdded:Connect(checkElement)
PlayerGui.DescendantAdded:Connect(function(desc)
    if ALWAYS_HIDE_NAMES[desc.Name] or ALWAYS_VISIBLE_NAMES[desc.Name] then
        checkElement(desc)
    end
end)
