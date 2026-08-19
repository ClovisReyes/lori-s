-- ==========================================================================
--  🐟 FISH IT: AUTO BOOTH PLAZA (NOIR ENGINE v2.1)
--  100% STEALTH & GUARANTEED FLOATING SCREEN HUD FOR CLOUDPHONE / DELTA
-- ==========================================================================

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
    task.wait(0.1)
    LocalPlayer = Players.LocalPlayer
end

-- ==========================================================================
-- 1. INSTANT FLOATING SCREEN HUD (CREATED FIRST BEFORE ANY BLOCKING CALLS)
-- ==========================================================================
local parentGui
if gethui then
    pcall(function() parentGui = gethui() end)
end
if not parentGui then
    parentGui = LocalPlayer:WaitForChild("PlayerGui", 5)
end
if not parentGui then
    pcall(function() parentGui = game:GetService("CoreGui") end)
end

if parentGui and parentGui:FindFirstChild("NoirBoothHUD") then
    pcall(function() parentGui.NoirBoothHUD:Destroy() end)
end

local hudGui = Instance.new("ScreenGui")
hudGui.Name = "NoirBoothHUD"
hudGui.ResetOnSpawn = false
hudGui.IgnoreGuiInset = true
hudGui.DisplayOrder = 999999
hudGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 260, 0, 80)
mainFrame.Position = UDim2.new(0.5, -130, 0, 20)
mainFrame.BackgroundColor3 = Color3.fromRGB(13, 16, 23)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.ZIndex = 100
mainFrame.Parent = hudGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = mainFrame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(0, 210, 255)
stroke.Thickness = 1.5
stroke.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -20, 0, 24)
titleLabel.Position = UDim2.new(0, 10, 0, 4)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🐟 NOIR AUTO BOOTH v2.1"
titleLabel.TextColor3 = Color3.fromRGB(0, 210, 255)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 12
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 101
titleLabel.Parent = mainFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 44)
statusLabel.Position = UDim2.new(0, 10, 0, 28)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Memulai inisialisasi..."
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.Font = Enum.Font.GothamMedium
statusLabel.TextSize = 10
statusLabel.TextWrapped = true
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.ZIndex = 101
statusLabel.Parent = mainFrame

-- Make HUD Draggable on Mobile / Touch Screen
local UserInputService = game:GetService("UserInputService")
local dragging, dragInput, dragStart, startPos

mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

mainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

hudGui.Parent = parentGui

local function updateHUD(text, color)
    print("[NOIR HUD] " .. tostring(text))
    if statusLabel and statusLabel.Parent then
        statusLabel.Text = tostring(text)
        if color then
            statusLabel.TextColor3 = color
        end
    end
end

updateHUD("GUI siap. Memuat modul game...", Color3.fromRGB(255, 220, 100))

-- ==========================================================================
-- 2. SERVICES & CHARACTER REFERENCES
-- ==========================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")
local VirtualUser = game:GetService("VirtualUser")

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid", 10)
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart", 10)

LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid", 10)
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart", 10)
end)

-- 3. Configuration Validation
local Config = getgenv().NOIR_CONFIG or {
    API_KEY = "NOIR-DEFAULT-ADMIN-KEY",
    SERVER_URL = "http://localhost:3000",
    AUTO_CLAIM_BOOTH = true,
    AUTO_LIST = true,
    AUTO_RESTOCK = true,
    AUTO_DELIST = true,
    SERVER_HOP_ON_FULL = true,
    HOP_MODE = "Lowest",
    ANTI_AFK = true,
    HEARTBEAT_INTERVAL = 15,
    INVENTORY_SYNC_INTERVAL = 30
}

-- 4. HTTP Request Wrapper
local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request or (delta and delta.request) or (fluxus and fluxus.request)
if not httpRequest then
    updateHUD("❌ Executor tidak mendukung HTTP Request!", Color3.fromRGB(255, 80, 80))
    return
end

