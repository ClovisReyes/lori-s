if not game:IsLoaded() then
    local loaded = false
    local conn; conn = game.Loaded:Connect(function()
        loaded = true
        if conn and conn.Connected then conn:Disconnect() end
    end)
    repeat task.wait() until game:IsLoaded() or loaded
end

if rconsoleclear then pcall(rconsoleclear) elseif consoleclear then pcall(consoleclear) end

local globalEnv = (getgenv and getgenv()) or _G

for _, key in ipairs({"_FishItActiveWorker", "_FishItLightingWorker"}) do
    if globalEnv[key] and typeof(globalEnv[key]) == "thread" then
        pcall(task.cancel, globalEnv[key])
        globalEnv[key] = nil
    end
end

if globalEnv._FishItCleanSky and typeof(globalEnv._FishItCleanSky) == "Instance" then
    pcall(game.Destroy, globalEnv._FishItCleanSky)
    globalEnv._FishItCleanSky = nil
end

local function cleanupList(list)
    if not list then return end
    for _, item in pairs(list) do
        if typeof(item) == "RBXScriptConnection" and item.Connected then
            pcall(item.Disconnect, item)
        elseif type(item) == "table" then
            cleanupList(item)
        end
    end
end

cleanupList(globalEnv._FishItOptimizerConnections)
cleanupList(globalEnv._FishItPlayerConnections)
cleanupList(globalEnv._FishItCharacterConnections)

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
local RunService = getService(game, "RunService")

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

local ipairs, pairs, pcall, tostring, type = ipairs, pairs, pcall, tostring, type
local clock, setmetatable = os.clock, setmetatable
local string_find, string_lower = string.find, string.lower
local table_insert = table.insert
local task_wait, task_spawn = task.wait, task.spawn

local Color3_fromRGB = Color3.fromRGB
local Instance_new = Instance.new
local Enum = Enum
local MATERIAL_SMOOTH_PLASTIC = Enum.Material.SmoothPlastic
local QUALITY_LEVEL_01 = Enum.QualityLevel.Level01

local COLOR_AMBIENT_BRIGHT = Color3_fromRGB(255, 255, 255)
local COLOR_FOG_COMFORT    = Color3_fromRGB(255, 255, 255)
local COLOR_WATER_BLUE     = Color3_fromRGB(65, 165, 230)
local EMPTY_STR            = ""

local SKY_DAY_BK = "rbxasset://textures/sky/sky512_bk.tex"
local SKY_DAY_DN = "rbxasset://textures/sky/sky512_dn.tex"
local SKY_DAY_FT = "rbxasset://textures/sky/sky512_ft.tex"
local SKY_DAY_LF = "rbxasset://textures/sky/sky512_lf.tex"
local SKY_DAY_RT = "rbxasset://textures/sky/sky512_rt.tex"
local SKY_DAY_UP = "rbxasset://textures/sky/sky512_up.tex"

local FRAME_BUDGET_SEC = 0.012

local processedCache = setmetatable({}, { __mode = "k" })
local boothCache     = setmetatable({}, { __mode = "k" })

local SAFE_TO_DESTROY = {
    ["Group Fishing Visuals"] = true, ["CosmeticFolder"] = true, ["Aquariums"] = true,
    ["!!! Aquariums"] = true, ["Radiant"] = true, ["Divine"] = true, ["FloorBeam"] = true,
    ["DestinationBeam"] = true, ["VFX"] = true, ["Wave"] = true, ["Waves"] = true,
    ["Perfect Area Highlight"] = true, ["AreaHighlight"] = true, ["Border"] = true,
}

local INVISIBLE_RIG_EXACT = {
    ["EmoteCratePreviewRig"] = true, ["FakeRig1"] = true, ["LimitedRig1"] = true,
    ["Props"] = true, ["Sunken Wreckage"] = true, ["FakeIslands"] = true,
}

