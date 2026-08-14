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
local ALWAYS_HIDE_ROOTS = {
    ["!!! Daily Login"] = true,
    ["!!! Update Log"] = true,
    ["Quest"] = true
}

local ALWAYS_VISIBLE_ROOTS = {
    ["Backpack"] = true,
    ["Events"] = true,
    ["Compass"] = true
}

-- PAKSA SEMBUNYIKAN SECARA DEEP (TERMASUK ELEMENT ANAKNYA)
local function forceHideItem(item)
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

local function applyAlwaysHide(root)
    forceHideItem(root)
    for _, desc in ipairs(root:GetDescendants()) do
        forceHideItem(desc)
    end
    root.DescendantAdded:Connect(forceHideItem)
end

-- PAKSA TAMPILKAN SECARA DEEP (TERMASUK SEMUA FRAME/CHILD INSIDE BACKPACK, EVENTS, COMPASS)
local function forceShowItem(item)
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

local function applyAlwaysVisible(root)
    forceShowItem(root)
    -- Terapkan pada kontainer utama (direct children) agar tombol HUD selalu muncul tanpa mengganggu sub-menu internal
    for _, child in ipairs(root:GetChildren()) do
        if child:IsA("GuiObject") then
            forceShowItem(child)
        end
    end
    root.ChildAdded:Connect(function(child)
        if child:IsA("GuiObject") then
            forceShowItem(child)
        end
    end)
end

-- MONITORING UTAMA PLAYERGUI
local function checkRoot(child)
    if ALWAYS_HIDE_ROOTS[child.Name] then
        applyAlwaysHide(child)
    elseif ALWAYS_VISIBLE_ROOTS[child.Name] then
        applyAlwaysVisible(child)
    end
end

for _, child in ipairs(PlayerGui:GetChildren()) do
    checkRoot(child)
end

PlayerGui.ChildAdded:Connect(checkRoot)
