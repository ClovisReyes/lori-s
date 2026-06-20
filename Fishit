-- Fish It! / General Roblox Server Hopper (Automated & Persistent)
-- Developed by Antigravity

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
while not localPlayer do
    task.wait(0.1)
    localPlayer = Players.LocalPlayer
end

-- Wait for character to spawn to avoid Teleport Error 769
if not localPlayer.Character then
    localPlayer.CharacterAdded:Wait()
end
task.wait(1.5) -- Extra buffer delay to ensure replication is complete

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local CONFIG_FILENAME = "serverhopper_config_" .. tostring(game.PlaceId) .. ".json"

---------------------------------------
-- CONFIGURATION & PERSISTENCE
---------------------------------------

local settings = {
    autoHop = false,
    hopInterval = 60,
    hopMode = "Lowest",
    autoRejoin = false
}

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
                    settings[k] = v
                end
            end
        end
    end
end

-- Load settings immediately
loadSettings()

---------------------------------------
-- PREVENT DUPLICATE GUIS
---------------------------------------

local function cleanupExisting()
    local success, coreGui = pcall(function() return game:GetService("CoreGui") end)
    if success and coreGui then
        local old = coreGui:FindFirstChild("FishItServerHopGui")
        if old then old:Destroy() end
    end
    local oldP = localPlayer:WaitForChild("PlayerGui"):FindFirstChild("FishItServerHopGui")
    if oldP then oldP:Destroy() end
end
cleanupExisting()

-- Select Parent GUI
local parentGui
local successCore, coreGui = pcall(function() return game:GetService("CoreGui") end)
if successCore and coreGui then
    parentGui = coreGui
else
    parentGui = localPlayer:WaitForChild("PlayerGui")
end

---------------------------------------
-- GUI SETUP
---------------------------------------

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FishItServerHopGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = parentGui

-- Main Panel Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 360, 0, 310) -- Expanded height to fit new inputs
mainFrame.Position = UDim2.new(0.5, -180, 0.4, -155)
mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = mainFrame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(45, 45, 58)
stroke.Thickness = 1.5
stroke.Parent = mainFrame

-- Title Header Frame
local headerFrame = Instance.new("Frame")
headerFrame.Name = "HeaderFrame"
headerFrame.Size = UDim2.new(1, 0, 0, 42)
headerFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
headerFrame.BorderSizePixel = 0
headerFrame.Parent = mainFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 10)
headerCorner.Parent = headerFrame

local headerOverlap = Instance.new("Frame")
headerOverlap.Name = "HeaderOverlap"
headerOverlap.Size = UDim2.new(1, 0, 0, 10)
headerOverlap.Position = UDim2.new(0, 0, 1, -10)
headerOverlap.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
headerOverlap.BorderSizePixel = 0
headerOverlap.Parent = headerFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, -50, 1, 0)
titleLabel.Position = UDim2.new(0, 15, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "FISH IT! AUTOMATED HOPPER"
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 13
titleLabel.TextColor3 = Color3.fromRGB(240, 240, 245)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = headerFrame

local accentLine = Instance.new("Frame")
accentLine.Name = "AccentLine"
accentLine.Size = UDim2.new(1, 0, 0, 2)
accentLine.Position = UDim2.new(0, 0, 1, 0)
accentLine.BorderSizePixel = 0
accentLine.Parent = headerFrame

local accentGradient = Instance.new("UIGradient")
accentGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 120, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 210, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 120, 255))
})
accentGradient.Parent = accentLine

local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 25, 0, 25)
closeBtn.Position = UDim2.new(1, -35, 0.5, -12)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "×"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 22
closeBtn.TextColor3 = Color3.fromRGB(150, 150, 160)
closeBtn.Parent = headerFrame

-- Content Container Frame
local contentFrame = Instance.new("Frame")
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(1, 0, 1, -44)
contentFrame.Position = UDim2.new(0, 0, 0, 44)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

-- Status Text
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(1, -30, 0, 20)
statusLabel.Position = UDim2.new(0, 15, 0, 15)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Ready"
statusLabel.Font = Enum.Font.GothamMedium
statusLabel.TextSize = 13
statusLabel.TextColor3 = Color3.fromRGB(0, 210, 255)
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = contentFrame

