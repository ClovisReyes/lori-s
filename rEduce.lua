if rconsoleclear then pcall(rconsoleclear) elseif consoleclear then pcall(consoleclear) end

local globalEnv = (getgenv and getgenv()) or _G

if globalEnv._FishItActiveWorker and typeof(globalEnv._FishItActiveWorker) == "thread" then
    pcall(task.cancel, globalEnv._FishItActiveWorker)
    globalEnv._FishItActiveWorker = nil
end

if globalEnv._FishItGCWorker and typeof(globalEnv._FishItGCWorker) == "thread" then
    pcall(task.cancel, globalEnv._FishItGCWorker)
    globalEnv._FishItGCWorker = nil
end

local function cleanupConnectionList(list)
    if not list then return end
    for _, item in pairs(list) do
        if typeof(item) == "RBXScriptConnection" and item.Connected then
            pcall(item.Disconnect, item)
        elseif type(item) == "table" then
            for _, subItem in ipairs(item) do
                if typeof(subItem) == "RBXScriptConnection" and subItem.Connected then
                    pcall(subItem.Disconnect, subItem)
                end
            end
        end
    end
end

cleanupConnectionList(globalEnv._FishItOptimizerConnections)
cleanupConnectionList(globalEnv._FishItPlayerConnections)
cleanupConnectionList(globalEnv._FishItCharacterConnections)

globalEnv._FishItOptimizerConnections = {}
globalEnv._FishItPlayerConnections = {}
globalEnv._FishItCharacterConnections = {}

local tracker = globalEnv._FishItOptimizerConnections
local playerConnections = globalEnv._FishItPlayerConnections
local characterConnections = globalEnv._FishItCharacterConnections

local function trackConnection(conn)
    table.insert(tracker, conn)
    return conn
end

local game = game
local workspace = workspace
local getService = game.GetService

