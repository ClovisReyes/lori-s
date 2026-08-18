if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
while not localPlayer do
    task.wait(0.1)
    localPlayer = Players.LocalPlayer
end

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local CONFIG_FILENAME = "serverhopper_config_" .. tostring(game.PlaceId) .. ".json"
local BLACKLIST_FILENAME = "serverhopper_blacklist_" .. tostring(game.PlaceId) .. ".json"

local settings = {
    autoHop = false,
    hopInterval = 60,
    hopMode = "Lowest"
}

local blacklist = {}
local hopping = false
local autoHopThread = nil

local function fileExists(filename)
    if isfile then
        local success, val = pcall(function() return isfile(filename) end)
        if success then return val end
    end
    local success = pcall(function() readfile(filename) end)
    return success
end

local function saveSettings()
    local success, content = pcall(function()
        return HttpService:JSONEncode(settings)
    end)
    if success and content then
        pcall(function()
            writefile(CONFIG_FILENAME, content)
        end)
    end
end

local function loadSettings()
    if fileExists(CONFIG_FILENAME) then
        local success, content = pcall(function()
            return readfile(CONFIG_FILENAME)
        end)
        if success and content then
            local successDecode, decoded = pcall(function()
                return HttpService:JSONDecode(content)
            end)
            if successDecode and decoded then
                for k, v in pairs(decoded) do
                    if settings[k] ~= nil then
                        settings[k] = v
                    end
                end
            end
        end
    end
end

local function saveBlacklist()
    local success, content = pcall(function()
        return HttpService:JSONEncode(blacklist)
    end)
    if success and content then
        pcall(function()
            writefile(BLACKLIST_FILENAME, content)
        end)
    end
end

local function loadBlacklist()
    if fileExists(BLACKLIST_FILENAME) then
        local success, content = pcall(function()
            return readfile(BLACKLIST_FILENAME)
        end)
        if success and content then
            local successDecode, decoded = pcall(function()
                return HttpService:JSONDecode(content)
            end)
            if successDecode and decoded then
                blacklist = decoded
            end
        end
    end
end

local function addToBlacklist(jobId)
    for _, id in ipairs(blacklist) do
        if id == jobId then return end
    end
    table.insert(blacklist, jobId)
    if #blacklist > 100 then
        table.remove(blacklist, 1)
    end
    saveBlacklist()
end

local function isBlacklisted(jobId)
    for _, id in ipairs(blacklist) do
        if id == jobId then return true end
    end
    return false
end

loadSettings()
loadBlacklist()
addToBlacklist(game.JobId)

local parentGui
if gethui then
    local success, hui = pcall(gethui)
    if success and hui then parentGui = hui end
end
if not parentGui then
    local successCore, coreGui = pcall(function() return game:GetService("CoreGui") end)
    if successCore and coreGui then
        parentGui = coreGui
    else
        parentGui = localPlayer:WaitForChild("PlayerGui", 5) or localPlayer:FindFirstChildOfClass("PlayerGui")
    end
end

if parentGui:FindFirstChild("ServerHopGui") then
    parentGui.ServerHopGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ServerHopGui"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 999
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = parentGui

local connections = {}
local function addConn(signal, fn)
    local conn = signal:Connect(fn)
    table.insert(connections, conn)
    return conn
end

local function cleanupAll()
    if autoHopThread then task.cancel(autoHopThread) autoHopThread = nil end
    for _, c in ipairs(connections) do
        if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
    end
    table.clear(connections)
end
screenGui.Destroying:Connect(cleanupAll)

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
    AccentDark = Color3.fromRGB(200, 95, 10),
    AccentLight = Color3.fromRGB(255, 165, 55),
    Text = Color3.fromRGB(245, 245, 250),
    Muted = Color3.fromRGB(140, 140, 150),
    Success = Color3.fromRGB(75, 220, 120),
    Error = Color3.fromRGB(255, 80, 80)
}