local PROMO_GUIS = {
    ["!!! Click Effect"] = true, ["Border"] = true, ["AreaHighlight"] = true,
    ["Exclusive Store"] = true, ["!!! Starter Pack"] = true, ["TokenShardsAd"] = true,
    ["BattlepassShop"] = true, ["EventLimitedShop"] = true, ["!!! BUY SPINS"] = true,
    ["Spin Wheel"] = true, ["LootboxDisplay"] = true, ["Lootbox"] = true,
    ["!!!! AbilityUI"] = true, ["EmoteLootbox"] = true, ["!!! Gifting"] = true,
    ["BlackMarket"] = true, ["GalaxyEvent"] = true, ["PurchaseScreenBlackout"] = true,
    ["EggIndicator"] = true,
}

pcall(function()
    settings().Rendering.QualityLevel = QUALITY_LEVEL_01
    workspace.InterpolationThrottling = Enum.InterpolationThrottlingMode.Enabled
end)

local cleanSky
local function ensureCleanSky()
    if cleanSky and cleanSky.Parent == Lighting then return cleanSky end
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
        cleanSky.SkyboxBk = SKY_DAY_BK
        cleanSky.SkyboxDn = SKY_DAY_DN
        cleanSky.SkyboxFt = SKY_DAY_FT
        cleanSky.SkyboxLf = SKY_DAY_LF
        cleanSky.SkyboxRt = SKY_DAY_RT
        cleanSky.SkyboxUp = SKY_DAY_UP
        cleanSky.Parent = Lighting
    end
    if cleanSky.CelestialBodiesShown then cleanSky.CelestialBodiesShown = false end
    if cleanSky.SkyboxBk ~= SKY_DAY_BK then
        cleanSky.SkyboxBk = SKY_DAY_BK
        cleanSky.SkyboxDn = SKY_DAY_DN
        cleanSky.SkyboxFt = SKY_DAY_FT
        cleanSky.SkyboxLf = SKY_DAY_LF
        cleanSky.SkyboxRt = SKY_DAY_RT
        cleanSky.SkyboxUp = SKY_DAY_UP
    end
    globalEnv._FishItCleanSky = cleanSky
    return cleanSky
end

ensureCleanSky()

local function disablePostEffect(item)
    if not item or item == cleanSky or processedCache[item] then return end
    processedCache[item] = true
    if isA(item, "Atmosphere") or isA(item, "Clouds") or (isA(item, "Sky") and item ~= cleanSky) then
        pcall(destroy, item)
    elseif isA(item, "PostEffect") then
        pcall(function()
            item.Enabled = false
            if isA(item, "BloomEffect") then
                item.Intensity = 0
                item.Size = 0
                item.Threshold = 2
            elseif isA(item, "ColorCorrectionEffect") then
                item.TintColor = COLOR_AMBIENT_BRIGHT
                item.Contrast = 0
                item.Saturation = 0
                item.Brightness = 0
            end
        end)
        trackConnection(item:GetPropertyChangedSignal("Enabled"):Connect(function()
            if item.Enabled then item.Enabled = false end
        end))
    end
end

for _, item in ipairs(getChildren(Lighting)) do disablePostEffect(item) end

local lightingProfiles = findFirstChild(Lighting, "LightingProfiles")
if lightingProfiles then
    for _, item in ipairs(getDescendants(lightingProfiles)) do disablePostEffect(item) end
    trackConnection(lightingProfiles.DescendantAdded:Connect(disablePostEffect))
end

pcall(function()
    if MaterialService then
        pcall(function() MaterialService.Use2022Materials = false end)
        if sethiddenproperty then
            pcall(function() sethiddenproperty(MaterialService, "Use2022Materials", false) end)
        end
        for _, item in ipairs(getDescendants(MaterialService)) do
            if isA(item, "MaterialVariant") then
                pcall(function()
                    item.ColorMap = EMPTY_STR
                    item.NormalMap = EMPTY_STR
                    item.RoughnessMap = EMPTY_STR
                    item.MetalnessMap = EMPTY_STR
                end)
                pcall(destroy, item)
            end
        end
    end
end)

local function applyFullbright()
    pcall(ensureCleanSky)
    Lighting.ClockTime = 14
    Lighting.TimeOfDay = "14:00:00"
    Lighting.Brightness = 0
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
    Lighting.ExposureCompensation = 0.85
end

applyFullbright()