local Players = getService(game, "Players")
local Lighting = getService(game, "Lighting")
local SoundService = getService(game, "SoundService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    LocalPlayer = Players.LocalPlayer
end

local isA = game.IsA
local findFirstChild = game.FindFirstChild
local findFirstChildOfClass = game.FindFirstChildOfClass
local getChildren = game.GetChildren
local getDescendants = game.GetDescendants
local destroy = game.Destroy
local waitForChild = game.WaitForChild
local getPlayerFromCharacter = Players.GetPlayerFromCharacter

local ipairs = ipairs
local pairs = pairs
local pcall = pcall
local tostring = tostring
local clock = os.clock
local setmetatable = setmetatable
local string_find = string.find
local string_lower = string.lower
local table_insert = table.insert
local table_remove = table.remove

local task = task
local task_wait = task.wait
local task_spawn = task.spawn

local Color3_fromRGB = Color3.fromRGB
local Instance_new = Instance.new
local Enum = Enum
local MATERIAL_SMOOTH_PLASTIC = Enum.Material.SmoothPlastic
local QUALITY_LEVEL_01 = Enum.QualityLevel.Level01

local COLOR_BLACK_VOID     = Color3_fromRGB(0, 0, 0)
local COLOR_AMBIENT_BRIGHT = Color3_fromRGB(180, 180, 180)
local COLOR_WATER_BLUE     = Color3_fromRGB(65, 165, 230)
local BLACK_ASSET_ID       = "rbxassetid://144410044"
local EMPTY_STR            = ""

local FRAME_BUDGET_SEC = 0.008

local processedCache = setmetatable({}, { __mode = "k" })

local SAFE_TO_DESTROY = {
    ["Group Fishing Visuals"] = true,
    ["CosmeticFolder"]        = true,
    ["Aquariums"]             = true,
    ["!!! Aquariums"]         = true,
    ["Radiant"]               = true,
    ["Divine"]                = true,
}

local INVISIBLE_RIG_EXACT = {
    ["EmoteCratePreviewRig"] = true,
    ["FakeRig1"]             = true,
    ["Props"]                = true,
    ["Sunken Wreckage"]      = true,
    ["FakeIslands"]          = true,
}

local PROMO_GUIS = {
    ["!!! Click Effect"]       = true,
    ["Border"]                 = true,
    ["AreaHighlight"]          = true,
    ["Exclusive Store"]        = true,
    ["!!! Starter Pack"]       = true,
    ["TokenShardsAd"]          = true,
    ["BattlepassShop"]         = true,
    ["EventLimitedShop"]       = true,
    ["!!! BUY SPINS"]          = true,
    ["Spin Wheel"]             = true,
    ["LootboxDisplay"]         = true,
    ["EmoteLootbox"]           = true,
    ["!!! Gifting"]            = true,
    ["BlackMarket"]            = true,
    ["GalaxyEvent"]            = true,
    ["PurchaseScreenBlackout"] = true,
    ["EggIndicator"]           = true,
}

pcall(function()
    settings().Rendering.QualityLevel = QUALITY_LEVEL_01
    workspace.InterpolationThrottling = Enum.InterpolationThrottlingMode.Enabled
end)

for _, item in ipairs(getChildren(Lighting)) do
    if isA(item, "PostEffect") or isA(item, "Atmosphere") or isA(item, "Clouds") then
        pcall(function() item.Enabled = false end)
    elseif isA(item, "Sky") then
        pcall(destroy, item)
    end
end

local blackSky = Instance_new("Sky")
blackSky.Name = "PotatoBlackSky"
blackSky.SkyboxBk = BLACK_ASSET_ID
blackSky.SkyboxDn = BLACK_ASSET_ID
blackSky.SkyboxFt = BLACK_ASSET_ID
blackSky.SkyboxLf = BLACK_ASSET_ID
blackSky.SkyboxRt = BLACK_ASSET_ID
blackSky.SkyboxUp = BLACK_ASSET_ID
blackSky.CelestialBodiesShown = false
blackSky.Parent = Lighting

Lighting.GlobalShadows = false
Lighting.FogColor = COLOR_BLACK_VOID
Lighting.FogStart = 300
Lighting.FogEnd = 1200
Lighting.ClockTime = 14
Lighting.Brightness = 1
Lighting.EnvironmentDiffuseScale = 0
Lighting.EnvironmentSpecularScale = 0
Lighting.ExposureCompensation = 0
Lighting.Ambient = COLOR_AMBIENT_BRIGHT
Lighting.OutdoorAmbient = COLOR_AMBIENT_BRIGHT

local terrain = workspace.Terrain
if terrain then
    terrain.WaterWaveSize = 0
    terrain.WaterWaveSpeed = 0
    terrain.WaterReflectance = 0
    terrain.WaterTransparency = 0.9
    terrain.WaterColor = COLOR_WATER_BLUE
    if sethiddenproperty then
        pcall(function() sethiddenproperty(terrain, "Decoration", false) end)
    end
end

local function isProtectedInstance(obj)
    if not obj then return true end
    local cur = obj
    while cur and cur ~= workspace do
        if cur == LocalPlayer.Character then return true end
        if isA(cur, "Model") and getPlayerFromCharacter(Players, cur) then return true end
        local n = string_lower(cur.Name)
        if string_find(n, "booth", 1, true)
            or string_find(n, "bobber", 1, true)
            or string_find(n, "rod", 1, true)
            or string_find(n, "fishing", 1, true)
            or string_find(n, "bite", 1, true)
            or string_find(n, "strike", 1, true)
            or string_find(n, "hook", 1, true)
            or string_find(n, "lure", 1, true)
            or string_find(n, "indicator", 1, true)
            or string_find(n, "prompt", 1, true)
            or string_find(n, "npc", 1, true) then
            return true
        end
        cur = cur.Parent
    end
    return false
end

local function fastPotatoLeaf(obj)
    if not obj or processedCache[obj] then return end
    processedCache[obj] = true

    if isA(obj, "BasePart") then
        obj.Material = MATERIAL_SMOOTH_PLASTIC
        obj.CastShadow = false
        obj.Reflectance = 0
    elseif isA(obj, "Decal") or isA(obj, "Texture") then
        obj.Transparency = 1
        pcall(destroy, obj)
    elseif isA(obj, "MeshPart") then
        obj.TextureID = EMPTY_STR
        obj.Material = MATERIAL_SMOOTH_PLASTIC
        obj.CastShadow = false
        obj.Reflectance = 0
    elseif isA(obj, "SpecialMesh") then
        obj.TextureId = EMPTY_STR
    elseif isA(obj, "ParticleEmitter") or isA(obj, "Beam") or isA(obj, "Trail") or isA(obj, "Highlight") then
        obj.Enabled = false
    elseif isA(obj, "PointLight") or isA(obj, "SpotLight") or isA(obj, "SurfaceLight") then
        obj.Enabled = false
    elseif isA(obj, "SurfaceAppearance") then
        pcall(destroy, obj)
    elseif isA(obj, "BillboardGui") or isA(obj, "SurfaceGui") then
        obj.Enabled = false
    elseif isA(obj, "Sound") then
        obj.Volume = 0
    end
end

local function purgeDestinationBeam(item)
    if not item then return end
    local name = item.Name
    local lowerName = string_lower(name)
    if string_find(lowerName, "destination", 1, true) or string_find(lowerName, "waypoint", 1, true) then
        if isA(item, "Beam") then
            item.Enabled = false
            pcall(destroy, item)
        elseif isA(item, "Attachment") or isA(item, "BillboardGui") or isA(item, "Highlight") or isA(item, "BasePart") then
            pcall(destroy, item)
        end
    end
end

local function makePotato(obj)
    if not obj or processedCache[obj] then return end
    purgeDestinationBeam(obj)
    if isProtectedInstance(obj) then return end
    fastPotatoLeaf(obj)
end

local function handleWeatherInstance(inst)
    if not inst then return end
    local name = inst.Name
    if name == "Rain" or name == "Vynozen FogEffect" or string_find(string_lower(name), "rain", 1, true) or string_find(string_lower(name), "fog", 1, true) then
        for _, child in ipairs(getDescendants(inst)) do
            if isA(child, "BasePart") then
                child.Transparency = 1
                child.CastShadow = false
            elseif isA(child, "ParticleEmitter") or isA(child, "Beam") or isA(child, "PostEffect") then
                child.Enabled = false
            end
        end
    end
end

local function neutralizeWeather()
    local fog = findFirstChild(workspace, "Vynozen FogEffect")
    if fog then handleWeatherInstance(fog) end

    local rain = findFirstChild(workspace, "Rain")
    if rain then handleWeatherInstance(rain) end
end
neutralizeWeather()

trackConnection(workspace.ChildAdded:Connect(handleWeatherInstance))

local function makeModelInvisible(model)
    if not model then return end
    for _, item in ipairs(getDescendants(model)) do
        if isA(item, "BasePart") or isA(item, "Decal") then
            item.Transparency = 1
            if isA(item, "BasePart") then
                item.CastShadow = false
                if model.Name ~= "FakeIslands" then
                    item.CanCollide = false
                end
            end
        elseif isA(item, "ParticleEmitter") or isA(item, "Beam") or isA(item, "Trail") or isA(item, "Highlight") or isA(item, "Light") then
            item.Enabled = false
        end
    end
end

local function processCharItem(item)
    if not item then return end
    local n = string_lower(item.Name)
    if string_find(n, "rod", 1, true) or string_find(n, "bobber", 1, true) or string_find(n, "line", 1, true) or string_find(n, "hook", 1, true) or string_find(n, "fishing", 1, true) then
        return
    end

    if isA(item, "Accessory") or isA(item, "Shirt") or isA(item, "Pants") or isA(item, "ShirtGraphic") or isA(item, "CharacterMesh") or isA(item, "SurfaceAppearance") then
        pcall(destroy, item)
    elseif isA(item, "Decal") then
        pcall(destroy, item)
    elseif isA(item, "SpecialMesh") and item.Parent and item.Parent.Name == "Head" then
        pcall(destroy, item)
    elseif isA(item, "ParticleEmitter") or isA(item, "Beam") or isA(item, "Trail") or isA(item, "Highlight") or isA(item, "Light") or isA(item, "Fire") or isA(item, "Smoke") then
        item.Enabled = false
    elseif isA(item, "BasePart") then
        item.Material = MATERIAL_SMOOTH_PLASTIC
        item.CastShadow = false
        item.Reflectance = 0
    end
end

local function optimizeCharacter(char, player)
    if not char or not isA(char, "Model") or processedCache[char] then return end
    processedCache[char] = true

    if player and characterConnections[player] then
        for _, conn in ipairs(characterConnections[player]) do
            if conn and conn.Connected then pcall(conn.Disconnect, conn) end
        end
        characterConnections[player] = {}
    end

    for _, item in ipairs(getDescendants(char)) do
        processCharItem(item)
    end

    local charConn = char.DescendantAdded:Connect(processCharItem)
    if player then
        if not characterConnections[player] then characterConnections[player] = {} end
        table_insert(characterConnections[player], charConn)
    else
        trackConnection(charConn)
    end
end

local function cleanNPC(npc)
    if not npc or not isA(npc, "Model") or processedCache[npc] then return end
    processedCache[npc] = true

    local hum = findFirstChildOfClass(npc, "Humanoid")
    if hum then
        hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        hum.NameDisplayDistance = 0
        hum.HealthDisplayDistance = 0
    end

    for _, item in ipairs(getDescendants(npc)) do
        if not isA(item, "ProximityPrompt") and not isA(item, "BillboardGui") then
            if isA(item, "Accessory") or isA(item, "Shirt") or isA(item, "Pants") or isA(item, "ShirtGraphic") or isA(item, "CharacterMesh") or isA(item, "Decal") then
                pcall(destroy, item)
            elseif isA(item, "SpecialMesh") and item.Parent and item.Parent.Name == "Head" then
                item.TextureId = EMPTY_STR
            elseif isA(item, "MeshPart") then
                item.TextureID = EMPTY_STR
                item.Material = MATERIAL_SMOOTH_PLASTIC
                item.CastShadow = false
            elseif isA(item, "BasePart") then
                item.Material = MATERIAL_SMOOTH_PLASTIC
                item.CastShadow = false
            elseif isA(item, "ParticleEmitter") or isA(item, "Beam") or isA(item, "Trail") or isA(item, "Highlight") then
                item.Enabled = false
            end
        end
    end
end

local function trackOtherPlayer(p)
    if p == LocalPlayer then return end
    playerConnections[p] = {}

    local caConn = p.CharacterAdded:Connect(function(c)
        optimizeCharacter(c, p)
    end)
    table_insert(playerConnections[p], caConn)

    if p.Character then
        optimizeCharacter(p.Character, p)
    end
end

trackConnection(LocalPlayer.CharacterAdded:Connect(function(c)
    optimizeCharacter(c, LocalPlayer)
end))
trackConnection(Players.PlayerAdded:Connect(trackOtherPlayer))
trackConnection(Players.PlayerRemoving:Connect(function(p)
    if playerConnections[p] then
        for _, conn in ipairs(playerConnections[p]) do
            if conn and conn.Connected then pcall(conn.Disconnect, conn) end
        end
        playerConnections[p] = nil
    end
    if characterConnections[p] then
        for _, conn in ipairs(characterConnections[p]) do
            if conn and conn.Connected then pcall(conn.Disconnect, conn) end
        end
        characterConnections[p] = nil
    end
end))

local function runAdaptiveBatch(items, handler)
    local total = #items
    if total == 0 then return end

    local start = clock()
    for i = 1, total do
        local obj = items[i]
        if obj then handler(obj) end

        if (clock() - start) >= FRAME_BUDGET_SEC then
            task_wait()
            start = clock()
        end
    end
end

globalEnv._FishItActiveWorker = task_spawn(function()
    if LocalPlayer.Character then optimizeCharacter(LocalPlayer.Character, LocalPlayer) end
    for _, p in ipairs(Players:GetPlayers()) do
        trackOtherPlayer(p)
    end
    task_wait()

    for _, obj in ipairs(getChildren(workspace)) do
        local name = obj.Name
        if INVISIBLE_RIG_EXACT[name] or string_find(name, "Rig", 1, true) then
            makeModelInvisible(obj)
        end
        if SAFE_TO_DESTROY[name] then
            pcall(destroy, obj)
        end
    end
    task_wait()

    local npcFolder = findFirstChild(workspace, "NPC")
    if npcFolder then
        runAdaptiveBatch(getChildren(npcFolder), cleanNPC)
    end
    task_wait()

    for _, child in ipairs(getChildren(workspace)) do
        if child ~= terrain and not isProtectedInstance(child) then
            local descendants = getDescendants(child)
            if #descendants > 0 then
                runAdaptiveBatch(descendants, fastPotatoLeaf)
            end
        end
    end
    task_wait()

    if terrain then
        for _, v in ipairs(getDescendants(terrain)) do
            purgeDestinationBeam(v)
        end
    end

    local sounds = getDescendants(SoundService)
    runAdaptiveBatch(sounds, function(s)
        if isA(s, "Sound") then s.Volume = 0 end
    end)

    task_spawn(function()
        local pgui = waitForChild(LocalPlayer, "PlayerGui", 5)
        if pgui then
            local function checkGui(g)
                if PROMO_GUIS[g.Name] then
                    if isA(g, "ScreenGui") or isA(g, "BillboardGui") then
                        g.Enabled = false
                    else
                        pcall(destroy, g)
                    end
                end
            end

            for _, g in ipairs(getChildren(pgui)) do checkGui(g) end
            trackConnection(pgui.ChildAdded:Connect(checkGui))

            local hud = findFirstChild(pgui, "HUD")
            if hud then
                for _, elem in ipairs(getDescendants(hud)) do
                    local elemName = string_lower(elem.Name)
                    if string_find(elemName, "banner", 1, true) or string_find(elemName, "pack", 1, true) or string_find(elemName, "offer", 1, true) or string_find(elemName, "promo", 1, true) or string_find(elemName, "bundle", 1, true) then
                        if isA(elem, "GuiObject") then elem.Visible = false end
                    end
                end
            end
        end
    end)

    globalEnv._FishItActiveWorker = nil
end)

local pendingQueue = {}
local isBatchProcessing = false

local function processBatchQueue()
    if isBatchProcessing then return end
    isBatchProcessing = true

    task_spawn(function()
        task_wait(0.05)
        while #pendingQueue > 0 do
            local start = clock()
            while #pendingQueue > 0 do
                local obj = table_remove(pendingQueue)
                if obj and obj.Parent then
                    makePotato(obj)
                end
                if (clock() - start) >= FRAME_BUDGET_SEC then
                    task_wait()
                    start = clock()
                end
            end
        end
        isBatchProcessing = false
    end)
end

trackConnection(workspace.DescendantAdded:Connect(function(obj)
    if not obj or processedCache[obj] then return end
    purgeDestinationBeam(obj)
    table_insert(pendingQueue, obj)
    if not isBatchProcessing then
        processBatchQueue()
    end
end))

if terrain then
    trackConnection(terrain.DescendantAdded:Connect(purgeDestinationBeam))
end

local npcFolder = findFirstChild(workspace, "NPC")
if npcFolder then
    trackConnection(npcFolder.ChildAdded:Connect(function(npc)
        task_wait(0.1)
        cleanNPC(npc)
    end))
end

local vehFolder = findFirstChild(workspace, "Vehicles")
if vehFolder then
    trackConnection(vehFolder.ChildAdded:Connect(function(v)
        task_wait(0.2)
        for _, item in ipairs(getDescendants(v)) do makePotato(item) end
    end))
end

if hookfunction and newcclosure and not globalEnv._FishItHooked then
    globalEnv._FishItHooked = true
    local oldPrint; oldPrint = hookfunction(print, newcclosure(function(...)
        local firstArg = select(1, ...)
        if tostring(firstArg) == "No HRP" then return end
        return oldPrint(...)
    end))
    local oldWarn; oldWarn = hookfunction(warn, newcclosure(function(...)
        local firstArg = select(1, ...)
        if tostring(firstArg) == "No HRP" then return end
        return oldWarn(...)
    end))
end

globalEnv._FishItGCWorker = task_spawn(function()
    while true do
        task_wait(180)
        pcall(function()
            collectgarbage("collect")
        end)
    end
end)
