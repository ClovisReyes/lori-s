if not game:IsLoaded() then
    game.Loaded:Wait()
end

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

local CONFIG_FILENAME = "serverhopper_config_" .. tostring(game.PlaceId) .. ".json"
local BLACKLIST_FILENAME = "serverhopper_blacklist_" .. tostring(game.PlaceId) .. ".json"

local settings = {
    autoHop = false,
    hopInterval = 60,
    hopMode = "Lowest"
}

local blacklist = {}

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

local function cleanupExisting()
    if gethui then
        local success, hui = pcall(gethui)
        if success and hui then
            local old = hui:FindFirstChild("ServerHopGui")
            if old then old:Destroy() end
        end
    end
    local success, coreGui = pcall(function() return game:GetService("CoreGui") end)
    if success and coreGui then
        local old = coreGui:FindFirstChild("ServerHopGui")
        if old then old:Destroy() end
    end
    local playerGui = localPlayer:FindFirstChildOfClass("PlayerGui") or localPlayer:WaitForChild("PlayerGui", 2)
    if playerGui then
        local oldP = playerGui:FindFirstChild("ServerHopGui")
        if oldP then oldP:Destroy() end
    end
end
cleanupExisting()

local parentGui
if gethui then
    local success, hui = pcall(gethui)
    if success and hui then
        parentGui = hui
    end
end
if not parentGui then
    local successCore, coreGui = pcall(function() return game:GetService("CoreGui") end)
    if successCore and coreGui then
        parentGui = coreGui
    else
        parentGui = localPlayer:WaitForChild("PlayerGui", 5) or localPlayer:FindFirstChildOfClass("PlayerGui")
    end
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ServerHopGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = parentGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 260, 0, 136)
mainFrame.Position = UDim2.new(0.5, -130, 0.4, -68)
mainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
mainFrame.BackgroundTransparency = 0.2
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.ZIndex = 2
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 6)
mainCorner.Parent = mainFrame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Thickness = 1
stroke.Transparency = 0.9
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.Parent = mainFrame

local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 10)
padding.PaddingRight = UDim.new(0, 10)
padding.PaddingTop = UDim.new(0, 8)
padding.PaddingBottom = UDim.new(0, 8)
padding.Parent = mainFrame

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Vertical
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 6)
layout.Parent = mainFrame

local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 16)
topBar.BackgroundTransparency = 1
topBar.BorderSizePixel = 0
topBar.ZIndex = 3
topBar.LayoutOrder = 1
topBar.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(0, 80, 1, 0)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "hop // engine"
titleLabel.Font = Enum.Font.Code
titleLabel.TextSize = 10
titleLabel.TextColor3 = Color3.fromRGB(140, 140, 150)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 4
titleLabel.Parent = topBar

local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 16, 1, 0)
closeBtn.Position = UDim2.new(1, -16, 0, 0)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "×"
closeBtn.Font = Enum.Font.Code
closeBtn.TextSize = 12
closeBtn.TextColor3 = Color3.fromRGB(140, 140, 150)
closeBtn.ZIndex = 4
closeBtn.Parent = topBar

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Name = "MinimizeBtn"
minimizeBtn.Size = UDim2.new(0, 16, 1, 0)
minimizeBtn.Position = UDim2.new(1, -36, 0, 0)
minimizeBtn.BackgroundTransparency = 1
minimizeBtn.Text = "—"
minimizeBtn.Font = Enum.Font.Code
minimizeBtn.TextSize = 10
minimizeBtn.TextColor3 = Color3.fromRGB(140, 140, 150)
minimizeBtn.ZIndex = 4
minimizeBtn.Parent = topBar

