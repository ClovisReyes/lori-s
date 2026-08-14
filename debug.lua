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
-- 2. POPUP HANDLER
-- ============================================================
local ALWAYS_HIDE = {
    ["!!! Daily Login"] = true,
    ["!!! Update Log"] = true,
    ["Quest"] = true
}

-- Cari tombol close di dalam popup
local function findCloseButton(popup)
    local main = popup:FindFirstChild("Main")
    if not main then return nil end

    -- Daily Login: Main.Close
    local btn = main:FindFirstChild("Close")
    if btn and btn:IsA("GuiButton") then return btn end

    -- Update Log: Main.Top.Exit
    local top = main:FindFirstChild("Top")
    if top then
        btn = top:FindFirstChild("Exit")
        if btn and btn:IsA("GuiButton") then return btn end
    end

    return nil
end

-- Coba close popup secara otomatis (tanpa VirtualInputManager)
local function tryAutoClose(popup)
    local closeBtn = findCloseButton(popup)
    if not closeBtn then return false end

    -- Method 1: firetouchinterest (aman, bukan VIM)
    local ok1 = pcall(function()
        firetouchinterest(closeBtn, closeBtn, 0)
    end)
    if ok1 then
        task.wait(0.05)
        pcall(function()
            firetouchinterest(closeBtn, closeBtn, 1)
        end)
        task.wait(0.5)
        if popup:IsA("ScreenGui") and not popup.Enabled then return true end
        if popup.Parent == nil then return true end
    end

    -- Method 2: fireclick
    pcall(function() fireclick(closeBtn) end)
    task.wait(0.5)
    if popup:IsA("ScreenGui") and not popup.Enabled then return true end

    -- Method 3: conn.Function langsung
    pcall(function()
        for _, conn in pairs(getconnections(closeBtn.InputBegan)) do
            conn.Function({
                UserInputType = Enum.UserInputType.Touch,
                UserInputState = Enum.UserInputState.Begin,
                Position = Vector3.new(0, 0, 0),
                Delta = Vector3.new(0, 0, 0),
                KeyCode = Enum.KeyCode.Unknown
            }, false)
        end
    end)
    task.wait(0.5)
    if popup:IsA("ScreenGui") and not popup.Enabled then return true end

    return false
end

-- Fallback: buat popup transparan, tampilkan HANYA tombol close
local function showOnlyCloseButton(popup)
    local closeBtn = findCloseButton(popup)

    -- Transparan-kan SEMUA elemen (tapi jangan Visible=false, agar child tetap render)
    for _, desc in ipairs(popup:GetDescendants()) do
        if desc ~= closeBtn then
            pcall(function()
                if desc:IsA("GuiObject") then
                    desc.BackgroundTransparency = 1
                    desc.Active = false
                end
                if desc:IsA("TextLabel") or desc:IsA("TextButton") then
                    desc.TextTransparency = 1
                    desc.TextStrokeTransparency = 1
                end
                if desc:IsA("ImageLabel") or desc:IsA("ImageButton") then
                    desc.ImageTransparency = 1
                end
            end)
        end
    end

    -- Highlight close button agar mudah ditemukan
    if closeBtn then
        pcall(function()
            closeBtn.Visible = true
            closeBtn.Active = true
            closeBtn.BackgroundTransparency = 0
            closeBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
            closeBtn.ImageTransparency = 0.5
            closeBtn.ZIndex = 100
        end)

        -- Tambah label petunjuk
        local hint = Instance.new("TextLabel")
        hint.Name = "CloseHint"
        hint.Text = "TAP X UNTUK CLOSE"
        hint.TextColor3 = Color3.fromRGB(255, 255, 0)
        hint.TextSize = 18
        hint.Font = Enum.Font.GothamBold
        hint.BackgroundTransparency = 0.3
        hint.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        hint.Size = UDim2.new(0, 220, 0, 35)
        hint.TextXAlignment = Enum.TextXAlignment.Center
        hint.Parent = closeBtn
        hint.Position = UDim2.new(0.5, -110, 1, 5)
        hint.ZIndex = 101
    end
end

-- Kill scripts di dalam popup (untuk popup yang belum sempat jalan)
local function killScriptsInside(gui)
    pcall(function()
        for _, desc in ipairs(gui:GetDescendants()) do
            if desc:IsA("LocalScript") then
                desc.Disabled = true
            end
        end
        gui.DescendantAdded:Connect(function(desc)
            if desc:IsA("LocalScript") then
                pcall(function() desc.Disabled = true end)
            end
        end)
    end)
end

-- ============================================================
-- 3. RESTORE HUD (fallback jika auto-close gagal)
-- ============================================================
local function restoreHUD()
    local targets = {
        {gui = "Backpack", child = "Display"},
        {gui = "Events",   child = "Frame"},
        {gui = "Compass",  child = "Inside"}
    }
    for _, t in ipairs(targets) do
        local gui = PlayerGui:FindFirstChild(t.gui)
        if gui then
            pcall(function() gui.Enabled = true end)
            local child = gui:FindFirstChild(t.child)
            if child then
                pcall(function() child.Visible = true end)
            end
        end
    end
end

-- ============================================================
-- 4. HANDLER UTAMA
-- ============================================================
local processedPopups = {}
local firstPopupHandled = false

local function handleChild(child)
    if not ALWAYS_HIDE[child.Name] then return end
    if processedPopups[child] then return end
    processedPopups[child] = true

    -- Quest: langsung hide saja (tidak perlu close)
    if child.Name == "Quest" then
        pcall(function()
            if child:IsA("ScreenGui") then
                child.Enabled = false
                child:GetPropertyChangedSignal("Enabled"):Connect(function()
                    if child.Enabled then child.Enabled = false end
                end)
            end
        end)
        return
    end

    -- Untuk popup berikutnya (bukan pertama): kill scripts dulu
    if firstPopupHandled then
        killScriptsInside(child)
        pcall(function()
            child.Enabled = false
            child:GetPropertyChangedSignal("Enabled"):Connect(function()
                if child.Enabled then
                    killScriptsInside(child)
                    child.Enabled = false
                end
            end)
        end)
        restoreHUD()
        return
    end

    -- Popup pertama: coba auto-close
    firstPopupHandled = true

    task.spawn(function()
        local closed = tryAutoClose(child)

        if closed then
            -- Berhasil! Game menangani restore HUD sendiri
            -- Cegah re-appear
            pcall(function()
                child:GetPropertyChangedSignal("Enabled"):Connect(function()
                    if child.Enabled then
                        killScriptsInside(child)
                        child.Enabled = false
                    end
                end)
            end)
        else
            -- Auto-close gagal → tampilkan hanya tombol close
            showOnlyCloseButton(child)

            -- Juga coba restore HUD sebagai fallback
            task.spawn(function()
                local conn
                local startTime = tick()
                conn = RunService.Heartbeat:Connect(function()
                    if tick() - startTime > 3 then
                        conn:Disconnect()
                        return
                    end
                    restoreHUD()
                end)
            end)
        end
    end)
end

-- Proses child yang sudah ada
for _, child in ipairs(PlayerGui:GetChildren()) do
    handleChild(child)
end

-- Monitor child baru
PlayerGui.ChildAdded:Connect(handleChild)
