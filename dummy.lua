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

local SIGNALS = {
    "MouseButton1Click",
    "Activated",
    "MouseButton1Down",
    "TouchTap",
    "InputBegan",
    "InputEnded"
}

local function fireButtonEvents(btn)
    if not btn then return end

    for _, sigName in ipairs(SIGNALS) do
        pcall(function()
            if btn[sigName] then
                if typeof(getconnections) == "function" then
                    for _, conn in ipairs(getconnections(btn[sigName])) do
                        conn:Fire()
                    end
                end
                if typeof(firesignal) == "function" then
                    firesignal(btn[sigName])
                end
            end
        end)
    end
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

local function restoreOtherGuis()
    for _, gui in ipairs(PlayerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and not TARGET_NAMES[gui.Name] then
            gui.Enabled = true
        end
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
            
            restoreOtherGuis()
        end)
        disableBlur()
    end
end

for _, desc in ipairs(PlayerGui:GetDescendants()) do
    processUI(desc)
end

PlayerGui.DescendantAdded:Connect(function(desc)
    processUI(desc)
end)

disableBlur()
restoreOtherGuis()