globalEnv._FishItLightingWorker = task_spawn(function()
    while true do
        task_wait(0.2)
        for _, item in ipairs(getChildren(Lighting)) do
            if isA(item, "Atmosphere") or isA(item, "Clouds") or (isA(item, "Sky") and item ~= cleanSky) then
                pcall(destroy, item)
            end
        end
        if Lighting.ClockTime ~= 14 or Lighting.Brightness ~= 0 or Lighting.Ambient ~= COLOR_AMBIENT_BRIGHT or Lighting.ExposureCompensation ~= 0.85 or Lighting.FogEnd ~= 100000 or (cleanSky and cleanSky.Parent ~= Lighting) then
            pcall(applyFullbright)
        end
    end
end)

local lockingLighting = false
local function lockLightingFast()
    if lockingLighting then return end
    if Lighting.ClockTime ~= 14 or Lighting.Brightness ~= 0 or Lighting.Ambient ~= COLOR_AMBIENT_BRIGHT or Lighting.OutdoorAmbient ~= COLOR_AMBIENT_BRIGHT or Lighting.FogEnd ~= 100000 or Lighting.ExposureCompensation ~= 0.85 then
        lockingLighting = true
        applyFullbright()
        lockingLighting = false
    end
end

trackConnection(Lighting:GetPropertyChangedSignal("ClockTime"):Connect(lockLightingFast))
trackConnection(Lighting:GetPropertyChangedSignal("TimeOfDay"):Connect(lockLightingFast))
trackConnection(Lighting:GetPropertyChangedSignal("Brightness"):Connect(lockLightingFast))
trackConnection(Lighting:GetPropertyChangedSignal("Ambient"):Connect(lockLightingFast))
trackConnection(Lighting:GetPropertyChangedSignal("OutdoorAmbient"):Connect(lockLightingFast))
trackConnection(Lighting:GetPropertyChangedSignal("FogEnd"):Connect(lockLightingFast))
trackConnection(Lighting:GetPropertyChangedSignal("FogColor"):Connect(lockLightingFast))
trackConnection(Lighting:GetPropertyChangedSignal("ExposureCompensation"):Connect(lockLightingFast))

if RunService then
    trackConnection(RunService.RenderStepped:Connect(function()
        if Lighting.ClockTime ~= 14 or Lighting.Brightness ~= 0 or Lighting.Ambient ~= COLOR_AMBIENT_BRIGHT or Lighting.FogEnd ~= 100000 then
            lockLightingFast()
        end
        if cleanSky and cleanSky.Parent ~= Lighting then
            pcall(function() cleanSky.Parent = Lighting end)
        end
    end))
end

trackConnection(Lighting.ChildAdded:Connect(disablePostEffect))

local camConn
local function secureCamera(cam)
    if not cam then return end
    if camConn and camConn.Connected then pcall(camConn.Disconnect, camConn) end
    for _, item in ipairs(getChildren(cam)) do disablePostEffect(item) end
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
        terrain.Decoration = false
        if sethiddenproperty then
            pcall(function() sethiddenproperty(terrain, "Decoration", false) end)
        end
    end)

    local function purgeClouds(item)
        if isA(item, "Clouds") then pcall(destroy, item) end
    end
    for _, item in ipairs(getChildren(terrain)) do purgeClouds(item) end
    trackConnection(terrain.ChildAdded:Connect(purgeClouds))
end

local function isBoothDescendant(obj)
    if not obj or obj == workspace then return false end
    if boothCache[obj] ~= nil then return boothCache[obj] end

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

local function cleanBasePart(item)
    item.Material = MATERIAL_SMOOTH_PLASTIC
    item.CastShadow = false
    item.Reflectance = 0
    if item.MaterialVariant ~= EMPTY_STR then item.MaterialVariant = EMPTY_STR end
end

local function cleanFishingEffects(item)
    if not item or isBoothDescendant(item) or isFishingLine(item) then return end
    if isA(item, "ParticleEmitter") or isA(item, "Highlight") or isA(item, "Light") or isA(item, "Trail") or isA(item, "Fire") or isA(item, "Smoke") or isA(item, "Beam") then
        pcall(destroy, item)
    elseif isA(item, "BasePart") then
        pcall(cleanBasePart, item)
        local n = string_lower(item.Name)
        if string_find(n, "vfx", 1, true) or string_find(n, "effect", 1, true) or string_find(n, "aura", 1, true) or string_find(n, "glow", 1, true) or string_find(n, "lightning", 1, true) or string_find(n, "electricity", 1, true) or string_find(n, "spark", 1, true) or string_find(n, "energy", 1, true) then
            pcall(function() item.Transparency = 1; destroy(item) end)
        end
    end
