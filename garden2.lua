--// Key system
local Players = game:GetService("Players")
local plr = Players.LocalPlayer

print("Waiting for key...")

--// Key GUI
local ScreenGui = Instance.new("ScreenGui", plr:WaitForChild("PlayerGui"))
local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 300, 0, 200)
Frame.Position = UDim2.new(0.5, -150, 0.5, -100)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)

local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "Enter Key"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 20

local TextBox = Instance.new("TextBox", Frame)
TextBox.Size = UDim2.new(1, -20, 0, 40)
TextBox.Position = UDim2.new(0, 10, 0, 50)
TextBox.PlaceholderText = "Enter Key Here"
TextBox.Text = ""
TextBox.Font = Enum.Font.Gotham
TextBox.TextSize = 16
TextBox.TextColor3 = Color3.fromRGB(0, 0, 0)
TextBox.BackgroundColor3 = Color3.fromRGB(200, 200, 200)

local CheckBtn = Instance.new("TextButton", Frame)
CheckBtn.Size = UDim2.new(1, -20, 0, 40)
CheckBtn.Position = UDim2.new(0, 10, 0, 100)
CheckBtn.Text = "Check Key"
CheckBtn.Font = Enum.Font.GothamBold
CheckBtn.TextSize = 18
CheckBtn.BackgroundColor3 = Color3.fromRGB(100, 200, 100)

local Label = Instance.new("TextLabel", Frame)
Label.Size = UDim2.new(1, -20, 0, 40)
Label.Position = UDim2.new(0, 10, 0, 150)
Label.BackgroundTransparency = 1
Label.Text = ""
Label.Font = Enum.Font.GothamBold
Label.TextSize = 16
Label.TextColor3 = Color3.fromRGB(255, 255, 255)

--// Remotes
local rs = game:GetService("ReplicatedStorage")
local remotes = rs:WaitForChild("RemoteFunctions")

-- Auto Skip (enable once at start)
task.delay(2, function()
    pcall(function()
        remotes.ToggleAutoSkip:InvokeServer(true)
        warn("[System] Auto Skip Enabled")
    end)
end)

--=== GAME SCRIPTS ===--

function load2xScript()
    warn("[System] Loaded 2x Speed Script")
    remotes.ChangeTickSpeed:InvokeServer(2)

    local difficulty = "dif_hard"
    local unitIDs = {} -- Track unit IDs for upgrades
    
    local placements = {
        -- Slingshot (Early Game)
        {
            time = 15, unit = "unit_slingshot", slot = 1,
            data = {
                Valid = true,
                Rotation = 180,
                Position = Vector3.new(-845.806396484375, 61.9303092956543, -165.56829833984375),
                CF = CFrame.new(-845.806396484375, 61.9303092956543, -165.56829833984375, -1, 0, -8.742277657347586e-08, 0, 1, 0, 8.742277657347586e-08, 0, -1)
            }
        },
        -- Rafflesia (Mid Game)
        {
            time = 47, unit = "unit_rafflesia", slot = 2,
            data = {
                Valid = true,
                PathIndex = 3,
                Position = Vector3.new(-842.3812866210938, 62.18030548095703, -159.8401641845703),
                DistanceAlongPath = 182.71156311035156,
                Rotation = 180,
                CF = CFrame.new(-842.3812866210938, 62.18030548095703, -159.8401641845703, 1, 0, -0, -0, 1, -0, -0, 0, 1)
            }
        },
        -- Golem Dragon (Late Game)
        {
            time = 85, unit = "unit_golem_dragon", slot = 3,
            data = {
                Valid = true,
                Rotation = 180,
                Position = Vector3.new(-855.949951171875, 61.93030548095703, -163.9769287109375),
                CF = CFrame.new(-855.949951171875, 61.93030548095703, -163.9769287109375, -1, 0, -8.742277657347586e-08, 0, 1, 0, 8.742277657347586e-08, 0, -1)
            }
        }
    }

    local function placeUnit(unitName, slot, data)
        local success, result = pcall(function()
            return remotes.PlaceUnit:InvokeServer(unitName, data)
        end)
        
        if success and result then
            unitIDs[slot] = result -- Store the unit ID returned by the game
            warn("[Placing] "..unitName.." | ID: "..tostring(result))
        else
            warn("[Placing] "..unitName.." | No ID returned")
        end
    end

    local function upgradeUnit(slot, times)
        if unitIDs[slot] then
            for i = 1, times do
                task.delay(i * 2, function() -- Upgrade with 2 second intervals
                    remotes.UpgradeUnit:InvokeServer(unitIDs[slot])
                    warn("[Upgrading] Slot "..slot.." | ID: "..unitIDs[slot].." | Level "..i)
                end)
            end
        else
            warn("[Upgrade Failed] No unit ID for slot "..slot)
        end
    end

    local function startGame()
        remotes.PlaceDifficultyVote:InvokeServer(difficulty)
        
        -- Place units
        for _, p in ipairs(placements) do
            task.delay(p.time, function()
                placeUnit(p.unit, p.slot, p.data)
            end)
        end
        
        -- Upgrade units (4 times each)
        task.delay(90, function() upgradeUnit(1, 4) end) -- Slingshot
        task.delay(95, function() upgradeUnit(2, 4) end) -- Rafflesia  
        task.delay(100, function() upgradeUnit(3, 4) end) -- Golem Dragon
    end

    while true do
        startGame()
        task.wait(174.5)
        remotes.RestartGame:InvokeServer()
        unitIDs = {} -- Reset unit IDs for next game
    end
end