local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(1, -120, 1, 0)
statusLabel.Position = UDim2.new(0, 84, 0, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "[ready]"
statusLabel.Font = Enum.Font.Code
statusLabel.TextSize = 10
statusLabel.TextColor3 = Color3.fromRGB(80, 220, 120)
statusLabel.TextXAlignment = Enum.TextXAlignment.Right
statusLabel.ZIndex = 4
statusLabel.Parent = topBar

local function updateStatus(text, isError)
    if not statusLabel then return end
    local cleanText = tostring(text):lower():gsub("%.%.%.", "")
    statusLabel.Text = "[" .. cleanText .. "]"
    if isError then
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    elseif cleanText == "ready" then
        statusLabel.TextColor3 = Color3.fromRGB(80, 220, 120)
    else
        statusLabel.TextColor3 = Color3.fromRGB(255, 180, 50)
    end
end

local infoLabel = Instance.new("TextLabel")
infoLabel.Name = "InfoLabel"
infoLabel.Size = UDim2.new(1, 0, 0, 12)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = "place: " .. game.PlaceId .. " | players: " .. #Players:GetPlayers() .. " active"
infoLabel.Font = Enum.Font.Code
infoLabel.TextSize = 9
infoLabel.TextColor3 = Color3.fromRGB(120, 120, 130)
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.ZIndex = 4
infoLabel.LayoutOrder = 2
infoLabel.Parent = mainFrame

local hopBtn = Instance.new("TextButton")
hopBtn.Name = "HopBtn"
hopBtn.Size = UDim2.new(1, 0, 0, 24)
hopBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
hopBtn.BackgroundTransparency = 0.4
hopBtn.BorderSizePixel = 0
hopBtn.Text = "execute_teleport()"
hopBtn.Font = Enum.Font.Code
hopBtn.TextSize = 10
hopBtn.TextColor3 = Color3.fromRGB(220, 220, 230)
hopBtn.ZIndex = 5
hopBtn.LayoutOrder = 3
hopBtn.Parent = mainFrame

local hopBtnCorner = Instance.new("UICorner")
hopBtnCorner.CornerRadius = UDim.new(0, 4)
hopBtnCorner.Parent = hopBtn

local hopBtnStroke = Instance.new("UIStroke")
hopBtnStroke.Color = Color3.fromRGB(255, 255, 255)
hopBtnStroke.Thickness = 1
hopBtnStroke.Transparency = 0.88
hopBtnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
hopBtnStroke.Parent = hopBtn

local settingsRow1 = Instance.new("Frame")
settingsRow1.Name = "SettingsRow1"
settingsRow1.Size = UDim2.new(1, 0, 0, 22)
settingsRow1.BackgroundTransparency = 1
settingsRow1.BorderSizePixel = 0
settingsRow1.ZIndex = 3
settingsRow1.LayoutOrder = 4
settingsRow1.Parent = mainFrame

local settingsLayout1 = Instance.new("UIListLayout")
settingsLayout1.FillDirection = Enum.FillDirection.Horizontal
settingsLayout1.SortOrder = Enum.SortOrder.LayoutOrder
settingsLayout1.Padding = UDim.new(0, 6)
settingsLayout1.Parent = settingsRow1

local modeBtnText = "mode: lowest"
if settings.hopMode == "Random" then
    modeBtnText = "mode: random"
elseif settings.hopMode == "Highest" then
    modeBtnText = "mode: highest"
end

local modeBtn = Instance.new("TextButton")
modeBtn.Name = "ModeBtn"
modeBtn.Size = UDim2.new(0.5, -3, 1, 0)
modeBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
modeBtn.BackgroundTransparency = 0.4
modeBtn.BorderSizePixel = 0
modeBtn.Text = modeBtnText
modeBtn.Font = Enum.Font.Code
modeBtn.TextSize = 9
modeBtn.TextColor3 = Color3.fromRGB(220, 220, 230)
modeBtn.ZIndex = 6
modeBtn.LayoutOrder = 1
modeBtn.Parent = settingsRow1

local modeBtnCorner = Instance.new("UICorner")
modeBtnCorner.CornerRadius = UDim.new(0, 4)
modeBtnCorner.Parent = modeBtn

local modeBtnStroke = Instance.new("UIStroke")
modeBtnStroke.Color = Color3.fromRGB(255, 255, 255)
modeBtnStroke.Thickness = 1
modeBtnStroke.Transparency = 0.88
modeBtnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
modeBtnStroke.Parent = modeBtn

local autoHopTrack = Instance.new("TextButton")
autoHopTrack.Name = "AutoHopTrack"
autoHopTrack.Size = UDim2.new(0.5, -3, 1, 0)
autoHopTrack.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
autoHopTrack.BackgroundTransparency = 0.4
autoHopTrack.BorderSizePixel = 0
autoHopTrack.Text = settings.autoHop and "loop: enabled" or "loop: disabled"
autoHopTrack.Font = Enum.Font.Code
autoHopTrack.TextSize = 9
autoHopTrack.TextColor3 = settings.autoHop and Color3.fromRGB(80, 220, 120) or Color3.fromRGB(220, 220, 230)
autoHopTrack.ZIndex = 6
autoHopTrack.LayoutOrder = 2
autoHopTrack.Parent = settingsRow1

local checkCorner = Instance.new("UICorner")
checkCorner.CornerRadius = UDim.new(0, 4)
checkCorner.Parent = autoHopTrack

local checkStroke = Instance.new("UIStroke")
checkStroke.Color = Color3.fromRGB(255, 255, 255)
checkStroke.Thickness = 1
checkStroke.Transparency = 0.88
checkStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
checkStroke.Parent = autoHopTrack

local settingsRow2 = Instance.new("Frame")
settingsRow2.Name = "SettingsRow2"
settingsRow2.Size = UDim2.new(1, 0, 0, 22)
settingsRow2.BackgroundTransparency = 1
settingsRow2.BorderSizePixel = 0
settingsRow2.ZIndex = 3
settingsRow2.LayoutOrder = 5
settingsRow2.Parent = mainFrame

local settingsLayout2 = Instance.new("UIListLayout")
settingsLayout2.FillDirection = Enum.FillDirection.Horizontal
settingsLayout2.SortOrder = Enum.SortOrder.LayoutOrder
settingsLayout2.Padding = UDim.new(0, 6)
settingsLayout2.Parent = settingsRow2

local intervalLabel = Instance.new("TextLabel")
intervalLabel.Name = "IntervalLabel"
intervalLabel.Size = UDim2.new(0.5, -3, 1, 0)
intervalLabel.BackgroundTransparency = 1
intervalLabel.BorderSizePixel = 0
intervalLabel.Text = "delay_seconds"
intervalLabel.Font = Enum.Font.Code
intervalLabel.TextSize = 9
intervalLabel.TextColor3 = Color3.fromRGB(140, 140, 150)
intervalLabel.TextXAlignment = Enum.TextXAlignment.Center
intervalLabel.ZIndex = 6
intervalLabel.LayoutOrder = 1
intervalLabel.Parent = settingsRow2

local intervalBox = Instance.new("TextBox")
intervalBox.Name = "IntervalBox"
intervalBox.Size = UDim2.new(0.5, -3, 1, 0)
intervalBox.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
intervalBox.BackgroundTransparency = 0.4
intervalBox.BorderSizePixel = 0
intervalBox.Text = tostring(settings.hopInterval)
intervalBox.Font = Enum.Font.Code
intervalBox.TextSize = 10
intervalBox.TextColor3 = Color3.fromRGB(220, 220, 230)
intervalBox.ClearTextOnFocus = false
intervalBox.ZIndex = 6
intervalBox.LayoutOrder = 2
intervalBox.Parent = settingsRow2

local intervalCorner = Instance.new("UICorner")
intervalCorner.CornerRadius = UDim.new(0, 4)
intervalCorner.Parent = intervalBox

local intervalStroke = Instance.new("UIStroke")
intervalStroke.Color = Color3.fromRGB(255, 255, 255)
intervalStroke.Thickness = 1
intervalStroke.Transparency = 0.88
intervalStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
intervalStroke.Parent = intervalBox

local floatingContainer = Instance.new("Frame")
floatingContainer.Name = "FloatingContainer"
floatingContainer.Size = UDim2.new(0, 36, 0, 36)
floatingContainer.Position = UDim2.new(0, 15, 0.5, -18)
floatingContainer.BackgroundTransparency = 1
floatingContainer.Visible = false
floatingContainer.Active = true
floatingContainer.ZIndex = 2
floatingContainer.Parent = screenGui

local floatingBtn = Instance.new("TextButton")
floatingBtn.Name = "FloatingBtn"
floatingBtn.Size = UDim2.new(1, 0, 1, 0)
floatingBtn.Position = UDim2.new(0, 0, 0, 0)
floatingBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
floatingBtn.BackgroundTransparency = 0.25
floatingBtn.BorderSizePixel = 0
floatingBtn.Text = "⚡"
floatingBtn.Font = Enum.Font.Code
floatingBtn.TextSize = 14
floatingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
floatingBtn.ZIndex = 3
floatingBtn.Parent = floatingContainer

local floatingCorner = Instance.new("UICorner")
floatingCorner.CornerRadius = UDim.new(0, 8)
floatingCorner.Parent = floatingBtn

local floatingStroke = Instance.new("UIStroke")
floatingStroke.Color = Color3.fromRGB(255, 255, 255)
floatingStroke.Thickness = 1
floatingStroke.Transparency = 0.85
floatingStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
floatingStroke.Parent = floatingBtn

local function setupHoverAnimation(btn, baseColor, hoverColor)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = hoverColor,
            BackgroundTransparency = 0.25
        }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = baseColor,
            BackgroundTransparency = 0.4
        }):Play()
    end)