-- Server Info Text
local infoLabel = Instance.new("TextLabel")
infoLabel.Name = "InfoLabel"
infoLabel.Size = UDim2.new(1, -30, 0, 18)
infoLabel.Position = UDim2.new(0, 15, 0, 35)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = "Current Server: " .. #Players:GetPlayers() .. " Players (Place ID: " .. game.PlaceId .. ")"
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextSize = 11
infoLabel.TextColor3 = Color3.fromRGB(140, 140, 150)
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.Parent = contentFrame

-- Main Server Hop Action Button
local hopBtn = Instance.new("TextButton")
hopBtn.Name = "HopBtn"
hopBtn.Size = UDim2.new(1, -30, 0, 42)
hopBtn.Position = UDim2.new(0, 15, 0, 68)
hopBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
hopBtn.BorderSizePixel = 0
hopBtn.Text = "Hop Server"
hopBtn.Font = Enum.Font.GothamBold
hopBtn.TextSize = 14
hopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
hopBtn.Parent = contentFrame

local hopBtnCorner = Instance.new("UICorner")
hopBtnCorner.CornerRadius = UDim.new(0, 8)
hopBtnCorner.Parent = hopBtn

local hopGradient = Instance.new("UIGradient")
hopGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 110, 240)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 180, 240))
})
hopGradient.Parent = hopBtn

-- Settings Panel Frame (bottom area)
local settingsFrame = Instance.new("Frame")
settingsFrame.Name = "SettingsFrame"
settingsFrame.Size = UDim2.new(1, -30, 0, 130)
settingsFrame.Position = UDim2.new(0, 15, 0, 122)
settingsFrame.BackgroundTransparency = 1
settingsFrame.Parent = contentFrame

-- 1. Mode Selection (Lowest Players vs. Random)
local modeLabel = Instance.new("TextLabel")
modeLabel.Name = "ModeLabel"
modeLabel.Size = UDim2.new(0.4, 0, 0, 25)
modeLabel.Position = UDim2.new(0, 0, 0, 5)
modeLabel.BackgroundTransparency = 1
modeLabel.Text = "Hop Mode:"
modeLabel.Font = Enum.Font.GothamSemibold
modeLabel.TextSize = 12
modeLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
modeLabel.TextXAlignment = Enum.TextXAlignment.Left
modeLabel.Parent = settingsFrame

local modeBtn = Instance.new("TextButton")
modeBtn.Name = "ModeBtn"
modeBtn.Size = UDim2.new(0.55, 0, 0, 26)
modeBtn.Position = UDim2.new(0.45, 0, 0, 5)
modeBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
modeBtn.BorderSizePixel = 0
modeBtn.Text = settings.hopMode == "Lowest" and "Lowest Players" or "Random Server"
modeBtn.Font = Enum.Font.GothamMedium
modeBtn.TextSize = 11
modeBtn.TextColor3 = Color3.fromRGB(220, 220, 230)
modeBtn.Parent = settingsFrame

local modeBtnCorner = Instance.new("UICorner")
modeBtnCorner.CornerRadius = UDim.new(0, 6)
modeBtnCorner.Parent = modeBtn

local modeBtnStroke = Instance.new("UIStroke")
modeBtnStroke.Color = Color3.fromRGB(48, 48, 62)
modeBtnStroke.Thickness = 1
modeBtnStroke.Parent = modeBtn

-- 2. Auto Hop (Repeat) Toggle Option
local autoHopLabel = Instance.new("TextLabel")
autoHopLabel.Name = "AutoHopLabel"
autoHopLabel.Size = UDim2.new(0.6, 0, 0, 25)
autoHopLabel.Position = UDim2.new(0, 0, 0, 36)
autoHopLabel.BackgroundTransparency = 1
autoHopLabel.Text = "Auto Hop (Repeat):"
autoHopLabel.Font = Enum.Font.GothamSemibold
autoHopLabel.TextSize = 12
autoHopLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
autoHopLabel.TextXAlignment = Enum.TextXAlignment.Left
autoHopLabel.Parent = settingsFrame

