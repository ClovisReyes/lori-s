--[[
    ========================================================================
     LORI'S NIGHTMARE - ULTIMATE UTILITY & EXPLOIT HUB (ROBLOX LUA)
    ========================================================================
     VERSI 2.1 (INTEGRASI FONT TTF KUSTOM & DETEKSI SENSOR ADAPTIF)
     Aesthetics: Ultra-Modern Dark Theme, Purple Violet Neon Gradient, Soft Borders
     Target: Lori's Nightmare Roblox (Dead by Daylight / Flee the Facility Style)
     Platform Compatibility: All major Executors (Solara, Wave, Delta, Codex, Hydrogen)
     Auto-bypass CoreGui safety & Persistent on respawn.
    ========================================================================
--]]

print("[DEBUG] Script dimulai...")

-- Error Handler Global
local function safeExecute(func, errorMsg)
    local success, err = pcall(func)
    if not success then
        warn("[ERROR] " .. errorMsg .. ":", err)
        return false
    end
    return true
end

-- ==========================================
-- 0. CONFIG LOGO KUSTOM (GITHUB RAW URL)
-- ==========================================
local GITHUB_LOGO_URL = "https://raw.githubusercontent.com/ClovisReyes/lori-s/main/Logo.png"

-- ==========================================
-- 0.5. CONFIG FONT PREMIUM ROBLOX (CLOUDFONT)
-- ==========================================
-- Menggunakan Montserrat, font geometric sans-serif modern terpopuler di Roblox
local FONT_FAMILY_ID = "rbxasset://fonts/families/Montserrat.json"

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    pcall(function()
        Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    end)
    LocalPlayer = Players.LocalPlayer
end

-- Target Parent (CoreGui jika didukung write access oleh executor, PlayerGui sebagai fallback solid)
local TargetParent = nil
local coreGuiSuccess = pcall(function()
    local testGui = Instance.new("ScreenGui")
    testGui.Parent = CoreGui
    testGui:Destroy()
    TargetParent = CoreGui
end)

if not coreGuiSuccess or not TargetParent then
    pcall(function()
        TargetParent = LocalPlayer:WaitForChild("PlayerGui", 5) or LocalPlayer:FindFirstChildOfClass("PlayerGui")
    end)
end

if not TargetParent then
    TargetParent = CoreGui
end

-- Bersihkan menu & panel lama jika ada
if TargetParent:FindFirstChild("LoriNightmareUltimateHub") then
    TargetParent.LoriNightmareUltimateHub:Destroy()
end

pcall(function()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if pg and pg:FindFirstChild("AutoFollowDiag") then
        pg.AutoFollowDiag:Destroy()
    end
end)
pcall(function()
    if CoreGui:FindFirstChild("AutoFollowDiag") then
        CoreGui.AutoFollowDiag:Destroy()
    end
end)

-- ============================================================
-- GLOBAL CLEANUP SYSTEM (Mencegah Double-Run / Spam / Lag)
-- ============================================================
if _G.LoriHubGlobals then
    print("[DEBUG] Membersihkan sesi script lama...")
    pcall(function()
        if _G.LoriHubGlobals.autoFollowConn then
            _G.LoriHubGlobals.autoFollowConn:Disconnect()
        end
    end)
    pcall(function()
        if _G.LoriHubGlobals.noclipConn then
            _G.LoriHubGlobals.noclipConn:Disconnect()
        end
    end)
    pcall(function()
        if _G.LoriHubGlobals.infJumpConn then
            _G.LoriHubGlobals.infJumpConn:Disconnect()
        end
    end)
    pcall(function()
        if _G.LoriHubGlobals.espUpdateThread then
            task.cancel(_G.LoriHubGlobals.espUpdateThread)
        end
    end)
    pcall(function()
        if _G.LoriHubGlobals.tvEspThread then
            task.cancel(_G.LoriHubGlobals.tvEspThread)
        end
    end)
    pcall(function()
        if _G.LoriHubGlobals.diagThread then
            task.cancel(_G.LoriHubGlobals.diagThread)
        end
    end)
    -- Bersihkan ESP Highlights lama
    pcall(function()
        for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
            if p.Character then
                local hl = p.Character:FindFirstChild("ESPHighlight")
                if hl then hl:Destroy() end
                -- Fallback pembersihan root jika ada sisa dari versi lama
                for _, r in ipairs({p.Character:FindFirstChild("HumanoidRootPart"), p.Character:FindFirstChildWhichIsA("BasePart")}) do
                    if r then
                        local oldHl = r:FindFirstChild("ESPHighlight")
                        if oldHl then oldHl:Destroy() end
                    end
                end
            end
        end
        -- Bersihkan juga dari model apa pun di Workspace yang memiliki ESPHighlight kustom
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj:IsA("Model") then
                local hl = obj:FindFirstChild("ESPHighlight")
                if hl then hl:Destroy() end
                local root = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")
                if root then
                    local oldHl = root:FindFirstChild("ESPHighlight")
                    if oldHl then oldHl:Destroy() end
                end
            end
        end
    end)
    print("[DEBUG] Sesi script lama berhasil dibersihkan.")
end

_G.LoriHubGlobals = {
    autoFollowConn = nil,
    noclipConn = nil,
    infJumpConn = nil,
    espUpdateThread = nil,
    tvEspThread = nil,
    diagThread = nil
}

-- ==========================================
-- 1. UTAMA & STYLING CONFIG (THEME PALETTE)
-- ==========================================
local Theme = {
    Background = Color3.fromRGB(15, 15, 20),
    Sidebar = Color3.fromRGB(10, 10, 14),
    Accent = Color3.fromRGB(138, 43, 226), -- Royal Purple
    AccentGradient = Color3.fromRGB(75, 0, 130),
    TextActive = Color3.fromRGB(255, 255, 255),
    TextMuted = Color3.fromRGB(150, 150, 160),
    CardBg = Color3.fromRGB(26, 26, 32),
    Green = Color3.fromRGB(46, 204, 113), -- Survivor Color (Neon Green)
    Red = Color3.fromRGB(231, 76, 60),    -- Killer Color (Neon Red)
    Blue = Color3.fromRGB(52, 152, 219),
    Yellow = Color3.fromRGB(241, 196, 15),
    Font = Enum.Font.GothamSemibold,      -- Fallback Font
    FontBold = Enum.Font.GothamBold       -- Fallback Font Bold
}

local function tween(object, info, properties)
    local tweenObject = TweenService:Create(object, info, properties)
    tweenObject:Play()
    return tweenObject
end

-- ==========================================
-- ==========================================
-- LOGIKA PEMUATAN FONT PREMIUM ROBLOX
-- ==========================================
local customFont = nil
local customFontBold = nil
pcall(function()
    customFont = Font.new(FONT_FAMILY_ID)
end)
pcall(function()
    customFontBold = Font.new(FONT_FAMILY_ID, Enum.FontWeight.Bold, Enum.FontStyle.Normal)
end)

-- Helper untuk Menerapkan Font ke UI Element
local function applyFont(element, isBold)
    if isBold and customFontBold then
        pcall(function()
            element.FontFace = customFontBold
        end)
    elseif customFont then
        pcall(function()
            element.FontFace = customFont
        end)
    else
        element.Font = isBold and Theme.FontBold or Theme.Font
    end
end

-- Logika Pengunduhan & Pemrosesan Otomatis Logo (GitHub / Fallback)
local customAssetLoaded = false
local finalLogoImage = "rbxassetid://18055673030" -- Fallback Default

if getcustomasset then
    local fileName = "LoriHelperLogo.png"
    local fileExists = false
    
    local fileCheck = pcall(function()
        return readfile(fileName)
    end)
    
    if fileCheck then
        fileExists = true
    elseif GITHUB_LOGO_URL and GITHUB_LOGO_URL ~= "" and writefile then
        local downloadSuccess, imgData = pcall(function()
            return game:HttpGet(GITHUB_LOGO_URL)
        end)
        
        if downloadSuccess and imgData and imgData ~= "" then
            pcall(function()
                writefile(fileName, imgData)
                fileExists = true
            end)
        end
    end
    
    if fileExists then
        local assetSuccess, assetId = pcall(function()
            return getcustomasset(fileName)
        end)
        if assetSuccess and assetId then
            finalLogoImage = assetId
            customAssetLoaded = true
        end
    end
end

-- Helper: Scan model untuk lampu merah / vision cone / senjata (biasanya dimiliki killer)
local function hasRedLightOrStain(model)
    if not model then return false end
    for _, child in ipairs(model:GetDescendants()) do
        if child:IsA("Light") then
            local color = child.Color
            if color.R > 0.85 and color.G < 0.15 and color.B < 0.15 then
                return true
            end
        elseif child:IsA("BasePart") then
            local name = child.Name:lower()
            -- Hanya cocokkan nama part eksklusif milik Killer (redstain, visioncone, redlight, lookangle).
            -- Hindari name:find("stain") karena rentan mencocokkan aksesoris bermotif survivor.
            if name == "redstain" or name == "visioncone" or name == "redlight" or name == "lookangle" then
                local color = child.Color
                if color.R > 0.85 and color.G < 0.15 and color.B < 0.15 then
                    return true
                end
            end
        end
    end
    return false
end

-- Helper: Cek Apakah Player Adalah Killer (The Nightmare)
-- PENTING: Default ke Survivor (Hijau) jika tidak yakin — mencegah false-positive
-- Deteksi killer GLOBAL & SOLID (dipakai ESP, auto-follow, panel)
-- Sinyal utama dari data asli game: atribut "SelectedMonster" hanya dimiliki killer aktif.
-- Mengembalikan: isKiller(boolean), reason(string)
local function killerInfo(player)
    if not player then return false, "no-player" end
    local sm = nil
    pcall(function() sm = player:GetAttribute("SelectedMonster") end)
    local smStr = (sm == nil) and "nil" or tostring(sm)
    if sm ~= nil then
        local s = tostring(sm):lower()
        if s ~= "" and s ~= "false" and s ~= "none" and s ~= "nil" and s ~= "0" then
            return true, "SelectedMonster=" .. smStr
        end
    end
    return false, "SelectedMonster=" .. smStr
end

local function getAttribute(player, name)
    if not player then return nil end
    local val = player:GetAttribute(name)
    if val ~= nil then return val end
    
    local char = player.Character
    if char then
        val = char:GetAttribute(name)
        if val ~= nil then return val end
    end
    return nil
end