function load3xScript()
    warn("[System] Loaded 3x Speed Script")
    remotes.ChangeTickSpeed:InvokeServer(3)

    local difficulty = "dif_hard"
    local unitIDs = {} -- Track unit IDs for upgrades
    
    local placements = {
        -- Slingshot (Early Game) - Faster timing for 3x
        {
            time = 12, unit = "unit_slingshot", slot = 1,
            data = {
                Valid = true,
                Rotation = 180,
                Position = Vector3.new(-845.806396484375, 61.9303092956543, -165.56829833984375),
                CF = CFrame.new(-845.806396484375, 61.9303092956543, -165.56829833984375, -1, 0, -8.742277657347586e-08, 0, 1, 0, 8.742277657347586e-08, 0, -1)
            }
        },
        -- Rafflesia (Mid Game)
        {
            time = 32, unit = "unit_rafflesia", slot = 2,
            data = {
                Valid = true,
                PathIndex = 3,
                Position = Vector3.new(-842.3812866210938, 62.18030548095703, -159.8401641845703),
                DistanceAlongPath = 182.71156311035156,
                Rotation = 180,
                CF = CFrame.new(-842.3812866210938, 62.18030548095703, -159.8401641845703, 1, 0, -0, -0, 1, -0, -0, 0, 1)
            }
        },
        -- Golem Dragon (Late Game)
        {
            time = 57, unit = "unit_golem_dragon", slot = 3,
            data = {
                Valid = true,
                Rotation = 180,
                Position = Vector3.new(-855.949951171875, 61.93030548095703, -163.9769287109375),
                CF = CFrame.new(-855.949951171875, 61.93030548095703, -163.9769287109375, -1, 0, -8.742277657347586e-08, 0, 1, 0, 8.742277657347586e-08, 0, -1)
            }
        }
    }

    local function placeUnit(unitName, slot, data)
        local success, result = pcall(function()
            return remotes.PlaceUnit:InvokeServer(unitName, data)
        end)
        
        if success and result then
            unitIDs[slot] = result -- Store the unit ID returned by the game
            warn("[Placing] "..unitName.." | ID: "..tostring(result))
        else
            warn("[Placing] "..unitName.." | No ID returned")
        end
    end

    local function upgradeUnit(slot, times)
        if unitIDs[slot] then
            for i = 1, times do
                task.delay(i * 1.5, function() -- Faster upgrades for 3x
                    remotes.UpgradeUnit:InvokeServer(unitIDs[slot])
                    warn("[Upgrading] Slot "..slot.." | ID: "..unitIDs[slot].." | Level "..i)
                end)
            end
        else
            warn("[Upgrade Failed] No unit ID for slot "..slot)
        end
    end

    local function startGame()
        remotes.PlaceDifficultyVote:InvokeServer(difficulty)
        
        -- Place units
        for _, p in ipairs(placements) do
            task.delay(p.time, function()
                placeUnit(p.unit, p.slot, p.data)
            end)
        end
        
        -- Upgrade units (4 times each)
        task.delay(60, function() upgradeUnit(1, 4) end) -- Slingshot
        task.delay(65, function() upgradeUnit(2, 4) end) -- Rafflesia  
        task.delay(70, function() upgradeUnit(3, 4) end) -- Golem Dragon
    end

    while true do
        startGame()
        task.wait(128)
        remotes.RestartGame:InvokeServer()
        unitIDs = {} -- Reset unit IDs for next game
    end
end

--=== SPEED MENU ===--
local function showSpeedMenu()
    Title.Text = "Select Speed"
    TextBox.Visible = false
    CheckBtn.Visible = false

    -- Reminder label directly below title
    local AutoSkipMsg = Instance.new("TextLabel", Frame)
    AutoSkipMsg.Size = UDim2.new(1, -20, 0, 30)
    AutoSkipMsg.Position = UDim2.new(0, 10, 0, 40)
    AutoSkipMsg.BackgroundTransparency = 1
    AutoSkipMsg.Text = "Pls Enable Auto Skip On Manually"
    AutoSkipMsg.Font = Enum.Font.GothamBold
    AutoSkipMsg.TextSize = 14
    AutoSkipMsg.TextColor3 = Color3.fromRGB(255, 200, 0)
    AutoSkipMsg.TextWrapped = true

    local btn2x = Instance.new("TextButton", Frame)
    btn2x.Size = UDim2.new(0.45, 0, 0, 50)
    btn2x.Position = UDim2.new(0.05, 0, 0.5, -25)
    btn2x.Text = "2x Speed"
    btn2x.BackgroundColor3 = Color3.fromRGB(80,160,250)

    local btn3x = Instance.new("TextButton", Frame)
    btn3x.Size = UDim2.new(0.45, 0, 0, 50)
    btn3x.Position = UDim2.new(0.5, 0, 0.5, -25)
    btn3x.Text = "3x Speed"
    btn3x.BackgroundColor3 = Color3.fromRGB(250,120,120)

    btn2x.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
        load2xScript()
    end)

    btn3x.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
        load3xScript()
    end)
end

--=== KEY CHECK ===--
CheckBtn.MouseButton1Click:Connect(function()
    if TextBox.Text:lower() == "cracked" then
        Label.Text = "Key Accepted!"
        Label.TextColor3 = Color3.fromRGB(0,255,0)
        task.delay(1, showSpeedMenu)
    else
        TextBox.Text = ""
        Label.Text = "Invalid Key!"
        Label.TextColor3 = Color3.fromRGB(255,0,0)
    end
end)

print("Script loaded! Enter key: cracked")