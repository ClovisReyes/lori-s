-- =====================================================================
-- FISH IT: DYNAMIC AUTO WEBHOOK SENDER (AUTO-HOOK LISTENER)
-- Otomatis Mengirim Webhook Saat Anda Menangkap Ikan (Manual / Auto-Fish)
-- =====================================================================

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- ========================== KONFIGURASI ==============================
local CONFIG = {
    WebhookUrl = "https://discord.com/api/webhooks/1536161350256959613/dYo-hYpPyNBI4ZrKg3Nkj4TYuUGYcGEJbx91Z-WC4zHTTa2Vv-aK1bdlMMWbVrNzp0ZM",
    StoreTitle = "(YUISTORE) Caught !",
    FooterText = "2026 - DISCORD 1 SERVER",
    SendTestOnStartup = true, -- Kirim 1x pesan test ke Discord saat script di-execute

    -- Warna embed per Rarity
    RarityColors = {
        ["Common"]      = 10070709,
        ["Uncommon"]    = 3066993,
        ["Rare"]        = 3447003,
        ["Epic"]        = 10181046,
        ["Legendary"]   = 16766720,
        ["Mythic"]      = 15105570,
        ["Forgotten"]   = 2067276,
        ["Forgottens"]  = 2067276,
        ["Secret"]      = 15548997,
        ["1"] = 10070709, ["2"] = 3066993, ["3"] = 3447003,
        ["4"] = 10181046, ["5"] = 16766720, ["6"] = 15105570,
        ["7"] = 2067276,  ["8"] = 2067276,  ["100"] = 15548997
    }
}

-- ==================== MASTER ASSET CACHE =============================
local ItemAssetCache = {}
local ItemMetadataCache = {}
local isDatabaseLoaded = false

local function cleanAssetId(str)
    if not str then return nil end
    return tostring(str):match("%d+")
end

local function safeGet(tbl, key)
    if type(tbl) ~= "table" then return nil end
    local ok, val = pcall(function() return rawget(tbl, key) end)
    if ok and val ~= nil then return val end
    local ok2, val2 = pcall(function() return tbl[key] end)
    if ok2 then return val2 end
    return nil
end

local function registerItem(itemName, rawIcon, rarity, chance)
    if not rawIcon or type(itemName) ~= "string" or #itemName < 2 then return end
    local id = cleanAssetId(rawIcon)
    if id and not ItemAssetCache[itemName] then
        ItemAssetCache[itemName] = id
        ItemMetadataCache[itemName] = {
            AssetId = id,
            Rarity = tostring(rarity or "Common"),
            Chance = tostring(chance or "-")
        }
    end
end

local function scanItemTable(tbl, depth)
    if depth > 4 or type(tbl) ~= "table" then return end
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            local itemName = safeGet(v, "Name") or safeGet(v, "FishName") or safeGet(v, "ItemName") or (type(k) == "string" and k)
            local rawIcon = safeGet(v, "Icon") or safeGet(v, "Image") or safeGet(v, "Texture") or safeGet(v, "Thumbnail") or safeGet(v, "Portrait") or safeGet(v, "AssetId")
            
            if rawIcon and itemName then
                local rarity = safeGet(v, "Rarity") or safeGet(v, "Tier") or "Unknown"
                local chance = safeGet(v, "Chance") or safeGet(v, "RarityChance") or "-"
                registerItem(itemName, rawIcon, rarity, chance)
            else
                scanItemTable(v, depth + 1)
            end
        end
    end
end

-- Sinkronisasi memori aktif game
local function syncAllGameAssets()
    if getgc then
        pcall(function()
            for _, obj in pairs(getgc(true)) do
                if type(obj) == "table" then
                    if rawget(obj, "Cerulean Dragon") or rawget(obj, "Starter Rod") or rawget(obj, "Thunderzilla") then
                        scanItemTable(obj, 1)
                        isDatabaseLoaded = true
                    end
                end
            end
        end)
    end

    local totalItems = 0
    for _ in pairs(ItemAssetCache) do totalItems = totalItems + 1 end
    print(string.format("[FISH IT SYNC] Berhasil sinkronisasi %d item langsung dari memori game!", totalItems))
    return totalItems
end

syncAllGameAssets()

