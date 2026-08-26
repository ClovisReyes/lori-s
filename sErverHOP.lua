if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

if _G.FishItServerHopConns then
    for _, c in ipairs(_G.FishItServerHopConns) do pcall(function() c:Disconnect() end) end
end
_G.FishItServerHopConns = {}
local function track(conn) table.insert(_G.FishItServerHopConns, conn) return conn end

local CFG_FILE = "serverhopper_config_" .. game.PlaceId .. ".json"
local BL_FILE = "serverhopper_blacklist_" .. game.PlaceId .. ".json"

local settings = { autoHop = false, hopInterval = 60, hopMode = "Lowest" }
local blacklist = {}
local hopping = false
local autoHopThread = nil

local function fileIo(mode, file, data)
    if mode == "write" and writefile then
        pcall(function() writefile(file, HttpService:JSONEncode(data)) end)
    elseif mode == "read" and isfile and readfile then
        local ok, res = pcall(function() return isfile(file) and readfile(file) end)
        if ok and res then
            local okD, dec = pcall(function() return HttpService:JSONDecode(res) end)
            if okD and dec then return dec end
        end
    end
end

local savedCfg = fileIo("read", CFG_FILE)
if savedCfg then for k, v in pairs(savedCfg) do settings[k] = v end end
if settings.hopMode ~= "Highest" then settings.hopMode = "Lowest" end
blacklist = fileIo("read", BL_FILE) or {}

local function addToBlacklist(jobId)
    if not jobId or jobId == "" or table.find(blacklist, jobId) then return end
    table.insert(blacklist, jobId)
    if #blacklist > 100 then table.remove(blacklist, 1) end
    fileIo("write", BL_FILE, blacklist)
end
addToBlacklist(game.JobId)

local parentGui = (gethui and gethui()) or game:GetService("CoreGui")
if parentGui:FindFirstChild("ServerHopGui") then parentGui.ServerHopGui:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ServerHopGui"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 9999
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = parentGui

local JB_BOLD = Font.fromName("JetBrainsMono", Enum.FontWeight.Bold)
local JB_MED = Font.fromName("JetBrainsMono", Enum.FontWeight.Medium)

local function create(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do obj[k] = v end
    if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
        pcall(function()
            if props and props.Font == Enum.Font.GothamMedium then
                obj.FontFace = JB_MED
            else
                obj.FontFace = JB_BOLD
            end
        end)
    end
    if parent then obj.Parent = parent end
    return obj
end

local T = {
    Bg = Color3.fromRGB(13, 15, 20), Card = Color3.fromRGB(20, 24, 32),
    Border = Color3.fromRGB(38, 48, 65), Accent = Color3.fromRGB(255, 140, 30),
    Text = Color3.fromRGB(245, 248, 255), Muted = Color3.fromRGB(140, 155, 175),
    Green = Color3.fromRGB(75, 225, 135), Red = Color3.fromRGB(255, 85, 85)
}

local main = create("Frame", {
    Name = "MainFrame", Size = UDim2.new(0, 260, 0, 178),
    Position = UDim2.new(0.5, -130, 0.35, -89), BackgroundColor3 = T.Bg,
    BorderSizePixel = 0, Active = true, Visible = false, ZIndex = 1
}, screenGui)
create("UICorner", { CornerRadius = UDim.new(0, 10) }, main)
create("UIStroke", { Color = T.Accent, Thickness = 1.2, Transparency = 0.25 }, main)
create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) }, main)
create("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) }, main)

local header = create("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, LayoutOrder = 1, ZIndex = 2 }, main)
create("TextLabel", { Size = UDim2.new(1, -60, 1, 0), BackgroundTransparency = 1, Text = "Server Hopper", Font = Enum.Font.Code, TextSize = 11, TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3 }, header)

local minBtn = create("TextButton", {
    Size = UDim2.new(0, 26, 0, 20), Position = UDim2.new(1, -54, 0, 1),
    BackgroundColor3 = T.Accent, Text = "—", Font = Enum.Font.Code,
    TextSize = 12, TextColor3 = Color3.fromRGB(15, 15, 20), BorderSizePixel = 0, ZIndex = 3
}, header)
create("UICorner", { CornerRadius = UDim.new(0, 4) }, minBtn)

local closeBtn = create("TextButton", {
    Size = UDim2.new(0, 22, 0, 20), Position = UDim2.new(1, -24, 0, 1),
    BackgroundColor3 = T.Accent, Text = "X", Font = Enum.Font.Code,
    TextSize = 11, TextColor3 = Color3.fromRGB(15, 15, 20), BorderSizePixel = 0, ZIndex = 3
}, header)
create("UICorner", { CornerRadius = UDim.new(0, 4) }, closeBtn)

local modeContainer = create("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundColor3 = T.Card, BorderSizePixel = 0, LayoutOrder = 2, ZIndex = 2 }, main)
create("UICorner", { CornerRadius = UDim.new(0, 5) }, modeContainer)
create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4) }, modeContainer)
create("UIPadding", { PaddingLeft = UDim.new(0, 3), PaddingRight = UDim.new(0, 3), PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 2) }, modeContainer)