local main = create("Frame", {
    Name = "MainFrame", Size = UDim2.new(0, 270, 0, 210),
    Position = UDim2.new(0.5, -135, 0.35, -105), BackgroundColor3 = T.Bg,
    BorderSizePixel = 0, Active = true, ZIndex = 1
}, screenGui)
create("UICorner", { CornerRadius = UDim.new(0, 10) }, main)
create("UIStroke", { Color = T.Accent, Thickness = 1.2, Transparency = 0.25 }, main)
create("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10) }, main)
create("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }, main)

local header = create("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, LayoutOrder = 1, ZIndex = 2 }, main)

create("TextLabel", {
    Size = UDim2.new(1, -50, 1, 0),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundTransparency = 1,
    Text = "Server Hopper v1.2.1",
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    TextColor3 = T.Text,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 3
}, header)

local minBtn = create("TextButton", { Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -44, 0, 1), BackgroundColor3 = T.Card, Text = "—", Font = Enum.Font.GothamMedium, TextSize = 11, TextColor3 = T.Muted, BorderSizePixel = 0, ZIndex = 3 }, header)
create("UICorner", { CornerRadius = UDim.new(0, 5) }, minBtn)

local closeBtn = create("TextButton", { Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -20, 0, 1), BackgroundColor3 = T.Card, Text = "✕", Font = Enum.Font.GothamMedium, TextSize = 10, TextColor3 = T.Muted, BorderSizePixel = 0, ZIndex = 3 }, header)
create("UICorner", { CornerRadius = UDim.new(0, 5) }, closeBtn)

local modeContainer = create("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = T.Card, BorderSizePixel = 0, LayoutOrder = 2, ZIndex = 2 }, main)
create("UICorner", { CornerRadius = UDim.new(0, 6) }, modeContainer)
create("UIPadding", { PaddingLeft = UDim.new(0, 3), PaddingRight = UDim.new(0, 3), PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3) }, modeContainer)
local modeLayout = create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4) }, modeContainer)

local modeButtons = {}
local modes = { "Lowest", "Random", "Highest" }

local function updateModeTabs()
    for name, btn in pairs(modeButtons) do
        local isActive = (settings.hopMode == name)
        btn.BackgroundColor3 = isActive and T.Accent or Color3.fromRGB(0, 0, 0)
        btn.BackgroundTransparency = isActive and 0 or 1
        btn.TextColor3 = isActive and Color3.fromRGB(15, 15, 18) or T.Muted
        btn.Font = Enum.Font.GothamMedium
    end
end

for _, m in ipairs(modes) do
    local btn = create("TextButton", {
        Name = m, Size = UDim2.new(0.333, -3, 1, 0),
        BackgroundTransparency = 1, Text = m,
        Font = Enum.Font.GothamMedium, TextSize = 10,
        BorderSizePixel = 0, ZIndex = 3
    }, modeContainer)
    create("UICorner", { CornerRadius = UDim.new(0, 4) }, btn)
    modeButtons[m] = btn

    addConn(btn.Activated, function()
        settings.hopMode = m
        updateModeTabs()
        saveSettings()
    end)
end
updateModeTabs()

local hopBtn = create("TextButton", {
    Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = T.Accent,
    BorderSizePixel = 0, Text = "Hop Server Now", Font = Enum.Font.GothamMedium,
    TextSize = 11, TextColor3 = Color3.fromRGB(15, 15, 18), LayoutOrder = 3, ZIndex = 2
}, main)
create("UICorner", { CornerRadius = UDim.new(0, 6) }, hopBtn)

