-- DEBUG SCRIPT: Jalankan ini SAAT popup Daily Login / Update Log MASIH TERBUKA
-- Script ini akan mencetak semua properti penting dari Backpack, Events, Compass

local Players = game:GetService("Players")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local targets = {"Backpack", "Events", "Compass"}

for _, name in ipairs(targets) do
    local gui = PlayerGui:FindFirstChild(name)
    if gui then
        print("========== " .. name .. " ==========")
        print("  ClassName: " .. gui.ClassName)
        
        if gui:IsA("ScreenGui") then
            print("  Enabled: " .. tostring(gui.Enabled))
        end
        if gui:IsA("GuiObject") then
            print("  Visible: " .. tostring(gui.Visible))
            print("  Position: " .. tostring(gui.Position))
            print("  Size: " .. tostring(gui.Size))
            print("  BackgroundTransparency: " .. tostring(gui.BackgroundTransparency))
        end
        if gui:IsA("CanvasGroup") then
            print("  GroupTransparency: " .. tostring(gui.GroupTransparency))
        end
        
        -- Cek semua anak langsung
        for _, child in ipairs(gui:GetChildren()) do
            if child:IsA("GuiObject") or child:IsA("CanvasGroup") then
                print("  -- Child: " .. child.Name .. " (" .. child.ClassName .. ")")
                print("     Visible: " .. tostring(child.Visible))
                print("     Position: " .. tostring(child.Position))
                print("     Size: " .. tostring(child.Size))
                if child:IsA("CanvasGroup") then
                    print("     GroupTransparency: " .. tostring(child.GroupTransparency))
                end
                if child:IsA("Frame") or child:IsA("CanvasGroup") then
                    -- Cek cucu
                    for _, grandchild in ipairs(child:GetChildren()) do
                        if grandchild:IsA("GuiObject") or grandchild:IsA("CanvasGroup") then
                            print("     -- GrandChild: " .. grandchild.Name .. " (" .. grandchild.ClassName .. ")")
                            print("        Visible: " .. tostring(grandchild.Visible))
                            if grandchild:IsA("CanvasGroup") then
                                print("        GroupTransparency: " .. tostring(grandchild.GroupTransparency))
                            end
                        end
                    end
                end
            end
        end
    else
        print("========== " .. name .. " = TIDAK DITEMUKAN ==========")
    end
end

print("\n========== DONE ==========")