local function apiCall(endpoint, method, payload)
    local url = Config.SERVER_URL .. endpoint
    local bodyData = payload and HttpService:JSONEncode(payload) or nil

    local response = httpRequest({
        Url = url,
        Method = method or "GET",
        Headers = {
            ["Content-Type"] = "application/json",
            ["x-api-key"] = Config.API_KEY
        },
        Body = bodyData
    })

    if response and response.StatusCode == 200 then
        local success, decoded = pcall(function()
            return HttpService:JSONDecode(response.Body)
        end)
        if success then return decoded end
    end
    return nil
end

-- ==========================================================================
-- 5. CLEAN MOBILE ANTI-AFK
-- ==========================================================================
if Config.ANTI_AFK then
    LocalPlayer.Idled:Connect(function()
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0, 0))
        end)
    end)
end

-- ==========================================================================
-- 6. LOAD NATIVE FISH IT MODULES
-- ==========================================================================
updateHUD("Memuat TradeData & Replion...", Color3.fromRGB(255, 200, 50))
local TradeData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Trading"):WaitForChild("TradeData"))
local ItemUtility = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ItemUtility"))
local Replion = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Replion"))
local DataReplion = Replion.Client:WaitReplion("Data")

local MyBooth = nil
local MyBoothClaimConfirmed = false
local ActiveSellConfigs = {}
local TotalTokensEarned = 0

