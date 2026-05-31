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

-- Target Parent (CoreGui untuk Executor agar aman, PlayerGui untuk Roblox Studio)
local TargetParent = nil
local success = pcall(function()
    TargetParent = CoreGui
end)
if not success or not TargetParent then
    TargetParent = LocalPlayer:WaitForChild("PlayerGui")
end

-- Bersihkan menu lama jika ada
if TargetParent:FindFirstChild("LoriNightmareUltimateHub") then
    TargetParent.LoriNightmareUltimateHub:Destroy()
end

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

-- Helper: Cek Apakah Player Adalah Killer (The Nightmare)
local function checkIfKiller(player)
    if not player then return false end
    
    -- 1. Cek Tim Resmi (Roblox Teams)
    if player.Team then
        local tName = player.Team.Name:lower()
        -- Jika nama tim mengandung unsur survivor/lobby/spectator, dia BUKAN killer
        if tName:find("child") or tName:find("survivor") or tName:find("citizen") or tName:find("innocent") or tName:find("good") or tName:find("lobby") or tName:find("spectator") or tName:find("choosing") or tName:find("loading") or tName:find("waiting") or tName:find("surv") or tName:find("kid") then
            return false
        end
        -- Jika nama tim mengandung unsur killer/nightmare
        if tName:find("nightmare") or tName:find("killer") or tName:find("monster") or tName:find("slasher") or tName:find("hunter") or tName:find("beast") or tName:find("bad") or tName:find("enemy") or tName:find("demon") then
            return true
        end
    end
    
    -- 2. Cek Atribut khusus pada Player atau Character
    local char = player.Character
    for _, obj in ipairs({player, char}) do
        if obj then
            for _, attr in ipairs({"Role", "Team", "Class", "Type", "Status", "Character", "SelectedCharacter"}) do
                local val = obj:GetAttribute(attr)
                if val then
                    local s = tostring(val):lower()
                    if s:find("nightmare") or s:find("killer") or s:find("monster") or s:find("hunter") or s:find("beast") or s:find("demon") or s:find("slasher") then
                        return true
                    elseif s:find("child") or s:find("survivor") or s:find("citizen") or s:find("innocent") or s:find("good") or s:find("player") then
                        return false
                    end
                end
            end
        end
    end
    
    -- 3. Cek Objek Value di dalam Player / Character (e.g. StringValue "Role" atau "Team")
    for _, obj in ipairs({player, char}) do
        if obj then
            for _, child in ipairs(obj:GetChildren()) do
                if child:IsA("StringValue") or child:IsA("BoolValue") or child:IsA("ValueObject") then
                    local cName = child.Name:lower()
                    if cName:find("role") or cName:find("team") or cName:find("class") or cName:find("type") or cName:find("status") then
                        local val = tostring(child.Value):lower()
                        if val:find("nightmare") or val:find("killer") or val:find("monster") or val:find("hunter") or val:find("slasher") then
                            return true
                        elseif val:find("child") or val:find("survivor") or val:find("citizen") or val:find("innocent") then
                            return false
                        end
                    end
                end
            end
        end
    end

    -- 4. Cek Nama Model Karakter (Nama Monster: Nightmare, Carnivore, Phantom, Tarantula)
    if char then
        local cName = char.Name:lower()
        if cName:find("nightmare") or cName:find("carnivore") or cName:find("phantom") or cName:find("tarantula") or cName:find("monster") or cName:find("killer") then
            return true
        end
        
        -- 5. Cek Red Stain atau Sinar Merah Khas Killer
        for _, d in ipairs(char:GetDescendants()) do
            if d:IsA("Light") or d:IsA("PointLight") or d:IsA("SpotLight") or d:IsA("SurfaceLight") then
                -- Cek warna merah (Red dominan, Green & Blue sangat rendah)
                if d.Color.R > 0.6 and d.Color.G < 0.4 and d.Color.B < 0.4 then
                    return true
                end
            end
            if d:IsA("BasePart") and (d.Name:lower():find("redstain") or d.Name:lower():find("stain") or d.Name:lower():find("killerlight") or d.Name:lower():find("monsterlight")) then
                return true
            end
        end
        
        -- 6. Cek Senjata / Alat Serang (Held Tools)
        for _, item in ipairs(char:GetChildren()) do
            if item:IsA("Tool") or item:IsA("Weapon") then
                local iName = item.Name:lower()
                if iName:find("knife") or iName:find("weapon") or iName:find("claw") or iName:find("scythe") or iName:find("sword") or iName:find("hit") or iName:find("kill") or iName:find("attack") or iName:find("nightmare") then
                    return true
                end
            end
        end
        
        -- 7. Karakteristik Fisik (Killer berukuran raksasa atau HipHeight tinggi)
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hrp and hum then
            if hrp.Size.Y > 2.3 or hum.HipHeight > 1.7 or hum.MaxHealth > 100 then
                return true
            end
        end
    end
    
    -- 8. Fallback: Jika local player ada tim "Children", dan player ini ada tim lain yang bukan Lobby/Spectator
    if LocalPlayer.Team and player.Team then
        local lpTeam = LocalPlayer.Team.Name:lower()
        local pTeam = player.Team.Name:lower()
        if (lpTeam:find("child") or lpTeam:find("survivor")) and 
           not (pTeam:find("child") or pTeam:find("survivor") or pTeam:find("lobby") or pTeam:find("spectator")) then
            return true
        end
    end
    
    return false
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
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LoriNightmareUltimateHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = TargetParent

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 580, 0, 380)
MainFrame.Position = UDim2.new(0.5, -290, 0.5, -190)
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

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

