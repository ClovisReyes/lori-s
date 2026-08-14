local PG = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local dg = Instance.new("ScreenGui")
dg.Name = "FindButtons"
dg.DisplayOrder = 999
dg.ResetOnSpawn = false
dg.Parent = PG

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(0.7, 0, 0.7, 0)
scroll.Position = UDim2.new(0.15, 0, 0.15, 0)
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
    l.TextSize = 12
    l.Font = Enum.Font.Code
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.AutomaticSize = Enum.AutomaticSize.Y
    l.Parent = scroll
end

local y = Color3.fromRGB(255, 255, 0)
local c = Color3.fromRGB(100, 255, 255)
local g = Color3.fromRGB(100, 255, 100)
local w = Color3.fromRGB(255, 255, 255)

for _, popupName in ipairs({"!!! Daily Login", "!!! Update Log"}) do
    local popup = PG:FindFirstChild(popupName)
    if popup then
        addL("=== " .. popupName .. " ===", y)
        for _, desc in ipairs(popup:GetDescendants()) do
            if desc:IsA("GuiButton") then
                local path = desc.Name
                local p = desc.Parent
                while p and p ~= popup do
                    path = p.Name .. "." .. path
                    p = p.Parent
                end
                local conns = 0
                pcall(function()
                    conns = #getconnections(desc.Activated) + #getconnections(desc.MouseButton1Click)
                end)
                addL("  [BTN] " .. path, c)
                addL("    Class: " .. desc.ClassName .. " | Conns: " .. conns, g)
                addL("    Text: " .. tostring(desc:FindFirstChildOfClass("TextLabel") and desc:FindFirstChildOfClass("TextLabel").Text or desc.Text), w)
                addL("    Size: " .. tostring(desc.Size), w)
            end
        end
    else
        addL("=== " .. popupName .. " NOT FOUND ===", Color3.fromRGB(255,100,100))
    end
end

local cb = Instance.new("TextButton")
cb.Size = UDim2.new(0, 80, 0, 30)
cb.Position = UDim2.new(0.85, -40, 0.15, -35)
cb.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
cb.TextColor3 = Color3.new(1,1,1)
cb.Text = "CLOSE"
cb.TextSize = 14
cb.Font = Enum.Font.GothamBold
cb.Parent = dg
cb.MouseButton1Click:Connect(function() dg:Destroy() end)
