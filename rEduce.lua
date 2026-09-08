if rconsoleclear then pcall(rconsoleclear) elseif consoleclear then pcall(consoleclear) end

local globalEnv = (getgenv and getgenv()) or _G

if globalEnv._FishItActiveWorker and typeof(globalEnv._FishItActiveWorker) == "thread" then
    pcall(task.cancel, globalEnv._FishItActiveWorker)
    globalEnv._FishItActiveWorker = nil
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
local Enum = Enum
local MATERIAL_SMOOTH_PLASTIC = Enum.Material.SmoothPlastic
local QUALITY_LEVEL_01 = Enum.QualityLevel.Level01

local COLOR_AMBIENT_BRIGHT = Color3_fromRGB(255, 255, 255)
local COLOR_WATER_BLUE     = Color3_fromRGB(65, 165, 230)
local EMPTY_STR            = ""

local FRAME_BUDGET_SEC = 0.003

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

local function disablePostEffect(item)
    if not item or processedCache[item] then return end
    processedCache[item] = true
    if isA(item, "PostEffect") or isA(item, "Atmosphere") or isA(item, "Clouds") then
        pcall(function()
            if item.Enabled then item.Enabled = false end
            trackConnection(item:GetPropertyChangedSignal("Enabled"):Connect(function()
                if item.Enabled then item.Enabled = false end
            end))
        end)
    elseif isA(item, "Sky") then
        pcall(destroy, item)
    end
end

for _, item in ipairs(getChildren(Lighting)) do
    disablePostEffect(item)
end

if MaterialService then
    pcall(function() MaterialService.Use2022Materials = false end)
    for _, item in ipairs(getChildren(MaterialService)) do
        if isA(item, "MaterialVariant") then
            pcall(destroy, item)
        end
    end
end

local function applyFullbright()
    Lighting.ClockTime = 14
    Lighting.Brightness = 0
    Lighting.GlobalShadows = false
    Lighting.Ambient = COLOR_AMBIENT_BRIGHT
    Lighting.OutdoorAmbient = COLOR_AMBIENT_BRIGHT
    Lighting.ColorShift_Top = COLOR_AMBIENT_BRIGHT
    Lighting.ColorShift_Bottom = COLOR_AMBIENT_BRIGHT
    Lighting.FogStart = 0
    Lighting.FogEnd = 100000
    Lighting.FogColor = COLOR_AMBIENT_BRIGHT
    Lighting.EnvironmentDiffuseScale = 0
    Lighting.EnvironmentSpecularScale = 0
    Lighting.ExposureCompensation = 0.6
end

applyFullbright()

local isEnforcingLighting = false
trackConnection(Lighting.Changed:Connect(function(prop)
    if isEnforcingLighting then return end
    if prop == "ClockTime" or prop == "Ambient" or prop == "OutdoorAmbient" or prop == "Brightness" or prop == "FogEnd" or prop == "GlobalShadows" or prop == "EnvironmentSpecularScale" then
        isEnforcingLighting = true
        applyFullbright()
        isEnforcingLighting = false
    end
end))

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
    terrain.WaterWaveSize = 0
    terrain.WaterWaveSpeed = 0
    terrain.WaterReflectance = 0
    terrain.WaterTransparency = 0.9
    terrain.WaterColor = COLOR_WATER_BLUE
    if sethiddenproperty then
        pcall(function() sethiddenproperty(terrain, "Decoration", false) end)
    end
end

local function isProtected(obj)
    if not obj then return true end
    local name = obj.Name
    if name == "Terrain" or name == "Camera" then return true end
    if name == "Bobber" or name == "FishingLine" then return true end
    local parent = obj.Parent
    if parent and parent ~= workspace then
        if parent == LocalPlayer.Character then return true end
        local pp = parent.Parent
        if pp and pp == LocalPlayer.Character then return true end
        if isA(parent, "Model") and getPlayerFromCharacter(Players, parent) then return true end
    end
    return false
end

local function purgeDestinationBeam(item)
    if not item then return end
    local name = item.Name
    if string_find(name, "Destination") or string_find(name, "Waypoint") or string_find(name, "destination") or string_find(name, "waypoint") then
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
        obj.Material = MATERIAL_SMOOTH_PLASTIC
        obj.CastShadow = false
        obj.Reflectance = 0
        if isA(obj, "MeshPart") then
            obj.TextureID = EMPTY_STR
        end
    elseif isA(obj, "Decal") or isA(obj, "Texture") then
        obj.Transparency = 1
        pcall(destroy, obj)
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

local function handleWeatherInstance(inst)
    if not inst then return end
    local name = inst.Name
    if name == "Rain" or name == "Vynozen FogEffect" or string_find(name, "Rain") or string_find(name, "Fog") or string_find(name, "rain") or string_find(name, "fog") then
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
    local n = item.Name
    if string_find(n, "Rod") or string_find(n, "rod") or string_find(n, "Bobber") or string_find(n, "bobber") or string_find(n, "Line") or string_find(n, "line") or string_find(n, "Hook") or string_find(n, "hook") or string_find(n, "Fishing") or string_find(n, "fishing") then
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

    local booths = findFirstChild(workspace, "Booths") or findFirstChild(workspace, "Booth")
    if booths then
        processedCache[booths] = true
        for _, item in ipairs(getDescendants(booths)) do
            processedCache[item] = true
        end
    end

    for _, obj in ipairs(getChildren(workspace)) do
        local name = obj.Name
        if INVISIBLE_RIG_EXACT[name] or string_find(name, "Rig") then
            makeModelInvisible(obj)
        end
        if SAFE_TO_DESTROY[name] then
            pcall(destroy, obj)
        end
    end

    local npcFolder = findFirstChild(workspace, "NPC")
    if npcFolder then
        runAdaptiveBatch(getChildren(npcFolder), cleanNPC)
    end

    local mapDescendants = getDescendants(workspace)
    runAdaptiveBatch(mapDescendants, makePotato)

    local sounds = getDescendants(SoundService)
    runAdaptiveBatch(sounds, function(s)
        if isA(s, "Sound") and s.Volume ~= 0 then s.Volume = 0 end
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
    purgeDestinationBeam(obj)
    task_wait()
    makePotato(obj)
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
