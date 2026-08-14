local PG = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local dg = Instance.new("ScreenGui")
dg.Name = "QuickDebug"
dg.DisplayOrder = 999
dg.ResetOnSpawn = false
dg.Parent = PG

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(0.55, 0, 0.35, 0)
scroll.Position = UDim2.new(0.22, 0, 0.05, 0)
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

local targets = {{"Backpack","Display"},{"Events","Frame"},{"Compass","Inside"}}

for _, p in ipairs(targets) do
    local parent = PG:FindFirstChild(p[1])
    if parent then
        local child = parent:FindFirstChild(p[2])
        if child then
            addL(p[1].."."..p[2], Color3.fromRGB(255,255,0))
            addL("  AnchorPoint: "..tostring(child.AnchorPoint))
            addL("  Position: "..tostring(child.Position))
            addL("  Size: "..tostring(child.Size))
            addL("  Visible: "..tostring(child.Visible))
            if child:IsA("CanvasGroup") then
                addL("  GroupTrans: "..tostring(child.GroupTransparency), Color3.fromRGB(255,100,100))
            end
        else
            addL(p[1].."."..p[2].." NOT FOUND", Color3.fromRGB(255,100,100))
        end
    end
end

local testBtn = Instance.new("TextButton")
testBtn.Size = UDim2.new(0, 220, 0, 40)
testBtn.Position = UDim2.new(0.5, -110, 0.45, 0)
testBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
testBtn.TextColor3 = Color3.new(1,1,1)
testBtn.Text = "TEST: PAKSA TAMPILKAN"
testBtn.TextSize = 15
testBtn.Font = Enum.Font.GothamBold
testBtn.Parent = dg
testBtn.MouseButton1Click:Connect(function()
    for _, p in ipairs(targets) do
        local parent = PG:FindFirstChild(p[1])
        if parent then
            local child = parent:FindFirstChild(p[2])
            if child then
                pcall(function()
                    child.Visible = true
                    child.Position = UDim2.new(0.3, 0, 0.3, 0)
                end)
            end
        end
    end
    testBtn.Text = "DONE! CEK LAYAR"
    testBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
end)

local cb = Instance.new("TextButton")
cb.Size = UDim2.new(0, 80, 0, 30)
cb.Position = UDim2.new(0.78, 0, 0.05, -5)
cb.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
cb.TextColor3 = Color3.new(1,1,1)
cb.Text = "CLOSE"
cb.TextSize = 14
cb.Font = Enum.Font.GothamBold
cb.Parent = dg
cb.MouseButton1Click:Connect(function() dg:Destroy() end)