end

setupHoverAnimation(hopBtn, Color3.fromRGB(25, 25, 30), Color3.fromRGB(45, 45, 55))
setupHoverAnimation(modeBtn, Color3.fromRGB(25, 25, 30), Color3.fromRGB(45, 45, 55))
setupHoverAnimation(autoHopTrack, Color3.fromRGB(25, 25, 30), Color3.fromRGB(45, 45, 55))
setupHoverAnimation(intervalBox, Color3.fromRGB(25, 25, 30), Color3.fromRGB(45, 45, 55))

closeBtn.MouseEnter:Connect(function()
    closeBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
end)
closeBtn.MouseLeave:Connect(function()
    closeBtn.TextColor3 = Color3.fromRGB(140, 140, 150)
end)

minimizeBtn.MouseEnter:Connect(function()
    minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
end)
minimizeBtn.MouseLeave:Connect(function()
    minimizeBtn.TextColor3 = Color3.fromRGB(140, 140, 150)
end)

local function makeDraggable(dragFrame, moveFrame)
    local dragging
    local dragInput
    local dragStart
    local startPos

    local function update(input)
        local delta = input.Position - dragStart
        moveFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    dragFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = moveFrame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

makeDraggable(topBar, mainFrame)
makeDraggable(floatingBtn, floatingContainer)