-- =====================================================================
-- PEMBERSIH VARIANT / MODIFIER
-- =====================================================================
local function cleanItemName(rawName)
    if not rawName then return "" end
    local clean = tostring(rawName)
    local prefixes = {
        "^Big%s+", "^Huge%s+", "^Giant%s+", "^Small%s+", "^Tiny%s+",
        "^Colossal%s+", "^Shiny%s+", "^Albino%s+", "^Golden%s+",
        "^Sparkling%s+", "^Crystallized%s+", "^Mythic%s+"
    }
    for _, pattern in ipairs(prefixes) do
        clean = clean:gsub(pattern, "")
    end
    return clean
end

local function getItemImageUrl(rawItemName)
    if not rawItemName or rawItemName == "" then
        return "https://www.roblox.com/asset-thumbnail/image?assetId=10842211652&width=420&height=420&format=png"
    end

    local assetId = ItemAssetCache[rawItemName] or ItemAssetCache[cleanItemName(rawItemName)]
    if not assetId then
        syncAllGameAssets()
        assetId = ItemAssetCache[rawItemName] or ItemAssetCache[cleanItemName(rawItemName)]
    end

    if assetId then
        return "https://www.roblox.com/asset-thumbnail/image?assetId=" .. assetId .. "&width=420&height=420&format=png"
    end

    return "https://www.roblox.com/asset-thumbnail/image?assetId=10842211652&width=420&height=420&format=png"
end

-- =====================================================================
-- FUNGSI PENGIRIMAN WEBHOOK
-- =====================================================================
local function sendCatchWebhook(data)
    local playerName = data.Player or (LocalPlayer and LocalPlayer.Name) or "Player"
    local fishName   = data.FishName or data.ItemName or "Unknown Fish"
    local mutation   = data.Mutation or "-"
    local weight     = data.Weight or "-"
    local meta       = ItemMetadataCache[cleanItemName(fishName)]
    local rarity     = data.Rarity or (meta and meta.Rarity) or "Common"
    local chance     = data.Chance or (meta and meta.Chance) or "-"

    local imageUrl = getItemImageUrl(fishName)
    local embedColor = CONFIG.RarityColors[tostring(rarity)] or 3447003

    local descriptionText = string.format(
        "**%s - %s !**\n\n" ..
        "» **Player:** `%s`\n" ..
        "» **Fish Name:** `%s`\n" ..
        "» **Mutation:** `%s`\n" ..
        "» **Weight:** `%s`\n" ..
        "» **Rarity:** `%s`\n" ..
        "» **Chance:** `%s`",
        playerName, fishName,
        playerName,
        fishName,
        mutation,
        weight,
        rarity,
        chance
    )

    local payload = {
        embeds = {
            {
                title = CONFIG.StoreTitle,
                description = descriptionText,
                color = embedColor,
                thumbnail = {
                    url = imageUrl
                },
                footer = {
                    text = CONFIG.FooterText
                }
            }
        }
    }

    local requestFunc = (syn and syn.request) or (http and http.request) or http_request or request
    if requestFunc then
        local res = requestFunc({
            Url = CONFIG.WebhookUrl,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(payload)
        })
        print(string.format("[WEBHOOK TERKIRIM] %s (%s) -> Discord!", fishName, tostring(weight)))
    else
        warn("[WEBHOOK ERROR] Executor tidak mendukung fungsi http request!")
    end
end

-- =====================================================================
-- AUTO-HOOK LISTENER (DETEKSI OTOMATIS SAAT MANCING DI FISH IT)
-- =====================================================================
local function parseAndSendCatch(rawResult, rawArgs)
    if not rawResult then return end
    
    local fishName, weight, mutation, rarity, chance

    if type(rawResult) == "table" then
        fishName = safeGet(rawResult, "FishName") or safeGet(rawResult, "Name") or safeGet(rawResult, "Item") or safeGet(rawResult, "Id")
        weight   = safeGet(rawResult, "Weight") or safeGet(rawResult, "WeightStr") or safeGet(rawResult, "Size")
        mutation = safeGet(rawResult, "Mutation") or safeGet(rawResult, "Variant") or "-"
        rarity   = safeGet(rawResult, "Rarity") or safeGet(rawResult, "Tier")
        chance   = safeGet(rawResult, "Chance")
    elseif type(rawResult) == "string" and #rawResult > 1 then
        fishName = rawResult
    end

    -- Format weight jika dalam angka
    if type(weight) == "number" then
        if weight >= 1000000 then
            weight = string.format("%.2fM kg", weight / 1000000)
        elseif weight >= 1000 then
            weight = string.format("%.2fk kg", weight / 1000)
        else
            weight = string.format("%.1f kg", weight)
        end
    end

    if fishName and tostring(fishName) ~= "" then
        print("[CATCH EVENT TERDETEKSI] Menangkap:", fishName)
        sendCatchWebhook({
            Player = LocalPlayer and LocalPlayer.Name or "Player",
            FishName = tostring(fishName),
            Weight = weight and tostring(weight) or "Unknown kg",
            Mutation = mutation and tostring(mutation) or "-",
            Rarity = rarity and tostring(rarity) or "Unknown",
            Chance = chance and tostring(chance) or "-"
        })
    end
