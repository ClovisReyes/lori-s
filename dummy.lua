if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local PlayerGui = (Players.LocalPlayer or Players.PlayerAdded:Wait()):WaitForChild("PlayerGui")

local TARGET_NAMES = {
    ["!!! Daily Login"] = true,
    ["!!! Update Log"] = true
}

local function createMockInput()
    return {
        UserInputType = Enum.UserInputType.MouseButton1,
        UserInputState = Enum.UserInputState.End,
        Position = Vector3.new(0, 0, 0),
        Delta = Vector3.new(0, 0, 0)
    }
end

local function safeClick(btn)
    if not btn then return end

    -- Jeda sangat singkat untuk sinkronisasi UI
    task.wait(0.1)

    local fired = false
    local mockInput = createMockInput()
    local signals = {"Activated", "MouseButton1Click", "MouseButton1Up", "InputBegan"}

    -- Invisible Click: Mengeksekusi fungsi callback internal tombol dengan parameter InputObject tiruan
    pcall(function()
        if typeof(getconnections) == "function" then
            for _, sig in ipairs(signals) do
                if btn[sig] then
                    local conns = getconnections(btn[sig])
                    if #conns > 0 then
                        for _, conn in ipairs(conns) do
                            pcall(function()
                                -- Panggil callback dengan mengirimkan mockInput agar tidak error nil
                                if type(conn.Function) == "function" then
                                    conn.Function(mockInput)
                                elseif type(conn.Fire) == "function" then
                                    conn:Fire(mockInput)
                                end
                            end)
                        end
                        fired = true
                    end
                end
            end
        end
    end)

    -- Fallback Firesignal jika getconnections tidak menemukan fungsi
    if not fired then
        pcall(function()
            if typeof(firesignal) == "function" then
                if btn.Activated then
                    firesignal(btn.Activated, mockInput)
                elseif btn.MouseButton1Click then
                    firesignal(btn.MouseButton1Click, mockInput)
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
