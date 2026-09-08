if rconsoleclear then pcall(rconsoleclear) elseif consoleclear then pcall(consoleclear) end

local globalEnv = (getgenv and getgenv()) or _G

if globalEnv._FishItActiveWorker and typeof(globalEnv._FishItActiveWorker) == "thread" then
    pcall(task.cancel, globalEnv._FishItActiveWorker)
    globalEnv._FishItActiveWorker = nil
end

if globalEnv._FishItLightingWorker and typeof(globalEnv._FishItLightingWorker) == "thread" then
    pcall(task.cancel, globalEnv._FishItLightingWorker)
    globalEnv._FishItLightingWorker = nil
end

if globalEnv._FishItCleanSky and typeof(globalEnv._FishItCleanSky) == "Instance" then
    pcall(game.Destroy, globalEnv._FishItCleanSky)
    globalEnv._FishItCleanSky = nil
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
local MaterialService = getService(game, "MaterialService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    repeat task.wait() until Players.LocalPlayer
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
local type = type
local clock = os.clock
local setmetatable = setmetatable
local string_find = string.find
local string_lower = string.lower
local table_insert = table.insert

local task = task
local task_wait = task.wait
local task_spawn = task.spawn

local Color3_fromRGB = Color3.fromRGB
local Instance_new = Instance.new
local Enum = Enum
local MATERIAL_SMOOTH_PLASTIC = Enum.Material.SmoothPlastic
local QUALITY_LEVEL_01 = Enum.QualityLevel.Level01

local COLOR_AMBIENT_BRIGHT = Color3_fromRGB(185, 185, 185)
local COLOR_FOG_COMFORT    = Color3_fromRGB(185, 185, 185)
local COLOR_WATER_BLUE     = Color3_fromRGB(65, 165, 230)
local EMPTY_STR            = ""

local FRAME_BUDGET_SEC = 0.012

local processedCache = setmetatable({}, { __mode = "k" })
local boothCache     = setmetatable({}, { __mode = "k" })

local SAFE_TO_DESTROY = {
    ["Group Fishing Visuals"] = true,
    ["CosmeticFolder"]        = true,
    ["Aquariums"]             = true,
    ["!!! Aquariums"]         = true,
    ["Radiant"]               = true,
    ["Divine"]                = true,
    ["FloorBeam"]             = true,
    ["DestinationBeam"]       = true,
}

local INVISIBLE_RIG_EXACT = {
    ["EmoteCratePreviewRig"] = true,
    ["FakeRig1"]             = true,
    ["LimitedRig1"]          = true,
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
    ["Lootbox"]                = true,
    ["!!!! AbilityUI"]         = true,
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

local cleanSky = findFirstChild(Lighting, "CleanSky")
if not cleanSky then
    cleanSky = Instance_new("Sky")
    cleanSky.Name = "CleanSky"
    cleanSky.CelestialBodiesShown = false
    cleanSky.SunAngularSize = 0
    cleanSky.MoonAngularSize = 0
    cleanSky.StarCount = 0
    cleanSky.SunTextureId = EMPTY_STR
    cleanSky.MoonTextureId = EMPTY_STR
    cleanSky.SkyboxBk = EMPTY_STR
    cleanSky.SkyboxDn = EMPTY_STR
    cleanSky.SkyboxFt = EMPTY_STR
    cleanSky.SkyboxLf = EMPTY_STR
    cleanSky.SkyboxRt = EMPTY_STR
    cleanSky.SkyboxUp = EMPTY_STR
    cleanSky.Parent = Lighting
end
globalEnv._FishItCleanSky = cleanSky

local function disablePostEffect(item)
    if not item or item == cleanSky or processedCache[item] then return end
    processedCache[item] = true
    if isA(item, "Atmosphere") then
        pcall(function()
            item.Density = 0
            item.Haze = 0
            item.Glare = 0
        end)
    elseif isA(item, "Clouds") then
        pcall(function()
            item.Cover = 0
            item.Density = 0
            item.Enabled = false
        end)
    elseif isA(item, "PostEffect") then
        pcall(function()
            if item.Enabled then item.Enabled = false end
            trackConnection(item:GetPropertyChangedSignal("Enabled"):Connect(function()
                if item.Enabled then item.Enabled = false end
            end))
        end)
    elseif isA(item, "Sky") and item ~= cleanSky then
        pcall(destroy, item)
    end
end

for _, item in ipairs(getChildren(Lighting)) do
    disablePostEffect(item)
end

pcall(function()
    if MaterialService then
        pcall(function() MaterialService.Use2022Materials = false end)
        for _, item in ipairs(getDescendants(MaterialService)) do
            if isA(item, "MaterialVariant") then
                pcall(function() item.ColorMap = EMPTY_STR end)
                pcall(function() item.NormalMap = EMPTY_STR end)
                pcall(function() item.RoughnessMap = EMPTY_STR end)
                pcall(function() item.MetalnessMap = EMPTY_STR end)
            end
        end
    end
end)

local function applyFullbright()
    pcall(function()
        if not cleanSky or not cleanSky.Parent or cleanSky.Parent ~= Lighting then
            local existing = findFirstChild(Lighting, "CleanSky")
            if existing and isA(existing, "Sky") then
                cleanSky = existing
            else
                cleanSky = Instance_new("Sky")
                cleanSky.Name = "CleanSky"
                cleanSky.CelestialBodiesShown = false
                cleanSky.SunAngularSize = 0
                cleanSky.MoonAngularSize = 0
                cleanSky.StarCount = 0
                cleanSky.SunTextureId = EMPTY_STR
                cleanSky.MoonTextureId = EMPTY_STR
                cleanSky.SkyboxBk = EMPTY_STR
                cleanSky.SkyboxDn = EMPTY_STR
                cleanSky.SkyboxFt = EMPTY_STR
                cleanSky.SkyboxLf = EMPTY_STR
                cleanSky.SkyboxRt = EMPTY_STR
                cleanSky.SkyboxUp = EMPTY_STR
                cleanSky.Parent = Lighting
            end
            globalEnv._FishItCleanSky = cleanSky
        end
        if cleanSky.CelestialBodiesShown then cleanSky.CelestialBodiesShown = false end
        if cleanSky.SunAngularSize ~= 0 then cleanSky.SunAngularSize = 0 end
        if cleanSky.MoonAngularSize ~= 0 then cleanSky.MoonAngularSize = 0 end
    end)

    Lighting.ClockTime = 14
    Lighting.TimeOfDay = "14:00:00"
    Lighting.Brightness = 2
    Lighting.GlobalShadows = false
    Lighting.Ambient = COLOR_AMBIENT_BRIGHT
    Lighting.OutdoorAmbient = COLOR_AMBIENT_BRIGHT
    Lighting.ColorShift_Top = Color3_fromRGB(0, 0, 0)
    Lighting.ColorShift_Bottom = Color3_fromRGB(0, 0, 0)
    Lighting.FogStart = 0
    Lighting.FogEnd = 100000
    Lighting.FogColor = COLOR_FOG_COMFORT
    Lighting.EnvironmentDiffuseScale = 0
    Lighting.EnvironmentSpecularScale = 0
    Lighting.ExposureCompensation = 0.25
end

applyFullbright()

globalEnv._FishItLightingWorker = task_spawn(function()
    while true do
        task_wait(0.2)
        if Lighting.ClockTime ~= 14 or Lighting.Brightness ~= 2 or Lighting.Ambient ~= COLOR_AMBIENT_BRIGHT or Lighting.ExposureCompensation ~= 0.25 or Lighting.EnvironmentSpecularScale ~= 0 or Lighting.GlobalShadows ~= false then
            pcall(applyFullbright)
        end
    end
end)

trackConnection(Lighting.ChildAdded:Connect(disablePostEffect))

local camConn
local function secureCamera(cam)
    if not cam then return end
    if camConn and camConn.Connected then pcall(camConn.Disconnect, camConn) end
    for _, item in ipairs(getChildren(cam)) do
        disablePostEffect(item)
    end
    camConn = cam.ChildAdded:Connect(disablePostEffect)
    trackConnection(camConn)
end

secureCamera(workspace.CurrentCamera)
trackConnection(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    secureCamera(workspace.CurrentCamera)
end))

local terrain = workspace.Terrain
if terrain then
    pcall(function()
        terrain.WaterWaveSize = 0
        terrain.WaterWaveSpeed = 0
        terrain.WaterReflectance = 0
        terrain.WaterTransparency = 0.9
        terrain.WaterColor = COLOR_WATER_BLUE
        if sethiddenproperty then
            pcall(function() sethiddenproperty(terrain, "Decoration", false) end)
        end
    end)

    local function purgeClouds(item)
        if isA(item, "Clouds") then
            pcall(function()
                item.Cover = 0
                item.Density = 0
                item.Enabled = false
            end)
            pcall(destroy, item)
        end
    end

    for _, item in ipairs(getChildren(terrain)) do
        purgeClouds(item)
    end
    trackConnection(terrain.ChildAdded:Connect(purgeClouds))
end

local function isBoothDescendant(obj)
    if not obj or obj == workspace then return false end
    if boothCache[obj] ~= nil then
        return boothCache[obj]
    end

    local cur = obj
    while cur and cur ~= workspace do
        if boothCache[cur] ~= nil then
            boothCache[obj] = boothCache[cur]
            return boothCache[cur]
        end
        local n = cur.Name
        if n == "Booths" or n == "Booth" or string_find(n, "Booth") or string_find(n, "booth") then
            boothCache[cur] = true
            boothCache[obj] = true
            return true
        end
        cur = cur.Parent
    end

    boothCache[obj] = false
    return false
end

local function isPlayerDescendant(obj)
    if not obj or obj == workspace then return false end
    local cur = obj
    while cur and cur ~= workspace do
        if cur == LocalPlayer.Character then return true end
        if isA(cur, "Model") and getPlayerFromCharacter(Players, cur) then return true end
        cur = cur.Parent
    end
    return false
end

local function isFishingLine(item)
    if not item then return false end
    local n = string_lower(item.Name)
    return n == "line" or n == "fishingline" or n == "rope" or (string_find(n, "line", 1, true) and not string_find(n, "lightning", 1, true))
end

local function cleanFishingEffects(item)
    if not item then return end
    if isBoothDescendant(item) then return end
    if isFishingLine(item) then return end

    if isA(item, "ParticleEmitter") or isA(item, "Highlight") or isA(item, "Light") or isA(item, "Trail") or isA(item, "Fire") or isA(item, "Smoke") then
        pcall(destroy, item)
    elseif isA(item, "Beam") then
        if not isFishingLine(item) then
            pcall(destroy, item)
        end
    elseif isA(item, "BasePart") then
        pcall(function()
            item.Material = MATERIAL_SMOOTH_PLASTIC
            item.CastShadow = false
            item.Reflectance = 0
            if item.MaterialVariant ~= EMPTY_STR then
                item.MaterialVariant = EMPTY_STR
            end
        end)
        local n = string_lower(item.Name)
        if string_find(n, "vfx", 1, true) or string_find(n, "effect", 1, true) or string_find(n, "aura", 1, true) or string_find(n, "glow", 1, true) or string_find(n, "lightning", 1, true) or string_find(n, "electricity", 1, true) or string_find(n, "spark", 1, true) or string_find(n, "energy", 1, true) then
            pcall(function()
                item.Transparency = 1
                destroy(item)
            end)
        end
    end
end

local function isProtected(obj)
    if not obj then return true end
    local name = obj.Name
    if name == "Terrain" or name == "Camera" then return true end
    if isBoothDescendant(obj) then return true end
    if isFishingLine(obj) then return true end
    if string_find(name, "Bobber") or string_find(name, "bobber") then
        cleanFishingEffects(obj)
        return true
    end
    if isPlayerDescendant(obj) then return true end
    return false
end

local function purgeDestinationBeam(item)
    if not item or isBoothDescendant(item) then return end
    local name = item.Name
    if string_find(name, "Destination") or string_find(name, "Waypoint") or string_find(name, "FloorBeam") or string_find(name, "destination") or string_find(name, "waypoint") or string_find(name, "floorbeam") then
        if isA(item, "Beam") or isA(item, "Attachment") or isA(item, "BillboardGui") or isA(item, "Highlight") or isA(item, "BasePart") then
            pcall(destroy, item)
        end
    end
end

local function makePotato(obj)
    if not obj or processedCache[obj] then return end
    if isProtected(obj) then return end
    processedCache[obj] = true

    if isA(obj, "BasePart") then
        pcall(function()
            obj.Material = MATERIAL_SMOOTH_PLASTIC
            obj.CastShadow = false
            obj.Reflectance = 0
            if obj.MaterialVariant ~= EMPTY_STR then
                obj.MaterialVariant = EMPTY_STR
            end
        end)
        if isA(obj, "MeshPart") then
            pcall(function() obj.TextureID = EMPTY_STR end)
        end
        for _, child in ipairs(getChildren(obj)) do
            if isA(child, "SurfaceAppearance") or isA(child, "Decal") or isA(child, "Texture") then
                pcall(destroy, child)
            end
        end
    elseif isA(obj, "Decal") or isA(obj, "Texture") then
        pcall(function()
            obj.Transparency = 1
            destroy(obj)
        end)
    elseif isA(obj, "SpecialMesh") then
        pcall(function() obj.TextureId = EMPTY_STR end)
    elseif isA(obj, "ParticleEmitter") or isA(obj, "Beam") or isA(obj, "Trail") or isA(obj, "Highlight") then
        pcall(function() obj.Enabled = false end)
    elseif isA(obj, "PointLight") or isA(obj, "SpotLight") or isA(obj, "SurfaceLight") then
        pcall(function() obj.Enabled = false end)
    elseif isA(obj, "SurfaceAppearance") then
        pcall(destroy, obj)
    elseif isA(obj, "BillboardGui") or isA(obj, "SurfaceGui") then
        pcall(function() obj.Enabled = false end)
    elseif isA(obj, "Sound") then
        pcall(function() obj.Volume = 0 end)
    end
end

local function handleWeatherInstance(inst)
    if not inst then return end
    local name = inst.Name
    if name == "Rain" or name == "Vynozen FogEffect" or string_find(name, "Rain") or string_find(name, "Fog") or string_find(name, "rain") or string_find(name, "fog") then
        for _, child in ipairs(getDescendants(inst)) do
            if isA(child, "BasePart") then
                pcall(function()
                    child.Transparency = 1
                    child.CastShadow = false
                end)
            elseif isA(child, "ParticleEmitter") or isA(child, "Beam") or isA(child, "PostEffect") then
                pcall(function() child.Enabled = false end)
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
            pcall(function()
                item.Transparency = 1
                if isA(item, "BasePart") then
                    item.CastShadow = false
                    if model.Name ~= "FakeIslands" then
                        item.CanCollide = false
                    end
                end
            end)
        elseif isA(item, "ParticleEmitter") or isA(item, "Beam") or isA(item, "Trail") or isA(item, "Highlight") or isA(item, "Light") then
            pcall(function() item.Enabled = false end)
        end
    end
end

local function processCharItem(item)
    if not item then return end
    if isBoothDescendant(item) then return end

    cleanFishingEffects(item)

    if isA(item, "Accessory") or isA(item, "Shirt") or isA(item, "Pants") or isA(item, "ShirtGraphic") or isA(item, "CharacterMesh") or isA(item, "SurfaceAppearance") then
        pcall(destroy, item)
    elseif isA(item, "Decal") then
        pcall(destroy, item)
    elseif isA(item, "SpecialMesh") and item.Parent and item.Parent.Name == "Head" then
        pcall(destroy, item)
    elseif isA(item, "BasePart") then
        pcall(function()
            item.Material = MATERIAL_SMOOTH_PLASTIC
            item.CastShadow = false
            item.Reflectance = 0
            if item.MaterialVariant ~= EMPTY_STR then
                item.MaterialVariant = EMPTY_STR
            end
        end)
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
        pcall(function()
            hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
            hum.NameDisplayDistance = 0
            hum.HealthDisplayDistance = 0
        end)
    end

    for _, item in ipairs(getDescendants(npc)) do
        if not isA(item, "ProximityPrompt") and not isA(item, "BillboardGui") then
            if isA(item, "Accessory") or isA(item, "Shirt") or isA(item, "Pants") or isA(item, "ShirtGraphic") or isA(item, "CharacterMesh") or isA(item, "Decal") then
                pcall(destroy, item)
            elseif isA(item, "SpecialMesh") and item.Parent and item.Parent.Name == "Head" then
                pcall(function() item.TextureId = EMPTY_STR end)
            elseif isA(item, "MeshPart") then
                pcall(function() item.TextureID = EMPTY_STR end)
                pcall(function()
                    item.Material = MATERIAL_SMOOTH_PLASTIC
                    item.CastShadow = false
                    if item.MaterialVariant ~= EMPTY_STR then
                        item.MaterialVariant = EMPTY_STR
                    end
                end)
            elseif isA(item, "BasePart") then
                pcall(function()
                    item.Material = MATERIAL_SMOOTH_PLASTIC
                    item.CastShadow = false
                    if item.MaterialVariant ~= EMPTY_STR then
                        item.MaterialVariant = EMPTY_STR
                    end
                end)
            elseif isA(item, "ParticleEmitter") or isA(item, "Beam") or isA(item, "Trail") or isA(item, "Highlight") then
                pcall(function() item.Enabled = false end)
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

local backpack = findFirstChildOfClass(LocalPlayer, "Backpack")
if backpack then
    for _, item in ipairs(getDescendants(backpack)) do
        cleanFishingEffects(item)
    end
    trackConnection(backpack.DescendantAdded:Connect(cleanFishingEffects))
end

local charsFolder = findFirstChild(workspace, "Characters")
if charsFolder then
    for _, c in ipairs(getChildren(charsFolder)) do
        local p = getPlayerFromCharacter(Players, c)
        optimizeCharacter(c, p)
    end
    trackConnection(charsFolder.ChildAdded:Connect(function(c)
        task_wait(0.05)
        local p = getPlayerFromCharacter(Players, c)
        optimizeCharacter(c, p)
    end))
end

local function runAdaptiveBatch(items, handler)
    local total = #items
    if total == 0 then return end

    local start = clock()
    for i = 1, total do
        local obj = items[i]
        if obj then
            pcall(handler, obj)
        end

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

    local mapDescendants = getDescendants(workspace)
    for _, item in ipairs(mapDescendants) do
        local n = item.Name
        if n == "Booths" or n == "Booth" or string_find(n, "Booth") or string_find(n, "booth") then
            boothCache[item] = true
            for _, desc in ipairs(getDescendants(item)) do
                boothCache[desc] = true
            end
        else
            local lowerName = string_lower(n)
            if string_find(lowerName, "bobber", 1, true) or string_find(lowerName, "rod", 1, true) then
                cleanFishingEffects(item)
            end
        end
    end

    for _, obj in ipairs(getChildren(workspace)) do
        local name = obj.Name
        if not isBoothDescendant(obj) then
            if INVISIBLE_RIG_EXACT[name] or string_find(name, "Rig") then
                makeModelInvisible(obj)
            end
            if SAFE_TO_DESTROY[name] then
                pcall(destroy, obj)
            end
        end
    end

    local npcFolder = findFirstChild(workspace, "NPC")
    if npcFolder then
        runAdaptiveBatch(getChildren(npcFolder), cleanNPC)
    end

    runAdaptiveBatch(mapDescendants, makePotato)

    local sounds = getDescendants(SoundService)
    runAdaptiveBatch(sounds, function(s)
        if isA(s, "Sound") and s.Volume ~= 0 then
            pcall(function() s.Volume = 0 end)
        end
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

trackConnection(workspace.DescendantAdded:Connect(function(obj)
    if not obj or processedCache[obj] then return end
    if isA(obj, "Clouds") then
        pcall(function()
            obj.Cover = 0
            obj.Density = 0
            obj.Enabled = false
            destroy(obj)
        end)
        return
    end
    if isBoothDescendant(obj) then return end
    purgeDestinationBeam(obj)
    local n = string_lower(obj.Name)
    if string_find(n, "bobber", 1, true) or string_find(n, "rod", 1, true) then
        cleanFishingEffects(obj)
        for _, d in ipairs(getDescendants(obj)) do
            cleanFishingEffects(d)
        end
        return
    end
    pcall(makePotato, obj)
end))

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
        task_wait(0.1)
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