local autoCard = create("Frame", { Size = UDim2.new(1, 0, 0, 52), BackgroundColor3 = T.Card, BorderSizePixel = 0, LayoutOrder = 4, ZIndex = 2 }, main)
create("UICorner", { CornerRadius = UDim.new(0, 6) }, autoCard)
create("UIStroke", { Color = T.Border, Thickness = 1 }, autoCard)
create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6) }, autoCard)
create("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 4) }, autoCard)

local autoRow = create("Frame", { Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, ZIndex = 3 }, autoCard)
create("TextLabel", { Size = UDim2.new(1, -55, 1, 0), BackgroundTransparency = 1, Text = "Auto Hop (Loop):", Font = Enum.Font.GothamMedium, TextSize = 10, TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4 }, autoRow)

local autoToggle = create("TextButton", {
    Size = UDim2.new(0, 48, 1, 0), Position = UDim2.new(1, -48, 0, 0),
    BackgroundColor3 = settings.autoHop and T.Accent or T.Bg,
    BorderSizePixel = 0, Text = settings.autoHop and "ON" or "OFF",
    Font = Enum.Font.GothamMedium, TextSize = 10,
    TextColor3 = settings.autoHop and Color3.fromRGB(15, 15, 18) or T.Muted,
    ZIndex = 4
}, autoRow)
create("UICorner", { CornerRadius = UDim.new(0, 4) }, autoToggle)
local autoToggleStroke = create("UIStroke", { Color = settings.autoHop and T.Accent or T.Border, Thickness = 1 }, autoToggle)

local delayRow = create("Frame", { Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, ZIndex = 3 }, autoCard)
create("TextLabel", { Size = UDim2.new(1, -55, 1, 0), BackgroundTransparency = 1, Text = "Delay Interval (s):", Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = T.Muted, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4 }, delayRow)

local delayBox = create("TextBox", {
    Size = UDim2.new(0, 48, 1, 0), Position = UDim2.new(1, -48, 0, 0),
    BackgroundColor3 = T.Bg, BorderSizePixel = 0,
    Text = tostring(settings.hopInterval), Font = Enum.Font.GothamMedium,
    TextSize = 11, TextColor3 = T.Text, ClearTextOnFocus = false, ZIndex = 4
}, delayRow)
create("UICorner", { CornerRadius = UDim.new(0, 4) }, delayBox)
create("UIStroke", { Color = T.Border, Thickness = 1 }, delayBox)

local footer = create("Frame", { Size = UDim2.new(1, 0, 0, 18), BackgroundColor3 = T.Card, BorderSizePixel = 0, LayoutOrder = 5, ZIndex = 2 }, main)
create("UICorner", { CornerRadius = UDim.new(0, 5) }, footer)
create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, footer)

local statusDot = create("Frame", { Size = UDim2.new(0, 5, 0, 5), Position = UDim2.new(0, 0, 0.5, -2.5), BackgroundColor3 = T.Success, BorderSizePixel = 0, ZIndex = 4 }, footer)
create("UICorner", { CornerRadius = UDim.new(1, 0) }, statusDot)

