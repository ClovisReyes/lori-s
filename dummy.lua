if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local PlayerGui = (Players.LocalPlayer or Players.PlayerAdded:Wait()):WaitForChild("PlayerGui")

local TARGET_NAMES = {
    ["!!! Daily Login"] = true,
    ["!!! Update Log"] = true
}

local MAIN_HUD_NAMES = {
    "HUD",
    "MobileUI",
    "TopbarStandard",
    "TopbarCentered",
    "TouchGui"
}

local function restoreMainHUD()
    for _, name in ipairs(MAIN_HUD_NAMES) do
        local hud = PlayerGui:FindFirstChild(name)
        if hud and hud:IsA("ScreenGui") then
            pcall(function()
                hud.Enabled = true
            end)
        end
    end
end

local function fireButtonEvents(btn)
    if not btn then return end

    pcall(function()
        if typeof(getconnections) == "function" then
            for _, conn in ipairs(getconnections(btn.MouseButton1Click)) do
                pcall(function() conn:Fire() end)
            end
            for _, conn in ipairs(getconnections(btn.Activated)) do
                pcall(function() conn:Fire() end)
            end
        end
    end)

    pcall(function()
        if typeof(firesignal) == "function" then
            pcall(function() firesignal(btn.MouseButton1Click) end)
            pcall(function() firesignal(btn.Activated) end)
        end
    end)
end

local function disableBlur()
    local blur = Lighting:FindFirstChild("Blur")
    if blur and blur:IsA("BlurEffect") then
        pcall(function()
            blur.Enabled = false
            blur.Size = 0
        end)
    end
end

local function processUI(gui)
    if TARGET_NAMES[gui.Name] then
        pcall(function()
            local btn = (gui:FindFirstChild("Main") and gui.Main:FindFirstChild("Top") and gui.Main.Top:FindFirstChild("Exit")) 
               or (gui:FindFirstChild("Main") and gui.Main:FindFirstChild("Close"))
               or gui:FindFirstChild("Exit", true) 
               or gui:FindFirstChild("Close", true)

            if btn then
                fireButtonEvents(btn)
            end

            if gui:IsA("ScreenGui") then
                gui.Enabled = false
            end
            gui:Destroy()
        end)

        disableBlur()
        restoreMainHUD()
    end
end

for _, desc in ipairs(PlayerGui:GetDescendants()) do
    processUI(desc)
end

PlayerGui.DescendantAdded:Connect(function(desc)
    processUI(desc)
end)

disableBlur()
restoreMainHUD()
