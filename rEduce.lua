-- ===================================================================
-- 🐟 FISH IT! - ULTRA BURIK & POTATO GRAPHICS OPTIMIZER (V4)
-- Khusus game Fish It! - Mode Full Burik Polos Tanpa Tekstur & Langit Hitam
-- ===================================================================

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local LocalPlayer = Players.LocalPlayer

print("🚀 [FISH IT!] Mengaktifkan Mode ULTRA BURIK MAKSIMAL...")

-- ===================================================================
-- 1. BUNGKAM LOG "No HRP" & ERROR VISUAL
-- ===================================================================
if hookfunction then
    local oldPrint; oldPrint = hookfunction(print, newcclosure(function(...)
        local args = {...}
        local str = tostring(args[1])
        if str == "No HRP" then return end
        return oldPrint(...)
    end))

    local oldWarn; oldWarn = hookfunction(warn, newcclosure(function(...)
        local args = {...}
        local str = tostring(args[1])
        if str == "No HRP" then return end
        return oldWarn(...)
    end))
end

-- ===================================================================
-- 2. SAFE HIDE CUACA (FOG & RAIN)
-- ===================================================================
local function neutralizeWeather()
    local fog = workspace:FindFirstChild("Vynozen FogEffect")
    if fog then
        for _, child in ipairs(fog:GetDescendants()) do
            if child:IsA("BasePart") then
                child.Transparency = 1
                child.CastShadow = false
            elseif child:IsA("ParticleEmitter") or child:IsA("Beam") or child:IsA("PostEffect") then
                child.Enabled = false
            end
        end
    end

    local rain = workspace:FindFirstChild("Rain")
    if rain then
        if rain:IsA("BasePart") then rain.Transparency = 1 end
        for _, child in ipairs(rain:GetDescendants()) do
            if child:IsA("ParticleEmitter") or child:IsA("Beam") then
                child.Enabled = false
            elseif child:IsA("BasePart") then
                child.Transparency = 1
            end
        end
    end
end
neutralizeWeather()

-- ===================================================================
-- 3. SEMBUNYIKAN RIG TOKO, DISPLAY, & DEKORASI
-- ===================================================================
local function makeModelInvisible(model)
    if not model then return end
    for _, item in ipairs(model:GetDescendants()) do
        if item:IsA("BasePart") or item:IsA("Decal") then
            item.Transparency = 1
            if item:IsA("BasePart") then
                item.CastShadow = false
                item.CanCollide = false
            end
        elseif item:IsA("ParticleEmitter") or item:IsA("Beam") or item:IsA("Trail") or item:IsA("Highlight") or item:IsA("Light") then
            item.Enabled = false
        end
    end
end

for _, obj in ipairs(workspace:GetChildren()) do
    local name = obj.Name
    if string.find(name, "Rig") or name == "EmoteCratePreviewRig" or name == "FakeRig1" or name == "Props" or name == "Sunken Wreckage" or name == "FakeIslands" then
        makeModelInvisible(obj)
    end
end

local safeToDestroy = {
    "Group Fishing Visuals",
    "CosmeticFolder",
    "Aquariums",
    "!!! Aquariums",
    "Radiant",
    "Divine"
}

for _, name in ipairs(safeToDestroy) do
    local obj = workspace:FindFirstChild(name)
    if obj then pcall(function() obj:Destroy() end) end
end

-- ===================================================================
-- 4. HAPUS SEMUA TEKSTUR, PBR, SURFACEAPPEARANCE & PARTIKEL (FULL BURIK)
-- ===================================================================
local function makePotato(obj)
    if obj:IsA("ParticleEmitter") or obj:IsA("Beam") or obj:IsA("Trail") or obj:IsA("Highlight") then
        obj.Enabled = false
    elseif obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
        obj.Enabled = false
    elseif obj:IsA("SurfaceAppearance") then
        -- Hapus tekstur PBR HD
        pcall(function() obj:Destroy() end)
    elseif obj:IsA("Decal") or obj:IsA("Texture") then
        -- Hapus semua stiker & tekstur permukaan
        obj.Transparency = 1
        pcall(function() obj:Destroy() end)
    elseif obj:IsA("MeshPart") then
        -- Hapus tekstur & ubah warna jadi abu-abu flat seragam
        obj.TextureID = ""
        obj.Material = Enum.Material.SmoothPlastic
        obj.CastShadow = false
        obj.Reflectance = 0
        if obj.Transparency < 1 then
            obj.Color = Color3.fromRGB(160, 160, 160)
        end
    elseif obj:IsA("SpecialMesh") then
        obj.TextureId = ""
    elseif obj:IsA("BasePart") then
        obj.Material = Enum.Material.SmoothPlastic
        obj.CastShadow = false
        obj.Reflectance = 0
        if obj.Transparency < 1 then
            obj.Color = Color3.fromRGB(160, 160, 160)
        end
    end
