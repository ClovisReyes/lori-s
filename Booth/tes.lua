-- ==========================================================================
--  🐟 FISH IT: AUTO BOOTH PLAZA (NOIR ENGINE v2.1)
--  CORE ENGINE: PURE AUTO BOOTH CLAIM & LISTING (NO ANTI-AFK / NO SERVERHOP)
-- ==========================================================================

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
    task.wait(0.1)
    LocalPlayer = Players.LocalPlayer
end

-- ==========================================================================
-- 1. FLOATING CONTROL PANEL & HUD
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
mainFrame.Size = UDim2.new(0, 260, 0, 115)
mainFrame.Position = UDim2.new(0.5, -130, 0, 25)
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
titleLabel.Size = UDim2.new(1, -20, 0, 22)
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
statusLabel.Size = UDim2.new(1, -20, 0, 36)
statusLabel.Position = UDim2.new(0, 10, 0, 26)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Memulai inisialisasi..."
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.Font = Enum.Font.GothamMedium
statusLabel.TextSize = 10
statusLabel.TextWrapped = true
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.ZIndex = 101
statusLabel.Parent = mainFrame

-- Action Buttons Container
local btnRow = Instance.new("Frame")
btnRow.Size = UDim2.new(1, -16, 0, 28)
btnRow.Position = UDim2.new(0, 8, 0, 78)
btnRow.BackgroundTransparency = 1
btnRow.ZIndex = 101
btnRow.Parent = mainFrame

local function createBtn(text, posX, width, bgCol)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(width, -4, 1, 0)
    btn.Position = UDim2.new(posX, 2, 0, 0)
    btn.BackgroundColor3 = bgCol or Color3.fromRGB(20, 28, 40)
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.ZIndex = 102
    btn.Parent = btnRow

    local bCorner = Instance.new("UICorner")
    bCorner.CornerRadius = UDim.new(0, 6)
    bCorner.Parent = btn

    local bStroke = Instance.new("UIStroke")
    bStroke.Color = Color3.fromRGB(0, 210, 255)
    bStroke.Thickness = 1
    bStroke.Transparency = 0.5
    bStroke.Parent = btn

    return btn
end

local btnClaim = createBtn("⚡ Klaim & Jual", 0, 0.50, Color3.fromRGB(0, 130, 200))
local btnSync = createBtn("🔄 Sync Tas", 0.50, 0.50, Color3.fromRGB(30, 40, 55))

-- Touch Dragging for Mobile Screen
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

updateHUD("GUI aktif. Menghubungkan ke game...", Color3.fromRGB(255, 220, 100))

-- ==========================================================================
-- 2. GAME SERVICES & CHARACTER REFERENCES
-- ==========================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid", 5) or Character:FindFirstChildOfClass("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart", 5) or Character:FindFirstChild("HumanoidRootPart")

LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid", 5) or char:FindFirstChildOfClass("Humanoid")
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart", 5) or char:FindFirstChild("HumanoidRootPart")
end)

-- 3. Configuration
local Config = getgenv().NOIR_CONFIG or {
    API_KEY = "NOIR-DEFAULT-ADMIN-KEY",
    SERVER_URL = "http://localhost:3000",
    AUTO_CLAIM_BOOTH = true,
    AUTO_LIST = true,
    AUTO_RESTOCK = true,
    AUTO_DELIST = true,
    HEARTBEAT_INTERVAL = 15,
    INVENTORY_SYNC_INTERVAL = 30
}

-- 4. HTTP Request Wrapper
local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request or (delta and delta.request) or (fluxus and fluxus.request)

local function apiCall(endpoint, method, payload)
    if not httpRequest then return nil end
    local url = Config.SERVER_URL .. endpoint
    local bodyData = payload and HttpService:JSONEncode(payload) or nil

    local success, response = pcall(function()
        return httpRequest({
            Url = url,
            Method = method or "GET",
            Headers = {
                ["Content-Type"] = "application/json",
                ["x-api-key"] = Config.API_KEY
            },
            Body = bodyData
        })
    end)

    if success and response and response.StatusCode == 200 then
        local decSuccess, decoded = pcall(function()
            return HttpService:JSONDecode(response.Body)
        end)
        if decSuccess then return decoded end
    end
    return nil
end

-- ==========================================================================
-- 5. LOAD NATIVE FISH IT MODULES (ASYNC NON-BLOCKING)
-- ==========================================================================
updateHUD("Memuat TradeData & Inventory...", Color3.fromRGB(255, 200, 50))

local TradeData, ItemUtility, Replion, DataReplion

pcall(function()
    TradeData = require(ReplicatedStorage:WaitForChild("Shared", 5):WaitForChild("Trading", 5):WaitForChild("TradeData", 5))
end)

pcall(function()
    ItemUtility = require(ReplicatedStorage:WaitForChild("Shared", 5):WaitForChild("ItemUtility", 5))
end)

pcall(function()
    Replion = require(ReplicatedStorage:WaitForChild("Packages", 5):WaitForChild("Replion", 5))
    if Replion and Replion.Client then
        if Replion.Client.GetReplion then
            DataReplion = Replion.Client:GetReplion("Data")
        end
        if not DataReplion and Replion.Client.WaitReplion then
            task.spawn(function()
                DataReplion = Replion.Client:WaitReplion("Data")
            end)
        end
    end
end)

local MyBooth = nil
local MyBoothClaimConfirmed = false
local ActiveSellConfigs = {}
local TotalTokensEarned = 0