-- ==========================================================================
-- 7. AUTO-CONFIRM PROMPTS IN PLAYERGUI
-- ==========================================================================
local function autoClickConfirmPrompts()
    local pGui = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:FindFirstChild("PlayerGui")
    if not pGui then return end

    for _, gui in ipairs(pGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled and gui.Name ~= "NoirBoothHUD" then
            for _, desc in ipairs(gui:GetDescendants()) do
                if desc:IsA("TextButton") or desc:IsA("ImageButton") then
                    local name = desc.Name:lower()
                    local text = (desc:IsA("TextButton") and desc.Text or ""):lower()
                    
                    if text:find("claim") or text:find("confirm") or text:find("yes") or text:find("accept") or text:find("ok")
                       or name:find("claim") or name:find("confirm") or name:find("yes") or name:find("accept") then
                        pcall(function()
                            if desc.Visible then
                                desc.Selectable = true
                                for _, conn in ipairs(getconnections and getconnections(desc.Activated) or {}) do
                                    conn:Fire()
                                end
                                for _, conn in ipairs(getconnections and getconnections(desc.MouseButton1Click) or {}) do
                                    conn:Fire()
                                end
                            end
                        end)
                    end
                end
            end
        end
    end
end

task.spawn(function()
    while true do
        task.wait(0.5)
        autoClickConfirmPrompts()
    end
end)

-- ==========================================================================
-- 8. STEALTH NATURAL WALK
-- ==========================================================================
local function safeWalkTo(targetPos, maxWaitSeconds)
    if not Humanoid or not HumanoidRootPart then return false end
    maxWaitSeconds = maxWaitSeconds or 15

    local distance = (HumanoidRootPart.Position - targetPos).Magnitude

    if distance <= 6 then
        HumanoidRootPart.CFrame = CFrame.lookAt(
            HumanoidRootPart.Position,
            Vector3.new(targetPos.X, HumanoidRootPart.Position.Y, targetPos.Z)
        )
        return true
    end

    Humanoid:MoveTo(targetPos)
    
    local startTime = tick()
    while (HumanoidRootPart.Position - targetPos).Magnitude > 5 and (tick() - startTime) < maxWaitSeconds do
        task.wait(0.2)
        if not Humanoid or not HumanoidRootPart then break end
        Humanoid:MoveTo(targetPos)
    end

    return (HumanoidRootPart.Position - targetPos).Magnitude <= 8
end

-- ==========================================================================
-- 9. LIVE INVENTORY SCANNER
-- ==========================================================================
local function scanInventory()
    local fishList = {}
    local itemsList = {}

    local invData = DataReplion:GetExpect("Inventory")
    if invData then
        for category, list in pairs(invData) do
            for _, item in ipairs(list) do
                local itemMeta = ItemUtility.GetItemDataFromItemType(category, item.Id)
                if itemMeta and itemMeta.Data then
                    local name = itemMeta.Data.Name or ("Item_" .. tostring(item.Id))
                    local rarity = itemMeta.Data.Tier or item.Tier or "Common"
                    local weight = item.Weight or (itemMeta.Data.Weight) or nil
                    local mutation = item.Mutation or nil
                    local itemType = itemMeta.Data.Type or category

                    local itemObj = {
                        uuid = item.UUID,
                        id = item.Id,
                        name = name,
                        category = category,
                        item_type = itemType,
                        rarity = tostring(rarity),
                        weight = weight and tonumber(weight) or nil,
                        mutation = mutation and tostring(mutation) or nil,
                        count = 1
                    }

                    if category == "Fish" or itemType == "Fish" or weight then
                        table.insert(fishList, itemObj)
                    else
                        table.insert(itemsList, itemObj)
                    end
                end
            end
        end
    end

    return { fish = fishList, items = itemsList }
end

-- ==========================================================================
-- 10. CHECK IF PLAYER ALREADY HAS A BOOTH
-- ==========================================================================
local function checkIfAlreadyHaveBooth()
    local activeListings = DataReplion:Get("SaleListings.Booth")
    if activeListings ~= nil then
        MyBoothClaimConfirmed = true
        return true
    end

    local tradePlaza = workspace:FindFirstChild("Islands") and workspace.Islands:FindFirstChild("TradePlaza")
    local boothsFolder = tradePlaza and tradePlaza:FindFirstChild("Booths") or workspace:FindFirstChild("Booths", true)
    
    if boothsFolder then
        for _, booth in ipairs(boothsFolder:GetChildren()) do
            local owner = booth:GetAttribute("Owner") or booth:GetAttribute("OwnerName") or (booth:FindFirstChild("Owner") and booth.Owner.Value)
            if owner == LocalPlayer.Name or owner == LocalPlayer.UserId then
                MyBooth = booth
                MyBoothClaimConfirmed = true
                return true
            end
        end
    end

    return false
end

-- ==========================================================================
-- 11. WORKFLOW STEP 1: DEKATI BOOTH & CLAIM BOOTH
-- ==========================================================================
local function findAndClaimBooth()
    if checkIfAlreadyHaveBooth() then
        updateHUD("✅ Booth sudah aktif terdaftar!", Color3.fromRGB(0, 255, 150))
        return true
    end

    local tradePlaza = workspace:FindFirstChild("Islands") and workspace.Islands:FindFirstChild("TradePlaza")
    local boothsFolder = tradePlaza and tradePlaza:FindFirstChild("Booths") or workspace:FindFirstChild("Booths", true)

    if not boothsFolder then
        updateHUD("❌ Folder Booths tidak ditemukan", Color3.fromRGB(255, 80, 80))
        return false
    end

    local candidateBooths = {}
    for _, booth in ipairs(boothsFolder:GetChildren()) do
        if booth.Name == "Booth" or booth:IsA("Model") then
            local claimAtt = booth:FindFirstChild("ClaimAttachment", true)
            local prompt = claimAtt and claimAtt:FindFirstChildWhichIsA("ProximityPrompt")
            
            if prompt and prompt.Enabled then
                local bPos = claimAtt.WorldPosition or (booth:IsA("Model") and booth:GetPivot().Position)
                local dist = HumanoidRootPart and (HumanoidRootPart.Position - bPos).Magnitude or 9999
                table.insert(candidateBooths, {
                    model = booth,
                    prompt = prompt,
                    attachment = claimAtt,
                    pos = bPos,
                    dist = dist
                })
            end
        end
    end

    if #candidateBooths == 0 then
        updateHUD("⚠️ Semua booth di Plaza penuh!", Color3.fromRGB(255, 180, 50))
        return false
    end

    table.sort(candidateBooths, function(a, b) return a.dist < b.dist end)
    local target = candidateBooths[1]

    updateHUD("Berjalan ke Booth kosong...", Color3.fromRGB(255, 220, 100))
    safeWalkTo(target.pos + Vector3.new(0, 0, 2), 12)
    task.wait(1)

    if target.prompt and target.prompt.Enabled then
        updateHUD("Mengklaim booth...", Color3.fromRGB(255, 200, 0))
        pcall(function()
            if fireproximityprompt then
                fireproximityprompt(target.prompt, (target.prompt.HoldDuration or 0.5) + 0.2)
            else
                target.prompt:InputHoldBegin()
                task.wait((target.prompt.HoldDuration or 0.5) + 0.2)
                target.prompt:InputHoldEnd()
            end
        end)
        task.wait(1.5)
        autoClickConfirmPrompts()
    end

    local startWait = tick()
    while (tick() - startWait) < 5 do
        autoClickConfirmPrompts()
        if checkIfAlreadyHaveBooth() or (target.prompt and not target.prompt.Enabled) then
            MyBooth = target.model
            MyBoothClaimConfirmed = true
            updateHUD("✅ Booth berhasil diklaim!", Color3.fromRGB(0, 255, 150))
            return true
        end
        task.wait(0.5)
    end

    updateHUD("Klaim booth manual atau tunggu bot...", Color3.fromRGB(255, 180, 50))
    return false
end

-- ==========================================================================
-- 12. WORKFLOW STEP 2: AUTO-LISTING & RESTOCK
-- ==========================================================================
local function executeListingWorkflow()
    if not Config.AUTO_LIST then return end
    
    if not MyBoothClaimConfirmed then
        if not checkIfAlreadyHaveBooth() then
            if not findAndClaimBooth() then
                updateHUD("Menunggu booth diklaim...", Color3.fromRGB(255, 200, 100))
                return
            end
        end
    end

    local activeListings = DataReplion:Get("SaleListings.Booth") or {}
    local listedItemCountByName = {}

    -- 1. AUTO-DELIST
    for listingId, listing in pairs(activeListings) do
        local inv = scanInventory()
        local matchedItem = nil
        for _, f in ipairs(inv.fish) do
            if f.uuid == listing.ItemId then matchedItem = f break end
        end

        if matchedItem then
            local itemName = matchedItem.name
            listedItemCountByName[itemName] = (listedItemCountByName[itemName] or 0) + 1

            local cfg = nil
            for _, c in ipairs(ActiveSellConfigs) do
                if string.lower(c.item_name) == string.lower(itemName) then
                    cfg = c
                    break
                end
            end

            if Config.AUTO_DELIST and (not cfg or not cfg.is_active) then
                pcall(function()
                    TradeData.Remotes.DeleteSaleListing:InvokeServer("Booth", listingId)
                end)
                updateHUD("❌ Delist: " .. itemName, Color3.fromRGB(255, 120, 120))
                task.wait(1.5)
            end
        end
    end

    -- 2. AUTO-LISTING
    local inv = scanInventory()
    for _, fish in ipairs(inv.fish) do
        local isAlreadyListed = false
        for _, l in pairs(activeListings) do
            if l.ItemId == fish.uuid then
                isAlreadyListed = true
                break
            end
        end

        if not isAlreadyListed then
            for _, cfg in ipairs(ActiveSellConfigs) do
                if cfg.is_active and string.lower(cfg.item_name) == string.lower(fish.name) then
                    local currentListed = listedItemCountByName[fish.name] or 0
                    local maxQuota = cfg.max_booth or 1

                    if currentListed < maxQuota then
                        local price = math.floor(cfg.price)
                        
                        if price > 0 and fish.uuid then
                            updateHUD(string.format("Memajang %s (%d T)...", fish.name, price), Color3.fromRGB(0, 210, 255))
                            
                            local success, res = pcall(function()
                                return TradeData.Remotes.CreateSaleListing:InvokeServer(
                                    "Booth",
                                    fish.item_type or fish.category or "Fish",
                                    fish.uuid,
                                    price
                                )
                            end)

                            if success then
                                listedItemCountByName[fish.name] = currentListed + 1
                                updateHUD(string.format("🐟 Terpasang: %s (%d T)", fish.name, price), Color3.fromRGB(0, 255, 150))
                            else
                                warn("[NOIR LIST] Gagal pasang: " .. tostring(res))
                            end
                        end
                        
                        task.wait(math.random(18, 28) / 10)
                    end
                end
            end
        end
    end
end

-- ==========================================================================
-- 13. NATIVE SALE EVENT LISTENER
-- ==========================================================================
TradeData.Remotes.SaleListingSold.OnClientEvent:Connect(function(buyerPlayer, _, _, category, itemData, price)
    local itemMeta = ItemUtility.GetItemDataFromItemType(category, itemData.Id)
    local itemName = (itemMeta and itemMeta.Data and itemMeta.Data.Name) or ("Item_" .. tostring(itemData.Id))
    local buyerName = (buyerPlayer and buyerPlayer.DisplayName) or (buyerPlayer and buyerPlayer.Name) or "Player"
    local salePrice = tonumber(price) or 0

    TotalTokensEarned = TotalTokensEarned + salePrice

    apiCall("/api/bot/sale", "POST", {
        roblox_username = LocalPlayer.Name,
        item_name = itemName,
        price = salePrice,
        buyer_name = buyerName,
        total_rap = TotalTokensEarned,
        tokens = TotalTokensEarned
    })

    updateHUD(string.format("💰 Terjual: %s (+%d T)!", itemName, salePrice), Color3.fromRGB(255, 215, 0))

    if Config.AUTO_RESTOCK then
        task.delay(3, executeListingWorkflow)
    end
end)

-- ==========================================================================
-- 14. ADVANCED SERVER HOPPER
-- ==========================================================================
local isHopping = false
local function executeServerHop()
    if isHopping then return end
    isHopping = true
    updateHUD("🚀 Mencari server Plaza baru...", Color3.fromRGB(255, 180, 50))

    local placeId = game.PlaceId
    local url = "https://games.roproxy.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"

    task.spawn(function()
        local http = (syn and syn.request) or (http and http.request) or http_request or request
        local response = http and http({ Url = url, Method = "GET" })
        if response and response.StatusCode == 200 then
            local decoded = HttpService:JSONDecode(response.Body)
            if decoded and decoded.data then
                for _, s in ipairs(decoded.data) do
                    if s.playing < s.maxPlayers and s.id ~= game.JobId then
                        TeleportService:TeleportToPlaceInstance(placeId, s.id, LocalPlayer)
                        return
                    end
                end
            end
        end
        TeleportService:Teleport(placeId, LocalPlayer)
        task.wait(5)
        isHopping = false
    end)
end

-- ==========================================================================
-- 15. MAIN EXECUTION LOOPS
-- ==========================================================================
updateHUD("Bot aktif. Memulai siklus...", Color3.fromRGB(0, 255, 150))

task.spawn(function()
    task.wait(3)
    if not checkIfAlreadyHaveBooth() then
        local claimed = findAndClaimBooth()
        if not claimed and Config.SERVER_HOP_ON_FULL then
            task.wait(3)
            executeServerHop()
            return
        end
    end
    task.wait(2)
    executeListingWorkflow()
end)

task.spawn(function()
    while task.wait(Config.HEARTBEAT_INTERVAL or 15) do
        local res = apiCall("/api/bot/heartbeat", "POST", {
            roblox_username = LocalPlayer.Name,
            roblox_user_id = tostring(LocalPlayer.UserId),
            server_job_id = game.JobId,
            total_rap = TotalTokensEarned,
            tokens = TotalTokensEarned,
            booth_claimed = MyBoothClaimConfirmed,
            booth_id = MyBooth and tostring(MyBooth.Name) or ""
        })

        if res and res.success and res.data and res.data.configs then
            ActiveSellConfigs = res.data.configs
        end
    end
end)

task.spawn(function()
    while task.wait(Config.INVENTORY_SYNC_INTERVAL or 30) do
        local inv = scanInventory()
        apiCall("/api/bot/inventory", "POST", {
            roblox_username = LocalPlayer.Name,
            fish_data = inv.fish,
            items_data = inv.items
        })
    end
end)

task.spawn(function()
    while task.wait(25) do
        if Config.AUTO_RESTOCK or Config.AUTO_LIST or Config.AUTO_DELIST then
            executeListingWorkflow()
        end
    end
end)