local autoHopTrack = Instance.new("TextButton")
autoHopTrack.Name = "AutoHopTrack"
autoHopTrack.Size = UDim2.new(0, 44, 0, 22)
autoHopTrack.Position = UDim2.new(1, -44, 0, 37)
autoHopTrack.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
autoHopTrack.BorderSizePixel = 0
autoHopTrack.Text = ""
autoHopTrack.Parent = settingsFrame

local trackCorner1 = Instance.new("UICorner")
trackCorner1.CornerRadius = UDim.new(1, 0)
trackCorner1.Parent = autoHopTrack

local autoHopThumb = Instance.new("Frame")
autoHopThumb.Name = "AutoHopThumb"
autoHopThumb.Size = UDim2.new(0, 16, 0, 16)
autoHopThumb.Position = UDim2.new(0, 3, 0.5, -8)
autoHopThumb.BackgroundColor3 = Color3.fromRGB(200, 200, 205)
autoHopThumb.BorderSizePixel = 0
autoHopThumb.Parent = autoHopTrack

local thumbCorner1 = Instance.new("UICorner")
thumbCorner1.CornerRadius = UDim.new(1, 0)
thumbCorner1.Parent = autoHopThumb

-- 3. Hop Interval Option (seconds)
local intervalLabel = Instance.new("TextLabel")
intervalLabel.Name = "IntervalLabel"
intervalLabel.Size = UDim2.new(0.6, 0, 0, 25)
intervalLabel.Position = UDim2.new(0, 0, 0, 67)
intervalLabel.BackgroundTransparency = 1
intervalLabel.Text = "Interval (sec):"
intervalLabel.Font = Enum.Font.GothamSemibold
intervalLabel.TextSize = 12
intervalLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
intervalLabel.TextXAlignment = Enum.TextXAlignment.Left
intervalLabel.Parent = settingsFrame

local intervalBox = Instance.new("TextBox")
intervalBox.Name = "IntervalBox"
intervalBox.Size = UDim2.new(0, 60, 0, 22)
intervalBox.Position = UDim2.new(1, -60, 0, 68)
intervalBox.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
intervalBox.BorderSizePixel = 0
intervalBox.Text = tostring(settings.hopInterval)
intervalBox.Font = Enum.Font.GothamMedium
intervalBox.TextSize = 11
intervalBox.TextColor3 = Color3.fromRGB(240, 240, 245)
intervalBox.Parent = settingsFrame

local intervalCorner = Instance.new("UICorner")
intervalCorner.CornerRadius = UDim.new(0, 6)
intervalCorner.Parent = intervalBox

local intervalStroke = Instance.new("UIStroke")
intervalStroke.Color = Color3.fromRGB(48, 48, 62)
intervalStroke.Thickness = 1
intervalStroke.Parent = intervalBox

-- 4. Auto Rejoin on Disconnect Option
local rejoinLabel = Instance.new("TextLabel")
rejoinLabel.Name = "RejoinLabel"
rejoinLabel.Size = UDim2.new(0.6, 0, 0, 25)
rejoinLabel.Position = UDim2.new(0, 0, 0, 98)
rejoinLabel.BackgroundTransparency = 1
rejoinLabel.Text = "Auto Rejoin on Kick:"
rejoinLabel.Font = Enum.Font.GothamSemibold
rejoinLabel.TextSize = 12
rejoinLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
rejoinLabel.TextXAlignment = Enum.TextXAlignment.Left
rejoinLabel.Parent = settingsFrame

local rejoinTrack = Instance.new("TextButton")
rejoinTrack.Name = "RejoinTrack"
rejoinTrack.Size = UDim2.new(0, 44, 0, 22)
rejoinTrack.Position = UDim2.new(1, -44, 0, 99)
rejoinTrack.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
rejoinTrack.BorderSizePixel = 0
rejoinTrack.Text = ""
rejoinTrack.Parent = settingsFrame

local trackCorner2 = Instance.new("UICorner")
trackCorner2.CornerRadius = UDim.new(1, 0)
trackCorner2.Parent = rejoinTrack

