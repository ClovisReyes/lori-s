-- DEBUG SCRIPT: Menampilkan properti HUD langsung di layar game
-- Jalankan ini SAAT popup Daily Login / Update Log MASIH TERBUKA (jangan close manual)

local Players = game:GetService("Players")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

-- Buat GUI debug di layar
local debugGui = Instance.new("ScreenGui")
debugGui.Name = "DebugHUD"
debugGui.ResetOnSpawn = false
debugGui.DisplayOrder = 999
debugGui.Parent = PlayerGui

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(0.5, 0, 0.8, 0)
scroll.Position = UDim2.new(0.25, 0, 0.1, 0)
scroll.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
scroll.BackgroundTransparency = 0.1
scroll.BorderSizePixel = 2
scroll.BorderColor3 = Color3.fromRGB(255, 255, 0)
scroll.ScrollBarThickness = 8
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = debugGui

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 2)
layout.Parent = scroll

local padding = Instance.new("UIPadding")
padding.PaddingAll = UDim.new(0, 8)
padding.Parent = scroll

local function addLine(text, color)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 18)
    label.BackgroundTransparency = 1
    label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
    label.Text = text
    label.TextSize = 13
    label.Font = Enum.Font.Code
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextWrapped = true
    label.AutomaticSize = Enum.AutomaticSize.Y
    label.Parent = scroll
end

local yellow = Color3.fromRGB(255, 255, 0)
local green = Color3.fromRGB(100, 255, 100)
local red = Color3.fromRGB(255, 100, 100)
local white = Color3.fromRGB(255, 255, 255)
local cyan = Color3.fromRGB(100, 255, 255)

addLine("=== DEBUG HUD PROPERTIES ===", yellow)
addLine("Jalankan SAAT popup masih terbuka", red)
addLine("", white)

local targets = {"Backpack", "Events", "Compass"}

for _, name in ipairs(targets) do
    local gui = PlayerGui:FindFirstChild(name)
    if gui then
        addLine(">>> " .. name .. " <<<", yellow)
        addLine("  ClassName: " .. gui.ClassName, green)
        
        if gui:IsA("ScreenGui") then
            addLine("  Enabled: " .. tostring(gui.Enabled), gui.Enabled and green or red)
        end
        if gui:IsA("GuiObject") then
            addLine("  Visible: " .. tostring(gui.Visible), gui.Visible and green or red)
            addLine("  Position: " .. tostring(gui.Position), white)
            addLine("  Size: " .. tostring(gui.Size), white)
        end
        if gui:IsA("CanvasGroup") then
            addLine("  GroupTransparency: " .. tostring(gui.GroupTransparency), gui.GroupTransparency > 0 and red or green)
        end
        
        for _, child in ipairs(gui:GetChildren()) do
            if child:IsA("GuiObject") or child:IsA("CanvasGroup") then
                addLine("  [Child] " .. child.Name .. " (" .. child.ClassName .. ")", cyan)
                addLine("    Visible: " .. tostring(child.Visible), child.Visible and green or red)
                addLine("    Position: " .. tostring(child.Position), white)
                addLine("    Size: " .. tostring(child.Size), white)
                if child:IsA("CanvasGroup") then
                    addLine("    GroupTransparency: " .. tostring(child.GroupTransparency), child.GroupTransparency > 0 and red or green)
                end
            end
        end
        addLine("", white)
    else
        addLine(">>> " .. name .. " = TIDAK DITEMUKAN <<<", red)
        addLine("", white)
    end
end

-- Tombol close debug
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 80, 0, 30)
closeBtn.Position = UDim2.new(0.75, -40, 0.1, -35)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Text = "CLOSE"
closeBtn.TextSize = 14
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = debugGui
closeBtn.MouseButton1Click:Connect(function()
    debugGui:Destroy()
end)