-- ==========================================================================
-- 6. AUTO-CONFIRM DIALOG PROMPTS IN PLAYERGUI
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
-- 7. LIVE INVENTORY SCANNER
-- ==========================================================================
local function scanInventory()
    local fishList = {}
    local itemsList = {}

    local invData = nil
    if DataReplion then
        pcall(function()
            invData = DataReplion:Get("Inventory") or DataReplion:GetExpect("Inventory")
        end)
    end

    if invData and ItemUtility then
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
-- 8. CHECK IF PLAYER ALREADY HAS A BOOTH
-- ==========================================================================
local function checkIfAlreadyHaveBooth()
    if DataReplion then
        local activeListings = DataReplion:Get("SaleListings.Booth")
        if activeListings ~= nil then
            MyBoothClaimConfirmed = true
            return true
        end
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
-- 9. WORKFLOW STEP 1: DEKATI BOOTH & CLAIM BOOTH
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
                local bPos = claimAtt.WorldPosition or (booth:IsA("Model") and booth:GetPivot().Position) or booth.Position
                local dist = (HumanoidRootPart and bPos) and (HumanoidRootPart.Position - bPos).Magnitude or 9999
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

    updateHUD("Mendekati Booth kosong...", Color3.fromRGB(255, 220, 100))
    if HumanoidRootPart and target.pos then
        HumanoidRootPart.CFrame = CFrame.new(target.pos + Vector3.new(0, 2, 2))
        task.wait(0.5)
    end

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
        task.wait(1.2)
        autoClickConfirmPrompts()
    end

    local startWait = tick()
    while (tick() - startWait) < 4 do
        autoClickConfirmPrompts()
        if checkIfAlreadyHaveBooth() or (target.prompt and not target.prompt.Enabled) then
            MyBooth = target.model
            MyBoothClaimConfirmed = true
            updateHUD("✅ Booth berhasil diklaim!", Color3.fromRGB(0, 255, 150))
            return true
        end
        task.wait(0.4)
    end

    MyBooth = target.model
    MyBoothClaimConfirmed = true
    updateHUD("✅ Booth siap. Memulai listing...", Color3.fromRGB(0, 255, 150))
    return true
end

-- ==========================================================================
-- 10. WORKFLOW STEP 2: AUTO-LISTING & RESTOCK
-- ==========================================================================
local function executeListingWorkflow()
    if not Config.AUTO_LIST then return end
    
    if not MyBoothClaimConfirmed then
        if not checkIfAlreadyHaveBooth() then
            if not findAndClaimBooth() then
                updateHUD("Klaim booth manual atau tekan tombol!", Color3.fromRGB(255, 200, 100))
                return
            end
        end
    end

    local activeListings = (DataReplion and DataReplion:Get("SaleListings.Booth")) or {}
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
                if TradeData and TradeData.Remotes and TradeData.Remotes.DeleteSaleListing then
                    pcall(function()
                        TradeData.Remotes.DeleteSaleListing:InvokeServer("Booth", listingId)
                    end)
                end
                updateHUD("❌ Delist: " .. itemName, Color3.fromRGB(255, 120, 120))
                task.wait(1.2)
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
                        
                        if price > 0 and fish.uuid and TradeData and TradeData.Remotes and TradeData.Remotes.CreateSaleListing then
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
                        
                        task.wait(math.random(15, 25) / 10)
                    end
                end
            end
        end
    end
end

-- Connect UI Action Buttons
btnClaim.Activated:Connect(function()
    task.spawn(function()
        updateHUD("Manual trigger: Klaim & Jual...", Color3.fromRGB(0, 210, 255))
        findAndClaimBooth()
        task.wait(1)
        executeListingWorkflow()
    end)
end)

btnSync.Activated:Connect(function()
    task.spawn(function()
        updateHUD("Sinkronisasi tas...", Color3.fromRGB(255, 200, 100))
        local inv = scanInventory()
        apiCall("/api/bot/inventory", "POST", {
            roblox_username = LocalPlayer.Name,
            fish_data = inv.fish,
            items_data = inv.items
        })
        updateHUD(string.format("✅ Tas tersinkron! (%d Ikan)", #inv.fish), Color3.fromRGB(0, 255, 150))
    end)
end)

-- ==========================================================================
-- 11. NATIVE SALE EVENT LISTENER
-- ==========================================================================
pcall(function()
    if TradeData and TradeData.Remotes and TradeData.Remotes.SaleListingSold then
        TradeData.Remotes.SaleListingSold.OnClientEvent:Connect(function(buyerPlayer, _, _, category, itemData, price)
            local itemMeta = ItemUtility and ItemUtility.GetItemDataFromItemType(category, itemData.Id)
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
    end
end)

-- ==========================================================================
-- 12. MAIN EXECUTION LOOPS
-- ==========================================================================
updateHUD("Bot aktif! Memulai otomatis...", Color3.fromRGB(0, 255, 150))

-- Auto start claim & list in background
task.spawn(function()
    task.wait(2)
    if not checkIfAlreadyHaveBooth() then
        findAndClaimBooth()
    end
    task.wait(1.5)
    executeListingWorkflow()
end)

-- Heartbeat Loop (Setiap 15s)
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

-- Live Inventory Sync Loop (Setiap 30s)
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

-- Periodic Listing & Restock Loop (Setiap 20s)
task.spawn(function()
    while task.wait(20) do
        if Config.AUTO_RESTOCK or Config.AUTO_LIST or Config.AUTO_DELIST then
            executeListingWorkflow()
        end
    end
end)