end

local function isProtected(obj)
    if not obj then return true end
    local name = obj.Name
    if name == "Terrain" or name == "Camera" or isBoothDescendant(obj) or isFishingLine(obj) then return true end
    if string_find(name, "Bobber") or string_find(name, "bobber") then
        cleanFishingEffects(obj)
        return true
    end
    if isPlayerDescendant(obj) then return true end
    return false
end

local function makePotato(obj)
    if not obj or processedCache[obj] or isProtected(obj) then return end
    processedCache[obj] = true

    local name = obj.Name
    if not isBoothDescendant(obj) and SAFE_TO_DESTROY[name] then
        pcall(destroy, obj)
        return
    end

    if isA(obj, "BasePart") then
        pcall(cleanBasePart, obj)
        if isA(obj, "MeshPart") then pcall(function() obj.TextureID = EMPTY_STR end) end
        for _, child in ipairs(getChildren(obj)) do
            if isA(child, "SurfaceAppearance") or isA(child, "Decal") or isA(child, "Texture") or isA(child, "Beam") or isA(child, "ParticleEmitter") or isA(child, "Trail") or isA(child, "Highlight") then
                pcall(destroy, child)
            end
        end
    elseif isA(obj, "Decal") or isA(obj, "Texture") or isA(obj, "SurfaceAppearance") then
        pcall(function() obj.Transparency = 1; destroy(obj) end)
    elseif isA(obj, "SpecialMesh") then
        pcall(function() obj.TextureId = EMPTY_STR end)
    elseif isA(obj, "ParticleEmitter") or isA(obj, "Beam") or isA(obj, "Trail") or isA(obj, "Highlight") or isA(obj, "Light") or isA(obj, "BillboardGui") or isA(obj, "SurfaceGui") then
        pcall(function() obj.Enabled = false end)
    elseif isA(obj, "Sound") then
        pcall(function() obj.Volume = 0 end)
    end
end

local function handleWeatherInstance(inst)
    if not inst then return end
    local name = string_lower(inst.Name)
    if string_find(name, "rain", 1, true) or string_find(name, "fog", 1, true) or string_find(name, "storm", 1, true) or string_find(name, "snow", 1, true) or string_find(name, "blizzard", 1, true) or string_find(name, "weather", 1, true) then
        for _, child in ipairs(getDescendants(inst)) do
            if isA(child, "BasePart") then
                pcall(function() child.Transparency = 1; child.CastShadow = false end)
            elseif isA(child, "ParticleEmitter") or isA(child, "Beam") or isA(child, "PostEffect") then
                pcall(function() child.Enabled = false end)
            end
        end
    end
end

for _, item in ipairs(getChildren(workspace)) do handleWeatherInstance(item) end
trackConnection(workspace.ChildAdded:Connect(handleWeatherInstance))

local function makeModelInvisible(model)
    if not model then return end
    for _, item in ipairs(getDescendants(model)) do
        if isA(item, "BasePart") or isA(item, "Decal") then
            pcall(function()
                item.Transparency = 1
                if isA(item, "BasePart") then
                    item.CastShadow = false
                    if model.Name ~= "FakeIslands" then item.CanCollide = false end
                end
            end)
        elseif isA(item, "ParticleEmitter") or isA(item, "Beam") or isA(item, "Trail") or isA(item, "Highlight") or isA(item, "Light") then
            pcall(function() item.Enabled = false end)
        end
    end
end

local function processCharItem(item)
    if not item or isBoothDescendant(item) then return end
    cleanFishingEffects(item)
    if isA(item, "Accessory") or isA(item, "Shirt") or isA(item, "Pants") or isA(item, "ShirtGraphic") or isA(item, "CharacterMesh") or isA(item, "SurfaceAppearance") or isA(item, "Decal") then
        pcall(destroy, item)
    elseif isA(item, "SpecialMesh") and item.Parent and item.Parent.Name == "Head" then
        pcall(destroy, item)
    elseif isA(item, "BasePart") then
        pcall(cleanBasePart, item)
    end
