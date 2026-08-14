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

-- 2. TARGET LIST (ALWAYS HIDE & ALWAYS VISIBLE)
local ALWAYS_HIDE_NAMES = {
    ["!!! Daily Login"] = true,
    ["!!! Update Log"] = true,
    ["Quest"] = true
}

local ALWAYS_VISIBLE_NAMES = {
    ["Display"] = true,
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

local function applyDeepHide(root)
    applyHide(root)
    for _, desc in ipairs(root:GetDescendants()) do
        applyHide(desc)
    end
    root.DescendantAdded:Connect(applyHide)
end

-- Tampilkan HANYA root dan kontainer tombol langsung (seperti Compass.Frame atau Events.Frame)
-- tanpa memaksa jendela modal internal (seperti jendela tas/inventory) ikut terbuka.
local function applyShallowVisible(root)
    applyVisible(root)
    for _, child in ipairs(root:GetChildren()) do
        if child:IsA("GuiObject") and (child.Name == "Frame" or ALWAYS_VISIBLE_NAMES[child.Name]) then
            applyVisible(child)
        end
    end
end

local function checkElement(element)
    local name = element.Name
    if ALWAYS_HIDE_NAMES[name] then
        applyDeepHide(element)
    elseif ALWAYS_VISIBLE_NAMES[name] then
        applyShallowVisible(element)
    end
end

-- Scan seluruh descendants di dalam PlayerGui
for _, desc in ipairs(PlayerGui:GetDescendants()) do
    checkElement(desc)
end

PlayerGui.DescendantAdded:Connect(checkElement)