local function checkIfKiller(player)
    if not player then return false end
    if player == LocalPlayer then return false end

    -- 0. Cek apakah ada ronde pertandingan yang sedang aktif
    local roundActive = false
    for _, p in ipairs(Players:GetPlayers()) do
        if getAttribute(p, "Lives") ~= nil then
            roundActive = true
            break
        end
    end

    -- 1. Cek Lives (Pembeda Paling Akurat & Mutlak Saat Ronde Berjalan)
    -- Jika player memiliki nyawa/Lives aktif, mereka PASTI Survivor ronde ini, abaikan semua atribut bocor dari ronde lalu!
    local hasLives = getAttribute(player, "Lives") ~= nil
    if hasLives then
        return false
    end

    -- 2. Cek Team (Sangat andal jika game menggunakan Team resmi)
    local team = player.Team
    if team then
        local tName = team.Name:lower()
        if tName:find("child") or tName:find("survivor") or tName:find("citizen") or 
           tName:find("lobby") or tName:find("spectator") or tName:find("waiting") or 
           tName:find("choosing") or tName:find("spectate") or tName:find("innocent") or 
           tName:find("human") or tName:find("people") or tName:find("surv") then
            return false
        end
        if tName:find("killer") or tName:find("nightmare") or tName:find("monster") or 
           tName:find("beast") or tName:find("slasher") or tName:find("hunter") or 
           tName:find("carnivore") or tName:find("phantom") then
            return true
        end
    end

    -- 3. Cek SelectedMonster (Atribut Killer Ronde Aktif Paling Mutlak di Player & Character)
    local sm = getAttribute(player, "SelectedMonster")
    if sm ~= nil then
        local s = tostring(sm):lower()
        if s ~= "" and s ~= "false" and s ~= "none" and s ~= "nil" and s ~= "0" then
            -- Jika ronde aktif, pastikan mereka benar-benar memiliki lampu/stain merah khas Killer.
            -- Ini menyaring mantan Killer dari ronde lalu yang atributnya bocor/tidak dihapus oleh server!
            if roundActive then
                local char = player.Character
                if char and hasRedLightOrStain(char) then
                    return true
                end
            else
                -- Di lobby, kita langsung percaya atribut SelectedMonster untuk pre-match prediction
                return true
            end
        end
    end

    -- 3b. Cek Atribut Killer Ronde Aktif Lainnya
    for _, attrName in ipairs({"Killer", "Nightmare", "IsNightmare", "IsKiller", "IsMonster", "Monster"}) do
        local v = getAttribute(player, attrName)
        if v ~= nil then
            local s = tostring(v):lower()
            if s ~= "" and s ~= "false" and s ~= "0" and s ~= "nil" and s ~= "none" then
                if roundActive then
                    local char = player.Character
                    if char and hasRedLightOrStain(char) then
                        return true
                    end
                else
                    return true
                end
            end
        end
    end

    -- 4. Cek Karakteristik Fisik (Hanya dipercayai saat ronde aktif berjalan)
    -- Ini mencegah aksesoris UGC merah/glowing milik survivor di lobby disalahartikan sebagai Killer!
    if roundActive then
        local char = player.Character
        if char then
            -- Cek Revive/Rescue prompt (Hanya ada di survivor knocked, killer tidak pernah punya ini)
            for _, obj in ipairs(char:GetDescendants()) do
                if obj:IsA("ProximityPrompt") then
                    local act = obj.ActionText:lower()
                    local name = obj.Name:lower()
                    if act:find("revive") or act:find("rescue") or act:find("help") or name:find("revive") or name:find("rescue") then
                        return false
                    end
                elseif obj:IsA("BillboardGui") or obj:IsA("TextLabel") then
                    local txt = ""
                    pcall(function() txt = obj.Text:lower() end)
                    if txt:find("help") or txt:find("rescue") or txt:find("camping") or txt:find("revive") then
                        return false
                    end
                end
            end
            
            -- Cek apakah memiliki lampu merah (red light / vision cone) khas Killer (UGC-safe)
            if hasRedLightOrStain(char) then
                return true
            end
        end
    end

    -- Default ke Survivor (Hijau) untuk menghindari false-positive pada player biasa di lobby/spectator
    return false
end

local function isPlayerKiller(player)
    return checkIfKiller(player)
end


-- Helper: Cek Apakah TV Sudah Selesai Diperbaiki
local function isTVCompleted(tvPart)
    if not tvPart or not tvPart.Parent then return true end
    
    -- Sensor 1: Check ProximityPrompt
    local prompt = tvPart:FindFirstChildOfClass("ProximityPrompt") or tvPart.Parent:FindFirstChildOfClass("ProximityPrompt")
    if prompt then
        if not prompt.Enabled then
            return true
        end
        local act = prompt.ActionText:lower()
        local obj = prompt.ObjectText:lower()
        if not (act:find("repair") or act:find("fix") or act:find("restore") or obj:find("tv") or obj:find("television")) then
            return true
        end
    end
    
    -- Sensor 2: Check Attributes & Value Objects
    for _, target in ipairs({tvPart, tvPart.Parent}) do
        if target then
            -- Status Attributes
            if target:GetAttribute("Repaired") == true or target:GetAttribute("Completed") == true or target:GetAttribute("Finished") == true or target:GetAttribute("Done") == true or target:GetAttribute("IsRepaired") == true then
                return true
            end
            
            -- Progress Attributes (0-100% or 0-1.0)
            local prog = target:GetAttribute("Progress") or target:GetAttribute("RepairProgress") or target:GetAttribute("Percent")
            if type(prog) == "number" then
                if prog >= 100 or (prog >= 1 and prog <= 1.05) then
                    return true
                end
            end
            
            -- Value Objects
            local repairedVal = target:FindFirstChild("Repaired") or target:FindFirstChild("Completed") or target:FindFirstChild("Finished") or target:FindFirstChild("Done")
            if repairedVal and (repairedVal:IsA("BoolValue") or repairedVal:IsA("ValueObject")) then
                if repairedVal.Value == true then
                    return true
                end
            end
            
            local progressVal = target:FindFirstChild("Progress") or target:FindFirstChild("RepairProgress") or target:FindFirstChild("Percent")
            if progressVal and (progressVal:IsA("NumberValue") or progressVal:IsA("IntValue")) then
                local val = progressVal.Value
                if val >= 100 or (val >= 1 and val <= 1.05) then
                    return true
                end
            end
        end
    end
    
    return false
end

-- Helper: Sensor TV Adaptif (ProximityPrompt)
local function findTVs()
    local tvList = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled then
            local actionText = obj.ActionText:lower()
            local objectText = obj.ObjectText:lower()
            
            if actionText:find("repair") or actionText:find("fix") or actionText:find("restore") or objectText:find("tv") or objectText:find("television") then
                local tvPart = obj.Parent
                local finalPart = nil
                
                if tvPart and tvPart:IsA("BasePart") then
                    finalPart = tvPart
                elseif tvPart and tvPart:IsA("Model") and tvPart.PrimaryPart then
                    finalPart = tvPart.PrimaryPart
                elseif tvPart and tvPart:IsA("Model") then
                    finalPart = tvPart:FindFirstChildWhichIsA("BasePart", true)
                end
                
                if finalPart and not isTVCompleted(finalPart) then
                    table.insert(tvList, finalPart)
                end
            end
        end
    end
    
    if #tvList == 0 then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and (obj.Name:lower():find("tv") or obj.Name:lower():find("television")) then
                if not isTVCompleted(obj) then
                    table.insert(tvList, obj)
                end
            end
        end
    end
    
    return tvList
end

-- ==========================================
-- 2. MEMBUAT INSTANCE GUI UTAMA
-- ==========================================
print("[DEBUG] Mulai membuat GUI...")
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LoriNightmareUltimateHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
print("[DEBUG] ScreenGui dibuat, parent:", TargetParent)
ScreenGui.Parent = TargetParent
local parentName = "Unknown"
pcall(function() parentName = TargetParent.Name end)
print("[DEBUG] ScreenGui di-parent ke:", parentName)

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 580, 0, 380)
MainFrame.Position = UDim2.new(0.5, -290, 0.5, -190)
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
print("[DEBUG] MainFrame dibuat")
MainFrame.Parent = ScreenGui
print("[DEBUG] MainFrame visible:", MainFrame.Visible)

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 14)
MainCorner.Parent = MainFrame

-- Border Ungu Menyala
local UIStroke = Instance.new("UIStroke")
UIStroke.Thickness = 1.5
UIStroke.Color = Theme.Accent
UIStroke.Transparency = 0.2
UIStroke.Parent = MainFrame

-- Sidebar Frame
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 165, 1, 0)
Sidebar.BackgroundColor3 = Theme.Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame

local SidebarCorner = Instance.new("UICorner")
SidebarCorner.CornerRadius = UDim.new(0, 14)
SidebarCorner.Parent = Sidebar

-- Judul Game di Sidebar
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(1, 0, 0, 55)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "LORI NIGHTMARE"
TitleLabel.TextColor3 = Theme.TextActive
TitleLabel.TextSize = 16
applyFont(TitleLabel, true)
TitleLabel.Parent = Sidebar

local TitleGradient = Instance.new("UIGradient")
TitleGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Theme.TextActive),
    ColorSequenceKeypoint.new(1, Theme.Accent)
})
TitleGradient.Parent = TitleLabel

-- Sidebar Navigation List
local NavList = Instance.new("Frame")
NavList.Name = "NavList"
NavList.Size = UDim2.new(1, -16, 1, -70)
NavList.Position = UDim2.new(0, 8, 0, 60)
NavList.BackgroundTransparency = 1
NavList.Parent = Sidebar

local NavLayout = Instance.new("UIListLayout")
NavLayout.Padding = UDim.new(0, 8)
NavLayout.SortOrder = Enum.SortOrder.LayoutOrder
NavLayout.Parent = NavList

-- Container untuk Halaman-halaman
local PagesContainer = Instance.new("Frame")
PagesContainer.Name = "PagesContainer"
PagesContainer.Size = UDim2.new(1, -185, 1, -20)
PagesContainer.Position = UDim2.new(0, 175, 0, 10)
PagesContainer.BackgroundTransparency = 1
PagesContainer.Parent = MainFrame

-- ==========================================
-- 3. FITUR GESER MENU (DRAG SYSTEM)
-- ==========================================
local dragToggle = nil
local dragSpeed = 0.08
local dragStart = nil
local startPos = nil

local function updateInput(input)
    local delta = input.Position - dragStart
    local position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    tween(MainFrame, TweenInfo.new(dragSpeed), {Position = position})
end

MainFrame.InputBegan:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        dragToggle = true
        dragStart = input.Position
        startPos = MainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragToggle = false
            end
        end)
    end
end)

MainFrame.InputChanged:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        if dragToggle then
            updateInput(input)
        end
    end
end)

-- ==========================================
-- 4. SISTEM TAB & NAVIGASI HALAMAN
-- ==========================================
local Pages = {}

local function CreatePage(name, isDefault)
    local PageFrame = Instance.new("Frame")
    PageFrame.Name = name .. "Page"
    PageFrame.Size = UDim2.new(1, 0, 1, 0)
    PageFrame.BackgroundTransparency = 1
    PageFrame.Visible = isDefault
    PageFrame.Parent = PagesContainer

    local PageList = Instance.new("UIListLayout")
    PageList.Padding = UDim.new(0, 10)
    PageList.SortOrder = Enum.SortOrder.LayoutOrder
    PageList.Parent = PageFrame

    Pages[name] = PageFrame

    -- Tombol Sidebar
    local NavBtn = Instance.new("TextButton")
    NavBtn.Name = name .. "Btn"
    NavBtn.Size = UDim2.new(1, 0, 0, 38)
    NavBtn.BackgroundColor3 = isDefault and Theme.Accent or Color3.fromRGB(20, 20, 26)
    NavBtn.Text = "   " .. name
    NavBtn.TextColor3 = isDefault and Theme.TextActive or Theme.TextMuted
    NavBtn.TextSize = 13
    applyFont(NavBtn, false)
    NavBtn.TextXAlignment = Enum.TextXAlignment.Left
    NavBtn.AutoButtonColor = false
    NavBtn.Parent = NavList

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 6)
    BtnCorner.Parent = NavBtn

    -- Hover & Click effects
    NavBtn.MouseEnter:Connect(function()
        if PagesContainer[name .. "Page"].Visible == false then
            tween(NavBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 40), TextColor3 = Theme.TextActive})
        end
    end)

    NavBtn.MouseLeave:Connect(function()
        if PagesContainer[name .. "Page"].Visible == false then
            tween(NavBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(20, 20, 26), TextColor3 = Theme.TextMuted})
        end
    end)

    NavBtn.MouseButton1Click:Connect(function()
        for pName, pFrame in pairs(Pages) do
            pFrame.Visible = false
            local associatedBtn = NavList:FindFirstChild(pName .. "Btn")
            if associatedBtn then
                tween(associatedBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(20, 20, 26), TextColor3 = Theme.TextMuted})
            end
        end
        PageFrame.Visible = true
        tween(NavBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Accent, TextColor3 = Theme.TextActive})
    end)

    return PageFrame