end

local function optimizeCharacter(char, player)
    if not char or not isA(char, "Model") or processedCache[char] then return end
    processedCache[char] = true

    if player and characterConnections[player] then
        cleanupList(characterConnections[player])
        characterConnections[player] = {}
    end

    for _, item in ipairs(getDescendants(char)) do processCharItem(item) end

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
                pcall(cleanBasePart, item)
            elseif isA(item, "BasePart") then
                pcall(cleanBasePart, item)
            elseif isA(item, "ParticleEmitter") or isA(item, "Beam") or isA(item, "Trail") or isA(item, "Highlight") then
                pcall(function() item.Enabled = false end)
            end
        end
    end
end

local function trackOtherPlayer(p)
    if p == LocalPlayer then return end
    playerConnections[p] = {}
    local caConn = p.CharacterAdded:Connect(function(c) optimizeCharacter(c, p) end)
    table_insert(playerConnections[p], caConn)
    if p.Character then optimizeCharacter(p.Character, p) end
end

trackConnection(LocalPlayer.CharacterAdded:Connect(function(c) optimizeCharacter(c, LocalPlayer) end))
trackConnection(Players.PlayerAdded:Connect(trackOtherPlayer))
trackConnection(Players.PlayerRemoving:Connect(function(p)
    if playerConnections[p] then cleanupList(playerConnections[p]); playerConnections[p] = nil end
    if characterConnections[p] then cleanupList(characterConnections[p]); characterConnections[p] = nil end
end))

local backpack = findFirstChildOfClass(LocalPlayer, "Backpack")
if backpack then
    for _, item in ipairs(getDescendants(backpack)) do cleanFishingEffects(item) end
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
        if obj then pcall(handler, obj) end
        if (clock() - start) >= FRAME_BUDGET_SEC then
            task_wait()
            start = clock()
        end
    end
end

globalEnv._FishItActiveWorker = task_spawn(function()
    local charTimeout = 0
    while not LocalPlayer.Character and charTimeout < 10 do
        task_wait(0.5)
        charTimeout = charTimeout + 0.5
    end
    task_wait(1)

    if LocalPlayer.Character then optimizeCharacter(LocalPlayer.Character, LocalPlayer) end

    for _, p in ipairs(Players:GetPlayers()) do trackOtherPlayer(p) end

    local islandsFolder = findFirstChild(workspace, "Islands")
    if islandsFolder then
        for _, isl in ipairs(getChildren(islandsFolder)) do
            local vfx = findFirstChild(isl, "VFX")
            if vfx then pcall(destroy, vfx) end
        end
    end

    local mapDescendants = getDescendants(workspace)
    for _, item in ipairs(mapDescendants) do
        local n = item.Name
        if n == "Booths" or n == "Booth" or string_find(n, "Booth") or string_find(n, "booth") then
            boothCache[item] = true
            for _, desc in ipairs(getDescendants(item)) do boothCache[desc] = true end
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
            if SAFE_TO_DESTROY[name] then pcall(destroy, obj) end
        end
    end

    local npcFolder = findFirstChild(workspace, "NPC")
    if npcFolder then runAdaptiveBatch(getChildren(npcFolder), cleanNPC) end

    runAdaptiveBatch(mapDescendants, makePotato)

    local sounds = getDescendants(SoundService)
    runAdaptiveBatch(sounds, function(s)
        if isA(s, "Sound") and s.Volume ~= 0 then pcall(function() s.Volume = 0 end) end
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
    if isA(obj, "Clouds") then pcall(destroy, obj); return end
    if isBoothDescendant(obj) then return end
    local name = obj.Name
    if SAFE_TO_DESTROY[name] then pcall(destroy, obj); return end
    local n = string_lower(name)
    if string_find(n, "bobber", 1, true) or string_find(n, "rod", 1, true) then
        cleanFishingEffects(obj)
        for _, d in ipairs(getDescendants(obj)) do cleanFishingEffects(d) end
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