local rejoinThumb = Instance.new("Frame")
rejoinThumb.Name = "RejoinThumb"
rejoinThumb.Size = UDim2.new(0, 16, 0, 16)
rejoinThumb.Position = UDim2.new(0, 3, 0.5, -8)
rejoinThumb.BackgroundColor3 = Color3.fromRGB(200, 200, 205)
rejoinThumb.BorderSizePixel = 0
rejoinThumb.Parent = rejoinTrack

local thumbCorner2 = Instance.new("UICorner")
thumbCorner2.CornerRadius = UDim.new(1, 0)
thumbCorner2.Parent = rejoinThumb

---------------------------------------
-- COMPONENT STYLING & ANIMATIONS
---------------------------------------

local function updateStatus(text, isError)
    statusLabel.Text = "Status: " .. text
    if isError then
        statusLabel.TextColor3 = Color3.fromRGB(255, 75, 75)
    else
        statusLabel.TextColor3 = Color3.fromRGB(0, 210, 255)
    end
end

local function setupButtonAnimations(btn, hoverBg, pressScale)
    local originalSize = btn.Size
    local originalColor = btn.BackgroundColor3

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = hoverBg
        }):Play()
    end)

    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = originalColor
        }):Play()
    end)

    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            TweenService:Create(btn, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset * pressScale, originalSize.Y.Scale, originalSize.Y.Offset * pressScale)
            }):Play()
        end
    end)

    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            TweenService:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = originalSize
            }):Play()
        end
    end)
end

setupButtonAnimations(closeBtn, Color3.fromRGB(150, 150, 160), 0.9)
setupButtonAnimations(modeBtn, Color3.fromRGB(40, 40, 52), 0.95)

-- Draggable implementation
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

makeDraggable(headerFrame, mainFrame)

---------------------------------------
-- INTERACTION ROUTINES
---------------------------------------

-- Close window action
closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- Toggle Hop Mode
modeBtn.MouseButton1Click:Connect(function()
    if settings.hopMode == "Lowest" then
        settings.hopMode = "Random"
        modeBtn.Text = "Random Server"
    else
        settings.hopMode = "Lowest"
        modeBtn.Text = "Lowest Players"
    end
    saveSettings()
end)

-- Visual toggles rendering
local function updateToggleVisual(track, thumb, value)
    local targetPos = value and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    local targetColor = value and Color3.fromRGB(0, 180, 120) or Color3.fromRGB(40, 40, 50)
    local thumbColor = value and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 205)

    TweenService:Create(track, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundColor3 = targetColor
    }):Play()
    TweenService:Create(thumb, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = targetPos,
        BackgroundColor3 = thumbColor
    }):Play()
end

-- Set Initial visual states
updateToggleVisual(autoHopTrack, autoHopThumb, settings.autoHop)
updateToggleVisual(rejoinTrack, rejoinThumb, settings.autoRejoin)

---------------------------------------
-- SERVER HOPPING ENGINE
---------------------------------------

local hopping = false
local countdownActive = false
local countdownThread = nil

local function fetchServers(placeId)
    local urls = {
        "https://games.roproxy.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100",
        "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"
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

    task.spawn(function()
        local serverList = fetchServers(placeId)
        if not serverList or #serverList == 0 then
            updateStatus("Failed to load servers", true)
            hopping = false
            return
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

        local targetServer
        if settings.hopMode == "Random" then
            targetServer = validServers[math.random(1, #validServers)]
        else
            table.sort(validServers, function(a, b)
                return tonumber(a.playing) < tonumber(b.playing)
            end)
            
            for _, s in ipairs(validServers) do
                if tonumber(s.playing) >= 2 then
                    targetServer = s
                    break
                end
            end
            
            if not targetServer then
                targetServer = validServers[1]
            end
        end

        if targetServer then
            updateStatus("Teleporting (" .. targetServer.playing .. "/" .. targetServer.maxPlayers .. ")...")
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

-- Retry server hop automatically if the teleport fails
TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage)
    if player == localPlayer then
        updateStatus("Teleport failed: " .. tostring(errorMessage) .. ". Retrying hop in 3s...", true)
        task.wait(3)
        executeServerHop()
    end
end)

hopBtn.MouseButton1Click:Connect(executeServerHop)

-- Hover/press effect for main action button
hopBtn.MouseEnter:Connect(function()
    TweenService:Create(hopBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundColor3 = Color3.fromRGB(0, 140, 255)
    }):Play()
end)
hopBtn.MouseLeave:Connect(function()
    TweenService:Create(hopBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundColor3 = Color3.fromRGB(0, 120, 255)
    }):Play()
end)