end

-- ==========================================
-- 5. KONSTRUKSI CARD & ELEMEN INPUT INTERAKTIF
-- ==========================================
local function CreateCard(parent, title, height)
    local Card = Instance.new("Frame")
    Card.Size = UDim2.new(1, 0, 0, height)
    Card.BackgroundColor3 = Theme.CardBg
    Card.BorderSizePixel = 0
    Card.Parent = parent

    local CardCorner = Instance.new("UICorner")
    CardCorner.CornerRadius = UDim.new(0, 8)
    CardCorner.Parent = Card

    local CardTitle = Instance.new("TextLabel")
    CardTitle.Size = UDim2.new(1, -20, 0, 25)
    CardTitle.Position = UDim2.new(0, 10, 0, 6)
    CardTitle.BackgroundTransparency = 1
    CardTitle.Text = title:upper()
    CardTitle.TextColor3 = Theme.Accent
    CardTitle.TextSize = 11
    applyFont(CardTitle, true)
    CardTitle.TextXAlignment = Enum.TextXAlignment.Left
    CardTitle.Parent = Card

    return Card
end

local function CreateButton(parent, text, pos, size, callback)
    local Btn = Instance.new("TextButton")
    Btn.Size = size
    Btn.Position = pos
    Btn.BackgroundColor3 = Theme.Accent
    Btn.Text = text
    Btn.TextColor3 = Theme.TextActive
    Btn.TextSize = 12
    applyFont(Btn, false)
    Btn.AutoButtonColor = false
    Btn.Parent = parent

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Btn

    -- Tween Effects
    Btn.MouseEnter:Connect(function()
        tween(Btn, TweenInfo.new(0.15), {Size = UDim2.new(size.X.Scale, size.X.Offset + 4, size.Y.Scale, size.Y.Offset + 2), BackgroundColor3 = Theme.AccentGradient})
    end)
    Btn.MouseLeave:Connect(function()
        tween(Btn, TweenInfo.new(0.15), {Size = size, BackgroundColor3 = Theme.Accent})
    end)
    Btn.MouseButton1Down:Connect(function()
        tween(Btn, TweenInfo.new(0.05), {Size = UDim2.new(size.X.Scale, size.X.Offset - 2, size.Y.Scale, size.Y.Offset - 2)})
    end)
    Btn.MouseButton1Up:Connect(function()
        tween(Btn, TweenInfo.new(0.05), {Size = size})
        callback()
    end)

    return Btn
end

local function CreateToggle(parent, text, pos, defaultState, callback)
    local ToggleBg = Instance.new("Frame")
    ToggleBg.Size = UDim2.new(0.9, 0, 0, 32)
    ToggleBg.Position = pos
    ToggleBg.BackgroundTransparency = 1
    ToggleBg.Parent = parent

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.7, 0, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Theme.TextActive
    Label.TextSize = 13
    applyFont(Label, false)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = ToggleBg

    local Switch = Instance.new("TextButton")
    Switch.Size = UDim2.new(0, 45, 0, 22)
    Switch.Position = UDim2.new(1, -45, 0.5, -11)
    Switch.BackgroundColor3 = defaultState and Theme.Green or Color3.fromRGB(50, 50, 60)
    Switch.Text = ""
    Switch.AutoButtonColor = false
    Switch.Parent = ToggleBg

    local SwitchCorner = Instance.new("UICorner")
    SwitchCorner.CornerRadius = UDim.new(1, 0)
    SwitchCorner.Parent = Switch

    local Indicator = Instance.new("Frame")
    Indicator.Size = UDim2.new(0, 16, 0, 16)
    Indicator.Position = defaultState and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    Indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Indicator.BorderSizePixel = 0
    Indicator.Parent = Switch

    local IndicatorCorner = Instance.new("UICorner")
    IndicatorCorner.CornerRadius = UDim.new(1, 0)
    IndicatorCorner.Parent = Indicator

    local active = defaultState
    Switch.MouseButton1Click:Connect(function()
        active = not active
        if active then
            tween(Switch, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Green})
            tween(Indicator, TweenInfo.new(0.2), {Position = UDim2.new(1, -19, 0.5, -8)})
        else
            tween(Switch, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 60)})
            tween(Indicator, TweenInfo.new(0.2), {Position = UDim2.new(0, 3, 0.5, -8)})
        end
        callback(active)
    end)
end

-- ==========================================
-- 6. PEMBUATAN ELEMEN TAB (MAIN, VISUALS, PLAYER)
-- ==========================================
local MainTab = CreatePage("Main", true)
local VisualsTab = CreatePage("Visuals", false)
local PlayerTab = CreatePage("Player", false)

-- ==========================================
-- IMPLEMENTASI TAB: MAIN (FARMING & HELPERS)
-- ==========================================
local FarmCard = CreateCard(MainTab, "Automations & Farming", 175)

-- Fitur 1: Auto Coin Farm (Teleport & Collect Coins)
local isFarmingCoins = false
local function autoFarmCoins()
    while isFarmingCoins do
        local character = LocalPlayer.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            local foundCoin = false
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") and (obj.Name:lower():find("coin") or obj.Name:lower():find("token") or obj.Name:lower():find("gold")) then
                    -- Teleport langsung ke posisi koin
                    rootPart.CFrame = obj.CFrame
                    foundCoin = true
                    task.wait(0.25) -- Jeda kecil agar server meregistrasi pengambilan koin
                    if not isFarmingCoins then break end
                end
            end
            if not foundCoin then
                -- Tidak ada koin di map saat ini
                task.wait(1)
            end
        else
            task.wait(1)
        end
    end
end

CreateToggle(FarmCard, "Auto Coin Farm (Teleport)", UDim2.new(0, 10, 0, 35), false, function(state)
    isFarmingCoins = state
    if isFarmingCoins then
        task.spawn(autoFarmCoins)
    end
end)

