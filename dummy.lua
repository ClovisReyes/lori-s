if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local PlayerGui = (Players.LocalPlayer or Players.PlayerAdded:Wait()):WaitForChild("PlayerGui")

local TARGET_NAMES = {
    ["!!! Daily Login"] = true,
    ["!!! Update Log"] = true
}

local function safeClick(btn)
    if not btn then return end

    -- Jeda 0.1-0.2 detik agar tidak terdeteksi sebagai instant-bot oleh Anti-Cheat (BAC)
    task.wait(0.15)

    local fired = false

    -- 1. Utamakan getconnections hanya pada event Activated atau MouseButton1Click
    pcall(function()
        if typeof(getconnections) == "function" then
            if btn:IsA("GuiButton") and btn.Activated then
                local conns = getconnections(btn.Activated)
                if #conns > 0 then
                    for _, conn in ipairs(conns) do
                        pcall(function() conn:Fire() end)
                    end
                    fired = true
                end
            end

            if not fired and btn.MouseButton1Click then
                local conns = getconnections(btn.MouseButton1Click)
                if #conns > 0 then
                    for _, conn in ipairs(conns) do
                        pcall(function() conn:Fire() end)
                    end
                    fired = true
                end
            end
        end
    end)

    -- 2. Fallback firesignal murni (hanya 1 signal, bukan spam)
    if not fired then
        pcall(function()
            if typeof(firesignal) == "function" then
                if btn.Activated then
                    firesignal(btn.Activated)
                elseif btn.MouseButton1Click then
                    firesignal(btn.MouseButton1Click)
                end
            end
        end)
    end
end

local function findCloseButton(gui)
    if gui.Name == "!!! Daily Login" then
        if gui:FindFirstChild("Main") and gui.Main:FindFirstChild("Close") then
            return gui.Main.Close
        end
    elseif gui.Name == "!!! Update Log" then
        if gui:FindFirstChild("Main") and gui.Main:FindFirstChild("Top") and gui.Main.Top:FindFirstChild("Exit") then
            return gui.Main.Top.Exit
        end
    end

    return gui:FindFirstChild("Close", true) or gui:FindFirstChild("Exit", true)
end

local function processUI(gui)
    if TARGET_NAMES[gui.Name] then
        task.spawn(function()
            local btn = findCloseButton(gui)
            if btn then
                safeClick(btn)
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