---------------------------------------
-- AUTO-HOP SCHEDULER LOOP
---------------------------------------

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
        while timeLeft > 0 and countdownActive do
            updateStatus("Auto-hop in " .. timeLeft .. "s...")
            task.wait(1)
            timeLeft = timeLeft - 1
        end
        
        if countdownActive then
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

-- Connect Auto Hop track interaction
autoHopTrack.MouseButton1Click:Connect(function()
    settings.autoHop = not settings.autoHop
    updateToggleVisual(autoHopTrack, autoHopThumb, settings.autoHop)
    saveSettings()
    handleAutoHopToggle()
end)

-- Connect Interval box focus lost (updates time and restarts timer)
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

-- Connect Auto Rejoin track interaction
rejoinTrack.MouseButton1Click:Connect(function()
    settings.autoRejoin = not settings.autoRejoin
    updateToggleVisual(rejoinTrack, rejoinThumb, settings.autoRejoin)
    saveSettings()
end)

---------------------------------------
-- AUTO REJOIN CONNECTION WRAPPER
---------------------------------------

local errorTriggered = false
GuiService.ErrorMessageChanged:Connect(function()
    if settings.autoRejoin and not errorTriggered then
        errorTriggered = true
        
        local notifyGui = Instance.new("ScreenGui")
        notifyGui.Name = "RejoinNotice"
        notifyGui.Parent = parentGui
        
        local notifyFrame = Instance.new("Frame")
        notifyFrame.Size = UDim2.new(0, 300, 0, 80)
        notifyFrame.Position = UDim2.new(0.5, -150, 0, 20)
        notifyFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
        notifyFrame.Parent = notifyGui
        
        local notifyCorner = Instance.new("UICorner")
        notifyCorner.CornerRadius = UDim.new(0, 8)
        notifyCorner.Parent = notifyFrame
        
        local notifyStroke = Instance.new("UIStroke")
        notifyStroke.Color = Color3.fromRGB(255, 75, 75)
        notifyStroke.Thickness = 1.5
        notifyStroke.Parent = notifyFrame
        
        local notifyText = Instance.new("TextLabel")
        notifyText.Size = UDim2.new(1, -20, 1, -20)
        notifyText.Position = UDim2.new(0, 10, 0, 10)
        notifyText.BackgroundTransparency = 1
        notifyText.Text = "Disconnected! Rejoining game in 8 seconds...\nPress Alt+F4 to cancel."
        notifyText.Font = Enum.Font.GothamBold
        notifyText.TextSize = 12
        notifyText.TextColor3 = Color3.fromRGB(240, 240, 245)
        notifyText.Parent = notifyFrame
        
        task.wait(8)
        
        local success, err = pcall(function()
            TeleportService:Teleport(game.PlaceId, localPlayer)
        end)
        
        if not success then
            notifyText.Text = "Rejoin failed! Retrying..."
            task.wait(5)
            pcall(function()
                TeleportService:Teleport(game.PlaceId, localPlayer)
            end)
        end
    end
end)

---------------------------------------
-- INITIALIZATION STARTUP
---------------------------------------

print("Fish It! Server Hopper loaded successfully.")

-- Start the countdown if autoHop setting is pre-loaded as enabled
if settings.autoHop then
    if settings.hopInterval == 0 then
        task.spawn(function()
            updateStatus("Auto-hopping instantly...")
            task.wait(1.5) -- Tiny safety wait to let Roblox player state initialize fully
            executeServerHop()
        end)
    else
        startCountdown()
    end
else
    updateStatus("Ready")
end
