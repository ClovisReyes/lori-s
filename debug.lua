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
-- 2. CARI TOMBOL CLOSE
-- ============================================================
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

-- ============================================================
-- 3. TRANSPARAN-KAN POPUP, SISAKAN TOMBOL CLOSE
--    User tap 1x → game close & restore HUD sendiri
-- ============================================================
local function transparentizePopup(popup)
    local closeBtn = findCloseButton(popup)

    -- Sembunyikan SEMUA konten visual (tapi jangan Visible=false)
    for _, desc in ipairs(popup:GetDescendants()) do
        if desc ~= closeBtn then
            pcall(function()
                if desc:IsA("GuiObject") then
                    desc.BackgroundTransparency = 1
                    desc.Active = false
                end
            end)
            pcall(function()
                if desc:IsA("TextLabel") or desc:IsA("TextButton") then
                    desc.TextTransparency = 1
                    desc.TextStrokeTransparency = 1
                end
            end)
            pcall(function()
                if desc:IsA("ImageLabel") or desc:IsA("ImageButton") then
                    desc.ImageTransparency = 1
                end
            end)
        end
    end

    -- Highlight tombol close
    if closeBtn then
        pcall(function()
            closeBtn.Visible = true
            closeBtn.Active = true
            closeBtn.BackgroundTransparency = 0
            closeBtn.BackgroundColor3 = Color3.fromRGB(255, 30, 30)
            closeBtn.ImageTransparency = 1
            closeBtn.ZIndex = 100
        end)

        -- Buat label "TAP DISINI"
        pcall(function()
            local hint = Instance.new("TextLabel")
            hint.Name = "Hint"
            hint.Text = "⬆ TAP UNTUK CLOSE ⬆"
            hint.TextColor3 = Color3.fromRGB(255, 255, 0)
            hint.TextSize = 16
            hint.Font = Enum.Font.GothamBold
            hint.BackgroundTransparency = 0.2
            hint.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            hint.Size = UDim2.new(0, 230, 0, 30)
            hint.Position = UDim2.new(0.5, -115, 1, 5)
            hint.ZIndex = 101
            hint.Parent = closeBtn
        end)
    end
end

-- ============================================================
-- 4. KILL SCRIPTS (untuk popup berikutnya yg belum jalan)
-- ============================================================
local function killAndHide(gui)
    pcall(function()
        for _, desc in ipairs(gui:GetDescendants()) do
            if desc:IsA("LocalScript") then
                desc.Disabled = true
            end
        end
    end)
    pcall(function()
        gui.Enabled = false
        gui:GetPropertyChangedSignal("Enabled"):Connect(function()
            if gui.Enabled then gui.Enabled = false end
        end)
    end)
end

-- ============================================================
-- 5. HANDLER UTAMA
-- ============================================================
local firstHandled = false
local processed = {}

local function handleChild(child)
    if not child:IsA("ScreenGui") then return end
    if processed[child] then return end

    local name = child.Name

    -- Quest: langsung hide
    if name == "Quest" then
        processed[child] = true
        pcall(function()
            child.Enabled = false
            child:GetPropertyChangedSignal("Enabled"):Connect(function()
                if child.Enabled then child.Enabled = false end
            end)
        end)
        return
    end

    -- Daily Login / Update Log
    if name == "!!! Daily Login" or name == "!!! Update Log" then
        processed[child] = true

        if firstHandled then
            -- Popup ke-2 dst: script sudah jalan, kill + hide langsung
            killAndHide(child)
        else
            -- Popup pertama: transparan-kan, user tap Close 1x
            firstHandled = true
            transparentizePopup(child)

            -- Setelah user close, cegah muncul lagi
            child:GetPropertyChangedSignal("Enabled"):Connect(function()
                if not child.Enabled then
                    -- Game sudah close popup → cegah re-appear
                    task.wait(2)
                    child:GetPropertyChangedSignal("Enabled"):Connect(function()
                        if child.Enabled then child.Enabled = false end
                    end)
                end
            end)
        end
    end
end

-- Proses yang sudah ada
for _, child in ipairs(PlayerGui:GetChildren()) do
    handleChild(child)
end

-- Monitor baru
PlayerGui.ChildAdded:Connect(handleChild)