end

-- Terapkan ke seluruh objek di Workspace
for _, obj in ipairs(workspace:GetDescendants()) do
    makePotato(obj)
end

-- Listener untuk objek baru
workspace.DescendantAdded:Connect(function(obj)
    task.wait()
    makePotato(obj)
end)

-- ===================================================================
-- 5. LANGIT HITAM PEKAT & AIR BIRU POLOS JERNIH
-- ===================================================================
-- Hapus semua efek langit, atmosfer, dan post processing
for _, item in ipairs(Lighting:GetChildren()) do
    if item:IsA("PostEffect") or item:IsA("Atmosphere") or item:IsA("Sky") or item:IsA("Clouds") then
        pcall(function() item:Destroy() end)
    end
end

-- Skybox Hitam Pekat Asli (Pure Solid Black Void 100%)
local blackAsset = "rbxassetid://144410044"
local blackSky = Instance.new("Sky")
blackSky.Name = "PotatoBlackSky"
blackSky.SkyboxBk = blackAsset
blackSky.SkyboxDn = blackAsset
blackSky.SkyboxFt = blackAsset
blackSky.SkyboxLf = blackAsset
blackSky.SkyboxRt = blackAsset
blackSky.SkyboxUp = blackAsset
blackSky.CelestialBodiesShown = false
blackSky.Parent = Lighting

-- Pencahayaan Flat & Kabut Hitam Pekat Void
Lighting.GlobalShadows = false
Lighting.FogColor = Color3.fromRGB(0, 0, 0)
Lighting.FogStart = 300
Lighting.FogEnd = 1200
Lighting.ClockTime = 0
Lighting.Brightness = 0
Lighting.EnvironmentDiffuseScale = 0
Lighting.EnvironmentSpecularScale = 0
Lighting.ExposureCompensation = 0
Lighting.Ambient = Color3.fromRGB(150, 150, 150)
Lighting.OutdoorAmbient = Color3.fromRGB(0, 0, 0)

-- Optimasi Terrain & Air (Biru Jernih, 0 Gelombang, 0 Beban GPU)
if workspace.Terrain then
    workspace.Terrain.WaterWaveSize = 0
    workspace.Terrain.WaterWaveSpeed = 0
    workspace.Terrain.WaterReflectance = 0
    workspace.Terrain.WaterTransparency = 0.9
    workspace.Terrain.WaterColor = Color3.fromRGB(65, 165, 230)
    if sethiddenproperty then
        pcall(function() sethiddenproperty(workspace.Terrain, "Decoration", false) end)
    end
end

-- Turunkan Quality Level Roblox Engine ke level 1
pcall(function()
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
end)

-- ===================================================================
-- 6. SEMBUNYIKAN PLAYER LAIN & KARAKTER KITA (GHOST MODE - PERSISTEN RESPAWN)
-- ===================================================================
local function cleanItem(item, isLocal)
    if item:IsA("Accessory") or item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") or item:IsA("CharacterMesh") or item:IsA("SurfaceAppearance") then
        pcall(function() item:Destroy() end)
    elseif item:IsA("MeshPart") then
        item.TextureID = ""
        item.Transparency = 1
        item.CastShadow = false
    elseif item:IsA("BasePart") or item:IsA("Decal") then
        item.Transparency = 1
        if item:IsA("BasePart") then
            item.CastShadow = false
            item.Material = Enum.Material.SmoothPlastic
            if not isLocal then item.CanCollide = false end
        end
    elseif item:IsA("ParticleEmitter") or item:IsA("Beam") or item:IsA("Trail") then
        item.Enabled = false
    end
end

local function cleanCharacter(char, isLocal)
    if not char then return end
    
    -- Bersihkan item yang sudah ada
    for _, item in ipairs(char:GetDescendants()) do
        cleanItem(item, isLocal)
    end

    -- Tangani baju/topi/rambut yang baru dimuat terlambat oleh server
    char.DescendantAdded:Connect(function(item)
        task.wait()
        cleanItem(item, isLocal)
    end)

    -- Atur Humanoid
    task.spawn(function()
        local hum = char:WaitForChild("Humanoid", 5)
        if hum and not isLocal then
            hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
            hum.NameDisplayDistance = 0
            hum.HealthDisplayDistance = 0
            local anim = hum:FindFirstChildOfClass("Animator")
            if anim then anim:Destroy() end
        end
    end)
