if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService(Players)
local localPlayer = Players.LocalPlayer
while not localPlayer do
    task.wait(0.1)
    localPlayer = Players.LocalPlayer
end

local ReplicatedStorage = game:GetService(ReplicatedStorage)
local HttpService = game:GetService(HttpService)
local StarterGui = game:GetService(StarterGui)

local function notify(title, text)
    pcall(function()
        StarterGui:SetCore(SendNotification, {
            Title = title,
            Text = text,
            Duration = 6
        })
    end)
end

notify(Scanner, Memulai scan Server Browser...)

local dump = {
    gameInfo = {
        placeId = game.PlaceId,
        jobId = game.JobId,
        gameTime = workspace.DistributedGameTime
    },
    remotesFound = {},
    guiFound = {}
}

local remotes = {}
local function scanContainer(container)
    if not container then return end
    pcall(function()
        for _, obj in ipairs(container:GetDescendants()) do
            local n = obj.Name:lower()
            if obj:IsA(RemoteFunction) or obj:IsA(RemoteEvent) or obj:IsA(BindableFunction) or obj:IsA(BindableEvent) then
                if n:find(server) or n:find(browser) or n:find(teleport) or n:find(list) or n:find(lobby) or n:find(match) or n:find(job) or n:find(queue) then
                    table.insert(remotes, {
                        name = obj.Name,
                        class = obj.ClassName,
                        path = obj:GetFullName()
                    })
                end
            end
        end
    end)
end

scanContainer(ReplicatedStorage)
scanContainer(localPlayer:FindFirstChildOfClass(PlayerGui))
dump.remotesFound = remotes

local guis = {}
local pGui = localPlayer:FindFirstChildOfClass(PlayerGui)
if pGui then
    pcall(function()
        for _, g in ipairs(pGui:GetDescendants()) do
            local n = g.Name:lower()
            if n:find(server) or n:find(browser) or n:find(uptime) or n:find(performance) or n:find(ping) or n:find(player) then
                local txt = (g:IsA(TextLabel) or g:IsA(TextButton) or g:IsA(TextBox)) and g.Text or nil
                table.insert(guis, {
                    name = g.Name,
                    class = g.ClassName,
                    path = g:GetFullName(),
                    text = txt
                })
            end
        end
    end)
end
dump.guiFound = guis

local outputJSON = {}
pcall(function()
    outputJSON = HttpService:JSONEncode(dump)
end)

pcall(function()
    writefile(fishit_serverbrowser_dump.json, outputJSON)
end)

if setclipboard then
    pcall(function()
        setclipboard(outputJSON)
    end)
end

notify(Scan Selesai! ✓, Hasil JSON OTOMATIS TERSALIN ke Clipboard! Tinggal Paste di chat.)

local parentGui
if gethui then
    pcall(function() parentGui = gethui() end)
end
if not parentGui then
    parentGui = localPlayer:WaitForChild(PlayerGui, 5) or localPlayer:FindFirstChildOfClass(PlayerGui)
end

if parentGui:FindFirstChild(ServerScannerGui) then
    parentGui.ServerScannerGui:Destroy()
end

local screenGui = Instance.new(ScreenGui)
screenGui.Name = ServerScannerGui
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 99999
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = parentGui

local frame = Instance.new(Frame)
frame.Size = UDim2.new(0, 280, 0, 220)
frame.Position = UDim2.new(0.5, -140, 0.4, -110)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
frame.BorderSizePixel = 0
frame.Active = true
frame.ZIndex = 10
frame.Parent = screenGui

local corner = Instance.new(UICorner)
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

local stroke = Instance.new(UIStroke)
stroke.Color = Color3.fromRGB(255, 130, 20)
stroke.Thickness = 1.2
stroke.Parent = frame

local title = Instance.new(TextLabel)
title.Size = UDim2.new(1, -40, 0, 26)
title.Position = UDim2.new(0, 10, 0, 4)
title.BackgroundTransparency = 1
title.Text = Scanner Selesai!
title.Font = Enum.Font.GothamBold
title.TextSize = 11
title.TextColor3 = Color3.fromRGB(255, 130, 20)
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 11
title.Parent = frame

local closeBtn = Instance.new(TextButton)
closeBtn.Size = UDim2.new(0, 20, 0, 20)
closeBtn.Position = UDim2.new(1, -26, 0, 6)
closeBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
closeBtn.Text = ✕
closeBtn.Font = Enum.Font.GothamMedium
closeBtn.TextSize = 10
closeBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
closeBtn.BorderSizePixel = 0
closeBtn.ZIndex = 11
closeBtn.Parent = frame
local closeCorner = Instance.new(UICorner)
closeCorner.CornerRadius = UDim.new(0, 4)
closeCorner.Parent = closeBtn
closeBtn.Activated:Connect(function() screenGui:Destroy() end)

local info = Instance.new(TextLabel)
info.Size = UDim2.new(1, -20, 0, 130)
info.Position = UDim2.new(0, 10, 0, 32)
info.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
info.Text = string.format(HASIL SCAN:\n• Remotes: %d ditemukan\n• GUI: %d ditemukan\n\n✓ Hasil sudah OTOMATIS disalin ke Clipboard Anda!\n✓ File: fishit_serverbrowser_dump.json\n\nTinggal Paste (Ctrl+V / Tempel) di chat., #dump.remotesFound, #dump.guiFound)
info.Font = Enum.Font.GothamMedium
info.TextSize = 10
info.TextColor3 = Color3.fromRGB(230, 230, 240)
info.TextWrapped = true
info.ZIndex = 11
info.Parent = frame
local infoCorner = Instance.new(UICorner)
infoCorner.CornerRadius = UDim.new(0, 6)
infoCorner.Parent = info

local copyBtn = Instance.new(TextButton)
copyBtn.Size = UDim2.new(1, -20, 0, 28)
copyBtn.Position = UDim2.new(0, 10, 1, -36)
copyBtn.BackgroundColor3 = Color3.fromRGB(255, 130, 20)
copyBtn.BorderSizePixel = 0
copyBtn.Text = Klik Di Sini Untuk Copy Ulang
copyBtn.Font = Enum.Font.GothamBold
copyBtn.TextSize = 10
copyBtn.TextColor3 = Color3.fromRGB(15, 15, 20)
copyBtn.ZIndex = 11
copyBtn.Parent = frame
local copyCorner = Instance.new(UICorner)
copyCorner.CornerRadius = UDim.new(0, 5)
copyCorner.Parent = copyBtn

copyBtn.Activated:Connect(function()
    if setclipboard then
        setclipboard(outputJSON)
        copyBtn.Text = Tersalin ke Clipboard! ✓
        task.wait(1.5)
        copyBtn.Text = Klik Di Sini Untuk Copy Ulang
    end
end)