-- Fitur 1.5: Auto Skill Check Versi 2.0 (Deteksi Adaptif & Multi-Container)
local isAutoSkillCheck = false
local guiAppearTimes = {}
local function autoSkillCheck()
    task.spawn(function()
        -- Helper: Cek Visibilitas GUI Secara Rekursif (Memastikan elemen benar-benar terlihat di layar)
        local function isGuiVisible(guiObject)
            if not guiObject then return false end
            if not guiObject:IsA("GuiObject") then return false end
            
            local current = guiObject
            while current and current:IsA("GuiObject") do
                if not current.Visible then
                    return false
                end
                current = current.Parent
            end
            
            local parentGui = guiObject:FindFirstAncestorWhichIsA("LayerCollector")
            if parentGui and not parentGui.Enabled then
                return false
            end
            
            return true
        end

        -- Helper: Cari GUI TV di Workspace jika dekat player (Mendukung QTE dalam bentuk SurfaceGui/BillboardGui di TV)
        local function getNearbyTVGui()
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not root then return nil end
            
            local tvs = findTVs()
            for _, tv in ipairs(tvs) do
                if tv and tv.Parent then
                    local dist = (tv.Position - root.Position).Magnitude
                    if dist < 18 then -- Rentang 18 studs dekat TV
                        for _, child in ipairs(tv:GetDescendants()) do
                            if (child:IsA("BillboardGui") or child:IsA("SurfaceGui")) and child.Enabled then
                                return child
                            end
                        end
                        for _, child in ipairs(tv.Parent:GetDescendants()) do
                            if (child:IsA("BillboardGui") or child:IsA("SurfaceGui")) and child.Enabled then
                                return child
                            end
                        end
                    end
                end
            end
            return nil
        end

        while isAutoSkillCheck do
            task.wait(0.005)
            
            local guisToScan = {}
            
            -- 1. Scan PlayerGui
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            if playerGui then
                for _, gui in ipairs(playerGui:GetChildren()) do
                    if (gui:IsA("ScreenGui") or gui:IsA("BillboardGui") or gui:IsA("SurfaceGui")) and gui.Enabled and gui.Name ~= "LoriNightmareUltimateHub" then
                        table.insert(guisToScan, gui)
                    end
                end
            end
            
            -- 2. Scan CoreGui (Pencegahan kegagalan / executor safety)
            pcall(function()
                if CoreGui then
                    for _, gui in ipairs(CoreGui:GetChildren()) do
                        if (gui:IsA("ScreenGui") or gui:IsA("BillboardGui") or gui:IsA("SurfaceGui")) and gui.Enabled and gui.Name ~= "LoriNightmareUltimateHub" then
                            table.insert(guisToScan, gui)
                        end
                    end
                end
            end)
            
            -- 3. Scan Workspace (Jika QTE digambar langsung pada objek TV 3D)
            local workspaceGui = getNearbyTVGui()
            if workspaceGui then
                table.insert(guisToScan, workspaceGui)
            end
            
            -- Jalankan deteksi QTE pada semua GUI yang terkumpul
            for _, gui in ipairs(guisToScan) do
                local gName = gui.Name:lower()
                local isMinigameGui = false
                
                -- Cek apakah GUI merupakan QTE/Skill Check/Repair Screen
                if gName:find("repair") or gName:find("tv") or gName:find("skill") or gName:find("qte") or gName:find("kaset") or gName:find("tape") or gName:find("cassette") or gName:find("minigame") or gName:find("play") or gName:find("interaction") or gName:find("interact") or gName:find("television") or
                   gui:FindFirstChild("Zone", true) or gui:FindFirstChild("Success", true) or gui:FindFirstChild("Circle", true) or gui:FindFirstChild("Ball", true) or gui:FindFirstChild("Target", true) or gui:FindFirstChild("Needle", true) or gui:FindFirstChild("Pointer", true) then
                    isMinigameGui = true
                end
                
                if isMinigameGui then
                    -- Nonaktifkan modal/active agar tidak mengunci pergerakan karakter atau kamera
                    pcall(function()
                        if gui:IsA("GuiObject") then
                            gui.Active = false
                        end
                        for _, child in ipairs(gui:GetDescendants()) do
                            if child:IsA("GuiObject") then
                                child.Active = false
                                if child:IsA("TextButton") or child:IsA("ImageButton") then
                                    child.Modal = false
                                end
                            end
                        end
                    end)

                    local hasPointer = gui:FindFirstChild("Pointer", true) or gui:FindFirstChild("Needle", true) or gui:FindFirstChild("Indicator", true)
                    local hasZone = gui:FindFirstChild("Zone", true) or gui:FindFirstChild("Success", true) or gui:FindFirstChild("Target", true) or gui:FindFirstChild("GreenBar", true) or gui:FindFirstChild("PerfectZone", true)
                    
                    if hasPointer and hasZone then
                        -- Cek delay pemunculan agar tidak fail di frame pertama
                        local guiId = nil
                        pcall(function() guiId = gui:GetDebugId() end)
                        guiId = guiId or tostring(gui)
                        
                        if not guiAppearTimes[guiId] then
                            guiAppearTimes[guiId] = tick()
                        end
                        
                        local elapsed = tick() - guiAppearTimes[guiId]
                        if elapsed >= 0.3 then -- Delay 0.3 detik agar game menginisialisasi rotasi jarum/sukses
                            if isGuiVisible(hasPointer) and isGuiVisible(hasZone) then
                                local pPos = hasPointer.AbsolutePosition
                                local zPos = hasZone.AbsolutePosition
                                local zSize = hasZone.AbsoluteSize
                                
                                -- 1. Deteksi apakah ini QTE Rotasi (Sudut/Lingkar) atau QTE Geser (Sliding)
                                local isRotationQTE = (pPos - zPos).Magnitude < 15 or hasPointer.Rotation ~= 0 or hasZone.Rotation ~= 0
                                
                                if isRotationQTE then
                                    -- QTE Rotasi: Bandingkan sudut rotasi (derajat)
                                    local pRot = hasPointer.AbsoluteRotation % 360
                                    local zRot = hasZone.AbsoluteRotation % 360
                                    
                                    local diff = (pRot - zRot) % 360
                                    if diff > 180 then diff = diff - 360 end
                                    
                                    if diff >= -15 and diff <= 35 then
                                        task.spawn(function()
                                            pcall(function()
                                                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                                                task.wait(0.01)
                                                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                                            end)
                                        end)
                                        task.wait(0.12)
                                    end
                                else
                                    -- QTE Geser: Bandingkan posisi fisik X/Y di layar
                                    local hOverlap = pPos.X >= (zPos.X - 5) and pPos.X <= (zPos.X + zSize.X + 5)
                                    local vOverlap = pPos.Y >= (zPos.Y - 5) and pPos.Y <= (zPos.Y + zSize.Y + 5)
                                    
                                    if hOverlap and vOverlap then
                                        task.spawn(function()
                                            pcall(function()
                                                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                                                task.wait(0.01)
                                                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                                            end)
                                        end)
                                        task.wait(0.12)
                                    end
                                end
                            end
                        end
                    else
                        -- Ini adalah QTE Lingkaran (Click). Jalankan deteksi klik mouse secara silent!
                        for _, btn in ipairs(gui:GetDescendants()) do
                            if (btn:IsA("ImageButton") or btn:IsA("TextButton") or btn:IsA("ImageLabel") or btn:IsA("Frame")) and isGuiVisible(btn) then
                                local bName = btn.Name:lower()
                                local parentName = btn.Parent and btn.Parent.Name:lower() or ""
                                
                                -- Deteksi tombol/objek lingkaran QTE
                                local isClickTarget = bName:find("circle") or bName:find("ball") or bName:find("click") or bName:find("tap") or bName:find("node") or bName:find("target") or bName:find("button") or bName:find("ring") or bName:find("hit") or
                                                      parentName:find("circle") or parentName:find("ball") or parentName:find("click") or parentName:find("tap") or parentName:find("target") or
                                                      btn:IsA("ImageButton") or btn:IsA("TextButton")
                                
                                if isClickTarget then
                                    local size = btn.AbsoluteSize
                                    local pos = btn.AbsolutePosition
                                    
                                    if size.X > 5 and size.Y > 5 and pos.X >= 0 and pos.Y >= 0 then
                                        task.spawn(function()
                                            -- A. Method 1: Silent klik menggunakan firesignal jika tersedia
                                            if firesignal then
                                                pcall(function() btn:Activate() end)
                                                pcall(function() firesignal(btn.MouseButton1Click) end)
                                                pcall(function() firesignal(btn.MouseButton1Down) end)
                                                pcall(function() firesignal(btn.Activated) end)
                                                pcall(function() firesignal(btn.InputBegan, {UserInputType = Enum.UserInputType.MouseButton1, UserInputState = Enum.UserInputState.Begin}) end)
                                                return
                                            end
                                            
                                            -- B. Method 2: Silent klik menggunakan getconnections
                                            if getconnections then
                                                if btn:IsA("ImageButton") or btn:IsA("TextButton") then
                                                    pcall(function() btn:Activate() end)
                                                    for _, conn in ipairs(getconnections(btn.MouseButton1Click)) do pcall(function() conn:Fire() end) end
                                                    for _, conn in ipairs(getconnections(btn.MouseButton1Down)) do pcall(function() conn:Fire() end) end
                                                    for _, conn in ipairs(getconnections(btn.Activated)) do pcall(function() conn:Fire() end) end
                                                end
                                                for _, conn in ipairs(getconnections(btn.InputBegan)) do
                                                    pcall(function() conn:Fire({UserInputType = Enum.UserInputType.MouseButton1, UserInputState = Enum.UserInputState.Begin}) end)
                                                end
                                                return
                                            end
                                            
                                            -- C. Method 3: Fallback klik virtual (hanya jika getconnections/firesignal tidak didukung)
                                            if btn:IsA("ImageButton") or btn:IsA("TextButton") then
                                                pcall(function() btn:Activate() end)
                                            end
                                            local centerX = pos.X + (size.X / 2)
                                            local centerY = pos.Y + (size.Y / 2)
                                            pcall(function()
                                                VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 1)
                                                task.wait(0.01)
                                                VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 1)
                                            end)
                                        end)
                                    end
                                end
                            end
                        end
                    end
                end
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