end

-- Listener Pemain Lain
local function setupOtherPlayer(player)
    if player == LocalPlayer then return end
    if player.Character then cleanCharacter(player.Character, false) end
    player.CharacterAdded:Connect(function(c)
        cleanCharacter(c, false)
    end)
end

for _, p in ipairs(Players:GetPlayers()) do setupOtherPlayer(p) end
Players.PlayerAdded:Connect(setupOtherPlayer)

-- ===================================================================
-- 7. HILANGKAN JORAN / UMPAN / LENTERA (TRANSPARENCY 1)
-- ===================================================================
local function cleanRod(char)
    if not char then return end
    local function hideTool(child)
        local n = child.Name
        if string.find(n, "FISHING") or string.find(n, "BAIT") or string.find(n, "LANTERN") or string.find(n, "VIEW_MODEL") then
            if child:IsA("MeshPart") then child.TextureID = "" end
            if child:IsA("BasePart") then
                child.Transparency = 1
                child.CastShadow = false
            end
            for _, item in ipairs(child:GetDescendants()) do
                if item:IsA("MeshPart") then item.TextureID = "" end
                if item:IsA("BasePart") or item:IsA("Decal") then
                    item.Transparency = 1
                    item.CastShadow = false
                elseif item:IsA("Beam") or item:IsA("ParticleEmitter") or item:IsA("Light") then
                    item.Enabled = false
                end
            end
        end
    end
    for _, c in ipairs(char:GetChildren()) do hideTool(c) end
    char.ChildAdded:Connect(function(c) task.wait(); hideTool(c) end)
end

-- Listener Karakter Kita Sendiri (Otomatis jalan setiap kali respawn)
local function onLocalCharacterSpawn(c)
    cleanCharacter(c, true)
    cleanRod(c)
end