local modeButtons = {}
local function updateModeTabs()
    for name, btn in pairs(modeButtons) do
        local active = (settings.hopMode == name)
        btn.BackgroundColor3 = active and T.Accent or T.Card
        btn.BackgroundTransparency = active and 0 or 1
        btn.TextColor3 = active and Color3.fromRGB(15, 15, 20) or T.Muted
    end
end

for _, m in ipairs({ "Lowest", "Highest" }) do
    local btn = create("TextButton", { Size = UDim2.new(0.5, -2, 1, 0), BackgroundTransparency = 1, Text = m, Font = Enum.Font.Code, TextSize = 9.5, BorderSizePixel = 0, ZIndex = 3 }, modeContainer)
    create("UICorner", { CornerRadius = UDim.new(0, 4) }, btn)
    modeButtons[m] = btn
    track(btn.Activated:Connect(function() settings.hopMode = m updateModeTabs() fileIo("write", CFG_FILE, settings) end))
end
updateModeTabs()

local hopBtn = create("TextButton", {
    Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = T.Accent,
    BorderSizePixel = 0, Text = "HOP SERVER NOW", Font = Enum.Font.Code,
    TextSize = 10, TextColor3 = Color3.fromRGB(15, 15, 20), LayoutOrder = 3, ZIndex = 2
}, main)
create("UICorner", { CornerRadius = UDim.new(0, 6) }, hopBtn)