-- Fitur 1.5: Auto Skill Check Versi 4.4 (Presisi Tinggi, Koreksi Topbar, Multi-Metode Paralel & Hemat CPU Adaptif)
local isAutoSkillCheck = false
local function autoSkillCheck()
    -- Helper Notifikasi Layar Game (StarterGui)
    local function notify(title, text, duration)
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = title,
                Text = text,
                Duration = duration or 3
            })
        end)
    end
    
    notify("Helper QTE", "Auto Skill Check Aktif!", 3)
    
    task.spawn(function()
        local justPressed = {}
        local guiOpenedTime = {}
        
        while isAutoSkillCheck do
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            if not playerGui then
                task.wait(0.5)
                continue
            end
            
            local activeGui = nil
            local activeName = ""

            -- TAHAP 1: Cari berdasarkan NAMA GUI (mendukung variasi nama, bukan hanya exact match)
            for _, gui in ipairs(playerGui:GetChildren()) do
                if (gui:IsA("ScreenGui") or gui:IsA("GuiBase2d")) and gui.Name ~= "LoriNightmareUltimateHub" and gui.Name ~= "DebugScanner" then
                    local enabled = true
                    pcall(function() enabled = gui.Enabled end)
                    if enabled then
                        local gName = gui.Name:lower()
                        if gName == "barminigame" or gName:find("skill") or gName:find("repair") or gName:find("cassette") or gName:find("kaset") or gName:find("qte") then
                            activeGui = gui
                            activeName = "barminigame"
                            break
                        elseif gName == "minigame" or gName:find("coin") then
                            activeGui = gui
                            activeName = "minigame"
                            break
                        end
                    end
                end
            end

            -- TAHAP 2: Fallback ADAPTIF — deteksi berdasarkan STRUKTUR elemen jika nama GUI tidak dikenal
            if not activeGui then
                for _, gui in ipairs(playerGui:GetChildren()) do
                    if (gui:IsA("ScreenGui") or gui:IsA("GuiBase2d")) and gui.Name ~= "LoriNightmareUltimateHub" and gui.Name ~= "DebugScanner" then
                        local enabled = true
                        pcall(function() enabled = gui.Enabled end)
                        if enabled then
                            local hasGoal, hasBar, hasCoin = false, false, false
                            for _, d in ipairs(gui:GetDescendants()) do
                                if d:IsA("GuiObject") and d.Visible then
                                    local dn = d.Name:lower()
                                    if dn == "goal" then hasGoal = true end
                                    if dn == "bar" then hasBar = true end
                                    if dn == "coin" or dn == "goldnocoin" then hasCoin = true end
                                end
                            end
                            if hasGoal and hasBar then
                                activeGui = gui; activeName = "barminigame"; break
                            elseif hasCoin then
                                activeGui = gui; activeName = "minigame"; break
                            end
                        end
                    end
                end
            end
            
            if activeGui then
                local guiKey = activeGui
                
                if not guiOpenedTime[guiKey] then
                    guiOpenedTime[guiKey] = os.clock()
                    if activeName == "barminigame" then
                        notify("Helper QTE", "Minigame Kaset Dimulai!", 2)
                    end
                end
                
                local function isGuiVisible(obj)
                    if not obj or not obj:IsA("GuiObject") then return false end
                    local cur = obj
                    while cur and cur:IsA("GuiObject") do
                        if not cur.Visible then return false end
                        cur = cur.Parent
                    end
                    local layer = obj:FindFirstAncestorWhichIsA("LayerCollector")
                    return not (layer and not layer.Enabled)
                end
                
                -- Helper: tekan tombol keyboard fisik (fallback untuk skill check berbasis keypress)
                local function pressKey(keyCode)
                    if not VirtualInputManager then return false end
                    local ok = pcall(function()
                        VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
                        task.wait(0.03)
                        VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
                    end)
                    return ok
                end

                -- Helper klik di koordinat layar absolut (fallback bila tidak ada GUI button spesifik)
                local function clickAt(cx, cy)
                    if not VirtualInputManager then return false end
                    local ok = pcall(function()
                        VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, true, game, 1)
                        task.wait(0.01)
                        VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, false, game, 1)
                    end)
                    return ok
                end

                -- Helper klik button (isSilent=true untuk koin koin, isSilent=false untuk kaset agar menggunakan raw input fisik)
                local function clickBtn(btn, isSilent)
                    if not btn then return end
                    task.spawn(function()
                        if isSilent then
                            -- Coin QTE: Silent, virtual-only click to keep it camera-free
                            local virtualSuccess = false
                            if firesignal then
                                pcall(function() firesignal(btn.MouseButton1Click) end)
                                pcall(function() firesignal(btn.Activated) end)
                                virtualSuccess = true
                            elseif getconnections then
                                for _, event in ipairs({btn.MouseButton1Click, btn.Activated}) do
                                    for _, c in ipairs(getconnections(event)) do
                                        pcall(function() c:Fire() end)
                                    end
                                end
                                virtualSuccess = true
                            end
                            if not virtualSuccess then
                                pcall(function() btn:Activate() end)
                            end
                        else
                            -- Cassette QTE: Physical single hardware click/tap (Bypasses custom UIS and doesn't double-click)
                            local clickSuccess = false
                            if VirtualInputManager then
                                pcall(function()
                                    local guiInset = game:GetService("GuiService"):GetGuiInset()
                                    local bp = btn.AbsolutePosition
                                    local bs = btn.AbsoluteSize
                                    local cx = bp.X + bs.X / 2
                                    local cy = bp.Y + bs.Y / 2 + guiInset.Y
                                    
                                    VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, true, game, 1)
                                    task.wait(0.01)
                                    VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, false, game, 1)
                                    clickSuccess = true
                                end)
                            end
                            
                            -- Fallback virtual click jika VirtualInputManager gagal/tidak ada di executor ini
                            if not clickSuccess then
                                if firesignal then
                                    pcall(function() firesignal(btn.MouseButton1Click) end)
                                elseif getconnections then
                                    for _, c in ipairs(getconnections(btn.MouseButton1Click)) do
                                        pcall(function() c:Fire() end)
                                    end
                                else
                                    pcall(function() btn:Activate() end)
                                end
                            end
                        end
                    end)
                end
                
                if activeName == "barminigame" then
                    local skillBtn = nil
                    local bars = {}   -- semua frame bernama "bar"

                    -- Kumpulkan semua "bar" (jarum + zona target) & tombol "SkillCheck"
                    for _, d in ipairs(activeGui:GetDescendants()) do
                        if d:IsA("GuiObject") and d.Visible then
                            local dName = d.Name
                            local dNameLower = dName:lower()

                            if dNameLower == "bar" and d:IsA("Frame") then
                                table.insert(bars, d)
                            end

                            if dName == "SkillCheck" or dNameLower == "skillcheck" then
                                skillBtn = d
                            end
                        end
                    end

                    -- Fallback: cari button apapun yang ada kata "skill" atau "check"
                    if not skillBtn then
                        for _, d in ipairs(activeGui:GetDescendants()) do
                            if (d:IsA("TextButton") or d:IsA("ImageButton")) and d.Visible then
                                local dName = d.Name:lower()
                                if dName:find("skill") or dName:find("check") then
                                    skillBtn = d
                                    break
                                end
                            end
                        end
                    end

                    -- ===== Identifikasi JARUM (bergerak) vs ZONA TARGET (diam) =====
                    -- Lacak posisi tiap bar antar-frame. Yang berubah posisi = jarum.
                    _G.qteBarTracker = _G.qteBarTracker or {}
                    local tracker = _G.qteBarTracker
                    local needle, target = nil, nil
                    local maxMove, minMove = -1, math.huge

                    for _, b in ipairs(bars) do
                        local cx = b.AbsolutePosition.X + b.AbsoluteSize.X / 2
                        local prev = tracker[b]
                        local moved = prev and math.abs(cx - prev) or 0
                        tracker[b] = cx
                        -- Jarum = bar dengan pergerakan terbesar
                        if moved > maxMove then maxMove = moved; needle = b end
                        -- Target = bar dengan pergerakan terkecil (paling diam)
                        if moved < minMove then minMove = moved; target = b end
                    end

                    -- Jika cuma 1 bar atau belum bisa bedakan, jangan paksa target
                    if needle == target then target = nil end

                    -- Debug log
                    if not justPressed[guiKey] and (not _G.lastQteLog or os.clock() - _G.lastQteLog > 5) then
                        _G.lastQteLog = os.clock()
                        local debugStr = string.format("[Helper QTE] Kaset! Bars=%d Jarum=%s Target=%s Tombol=%s",
                            #bars, tostring(needle ~= nil), tostring(target ~= nil), tostring(skillBtn ~= nil))
                        print(debugStr)
                        notify("Helper QTE", debugStr, 3)
                    end

                    -- ===== TRIGGER dengan TIMING =====
                    local function fireClick()
                        justPressed[guiKey] = true
                        notify("Helper QTE", "Klik Kaset!", 1)
                        -- SILENT CLICK MURNI — identik dengan circle (firesignal MouseButton1Click + Activated)
                        if skillBtn then clickBtn(skillBtn, true) end
                        task.delay(0.25, function() justPressed[guiKey] = false end)
                    end

                    if skillBtn and not justPressed[guiKey] then
                        if needle and target then
                            -- Klik saat jarum masuk/mendekati zona target (toleransi lebar agar tidak meleset antar-frame)
                            local needleX = needle.AbsolutePosition.X + needle.AbsoluteSize.X / 2
                            local targetX = target.AbsolutePosition.X + target.AbsoluteSize.X / 2
                            -- Toleransi diperlebar: setengah lebar + 25px buffer (jarum bisa cepat)
                            local tol = (needle.AbsoluteSize.X + target.AbsoluteSize.X) / 2 + 25
                            -- Prediksi: posisi jarum di frame berikutnya (pakai kecepatan dari tracker)
                            local predictedX = needleX
                            local prev = tracker[needle]
                            if prev then predictedX = needleX + (needleX - prev) end
                            if math.abs(needleX - targetX) <= tol or math.abs(predictedX - targetX) <= tol then
                                fireClick()
                            end
                        elseif needle then
                            -- Cuma ada jarum: klik saat jarum dekat tengah track
                            local track = needle.Parent
                            if track and track:IsA("GuiObject") then
                                local needleX = needle.AbsolutePosition.X + needle.AbsoluteSize.X / 2
                                local centerX = track.AbsolutePosition.X + track.AbsoluteSize.X / 2
                                if math.abs(needleX - centerX) <= track.AbsoluteSize.X * 0.18 then
                                    fireClick()
                                end
                            end
                        elseif #bars == 0 then
                            -- Tidak ada bar terdeteksi sama sekali: klik tombol langsung (fallback)
                            fireClick()
                        end
                    end
                    
                elseif activeName == "minigame" then
                    for _, btn in ipairs(activeGui:GetDescendants()) do
                        if not (btn:IsA("ImageButton") or btn:IsA("TextButton")) then continue end
                        if not isGuiVisible(btn) then continue end
                        local sz   = btn.AbsoluteSize
                        local bpos = btn.AbsolutePosition
                        if sz.X < 5 or sz.Y < 5 or sz.X > 500 or sz.Y > 500 then continue end
                        if bpos.X < 0 or bpos.Y < 0 then continue end
                        
                        local btnName = btn.Name
                        -- Deteksi button koin: "Template", "Coin", "GoldNoCoin"
                        if btnName == "Template" or btnName == "Coin" or btnName == "GoldNoCoin" then
                            -- Hindari klik ganda button yang sama dalam waktu singkat
                            _G.qteCoinClicked = _G.qteCoinClicked or {}
                            local last = _G.qteCoinClicked[btn]
                            if not last or (os.clock() - last) > 0.4 then
                                _G.qteCoinClicked[btn] = os.clock()
                                clickBtn(btn, true) -- klik virtual silent (yang terbukti work)
                            end
                        end
                    end
                end
                task.wait()
            else
                task.wait(0.1)
            end
        end
    end)
end

CreateToggle(FarmCard, "Auto Skill Check (TV & Kaset)", UDim2.new(0, 10, 0, 75), false, function(state)
    isAutoSkillCheck = state
    if isAutoSkillCheck then
        autoSkillCheck()
    end
end)