closeBtn.MouseButton1Click:Connect(function()
    countdownActive = false
    screenGui:Destroy()
end)

minimizeBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    floatingContainer.Visible = true
end)

floatingBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = true
    floatingContainer.Visible = false
end)

modeBtn.MouseButton1Click:Connect(function()
    if settings.hopMode == "Lowest" then
        settings.hopMode = "Random"
        modeBtn.Text = "mode: random"
    elseif settings.hopMode == "Random" then
        settings.hopMode = "Highest"
        modeBtn.Text = "mode: highest"
    else
        settings.hopMode = "Lowest"
        modeBtn.Text = "mode: lowest"
    end
    saveSettings()
end)

local function updateCheckboxVisual()
    if settings.autoHop then
        autoHopTrack.Text = "loop: enabled"
        autoHopTrack.TextColor3 = Color3.fromRGB(80, 220, 120)
    else
        autoHopTrack.Text = "loop: disabled"
        autoHopTrack.TextColor3 = Color3.fromRGB(220, 220, 230)
    end
end

local hopping = false
local countdownActive = false
local countdownThread = nil

local function fetchServers(placeId, sortOrder)
    sortOrder = sortOrder or "Asc"
    local urls = {
        "https://games.roproxy.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=" .. sortOrder .. "&excludeFullGames=true&limit=100",
        "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=" .. sortOrder .. "&excludeFullGames=true&limit=100"
    }

    local body = nil
    local http = (syn and syn.request) or (http and http.request) or http_request or (Fluxus and Fluxus.request) or request

    for _, url in ipairs(urls) do
        if http then
            local success, response = pcall(function()
                return http({
                    Url = url,
                    Method = "GET"
                })
            end)
            if success and response and response.StatusCode == 200 then
                body = response.Body
                break
            end
        end

        local success, response = pcall(function()
            return game:HttpGet(url)
        end)
        if success and response then
            body = response
            break
        end
    end

    if not body then return nil end

    local successDecode, decoded = pcall(function()
        return HttpService:JSONDecode(body)
    end)

    if successDecode and decoded and decoded.data then
        return decoded.data
    end

    return nil
end

