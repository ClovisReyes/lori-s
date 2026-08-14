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

local function fireButtonEvents(btn)
    if not btn then return end

    pcall(function()
        if typeof(getconnections) == "function" then
            for _, conn in ipairs(getconnections(btn.MouseButton1Click)) do
                conn:Fire()
            end
            for _, conn in ipairs(getconnections(btn.Activated)) do
                conn:Fire()
            end
            for _, conn in ipairs(getconnections(btn.MouseButton1Down)) do
                conn:Fire()
            end
        end
    end)

    pcall(function()
        if typeof(firesignal) == "function" then
            firesignal(btn.MouseButton1Click)
            firesignal(btn.Activated)
            firesignal(btn.MouseButton1Down)
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
            local btn = nil
            if gui.Name == "!!! Update Log" then
                btn = (gui:FindFirstChild("Main") and gui.Main:FindFirstChild("Top") and gui.Main.Top:FindFirstChild("Exit")) 
                   or gui:FindFirstChild("Exit", true)
            elseif gui.Name == "!!! Daily Login" then
                btn = (gui:FindFirstChild("Main") and gui.Main:FindFirstChild("Close")) 
                   or gui:FindFirstChild("Close", true)
            end

            if btn then
                fireButtonEvents(btn)
            end
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