-- Tombol Debug Scanner GUI
local debugScanGui = nil
CreateButton(FarmCard, "🔍 Debug GUI Scanner", UDim2.new(0, 10, 0, 110), UDim2.new(1, -20, 0, 28), function()
    if debugScanGui then
        debugScanGui:Destroy()
        debugScanGui = nil
        return
    end
    
    debugScanGui = Instance.new("ScreenGui")
    debugScanGui.Name = "DebugScanner"
    debugScanGui.ResetOnSpawn = false
    debugScanGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    debugScanGui.DisplayOrder = 999
    debugScanGui.Parent = LocalPlayer.PlayerGui
    
    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(0, 480, 0, 420)
    panel.Position = UDim2.new(0.5, -240, 0.5, -210)
    panel.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    panel.BorderSizePixel = 0
    panel.Parent = debugScanGui
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)
    
    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = panel
    Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)
    
    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -90, 1, 0)
    titleLbl.Position = UDim2.new(0, 12, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = "🔍 Debug Scanner - Scan saat cassette aktif"
    titleLbl.TextColor3 = Color3.fromRGB(200, 220, 255)
    titleLbl.TextSize = 12
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.TextTruncate = Enum.TextTruncate.AtEnd
    titleLbl.Parent = titleBar
    
    -- Tombol Minimize
    local isMinimized = false
    local fullHeight = UDim2.new(0, 480, 0, 420)
    local miniHeight = UDim2.new(0, 480, 0, 44)
    
    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, 32, 0, 32)
    minBtn.Position = UDim2.new(1, -78, 0, 4)
    minBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
    minBtn.Text = "—"
    minBtn.TextColor3 = Color3.fromRGB(220, 220, 255)
    minBtn.TextSize = 14
    minBtn.Font = Enum.Font.GothamBold
    minBtn.BorderSizePixel = 0
    minBtn.Parent = titleBar
    Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)
    
    minBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        if isMinimized then
            panel.Size = miniHeight
            scroll.Visible = false
            scanBtn.Visible = false
            copyBtn.Visible = false
            minBtn.Text = "□"
        else
            panel.Size = fullHeight
            scroll.Visible = true
            scanBtn.Visible = true
            copyBtn.Visible = true
            minBtn.Text = "—"
        end
    end)
    
    local closeX = Instance.new("TextButton")
    closeX.Size = UDim2.new(0, 32, 0, 32)
    closeX.Position = UDim2.new(1, -40, 0, 4)
    closeX.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    closeX.Text = "✕"
    closeX.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeX.TextSize = 14
    closeX.Font = Enum.Font.GothamBold
    closeX.BorderSizePixel = 0
    closeX.Parent = titleBar
    Instance.new("UICorner", closeX).CornerRadius = UDim.new(0, 6)
    closeX.MouseButton1Click:Connect(function()
        debugScanGui:Destroy()
        debugScanGui = nil
    end)
    
    -- Scroll frame hasil scan
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -20, 1, -90)
    scroll.Position = UDim2.new(0, 10, 0, 48)
    scroll.BackgroundColor3 = Color3.fromRGB(8, 8, 18)
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 5
    scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 120, 200)
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.Parent = panel
    Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 6)
    
    local resultText = Instance.new("TextLabel")
    resultText.Size = UDim2.new(1, -10, 0, 0)
    resultText.Position = UDim2.new(0, 5, 0, 5)
    resultText.BackgroundTransparency = 1
    resultText.TextColor3 = Color3.fromRGB(150, 255, 150)
    resultText.TextSize = 11
    resultText.Font = Enum.Font.Code
    resultText.TextXAlignment = Enum.TextXAlignment.Left
    resultText.TextYAlignment = Enum.TextYAlignment.Top
    resultText.TextWrapped = true
    resultText.AutomaticSize = Enum.AutomaticSize.Y
    resultText.Text = "Tekan  ▶ Mulai Rekam  lalu lakukan repair cassette/TV di game.\nLog perubahan GUI akan muncul di sini secara realtime."
    resultText.Parent = scroll
    
    -- Tombol bawah
    local scanBtn = Instance.new("TextButton")
    scanBtn.Size = UDim2.new(0.47, 0, 0, 32)
    scanBtn.Position = UDim2.new(0, 10, 1, -38)
    scanBtn.BackgroundColor3 = Color3.fromRGB(40, 100, 200)
    scanBtn.Text = "▶  Mulai Rekam"
    scanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    scanBtn.TextSize = 12
    scanBtn.Font = Enum.Font.GothamBold
    scanBtn.BorderSizePixel = 0
    scanBtn.Parent = panel
    Instance.new("UICorner", scanBtn).CornerRadius = UDim.new(0, 6)
    
    local copyBtn = Instance.new("TextButton")
    copyBtn.Size = UDim2.new(0.47, 0, 0, 32)
    copyBtn.Position = UDim2.new(0.53, -10, 1, -38)
    copyBtn.BackgroundColor3 = Color3.fromRGB(30, 150, 70)
    copyBtn.Text = "📋  Salin ke Clipboard"
    copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    copyBtn.TextSize = 12
    copyBtn.Font = Enum.Font.GothamBold
    copyBtn.BorderSizePixel = 0
    copyBtn.Parent = panel
    Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 6)
    
    local isRecording = false
    local logLines = {}
    local startTime = 0
    
    local function getTs()
        return string.format("[+%.1fs]", os.clock() - startTime)
    end
    
    local function addLog(line)
        table.insert(logLines, line)
        -- Batasi 2000 baris agar tidak terlalu berat
        if #logLines > 2000 then
            table.remove(logLines, 1)
        end
        resultText.Text = table.concat(logLines, "\n")
        task.wait()
        scroll.CanvasSize = UDim2.new(0, 0, 0, resultText.AbsoluteSize.Y + 15)
        -- Auto scroll ke bawah
        scroll.CanvasPosition = Vector2.new(0, math.max(0, resultText.AbsoluteSize.Y - scroll.AbsoluteSize.Y + 15))
    end
    
    scanBtn.MouseButton1Click:Connect(function()
        if isRecording then
            -- STOP
            isRecording = false
            scanBtn.Text = "▶  Mulai Rekam"
            scanBtn.BackgroundColor3 = Color3.fromRGB(40, 100, 200)
            addLog(getTs() .. " ⏹ REKAM DIHENTIKAN.")
            return
        end
        
        -- START
        isRecording = true
        logLines = {}
        startTime = os.clock()
        scanBtn.Text = "⏹  Stop Rekam"
        scanBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        addLog("[+0.0s] ▶ MULAI REKAM — lakukan repair/minigame sekarang...")
        
        task.spawn(function()
            local knownGuis = {}     -- GUI name → true
            local elemVis = {}       -- GUI name → { elemKey → visible bool }
            
            while isRecording do
                task.wait(0.3)
                if not isRecording then break end
                
                local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
                if not playerGui then continue end
                
                local currentGuis = {}
                
                for _, gui in ipairs(playerGui:GetChildren()) do
                    if not gui:IsA("ScreenGui") or not gui.Enabled then continue end
                    if gui.Name == "LoriNightmareUltimateHub" or gui.Name == "DebugScanner" then continue end
                    
                    local gName = gui.Name
                    currentGuis[gName] = true
                    
                    -- GUI BARU MUNCUL
                    if not knownGuis[gName] then
                        knownGuis[gName] = true
                        elemVis[gName] = {}
                        addLog(getTs() .. " 🆕 GUI MUNCUL: [" .. gName .. "]")
                        -- Log semua elemen visible
                        for _, d in ipairs(gui:GetDescendants()) do
                            if d:IsA("GuiObject") then
                                local t = ""
                                pcall(function() t = d.Text end)
                                local vis = d.Visible
                                local sz = d.AbsoluteSize
                                local pos = d.AbsolutePosition
                                local key = d.ClassName .. "_" .. d.Name
                                elemVis[gName][key] = vis
                                if vis then
                                    addLog(string.format("   [V] %s | %s | '%s' | %.0fx%.0f | Pos=%.0f,%.0f",
                                        d.ClassName, d.Name, t, sz.X, sz.Y, pos.X, pos.Y))
                                end
                            end
                        end
                    else
                        -- GUI SUDAH DIKENAL — cek perubahan visibility
                        if not elemVis[gName] then elemVis[gName] = {} end
                        for _, d in ipairs(gui:GetDescendants()) do
                            if d:IsA("GuiObject") then
                                local key = d.ClassName .. "_" .. d.Name
                                local nowVis = d.Visible
                                local prevVis = elemVis[gName][key]
                                
                                if prevVis ~= nowVis then
                                    elemVis[gName][key] = nowVis
                                    local t = ""
                                    pcall(function() t = d.Text end)
                                    local sz = d.AbsoluteSize
                                    local pos = d.AbsolutePosition
                                    if nowVis then
                                        addLog(string.format("%s 👁 MUNCUL [%s] %s | %s | '%s' | %.0fx%.0f | Pos=%.0f,%.0f",
                                            getTs(), gName, d.ClassName, d.Name, t, sz.X, sz.Y, pos.X, pos.Y))
                                    else
                                        addLog(string.format("%s 🙈 HILANG [%s] %s | %s",
                                            getTs(), gName, d.ClassName, d.Name))
                                    end
                                end
                            end
                        end
                    end
                end
                
                -- CEK GUI YANG MENGHILANG
                for gName in pairs(knownGuis) do
                    if not currentGuis[gName] then
                        knownGuis[gName] = nil
                        elemVis[gName] = nil
                        addLog(getTs() .. " ❌ GUI HILANG: [" .. gName .. "]")
                    end
                end
            end
        end)
    end)
    
    copyBtn.MouseButton1Click:Connect(function()
        local scanData = table.concat(logLines, "\n")
        if scanData ~= "" then
            pcall(function() setclipboard(scanData) end)
            copyBtn.Text = "✅  Tersalin!"
        else
            copyBtn.Text = "⚠  Rekam dulu!"
        end
        task.delay(1.5, function()
            if copyBtn and copyBtn.Parent then copyBtn.Text = "📋  Salin ke Clipboard" end
        end)
    end)
end)

-- Fitur 2: Teleport Ke TV Terdekat (Versi Sensor Adaptif ProximityPrompt)
local function teleportToNearestTV()
    local character = LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    local tvs = findTVs()
    local nearestTV = nil
    local shortestDist = math.huge
    
    for _, tv in ipairs(tvs) do
        local dist = (tv.Position - rootPart.Position).Magnitude
        if dist < shortestDist then
            shortestDist = dist
            nearestTV = tv
        end
    end
    
    if nearestTV then
        rootPart.CFrame = nearestTV.CFrame + Vector3.new(0, 4, 0)
    end
end

CreateButton(FarmCard, "Teleport ke TV Terdekat", UDim2.new(0, 10, 0, 120), UDim2.new(0.9, 0, 0, 35), function()
    teleportToNearestTV()
end)

-- ==========================================
-- IMPLEMENTASI TAB: VISUALS (ESP CONTROLS)
-- ==========================================
local EspCard = CreateCard(VisualsTab, "Extra Sensory Perception (ESP)", 120)

local espPlayersActive = false
local espTvsActive = false

local playerEspConns = {}
local tvEspBoxes = {}

-- ESP Player Logic (Highlight dinamis: Killer = MERAH, Survivor = HIJAU)
local espUpdateThread = nil

local function applyPlayerESP(player)
    -- Disimpan untuk kompatibilitas; pewarnaan sebenarnya dilakukan di loop dinamis
    if player == LocalPlayer then return end
end

-- Loop yang terus update warna highlight tiap player sesuai role killer/survivor (serta deteksi bot killer di workspace)
local function espUpdateLoop()
    while espPlayersActive do
        -- 1. Pindai Player Asli (Human)
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local char = player.Character
                local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart")
                if root then
                    -- Parent Highlight ke Model (char) karena engine Roblox memblokir rendering Highlight yang di-parent ke BasePart (root)
                    local hl = char:FindFirstChild("ESPHighlight")
                    if not hl then
                        hl = Instance.new("Highlight")
                        hl.Name = "ESPHighlight"
                        hl.Adornee = char
                        hl.FillTransparency = 0.4
                        hl.OutlineTransparency = 0.1
                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        pcall(function() hl.Parent = char end)
                    end
                    if hl.Adornee ~= char then hl.Adornee = char end

                        -- Tentukan warna: MERAH untuk killer, HIJAU untuk survivor
                        local isKiller = false
                        
                        -- Pengecekan pre-match / lobby: jika local player di tim lobby/spectator, paksa hijau kecuali SelectedMonster valid
                        local isLobbyMode = false
                        local myTeam = LocalPlayer.Team
                        if myTeam then
                            local mtName = myTeam.Name:lower()
                            if mtName:find("lobby") or mtName:find("spectat") or mtName:find("waiting") or mtName:find("choosing") then
                                isLobbyMode = true
                            end
                        end
                        
                        -- Cek apakah ronde sedang aktif secara global
                        local isRoundRunning = false
                        for _, p in ipairs(Players:GetPlayers()) do
                            if p:GetAttribute("Lives") ~= nil then
                                isRoundRunning = true
                                break
                            end
                        end
                        
                        if not isRoundRunning or isLobbyMode then
                            -- Di lobby / spectator mode: hanya Kugisaki (atau killer terpilih baru) yang boleh merah.
                            -- Sisanya dipaksa HIJAU.
                            local sm = getAttribute(player, "SelectedMonster")
                            if sm ~= nil then
                                local s = tostring(sm):lower()
                                if s ~= "" and s ~= "false" and s ~= "none" and s ~= "nil" and s ~= "0" then
                                    isKiller = true
                                end
                            end
                        else
                            -- Di dalam match aktif: gunakan deteksi checkIfKiller standar
                            pcall(function() isKiller = isPlayerKiller(player) end)
                        end

                        if isKiller then
                            hl.FillColor = Theme.Red
                            hl.OutlineColor = Color3.fromRGB(255, 120, 120)
                        else
                            hl.FillColor = Theme.Green
                            hl.OutlineColor = Theme.TextActive
                        end
                end
            end
        end

        -- 2. Pindai Bot/NPC Killer di Workspace (Mendukung bersarang/folders)
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj ~= LocalPlayer.Character then
                local hum = obj:FindFirstChildOfClass("Humanoid")
                local root = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")
                
                if hum and root and not Players:GetPlayerFromCharacter(obj) then
                    local oName = obj.Name:lower()
                    local isBotKiller = false
                    
                    -- Lacak senjata killer bot di descendants model
                    local hasWeapon = false
                    for _, child in ipairs(obj:GetDescendants()) do
                        if child:IsA("BasePart") or child:IsA("Model") then
                            local tName = child.Name:lower()
                            if tName:find("claw") or tName:find("knife") or tName:find("weapon") or tName:find("blade") or tName:find("axe") or tName:find("hammer") or tName:find("sword") or tName:find("bat") or tName:find("slasher") or tName:find("machete") or tName:find("cleaver") or tName:find("scythe") or tName:find("sickle") then
                                hasWeapon = true
                                break
                            end
                        end
                    end
                    
                    if oName:find("nightmare") or oName:find("monster") or oName:find("carnivore") or
                       oName:find("phantom") or oName:find("tarantula") or oName:find("spider") or
                       oName:find("slasher") or oName:find("hunter") or hasRedLightOrStain(obj) or hasWeapon then
                        isBotKiller = true
                    end
                    
                    if isBotKiller then
                        -- Parent Highlight ke Model (obj) agar ter-render sempurna oleh engine Roblox
                        local hl = obj:FindFirstChild("ESPHighlight")
                        if not hl then
                            hl = Instance.new("Highlight")
                            hl.Name = "ESPHighlight"
                            hl.Adornee = obj
                            hl.FillTransparency = 0.4
                            hl.OutlineTransparency = 0.1
                            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                            pcall(function() hl.Parent = obj end)
                        end
                        if hl.Adornee ~= obj then hl.Adornee = obj end
                        hl.FillColor = Theme.Red
                        hl.OutlineColor = Color3.fromRGB(255, 120, 120)
                    end
                end
            end
        end

        task.wait(0.5)
    end