local function executeServerHop()
    if hopping then return end
    hopping = true
    updateStatus("Fetching servers...")

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
            pcall(Character)
            pcall(function()
                character:WaitForChild("HumanoidRootPart", 5)
            end)
        end

        local serverList = fetchServers(placeId, sortOrder)
        if not serverList or #serverList == 0 then
            updateStatus("Failed to load servers", true)
            hopping = false
            return
        end

        print("[hopper debug] fetched " .. #serverList .. " servers using sortorder: " .. tostring(sortOrder))
        for i = 1, math.min(5, #serverList) do
            local s = serverList[i]
            print(string.format("  #%d: %s/%s players | id: %s", i, tostring(s.playing), tostring(s.maxPlayers), tostring(s.id):sub(1, 8)))
        end

        updateStatus("Sorting & filtering...")
        local validServers = {}

        for _, server in ipairs(serverList) do
            if server.id ~= currentJobId and tonumber(server.playing) < tonumber(server.maxPlayers) then
                table.insert(validServers, server)
            end
        end

        if #validServers == 0 then
            updateStatus("No available servers found", true)
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
                return tonumber(a.playing) > tonumber(b.playing)
            end)
            targetServer = nonBlacklisted[1]
        else
            table.sort(nonBlacklisted, function(a, b)
                return tonumber(a.playing) < tonumber(b.playing)
            end)
            
            for _, s in ipairs(nonBlacklisted) do
                if tonumber(s.playing) >= 2 then
                    targetServer = s
                    break
                end
            end
            
            if not targetServer then
                targetServer = nonBlacklisted[1]
            end
        end

        if targetServer then
            print("[hopper debug] selected target: " .. tostring(targetServer.playing) .. "/" .. tostring(targetServer.maxPlayers) .. " players (id: " .. tostring(targetServer.id):sub(1, 8) .. ")")
            updateStatus("Teleporting (" .. targetServer.playing .. "/" .. targetServer.maxPlayers .. ")...")
            
            addToBlacklist(targetServer.id)

            local teleportSuccess, errorMsg = pcall(function()
                TeleportService:TeleportToPlaceInstance(placeId, targetServer.id, localPlayer)
            end)

            if not teleportSuccess then
                updateStatus("Teleport failed, trying default...", true)
                task.wait(1.5)
                pcall(function()
                    TeleportService:Teleport(placeId, localPlayer)
                end)
            end
        else
            updateStatus("No valid target found", true)
        end
        
        hopping = false
    end)
end

TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage)
    if player == localPlayer and screenGui.Parent then
        updateStatus("Teleport failed: " .. tostring(errorMessage) .. ". Retrying hop in 3s...", true)
        task.wait(3)
        if screenGui.Parent then
            executeServerHop()
        end
    end
end)

hopBtn.MouseButton1Click:Connect(executeServerHop)

local function stopCountdown()
    countdownActive = false
    countdownThread = nil
    updateStatus("Ready")
end

local function startCountdown()
    if countdownActive then return end
    countdownActive = true

    countdownThread = task.spawn(function()
        local timeLeft = tonumber(settings.hopInterval) or 60
        while timeLeft > 0 and countdownActive and screenGui.Parent do
            updateStatus("Auto-hop in " .. timeLeft .. "s...")
            task.wait(1)
            timeLeft = timeLeft - 1
        end
        
        if countdownActive and screenGui.Parent then
            executeServerHop()
        end
    end)
end

local function handleAutoHopToggle()
    if settings.autoHop then
        startCountdown()
    else
        stopCountdown()
    end
end

autoHopTrack.MouseButton1Click:Connect(function()
    settings.autoHop = not settings.autoHop
    updateCheckboxVisual()
    saveSettings()
    handleAutoHopToggle()
end)

intervalBox.FocusLost:Connect(function(enterPressed)
    local val = tonumber(intervalBox.Text)
    if val and val >= 0 then
        settings.hopInterval = math.floor(val)
        saveSettings()
        if settings.autoHop then
            stopCountdown()
            startCountdown()
        end
    else
        intervalBox.Text = tostring(settings.hopInterval)
    end
end)

print("Hopper script loaded.")

if settings.autoHop then
    if settings.hopInterval == 0 then
        task.spawn(function()
            updateStatus("Auto-hopping instantly...")
            task.wait(1.5)
            if screenGui.Parent then
                executeServerHop()
            end
        end)
    else
        startCountdown()
    end
else
    updateStatus("Ready")
end
