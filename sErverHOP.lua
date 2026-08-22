if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService(Players)
local localPlayer = Players.LocalPlayer
while not localPlayer do
    task.wait(0.1)
    localPlayer = Players.LocalPlayer
end

local HttpService = game:GetService(HttpService)
local ReplicatedStorage = game:GetService(ReplicatedStorage)
local TweenService = game:GetService(TweenService)
local UserInputService = game:GetService(UserInputService)

local parentGui
if gethui then
    local success, hui = pcall(gethui)
    if success and hui then parentGui = hui end
end
if not parentGui then
    local successCore, coreGui = pcall(function() return game:GetService(CoreGui) end)
    if successCore and coreGui then
        parentGui = coreGui
    else
        parentGui = localPlayer:WaitForChild(PlayerGui, 5) or localPlayer:FindFirstChildOfClass(PlayerGui)
    end
end

if parentGui:FindFirstChild(ScannerHopGui) then
    parentGui.ScannerHopGui:Destroy()
end

local screenGui = Instance.new(ScreenGui)
screenGui.Name = ScannerHopGui
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 9999
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = parentGui

local function create(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do obj[k] = v end
    if parent then obj.Parent = parent end
    return obj
end

local T = {
    Bg = Color3.fromRGB(13, 13, 16),
    Card = Color3.fromRGB(20, 20, 25),
    CardHover = Color3.fromRGB(28, 28, 36),
    Border = Color3.fromRGB(38, 38, 48),
    Accent = Color3.fromRGB(255, 130, 20),
    AccentLight = Color3.fromRGB(255, 165, 55),
    Text = Color3.fromRGB(245, 245, 250),
    Muted = Color3.fromRGB(140, 140, 150),
    Success = Color3.fromRGB(75, 220, 120),
    Error = Color3.fromRGB(255, 80, 80)
}

local main = create(Frame, {
    Name = MainFrame,
    Size = UDim2.new(0, 280, 0, 240),
    Position = UDim2.new(0.5, -140, 0.35, -120),
    BackgroundColor3 = T.Bg,
    BorderSizePixel = 0,
    Active = true,
    ZIndex = 1
}, screenGui)
create(UICorner, { CornerRadius = UDim.new(0, 10) }, main)
create(UIStroke, { Color = T.Accent, Thickness = 1.2, Transparency = 0.25 }, main)
create(UIPadding, { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10) }, main)
create(UIListLayout, { FillDirection = Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }, main)

local header = create(Frame, { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, LayoutOrder = 1, ZIndex = 2 }, main)

create(TextLabel, {
    Size = UDim2.new(1, -30, 1, 0),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundTransparency = 1,
    Text = Fish It! Server Scanner,
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    TextColor3 = T.Text,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 3
}, header)

local closeBtn = create(TextButton, { Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -20, 0, 1), BackgroundColor3 = T.Card, Text = ✕, Font = Enum.Font.GothamMedium, TextSize = 10, TextColor3 = T.Muted, BorderSizePixel = 0, ZIndex = 3 }, header)
create(UICorner, { CornerRadius = UDim.new(0, 5) }, closeBtn)
closeBtn.Activated:Connect(function() screenGui:Destroy() end)

local scroll = create(ScrollingFrame, {
    Size = UDim2.new(1, 0, 0, 110),
    BackgroundColor3 = T.Card,
    BorderSizePixel = 0,
    CanvasSize = UDim2.new(0, 0, 0, 500),
    ScrollBarThickness = 3,
    LayoutOrder = 2,
    ZIndex = 2
}, main)
create(UICorner, { CornerRadius = UDim.new(0, 6) }, scroll)
create(UIPadding, { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6) }, scroll)

local logText = create(TextLabel, {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Text = Klik tombol SCAN di bawah untuk mulai memindai Server Browser...,
    Font = Enum.Font.GothamMedium,
    TextSize = 9,
    TextColor3 = T.Muted,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    TextWrapped = true,
    ZIndex = 3
}, scroll)

local scanBtn = create(TextButton, {
    Size = UDim2.new(1, 0, 0, 28),
    BackgroundColor3 = T.Accent,
    BorderSizePixel = 0,
    Text = SCAN SERVER BROWSER,
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    TextColor3 = Color3.fromRGB(15, 15, 18),
    LayoutOrder = 3,
    ZIndex = 2
}, main)
create(UICorner, { CornerRadius = UDim.new(0, 6) }, scanBtn)

local copyBtn = create(TextButton, {
    Size = UDim2.new(1, 0, 0, 28),
    BackgroundColor3 = T.Card,
    BorderSizePixel = 0,
    Text = COPY HASIL JSON,
    Font = Enum.Font.GothamMedium,
    TextSize = 10,
    TextColor3 = T.Text,
    LayoutOrder = 4,
    ZIndex = 2
}, main)
create(UICorner, { CornerRadius = UDim.new(0, 6) }, copyBtn)
create(UIStroke, { Color = T.Border, Thickness = 1 }, copyBtn)

local function makeDraggable(handle, frame)
    local drag, startPos, dragStart = false, nil, nil
    handle.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            drag, startPos, dragStart = true, frame.Position, inp.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if drag and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            local d = inp.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            drag = false
        end
    end)
end
makeDraggable(header, main)

local dumpData = {}
local outputJSON = "

local function startScanning()
 logText.TextColor3 = T.AccentLight
 logText.Text = Sedang memindai ReplicatedStorage & PlayerGui...
 scanBtn.Text = Scanning...

 task.spawn(function()
 local remotes = {}
 local function scanFolder(container)
 if not container then return end
 pcall(function()
 for _, obj in ipairs(container:GetDescendants()) do
 local n = obj.Name:lower()
 if obj:IsA(RemoteFunction) or obj:IsA(RemoteEvent) or obj:IsA(BindableFunction) or obj:IsA(BindableEvent) then
 if n:find(server) or n:find(browser) or n:find(teleport) or n:find(list) or n:find(lobby) or n:find(match) or n:find(job) then
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

 scanFolder(ReplicatedStorage)
 scanFolder(localPlayer:FindFirstChildOfClass(PlayerGui))

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

 dumpData = {
 gameInfo = {
 placeId = game.PlaceId,
 jobId = game.JobId,
 uptimeSeconds = workspace.DistributedGameTime
 },
 remotesFound = remotes,
 guiFound = guis
 }

 pcall(function()
 outputJSON = HttpService:JSONEncode(dumpData)
 end)

 pcall(function()
 writefile(fishit_serverbrowser_dump.json, outputJSON)
 end)

 if setclipboard then
 pcall(function() setclipboard(outputJSON) end)
 end

 local res = string.format(✓ Scan Sukses!\n\n• %d Remotes ditemukan\n• %d GUI terdeteksi\n\n[Hasil sudah otomatis tersalin ke Clipboard & tersimpan di fishit_serverbrowser_dump.json], #remotes, #guis)
 logText.TextColor3 = T.Success
 logText.Text = res
 scanBtn.Text = SCAN ULANG
 copyBtn.Text = COPY HASIL JSON (Siap)
 end)
end

scanBtn.Activated:Connect(startScanning)

copyBtn.Activated:Connect(function()
 if outputJSON ~=  and setclipboard then
 setclipboard(outputJSON)
 copyBtn.Text = Tersalin ke Clipboard! ✓
 task.wait(1.5)
 copyBtn.Text = COPY HASIL JSON (Siap)
 else
 startScanning()
 end
end)

task.wait(0.2)
startScanning()