end

local function togglePlayerESP(state)
    espPlayersActive = state
    if espPlayersActive then
        espUpdateThread = task.spawn(espUpdateLoop)
        _G.LoriHubGlobals.espUpdateThread = espUpdateThread
    else
        if espUpdateThread then
            pcall(function() task.cancel(espUpdateThread) end)
            espUpdateThread = nil
            _G.LoriHubGlobals.espUpdateThread = nil
        end
        for _, c in ipairs(playerEspConns) do
            c:Disconnect()
        end
        playerEspConns = {}
        
        -- Hapus ESP dari Player Asli (Model char)
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then
                local hl = p.Character:FindFirstChild("ESPHighlight")
                if hl then hl:Destroy() end
                -- Fallback pembersihan root versi lama
                local root = p.Character:FindFirstChild("HumanoidRootPart")
                local oldHl = root and root:FindFirstChild("ESPHighlight")
                if oldHl then oldHl:Destroy() end
            end
        end

        -- Hapus ESP dari Bot/NPC Killer di Workspace
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj:IsA("Model") then
                local hl = obj:FindFirstChild("ESPHighlight")
                if hl then hl:Destroy() end
                -- Fallback pembersihan root versi lama
                local root = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")
                local oldHl = root and root:FindFirstChild("ESPHighlight")
                if oldHl then oldHl:Destroy() end
            end
        end
    end
end

-- ESP Object Logic (TV & Coins)
local function createObjectESP(object, color, name, listTable)
    if not object:IsA("BasePart") then return end
    
    if object:FindFirstChild("ObjectESP") then
        object.ObjectESP:Destroy()
    end
    
    local bgui = Instance.new("BillboardGui")
    bgui.Name = "ObjectESP"
    bgui.Size = UDim2.new(0, 100, 0, 30)
    bgui.AlwaysOnTop = true
    bgui.Adornee = object
    bgui.Parent = object
    
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.Text = name
    text.TextColor3 = color
    text.TextSize = 11
    applyFont(text, true)
    text.Parent = bgui
    
    table.insert(listTable, bgui)
end

-- (Coin ESP Has Been Removed)

local tvEspThread = nil
local function toggleTvESP(state)
    espTvsActive = state
    if espTvsActive then
        -- Hapus ESP lama jika ada
        for _, bgui in ipairs(tvEspBoxes) do
            if bgui and bgui.Parent then bgui:Destroy() end
        end
        tvEspBoxes = {}
        
        -- Loop pembaruan dinamis agar TV yang selesai langsung disembunyikan ESP-nya
        tvEspThread = task.spawn(function()
            while espTvsActive do
                local tvs = findTVs()
                
                -- Update status ESP TV
                for _, tvPart in ipairs(tvs) do
                    if tvPart and tvPart:IsA("BasePart") then
                        local completed = isTVCompleted(tvPart)
                        local existingESP = tvPart:FindFirstChild("ObjectESP")
                        
                        if completed then
                            if existingESP then
                                existingESP:Destroy()
                            end
                        else
                            if not existingESP then
                                createObjectESP(tvPart, Theme.Blue, "📺 TV", tvEspBoxes)
                            end
                        end
                    end
                end
                
                -- Hapus ESP dari daftar jika TV sudah dihancurkan / tidak valid
                for i = #tvEspBoxes, 1, -1 do
                    local bgui = tvEspBoxes[i]
                    if not bgui or not bgui.Parent or not bgui.Parent.Parent then
                        table.remove(tvEspBoxes, i)
                    end
                end
                
                task.wait(1) -- Perbarui setiap 1 detik
            end
        end)
        _G.LoriHubGlobals.tvEspThread = tvEspThread
    else
        if tvEspThread then
            pcall(function() task.cancel(tvEspThread) end)
            tvEspThread = nil
            _G.LoriHubGlobals.tvEspThread = nil
        end
        
        for _, bgui in ipairs(tvEspBoxes) do
            if bgui and bgui.Parent then bgui:Destroy() end
        end
        tvEspBoxes = {}
    end
end

CreateToggle(EspCard, "Show Active Players (ESP)", UDim2.new(0, 10, 0, 35), false, togglePlayerESP)
CreateToggle(EspCard, "Show TVs (ESP)", UDim2.new(0, 10, 0, 75), false, toggleTvESP)

-- ==========================================
-- IMPLEMENTASI TAB: PLAYER (SPEED & PHYSICALS)
-- ==========================================
local ModifierCard = CreateCard(PlayerTab, "Movement & Physics Modifiers", 120)

-- WalkSpeed Controls
local speedVal = 16
local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0.4, 0, 0, 30)
speedLabel.Position = UDim2.new(0, 10, 0, 35)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "WalkSpeed: " .. speedVal
speedLabel.TextColor3 = Theme.TextActive
speedLabel.TextSize = 13
applyFont(speedLabel, false)
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = ModifierCard

CreateButton(ModifierCard, "+ Speed", UDim2.new(0.45, 0, 0, 35), UDim2.new(0, 70, 0, 30), function()
    speedVal = math.min(speedVal + 10, 200)
    speedLabel.Text = "WalkSpeed: " .. speedVal
    local char = LocalPlayer.Character
    if char and char:FindFirstChildOfClass("Humanoid") then
        char:FindFirstChildOfClass("Humanoid").WalkSpeed = speedVal
    end
end)

CreateButton(ModifierCard, "Reset", UDim2.new(0.70, 0, 0, 35), UDim2.new(0, 60, 0, 30), function()
    speedVal = 16
    speedLabel.Text = "WalkSpeed: " .. speedVal
    local char = LocalPlayer.Character
    if char and char:FindFirstChildOfClass("Humanoid") then
        char:FindFirstChildOfClass("Humanoid").WalkSpeed = speedVal
    end
end)

-- JumpPower Controls
local jumpVal = 50
local jumpLabel = Instance.new("TextLabel")
jumpLabel.Size = UDim2.new(0.4, 0, 0, 30)
jumpLabel.Position = UDim2.new(0, 10, 0, 75)
jumpLabel.BackgroundTransparency = 1
jumpLabel.Text = "JumpPower: " .. jumpVal
jumpLabel.TextColor3 = Theme.TextActive
jumpLabel.TextSize = 13
applyFont(jumpLabel, false)
jumpLabel.TextXAlignment = Enum.TextXAlignment.Left
jumpLabel.Parent = ModifierCard

CreateButton(ModifierCard, "+ Jump", UDim2.new(0.45, 0, 0, 75), UDim2.new(0, 70, 0, 30), function()
    jumpVal = math.min(jumpVal + 15, 300)
    jumpLabel.Text = "JumpPower: " .. jumpVal
    local char = LocalPlayer.Character
    if char and char:FindFirstChildOfClass("Humanoid") then
        local hum = char:FindFirstChildOfClass("Humanoid")
        hum.UseJumpPower = true
        hum.JumpPower = jumpVal
    end
end)

CreateButton(ModifierCard, "Reset", UDim2.new(0.70, 0, 0, 75), UDim2.new(0, 60, 0, 30), function()
    jumpVal = 50
    jumpLabel.Text = "JumpPower: " .. jumpVal
    local char = LocalPlayer.Character
    if char and char:FindFirstChildOfClass("Humanoid") then
        char:FindFirstChildOfClass("Humanoid").JumpPower = jumpVal
    end
end)

-- Player physics loops (Ensure persistent stats on respawn)
LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid")
    hum.WalkSpeed = speedVal
    if jumpVal ~= 50 then
        hum.UseJumpPower = true
        hum.JumpPower = jumpVal
    end
end)

