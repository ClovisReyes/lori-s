if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local VirtualInputManager = pcall(function() return game:GetService("VirtualInputManager") end) and game:GetService("VirtualInputManager")
local PlayerGui = (Players.LocalPlayer or Players.PlayerAdded:Wait()):WaitForChild("PlayerGui")

local TARGET_NAMES = {
    ["!!! Daily Login"] = true,
    ["!!! Update Log"] = true
}

local BUTTON_SIGNALS = {
    "Activated",
    "MouseButton1Click",
    "MouseButton1Down",
    "MouseButton1Up",
    "TouchTap",
    "InputBegan",
    "InputEnded"
}

local function fireButton(btn)
    if not btn or not btn:IsA("GuiObject") then return end

    -- 1. Trigger via getconnections (Fire & Function)
    pcall(function()
        if typeof(getconnections) == "function" then
            for _, sig in ipairs(BUTTON_SIGNALS) do
                if btn[sig] then
                    for _, conn in ipairs(getconnections(btn[sig])) do
                        pcall(function()
                            if type(conn.Fire) == "function" then
                                conn:Fire()
                            end
                            if type(conn.Function) == "function" then
                                conn.Function()
                            end
                        end)
                    end
                end
            end
        end
    end)

    -- 2. Trigger via firesignal jika didukung executor
    pcall(function()
        if typeof(firesignal) == "function" then
            for _, sig in ipairs(BUTTON_SIGNALS) do
                if btn[sig] then
                    pcall(function() firesignal(btn[sig]) end)
                end
            end
        end
    end)

    -- 3. Simulasi Klik / Touch fisik murni menggunakan VirtualInputManager
    pcall(function()
        if VirtualInputManager and btn.AbsoluteSize.X > 0 and btn.AbsoluteSize.Y > 0 then
            local inset = GuiService:GetGuiInset()
            local pos = btn.AbsolutePosition + (btn.AbsoluteSize / 2) + inset
            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
            VirtualInputManager:SendTouchEvent(1, 0, pos.X, pos.Y)
            VirtualInputManager:SendTouchEvent(1, 1, pos.X, pos.Y)
        end
    end)
end

local function findCloseButton(gui)
    -- Path presisi sesuai spesifikasi game
    if gui.Name == "!!! Daily Login" then
        if gui:FindFirstChild("Main") and gui.Main:FindFirstChild("Close") then
            return gui.Main.Close
        end
    elseif gui.Name == "!!! Update Log" then
        if gui:FindFirstChild("Main") and gui.Main:FindFirstChild("Top") and gui.Main.Top:FindFirstChild("Exit") then
            return gui.Main.Top.Exit
        end
    end

    -- Fallback pencarian alternatif jika struktur UI berubah
    local candidateNames = {"Exit", "Close", "CloseButton", "ExitButton", "X", "CloseBtn"}
    for _, name in ipairs(candidateNames) do
        local found = gui:FindFirstChild(name, true)
        if found then
            if found:IsA("GuiButton") then
                return found
            else
                local subBtn = found:FindFirstChildWhichIsA("GuiButton", true)
                if subBtn then return subBtn end
                return found
            end
        end
    end

    for _, desc in ipairs(gui:GetDescendants()) do
        if desc:IsA("GuiButton") then
            local lowerName = desc.Name:lower()
            if lowerName:find("close") or lowerName:find("exit") or lowerName == "x" then
                return desc
            end
        end
    end

    return nil
end

local function processUI(gui)
    if TARGET_NAMES[gui.Name] then
        pcall(function()
            local btn = findCloseButton(gui)
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
