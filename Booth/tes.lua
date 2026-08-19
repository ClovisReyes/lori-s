-- ==========================================================================
--  🐟 FISH IT: AUTO BOOTH PLAZA (NOIR ENGINE v2.1)
--  LEAN & FAST: RANDOM BOOTH CLAIM, SHOPKEEPER POSITION, AUTO-LIST & TAX
-- ==========================================================================

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
    task.wait(0.1)
    LocalPlayer = Players.LocalPlayer
end

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart", 10) or Character:FindFirstChild("HumanoidRootPart")

LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart", 10) or char:FindFirstChild("HumanoidRootPart")
end)

local function notify(title, msg)
    print(string.format("[NOIR] [%s] %s", tostring(title), tostring(msg)))
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "🐟 NOIR: " .. tostring(title),
            Text = tostring(msg),
            Duration = 4
        })
    end)
end

notify("Starting", "Memulai Noir Auto Booth v2.1 (Lean Mode)...")

-- 1. Configuration
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

-- 2. Universal HTTP Request Wrapper
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
-- 3. LOAD NATIVE FISH IT MODULES
-- ==========================================================================
local TradeData, ItemUtility, Replion, DataReplion

pcall(function()
    TradeData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Trading"):WaitForChild("TradeData"))
end)

pcall(function()
    ItemUtility = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ItemUtility"))
end)

pcall(function()
    Replion = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Replion"))
end)

local function getDataReplion()
    if DataReplion then return DataReplion end
    if Replion and Replion.Client then
        pcall(function()
            if Replion.Client.GetReplion then
                DataReplion = Replion.Client:GetReplion("Data")
            end
        end)
        if not DataReplion and Replion.Client.WaitReplion then
            pcall(function()
                DataReplion = Replion.Client:WaitReplion("Data", 5)
            end)
        end
    end
    return DataReplion
end

local MyBooth = nil
local MyBoothClaimConfirmed = false
local ActiveSellConfigs = {}
local TotalTokensEarned = 0