-- Helper: Cek Apakah Player Sedang Knocked (Downed)
local function isPlayerKnocked()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    
    -- 0. Cek Health (gk ada hp / sekali pukul mati, biasanya health <= 1 atau health == 0)
    if hum.Health <= 1 then
        return true
    end
    
    -- 1. Deteksi Utama: Adanya ProximityPrompt "Revive" atau "Rescue" di karakter kita sendiri!
    -- PENTING: Jangan cek prompt.Enabled karena prompt ini dimatikan oleh game di client kita sendiri agar tidak bisa revive diri sendiri.
    -- Keberadaan prompt revive di dalam model karakter kita sendiri sudah merupakan tanda pasti downed!
    for _, prompt in ipairs(char:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            local act = prompt.ActionText:lower()
            local obj = prompt.ObjectText:lower()
            local name = prompt.Name:lower()
            if act:find("revive") or act:find("rescue") or act:find("help") or act:find("tolong") or act:find("save") or
               obj:find("revive") or obj:find("rescue") or obj:find("help") or obj:find("player") or
               name:find("revive") or name:find("rescue") or name:find("help") then
                return true
            end
        end
    end
    
    -- 2. PlatformStand Check (Sering di-set true saat merangkak/lumpuh)
    if hum.PlatformStand == true then
        return true
    end
    
    -- 3. Humanoid State Check (Physics / PlatformStanding)
    local state = hum:GetState()
    if state == Enum.HumanoidStateType.Physics or state == Enum.HumanoidStateType.PlatformStanding or state == Enum.HumanoidStateType.Ragdoll then
        return true
    end
    
    -- 4. Cek Kecepatan Jalan — WalkSpeed 0 OR sangat lambat (0-5) = kemungkinan downed/crawl
    -- Catatan: WalkSpeed=0 saat downed, bukan WalkSpeed>0
    if hum.WalkSpeed >= 0 and hum.WalkSpeed <= 4 then
        -- Pastikan ini bukan sekadar standing still: harus ada tanda lain (health rendah atau state aneh)
        if hum.Health < hum.MaxHealth * 0.3 then
            return true
        end
    end
    
    -- 4b. Cek GUI "CRAWL" di PlayerGui (spesifik Lori's Nightmare)
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    if pGui then
        for _, obj in ipairs(pGui:GetDescendants()) do
            if obj.Visible == true then
                local n = obj.Name:lower()
                local t = ""
                pcall(function() t = obj.Text:lower() end)
                if n:find("crawl") or n:find("knocked") or n:find("downed") or t:find("crawl") or t:find("crawling") then
                    return true
                end
            end
        end
    end
    
    -- 5. Attributes Check (Cek pada Player dan Character)
    for _, obj in ipairs({LocalPlayer, char}) do
        if obj then
            if obj:GetAttribute("Knocked") == true or obj:GetAttribute("Downed") == true or 
               obj:GetAttribute("IsKnocked") == true or obj:GetAttribute("Ragdoll") == true or 
               obj:GetAttribute("Lying") == true or obj:GetAttribute("Crawling") == true then
                return true
            end
        end
    end
    
    -- 6. Child elements Check
    if char:FindFirstChild("Downed") or char:FindFirstChild("Knocked") or char:FindFirstChild("Ragdoll") or char:FindFirstChild("IsKnocked") or char:FindFirstChild("KO") or char:FindFirstChild("Crawling") then
        return true
    end
    
    -- 7. Fallback health check
    if hum.Health <= 15 then
        return true
    end
    
    return false
end



local lastFollowDebugTime = 0



-- Helper: Cari Root Part Milik Killer (Mendukung Player & NPC/Bot Monster di Workspace)
local function findKillerRoot()
    local debugLog = (os.clock() - lastFollowDebugTime > 3) -- batasi print setiap 3 detik agar tidak spam
    if debugLog then
        lastFollowDebugTime = os.clock()
    end

    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local myTeamName = LocalPlayer.Team and LocalPlayer.Team.Name:lower() or "nil"

    -- DUMP DIAGNOSTIK: cetak semua player lengkap dengan tim, walkspeed, atribut (sekali tiap 3 detik)
    if debugLog then
        print("================ [AUTO-FOLLOW DIAGNOSTIK] ================")
        print("LocalPlayer Team: " .. myTeamName)
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local team = p.Team and p.Team.Name or "NO-TEAM"
                local charName = p.Character and p.Character.Name or "NO-CHAR"
                local ws = "?"
                local hp = "?"
                if p.Character then
                    local h = p.Character:FindFirstChildOfClass("Humanoid")
                    if h then ws = tostring(h.WalkSpeed); hp = tostring(math.floor(h.Health)) end
                end
                -- Kumpulkan semua atribut player
                local attrs = ""
                pcall(function()
                    for k, v in pairs(p:GetAttributes()) do
                        attrs = attrs .. k .. "=" .. tostring(v) .. " "
                    end
                end)
                print(string.format("  PLAYER: %s | Team=%s | Char=%s | WS=%s | HP=%s | Attrs:[%s]",
                    p.Name, team, charName, ws, hp, attrs))
            end
        end
        print("=========================================================")
    end

    -- ============================================================
    -- METODE 1: Gunakan isPlayerKiller (deteksi terpadu yang sama dengan ESP)
    -- Ini memastikan target follow = target merah di ESP (SelectedMonster)
    -- ============================================================
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local isKiller = false
                pcall(function() isKiller = isPlayerKiller(p) end)
                if isKiller then
                    if debugLog then print("[AUTO-FOLLOW] Killer ditemukan via SelectedMonster: " .. p.Name) end
                    return root
                end
            end
        end
    end

    -- ============================================================
    -- METODE 2: Deteksi via WalkSpeed (killer biasanya lebih cepat dari survivor)
    -- ============================================================
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local pHum = p.Character:FindFirstChildOfClass("Humanoid")
            local pRoot = p.Character:FindFirstChild("HumanoidRootPart")
            if pHum and pRoot and pHum.WalkSpeed > 18 then
                if debugLog then print("[AUTO-FOLLOW] Killer ditemukan via WalkSpeed (" .. pHum.WalkSpeed .. "): " .. p.Name) end
                return pRoot
            end
        end
    end

    -- ============================================================
    -- METODE 3: Deteksi via Red Light / Senjata di karakter player
    -- ============================================================
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            if root and hasRedLightOrStain(p.Character) then
                if debugLog then print("[AUTO-FOLLOW] Killer ditemukan via Red Light: " .. p.Name) end
                return root
            end
        end
    end

    -- ============================================================
    -- METODE 4: NPC/Bot Monster di Workspace
    -- ============================================================
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= LocalPlayer.Character then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            local root = obj:FindFirstChild("HumanoidRootPart")
            if hum and root and root:IsA("BasePart") and not root.Anchored then
                local oName = obj.Name:lower()
                -- Pastikan bukan player lain
                if not Players:GetPlayerFromCharacter(obj) then
                    if oName:find("nightmare") or oName:find("monster") or oName:find("carnivore") or
                       oName:find("phantom") or oName:find("tarantula") or oName:find("spider") or
                       oName:find("slasher") or oName:find("hunter") or hasRedLightOrStain(obj) then
                        if debugLog then print("[AUTO-FOLLOW] Killer Bot ditemukan: " .. obj.Name) end
                        return root
                    end
                end
            end
        end
    end

    -- ============================================================
    -- METODE 5 (FALLBACK): Player TERDEKAT yang BUKAN survivor terkonfirmasi
    -- Skip siapa pun yang punya atribut Survivor berisi skin survivor biasa.
    -- ============================================================
    if myRoot then
        local KILLER_SKINS2 = {
            nightmare=true, phantom=true, spectre=true, tarantula=true,
            spider=true, carnivore=true, azazil=true, slasher=true,
            monster=true, hunter=true, chaser=true
        }
        local nearest = nil
        local nearestDist = math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local root = p.Character:FindFirstChild("HumanoidRootPart")
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                if root and hum and hum.Health > 0 then
                    -- Skip player yang TERKONFIRMASI survivor (punya skin survivor valid)
                    local isConfirmedSurvivor = false
                    local sv = p:GetAttribute("Survivor")
                    if sv ~= nil then
                        local s = tostring(sv):lower()
                        if s ~= "" and not KILLER_SKINS2[s] then
                            isConfirmedSurvivor = true
                        end
                    end
                    if not isConfirmedSurvivor then
                        local dist = (root.Position - myRoot.Position).Magnitude
                        if dist < nearestDist then
                            nearestDist = dist
                            nearest = root
                        end
                    end
                end
            end
        end
        if nearest then
            if debugLog then print("[AUTO-FOLLOW] Fallback: non-survivor terdekat (jarak " .. math.floor(nearestDist) .. ")") end
            return nearest
        end
    end

    if debugLog then
        print("[AUTO-FOLLOW] Killer tidak ditemukan! Cek diagnostik di atas.")
    end
    return nil
end

-- Loop Auto Follow Killer (Mengikuti Killer Selamanya Saat Aktif & Downed)
local isAutoFollowKiller = false
local autoFollowConn = nil
local slipAwayTriggeredThisDown = false -- Kunci jeda permanen per downed state saat menekan SLIP AWAY

local function autoFollowKillerLoop()
    if autoFollowConn then
        autoFollowConn:Disconnect()
        autoFollowConn = nil
    end

    -- Notifikasi status di layar
    local function notify(title, text, duration)
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = title, Text = text, Duration = duration or 2
            })
        end)
    end

    notify("Auto Follow", "Aktif! Menunggu kondisi knocked...", 3)

    -- Monitor tombol SLIP AWAY di PlayerGui secara berkala
    task.spawn(function()
        local function virtualClick(btn)
            if not btn then return end
            if firesignal then
                pcall(function() firesignal(btn.MouseButton1Click) end)
                pcall(function() firesignal(btn.Activated) end)
            elseif getconnections then
                for _, event in ipairs({btn.MouseButton1Click, btn.Activated}) do
                    for _, c in ipairs(getconnections(event)) do
                        pcall(function() c:Fire() end)
                    end
                end
            else
                pcall(function() btn:Activate() end)
            end
        end

        local hookedButtons = {} -- Track tombol yang sudah di-hook
        while isAutoFollowKiller do
            task.wait(0.1) -- Pemindaian super cepat untuk kenyamanan auto-click
            local pGui = LocalPlayer:FindFirstChild("PlayerGui")
            if not pGui then continue end
            
            for _, obj in ipairs(pGui:GetDescendants()) do
                if (obj:IsA("TextButton") or obj:IsA("ImageButton")) and obj.Visible then
                    local n = obj.Name:lower()
                    local t = ""
                    pcall(function() t = obj.Text:lower() end)
                    
                    if n:find("slip") or t:find("slip") or n:find("away") or t:find("away") or n:find("wiggle") or t:find("wiggle") then
                        -- 1. Jalankan Auto-Clicker Virtual Super Cepat (Auto-Wiggle) secara realtime!
                        pcall(function() virtualClick(obj) end)
                        
                        -- 2. Daftarkan hook event click jika belum di-hook
                        if not hookedButtons[obj] then
                            hookedButtons[obj] = true
                            
                            local function triggerSlipAway()
                                if slipAwayTriggeredThisDown then return end
                                slipAwayTriggeredThisDown = true
                                
                                pcall(function()
                                    local char = LocalPlayer.Character
                                    if not char then return end

                                    -- 1. Hancurkan seluruh joint eksternal di client
                                    for _, part in ipairs(char:GetChildren()) do
                                        if part:IsA("BasePart") then
                                            pcall(function() part:BreakJoints() end)
                                        end
                                    end
                                    
                                    for _, child in ipairs(char:GetDescendants()) do
                                        if child:IsA("JointInstance") or child:IsA("Weld") or child:IsA("Motor6D") or child:IsA("WeldConstraint") then
                                            local p0 = child.Part0
                                            local p1 = child.Part1
                                            if p0 and p1 then
                                                if not (p0:IsDescendantOf(char) and p1:IsDescendantOf(char)) then
                                                    pcall(function() child:Destroy() end)
                                                end
                                            end
                                        end
                                    end

                                    -- 2. Trik Premium: Lepas parent parts karakter sementara ke nil untuk memutuskan joint di server secara permanen!
                                    local partsToReset = {}
                                    for _, part in ipairs(char:GetChildren()) do
                                        if part:IsA("BasePart") then
                                            table.insert(partsToReset, {
                                                Part = part,
                                                OriginalParent = char,
                                                OriginalCFrame = part.CFrame
                                            })
                                        end
                                    end
                                    
                                    for _, data in ipairs(partsToReset) do
                                        pcall(function() data.Part.Parent = nil end)
                                    end
                                    
                                    task.wait(0.08)
                                    
                                    for _, data in ipairs(partsToReset) do
                                        pcall(function()
                                            data.Part.Parent = data.OriginalParent
                                            data.Part.CFrame = data.OriginalCFrame
                                        end)
                                    end

                                    -- 3. Pulihkan kondisi fisik karakter
                                    local hum = char:FindFirstChildOfClass("Humanoid")
                                    if hum then
                                        hum.PlatformStand = false
                                        pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
                                    end

                                    -- 4. Teleportasi Kontinu Selama 1.5 Detik untuk menembus server-side rubberbanding!
                                    local startTime = os.clock()
                                    local teleportLoop
                                    teleportLoop = RunService.Heartbeat:Connect(function()
                                        if not isAutoFollowKiller or os.clock() - startTime > 1.5 then
                                            if teleportLoop then
                                                teleportLoop:Disconnect()
                                                teleportLoop = nil
                                            end
                                            return
                                        end
                                        
                                        local root = char:FindFirstChild("HumanoidRootPart")
                                        if root then
                                            root.Anchored = false
                                            pcall(function()
                                                root.Velocity = Vector3.zero
                                                root.RotVelocity = Vector3.zero
                                                root.AssemblyLinearVelocity = Vector3.zero
                                                root.AssemblyAngularVelocity = Vector3.zero
                                            end)
                                            
                                            local killerRoot = findKillerRoot()
                                            if killerRoot then
                                                root.CFrame = killerRoot.CFrame * CFrame.new(0, 4, 15)
                                            else
                                                root.CFrame = root.CFrame * CFrame.new(0, 15, 0)
                                            end
                                        end
                                    end)
                                end)
                                
                                notify("Auto Follow", "Slip Away! Terlepas & teleport kontinu.", 3)
                            end
                            
                            pcall(function() obj.MouseButton1Click:Connect(triggerSlipAway) end)
                            pcall(function() obj.Activated:Connect(triggerSlipAway) end)
                            
                            -- Pemicu otomatis teleportasi setelah 0.8 detik tombol muncul (mengakomodasi waktu auto-wiggle)
                            task.delay(0.8, function()
                                if obj and obj.Parent and obj.Visible then
                                    triggerSlipAway()
                                end
                            end)
                        end
                    end
                end
            end
        end
    end)
    
    -- Helper: Deteksi apakah karakter kita sedang di-weld (di-grab/carry) oleh objek luar
    local function isPlayerWelded(myChar, kRoot)
        if not myChar then return false end
        local kChar = kRoot and kRoot.Parent
        
        -- Scan joints di karakter kita sendiri
        for _, child in ipairs(myChar:GetDescendants()) do
            if child:IsA("Weld") or child:IsA("Motor6D") or child:IsA("WeldConstraint") then
                local p0 = child.Part0
                local p1 = child.Part1
                if p0 and p1 then
                    if not p0:IsDescendantOf(myChar) or not p1:IsDescendantOf(myChar) then
                        return true
                    end
                end
            end
        end
        
        -- Scan joints di karakter killer
        if kChar then
            for _, child in ipairs(kChar:GetDescendants()) do
                if child:IsA("Weld") or child:IsA("Motor6D") or child:IsA("WeldConstraint") then
                    local p0 = child.Part0
                    local p1 = child.Part1
                    if p0 and p1 then
                        if p0:IsDescendantOf(myChar) or p1:IsDescendantOf(myChar) then
                            return true
                        end
                    end
                end
            end
        end
        
        return false
    end

    -- Gunakan Heartbeat agar update setiap frame (sangat smooth & tidak bisa dilewati)
    autoFollowConn = RunService.Heartbeat:Connect(function()
        if not isAutoFollowKiller then
            autoFollowConn:Disconnect()
            autoFollowConn = nil
            return
        end
        
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        
        if root then
            -- Hanya berteleportasi jika kita knocked/downed (sehat = bisa main biasa)
            if not isPlayerKnocked() then
                slipAwayTriggeredThisDown = false -- Reset status agar siap digunakan di downed berikutnya
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and hum.PlatformStand then
                    hum.PlatformStand = false
                end
                return
            end

            -- Jika sudah menekan slip away di downed saat ini, jangan teleport lagi sampai sehat!
            if slipAwayTriggeredThisDown then
                return
            end

            local killerRoot = findKillerRoot()
            if killerRoot then
                -- Cek apakah kita sedang digendong (welded) oleh Killer secara fisik
                local welded = false
                pcall(function() welded = isPlayerWelded(char, killerRoot) end)
                
                if not welded then
                    if root.Anchored then
                        root.Anchored = false
                    end
                    
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum and not hum.PlatformStand then
                        hum.PlatformStand = true
                    end
                    
                    -- Teleportasi presisi & kontinu (nempel erat 3 stud ke atas, 2 stud di belakang Killer)
                    root.CFrame = killerRoot.CFrame * CFrame.new(0, 3, 2)
                end
            end
        end
    end)
    _G.LoriHubGlobals.autoFollowConn = autoFollowConn