local statusLbl = create("TextLabel", { Size = UDim2.new(1, -75, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Text = "Ready", Font = Enum.Font.GothamMedium, TextSize = 9, TextColor3 = T.Success, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 4 }, footer)
local onlineLbl = create("TextLabel", { Size = UDim2.new(0, 80, 1, 0), Position = UDim2.new(1, -80, 0, 0), BackgroundTransparency = 1, Text = #Players:GetPlayers() .. "/" .. (Players.MaxPlayers or 22) .. " online", Font = Enum.Font.Gotham, TextSize = 9, TextColor3 = T.Muted, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 4 }, footer)

addConn(Players.PlayerAdded, function() onlineLbl.Text = #Players:GetPlayers() .. "/" .. (Players.MaxPlayers or 22) .. " online" end)
addConn(Players.PlayerRemoving, function() task.wait(0.2) onlineLbl.Text = #Players:GetPlayers() .. "/" .. (Players.MaxPlayers or 22) .. " online" end)

local function updateStatus(text, statusType)
    if not statusLbl or not statusLbl.Parent then return end
    statusLbl.Text = tostring(text)
    if statusType == "error" then
        statusLbl.TextColor3 = T.Error
        statusDot.BackgroundColor3 = T.Error
    elseif statusType == "success" or text == "Ready" then
        statusLbl.TextColor3 = T.Success
        statusDot.BackgroundColor3 = T.Success
    else
        statusLbl.TextColor3 = T.AccentLight
        statusDot.BackgroundColor3 = T.Accent
    end
end

local floatBadge = create("Frame", { Size = UDim2.new(0, 42, 0, 42), Position = UDim2.new(0, 20, 0.5, -21), BackgroundColor3 = T.Bg, BorderSizePixel = 0, Visible = false, Active = true, ZIndex = 10 }, screenGui)
create("UICorner", { CornerRadius = UDim.new(0, 10) }, floatBadge)
create("UIStroke", { Color = T.Accent, Thickness = 1.5, Transparency = 0.2 }, floatBadge)

local floatBtn = create("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "⚡", Font = Enum.Font.GothamMedium, TextSize = 18, TextColor3 = T.Accent, ZIndex = 11 }, floatBadge)

local function addHover(btn, normal, hover)
    addConn(btn.MouseEnter, function() TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = hover }):Play() end)
    addConn(btn.MouseLeave, function() TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = normal }):Play() end)
end
addHover(hopBtn, T.Accent, T.AccentLight)
addHover(minBtn, T.Card, T.CardHover)
addHover(closeBtn, T.Card, Color3.fromRGB(180, 40, 40))

local function makeDraggable(handle, frame, onClick)
    local drag, startPos, dragStart, distSq = false, nil, nil, 0
    addConn(handle.InputBegan, function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            drag, startPos, dragStart, distSq = true, frame.Position, inp.Position, 0
        end
    end)
    addConn(UserInputService.InputChanged, function(inp)
        if drag and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            local d = inp.Position - dragStart
            distSq = d.X * d.X + d.Y * d.Y
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    addConn(UserInputService.InputEnded, function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            if drag then
                drag = false
                if distSq < 36 and onClick then onClick() end
            end
        end
    end)
end
makeDraggable(header, main)
makeDraggable(floatBtn, floatBadge, function() main.Visible = true floatBadge.Visible = false end)

addConn(minBtn.Activated, function() main.Visible = false floatBadge.Visible = true end)
addConn(closeBtn.Activated, function()
    settings.autoHop = false
    cleanupAll()
    screenGui:Destroy()
end)


local function fetchServers(placeId, sortOrder, cursor)
    local cur = (cursor and cursor ~= "") and ("&cursor=" .. cursor) or ""
    local sort = sortOrder or "Asc"
    local urls = {
        "https://games.roproxy.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=" .. sort .. "&limit=100" .. cur,
        "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=" .. sort .. "&limit=100" .. cur
    }

    local http = (syn and syn.request) or (http and http.request) or http_request or (Fluxus and Fluxus.request) or request

    for _, url in ipairs(urls) do
        if http then
            local success, response = pcall(function()
                return http({
                    Url = url,
                    Method = "GET"
                })
            end)
            if success and response and response.StatusCode == 200 and response.Body then
                local successDecode, decoded = pcall(function()
                    return HttpService:JSONDecode(response.Body)
                end)
                if successDecode and decoded and decoded.data then
                    return decoded.data, decoded.nextPageCursor
                end
            end
        end

        local success, response = pcall(function()
            return game:HttpGet(url)
        end)
        if success and response then
            local successDecode, decoded = pcall(function()
                return HttpService:JSONDecode(response)
            end)
            if successDecode and decoded and decoded.data then
                return decoded.data, decoded.nextPageCursor
            end
        end
    end

    return nil
end

local function executeServerHop()
    if hopping then return end
    hopping = true
    updateStatus("Fetching servers...", "info")

    local placeId = game.PlaceId
    local currentJobId = game.JobId

    local sortOrder = "Asc"
    if settings.hopMode == "Highest" then
        sortOrder = "Desc"
    elseif settings.hopMode == "Random" then
        sortOrder = math.random(1, 2) == 1 and "Asc" or "Desc"
    end

    task.spawn(function()
        local character = localPlayer.Character
        if not character then
            local startTime = tick()
            while not localPlayer.Character and tick() - startTime < 5 do
                task.wait(0.1)
            end
            character = localPlayer.Character
        end
        if character then
            pcall(function()
                character:WaitForChild("HumanoidRootPart", 5)
            end)
        end

        local serverList, nextCursor = fetchServers(placeId, sortOrder)
        if not serverList or #serverList == 0 then
            updateStatus("Failed to load servers", "error")
            task.wait(2)
            hopping = false
            return
        end

        updateStatus("Sorting & filtering...", "info")
        local validServers = {}

        local function addValid(list)
            for _, server in ipairs(list or {}) do
                local pl, maxP = tonumber(server.playing) or 0, tonumber(server.maxPlayers) or 0
                if server.id ~= currentJobId and pl < maxP and pl >= 1 then
                    table.insert(validServers, server)
                end
            end
        end

        addValid(serverList)

        if (settings.hopMode == "Highest" or #validServers < 15) and nextCursor then
            local serverList2 = fetchServers(placeId, sortOrder, nextCursor)
            if serverList2 then addValid(serverList2) end
        end

        if #validServers == 0 then
            updateStatus("No available servers found", "error")
            task.wait(2)
            hopping = false
            return
        end

        local nonBlacklisted = {}
        for _, s in ipairs(validServers) do
            if not isBlacklisted(s.id) then
                table.insert(nonBlacklisted, s)
            end
        end

        if #nonBlacklisted == 0 then
            blacklist = {}
            addToBlacklist(currentJobId)
            saveBlacklist()
            nonBlacklisted = validServers
        end

        local targetServer
        if settings.hopMode == "Random" then
            targetServer = nonBlacklisted[math.random(1, #nonBlacklisted)]
        elseif settings.hopMode == "Highest" then
            table.sort(nonBlacklisted, function(a, b)
                return (tonumber(a.playing) or 0) > (tonumber(b.playing) or 0)
            end)
            targetServer = nonBlacklisted[1]
        else
            table.sort(nonBlacklisted, function(a, b)
                return (tonumber(a.playing) or 0) < (tonumber(b.playing) or 0) end)
            for _, s in ipairs(nonBlacklisted) do
                if (tonumber(s.playing) or 0) == 1 then
                    targetServer = s
                    break
                end
            end
            if not targetServer then
                for _, s in ipairs(nonBlacklisted) do
                    if (tonumber(s.playing) or 0) >= 2 then
                        targetServer = s
                        break
                    end
                end
            end
            targetServer = targetServer or nonBlacklisted[1]
        end

        if targetServer then
            updateStatus("Teleporting (" .. tostring(targetServer.playing) .. "/" .. tostring(targetServer.maxPlayers) .. ")...", "info")
            addToBlacklist(targetServer.id)

            local teleportSuccess = pcall(function()
                TeleportService:TeleportToPlaceInstance(placeId, targetServer.id, localPlayer)
            end)

            if not teleportSuccess then
                updateStatus("Retrying teleport...", "error")
                task.wait(1.5)
                pcall(function()
                    TeleportService:Teleport(placeId, localPlayer)
                end)
            end
        else
            updateStatus("No valid target found", "error")
        end

        task.wait(4)
        hopping = false
    end)
end

local function handleTeleportFailure()
    pcall(function() GuiService:ClearError() end)
    hopping = false
    updateStatus("Server full! Cari lagi dlm 2s...", "error")
    task.wait(2)
    if screenGui and screenGui.Parent then
        executeServerHop()
    end
end

addConn(GuiService.ErrorMessageChanged, function(msg)
    if msg and msg ~= "" then
        task.spawn(handleTeleportFailure)
    end
end)

addConn(TeleportService.TeleportInitFailed, function(player)
    if player == localPlayer then
        task.spawn(handleTeleportFailure)
    end
end)

pcall(function()
    local coreGui = game:GetService("CoreGui")
    local promptGui = coreGui:WaitForChild("RobloxPromptGui", 2)
    local promptOverlay = promptGui and promptGui:WaitForChild("promptOverlay", 2)
    if promptOverlay then
        addConn(promptOverlay.ChildAdded, function(child)
            if child.Name == "ErrorPrompt" or child.Name:find("Error") or child.Name:find("Prompt") then
                task.wait(0.2)
                task.spawn(handleTeleportFailure)
            end
        end)
    end
end)

addConn(hopBtn.Activated, executeServerHop)

local function startAutoHop()
    if autoHopThread then task.cancel(autoHopThread) autoHopThread = nil end
    autoHopThread = task.spawn(function()
        while settings.autoHop and screenGui and screenGui.Parent do
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
    autoToggle.TextColor3 = settings.autoHop and Color3.fromRGB(15, 15, 18) or T.Muted
    autoToggleStroke.Color = settings.autoHop and T.Accent or T.Border
end

addConn(autoToggle.Activated, function()
    settings.autoHop = not settings.autoHop
    updateAutoHopVisual()
    saveSettings()
    if settings.autoHop then
        startAutoHop()
    elseif autoHopThread then
        task.cancel(autoHopThread)
        updateStatus("Ready", "success")
    end
end)

addConn(delayBox.FocusLost, function()
    local val = tonumber(delayBox.Text:gsub("%D+", ""))
    if val and val >= 0 then
        settings.hopInterval = math.floor(val)
        delayBox.Text = tostring(settings.hopInterval)
        saveSettings()
        if settings.autoHop then startAutoHop() end
    else
        delayBox.Text = tostring(settings.hopInterval)
    end
end)

if settings.autoHop then startAutoHop() else updateStatus("Ready", "success") end
