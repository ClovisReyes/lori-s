if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local PlayerGui = (Players.LocalPlayer or Players.PlayerAdded:Wait()):WaitForChild("PlayerGui")

local TARGET_NAMES = {
    ["!!! Daily Login"] = true,
    ["!!! Update Log"] = true
}

local BUTTON_SIGNALS = {
    "MouseButton1Click",
    "Activated",
    "MouseButton1Down",
    "MouseButton1Up",
    "TouchTap"
}

local function fireButton(btn)
    if not btn then return end

    pcall(function()
        if typeof(getconnections) == "function" then
            for _, sig in ipairs(BUTTON_SIGNALS) do
                if btn[sig] then
                    for _, conn in ipairs(getconnections(btn[sig])) do
                        pcall(function() conn:Fire() end)
                    end
                end
            end
        end
    end)

    pcall(function()
        if typeof(firesignal) == "function" then
            for _, sig in ipairs(BUTTON_SIGNALS) do
                if btn[sig] then
                    pcall(function() firesignal(btn[sig]) end)
                end
            end
        end
    end)
end

local function processUI(gui)
    if TARGET_NAMES[gui.Name] then
        pcall(function()
            local btn = (gui:FindFirstChild("Main") and gui.Main:FindFirstChild("Top") and gui.Main.Top:FindFirstChild("Exit")) 
               or (gui:FindFirstChild("Main") and gui.Main:FindFirstChild("Close"))
               or gui:FindFirstChild("Exit", true) 
               or gui:FindFirstChild("Close", true)

            if btn then
                fireButton(btn)
            end
        end)
    end
end

for _, desc in ipairs(PlayerGui:GetDescendants()) do
    processUI(desc)
end

PlayerGui.DescendantAdded:Connect(function(desc)
    processUI(desc)
end)
