if not game:IsLoaded() then
    game.Loaded:Wait()
end

local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local PlayerGui = (Players.LocalPlayer or Players.PlayerAdded:Wait()):WaitForChild("PlayerGui")

-- ============================================================
-- 1. DISABLE BLUR
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
-- 2. ALWAYS HIDE: Daily Login, Update Log, Quest
--    Strategi: DISABLE semua LocalScript di dalam popup
--    SEBELUM sempat jalan → logika "hide HUD" tidak pernah berjalan
-- ============================================================
local ALWAYS_HIDE = {
    ["!!! Daily Login"] = true,
    ["!!! Update Log"] = true,
    ["Quest"] = true
}

local function killScriptsInside(gui)
    pcall(function()
        for _, desc in ipairs(gui:GetDescendants()) do
            if desc:IsA("LocalScript") then
                desc.Disabled = true
            end
        end
    end)
    -- Juga kill script yang muncul belakangan
    pcall(function()
        gui.DescendantAdded:Connect(function(desc)
            if desc:IsA("LocalScript") then
                pcall(function() desc.Disabled = true end)
            end
        end)
    end)
end

local function hidePopup(gui)
    -- Step 1: KILL scripts di dalam popup (cegah hide HUD logic)
    killScriptsInside(gui)

    -- Step 2: Hide popup itu sendiri
    pcall(function()
        if gui:IsA("ScreenGui") then
            gui.Enabled = false
            gui:GetPropertyChangedSignal("Enabled"):Connect(function()
                if gui.Enabled then
                    killScriptsInside(gui)
                    gui.Enabled = false
                end
            end)
        end
    end)
end

-- ============================================================
-- 3. RESTORE HUD: Backpack, Events, Compass
--    Perbaiki properti yang mungkin sudah sempat diubah game
-- ============================================================
local HUD_CHILDREN = {
    {gui = "Backpack", child = "Display"},
    {gui = "Events",   child = "Frame"},
    {gui = "Compass",  child = "Inside"}
}

local function restoreHUD()
    -- Restore ScreenGui Enabled
    for _, t in ipairs(HUD_CHILDREN) do
        local gui = PlayerGui:FindFirstChild(t.gui)
        if gui then
            pcall(function() gui.Enabled = true end)

            local child = gui:FindFirstChild(t.child)
            if child then
                pcall(function()
                    child.Visible = true
                end)
            end
        end
    end
end

-- Heartbeat fighter: lawan perubahan selama beberapa detik
local function fightForHUD(duration)
    task.spawn(function()
        local startTime = tick()
        local conn
        conn = RunService.Heartbeat:Connect(function()
            if tick() - startTime > duration then
                conn:Disconnect()
                return
            end
            restoreHUD()
        end)
    end)
end

-- ============================================================
-- 4. HANDLER UTAMA
-- ============================================================
local processedPopups = {}

local function handleChild(child)
    if ALWAYS_HIDE[child.Name] and not processedPopups[child] then
        processedPopups[child] = true

        -- Hide popup + kill scripts
        hidePopup(child)

        -- Paksa restore HUD + lawan selama 3 detik
        fightForHUD(3)
    end
end

-- Proses semua child yang sudah ada
for _, child in ipairs(PlayerGui:GetChildren()) do
    handleChild(child)
end

-- Monitor child baru yang muncul
PlayerGui.ChildAdded:Connect(handleChild)