local autoCard = create("Frame", { Size = UDim2.new(1, 0, 0, 48), BackgroundColor3 = T.Card, BorderSizePixel = 0, LayoutOrder = 4, ZIndex = 2 }, main)
create("UICorner", { CornerRadius = UDim.new(0, 6) }, autoCard)
create("UIStroke", { Color = T.Border, Thickness = 1 }, autoCard)
create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3) }, autoCard)
create("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 3) }, autoCard)

local r1 = create("Frame", { Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, ZIndex = 3 }, autoCard)
create("TextLabel", { Size = UDim2.new(1, -55, 1, 0), BackgroundTransparency = 1, Text = "Auto Hop (Loop):", Font = Enum.Font.GothamMedium, TextSize = 9, TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4 }, r1)
local autoToggle = create("TextButton", {
    Size = UDim2.new(0, 48, 1, 0), Position = UDim2.new(1, -48, 0, 0),
    BackgroundColor3 = settings.autoHop and T.Accent or T.Bg,
    Text = settings.autoHop and "ON" or "OFF", Font = Enum.Font.Code, TextSize = 9.5,
    TextColor3 = settings.autoHop and Color3.fromRGB(15, 15, 20) or T.Muted, BorderSizePixel = 0, ZIndex = 4
}, r1)
create("UICorner", { CornerRadius = UDim.new(0, 4) }, autoToggle)
create("UIStroke", { Color = T.Border, Thickness = 1 }, autoToggle)

local r2 = create("Frame", { Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, ZIndex = 3 }, autoCard)
create("TextLabel", { Size = UDim2.new(1, -55, 1, 0), BackgroundTransparency = 1, Text = "Delay Interval (s):", Font = Enum.Font.GothamMedium, TextSize = 9, TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4 }, r2)
local delayBox = create("TextBox", {
    Size = UDim2.new(0, 48, 1, 0), Position = UDim2.new(1, -48, 0, 0),
    BackgroundColor3 = T.Bg, Text = tostring(settings.hopInterval), Font = Enum.Font.Code,
    TextSize = 10, TextColor3 = T.Accent, ClearTextOnFocus = false, BorderSizePixel = 0, ZIndex = 4
}, r2)
create("UICorner", { CornerRadius = UDim.new(0, 4) }, delayBox)
create("UIStroke", { Color = T.Border, Thickness = 1 }, delayBox)

local footer = create("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundColor3 = T.Card, BorderSizePixel = 0, LayoutOrder = 5, ZIndex = 2 }, main)
create("UICorner", { CornerRadius = UDim.new(0, 5) }, footer)
create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, footer)

local statusDot = create("Frame", { Size = UDim2.new(0, 6, 0, 6), Position = UDim2.new(0, 0, 0.5, -3), BackgroundColor3 = T.Green, BorderSizePixel = 0, ZIndex = 4 }, footer)
create("UICorner", { CornerRadius = UDim.new(1, 0) }, statusDot)

local statusLbl = create("TextLabel", { Size = UDim2.new(1, -95, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, Text = "Ready", Font = Enum.Font.Code, TextSize = 10, TextColor3 = T.Green, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 4 }, footer)
local onlineLbl = create("TextLabel", { Size = UDim2.new(0, 90, 1, 0), Position = UDim2.new(1, -90, 0, 0), BackgroundTransparency = 1, Text = #Players:GetPlayers() .. " Players", Font = Enum.Font.Code, TextSize = 10, TextColor3 = T.Muted, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 4 }, footer)

track(Players.PlayerAdded:Connect(function() onlineLbl.Text = #Players:GetPlayers() .. " Players" end))
track(Players.PlayerRemoving:Connect(function() task.wait(0.2) onlineLbl.Text = #Players:GetPlayers() .. " Players" end))

local function updateStatus(text, statusType)
    if not statusLbl or not statusLbl.Parent then return end
    statusLbl.Text = tostring(text)
    if statusType == "error" then
        statusLbl.TextColor3 = T.Red statusDot.BackgroundColor3 = T.Red
    elseif statusType == "success" or text == "Ready" then
        statusLbl.TextColor3 = T.Green statusDot.BackgroundColor3 = T.Green
    else
        statusLbl.TextColor3 = T.Accent statusDot.BackgroundColor3 = T.Accent
    end
end

local floatBadge = create("Frame", { Size = UDim2.new(0, 38, 0, 38), Position = UDim2.new(0, 20, 0.5, -19), BackgroundColor3 = T.Bg, BorderSizePixel = 0, Visible = true, Active = true, ZIndex = 10 }, screenGui)
create("UICorner", { CornerRadius = UDim.new(0, 8) }, floatBadge)
create("UIStroke", { Color = T.Accent, Thickness = 1.2, Transparency = 0.2 }, floatBadge)
local floatBtn = create("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "Ꝏ", Font = Enum.Font.Code, TextSize = 18, TextColor3 = T.Accent, ZIndex = 11 }, floatBadge)

local function makeDraggable(handle, frame, onClick)
    local drag, startPos, dragStart, distSq = false, nil, nil, 0
    track(handle.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            drag, startPos, dragStart, distSq = true, frame.Position, inp.Position, 0
        end
    end))
    track(UserInputService.InputChanged:Connect(function(inp)
        if drag and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            local d = inp.Position - dragStart
            distSq = d.X * d.X + d.Y * d.Y
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end))
    track(UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            if drag then
                drag = false
                if distSq < 36 and onClick then onClick() end
            end
        end
    end))
end
makeDraggable(header, main)
makeDraggable(floatBtn, floatBadge, function() main.Visible = true floatBadge.Visible = false end)

track(minBtn.Activated:Connect(function() main.Visible = false floatBadge.Visible = true end))
track(closeBtn.Activated:Connect(function() screenGui:Destroy() end))

local function fetchServers(placeId, sortOrder, cursor)
    local cur = (cursor and cursor ~= "") and ("&cursor=" .. cursor) or ""
    local sort = sortOrder or "Asc"
    local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=" .. sort .. "&excludeFullGames=true&limit=100" .. cur
    
    local req = (syn and syn.request) or (http and http.request) or http_request or request
    local body = nil
    
    if req then
        local s, res = pcall(function() return req({ Url = url, Method = "GET" }) end)
        if s and res and (res.StatusCode == 200 or res.Status == 200) and res.Body then body = res.Body end
    elseif game.HttpGet then
        local s, res = pcall(function() return game:HttpGet(url) end)
        if s and res then body = res end
    end
    
    if body and body ~= "" then
        local s, json = pcall(function() return HttpService:JSONDecode(body) end)
        if s and json and json.data and #json.data > 0 then return json.data, json.nextPageCursor end
    end
    return nil
end

local function executeServerHop()
    if hopping then return end
    hopping = true
    updateStatus("Scanning...", "info")

    local placeId = game.PlaceId
    local currentJobId = game.JobId
    local mode = (settings.hopMode == "Highest") and "Highest" or "Lowest"
    local apiSort = (mode == "Highest") and "Desc" or "Asc"

    task.spawn(function()
        local valid = {}
        local list = fetchServers(placeId, apiSort)
        if list and #list > 0 then
            for _, s in ipairs(list) do
                local pl = tonumber(s.playing) or 0
                local maxP = tonumber(s.maxPlayers) or 20
                if s.id and s.id ~= currentJobId and not table.find(blacklist, s.id) and pl < maxP and pl >= 1 then
                    table.insert(valid, { id = s.id, playing = pl, maxPlayers = maxP })
                end
            end
        end

        if #valid == 0 then
            blacklist = {}
            addToBlacklist(currentJobId)
            updateStatus("Refreshing...", "info")
            task.wait(1)
            hopping = false
            return executeServerHop()
        end

        if mode == "Highest" then
            table.sort(valid, function(a, b) return a.playing > b.playing end)
        else
            table.sort(valid, function(a, b) return a.playing < b.playing end)
        end

        local target = valid[1]
        if target and target.id then
            updateStatus("Teleporting (" .. target.playing .. "p)...", "info")
            addToBlacklist(target.id)
            TeleportService:TeleportToPlaceInstance(placeId, target.id, localPlayer)
        end
        task.delay(4, function() hopping = false updateStatus("Ready", "success") end)
    end)
end

track(hopBtn.Activated:Connect(executeServerHop))

local function startAutoHop()
    if autoHopThread then task.cancel(autoHopThread) autoHopThread = nil end
    autoHopThread = task.spawn(function()
        while settings.autoHop and screenGui.Parent do
            local interval = tonumber(settings.hopInterval) or 60
            for i = interval, 1, -1 do
                if not settings.autoHop or not screenGui.Parent then break end
                updateStatus("Hop in " .. i .. "s...", "info")
                task.wait(1)
            end
            if settings.autoHop and screenGui.Parent then
                executeServerHop()
                task.wait(8)
            end
        end
        if not settings.autoHop then updateStatus("Ready", "success") end
    end)
end

local function updateAutoHopVisual()
    autoToggle.Text = settings.autoHop and "ON" or "OFF"
    autoToggle.BackgroundColor3 = settings.autoHop and T.Accent or T.Bg
    autoToggle.TextColor3 = settings.autoHop and Color3.fromRGB(15, 15, 20) or T.Muted
end

track(autoToggle.Activated:Connect(function()
    settings.autoHop = not settings.autoHop
    updateAutoHopVisual()
    fileIo("write", CFG_FILE, settings)
    if settings.autoHop then startAutoHop() elseif autoHopThread then task.cancel(autoHopThread) updateStatus("Ready", "success") end
end))

track(delayBox.FocusLost:Connect(function()
    local val = tonumber(delayBox.Text:gsub("%D+", ""))
    settings.hopInterval = (val and val >= 1) and math.floor(val) or 60
    delayBox.Text = tostring(settings.hopInterval)
    fileIo("write", CFG_FILE, settings)
    if settings.autoHop then startAutoHop() end
end))

pcall(function()
    track(GuiService.ErrorMessageChanged:Connect(function(msg)
        if msg and msg ~= "" then
            pcall(function() GuiService:ClearError() end)
            hopping = false updateStatus("Retrying...", "error")
            task.wait(1.2) executeServerHop()
        end
    end))
end)

track(screenGui.Destroying:Connect(function()
    if autoHopThread then task.cancel(autoHopThread) end
    for _, c in ipairs(_G.FishItServerHopConns or {}) do pcall(function() c:Disconnect() end) end
    _G.FishItServerHopConns = nil
end))

if settings.autoHop then startAutoHop() else updateStatus("Ready", "success") end
