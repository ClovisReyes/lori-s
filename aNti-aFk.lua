if not game:IsLoaded() then
    game.Loaded:Wait()
end

local INTERVAL_DETIK = 5 * 60

local function doFakeTap()
    pcall(function()
        if typeof(mousemoverel) == "function" then
            mousemoverel(1, 0)
            task.wait(0.01)
            mousemoverel(-1, 0)
        else
            local vim = typeof(cloneref) == "function" and cloneref(game:GetService("VirtualInputManager")) or game:GetService("VirtualInputManager")
            vim:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
            task.wait(0.01)
            vim:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
        end
    end)
end

task.spawn(function()
    while true do
        task.wait(INTERVAL_DETIK)
        doFakeTap()
    end
end)