-- ESP Player Logic (Highlight modern dengan warna Killer/Survivor)
local function applyPlayerESP(player)
    if player == LocalPlayer then return end
    
    local function highlightChar(char)
        local root = char:WaitForChild("HumanoidRootPart", 8)
        if not root then return end
        
        if root:FindFirstChild("ESPHighlight") then
            root.ESPHighlight:Destroy()
        end
        
        local isKiller = checkIfKiller(player)
        local espColor = isKiller and Theme.Red or Theme.Green
        
        local hl = Instance.new("Highlight")
        hl.Name = "ESPHighlight"
        hl.Adornee = char
        hl.FillColor = espColor
        hl.FillTransparency = 0.4
        hl.OutlineColor = Theme.TextActive
        hl.OutlineTransparency = 0.1
        hl.Parent = root
    end
    
    if player.Character then
        highlightChar(player.Character)
    end
    
    local conn = player.CharacterAdded:Connect(highlightChar)
    table.insert(playerEspConns, conn)
end

local function togglePlayerESP(state)
    espPlayersActive = state
    if espPlayersActive then
        for _, p in ipairs(Players:GetPlayers()) do
            applyPlayerESP(p)
        end
        local conn = Players.PlayerAdded:Connect(applyPlayerESP)
        table.insert(playerEspConns, conn)
    else
        for _, c in ipairs(playerEspConns) do
            c:Disconnect()
        end
        playerEspConns = {}
        
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local hl = p.Character.HumanoidRootPart:FindFirstChild("ESPHighlight")
                if hl then hl:Destroy() end
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
    else
        if tvEspThread then
            pcall(function() task.cancel(tvEspThread) end)
            tvEspThread = nil
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
    -- (Sangat akurat karena game memunculkan tombol ini agar player lain bisa menolong kita saat downed)
    for _, prompt in ipairs(char:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and prompt.Enabled then
            local act = prompt.ActionText:lower()
            local obj = prompt.ObjectText:lower()
            if act:find("revive") or act:find("rescue") or act:find("help") or act:find("tolong") or act:find("save") or
               obj:find("revive") or obj:find("rescue") or obj:find("help") or obj:find("player") then
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
    
    -- 4. Cek Kecepatan Jalan (Crawling speed biasanya sangat lambat, e.g., di bawah 5)
    if hum.WalkSpeed > 0 and hum.WalkSpeed <= 5 then
        return true
    end
    
    -- 5. Attributes Check
    if char:GetAttribute("Knocked") == true or char:GetAttribute("Downed") == true or char:GetAttribute("IsKnocked") == true or char:GetAttribute("Ragdoll") == true or char:GetAttribute("Lying") == true or char:GetAttribute("Crawling") == true then
        return true
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

-- Helper: Cari Root Part Milik Killer (Mendukung Player & NPC/Bot Monster di Workspace)
local function findKillerRoot()
    -- 1. Cari Killer sebagai Player
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and checkIfKiller(p) then
            local char = p.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                return root
            end
        end
    end
    
    -- 2. Cari Killer sebagai NPC/Bot di tingkat atas Workspace
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Model") and obj ~= LocalPlayer.Character then
            local oName = obj.Name:lower()
            if oName:find("nightmare") or oName:find("killer") or oName:find("monster") or obj:GetAttribute("IsNightmare") or obj:GetAttribute("IsKiller") then
                local root = obj:FindFirstChild("HumanoidRootPart")
                if root then
                    return root
                end
            end
        end
    end
    
    -- 3. Fallback: Cari di seluruh Workspace descendants (jika monster ditaruh di dalam sub-folder map)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= LocalPlayer.Character then
            local oName = obj.Name:lower()
            if oName:find("nightmare") or oName:find("killer") or obj:GetAttribute("IsNightmare") or obj:GetAttribute("IsKiller") then
                local root = obj:FindFirstChild("HumanoidRootPart")
                if root then
                    return root
                end
            end
        end
    end
    
    return nil
end

-- Loop Auto Follow Killer saat Knocked
local isAutoFollowKiller = false
local function autoFollowKillerLoop()
    while isAutoFollowKiller do
        task.wait(0.08) -- Perbarui sedikit lebih cepat untuk pergerakan halus
        if isPlayerKnocked() then
            local killerRoot = findKillerRoot()
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            
            if root and killerRoot then
                -- Teleportasikan 3 stud di atas dan 2 stud di belakang Killer (Sangat stabil & anti-stuck)
                root.CFrame = killerRoot.CFrame * CFrame.new(0, 3, 2)
            end
        end
    end
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
    else
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
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
    else
        if infJumpConnection then
            infJumpConnection:Disconnect()
            infJumpConnection = nil
        end
    end
end

CreateToggle(BypassCard, "Noclip (Walk Through Walls)", UDim2.new(0, 10, 0, 30), false, toggleNoclip)
CreateToggle(BypassCard, "Infinite Jump in Air", UDim2.new(0, 10, 0, 65), false, toggleInfJump)
CreateToggle(BypassCard, "Auto Follow Killer when Knocked", UDim2.new(0, 10, 0, 100), false, function(state)
    isAutoFollowKiller = state
    if isAutoFollowKiller then
        task.spawn(autoFollowKillerLoop)
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
