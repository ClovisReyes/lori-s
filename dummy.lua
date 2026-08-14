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
-- 2. CAPTURE POSISI NORMAL HUD (sebelum popup muncul)
-- ============================================================
local HUD_TARGETS = {
    {gui = "Backpack", child = "Display"},
    {gui = "Events",   child = "Frame"},
    {gui = "Compass",  child = "Inside"}
}

-- Simpan posisi asli setiap target
local savedData = {}

local function captureOriginal(guiName, childName)
    local key = guiName .. "." .. childName
    if savedData[key] then return end

    local gui = PlayerGui:FindFirstChild(guiName)
    if not gui then return end
    local child = gui:FindFirstChild(childName)
    if not child then return end

    savedData[key] = {
        obj = child,
        parentGui = gui,
        Position = child.Position,
        Visible = child.Visible
    }
end

-- Coba capture segera (sebelum popup sempat tween)
for _, t in ipairs(HUD_TARGETS) do
    captureOriginal(t.gui, t.child)
end

-- ============================================================
-- 3. RESTORE HUD - paksa posisi kembali + lawan tween
-- ============================================================
local function restoreHUD()
    for _, t in ipairs(HUD_TARGETS) do
        local key = t.gui .. "." .. t.child
        local data = savedData[key]
        if data and data.obj then
            pcall(function()
                data.obj.Visible = true
                data.obj.Position = data.Position
                data.parentGui.Enabled = true
            end)
        else
            -- Fallback: cari ulang dan paksa tampilkan
            local gui = PlayerGui:FindFirstChild(t.gui)
            if gui then
                local child = gui:FindFirstChild(t.child)
                if child then
                    pcall(function()
                        child.Visible = true
                        gui.Enabled = true
                    end)
                end
            end
        end
    end
end

-- Lawan tween game selama beberapa detik dengan Heartbeat
local function fightTweenAndRestore()
    task.spawn(function()
        local conn
        local startTime = tick()
        -- Lawan selama 5 detik untuk memastikan semua tween game kalah
        conn = RunService.Heartbeat:Connect(function()
            if tick() - startTime > 5 then
                conn:Disconnect()
                return
            end
            restoreHUD()
        end)
    end)
end

-- ============================================================
-- 4. HIDE POPUP + TRIGGER RESTORE
-- ============================================================
local ALWAYS_HIDE = {
    ["!!! Daily Login"] = true,
    ["!!! Update Log"] = true,
    ["Quest"] = true
}

local hiddenPopups = {}

local function handleChild(child)
    if not ALWAYS_HIDE[child.Name] then return end
    if hiddenPopups[child] then return end
    hiddenPopups[child] = true

    -- Hide popup
    pcall(function()
        if child:IsA("ScreenGui") then
            child.Enabled = false
            child:GetPropertyChangedSignal("Enabled"):Connect(function()
                if child.Enabled then
                    child.Enabled = false
                    -- Popup coba muncul lagi, lawan lagi
                    fightTweenAndRestore()
                end
            end)
        end
    end)

    -- Capture ulang posisi (jika belum tercapture di awal)
    for _, t in ipairs(HUD_TARGETS) do
        captureOriginal(t.gui, t.child)
    end

    -- Paksa restore HUD + lawan tween
    fightTweenAndRestore()
end

-- Proses child yang sudah ada
for _, child in ipairs(PlayerGui:GetChildren()) do
    handleChild(child)
end

-- Monitor child baru
PlayerGui.ChildAdded:Connect(function(child)
    handleChild(child)

    -- Jika child baru adalah salah satu HUD target, capture posisinya
    for _, t in ipairs(HUD_TARGETS) do
        if child.Name == t.gui then
            task.wait(0.1) -- Tunggu child selesai di-setup game
            captureOriginal(t.gui, t.child)
        end
    end
end)