-- ==========================================================================
-- 4. LIVE INVENTORY SCANNER
-- ==========================================================================
local function scanInventory()
    local fishList = {}
    local itemsList = {}

    local rep = getDataReplion()
    local invData = nil
    if rep then
        pcall(function()
            invData = rep:Get("Inventory") or rep:GetExpect("Inventory")
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
-- 5. SHOPKEEPER POSITION HELPER (STAND BEHIND BOOTH FACING FORWARD)
-- ==========================================================================
local function getBehindBoothCFrame(boothModel, fallbackPos)
    if boothModel and boothModel:IsA("Model") then
        local pivot = boothModel:GetPivot()
        -- Berdiri 4.2 studs di belakang meja booth pada ketinggian lantai
        local behindPos = pivot.Position - (pivot.LookVector * 4.2) + Vector3.new(0, 1, 0)
        return CFrame.lookAt(behindPos, behindPos + pivot.LookVector)
    elseif fallbackPos then
        return CFrame.new(fallbackPos + Vector3.new(0, 1, -4))
    end
    return nil
end

-- ==========================================================================
-- 6. CHECK IF PLAYER ALREADY HAS A BOOTH
-- ==========================================================================
local function checkIfAlreadyHaveBooth()
    if MyBooth and MyBooth.Parent and MyBoothClaimConfirmed then
        return true
    end

    local tradePlaza = workspace:FindFirstChild("Islands") and workspace.Islands:FindFirstChild("TradePlaza")
    local boothsFolder = tradePlaza and tradePlaza:FindFirstChild("Booths") or workspace:FindFirstChild("Booths", true)
    
    if boothsFolder then
        for _, booth in ipairs(boothsFolder:GetChildren()) do
            local owner = booth:GetAttribute("Owner") or booth:GetAttribute("OwnerName") or (booth:FindFirstChild("Owner") and booth.Owner.Value)
            local isMyOwner = owner and (tostring(owner) == LocalPlayer.Name or tostring(owner) == tostring(LocalPlayer.UserId))
            
            -- Cek jika prompt berubah menjadi "Edit Booth"
            local editPrompt = booth:FindFirstChildWhichIsA("ProximityPrompt", true)
            local isEditBooth = editPrompt and (editPrompt.ActionText:lower():find("edit") or editPrompt.ObjectText:lower():find("booth"))
            local bPivot = booth:IsA("Model") and booth:GetPivot().Position or booth.Position

            if isMyOwner or (isEditBooth and HumanoidRootPart and bPivot and (HumanoidRootPart.Position - bPivot).Magnitude < 15) then
                MyBooth = booth
                MyBoothClaimConfirmed = true
                
                -- Posisikan rapi di belakang booth
                local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                local hrp = char:WaitForChild("HumanoidRootPart", 5) or char:FindFirstChild("HumanoidRootPart")
                local targetCFrame = getBehindBoothCFrame(booth, bPivot)
                if hrp and targetCFrame then
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    hrp.CFrame = targetCFrame
                end
                return true
            end
        end
    end

    return false
end

-- ==========================================================================
-- 7. WORKFLOW STEP 1: RANDOM BOOTH CLAIM (DIBELAKANG MEJA)
-- ==========================================================================
local function findAndClaimBooth()
    if checkIfAlreadyHaveBooth() then
        notify("Booth", "✅ Booth sudah aktif terdaftar!")
        return true
    end

    local tradePlaza = workspace:FindFirstChild("Islands") and workspace.Islands:FindFirstChild("TradePlaza")
    local boothsFolder = tradePlaza and tradePlaza:FindFirstChild("Booths") or workspace:FindFirstChild("Booths", true)

    if not boothsFolder then
        warn("[NOIR] Folder Booths tidak ditemukan di TradePlaza.")
        return false
    end

    local candidateBooths = {}
    for _, booth in ipairs(boothsFolder:GetChildren()) do
        if booth.Name == "Booth" or booth:IsA("Model") then
            local claimAtt = booth:FindFirstChild("ClaimAttachment", true)
            local prompt = claimAtt and claimAtt:FindFirstChildWhichIsA("ProximityPrompt") or booth:FindFirstChildWhichIsA("ProximityPrompt", true)
            
            if prompt and prompt.Enabled then
                local bPos = nil
                if claimAtt and claimAtt:IsA("Attachment") then
                    bPos = claimAtt.WorldPosition
                elseif prompt.Parent and prompt.Parent:IsA("BasePart") then
                    bPos = prompt.Parent.Position
                elseif booth:IsA("Model") then
                    bPos = booth:GetPivot().Position
                end

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
        notify("Plaza Full", "⚠️ Semua booth di server ini penuh!")
        return false
    end

    -- ACAK BOOTH KOSONG (RANDOM PICK)
    local randomIndex = math.random(1, #candidateBooths)
    local target = candidateBooths[randomIndex]

    notify("Claim Booth", string.format("Teleport ke booth acak (Slot %d/%d)...", randomIndex, #candidateBooths))
    
    -- 1. Teleport langsung ke BELAKANG meja booth menghadap ke depan
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart", 5) or char:FindFirstChild("HumanoidRootPart")
    local behindCFrame = getBehindBoothCFrame(target.model, target.pos)
    if hrp and behindCFrame then
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        hrp.CFrame = behindCFrame
        task.wait(0.3)
    end

    -- 2. Trigger ProximityPrompt klaim booth dari belakang (Langsung klaim tanpa dialog)
    if target.prompt and target.prompt.Enabled then
        pcall(function()
            if fireproximityprompt then
                fireproximityprompt(target.prompt)
            end
        end)
        task.wait(0.2)
        pcall(function()
            if fireproximityprompt then
                fireproximityprompt(target.prompt, 0)
            end
        end)
        task.wait(1)
    end

    -- 3. Verifikasi klaim
    local startWait = tick()
    while (tick() - startWait) < 4 do
        if checkIfAlreadyHaveBooth() or (target.prompt and not target.prompt.Enabled) then
            MyBooth = target.model
            MyBoothClaimConfirmed = true
            
            if hrp and behindCFrame then
                hrp.CFrame = behindCFrame
            end

            notify("Sukses", "✅ Booth berhasil diklaim secara acak!")
            return true
        end
        task.wait(0.3)
    end

    MyBooth = target.model
    MyBoothClaimConfirmed = true
    return true
end

-- ==========================================================================
-- 8. WORKFLOW STEP 2: AUTO-LISTING, DELISTING, & PAJAK
-- ==========================================================================
local function executeListingWorkflow()
    if not Config.AUTO_LIST then return end
    
    if not MyBoothClaimConfirmed then
        if not checkIfAlreadyHaveBooth() then
            if not findAndClaimBooth() then
                notify("Status", "Menunggu booth berhasil diklaim...")
                return
            end
        end
    end

    local rep = getDataReplion()
    local activeListings = (rep and rep:Get("SaleListings.Booth")) or {}
    local listedItemCountByName = {}

    -- 1. AUTO-DELIST (Tarik item jika dinonaktifkan di dashboard)
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
                notify("Delist", "❌ Menarik: " .. itemName)
                task.wait(1.5)
            end
        end
    end

    -- 2. AUTO-LISTING DENGAN PERHITUNGAN PAJAK (Contoh: 250 T -> 253 T di etalase)
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
                        local netPrice = math.floor(cfg.price)
                        -- Estimasi harga etalase setelah pajak game (+1.2% / pembulatan ke atas)
                        local taxedPrice = math.ceil(netPrice * 1.012)
                        
                        if netPrice > 0 and fish.uuid and TradeData and TradeData.Remotes and TradeData.Remotes.CreateSaleListing then
                            notify("Memajang", string.format("🐟 %s (%d T -> Etalase: %d T)...", fish.name, netPrice, taxedPrice))
                            
                            local success, res = pcall(function()
                                return TradeData.Remotes.CreateSaleListing:InvokeServer(
                                    "Booth",
                                    fish.item_type or fish.category or "Fish",
                                    fish.uuid,
                                    netPrice
                                )
                            end)

                            if success then
                                listedItemCountByName[fish.name] = currentListed + 1
                                notify("Sukses", string.format("✅ Terpasang: %s (%d T)", fish.name, netPrice))
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

-- ==========================================================================
-- 9. NATIVE SALE EVENT LISTENER & RESTOCK
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

            notify("Terjual!", string.format("💰 %s terjual (+%d Tokens)!", itemName, salePrice))

            if Config.AUTO_RESTOCK then
                task.delay(3, executeListingWorkflow)
            end
        end)
    end
end)

-- ==========================================================================
-- 10. MAIN EXECUTION LOOPS
-- ==========================================================================
notify("Bot Ready", "Menjalankan siklus otomatis...")

-- Initial Auto-Claim & Listing Cycle
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
        local rep = getDataReplion()
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
