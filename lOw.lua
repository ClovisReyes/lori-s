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
    elseif 
