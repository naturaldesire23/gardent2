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

--=== IMPROVED PLACEMENT SYSTEM ===--
local function getValidPlacementData(position, rotation, isPathUnit)
    if isPathUnit then
        -- For Rafflesia (path-based unit) - simplified approach
        return {
            Valid = true,
            PathIndex = 1, -- Try different path indices if this doesn't work
            Position = position,
            DistanceAlongPath = 0, -- Start of path
            Rotation = rotation,
            CF = CFrame.new(position) * CFrame.Angles(0, math.rad(rotation), 0)
        }
    else
        -- For regular units like Slingshot and Golem Dragon
        return {
            Valid = true,
            Position = position,
            Rotation = rotation,
            CF = CFrame.new(position) * CFrame.Angles(0, math.rad(rotation), 0)
        }
    end
end

--=== SAFER UPGRADE SYSTEM (Using hotkey E) ===--
local UIS = game:GetService("UserInputService")
local function setupUpgradeHotkey()
    local connection
    connection = UIS.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.E then
            -- Try to upgrade selected unit or all slots
            for slot = 1, 3 do
                pcall(function()
                    -- Method 1: Direct slot number
                    remotes.UpgradeUnit:InvokeServer(slot)
                    -- Method 2: String slot
                    remotes.UpgradeUnit:InvokeServer(tostring(slot))
                end)
            end
            warn("[Upgrade] Attempted upgrades on all slots")
        end
    end)
    
    return connection
end

--=== GAME SCRIPTS ===--

function load2xScript()
    warn("[System] Loaded 2x Speed Script")
    remotes.ChangeTickSpeed:InvokeServer(2)
    
    local upgradeConnection = setupUpgradeHotkey()

    local difficulty = "dif_hard"
    
    -- Improved placement positions (more reliable)
    local placements = {
        -- Slingshot (Early Game) - Slot 1
        {
            time = 15, unit = "unit_slingshot", slot = 1,
            isPathUnit = false,
            position = Vector3.new(-845.806, 61.930, -165.568),
            rotation = 180
        },
        -- Rafflesia (Mid Game) - Slot 2 - SIMPLIFIED POSITION
        {
            time = 47, unit = "unit_rafflesia", slot = 2,
            isPathUnit = true,
            position = Vector3.new(-842.381, 62.180, -159.840),
            rotation = 180
        },
        -- Golem Dragon (Late Game) - Slot 3
        {
            time = 85, unit = "unit_golem_dragon", slot = 3,
            isPathUnit = false,
            position = Vector3.new(-855.950, 61.930, -163.977),
            rotation = 180
        }
    }

    local function placeUnit(unitName, isPathUnit, position, rotation)
        local placementData = getValidPlacementData(position, rotation, isPathUnit)
        
        -- Try multiple placement methods
        local success = pcall(function()
            remotes.PlaceUnit:InvokeServer(unitName, placementData)
        end)
        
        if success then
            warn("[Placing] SUCCESS: "..unitName.." at "..tostring(position))
        else
            warn("[Placing] FAILED: "..unitName.." - trying alternative...")
            
            -- Alternative placement method
            pcall(function()
                local altData = {
                    Valid = true,
                    Position = position,
                    Rotation = rotation,
                    CF = CFrame.new(position)
                }
                remotes.PlaceUnit:InvokeServer(unitName, altData)
            end)
        end
    end

    local function startGame()
        remotes.PlaceDifficultyVote:InvokeServer(difficulty)
        
        -- Place units with better error handling
        for _, p in ipairs(placements) do
            task.delay(p.time, function()
                placeUnit(p.unit, p.isPathUnit, p.position, p.rotation)
            end)
        end
        
        -- Manual upgrade instructions
        warn("[Upgrade] Press E key to upgrade units manually")
        warn("[Upgrade] Recommended: Press E around seconds 50, 60, 70, 80, 90, 100")
    end

    -- Game loop for 4+ minute games
    while true do
        startGame()
        task.wait(260) -- 4 minutes 20 seconds (260 seconds)
        remotes.RestartGame:InvokeServer()
        task.wait(2) -- Brief pause before restart
    end
end

function load3xScript()
    warn("[System] Loaded 3x Speed Script")
    remotes.ChangeTickSpeed:InvokeServer(3)
    
    local upgradeConnection = setupUpgradeHotkey()

    local difficulty = "dif_hard"
    
    -- Faster timings for 3x speed
    local placements = {
        -- Slingshot (Early Game)
        {
            time = 12, unit = "unit_slingshot", slot = 1,
            isPathUnit = false,
            position = Vector3.new(-845.806, 61.930, -165.568),
            rotation = 180
        },
        -- Rafflesia (Mid Game)
        {
            time = 32, unit = "unit_rafflesia", slot = 2,
            isPathUnit = true,
            position = Vector3.new(-842.381, 62.180, -159.840),
            rotation = 180
        },
        -- Golem Dragon (Late Game)
        {
            time = 57, unit = "unit_golem_dragon", slot = 3,
            isPathUnit = false,
            position = Vector3.new(-855.950, 61.930, -163.977),
            rotation = 180
        }
    }

    local function placeUnit(unitName, isPathUnit, position, rotation)
        local placementData = getValidPlacementData(position, rotation, isPathUnit)
        
        local success = pcall(function()
            remotes.PlaceUnit:InvokeServer(unitName, placementData)
        end)
        
        if success then
            warn("[Placing] SUCCESS: "..unitName.." at "..tostring(position))
        else
            warn("[Placing] FAILED: "..unitName.." - trying alternative...")
            pcall(function()
                local altData = {
                    Valid = true,
                    Position = position,
                    Rotation = rotation,
                    CF = CFrame.new(position)
                }
                remotes.PlaceUnit:InvokeServer(unitName, altData)
            end)
        end
    end

    local function startGame()
        remotes.PlaceDifficultyVote:InvokeServer(difficulty)
        
        for _, p in ipairs(placements) do
            task.delay(p.time, function()
                placeUnit(p.unit, p.isPathUnit, p.position, p.rotation)
            end)
        end
        
        warn("[Upgrade] Press E key to upgrade units manually")
        warn("[Upgrade] Recommended: Press E around seconds 40, 50, 60, 70, 80, 90")
    end

    while true do
        startGame()
        task.wait(195) -- 3 minutes 15 seconds for 3x speed
        remotes.RestartGame:InvokeServer()
        task.wait(2)
    end
end

--=== SPEED MENU ===--
local function showSpeedMenu()
    Title.Text = "Select Speed"
    TextBox.Visible = false
    CheckBtn.Visible = false

    local AutoSkipMsg = Instance.new("TextLabel", Frame)
    AutoSkipMsg.Size = UDim2.new(1, -20, 0, 30)
    AutoSkipMsg.Position = UDim2.new(0, 10, 0, 40)
    AutoSkipMsg.BackgroundTransparency = 1
    AutoSkipMsg.Text = "Press E to upgrade units manually"
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