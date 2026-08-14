local PG = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local dg = Instance.new("ScreenGui")
dg.Name = "EventCheck"
dg.DisplayOrder = 999
dg.ResetOnSpawn = false
dg.Parent = PG

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(0.7, 0, 0.6, 0)
scroll.Position = UDim2.new(0.15, 0, 0.05, 0)
scroll.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
scroll.BackgroundTransparency = 0.1
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ScrollBarThickness = 6
scroll.Parent = dg

Instance.new("UIListLayout", scroll).Padding = UDim.new(0, 2)

local function addL(t, c)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -8, 0, 16)
    l.Position = UDim2.new(0, 4, 0, 0)
    l.BackgroundTransparency = 1
    l.TextColor3 = c or Color3.new(1,1,1)
    l.Text = t
    l.TextSize = 13
    l.Font = Enum.Font.Code
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.AutomaticSize = Enum.AutomaticSize.Y
    l.Parent = scroll
end

local g = Color3.fromRGB(100,255,100)
local r = Color3.fromRGB(255,100,100)
local y = Color3.fromRGB(255,255,0)
local c = Color3.fromRGB(100,255,255)

local popups = {"!!! Daily Login", "!!! Update Log"}
local events = {
    "Activated", "MouseButton1Click", "MouseButton1Down",
    "MouseButton1Up", "InputBegan", "InputEnded",
    "TouchTap", "TouchLongPress", "MouseEnter"
}

for _, popupName in ipairs(popups) do
    local popup = PG:FindFirstChild(popupName)
    if not popup then continue end
    
    addL("=== " .. popupName .. " ===", y)
    local main = popup:FindFirstChild("Main")
    if not main then addL("  Main NOT FOUND", r) continue end
    local close = main:FindFirstChild("Close")
    if not close then addL("  Close NOT FOUND", r) continue end
    
    addL("Close button found: " .. close.ClassName, g)
    
    for _, ev in ipairs(events) do
        pcall(function()
            local conns = getconnections(close[ev])
            local count = #conns
            if count > 0 then
                addL("  " .. ev .. ": " .. count .. " conns", g)
            else
                addL("  " .. ev .. ": 0", r)
            end
        end)
    end
    
    -- Juga cek parent Main untuk event
    addL("-- Main events --", c)
    for _, ev in ipairs(events) do
        pcall(function()
            local conns = getconnections(main[ev])
            if #conns > 0 then
                addL("  Main." .. ev .. ": " .. #conns .. " conns", g)
            end
        end)
    end
end

-- Tombol TEST: coba fire close
local testBtn = Instance.new("TextButton")
testBtn.Size = UDim2.new(0, 220, 0, 40)
testBtn.Position = UDim2.new(0.5, -110, 0.7, 0)
testBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
testBtn.TextColor3 = Color3.new(1,1,1)
testBtn.Text = "TES FIRE CLOSE"
testBtn.TextSize = 15
testBtn.Font = Enum.Font.GothamBold
testBtn.Parent = dg
testBtn.MouseButton1Click:Connect(function()
    for _, popupName in ipairs(popups) do
        local popup = PG:FindFirstChild(popupName)
        if not popup then continue end
        local main = popup:FindFirstChild("Main")
        if not main then continue end
        local btn = main:FindFirstChild("Close")
        if not btn then continue end
        
        pcall(function() firesignal(btn.Activated) end)
        pcall(function() firesignal(btn.MouseButton1Click) end)
        pcall(function() fireclick(btn) end)
        pcall(function()
            for _,co in pairs(getconnections(btn.InputBegan)) do co:Fire() end
        end)
    end
    testBtn.Text = "FIRED! CEK POPUP"
    testBtn.BackgroundColor3 = Color3.fromRGB(100,100,100)
end)

local cb = Instance.new("TextButton")
cb.Size = UDim2.new(0, 80, 0, 30)
cb.Position = UDim2.new(0.85, -40, 0.05, 0)
cb.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
cb.TextColor3 = Color3.new(1,1,1)
cb.Text = "CLOSE"
cb.TextSize = 14
cb.Font = Enum.Font.GothamBold
cb.Parent = dg
cb.MouseButton1Click:Connect(function() dg:Destroy() end)
