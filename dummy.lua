if not game:IsLoaded() then
    game.Loaded:Wait()
end

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
-- ============================================================
local ALWAYS_HIDE = {
    ["!!! Daily Login"] = true,
    ["!!! Update Log"] = true,
    ["Quest"] = true
}

local function hideGui(gui)
    pcall(function()
        if gui:IsA("ScreenGui") then
            gui.Enabled = false
        elseif gui:IsA("GuiObject") then
            gui.Visible = false
        end
    end)
end

-- ============================================================
-- 3. ALWAYS VISIBLE: Backpack, Events, Compass
--    Paksa tampilkan kembali setelah popup di-hide
-- ============================================================
local RESTORE_TARGETS = {"Backpack", "Events", "Compass"}

local function restoreHUD()
    for _, name in ipairs(RESTORE_TARGETS) do
        local gui = PlayerGui:FindFirstChild(name)
        if gui then
            pcall(function()
                if gui:IsA("ScreenGui") then
                    gui.Enabled = true
                elseif gui:IsA("GuiObject") then
                    gui.Visible = true
                end
            end)
        end
    end
end

-- Pasang watcher permanen pada setiap target HUD
-- Jika game menyembunyikannya, paksa tampilkan kembali
local watchedTargets = {}

local function watchTarget(gui)
    if watchedTargets[gui] then return end
    watchedTargets[gui] = true

    pcall(function()
        if gui:IsA("ScreenGui") then
            gui:GetPropertyChangedSignal("Enabled"):Connect(function()
                if not gui.Enabled then
                    task.wait(0.05)
                    gui.Enabled = true
                end
            end)
        elseif gui:IsA("GuiObject") then
            gui:GetPropertyChangedSignal("Visible"):Connect(function()
                if not gui.Visible then
                    task.wait(0.05)
                    gui.Visible = true
                end
            end)
        end
    end)
end

local function setupHUDWatchers()
    for _, name in ipairs(RESTORE_TARGETS) do
        local gui = PlayerGui:FindFirstChild(name)
        if gui then
            watchTarget(gui)
        end
    end
end

-- ============================================================
-- 4. HANDLER UTAMA
-- ============================================================
local function handleChild(child)
    if ALWAYS_HIDE[child.Name] then
        -- Hide popup
        hideGui(child)

        -- Cegah popup muncul kembali
        pcall(function()
            if child:IsA("ScreenGui") then
                child:GetPropertyChangedSignal("Enabled"):Connect(function()
                    if child.Enabled then child.Enabled = false end
                end)
            end
        end)

        -- Setelah popup di-hide, paksa restore HUD dengan jeda agar game selesai proses
        task.spawn(function()
            task.wait(0.1)
            restoreHUD()
            task.wait(0.3)
            restoreHUD()
            task.wait(0.5)
            restoreHUD()
        end)
    end
end

-- Proses semua child yang sudah ada
for _, child in ipairs(PlayerGui:GetChildren()) do
    handleChild(child)
end

-- Setup watcher untuk HUD targets
setupHUDWatchers()

-- Monitor child baru yang muncul
PlayerGui.ChildAdded:Connect(function(child)
    handleChild(child)

    -- Jika child baru adalah target HUD, pasang watcher
    for _, name in ipairs(RESTORE_TARGETS) do
        if child.Name == name then
            watchTarget(child)
            break
        end
    end
end)