if LocalPlayer.Character then onLocalCharacterSpawn(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(onLocalCharacterSpawn)

-- Listener Tambahan jika karakter di-parent ke folder workspace.Characters
local charFolder = workspace:FindFirstChild("Characters")
if charFolder then
    charFolder.ChildAdded:Connect(function(c)
        task.wait(0.05)
        if c.Name == LocalPlayer.Name then
            onLocalCharacterSpawn(c)
        else
            cleanCharacter(c, false)
        end
    end)
end

-- ===================================================================
-- 8. BERSIHKAN BANNER PROMOSI, POPUP TOKO, & 3D FLOATING TEXT
-- ===================================================================
-- A. Bersihkan 3D Floating Text & Billboard Iklan di Workspace
for _, gui in ipairs(workspace:GetDescendants()) do
    if gui:IsA("BillboardGui") or gui:IsA("SurfaceGui") then
        gui.Enabled = false
    end
end
workspace.DescendantAdded:Connect(function(gui)
    if gui:IsA("BillboardGui") or gui:IsA("SurfaceGui") then
        task.wait()
        gui.Enabled = false
    end
end)

-- B. Bersihkan ScreenGui Promosi & Popup di PlayerGui
local pgui = LocalPlayer:WaitForChild("PlayerGui", 5)
if pgui then
    local promoGuis = {
        "!!! Click Effect", "Border", "AreaHighlight",
        "Exclusive Store", "!!! Starter Pack", "TokenShardsAd",
        "BattlepassShop", "EventLimitedShop", "!!! BUY SPINS",
        "Spin Wheel", "LootboxDisplay", "EmoteLootbox",
        "!!! Gifting", "BlackMarket", "GalaxyEvent",
        "PurchaseScreenBlackout", "EggIndicator"
    }
    
    for _, gName in ipairs(promoGuis) do
        local g = pgui:FindFirstChild(gName)
        if g then
            if g:IsA("ScreenGui") or g:IsA("BillboardGui") then
                g.Enabled = false
            else
                pcall(function() g:Destroy() end)
            end
        end
    end

    -- Sembunyikan frame banner iklan di dalam HUD (seperti Lightning Pack)
    local hud = pgui:FindFirstChild("HUD")
    if hud then
        for _, elem in ipairs(hud:GetDescendants()) do
            local elemName = string.lower(elem.Name)
            if string.find(elemName, "banner") or string.find(elemName, "pack") or string.find(elemName, "offer") or string.find(elemName, "promo") or string.find(elemName, "bundle") then
                if elem:IsA("GuiObject") then
                    elem.Visible = false
                end
            end
        end
    end
end

-- ===================================================================
-- 9. OPTIMASI 88 NPC DI MAP (HEMAT CPU & TETAP BISA BELANJA/INTERAKSI)
-- ===================================================================
local function cleanNPC(npc)
    if not npc or not npc:IsA("Model") then return end
    task.spawn(function()
        local hum = npc:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
            hum.NameDisplayDistance = 0
            hum.HealthDisplayDistance = 0
            local anim = hum:FindFirstChildOfClass("Animator")
            if anim then anim:Destroy() end -- Hentikan komputasi animasi CPU
        end

        for _, item in ipairs(npc:GetDescendants()) do
            -- Pertahankan ProximityPrompt agar interaksi tetap berfungsi 100%
            if not item:IsA("ProximityPrompt") then
                if item:IsA("Accessory") or item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") or item:IsA("CharacterMesh") then
                    item:Destroy()
                elseif item:IsA("MeshPart") then
                    item.TextureID = ""
                    item.Material = Enum.Material.SmoothPlastic
                    item.CastShadow = false
                    item.Color = Color3.fromRGB(160, 160, 160)
                elseif item:IsA("BasePart") then
                    item.Material = Enum.Material.SmoothPlastic
                    item.CastShadow = false
                    item.Color = Color3.fromRGB(160, 160, 160)
                elseif item:IsA("ParticleEmitter") or item:IsA("Beam") or item:IsA("Trail") or item:IsA("Highlight") then
                    item.Enabled = false
                end
            end
        end
    end)
end

local npcFolder = workspace:FindFirstChild("NPC")
if npcFolder then
    for _, npc in ipairs(npcFolder:GetChildren()) do
        cleanNPC(npc)
    end
    npcFolder.ChildAdded:Connect(function(npc)
        task.wait(0.1)
        cleanNPC(npc)
    end)
end

-- ===================================================================
-- 10. OPTIMASI KAPAL & KENDARAAN (VEHICLES)
-- ===================================================================
local function cleanVehicle(veh)
    if not veh then return end
    for _, item in ipairs(veh:GetDescendants()) do
        if item:IsA("ParticleEmitter") or item:IsA("Beam") or item:IsA("Trail") then
            item.Enabled = false
        elseif item:IsA("Sound") then
            item.Volume = 0
        elseif item:IsA("MeshPart") then
            item.TextureID = ""
            item.Material = Enum.Material.SmoothPlastic
            item.CastShadow = false
        elseif item:IsA("BasePart") then
            item.Material = Enum.Material.SmoothPlastic
            item.CastShadow = false
        end
    end
end

local vehFolder = workspace:FindFirstChild("Vehicles")
if vehFolder then
    for _, v in ipairs(vehFolder:GetChildren()) do cleanVehicle(v) end
    vehFolder.ChildAdded:Connect(function(v) task.wait(); cleanVehicle(v) end)
end

local boatStorage = workspace:FindFirstChild("Race Boat Storage")
if boatStorage then
    for _, b in ipairs(boatStorage:GetChildren()) do cleanVehicle(b) end
    boatStorage.ChildAdded:Connect(function(b) task.wait(); cleanVehicle(b) end)
end

-- ===================================================================
-- 11. OPTIMASI EFEK & AURA PET (PELIHARAAN)
-- ===================================================================
local function cleanPetAuras()
    local petSpawns = workspace:FindFirstChild("!!! PET SPAWN LOCATIONS")
    if petSpawns then
        for _, item in ipairs(petSpawns:GetDescendants()) do
            if item:IsA("ParticleEmitter") or item:IsA("Beam") or item:IsA("Trail") or item:IsA("Highlight") then
                item.Enabled = false
            end
        end
    end
end
cleanPetAuras()

-- ===================================================================
-- 12. MATIKAN SUARA AMBIENT
-- ===================================================================
for _, s in ipairs(SoundService:GetDescendants()) do
    if s:IsA("Sound") then s.Volume = 0 end
end
for _, s in ipairs(workspace:GetDescendants()) do
    if s:IsA("Sound") then s.Volume = 0 end
end

print("=======================================================")
print("✅ [FISH IT!] MODE ULTRA BURIK & OPTIMASI TOTAL AKTIF!")
print("=======================================================")