end

-- Bypass & Movement Physics Card (No-clip & Inf Jump)
local BypassCard = CreateCard(PlayerTab, "Bypass Mechanics", 135)

-- Noclip Toggle
local noclipConnection = nil
local isNoclipping = false
local function toggleNoclip(state)
    isNoclipping = state
    if isNoclipping then
        noclipConnection = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end)
        _G.LoriHubGlobals.noclipConn = noclipConnection
    else
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
            _G.LoriHubGlobals.noclipConn = nil
        end
    end
end

-- Infinite Jump Toggle
local infJumpConnection = nil
local isInfJumping = false
local function toggleInfJump(state)
    isInfJumping = state
    if isInfJumping then
        infJumpConnection = UserInputService.JumpRequest:Connect(function()
            local char = LocalPlayer.Character
            if char and char:FindFirstChildOfClass("Humanoid") then
                char:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
        _G.LoriHubGlobals.infJumpConn = infJumpConnection
    else
        if infJumpConnection then
            infJumpConnection:Disconnect()
            infJumpConnection = nil
            _G.LoriHubGlobals.infJumpConn = nil
        end
    end
end

CreateToggle(BypassCard, "Noclip (Walk Through Walls)", UDim2.new(0, 10, 0, 30), false, toggleNoclip)
CreateToggle(BypassCard, "Infinite Jump in Air", UDim2.new(0, 10, 0, 65), false, toggleInfJump)
CreateToggle(BypassCard, "Auto Follow Killer (Always)", UDim2.new(0, 10, 0, 100), false, function(state)
    isAutoFollowKiller = state
    if isAutoFollowKiller then
        task.spawn(autoFollowKillerLoop)
    else
        pcall(function()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.PlatformStand = false
            end
        end)
    end
end)

-- ==========================================
-- 7. SISTEM MINIMIZE LOGO (LOGO KUSTOM USER)
-- ==========================================
-- Membuat Tombol Floating Persegi Sisi Tumpul dengan fallback text N
local MinimizeIcon = Instance.new("ImageButton")
MinimizeIcon.Name = "MinimizeIcon"
MinimizeIcon.Size = UDim2.new(0, 52, 0, 52)
MinimizeIcon.Position = UDim2.new(0.05, 0, 0.2, 0)
MinimizeIcon.BackgroundColor3 = Color3.fromRGB(5, 15, 35) -- Biru dongker menyala gelap matching logo user
MinimizeIcon.BorderSizePixel = 0
MinimizeIcon.Image = finalLogoImage
MinimizeIcon.Visible = false
MinimizeIcon.ClipsDescendants = true
MinimizeIcon.Parent = ScreenGui

local IconCorner = Instance.new("UICorner")
IconCorner.CornerRadius = UDim.new(0, 12) -- Persegi Sisi Tumpul (Rounded Square)
IconCorner.Parent = MinimizeIcon

local IconStroke = Instance.new("UIStroke")
IconStroke.Thickness = 2
IconStroke.Color = Color3.fromRGB(0, 85, 255) -- Glowing Neon Blue
IconStroke.Transparency = 0.2
IconStroke.Parent = MinimizeIcon

-- Fallback text 'N' putih elegan jika ID gambar belum dimuat
local FallbackText = Instance.new("TextLabel")
FallbackText.Size = UDim2.new(1, 0, 1, 0)
FallbackText.BackgroundTransparency = 1
FallbackText.Text = "N"
FallbackText.TextColor3 = Theme.TextActive
FallbackText.TextSize = 24
applyFont(FallbackText, true)
FallbackText.Parent = MinimizeIcon

-- Sembunyikan tulisan fallback jika kustom asset berhasil terpasang
if customAssetLoaded then
    FallbackText.Visible = false
end

-- Membuat Tombol Floating Draggable (Bisa digeser)
local iconDragToggle = nil
local iconDragStart = nil
local iconStartPos = nil

MinimizeIcon.InputBegan:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        iconDragToggle = true
        iconDragStart = input.Position
        iconStartPos = MinimizeIcon.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                iconDragToggle = false
            end
        end)
    end
end)

MinimizeIcon.InputChanged:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        if iconDragToggle then
            local delta = input.Position - iconDragStart
            local position = UDim2.new(iconStartPos.X.Scale, iconStartPos.X.Offset + delta.X, iconStartPos.Y.Scale, iconStartPos.Y.Offset + delta.Y)
            tween(MinimizeIcon, TweenInfo.new(0.08), {Position = position})
        end
    end
end)

-- ==========================================
-- 8. TOMBOL ACTION: MINIMIZE & CLOSE PADA PANEL UTAMA
-- ==========================================
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Name = "MinimizeBtn"
MinimizeBtn.Size = UDim2.new(0, 32, 0, 32)
MinimizeBtn.Position = UDim2.new(1, -70, 0, 8)
MinimizeBtn.BackgroundTransparency = 1
MinimizeBtn.Text = "—"
MinimizeBtn.TextColor3 = Theme.TextMuted
MinimizeBtn.TextSize = 14
applyFont(MinimizeBtn, true)
MinimizeBtn.Parent = MainFrame

MinimizeBtn.MouseEnter:Connect(function()
    tween(MinimizeBtn, TweenInfo.new(0.2), {TextColor3 = Theme.Accent})
end)
MinimizeBtn.MouseLeave:Connect(function()
    tween(MinimizeBtn, TweenInfo.new(0.2), {TextColor3 = Theme.TextMuted})
end)

-- Fungsi Pemicu Minimize
MinimizeBtn.MouseButton1Click:Connect(function()
    tween(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 0, 0, 0),
        Position = MainFrame.Position + UDim2.new(0, 290, 0, 190),
        BackgroundTransparency = 1
    })
    task.wait(0.25)
    MainFrame.Visible = false
    
    MinimizeIcon.Visible = true
    MinimizeIcon.Size = UDim2.new(0, 0, 0, 0)
    tween(MinimizeIcon, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 52, 0, 52)
    })
end)

-- Fungsi Pemicu Maximize (Klik Logo Floating untuk Membuka Kembali)
MinimizeIcon.MouseButton1Click:Connect(function()
    if iconDragToggle then return end
    
    tween(MinimizeIcon, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0)
    })
    task.wait(0.2)
    MinimizeIcon.Visible = false
    
    MainFrame.Visible = true
    tween(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 580, 0, 380),
        Position = UDim2.new(0.5, -290, 0.5, -190),
        BackgroundTransparency = 0
    })
end)

-- Tombol Tutup GUI (Close Button)
local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -38, 0, 8)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Theme.TextMuted
CloseBtn.TextSize = 18
applyFont(CloseBtn, true)
CloseBtn.Parent = MainFrame

CloseBtn.MouseEnter:Connect(function()
    tween(CloseBtn, TweenInfo.new(0.2), {TextColor3 = Theme.Red})
end)
CloseBtn.MouseLeave:Connect(function()
    tween(CloseBtn, TweenInfo.new(0.2), {TextColor3 = Theme.TextMuted})
end)

CloseBtn.MouseButton1Click:Connect(function()
    isFarmingCoins = false
    isAutoSkillCheck = false
    isAutoFollowKiller = false
    toggleNoclip(false)
    toggleInfJump(false)
    togglePlayerESP(false)
    toggleTvESP(false)
    
    tween(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 0, 0, 0),
        Position = MainFrame.Position + UDim2.new(0, 290, 0, 190),
        BackgroundTransparency = 1
    })
    task.wait(0.3)
    ScreenGui:Destroy()
end)

print("[LORI'S ULTIMATE HUB] Berhasil di-inject! Nikmati automasi premium.")
print("[DEBUG] GUI seharusnya sudah muncul. Cek F9 console untuk detail.")
local screenGuiParentStr = "nil"
pcall(function() screenGuiParentStr = tostring(ScreenGui.Parent) end)
print("[DEBUG] ScreenGui.Parent:", screenGuiParentStr)
print("[DEBUG] MainFrame.Visible:", MainFrame.Visible)
print("[DEBUG] MainFrame.Size:", MainFrame.Size)
