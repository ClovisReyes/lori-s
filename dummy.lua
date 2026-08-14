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

local function getActualButton(obj)
    if not obj then return nil end
    if obj:IsA("GuiButton") then
        return obj
    end
    local childBtn = obj:FindFirstChildWhichIsA("GuiButton", true)
    if childBtn then
        return childBtn
    end
    return obj
end

local function findCloseButton(gui)
    local targetBtn = nil

    if gui.Name == "!!! Daily Login" then
        if gui:FindFirstChild("Main") then
            targetBtn = gui.Main:FindFirstChild("Close") or gui.Main:FindFirstChild("Exit")
        end
    elseif gui.Name == "!!! Update Log" then
        if gui:FindFirstChild("Main") then
            local top = gui.Main:FindFirstChild("Top")
            if top then
                targetBtn = top:FindFirstChild("Exit") or top:FindFirstChild("Close")
            else
                targetBtn = gui.Main:FindFirstChild("Exit") or gui.Main:FindFirstChild("Close")
            end
        end
    end

    if not targetBtn then
        targetBtn = gui:FindFirstChild("Close", true) or gui:FindFirstChild("Exit", true)
    end

    return getActualButton(targetBtn)
end

local function safeClick(btn, gui)
    task.wait(0.1)

    local mockInput = createMockInput()
    local signals = {"Activated", "MouseButton1Click", "TouchTap", "InputBegan"}

    -- 1. Jalankan koneksi event tombol secara aman jika ditemukan
    if btn then
        pcall(function()
            if typeof(getconnections) == "function" then
                for _, sig in ipairs(signals) do
                    if btn[sig] then
                        for _, conn in ipairs(getconnections(btn[sig])) do
                            pcall(function()
                                if type(conn.Function) == "function" then
                                    conn.Function(mockInput)
                                elseif type(conn.Fire) == "function" then
                                    conn:Fire(mockInput)
                                end
                            end)
                        end
                    end
                end
            end
        end)

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

    -- 2. Memastikan GUI tertutup (toggle Visible/Enabled) tanpa me-destroy UI
    task.wait(0.2)
    pcall(function()
        if gui and gui.Parent then
            if gui:IsA("ScreenGui") and gui.Enabled then
                gui.Enabled = false
            elseif gui:IsA("GuiObject") and gui.Visible then
                gui.Visible = false
            end
        end
    end)
end

local function processUI(gui)
    if TARGET_NAMES[gui.Name] then
        task.spawn(function()
            local btn = findCloseButton(gui)
            safeClick(btn, gui)
        end)
    end
end

for _, desc in ipairs(PlayerGui:GetDescendants()) do
    processUI(desc)
end

PlayerGui.DescendantAdded:Connect(function(desc)
    processUI(desc)
end)