end

-- 1. Hook RemoteFunction CatchFishCompleted (Metode Jaringan / Paling Akurat)
local hookInstalled = false

-- A. Hook metamethod __namecall
pcall(function()
    if hookmetamethod then
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args = {...}

            if not checkcaller() and (method == "InvokeServer" or method == "invokeServer") then
                local sName = tostring(self.Name)
                if sName == "CatchFishCompleted" or sName:find("CatchFish") then
                    local res = oldNamecall(self, ...)
                    task.spawn(function()
                        parseAndSendCatch(res, args)
                    end)
                    return res
                end
            end
            return oldNamecall(self, ...)
        end))
        hookInstalled = true
    end
end)

-- B. Direct Net Function Hook (Sebagai Backup jika metamethod tidak aktif)
pcall(function()
    local NetMod = ReplicatedStorage:FindFirstChild("Packages") and ReplicatedStorage.Packages:FindFirstChild("Net")
    if NetMod then
        local Net = require(NetMod)
        if Net and Net.RemoteFunction then
            local rf = Net:RemoteFunction("CatchFishCompleted")
            if rf and rf.InvokeServer then
                local oldInvoke = rf.InvokeServer
                rf.InvokeServer = function(this, ...)
                    local res = oldInvoke(this, ...)
                    task.spawn(function()
                        parseAndSendCatch(res, {...})
                    end)
                    return res
                end
                hookInstalled = true
            end
        end
    end
end)

-- 2. UI Catch Notification Listener (Sebagai Cadangan Tambahan)
if LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") then
    LocalPlayer.PlayerGui.DescendantAdded:Connect(function(desc)
        if desc:IsA("TextLabel") or desc:IsA("TextButton") then
            task.wait(0.1)
            local text = desc.Text
            if text and (text:find("Caught") or text:find("kg") or text:find("1 in")) then
                -- Cek apakah nama ikan cocok dengan item di cache
                for fishName, _ in pairs(ItemAssetCache) do
                    if text:find(fishName) then
                        print("[UI EVENT TERDETEKSI] Menangkap via UI:", fishName)
                        -- Bisa digunakan jika remote tidak tertangkap
                    end
                end
            end
        end
    end)
end

print("==================================================")
if hookInstalled then
    print("[AUTO-HOOK AKTIF] Script sudah terhubung ke event memancing!")
    print("[INFO] Silakan coba memancing sekarang, webhook akan otomatis terkirim.")
else
    print("[LISTENER AKTIF] Menunggu tangkapan ikan...")
end
print("==================================================")

-- =====================================================================
-- TEST 1X KE DISCORD SAAT SCRIPT AKTIF (Bisa dimatikan di CONFIG)
-- =====================================================================
if CONFIG.SendTestOnStartup then
    task.spawn(function()
        task.wait(1)
        print("[TEST] Mengirim 1 contoh embed ke Discord untuk verifikasi...")
        sendCatchWebhook({
            Player = LocalPlayer and LocalPlayer.Name or "ANMLxDYN",
            FishName = "Cerulean Dragon",
            Mutation = "-",
            Weight = "1.04M kg",
            Rarity = "Forgottens",
            Chance = "1 in 25M"
        })
    end)
end

-- Export ke Environment Global agar bisa dipanggil dari script lain / auto-fish
if getgenv then
    getgenv().SendCatchWebhook = sendCatchWebhook
    getgenv().GetItemImageUrl  = getItemImageUrl
    getgenv().ItemAssetCache   = ItemAssetCache
end
_G.SendCatchWebhook = sendCatchWebhook
_G.GetItemImageUrl  = getItemImageUrl
_G.ItemAssetCache   = ItemAssetCache

return {
    SendCatchWebhook = sendCatchWebhook,
    GetItemImageUrl  = getItemImageUrl,
    ItemAssetCache   = ItemAssetCache
}
